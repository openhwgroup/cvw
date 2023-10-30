///////////////////////////////////////////
// spill.sv
//
// Written: Rose Thompson ross1728@gmail.com
// Created: 26 October 2023
// Modified: 26 October 2023
//
// Purpose: This module implements native alignment support for the Zicclsm extension
//          It is simlar to the IFU's spill module and probably could be merged together with 
//          some effort.
//
// Documentation: RISC-V System on Chip Design Chapter 11 (Figure 11.5)
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module align import cvw::*;  #(parameter cvw_t P) (
  input logic               clk,               
  input logic               reset,
  input logic               StallM, FlushM,
  input logic [P.XLEN-1:0]  IEUAdrM,               // 2 byte aligned PC in Fetch stage
  input logic [P.XLEN-1:0]  IEUAdrE,           // The next IEUAdrM
  input logic [2:0]         Funct3M,           // Size of memory operation
  input logic [1:0]         MemRWM, 
  input logic               CacheableM,
  input logic [P.LLEN*2-1:0]DCacheReadDataWordM,  // Instruction from the IROM, I$, or bus. Used to check if the instruction if compressed
  input logic               CacheBusHPWTStall,         // I$ or bus are stalled. Transition to second fetch of spill after the first is fetched
  input logic               DTLBMissM,         // ITLB miss, ignore memory request
  input logic               DataUpdateDAM,     // ITLB miss, ignore memory request

  input logic [(P.LLEN-1)/8:0] ByteMaskM,
  input logic [(P.LLEN-1)/8:0] ByteMaskExtendedM,
  input logic [P.LLEN-1:0] LSUWriteDataM, 

  output logic [(P.LLEN*2-1)/8:0] ByteMaskSpillM,
  output logic [P.LLEN*2-1:0] LSUWriteDataSpillM, 

  output logic [P.XLEN-1:0] IEUAdrSpillE,      // The next PCF for one of the two memory addresses of the spill
  output logic [P.XLEN-1:0] IEUAdrSpillM,      // IEUAdrM for one of the two memory addresses of the spill
  output logic              SelSpillE,     // During the transition between the two spill operations, the IFU should stall the pipeline
  output logic [P.LLEN-1:0] DCacheReadDataWordSpillM);// The final 32 bit instruction after merging the two spilled fetches into 1 instruction

  // Spill threshold occurs when all the cache offset PC bits are 1 (except [0]).  Without a cache this is just PCF[1]
  typedef enum logic [1:0]  {STATE_READY, STATE_SPILL} statetype;

  statetype          CurrState, NextState;
  logic              TakeSpillM;
  logic              SpillM;
  logic              SelSpillM;
  logic              SpillSaveM;
  logic [P.LLEN-1:0]   ReadDataWordFirstHalfM;
  logic              MisalignedM;
  logic [P.LLEN*2-1:0] ReadDataWordSpillAllM;
  logic [P.LLEN*2-1:0] ReadDataWordSpillShiftedM;

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // PC logic 
  ////////////////////////////////////////////////////////////////////////////////////////////////////
  
  localparam LLENINBYTES = P.LLEN/8;
  logic [P.XLEN-1:0]     IEUAdrIncrementM;
  /* verilator lint_off WIDTHEXPAND */
  assign IEUAdrIncrementM = IEUAdrM + LLENINBYTES;
  /* verilator lint_on WIDTHEXPAND */
  mux2 #(P.XLEN) ieuadrspillemux(.d0(IEUAdrE), .d1(IEUAdrIncrementM), .s(SelSpillE), .y(IEUAdrSpillE));
  mux2 #(P.XLEN) ieuadrspillmmux(.d0(IEUAdrM), .d1(IEUAdrIncrementM), .s(SelSpillM), .y(IEUAdrSpillM));

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Detect spill
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  // spill detection in lsu is more complex than ifu, depends on 3 factors
  // 1) operation size
  // 2) offset
  // 3) access location within the cacheline
  logic [$clog2(P.DCACHE_LINELENINBITS/8)-1:$clog2(LLENINBYTES)] WordOffsetM;
  logic [$clog2(LLENINBYTES)-1:0]                 ByteOffsetM;
  logic                                HalfSpillM, WordSpillM;
  assign {WordOffsetM, ByteOffsetM} = IEUAdrM[$clog2(P.DCACHE_LINELENINBITS/8)-1:0];
  assign HalfSpillM = (WordOffsetM == '1) & Funct3M[1:0] == 2'b01 & ByteOffsetM[0] != 1'b0;
  assign WordSpillM = (WordOffsetM == '1) & Funct3M[1:0] == 2'b10 & ByteOffsetM[1:0] != 2'b00;
  if(P.LLEN == 64) begin
    logic DoubleSpillM;
    assign DoubleSpillM = (WordOffsetM == '1) & Funct3M[1:0] == 2'b11 & ByteOffsetM[2:0] != 3'b00;
    assign SpillM = (|MemRWM) & CacheableM & (HalfSpillM | WordSpillM | DoubleSpillM);
  end else begin
    assign SpillM = (|MemRWM) & CacheableM & (HalfSpillM | WordSpillM);
  end
      
  // Don't take the spill if there is a stall, TLB miss, or hardware update to the D/A bits
  assign TakeSpillM = SpillM & ~CacheBusHPWTStall & ~(DTLBMissM | (P.SVADU_SUPPORTED & DataUpdateDAM));
  
  always_ff @(posedge clk)
    if (reset | FlushM)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  always_comb begin
    case (CurrState)
      STATE_READY: if (TakeSpillM)                NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      STATE_SPILL: if(StallM)                     NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      default:                                    NextState = STATE_READY;
    endcase
  end

  assign SelSpillM = (CurrState == STATE_SPILL);
  assign SelSpillE = (CurrState == STATE_READY & TakeSpillM) | (CurrState == STATE_SPILL & CacheBusHPWTStall);
  assign SpillSaveM = (CurrState == STATE_READY) & TakeSpillM & ~FlushM;

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Merge spilled data
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  // save the first 2 bytes
  flopenr #(P.LLEN) SpillDataReg(clk, reset, SpillSaveM, DCacheReadDataWordM[P.LLEN-1:0], ReadDataWordFirstHalfM);

  // merge together
  mux2 #(2*P.LLEN) postspillmux(DCacheReadDataWordM, {DCacheReadDataWordM[P.LLEN-1:0], ReadDataWordFirstHalfM}, SpillM, ReadDataWordSpillAllM);

  // align by shifting
  // *** optimize by merging with halfSpill, WordSpill, etc
  logic HalfMisalignedM, WordMisalignedM;
  assign HalfMisalignedM = Funct3M[1:0] == 2'b01 & ByteOffsetM[0] != 1'b0;
  assign WordMisalignedM = Funct3M[1:0] == 2'b10 & ByteOffsetM[1:0] != 2'b00;
  if(P.LLEN == 64) begin
    logic DoubleMisalignedM;
    assign DoubleMisalignedM = Funct3M[1:0] == 2'b11 & ByteOffsetM[2:0] != 3'b00;
    assign MisalignedM = HalfMisalignedM | WordMisalignedM | DoubleMisalignedM;
  end else begin
    assign MisalignedM = HalfMisalignedM | WordMisalignedM;
  end

  // shifter (4:1 mux for 32 bit, 8:1 mux for 64 bit)
  // 8 * is for shifting by bytes not bits
  assign ReadDataWordSpillShiftedM = ReadDataWordSpillAllM >> (MisalignedM ? 8 * ByteOffsetM : '0);
  assign DCacheReadDataWordSpillM = ReadDataWordSpillShiftedM[P.LLEN-1:0];

  // write path. Also has the 8:1 shifter muxing for the byteoffset
  // then it also has the mux to select when a spill occurs
  logic [P.LLEN*2-1:0] LSUWriteDataShiftedM;
  assign LSUWriteDataShiftedM = {LSUWriteDataM, LSUWriteDataM} << (MisalignedM ? 8 * ByteOffsetM : '0);
  mux2 #(2*P.LLEN) writedataspillmux(LSUWriteDataShiftedM, {{{P.LLEN}{1'b0}}, LSUWriteDataShiftedM[P.LLEN*2-1:P.LLEN]}, SelSpillM, LSUWriteDataSpillM);
  logic [P.LLEN*2/8-1:0] ByteMaskShiftedM;
  assign ByteMaskShiftedM = {ByteMaskExtendedM, ByteMaskM};
  mux2 #(2*P.LLEN/8) bytemaskspillmux(ByteMaskShiftedM, {{{P.LLEN/8}{1'b0}}, ByteMaskExtendedM}, SelSpillM, ByteMaskSpillM);
  
endmodule

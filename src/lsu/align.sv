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
  input logic [31:0]        ReadDataWordMuxM,  // Instruction from the IROM, I$, or bus. Used to check if the instruction if compressed
  input logic               LSUStallM,         // I$ or bus are stalled. Transition to second fetch of spill after the first is fetched
  input logic               DTLBMissM,         // ITLB miss, ignore memory request

  output logic [P.XLEN-1:0] IEUAdrSpillE,      // The next PCF for one of the two memory addresses of the spill
  output logic [P.XLEN-1:0] IEUAdrSpillM,      // IEUAdrM for one of the two memory addresses of the spill
  output logic              SelSpillE,     // During the transition between the two spill operations, the IFU should stall the pipeline
  output logic [31:0]       ReadDataWordSpillM)// The final 32 bit instruction after merging the two spilled fetches into 1 instruction

  // Spill threshold occurs when all the cache offset PC bits are 1 (except [0]).  Without a cache this is just PCF[1]
  typedef enum logic [1:0]  {STATE_READY, STATE_SPILL} statetype;

  statetype          CurrState, NextState;
  logic              TakeSpillM, TakeSpillE;
  logic              SpillF;
  logic              SelSpillF;
  logic              SpillSaveF;
  logic [15:0]       InstrFirstHalfF;

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // PC logic 
  ////////////////////////////////////////////////////////////////////////////////////////////////////
  
  localparam LLENINBYTES = LLEN/8;
  logic              IEUAdrIncrementM;
  assign IEUAdrIncrementM = IEUAdrM + LLENINBYTES;
  mux2 #(P.XLEN) pcplus2mux(.d0({IEUAdrM[P.XLEN-1:2], 2'b10}), .d1(IEUAdrIncrementM), .s(TakeSpillM), .y(IEUAdrSpillM));
  mux2 #(P.XLEN) pcnextspillmux(.d0(IEUAdrE), .d1(IEUAdrIncrementM), .s(TakeSpillE), .y(IEUAdrSpillE));

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Detect spill
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  // spill detection in lsu is more complex than ifu, depends on 3 factors
  // 1) operation size
  // 2) offset
  // 3) access location within the cacheline or is the access is uncached.
  // first consider uncached operations
  // accesses are always aligned to the natural size of the bus (XLEN or AHBW)

  if (P.ICACHE_SUPPORTED) begin
    logic  SpillCachedF, SpillUncachedF;
    assign SpillCachedF = &IEUAdrM[$clog2(P.ICACHE_LINELENINBITS/32)+1:1];
    assign SpillUncachedF = IEUAdrM[1]; // *** try to optimize this based on whether the next instruction is 16 bits and by fetching 64 bits in RV64
    assign SpillF = CacheableF ? SpillCachedF : SpillUncachedF;
  end else
    assign SpillF = IEUAdrM[1]; // *** might relax - only spill if next instruction is uncompressed
  // Don't take the spill if there is a stall, TLB miss, or hardware update to the D/A bits
  assign TakeSpillF = SpillF & ~IFUCacheBusStallF & ~(ITLBMissF | (P.SVADU_SUPPORTED & InstrUpdateDAF));
  
  always_ff @(posedge clk)
    if (reset | FlushM)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  always_comb begin
    case (CurrState)
      STATE_READY: if (TakeSpillF)                NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      STATE_SPILL: if(StallM)                     NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      default:                                    NextState = STATE_READY;
    endcase
  end

  assign SelSpillF = (CurrState == STATE_SPILL);
  assign SelSpillNextF = (CurrState == STATE_READY & TakeSpillF) | (CurrState == STATE_SPILL & IFUCacheBusStallF);
  assign SpillSaveF = (CurrState == STATE_READY) & TakeSpillF & ~FlushM;

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Merge spilled instruction
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  // save the first 2 bytes
  flopenr #(16) SpillInstrReg(clk, reset, SpillSaveF, InstrRawF[15:0], InstrFirstHalfF);

  // merge together
  mux2 #(32) postspillmux(InstrRawF, {InstrRawF[15:0], InstrFirstHalfF}, SpillF, PostSpillInstrRawF);

  // Need to use always comb to avoid pessimistic x propagation if PostSpillInstrRawF is x
  always_comb
  if (PostSpillInstrRawF[1:0] != 2'b11) CompressedF = 1'b1;
  else CompressedF = 1'b0;

endmodule

///////////////////////////////////////////
// spill.sv
//
// Written: Ross Thompson ross1728@gmail.com
// Created: 28 January 2022
// Modified: 19 January 2023
//
// Purpose: allows the IFU to make extra memory request if instruction address crosses
//          cache line boundaries or if instruction address without a cache crosses
//          XLEN/8 boundary.
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

module spill import cvw::*;  #(parameter cvw_t P) (
  input logic               clk,               
  input logic               reset,
  input logic               StallD, FlushD,
  input logic [P.XLEN-1:0]  PCF,               // 2 byte aligned PC in Fetch stage
  input logic [P.XLEN-1:2]  PCPlus4F,          // PCF + 4
  input logic [P.XLEN-1:0]  PCNextF,           // The next PCF
  input logic [31:0]        InstrRawF,         // Instruction from the IROM, I$, or bus. Used to check if the instruction if compressed
  input logic               IFUCacheBusStallF, // I$ or bus are stalled. Transition to second fetch of spill after the first is fetched
  input logic               ITLBMissF,         // ITLB miss, ignore memory request
  input logic               InstrUpdateDAF,    // Ignore memory request if the hptw support write and a DA page fault occurs (hptw is still active)
  output logic [P.XLEN-1:0] PCSpillNextF,      // The next PCF for one of the two memory addresses of the spill
  output logic [P.XLEN-1:0] PCSpillF,          // PCF for one of the two memory addresses of the spill
  output logic              SelSpillNextF,     // During the transition between the two spill operations, the IFU should stall the pipeline
  output logic [31:0]       PostSpillInstrRawF,// The final 32 bit instruction after merging the two spilled fetches into 1 instruction
  output logic              CompressedF);      // The fetched instruction is compressed

  // Spill threshold occurs when all the cache offset PC bits are 1 (except [0]).  Without a cache this is just PCF[1]
  typedef enum logic [1:0]  {STATE_READY, STATE_SPILL} statetype;
  localparam                SPILLTHRESHOLD = P.ICACHE_SUPPORTED ? P.ICACHE_LINELENINBITS/32 : 1; 

  statetype          CurrState, NextState;
  logic [P.XLEN-1:0] PCPlus2NextF, PCPlus2F;         
  logic              TakeSpillF;
  logic              SpillF;
  logic              SelSpillF;
  logic              SpillSaveF;
  logic [15:0]       InstrFirstHalfF;

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // PC logic 
  ////////////////////////////////////////////////////////////////////////////////////////////////////
  
  // compute PCF+2 from the raw PC+4
  mux2 #(P.XLEN) pcplus2mux(.d0({PCF[P.XLEN-1:2], 2'b10}), .d1({PCPlus4F, 2'b00}), .s(PCF[1]), .y(PCPlus2NextF));
  // select between PCNextF and PCF+2
  mux2 #(P.XLEN) pcnextspillmux(.d0(PCNextF), .d1(PCPlus2NextF), .s(SelSpillNextF & ~FlushD), .y(PCSpillNextF));
  // select between PCF and PCF+2
  // not required for functional correctness, but improves critical path.  pcspillf ends up on the hptw's ihadr 
  // and into the dmmu.  Cutting the path here removes the PC+4 adder.
  flopr #(P.XLEN) pcplus2reg(clk, reset, PCPlus2NextF, PCPlus2F);
  mux2 #(P.XLEN) pcspillmux(.d0(PCF), .d1(PCPlus2F), .s(SelSpillF), .y(PCSpillF));

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Detect spill
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  assign SpillF = &PCF[$clog2(SPILLTHRESHOLD)+1:1];
  assign TakeSpillF = SpillF & ~IFUCacheBusStallF & ~(ITLBMissF | (P.SVADU_SUPPORTED & InstrUpdateDAF));
  
  always_ff @(posedge clk)
    if (reset | FlushD)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  always_comb begin
    case (CurrState)
      STATE_READY: if (TakeSpillF)                NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      STATE_SPILL: if(StallD)                     NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      default:                                    NextState = STATE_READY;
    endcase
  end

  assign SelSpillF = (CurrState == STATE_SPILL);
  assign SelSpillNextF = (CurrState == STATE_READY & TakeSpillF) | (CurrState == STATE_SPILL & IFUCacheBusStallF);
  assign SpillSaveF = (CurrState == STATE_READY) & TakeSpillF & ~FlushD;

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

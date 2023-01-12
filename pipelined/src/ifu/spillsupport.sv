///////////////////////////////////////////
// spillsupport.sv
//
// Written: Ross Thompson ross1728@gmail.com January 28, 2022
// Modified:
//
// Purpose: allows the IFU to make extra memory request if instruction address crosses
//          cache line boundaries or if instruction address without a cache crosses
//          XLEN/8 boundary.
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

`include "wally-config.vh"

module spillsupport #(parameter CACHE_ENABLED)
  (input logic              clk,
   input logic              reset,
   input logic              StallF, Flush,
   input logic [`XLEN-1:0]  PCF,
   input logic [`XLEN-1:2]  PCPlus4F,
   input logic [`XLEN-1:0]  PCNextF,
   input logic [31:0]       InstrRawF,
   input logic              IFUCacheBusStallD,
   input logic              ITLBMissF, 
   input logic              InstrDAPageFaultF, 
   output logic [`XLEN-1:0] PCNextFSpill,
   output logic [`XLEN-1:0] PCFSpill,
   output logic             SelNextSpillF,
   output logic [31:0]      PostSpillInstrRawF,
   output logic             CompressedF);


  localparam integer   SPILLTHRESHOLD = CACHE_ENABLED ? `ICACHE_LINELENINBITS/32 : 1;
  logic [`XLEN-1:0]    PCPlus2F;
  logic                TakeSpillF;
  logic                SpillF;
  logic                SelSpillF, SpillSaveF;
  logic [15:0]         SpillDataLine0, SavedInstr;
  typedef enum logic [1:0]     {STATE_READY, STATE_SPILL} statetype;
  (* mark_debug = "true" *)  statetype CurrState, NextState;

  // compute PCF+2
  mux2 #(`XLEN) pcplus2mux(.d0({PCF[`XLEN-1:2], 2'b10}), .d1({PCPlus4F, 2'b00}), .s(PCF[1]), .y(PCPlus2F));
  // select between PCNextF and PCF+2
  mux2 #(`XLEN) pcnextspillmux(.d0(PCNextF), .d1(PCPlus2F), .s(SelNextSpillF & ~Flush), .y(PCNextFSpill));
  // select between PCF and PCF+2
  mux2 #(`XLEN) pcspillmux(.d0(PCF), .d1(PCPlus2F), .s(SelSpillF), .y(PCFSpill));
  
  assign SpillF = &PCF[$clog2(SPILLTHRESHOLD)+1:1];
  assign TakeSpillF = SpillF & ~IFUCacheBusStallD & ~(ITLBMissF | (`HPTW_WRITES_SUPPORTED & InstrDAPageFaultF));
  
  always_ff @(posedge clk)
    if (reset | Flush)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  always_comb begin
    case (CurrState)
      STATE_READY: if (TakeSpillF)                NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      STATE_SPILL: if(IFUCacheBusStallD | StallF) NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      default:                                    NextState = STATE_READY;
    endcase
  end

  assign SelSpillF = (CurrState == STATE_SPILL);
  assign SelNextSpillF = (CurrState == STATE_READY & TakeSpillF) |
                         (CurrState == STATE_SPILL & IFUCacheBusStallD);
  assign SpillSaveF = (CurrState == STATE_READY) & TakeSpillF;
  assign SavedInstr = CACHE_ENABLED ? InstrRawF[15:0] : InstrRawF[31:16];
  
  flopenr #(16) SpillInstrReg(.clk(clk),
                              .en(SpillSaveF  & ~Flush),
                              .reset(reset),
                              .d(SavedInstr),
                              .q(SpillDataLine0));

  mux2 #(32) postspillmux(.d0(InstrRawF), .d1({InstrRawF[15:0], SpillDataLine0}), .s(SpillF),
    .y(PostSpillInstrRawF));
  assign CompressedF = PostSpillInstrRawF[1:0] != 2'b11;

endmodule

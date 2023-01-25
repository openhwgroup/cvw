///////////////////////////////////////////
// RASPredictor.sv
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 15, 2021
// Modified: 
//
// Purpose: 2 bit saturating counter predictor with parameterized table depth.
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

module RASPredictor
  #(parameter int StackSize = 16
    )
  (input logic              clk,
   input logic 				reset, StallF, StallD, StallE, StallM, FlushD, FlushE, FlushM,
   output logic [`XLEN-1:0] RASPCF,
   input logic [3:0] 		WrongPredInstrClassD,
   input logic [3:0] 		InstrClassD, InstrClassE, PredInstrClassF,
   input logic [`XLEN-1:0] 	PCLinkE
   );

  // *** need to repair popped and then flushed returns.
  logic                     CounterEn;
  localparam Depth = $clog2(StackSize);

  logic [Depth-1:0]         PtrD, PtrQ, PtrP1, PtrM1;
  logic [StackSize-1:0]     [`XLEN-1:0] memory;
  integer        index;
  logic 		 PopF;
  logic 		 PushE;
  logic 		 RepairD;
  
  

  assign PopF = PredInstrClassF[2] & ~StallD & ~FlushD;
  assign RepairD = InstrClassD[2] & ~StallE & ~FlushE;
  assign PushE = InstrClassE[3] & ~StallM & ~FlushM;
    
  assign CounterEn = PopF | PushE | WrongPredInstrClassD[2];

  assign PtrD = PopF | RepairD ? PtrM1 : PtrP1;

  assign PtrM1 = PtrQ - 1'b1;
  assign PtrP1 = PtrQ + 1'b1;
  // *** what happens if jal is executing and there is a return being flushed in Decode?

  flopenr #(Depth) PTR(.clk(clk),
      .reset(reset),
      .en(CounterEn),
      .d(PtrD),
      .q(PtrQ));

  // RAS must be reset. 
  always_ff @ (posedge clk) begin
    if(reset) begin
      for(index=0; index<StackSize; index++)
		memory[index] <= {`XLEN{1'b0}};
    end else if(PushE) begin
      memory[PtrP1] <= #1 PCLinkE;
    end
  end

  assign RASPCF = memory[PtrQ];
  
  
endmodule




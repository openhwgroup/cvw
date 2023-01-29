///////////////////////////////////////////
// RASPredictor.sv
//
// Written: Ross Thomposn ross1728@gmail.com
// Created: 15 February 2021
// Modified: 25 January 2023
//
// Purpose: 2 bit saturating counter predictor with parameterized table depth.
// 
// Documentation: RISC-V System on Chip Design Chapter 10 (Figure ***)
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

module RASPredictor #(parameter int StackSize = 16 )(
  input  logic             clk,
  input  logic 			   reset, 
  input  logic 			   StallF, StallD, StallE, StallM, FlushD, FlushE, FlushM,
  input  logic [3:0] 	   WrongPredInstrClassD,                      // Prediction class is wrong
  input  logic [3:0] 	   InstrClassD, InstrClassE, PredInstrClassF, // Instr class
  input  logic [`XLEN-1:0] PCLinkE,                                   // PC of instruction after a jal
  output logic [`XLEN-1:0] RASPCF                                     // Top of the stack
   );

  logic                     CounterEn;
  localparam Depth = $clog2(StackSize);

  logic [Depth-1:0]         PtrD, PtrQ, PtrP1, PtrM1;
  logic [StackSize-1:0]     [`XLEN-1:0] memory;
  integer        index;

  logic 		 PopF;
  logic 		 PushE;
  logic 		 RepairD;
  logic 		 IncrRepairD, DecRepairD;
  
  logic 		 DecrementPtr;
  
  assign PopF = PredInstrClassF[2] & ~StallD & ~FlushD;

  assign RepairD = ((WrongPredInstrClassD[2]) & ~StallE & ~FlushE) |  // Wrong class undo increment or decrement.
				   (~StallE & FlushE & InstrClassD[2]) | // ret in decode flushed
				   (~StallM & FlushM & InstrClassE[2]) ; // ret in execution flushed
  
  assign IncrRepairD = (~StallE & FlushE & InstrClassD[2]) | // ret in decode flushed
					   (~StallM & FlushM & InstrClassE[2]) | // ret in execution flushed
					   (WrongPredInstrClassD[2] & ~InstrClassD[2] & ~StallE & ~FlushE); // Guessed it was a ret, but its not

  assign DecRepairD =  (WrongPredInstrClassD[2] & InstrClassD[2] & ~StallE & ~FlushE); // Guessed non ret but is a ret.
  
  assign PushE = InstrClassE[3] & ~StallM & ~FlushM;
    
  assign CounterEn = PopF | PushE | RepairD;

  assign DecrementPtr = (PopF | DecRepairD) & ~IncrRepairD;
  mux2 #(Depth) PtrMux(PtrP1, PtrM1, DecrementPtr, PtrD);

  assign PtrM1 = PtrQ - 1'b1;
  assign PtrP1 = PtrQ + 1'b1;

  flopenr #(Depth) PTR(clk, reset, CounterEn, PtrD, PtrQ);

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




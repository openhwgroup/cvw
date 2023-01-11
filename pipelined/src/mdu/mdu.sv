///////////////////////////////////////////
// mdu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: M extension multiply and divide
// 
// A component of the Wally configurable RISC-V project.
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

module mdu (
	       input logic 		clk, reset,
	       // Execute Stage interface
	       //    input logic [`XLEN-1:0] 	SrcAE, SrcBE,
		   input logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
	       input logic [2:0] 	Funct3E, Funct3M,
	       input logic 		IntDivE, W64E, 
	       // Writeback stage
	       output logic [`XLEN-1:0] MDUResultW,
	       // Divide Done
	       output logic 		DivBusyE, 
	       // hazards
	       input logic 		StallM, StallW, FlushE, FlushM, FlushW 
	       );

	logic [`XLEN-1:0] MDUResultM;
	logic [`XLEN-1:0] PrelimResultM;
	logic [`XLEN-1:0] QuotM, RemM;
	logic [`XLEN*2-1:0] ProdM; 

	logic 		     DivSignedE;	
	logic           W64M; 

	// Multiplier
	mul mul(.clk, .reset, .StallM, .FlushM, .ForwardedSrcAE, .ForwardedSrcBE, .Funct3E, .ProdM);

	// Divide
	// Start a divide when a new division instruction is received and the divider isn't already busy or finishing
	// When F extensions are supported, use the FPU divider instead
	if (`IDIV_ON_FPU) begin  
	  assign QuotM = 0;
	  assign RemM = 0;
	  assign DivBusyE = 0;
	end else begin
		assign DivSignedE = ~Funct3E[0];
		intdivrestoring div(.clk, .reset, .StallM, .FlushE, .DivSignedE, .W64E, .IntDivE, 
							.ForwardedSrcAE, .ForwardedSrcBE, .DivBusyE, .QuotM, .RemM);
	end
		
	// Result multiplexer
	always_comb
		case (Funct3M)	   
			3'b000: PrelimResultM = ProdM[`XLEN-1:0];
			3'b001: PrelimResultM = ProdM[`XLEN*2-1:`XLEN];
			3'b010: PrelimResultM = ProdM[`XLEN*2-1:`XLEN];
			3'b011: PrelimResultM = ProdM[`XLEN*2-1:`XLEN];
			3'b100: PrelimResultM = QuotM;
			3'b101: PrelimResultM = QuotM;
			3'b110: PrelimResultM = RemM;
			3'b111: PrelimResultM = RemM;
		endcase 

	// Handle sign extension for W-type instructions
	flopenrc #(1) W64MReg(clk, reset, FlushM, ~StallM, W64E, W64M);
	if (`XLEN == 64) begin:resmux // RV64 has W-type instructions
		assign MDUResultM = W64M ? {{32{PrelimResultM[31]}}, PrelimResultM[31:0]} : PrelimResultM;
	end else begin:resmux // RV32 has no W-type instructions
		assign MDUResultM = PrelimResultM;
	end

	// Writeback stage pipeline register
	flopenrc #(`XLEN) MDUResultWReg(clk, reset, FlushW, ~StallW, MDUResultM, MDUResultW);	 
endmodule // mdu



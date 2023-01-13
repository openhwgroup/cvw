///////////////////////////////////////////
// mdu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: M extension multiply and divide
// 
// Documentation: RISC-V System on Chip Design Chapter 12 (Figure 12.21)
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

module mdu(
  input  logic 							clk, reset,
  input  logic 							StallM, StallW, 
  input  logic							FlushE, FlushM, FlushW,
	input  logic [`XLEN-1:0] 	ForwardedSrcAE, ForwardedSrcBE, 	// inputs A and B from IEU forwarding mux output
	input  logic [2:0] 				Funct3E, Funct3M,									// type of MDU operation
	input  logic 							IntDivE, W64E, 										// Integer division/remainder, and W-type instrutions
	output logic [`XLEN-1:0] 	MDUResultW,												// multiply/divide result
	output logic 							DivBusyE													// busy signal to stall pipeline in Execute stage
);

	logic [`XLEN*2-1:0] 			ProdM; 														// double-width product from mul
	logic [`XLEN-1:0] 				QuotM, RemM;											// quotient and remainder from intdivrestoring
	logic [`XLEN-1:0] 				PrelimResultM;										// selected result before W truncation
	logic [`XLEN-1:0] 				MDUResultM;												// result after W truncation
	logic           					W64M; 														// W-type instruction

	// Multiplier
	mul mul(.clk, .reset, .StallM, .FlushM, .ForwardedSrcAE, .ForwardedSrcBE, .Funct3E, .ProdM);

	// Divider
	// Start a divide when a new division instruction is received and the divider isn't already busy or finishing
	// When IDIV_ON_FPU is set, use the FPU divider instead
	if (`IDIV_ON_FPU) begin  
	  assign QuotM = 0;
	  assign RemM = 0;
	  assign DivBusyE = 0;
	end else begin
		intdivrestoring div(.clk, .reset, .StallM, .FlushE, .DivSignedE(~Funct3E[0]), .W64E, .IntDivE, 
							.ForwardedSrcAE, .ForwardedSrcBE, .DivBusyE, .QuotM, .RemM);
	end
		
	// Result multiplexer
	always_comb
		case (Funct3M)	   
			3'b000: PrelimResultM = ProdM[`XLEN-1:0];					// mul
			3'b001: PrelimResultM = ProdM[`XLEN*2-1:`XLEN];		// mulh
			3'b010: PrelimResultM = ProdM[`XLEN*2-1:`XLEN];		// mulhsu
			3'b011: PrelimResultM = ProdM[`XLEN*2-1:`XLEN];		// mulhu
			3'b100: PrelimResultM = QuotM;										// div
			3'b101: PrelimResultM = QuotM;										// divu
			3'b110: PrelimResultM = RemM;											// rem
			3'b111: PrelimResultM = RemM;											// remu
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



///////////////////////////////////////////
// muldiv.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: M extension multiply and divide
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module muldiv (
	       input logic 		clk, reset,
	       // Decode Stage interface
	       input logic [31:0] 	InstrD, 
	       // Execute Stage interface
	       input logic [`XLEN-1:0] 	SrcAE, SrcBE,
	       input logic [2:0] 	Funct3E, Funct3M,
	       input logic 		MulDivE, W64E,
	       // Writeback stage
	       output logic [`XLEN-1:0] MulDivResultW,
	       // Divide Done
	       output logic 		DivDoneE,
	       output logic 		DivBusyE, 
	       // hazards
	       input logic 		StallE, StallM, StallW, FlushM, FlushW 
	       );

   generate
      if (`M_SUPPORTED) begin
	 logic [`XLEN-1:0] MulDivResultE, MulDivResultM;
	 logic [`XLEN-1:0] PrelimResultM;
	 logic [`XLEN-1:0] QuotM, RemM;
	 logic [`XLEN*2-1:0] ProdE, ProdM; 

	 logic 		     enable_q;	 
	 //logic [2:0] 	     Funct3E_Q;
	 logic 		     div0error; // ***unused
	 logic [`XLEN-1:0]   X, D;
	 //logic [`XLEN-1:0]   Num0, Den0;	 

	// logic 		     gclk;
	 logic 		     StartDivideE, BusyE;
	 logic 		     SignedDivideE;	
	 logic           W64M; 
	 
	 
	 // Multiplier
	 mul mul(.*);
	 flopenrc #(`XLEN*2) ProdMReg(clk, reset, FlushM, ~StallM, ProdE, ProdM); 

	 // Divide

	 // Handle sign extension for W-type instructions
	 if (`XLEN == 64) begin // RV64 has W-type instructions
            assign X = W64E ? {{32{SrcAE[31]&SignedDivideE}}, SrcAE[31:0]} : SrcAE;
            assign D = W64E ? {{32{SrcBE[31]&SignedDivideE}}, SrcBE[31:0]} : SrcBE;
	 end else begin // RV32 has no W-type instructions
            assign X = SrcAE;
            assign D = SrcBE;	    
	 end	    

	 assign SignedDivideE = ~Funct3E[0]; // simplified from (Funct3E[2]&~Funct3E[1]&~Funct3E[0]) | (Funct3E[2]&Funct3E[1]&~Funct3E[0]);	 
	 //intdiv #(`XLEN) div (QuotE, RemE, DivDoneE, DivBusyE, div0error, N, D, gclk, reset, StartDivideE, SignedDivideE);
	 intdivrestoring div(.clk, .reset, .StallM, .FlushM, 
	   .SignedDivideE, .StartDivideE, .X(X), .D(D), .BusyE, .done(DivDoneE), .Q(QuotM), .REM(RemM));

	 // Start a divide when a new division instruction is received and the divider isn't already busy or finishing
	 assign StartDivideE = MulDivE & Funct3E[2] & ~BusyE & ~DivDoneE; // *** mabye DivDone should be M stage
	 assign DivBusyE = StartDivideE | BusyE;
	 	 
	 // Select result
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
	 if (`XLEN == 64) begin // RV64 has W-type instructions
            assign MulDivResultM = W64M ? {{32{PrelimResultM[31]}}, PrelimResultM[31:0]} : PrelimResultM;
	 end else begin // RV32 has no W-type instructions
            assign MulDivResultM = PrelimResultM;
	 end

	 flopenrc #(`XLEN) MulDivResultWReg(clk, reset, FlushW, ~StallW, MulDivResultM, MulDivResultW);	 

      end else begin // no M instructions supported
	 	assign MulDivResultW = 0; 
		assign DivBusyE = 0;
		assign DivDoneE = 0;
      end
   endgenerate

endmodule // muldiv



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
	       input logic [2:0] 	Funct3E,
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
	 logic [`XLEN-1:0] PrelimResultE;
	 logic [`XLEN-1:0] QuotE, RemE;
	 //logic [`XLEN-1:0] Q, R;	 
	 logic [`XLEN*2-1:0] ProdE; 

	 logic 		     enable_q;	 
	 logic [2:0] 	     Funct3E_Q;
	 logic 		     div0error;
	 logic [`XLEN-1:0]   N, D;

	 logic 		     gclk;
	 logic 		     DivStartE;
	 logic 		     startDivideE;
	 logic 		     signedDivide;	 
	 
	 // Multiplier
	 mul mul(.*);
	 // Divide

	// *** replace this clock gater
	 always @(negedge clk) begin
	    enable_q <= ~StallM;
	 end
	 assign gclk = enable_q & clk;

	 // capture the Numerator/Denominator	 
	 flopenrc #(`XLEN) reg_num (.d(SrcAE), .q(N),
				    .en(startDivideE), .clear(DivDoneE),
				    .reset(reset),  .clk(~gclk));
	 flopenrc #(`XLEN) reg_den (.d(SrcBE), .q(D),
				    .en(startDivideE), .clear(DivDoneE),
				    .reset(reset),  .clk(~gclk));	 
	 assign signedDivide = (Funct3E[2]&~Funct3E[1]&~Funct3E[0]) | (Funct3E[2]&Funct3E[1]&~Funct3E[0]);	 
	 div div (QuotE, RemE, DivDoneE, DivBusyE, div0error, N, D, gclk, reset, startDivideE, signedDivide);

	 // Added for debugging of start signal for divide
	 assign startDivideE = MulDivE&DivStartE&~DivBusyE;
	 
	 // capture the start control signals since they are not held constant.
	 flopenrc #(3) funct3ereg (.d(Funct3E),
				   .q(Funct3E_Q),
				   .en(DivStartE),
				   .clear(DivDoneE),
				   .reset(reset),
				   .clk(clk));
	 
	 // Select result
	 always_comb
	   //           case (DivDoneE ? Funct3E_Q : Funct3E)
           case (Funct3E)	   
             3'b000: PrelimResultE = ProdE[`XLEN-1:0];
             3'b001: PrelimResultE = ProdE[`XLEN*2-1:`XLEN];
             3'b010: PrelimResultE = ProdE[`XLEN*2-1:`XLEN];
             3'b011: PrelimResultE = ProdE[`XLEN*2-1:`XLEN];
             3'b100: PrelimResultE = QuotE;
             3'b101: PrelimResultE = QuotE;
             3'b110: PrelimResultE = RemE;
             3'b111: PrelimResultE = RemE;
           endcase // case (Funct3E)

	 // Start Divide process
	 always_comb
           case (Funct3E)
             3'b000: DivStartE = 1'b0;
             3'b001: DivStartE = 1'b0;
             3'b010: DivStartE = 1'b0;
             3'b011: DivStartE = 1'b0;
             3'b100: DivStartE = 1'b1;
             3'b101: DivStartE = 1'b1;
             3'b110: DivStartE = 1'b1;
             3'b111: DivStartE = 1'b1;
           endcase
	 
	 // Handle sign extension for W-type instructions
	 if (`XLEN == 64) begin // RV64 has W-type instructions
            assign MulDivResultE = W64E ? {{32{PrelimResultE[31]}}, PrelimResultE[31:0]} : PrelimResultE;
	 end else begin // RV32 has no W-type instructions
            assign MulDivResultE = PrelimResultE;
	 end

	 flopenrc #(`XLEN) MulDivResultMReg(clk, reset, FlushM, ~StallM, MulDivResultE, MulDivResultM);
	 flopenrc #(`XLEN) MulDivResultWReg(clk, reset, FlushW, ~StallW, MulDivResultM, MulDivResultW);	 

      end else begin // no M instructions supported
	 assign MulDivResultW = 0; 
      end
   endgenerate

endmodule // muldiv



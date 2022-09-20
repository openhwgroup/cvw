///////////////////////////////////////////
// fsgninj.sv
//
// Written: me@KatherineParry.com
// Modified: 6/23/2021
//
// Purpose: FPU Sign Injection instructions
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module fsgninj (  
	input logic        			Xs, Ys,	// X and Y sign bits
	input logic [`FLEN-1:0] 	X,		// X
	input logic [`FMTBITS-1:0]	Fmt,	// format
	input  logic [1:0]  		OpCtrl,	// operation control
	output logic [`FLEN-1:0] 	SgnRes	// result
);

	logic ResSgn;

	// OpCtrl:
	// 		00 - fsgnj  - directly copy over sign value of Y
	// 		01 - fsgnjn - negate sign value of Y
	// 		10 - fsgnjx - XOR sign values of X and Y
	
	// calculate the result's sign
	assign ResSgn = (OpCtrl[1] ? Xs : OpCtrl[0]) ^ Ys;
	
	// format final result based on precision
	//    - uses NaN-blocking format
	//        - if there are any unsused bits the most significant bits are filled with 1s
	
    if (`FPSIZES == 1)
		assign SgnRes = {ResSgn, X[`FLEN-2:0]};

    else if (`FPSIZES == 2)
		assign SgnRes = {~Fmt|ResSgn, X[`FLEN-2:`LEN1], Fmt ? X[`LEN1-1] : ResSgn, X[`LEN1-2:0]};

    else if (`FPSIZES == 3) begin
		logic [2:0] SgnBits;
        always_comb
            case (Fmt)
                `FMT: SgnBits = {ResSgn, X[`LEN1-1], X[`LEN2-1]};
                `FMT1: SgnBits = {1'b1, ResSgn, X[`LEN2-1]};
                `FMT2: SgnBits = {2'b11, ResSgn};
                default: SgnBits = {3{1'bx}};
            endcase
		assign SgnRes = {SgnBits[2], X[`FLEN-2:`LEN1], SgnBits[1], X[`LEN1-2:`LEN2], SgnBits[0], X[`LEN2-2:0]};
        

	end else if (`FPSIZES == 4) begin
		logic [3:0] SgnBits;
        always_comb
            case (Fmt)
                `Q_FMT: SgnBits = {ResSgn, X[`D_LEN-1], X[`S_LEN-1], X[`H_LEN-1]};
                `D_FMT: SgnBits = {1'b1, ResSgn, X[`S_LEN-1], X[`H_LEN-1]};
                `S_FMT: SgnBits = {2'b11, ResSgn, X[`H_LEN-1]};
                `H_FMT: SgnBits = {3'b111, ResSgn};
            endcase
		assign SgnRes = {SgnBits[3], X[`Q_LEN-2:`D_LEN], SgnBits[2], X[`D_LEN-2:`S_LEN], SgnBits[1], X[`S_LEN-2:`H_LEN], SgnBits[0], X[`H_LEN-2:0]};
	end

endmodule

///////////////////////////////////////////
//
// Written: Katherine Parry
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
	input logic        	XSgnE, YSgnE,	// X and Y sign bits
	input logic [`FLEN-1:0] 	FSrcXE,			// X
	input logic [`FMTBITS-1:0]		FmtE,			// precision 1 = double 0 = single
	input  logic [1:0]  SgnOpCodeE,		// operation control
	output logic [`FLEN-1:0] SgnResE			// result
);

	logic ResSgn;

	//op code designation:
	//
	//00 - fsgnj - directly copy over sign value of FSrcYE
	//01 - fsgnjn - negate sign value of FSrcYE
	//10 - fsgnjx - XOR sign values of FSrcXE & FSrcYE
	//
	
	// calculate the result's sign
	assign ResSgn = (SgnOpCodeE[1] ? XSgnE : SgnOpCodeE[0]) ^ YSgnE;
	
	// format final result based on precision
	//    - uses NaN-blocking format
	//        - if there are any unsused bits the most significant bits are filled with 1s
	
    if (`FPSIZES == 1)
		assign SgnResE = {ResSgn, FSrcXE[`FLEN-2:0]};

    else if (`FPSIZES == 2)
		assign SgnResE = {~FmtE|ResSgn, FSrcXE[`FLEN-2:`LEN1], FmtE ? FSrcXE[`LEN1-1] : ResSgn, FSrcXE[`LEN1-2:0]};

    else if (`FPSIZES == 3) begin
		logic [2:0] SgnBits;
        always_comb
            case (FmtE)
                `FMT: SgnBits = {ResSgn, FSrcXE[`LEN1-1], FSrcXE[`LEN2-1]};
                `FMT1: SgnBits = {1'b1, ResSgn, FSrcXE[`LEN2-1]};
                `FMT2: SgnBits = {2'b11, ResSgn};
                default: SgnBits = {3{1'bx}};
            endcase
		assign SgnResE = {SgnBits[2], FSrcXE[`FLEN-2:`LEN1], SgnBits[1], FSrcXE[`LEN1-2:`LEN2], SgnBits[0], FSrcXE[`LEN2-2:0]};
        

	end else if (`FPSIZES == 4) begin
		logic [3:0] SgnBits;
        always_comb
            case (FmtE)
                `Q_FMT: SgnBits = {ResSgn, FSrcXE[`D_LEN-1], FSrcXE[`S_LEN-1], FSrcXE[`H_LEN-1]};
                `D_FMT: SgnBits = {1'b1, ResSgn, FSrcXE[`S_LEN-1], FSrcXE[`H_LEN-1]};
                `S_FMT: SgnBits = {2'b11, ResSgn, FSrcXE[`H_LEN-1]};
                `H_FMT: SgnBits = {3'b111, ResSgn};
            endcase
		assign SgnResE = {SgnBits[3], FSrcXE[`Q_LEN-2:`D_LEN], SgnBits[2], FSrcXE[`D_LEN-2:`S_LEN], SgnBits[1], FSrcXE[`S_LEN-2:`H_LEN], SgnBits[0], FSrcXE[`H_LEN-2:0]};
	end

endmodule

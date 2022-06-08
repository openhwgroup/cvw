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
	assign ResSgn = SgnOpCodeE[1] ? (XSgnE ^ YSgnE) : (YSgnE ^ SgnOpCodeE[0]);
	
	// format final result based on precision
	//    - uses NaN-blocking format
	//        - if there are any unsused bits the most significant bits are filled with 1s
	
    if (`FPSIZES == 1)
		assign SgnResE = {ResSgn, FSrcXE[`FLEN-2:0]};

    else if (`FPSIZES == 2)
		assign SgnResE = FmtE ? {ResSgn, FSrcXE[`FLEN-2:0]} : {{`FLEN-`LEN1{1'b1}}, ResSgn, FSrcXE[`LEN1-2:0]};

    else if (`FPSIZES == 3)
        always_comb
            case (FmtE)
                `FMT: SgnResE = {ResSgn, FSrcXE[`FLEN-2:0]};
                `FMT1: SgnResE = {{`FLEN-`LEN1{1'b1}}, ResSgn, FSrcXE[`LEN1-2:0]};
                `FMT2: SgnResE = {{`FLEN-`LEN2{1'b1}}, ResSgn, FSrcXE[`LEN2-2:0]};
                default: SgnResE = 0;
            endcase

    else if (`FPSIZES == 4)
        always_comb
            case (FmtE)
                2'h3: SgnResE = {ResSgn, FSrcXE[`Q_LEN-2:0]};
                2'h1: SgnResE = {{`Q_LEN-`D_LEN{1'b1}}, ResSgn, FSrcXE[`D_LEN-2:0]};
                2'h0: SgnResE = {{`Q_LEN-`S_LEN{1'b1}}, ResSgn, FSrcXE[`S_LEN-2:0]};
                2'h2: SgnResE = {{`Q_LEN-`H_LEN{1'b1}}, ResSgn, FSrcXE[`H_LEN-2:0]};
            endcase


endmodule

///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Negate integer result
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

module negateintres(
    input logic         Xs,
    input logic [`NORMSHIFTSZ-1:0]  Shifted,
    input logic         Signed,
    input logic         Int64,
    input logic         Plus1,
    output logic [1:0]          CvtNegResMsbs,
    output logic [`XLEN+1:0]    CvtNegRes
);

    
    // round and negate the positive res if needed
    assign CvtNegRes = Xs ? -({2'b0, Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1}) : {2'b0, Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1};
    
    assign CvtNegResMsbs = Signed ? Int64 ? CvtNegRes[`XLEN:`XLEN-1] : CvtNegRes[32:31] :
			              Int64 ? CvtNegRes[`XLEN+1:`XLEN] : CvtNegRes[33:32];

endmodule
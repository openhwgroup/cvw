///////////////////////////////////////////
// roundsign.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Sign calculation ofr rounding
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

module roundsign(
    input logic         FmaPs, FmaAs,
    input logic         FmaInvA,
    input logic         Xs,
    input logic         Ys,
    input logic         FmaNegSum,
    input logic         Sqrt,
    input logic         FmaOp,
    input logic         DivOp,
    input logic         CvtOp,
    input logic         CvtCs,
    input logic         FmaSs,
    output logic        Ms
);

    logic Qs;

    assign Qs = Xs^(Ys&~Sqrt);

    // Sign for rounding calulation
    assign Ms = (FmaSs&FmaOp) | (CvtCs&CvtOp) | (Qs&DivOp);

endmodule
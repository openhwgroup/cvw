///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: calculating the result's sign
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

module resultsign(
    input logic [2:0]   Frm,
    input logic         FmaPs, FmaAs,
    input logic         ZInf,
    input logic         InfIn,
    input logic         FmaOp,
    input logic [`NE+1:0] FmaSe,
    input logic         FmaSmZero,
    input logic         Mult,
    input logic         R,
    input logic         S,
    input logic         Nsgn,
    output logic        Ws
);

    logic ZeroSgn;
    logic InfSgn;
    logic Underflow;
    // logic ResultSgnTmp;

    // Determine the sign if the sum is zero
    //      if cancelation then 0 unless round to -infinity
    //      if multiply then Psgn
    //      otherwise psign
    assign Underflow = FmaSe[`NE+1] | ((FmaSe == 0) & (R|S));
    assign ZeroSgn = (FmaPs^FmaAs)&~Underflow&~Mult ? Frm[1:0] == 2'b10 : FmaPs;


    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign InfSgn = ZInf ? FmaAs : FmaPs;
    assign Ws = InfIn&FmaOp ? InfSgn : FmaSmZero&FmaOp ? ZeroSgn : Nsgn;

endmodule
///////////////////////////////////////////
// fclassivy.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: classify unit
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

module fclassify (
    input logic         Xs,     // sign bit
    input logic         XNaN,   // is NaN
    input logic         XSNaN,  // is signaling NaN
    input logic         XDenorm,// is denormal
    input logic         XZero,  // is zero
    input logic         XInf,   // is infinity
    output logic [`XLEN-1:0] ClassRes// classify result
);

    logic PInf, PZero, PNorm, PDenorm;
    logic NInf, NZero, NNorm, NDenorm;
    logic XNorm;
   
    // determine the sub categories
    assign XNorm= ~(XNaN | XInf| XDenorm| XZero);
    assign PInf = ~Xs&XInf;
    assign NInf = Xs&XInf;
    assign PNorm = ~Xs&XNorm;
    assign NNorm = Xs&XNorm;
    assign PDenorm = ~Xs&XDenorm;
    assign NDenorm = Xs&XDenorm;
    assign PZero = ~Xs&XZero;
    assign NZero = Xs&XZero;

    // determine sub category and combine into the result
    //  bit 0 - -Inf
    //  bit 1 - -Norm
    //  bit 2 - -Denorm
    //  bit 3 - -Zero
    //  bit 4 - +Zero
    //  bit 5 - +Denorm
    //  bit 6 - +Norm
    //  bit 7 - +Inf
    //  bit 8 - signaling NaN
    //  bit 9 - quiet NaN
    assign ClassRes = {{`XLEN-10{1'b0}}, XNaN&~XSNaN, XSNaN, PInf, PNorm, PDenorm, PZero, NZero, NDenorm, NNorm, NInf};

endmodule

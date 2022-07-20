///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: unpack all inputs
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

module unpack ( 
    input logic  [`FLEN-1:0]        X, Y, Z,    // inputs from register file
    input logic  [`FMTBITS-1:0]     Fmt,       // format signal 00 - single 01 - double 11 - quad 10 - half
    output logic                    Xs, Ys, Zs,    // sign bits of XYZ
    output logic [`NE-1:0]          Xe, Ye, Ze,    // exponents of XYZ (converted to largest supported precision)
    output logic [`NF:0]            Xm, Ym, Zm,    // mantissas of XYZ (converted to largest supported precision)
    output logic                    XNaN, YNaN, ZNaN,    // is XYZ a NaN
    output logic                    XSNaN, YSNaN, ZSNaN, // is XYZ a signaling NaN
    output logic                    XDenorm, ZDenorm,   // is XYZ denormalized
    output logic                    XZero, YZero, ZZero,         // is XYZ zero
    output logic                    XInf, YInf, ZInf,            // is XYZ infinity
    output logic                    XExpMax                        // does X have the maximum exponent (NaN or Inf)
);
 
    logic           XExpNonZero, YExpNonZero, ZExpNonZero; // is the exponent of XYZ non-zero
    logic           XFracZero, YFracZero, ZFracZero; // is the fraction zero
    logic           YExpMax, ZExpMax;  // is the exponent all 1s
    
    unpackinput unpackinputX (.In(X), .Fmt, .Sgn(Xs), .Exp(Xe), .Man(Xm), 
                            .NaN(XNaN), .SNaN(XSNaN), .ExpNonZero(XExpNonZero),
                            .Zero(XZero), .Inf(XInf), .ExpMax(XExpMax), .FracZero(XFracZero));

    unpackinput unpackinputY (.In(Y), .Fmt, .Sgn(Ys), .Exp(Ye), .Man(Ym), 
                            .NaN(YNaN), .SNaN(YSNaN), .ExpNonZero(YExpNonZero),
                            .Zero(YZero), .Inf(YInf), .ExpMax(YExpMax), .FracZero(YFracZero));

    unpackinput unpackinputZ (.In(Z), .Fmt, .Sgn(Zs), .Exp(Ze), .Man(Zm), 
                            .NaN(ZNaN), .SNaN(ZSNaN), .ExpNonZero(ZExpNonZero),
                            .Zero(ZZero), .Inf(ZInf), .ExpMax(ZExpMax), .FracZero(ZFracZero));
    // is the input denormalized
    assign XDenorm = ~XExpNonZero & ~XFracZero;
    assign ZDenorm = ~ZExpNonZero & ~ZFracZero;
endmodule
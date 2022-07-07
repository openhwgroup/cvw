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
    input logic  [`FMTBITS-1:0]     FmtE,       // format signal 00 - single 01 - double 11 - quad 10 - half
    output logic                    XSgnE, YSgnE, ZSgnE,    // sign bits of XYZ
    output logic [`NE-1:0]          XExpE, YExpE, ZExpE,    // exponents of XYZ (converted to largest supported precision)
    output logic [`NF:0]            XManE, YManE, ZManE,    // mantissas of XYZ (converted to largest supported precision)
    output logic                    XNaNE, YNaNE, ZNaNE,    // is XYZ a NaN
    output logic                    XSNaNE, YSNaNE, ZSNaNE, // is XYZ a signaling NaN
    output logic                    XDenormE, ZDenormE,   // is XYZ denormalized
    output logic                    XZeroE, YZeroE, ZZeroE,         // is XYZ zero
    output logic                    XInfE, YInfE, ZInfE,            // is XYZ infinity
    output logic                    XExpMaxE                        // does X have the maximum exponent (NaN or Inf)
);
 
    logic [`NF-1:0] XFracE, YFracE, ZFracE; //Fraction of XYZ
    logic           XExpNonZero, YExpNonZero, ZExpNonZero; // is the exponent of XYZ non-zero
    logic           XFracZero, YFracZero, ZFracZero; // is the fraction zero
    logic           YExpMaxE, ZExpMaxE;  // is the exponent all 1s
    
    unpackinput unpackinputX (.In(X), .FmtE, .Sgn(XSgnE), .Exp(XExpE), .Man(XManE), 
                            .NaN(XNaNE), .SNaN(XSNaNE), .ExpNonZero(XExpNonZero),
                            .Zero(XZeroE), .Inf(XInfE), .ExpMax(XExpMaxE), .FracZero(XFracZero));

    unpackinput unpackinputY (.In(Y), .FmtE, .Sgn(YSgnE), .Exp(YExpE), .Man(YManE), 
                            .NaN(YNaNE), .SNaN(YSNaNE), .ExpNonZero(YExpNonZero),
                            .Zero(YZeroE), .Inf(YInfE), .ExpMax(YExpMaxE), .FracZero(YFracZero));

    unpackinput unpackinputZ (.In(Z), .FmtE, .Sgn(ZSgnE), .Exp(ZExpE), .Man(ZManE), 
                            .NaN(ZNaNE), .SNaN(ZSNaNE), .ExpNonZero(ZExpNonZero),
                            .Zero(ZZeroE), .Inf(ZInfE), .ExpMax(ZExpMaxE), .FracZero(ZFracZero));
    // is the input denormalized
    assign XDenormE = ~XExpNonZero & ~XFracZero;
    assign ZDenormE = ~ZExpNonZero & ~ZFracZero;
endmodule
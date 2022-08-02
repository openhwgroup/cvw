///////////////////////////////////////////
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: Floating point multiply-accumulate of configurable size
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

module fma(
    input logic                 Xs, Ys, Zs,    // input's signs
    input logic  [`NE-1:0]      Xe, Ye, Ze,    // input's biased exponents in B(NE.0) format
    input logic  [`NF:0]        Xm, Ym, Zm,    // input's significands in U(0.NF) format
    input logic                 XZero, YZero, ZZero, // is the input zero
    input logic  [2:0]          OpCtrl,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [`FMTBITS-1:0] Fmt,       // format of the result single double half or quad
    output logic [`NE+1:0]      Pe,       // the product's exponent B(NE+2.0) format; adds 2 bits to allow for size of number and negative sign
    output logic                ZmSticky,  // sticky bit that is calculated during alignment
    output logic                KillProd,  // set the product to zero before addition if the product is too small to matter
    output logic [3*`NF+5:0]    Sm,           // the positive sum's significand
    output logic                NegSum,        // was the sum negitive
    output logic                InvA,          // Was A inverted for effective subtraction (P-A or -P+A)
    output logic                As,       // the aligned addend's sign (modified Z sign for other opperations)
    output logic                Ps,          // the product's sign
    output logic                Ss,          // the sum's sign
    output logic [`NE+1:0]      Se,
    output logic [$clog2(3*`NF+7)-1:0]          SCnt        // normalization shift count
    );

    logic [2*`NF+1:0]   Pm;           // the product's significand in U(2.2Nf) format
    logic [3*`NF+5:0]   Am;     // addend aligned's mantissa for addition in U(NF+5.2NF+1)
    logic [3*`NF+5:0]   AmInv;   // aligned addend's mantissa possibly inverted
    logic [2*`NF+1:0]   PmKilled;      // the product's mantissa possibly killed
    ///////////////////////////////////////////////////////////////////////////////
    // Calculate the product
    //      - When multipliying two fp numbers, add the exponents
    //      - Subtract the bias (XExp + YExp has two biases, one from each exponent)
    //      - If the product is zero then kill the exponent
    //      - Multiply the mantissas
    ///////////////////////////////////////////////////////////////////////////////
   

   // calculate the product's exponent 
    fmaexpadd expadd(.Fmt, .Xe, .Ye, .XZero, .YZero, .Pe);

    // multiplication of the mantissa's
    fmamult mult(.Xm, .Ym, .Pm);
   
    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////
    // calculate the signs and take the opperation into account
    fmasign sign(.OpCtrl, .Xs, .Ys, .Zs, .Ps, .As);

    fmaalign align(.Ze, .Zm, .XZero, .YZero, .ZZero, .Xe, .Ye,
                .Am, .ZmSticky, .KillProd);
                        


    // ///////////////////////////////////////////////////////////////////////////////
    // // Addition/LZA
    // ///////////////////////////////////////////////////////////////////////////////
        
    fmaadd add(.Am, .Pm, .Ze, .Pe, .Ps, .As, .KillProd, .ZmSticky, .AmInv, .PmKilled, .NegSum, .InvA, .Sm, .Se, .Ss);

    fmalza #(3*`NF+6) lza(.A(AmInv), .Pm({PmKilled, 1'b0, InvA&Ps&ZmSticky&KillProd}), .Cin(InvA & ~(ZmSticky & ~KillProd)), .sub(InvA), .SCnt);
endmodule



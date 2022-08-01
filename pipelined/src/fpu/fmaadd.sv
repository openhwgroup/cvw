///////////////////////////////////////////
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: FMA significand adder
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

module fmaadd(
    input logic  [3*`NF+5:0]    Am, // aligned addend's mantissa for addition in U(NF+5.2NF+1)
    input logic  [2*`NF+1:0]    Pm,       // the product's mantissa
    input logic                 Ps, As,// the product sign and the alligend addeded's sign (Modified Z sign for other opperations)
    input logic                 KillProd,      // should the product be set to 0
    input logic                 ZmSticky,
    input logic  [`NE-1:0]      Ze,
    input logic  [`NE+1:0]      Pe,
    output logic [3*`NF+6:0]    AmInv,  // aligned addend possibly inverted
    output logic [2*`NF+1:0]    PmKilled,     // the product's mantissa possibly killed
    output logic                NegSum,        // was the sum negitive
    output logic                InvA,          // do you invert the aligned addend
    output logic                Ss,          
    output logic [`NE+1:0]      Se,
    output logic [3*`NF+5:0]    Sm           // the positive sum
);
    logic [3*`NF+6:0]    PreSum, NegPreSum; // possibly negitive sum

    ///////////////////////////////////////////////////////////////////////////////
    // Addition
    ///////////////////////////////////////////////////////////////////////////////
   
    // Negate Z  when doing one of the following opperations:
    //      -prod +  Z
    //       prod -  Z
    assign InvA = As ^ Ps;

    // Choose an inverted or non-inverted addend - the one has to be added now for the LZA
    assign AmInv = InvA ? {1'b1, ~Am} : {1'b0, Am};
    // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
    assign PmKilled = Pm&{2*`NF+2{~KillProd}};
    // Do the addition
    //      - calculate a positive and negitive sum in parallel
    //              Zsticky             Psticky
    // PreSum    -1 = don't add 1     +1 = add 2
    // NegPreSum +1 = add 2           -1 = don't add 1
    // for NegPreSum the product is set to -1 whenever the product is killed, therefore add 1, 2 or 0
    assign PreSum = {{`NF+3{1'b0}}, PmKilled, 1'b0, InvA&ZmSticky&KillProd} + AmInv + {{3*`NF+6{1'b0}}, InvA&~((ZmSticky&~KillProd))};
    assign NegPreSum = {1'b0, Am} + {{`NF+3{1'b1}}, ~PmKilled, 2'b11} + {(3*`NF+5)'(0), ZmSticky&~KillProd, ~(ZmSticky)};
     
    // Is the sum negitive
    assign NegSum = PreSum[3*`NF+6];

    // Choose the positive sum and accompanying LZA result.
    assign Sm = NegSum ? NegPreSum[3*`NF+5:0] : PreSum[3*`NF+5:0];
    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign Ss = NegSum^Ps; //*** move to execute stage
    assign Se = KillProd ? {2'b0, Ze} : Pe;
endmodule

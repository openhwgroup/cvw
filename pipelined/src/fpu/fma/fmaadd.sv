///////////////////////////////////////////
// fmaadd.sv
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
    input logic  [3*`NF+3:0]    Am, // aligned addend's mantissa for addition in U(NF+5.2NF+1)
    input logic  [2*`NF+1:0]    Pm,       // the product's mantissa
    input logic                 Ps, // the product sign and the alligend addeded's sign (Modified Z sign for other opperations)
    input logic                InvA,          // invert the aligned addend
    input logic                 KillProd,      // should the product be set to 0
    input logic                 ASticky,
    input logic  [`NE-1:0]      Ze,
    input logic  [`NE+1:0]      Pe,
    output logic [3*`NF+3:0]    AmInv, // aligned addend possibly inverted
    output logic [2*`NF+1:0]    PmKilled,     // the product's mantissa possibly killed
    output logic                Ss,          
    output logic [`NE+1:0]      Se,
    output logic [3*`NF+3:0]    Sm          // the positive sum
);
    logic [3*`NF+3:0]    PreSum, NegPreSum; // possibly negitive sum
    logic [3*`NF+5:0]    PreSumdebug, NegPreSumdebug; // possibly negitive sum
    logic                NegSum;        // was the sum negitive
    logic                NegSumdebug;        // was the sum negitive

    ///////////////////////////////////////////////////////////////////////////////
    // Addition
    ///////////////////////////////////////////////////////////////////////////////
   
    // Choose an inverted or non-inverted addend.  Put carry into adder/LZA for addition
    assign AmInv = InvA ? ~Am : Am;
    // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
    assign PmKilled = KillProd ? '0 : Pm;
    // Do the addition
    //      - calculate a positive and negitive sum in parallel
    // if there was a small negitive number killed in the alignment stage one needs to be subtracted from the sum
    //      prod - addend where some of the addend is put into the sticky bit then don't add +1 from negation 
    //          ie ~(InvA&ASticky&~KillProd)&InvA = (~ASticky|KillProd)&InvA
    //      addend - prod where product is killed (and not exactly zero) then don't add +1 from negation 
    //          ie ~(InvA&ASticky&KillProd)&InvA = (~ASticky|~KillProd)&InvA
    //          in this case this result is only ever selected when InvA=1 so we can remove &InvA
    assign {NegSum, PreSum} = {{`NF+2{1'b0}}, PmKilled, 1'b0} + {InvA, AmInv} + {{3*`NF+4{1'b0}}, (~ASticky|KillProd)&InvA};
    assign NegPreSum = Am + {{`NF+1{1'b1}}, ~PmKilled, 1'b0} + {(3*`NF+2)'(0), ~ASticky|~KillProd, 1'b0};
     
    // Choose the positive sum and accompanying LZA result.
    assign Sm = NegSum ? NegPreSum : PreSum;
    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign Ss = NegSum^Ps; 
    assign Se = KillProd ? {2'b0, Ze} : Pe;
endmodule

///////////////////////////////////////////
// fdivsqrtfgen2.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 2 F Addend Generator
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

module fdivsqrtfgen2 (
  input  logic sp, sz,
  input  logic [`DIVb+1:0] C,
  input  logic [`DIVb:0] U, UM,
  output logic [`DIVb+3:0] F
);
  logic [`DIVb+3:0] FP, FN, FZ;
  logic [`DIVb+3:0] SExt, SMExt, CExt;

  assign SExt = {3'b0, U};
  assign SMExt = {3'b0, UM};
  assign CExt = {2'b11, C}; // extend C from Q2.k to Q4.k

  // Generate for both positive and negative bits
  assign FP = ~(SExt << 1) & CExt;
  assign FN = (SMExt << 1) | (CExt & ~(CExt << 2));
  assign FZ = '0;

  // Choose which adder input will be used

  always_comb
    if (sp)       F = FP;
    else if (sz)  F = FZ;
    else          F = FN;

endmodule

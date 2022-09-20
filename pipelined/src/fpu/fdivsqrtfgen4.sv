///////////////////////////////////////////
// fdivsqrtfgen4.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
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

module fdivsqrtfgen4 (
  input  logic [3:0] s,
  input  logic [`DIVb+3:0] C, U, UM,
  output logic [`DIVb+3:0] F
);
  logic [`DIVb+3:0] F2, F1, F0, FN1, FN2;
  
  // Generate for both positive and negative bits
  assign F2  = (~U << 2) & (C << 2);
  assign F1  = ~(U << 1) & C;
  assign F0  = '0;
  assign FN1 = (UM << 1) | (C & ~(C << 3));
  assign FN2 = (UM << 2) | ((C << 2)&~(C << 4));

  // Choose which adder input will be used

  always_comb
    if (s[3])       F = F2;
    else if (s[2])  F = F1;
    else if (s[1])  F = FN1;
    else if (s[0])  F = FN2;
    else            F = F0;
endmodule
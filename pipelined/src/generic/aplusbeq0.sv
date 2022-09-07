///////////////////////////////////////////
// aplusbeq0.sv
//
// Written: David_Harris@hmc.edu 9/7/2022
// Modified:
//
// Purpose: Determine if A+B = 0.  Used in FP divider.
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

module aplusbeq0 #(parameter WIDTH = 8) (
  input  logic [WIDTH-1:0] a, b,
  output logic             zero);

  logic [WIDTH-1:0] x;
  logic [WIDTH-1:0] orshift;

  // The sum is zero if the bitwise XOR is equal to the bitwise OR shifted left by 1, for all columns
  // *** explain, cite book

  assign x = a ^ b;
  assign orshift = {a[WIDTH-2:0] | b[WIDTH-2:0], 1'b0};
  assign zero = (x == orshift);
endmodule
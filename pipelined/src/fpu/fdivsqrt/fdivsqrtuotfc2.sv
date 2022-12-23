///////////////////////////////////////////
// fdivsqrtuotfc2.sv
//
// Written: me@KatherineParry.com, cturek@hmc.edu 
// Modified:7/14/2022
//
// Purpose: Radix 2 unified on-the-fly converter
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

///////////////////////////////
// Unified OTFC, Radix 2 //
///////////////////////////////
module fdivsqrtuotfc2(
  input  logic         up, un, swap,
  input  logic [`DIVb+1:0] C,
  input logic [`DIVb:0] U, UM,
  output logic [`DIVb:0] UNext, UMNext
);
  //  The on-the-fly converter transfers the divsqrt
  //  bits to the quotient as they come.
  logic [`DIVb:0] K;
  logic unSwap, upSwap;
  
  // Check for swap (int div only)
  assign unSwap = swap ? up : un;
  assign upSwap = swap ? un : up;

  assign K = (C[`DIVb:0] & ~(C[`DIVb:0] << 1));

  always_comb begin
    if (upSwap) begin
      UNext  = U | K;
      UMNext = U;
    end else if (unSwap) begin
      UNext  = UM | K;
      UMNext = UM;
    end else begin // If up and un are not true, then uz is
      UNext  = U;
      UMNext = UM | K;
    end
  end
endmodule

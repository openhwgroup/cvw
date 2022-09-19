///////////////////////////////////////////
// otfc.sv
//
// Written: me@KatherineParry.com, cturek@hmc.edu 
// Modified:7/14/2022
//
// Purpose: On the fly conversion
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
// Un ified OTFC, Radix 2 //
///////////////////////////////
module uotfc2(
  input  logic         sp, sz,
  input  logic [`DIVb+1:0] C,
  input logic [`DIVb:0] U, UM,
  output logic [`DIVb:0] UNext, UMNext
);
  //  The on-the-fly converter transfers the divsqrt
  //  bits to the quotient as they come.
  logic [`DIVb:0] K;

  assign K = (C[`DIVb:0] & ~(C[`DIVb:0] << 1));

  always_comb begin
    if (sp) begin
      UNext  = U | K;
      UMNext = U;
    end else if (sz) begin
      UNext  = U;
      UMNext = UM | K;
    end else begin        // If sp and sz are not true, then sn is
      UNext  = UM | K;
      UMNext = UM;
    end 
  end

endmodule

///////////////////////////////
// Unified OTFC, Radix 4 //
///////////////////////////////
module uotfc4(
  input  logic [3:0]   s,
  input  logic         Sqrt,
  input  logic [`DIVb:0] U, UM,
  input  logic [`DIVb:0] C,
  output logic [`DIVb:0] UNext, UMNext
);
  //  The on-the-fly converter transfers the square root 
  //  bits to the quotient as they come.
  //  Use this otfc for division and square root.

  logic [`DIVb:0] K1, K2, K3;
  assign K1 = (C&~(C << 1));        // K
  assign K2 = ((C << 1)&~(C << 2)); // 2K
  assign K3 = (C & ~(C << 2));      // 3K

  always_comb begin
    if (s[3]) begin
      UNext  = U | K2;
      UMNext = U | K1;
    end else if (s[2]) begin
      UNext  = U | K1;
      UMNext = U;
    end else if (s[1]) begin
      UNext  = UM | K3;
      UMNext = UM | K2;
    end else if (s[0]) begin
      UNext  = UM | K2;
      UMNext = UM | K1;
    end else begin        // If sp and sn are not true, then sz is
      UNext  = U;
      UMNext = UM | K3;
    end 
  end

endmodule

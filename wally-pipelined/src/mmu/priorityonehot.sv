///////////////////////////////////////////
// priorityonehot.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 7 April 2021
// Modified: Teo Ene 15 Apr 2021:
//              Temporarily removed paramterized priority encoder for non-parameterized one
//              To get synthesis working quickly
//           Kmacsaigoren@hmc.edu 28 May 2021:
//              Added working version of parameterized priority encoder. 
//           David_Harris@Hmc.edu switched to one-hot output
//
// Purpose: Priority circuit to choose most significant one-hot output
//
// A component of the Wally configurable RISC-V project.
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module priorityonehot #(parameter ENTRIES = 8) (
  input  logic  [ENTRIES-1:0] a,
  output logic  [ENTRIES-1:0] y
);

  /* verilator lint_off UNOPTFLAT */

  logic [ENTRIES-1:0] nolower;

  // generate thermometer code mask
  prioritythemometer #(ENTRIES) maskgen(.a({a[ENTRIES-2:0], 1'b1}), .y(nolower));
  // genvar i;
  // generate
  //   assign nolower[0] = 1'b1;
  //   for (i=1; i<ENTRIES; i++) begin:therm
  //     assign nolower[i] = nolower[i-1] & ~a[i-1];
  //   end
  // endgenerate
  // *** replace mask generation logic ^^^ with priority thermometer


  assign y = a & nolower;

  /* verilator lint_on UNOPTFLAT */

endmodule

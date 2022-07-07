///////////////////////////////////////////
//
// Written: David Harris
// Modified: 11 September 2021
//
// Purpose: Recurrence-based SRT Division and Square Root
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

// Bit counts:
// Inputs are originally normalized floating point numbers with NF fractional bits and a leading 1 integer bit
// x is right shifted by up to 2 to be in the range of 1/4 <= x < 1/2 for divide, 1/4 <= x < 1 for sqrt
// Hence, x now has NF+2 fractional bits and 0 integer bits
// d is right shifted by 1 to be in the range of 1/2 <= d < 1.  It thus has NF+1 fractional bits and 0 integer bits
// q is eventually in the range of 1/4 < q < 1 and hence needs NF+2 bits to keep NF bits when normalized, plus some*** more bits for rounding
// The partial 

/*  
module fpudivsqrtrecurcore (
    input logic                 clk,
    input logic                 reset,
    input logic                 start, // start a computation
    input logic                 busy, // computation running
    input logic                 fmt, // precision 1 = double 0 = single
    input logic [`NF+1:0]         x,     // in range 1/4 <= x < 1/2 for divide, 1/4 <=x < 1 for sqrt
    input logic [`NF+1:0]         din,    // in range 1/2 <= d < 1 for divide
     input logic                 FDiv, FSqrt, // *** not yet used
 	output logic [`FLEN-1:0]    FDivSqrtRecurRes    // result
  );

  assign FDivSqrtRecurRes = 0;
 
  logic [***] d, ws, wsout, wsnext, wc, wcout, wcnext;
  logic [1:0] q; // 00 = 0, 01 = 1, 10 = -1

  // Radix-2 SRT Division
  
  // registers for divisor and partial remainder
  flopen #(NF+1) dreg(clk, start, din, d);
  mux2 #(NF+1) wsmux(wsout, x, start, wsnext);
  flopen #(NF+1) wsreg(clk, busy, wsnext, ws);
  mux2 #(NF+1) wcmux(wcout, 0, start, wcnext);
  flopen #(NF+1) wcreg(clk, busy, wcnext, wc);

  // quotient selection
  qsel qsel(ws[***4bits], wc[***], q);
  
  // partial remainder update
  always_comb begin // select -d * q to add to partial remainder
      if      (q[1]) dq = d;
      else if (q[0]) dq = ~d;
      else           dq = 0;
  end
  csa #(***) csa(ws, wc, dq, q[1], wsout, wcout);


endmodule
*/

/*
module csa #(parameter N=4) (
    input logic [N-1:0] sin, cin, ain,
    input logic carry,
    output logic [N-1:0] sum, cout
);

    logic [N-1:0] c;

    assign c = {cin[N-2:0], carry}; // shift carries left and inject optional 1 into lsb
    assign sum = sin ^ ain ^ c;
    assign cout = sin & ain | sin & c | ain & c;
endmodule
*/

module qsel( // radix 2 SRT division quotient selection
    input logic [3:0] wc, ws,
    output logic [1:0] q
);

endmodule




///////////////////////////////////////////
// intdivrestoringstep.sv
//
// Written: David_Harris@hmc.edu 2 October 2021
// Modified: 
//
// Purpose: Restoring integer division using a shift register and subtractor
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

/* verilator lint_off UNOPTFLAT */

module intdivrestoringstep(
  input  logic [`XLEN-1:0] W, XQ, DAbsB,
  output logic [`XLEN-1:0] WOut, XQOut);

  logic [`XLEN-1:0] WShift, WPrime;
  logic qi, qib;
  
  assign {WShift, XQOut} = {W[`XLEN-2:0], XQ, qi};  // shift W and X/Q left, insert quotient bit at bottom
  adder #(`XLEN+1) wdsub({1'b0, WShift}, {1'b1, DAbsB}, {qib, WPrime}); // effective subtractor, carry out determines quotient bit
  assign qi = ~qib;
  mux2 #(`XLEN) wrestoremux(WShift, WPrime, qi, WOut); // if quotient is zero, restore W
endmodule

/* verilator lint_on UNOPTFLAT */

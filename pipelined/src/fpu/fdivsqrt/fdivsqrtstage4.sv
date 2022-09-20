///////////////////////////////////////////
// fdivsqrtstage4.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, Cedar Turek
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit stage
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
module fdivsqrtstage4 (
  input logic [`DIVN-2:0] D,
  input logic [`DIVb+3:0]  DBar, D2, DBar2,
  input logic [`DIVb:0] U, UM,
  input logic [`DIVb+3:0]  WS, WC,
  input logic [`DIVb+1:0] C,
  output logic [`DIVb+1:0] CNext,
  input logic SqrtM, j1,
  output logic un,
  output logic [`DIVb:0] UNext, UMNext, 
  output logic [`DIVb+3:0]  WSA, WCA
);
 /* verilator lint_on UNOPTFLAT */

  logic [`DIVb+3:0]  Dsel;
  logic [3:0]     u;
  logic [`DIVb+3:0] F;
  logic [`DIVb+3:0] AddIn;
  logic [4:0] Smsbs;
  logic CarryIn;
  assign CNext = {2'b11, C[`DIVb+1:2]};

  // Digit Selection logic
  // u encoding:
	// 1000 = +2
	// 0100 = +1
	// 0000 =  0
	// 0010 = -1
	// 0001 = -2
  assign Smsbs = U[`DIVb:`DIVb-4];
  fdivsqrtqsel4 qsel4(.D, .Smsbs, .WS, .WC, .Sqrt(SqrtM), .j1, .u);
  fdivsqrtfgen4 fgen4(.u, .C({2'b11, CNext}), .U({3'b000, U}), .UM({3'b000, UM}), .F);

  always_comb
  case (u)
    4'b1000: Dsel = DBar2;
    4'b0100: Dsel = DBar;
    4'b0000: Dsel = '0;
    4'b0010: Dsel = {3'b0, 1'b1, D, {`DIVb-`DIVN+1{1'b0}}};
    4'b0001: Dsel = D2;
    default: Dsel = 'x;
  endcase

  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  assign AddIn = SqrtM ? F : Dsel;
  assign CarryIn = ~SqrtM & (u[3] | u[2]); // +1 for 2's complement of -D and -2D 
  csa #(`DIVb+4) csa(WS, WC, AddIn, CarryIn, WSA, WCA);
 
  fdivsqrtuotfc4 fdivsqrtuotfc4(.u, .Sqrt(SqrtM), .C(CNext[`DIVb:0]), .U, .UM, .UNext, .UMNext);

  assign un = 0; // unused for radix 4
endmodule



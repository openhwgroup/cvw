///////////////////////////////////////////
// fdivsqrtstage2.sv
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
module fdivsqrtstage2 (
  input logic [`DIVN-2:0] D,
  input logic [`DIVb+3:0]  DBar, D2, DBar2,
  input logic [`DIVb:0] Q, QM,
  input logic [`DIVb:0] S, SM,
  input logic [`DIVb+3:0]  WS, WC,
  input logic [`DIVb-1:0] C,
  input logic SqrtM,
  output logic [`DIVb:0] QNext, QMNext, 
  output logic qn,
  output logic [`DIVb:0] SNext, SMNext, 
  output logic [`DIVb+3:0]  WSA, WCA
);
 /* verilator lint_on UNOPTFLAT */

  logic [`DIVb+3:0]  Dsel;
  logic qp, qz;
  logic [`DIVb+3:0] F;
  logic [`DIVb+3:0] AddIn;

  // Qmient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  // q encoding:
	// 1000 = +2
	// 0100 = +1
	// 0000 =  0
	// 0010 = -1
	// 0001 = -2
  qsel2 qsel2(WS[`DIVb+3:`DIVb], WC[`DIVb+3:`DIVb], qp, qz, qn);
  fgen2 fgen2(.sp(qp), .sz(qz), .C, .S, .SM, .F);

  assign Dsel = {`DIVb+4{~qz}}&(qp ? DBar : {3'b0, 1'b1, D, {`DIVb-`DIVN+1{1'b0}}});
  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  assign AddIn = SqrtM ? F : Dsel;
  csa #(`DIVb+4) csa(WS, WC, AddIn, qp&~SqrtM, WSA, WCA);

  // *** dh 8/29/22: will need to trim down to just sotfc
  otfc2 otfc2(.qp, .qz, .Q, .QM, .QNext, .QMNext);
  sotfc2 sotfc2(.sp(qp), .sz(qz), .C, .S, .SM, .SNext, .SMNext);
endmodule



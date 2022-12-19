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
  input  logic [`DIVb-1:0] D,
  input  logic [`DIVb+3:0]  DBar, 
  input  logic [`DIVb:0] U, UM,
  input  logic [`DIVb+3:0]  WS, WC,
  input  logic [`DIVb+1:0] C,
  input  logic SqrtE,
  input  logic OTFCSwap, MDUE,
  output logic un,
  output logic [`DIVb+1:0] CNext,
  output logic [`DIVb:0] UNext, UMNext, 
  output logic [`DIVb+3:0]  WSNext, WCNext
);
 /* verilator lint_on UNOPTFLAT */

  logic [`DIVb+3:0]  Dsel;
  logic up, uz;
  logic [`DIVb+3:0] F;
  logic [`DIVb+3:0] AddIn;
  logic [`DIVb+3:0]  WSA, WCA;

  // Qmient Selection logic
  // Given partial remainder, select digit of +1, 0, or -1 (up, uz, un)
  // q encoding:
	// 1000 = +2
	// 0100 = +1
	// 0000 =  0
	// 0010 = -1
	// 0001 = -2
  fdivsqrtqsel2 qsel2(WS[`DIVb+3:`DIVb], WC[`DIVb+3:`DIVb], OTFCSwap, up, uz, un);

  // Sqrt F generation
  fdivsqrtfgen2 fgen2(.up, .uz, .C(CNext), .U, .UM, .F);

  // Divisor multiple
  always_comb
    if      (up) Dsel = DBar;
    else if (uz) Dsel = '0; // qz
    else         Dsel = {3'b000, 1'b1, D}; // un

  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  assign AddIn = (SqrtE & ~MDUE) ? F : Dsel;
  csa #(`DIVb+4) csa(WS, WC, AddIn, up&~(SqrtE & ~MDUE), WSA, WCA);
  assign WSNext = WSA << 1;
  assign WCNext = WCA << 1;

  // Shift thermometer code C
  assign CNext = {1'b1, C[`DIVb+1:1]};

  // Unified On-The-Fly Converter to accumulate result
  fdivsqrtuotfc2 uotfc2(.up, .uz, .C(CNext), .U, .UM, .UNext, .UMNext);
endmodule



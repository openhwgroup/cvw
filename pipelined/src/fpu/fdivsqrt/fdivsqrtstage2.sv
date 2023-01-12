///////////////////////////////////////////
// fdivsqrtstage2.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: radix-2 divsqrt recurrence stage
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
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
  fdivsqrtqsel2 qsel2(WS[`DIVb+3:`DIVb], WC[`DIVb+3:`DIVb], up, uz, un);

  // Sqrt F generation.  Extend C, U, UM to Q4.k
  fdivsqrtfgen2 fgen2(.up, .uz, .C({2'b11, CNext}), .U({3'b000, U}), .UM({3'b000, UM}), .F);

  // Divisor multiple
  always_comb
    if      (up) Dsel = DBar;
    else if (uz) Dsel = '0;
    else         Dsel = {4'b0001, D}; // un

  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  mux2 #(`DIVb+4) addinmux(Dsel, F, SqrtE, AddIn);
  csa #(`DIVb+4) csa(WS, WC, AddIn, up&~SqrtE, WSA, WCA);
  assign WSNext = WSA << 1;
  assign WCNext = WCA << 1;

  // Shift thermometer code C
  assign CNext = {1'b1, C[`DIVb+1:1]};

  // Unified On-The-Fly Converter to accumulate result
  fdivsqrtuotfc2 uotfc2(.up, .un, .C(CNext), .U, .UM, .UNext, .UMNext);
endmodule



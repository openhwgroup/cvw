///////////////////////////////////////////
// fsgninj.sv
//
// Written: me@KatherineParry.com
// Modified: 6/23/2021
//
// Purpose: FPU Sign Injection instructions
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

module fsgninj (  
	input  logic        		    Xs, Ys,	// X and Y sign bits
	input  logic [`FLEN-1:0] 	  X,		  // X
	input  logic [`FMTBITS-1:0]	Fmt,	  // format
	input  logic [1:0]  		    OpCtrl,	// operation control
	output logic [`FLEN-1:0] 	  SgnRes	// result
);

	logic ResSgn;	// result sign

	// OpCtrl:
	// 		00 - fsgnj  - directly copy over sign value of Y
	// 		01 - fsgnjn - negate sign value of Y
	// 		10 - fsgnjx - XOR sign values of X and Y
	
	// calculate the result's sign
	assign ResSgn = (OpCtrl[1] ? Xs : OpCtrl[0]) ^ Ys;
	
	// format final result based on precision
	//    - uses NaN-blocking format
	//        - if there are any unsused bits the most significant bits are filled with 1s
	
  if (`FPSIZES == 1)
		assign SgnRes = {ResSgn, X[`FLEN-2:0]};
  else if (`FPSIZES == 2)
		assign SgnRes = {~Fmt|ResSgn, X[`FLEN-2:`LEN1], Fmt ? X[`LEN1-1] : ResSgn, X[`LEN1-2:0]};
  else if (`FPSIZES ==  3) begin
		logic [2:0] SgnBits;
    always_comb
      case (Fmt)
        `FMT:    SgnBits = {ResSgn, X[`LEN1-1], X[`LEN2-1]};
  	    `FMT1:   SgnBits = {1'b1, ResSgn, X[`LEN2-1]};
        `FMT2:   SgnBits = {2'b11, ResSgn};
        default: SgnBits = {3{1'bx}};
      endcase
		assign SgnRes = {SgnBits[2], X[`FLEN-2:`LEN1], SgnBits[1], X[`LEN1-2:`LEN2], SgnBits[0], X[`LEN2-2:0]};
	end else if (`FPSIZES == 4) begin
		logic [3:0] SgnBits;
    always_comb
      case (Fmt)
        `Q_FMT: SgnBits = {ResSgn, X[`D_LEN-1], X[`S_LEN-1], X[`H_LEN-1]};
        `D_FMT: SgnBits = {1'b1, ResSgn, X[`S_LEN-1], X[`H_LEN-1]};
        `S_FMT: SgnBits = {2'b11, ResSgn, X[`H_LEN-1]};
        `H_FMT: SgnBits = {3'b111, ResSgn};
      endcase
		assign SgnRes = {SgnBits[3], X[`Q_LEN-2:`D_LEN], SgnBits[2], X[`D_LEN-2:`S_LEN], SgnBits[1], X[`S_LEN-2:`H_LEN], SgnBits[0], X[`H_LEN-2:0]};
	end

endmodule

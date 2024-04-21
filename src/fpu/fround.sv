///////////////////////////////////////////
// fround.sv
//
// Written: David_Harris@hmc.edu
// Modified: 4/21/2024
//
// Purpose: Floating-point round to integer for Zfa
// 
// Documentation: RISC-V System on Chip Design Chapter 16
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
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

module fround import cvw::*;  #(parameter cvw_t P) (
  input  logic                    Xs,           // input's sign
  input  logic [P.NE-1:0]         Xe,           // input's exponent
  input  logic [P.NF:0]           Xm,           // input's fraction
  input  logic [P.FMTBITS-1:0]    Fmt,          // the input's precision (11=quad 01=double 00=single 10=half)
);

  logic [P.NE-2:0] Bias;
  logic [P.NE-1:0] E;

  //////////////////////////////////////////
  // Determine exponent bias according to the format
  //////////////////////////////////////////
  // *** replicated from fdivsqrt; find a way to share
  
  if (P.FPSIZES == 1) begin
    assign Bias = (P.NE-1)'(P.BIAS); 

  end else if (P.FPSIZES == 2) begin
    assign Bias = Fmt ? (P.NE-1)'(P.BIAS) : (P.NE-1)'(P.BIAS1); 

  end else if (P.FPSIZES == 3) begin
    always_comb
      case (Fmt)
        P.FMT: Bias  =  (P.NE-1)'(P.BIAS);
        P.FMT1: Bias = (P.NE-1)'(P.BIAS1);
        P.FMT2: Bias = (P.NE-1)'(P.BIAS2);
        default: Bias = 'x;
      endcase

  end else if (P.FPSIZES == 4) begin        
  always_comb
    case (Fmt)
      2'h3: Bias =  (P.NE-1)'(P.Q_BIAS);
      2'h1: Bias =  (P.NE-1)'(P.D_BIAS);
      2'h0: Bias =  (P.NE-1)'(P.S_BIAS);
      2'h2: Bias =  (P.NE-1)'(P.H_BIAS);
    endcase
  end

  // Unbiased exponent
  assign E = Xe - Bias;

  //////////////////////////////////////////
  // Compute LSB, rounding bit and Sticky bit mask (TMask)
  //      if (E < 0)					// negative exponents round to 0 or 1.  
  //              L' = 0      // LSB = 0
  //              if (E = -1) R' = 1, TMask = 0.1111...111	// if (E = -1) 0.5  X < 1.  Round bit is 1
  //              else R' = 0; TMask = 1.1111...111  	// if (E < -1), X < 0.5.  Round bit is 0
  //      else					// positive exponents truncate fraction and may add 1
  //              IMask = 1.0000…000 >>> E  		// (in U1.Nf form); implies thermometer code generator
  //              TMask = ~(IMask >>> 1) 			// 0.01111…111 >> E
  //              HotE = IMask & ~(IMask << 1) 		// a 1 in column E, where 0 is the integer bit, 
 	//				// 1 is the most significant fractional bit, etc.
  //              HotEP1 = HotE >> 1			// a 1 in column E+1
  //              L' = OR(Xm & HotE) 			// Xm[E], where Xm[0] is the integer bit, 
 	//				// Xm[1] is the most significant fractional bit, etc.
  //              R' = OR(Xm & HotEP1)			// Xm[E+1] 
  //              TRUNC = Xm & IMask			// Truncated fraction, corresponds to truncated integer value
  //              RND =  TRUNC + HotE 			// TRUNC + (1 >> E), corresponds to next integer
  //      T' = OR(Xm & TMask)				// T’ = OR(Xm[E+2:Nf]) if E >= 0, OR(Xf) if E = -1, 1 if E < -1
  //////////////////////////////////////////

  // Check if exponent is negative and -1
  assign Elt0 = (E < 0);
  assign Eeqm1 = (E == -1);

  assign Rneg = Elt0;
  mux2
   
  // 
  // if (E = -1) R' = 1, TMask = 0.1111...111	// if (E = -1) 0.5  X < 1.  Round bit is 1
                else R' = 0; TMask = 1.1111...111  	// if (E < -1), X < 0.5.  Round bit is 0


  mux


endmodule

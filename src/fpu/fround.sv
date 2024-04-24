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
  input  logic                    XNaN,         // X is NaN
  input  logic                    XSNaN,        // X is Signalling NaN
  input  logic                    XZero,        // X is Zero
  input  logic [P.FMTBITS-1:0]    Fmt          // the input's precision (11=quad 01=double 00=single 10=half)
);

 
  logic [P.NE-2:0] Bias;
  logic [P.NE-1:0] E;
  logic [P.NF:0] Imask, Tmasknonneg, Tmaskneg, Tmask, HotE, HotEP1, Trunc, Rnd;
  logic Lnonneg, Lp, Rnonneg, Rp, Tp;

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

/*

  // Unbiased exponent
  assign E = Xe - Bias;

  //////////////////////////////////////////
  // Compute LSB L', rounding bit R' and Sticky bit T'
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

  // Logic for nonnegative mask and rounding bits
  assign Imask = {1'b1, {P.NF{1'b0}}} >>> E;
  assign Tmasknonneg = ~(IMask >>> 1'b1);
  assign HotE = IMask & !(IMask << 1'b1);
  assign HotEP1 = HotE >> 1'b1;
  assign Lnonneg = |(Xm & HotE);
  assign Rnonneg = |(Xm & HotEP1);
  assign Trunc = Xm & Imask;
  assign Rnd = Trunc + HotE;
   
  // mux and AND-OR logic to select final rounding bits
  mux2 #(1) Lmux(Lnonneg, 1'b0, Elt0, Lp);
  mux2 #(1) Rmux(Rnonneg, Eeqm1, Elt0, Rp);
  assign Tmaskneg = {~Eeqm1, {P.NF{1'b1}}}; // 1.11111 or 0.11111
  mux2 #(P.NF+1) Tmaskmux(Tmasknonneg, Tmaskneg, Elt0, Tmask);
  assign Tp = |(Xm & Tmask);


  ///////////////////////////
  // Rounding, flags, special Cases 
  //      Flags = 0						// unless overridden later
  //      if (X is NaN)
  //              W = Canonical NaN
  //              Invalid = (X is signaling NaN)
  //      else if (E >= Nf or X is +/- 0) 
  //              W = X						// is exact; this also handles infinity
  //      else 
  //              RoundUp = RoundingLogic(Xs, L', R', T', rm)	// Table 16.4
  //              if (E < 0) 					// 0 <= X < 1 rounds to 0 or 1
  //                      if (RoundUp)     {Ws, We, Wf} = {Xs, bias, 0}	// +/- 1.0
  //                     else                    {Ws, We, Wf} = {Xs, 0, 0}	// +/- 0
  //              else //						// X >= 1 rounds to an integer or overflows to infinity
  //                     if (RoundUp) Rm = RND else Rm = TRUNC	// Round up to RND or down to TRUNC
  //                     if (Rm = 2.0)					// rounding requires incrementing exponent
  //                             if (Xe = emax) {Ws, We, Wf} = {Xs, 111..11, 0} 	// overflow to W = Infinity with sign of Xs
  //                             else	        {Ws, We, Wf} = {Xs, Xe+1, 0}	// 1.0 x 2E+1
  //                     else                      {Ws, We, Wf} = {Xs, Xe, Rf}	// Rounded fraction, retain sign and exponent
  //              If (FroundNX instruction) Inexact = R' | T'
  ///////////////////////////

  // Exact logic
  assign Exact = (E >= Nf | XZero); // result will be exact; no need to round

  // Rounding logic: determine whether to round up in magnitude
  always_comb
    case (Rm) // *** make sure this includes dynamic
      3'b000:  RoundUp = Rp & (Lp | Tp);  // RNE
      3'b001:  RoundUp = 0;               // RZ
      3'b010:  RoundUp = Xs & (Rp | Tp);  // RN
      3'b011:  RoundUp = ~Xs & (Rp | Tp); // RP
      3'b101:  RoundUp = Rp;              // RNTA
      default: RoundUp = 0;               // should never happen
    endcase

    // output logic
    if (XNaN) W = CanonicalNan; // ***
    else if (Exact) W = X;
    else if (Elt0) 
      if (RoundUp) W = {Xs, bias, {P.NF}} // *** format conversions

      *** may not need to round to infinity; update docs and pseudocode above

  always_comb

  // Flags
  assign Invalid = XSNaN;
  assign Inexact = FRoundNX & ~(XNaN | Exact) & (Rp | T'); 
 */

endmodule

///////////////////////////////////////////
// fdivsqrtpreproc.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: Divide/Square root preprocessing: integer absolute value and W64, normalization shift
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

module fdivsqrtpreproc import cvw::*;  #(parameter cvw_t P) (
  input  logic                clk,
  input  logic                IFDivStartE, 
  input  logic [P.NF:0]        Xm, Ym,
  input  logic [P.NE-1:0]      Xe, Ye,
  input  logic [P.FMTBITS-1:0] Fmt,
  input  logic                Sqrt,
  input  logic                XZeroE,
  input  logic [2:0]          Funct3E,
  output logic [P.NE+1:0]      QeM,
  output logic [P.DIVb+3:0]    X,
  output logic [P.DIVb-1:0]    DPreproc,
  // Int-specific
  input  logic [P.XLEN-1:0]    ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  input  logic                IntDivE, W64E,
  output logic                ISpecialCaseE,
  output logic [P.DIVBLEN:0]   nE, nM, mM,
  output logic                NegQuotM, ALTBM, IntDivM, W64M,
  output logic                AsM, BZeroM,
  output logic [P.XLEN-1:0]    AM
);

  logic [P.DIVb-1:0]           XPreproc;
  logic [P.DIVb:0]             PreSqrtX;
  logic [P.DIVb+3:0]           DivX, DivXShifted, SqrtX, PreShiftX; // Variations of dividend, to be muxed
  logic [P.NE+1:0]             QeE;                                 // Quotient Exponent (FP only)
  logic [P.DIVb-1:0]           IFNormLenX, IFNormLenD;              // Correctly-sized inputs for iterator
  logic [P.DIVBLEN:0]          mE, ell;                             // Leading zeros of inputs
  logic                       NumerZeroE;                          // Numerator is zero (X or A)
  logic                       AZeroE, BZeroE;                      // A or B is Zero for integer division

  if (P.IDIV_ON_FPU) begin:intpreproc // Int Supported
    logic signedDiv, NegQuotE;
    logic AsBit, BsBit, AsE, BsE, ALTBE;
    logic [P.XLEN-1:0] AE, BE, PosA, PosB;
    logic [P.DIVBLEN:0] ZeroDiff, p;

    // Extract inputs, signs, zero, depending on W64 mode if applicable
    assign signedDiv = ~Funct3E[0];
    assign NegQuotE = AsE ^ BsE; // Quotient is negative

    // Source handling
    if (P.XLEN==64) begin // 64-bit, supports W64
      mux2 #(1) azeromux(~(|ForwardedSrcAE), ~(|ForwardedSrcAE[31:0]), W64E, AZeroE);
      mux2 #(1) bzeromux(~(|ForwardedSrcBE), ~(|ForwardedSrcBE[31:0]), W64E, BZeroE);
      mux2 #(1)  abitmux(ForwardedSrcAE[63], ForwardedSrcAE[31], W64E, AsBit);
      mux2 #(1)  bbitmux(ForwardedSrcBE[63], ForwardedSrcBE[31], W64E, BsBit);
      mux2 #(64)    amux(ForwardedSrcAE, {{(P.XLEN-32){AsE}}, ForwardedSrcAE[31:0]}, W64E, AE);
      mux2 #(64)    bmux(ForwardedSrcBE, {{(P.XLEN-32){BsE}}, ForwardedSrcBE[31:0]}, W64E, BE);
      assign AsE = signedDiv & AsBit;
      assign BsE = signedDiv & BsBit;
    end else begin // 32 bits only
      assign AsE = signedDiv & ForwardedSrcAE[31];
      assign BsE = signedDiv & ForwardedSrcBE[31];
      assign AE = ForwardedSrcAE;
      assign BE = ForwardedSrcBE;
      assign AZeroE = ~(|ForwardedSrcAE);
      assign BZeroE = ~(|ForwardedSrcBE);
    end

    // Force integer inputs to be postiive
    mux2 #(P.XLEN) posamux(AE, -AE, AsE, PosA);
    mux2 #(P.XLEN) posbmux(BE, -BE, BsE, PosB);

    // Select integer or floating point inputs
    mux2 #(P.DIVb) ifxmux({Xm, {(P.DIVb-P.NF-1){1'b0}}}, {PosA, {(P.DIVb-P.XLEN){1'b0}}}, IntDivE, IFNormLenX);
    mux2 #(P.DIVb) ifdmux({Ym, {(P.DIVb-P.NF-1){1'b0}}}, {PosB, {(P.DIVb-P.XLEN){1'b0}}}, IntDivE, IFNormLenD);

    // calculate number of fractional bits p
    assign ZeroDiff = mE - ell;         // Difference in number of leading zeros
    assign ALTBE = ZeroDiff[P.DIVBLEN];  // A less than B (A has more leading zeros)
    mux2 #(P.DIVBLEN+1) pmux(ZeroDiff, {(P.DIVBLEN+1){1'b0}}, ALTBE, p);            // *** is there a more graceful way to write these constants    

    // Integer special cases (terminate immediately)
    assign ISpecialCaseE = BZeroE | ALTBE;

  /* verilator lint_off WIDTH */
    // calculate number of fractional digits nE and right shift amount RightShiftX to complete in discrete number of steps

    if (P.LOGRK > 0) begin // more than 1 bit per cycle
      logic [P.LOGRK-1:0] IntTrunc, RightShiftX;
      logic [P.DIVBLEN:0] TotalIntBits, IntSteps;

      assign TotalIntBits = P.LOGR + p;                            // Total number of result bits (r integer bits plus p fractional bits)
      assign IntTrunc = TotalIntBits % P.RK;                       // Truncation check for ceiling operator
      assign IntSteps = (TotalIntBits >> P.LOGRK) + |IntTrunc;     // Number of steps for int div
      assign nE = (IntSteps * P.DIVCOPIES) - 1;                    // Fractional digits
      assign RightShiftX = P.RK - 1 - ((TotalIntBits - 1) % P.RK);  // Right shift amount
      assign DivXShifted = DivX >> RightShiftX;                   // shift X by up to R*K-1 to complete in nE steps
    end else begin // radix 2 1 copy doesn't require shifting
      assign nE = p; 
      assign DivXShifted = DivX;
    end
  /* verilator lint_on WIDTH */

    // Selet integer or floating-point operands
    mux2 #(1)    numzmux(XZeroE, AZeroE, IntDivE, NumerZeroE);
    mux2 #(P.DIVb+4) xmux(PreShiftX, DivXShifted, IntDivE, X);

    // pipeline registers
    flopen #(1)        mdureg(clk, IFDivStartE, IntDivE,     IntDivM);
    flopen #(1)       altbreg(clk, IFDivStartE, ALTBE,    ALTBM);
    flopen #(1)    negquotreg(clk, IFDivStartE, NegQuotE, NegQuotM);
    flopen #(1)      bzeroreg(clk, IFDivStartE, BZeroE,   BZeroM);
    flopen #(1)      asignreg(clk, IFDivStartE, AsE,      AsM);
    flopen #(P.DIVBLEN+1) nreg(clk, IFDivStartE, nE,       nM);
    flopen #(P.DIVBLEN+1) mreg(clk, IFDivStartE, mE,       mM);
    flopen #(P.XLEN)   srcareg(clk, IFDivStartE, AE,       AM);
    if (P.XLEN==64) 
      flopen #(1)      w64reg(clk, IFDivStartE, W64E,     W64M);

  end else begin // Int not supported
    assign IFNormLenX = {Xm, {(P.DIVb-P.NF-1){1'b0}}};
    assign IFNormLenD = {Ym, {(P.DIVb-P.NF-1){1'b0}}};
    assign NumerZeroE = XZeroE;
    assign X = PreShiftX;
  end

  // count leading zeros for Subnorm FP and to normalize integer inputs
  lzc #(P.DIVb) lzcX (IFNormLenX, ell);
  lzc #(P.DIVb) lzcY (IFNormLenD, mE);

  // Normalization shift
  assign XPreproc = IFNormLenX << (ell + {{P.DIVBLEN{1'b0}}, 1'b1}); // *** try to remove this +1
  assign DPreproc = IFNormLenD << (mE + {{P.DIVBLEN{1'b0}}, 1'b1}); 

  // append leading 1 (for normal inputs)
  // shift square root to be in range [1/4, 1)
  // Normalized numbers are shifted right by 1 if the exponent is odd
  // Denormalized numbers have Xe = 0 and an unbiased exponent of 1-BIAS.  They are shifted right if the number of leading zeros is odd.
  mux2 #(P.DIVb+1) sqrtxmux({~XZeroE, XPreproc}, {1'b0, ~XZeroE, XPreproc[P.DIVb-1:1]}, (Xe[0] ^ ell[0]), PreSqrtX);
  assign DivX = {3'b000, ~NumerZeroE, XPreproc};

  // Sqrt is initialized on step one as R(X-1), so depends on Radix
  if (P.RADIX == 2)  assign SqrtX = {3'b111, PreSqrtX};
  else              assign SqrtX = {2'b11, PreSqrtX, 1'b0};
  mux2 #(P.DIVb+4) prexmux(DivX, SqrtX, Sqrt, PreShiftX);
 
  // Floating-point exponent
  fdivsqrtexpcalc #(P) expcalc(.Fmt, .Xe, .Ye, .Sqrt, .XZero(XZeroE), .ell, .m(mE), .Qe(QeE));
  flopen #(P.NE+2) expreg(clk, IFDivStartE, QeE, QeM);
endmodule


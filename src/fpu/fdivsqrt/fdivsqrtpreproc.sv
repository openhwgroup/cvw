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
  input  logic                 clk,
  input  logic                 IFDivStartE, 
  input  logic [P.NF:0]        Xm, Ym,
  input  logic [P.NE-1:0]      Xe, Ye,
  input  logic [P.FMTBITS-1:0] FmtE,
  input  logic                 SqrtE,
  input  logic                 XZeroE,
  input  logic [2:0]           Funct3E,
  output logic [P.NE+1:0]      UeM,
  output logic [P.DIVb+3:0]    X, D,
  // Int-specific
  input  logic [P.XLEN-1:0]    ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  input  logic                 IntDivE, W64E,
  output logic                 ISpecialCaseE,
  output logic [P.DURLEN-1:0]  CyclesE,
  output logic [P.DIVBLEN:0]   IntNormShiftM,
  output logic                 ALTBM, IntDivM, W64M,
  output logic                 AsM, BsM, BZeroM,
  output logic [P.XLEN-1:0]    AM
);

  logic [P.DIVb:0]             Xnorm, Dnorm;
  logic [P.DIVb:0]             PreSqrtX;
  logic [P.DIVb+3:0]           DivX, DivXShifted, SqrtX, PreShiftX; // Variations of dividend, to be muxed
  logic [P.NE+1:0]             UeE;                                 // Result Exponent (FP only)
  logic [P.DIVb:0]             IFX, IFD;                            // Correctly-sized inputs for iterator, selected from int or fp input
  logic [P.DIVBLEN:0]          mE, ell;                             // Leading zeros of inputs
  logic [P.DIVBLEN:0]          IntResultBits;                       // bits in integer result
  logic                        NumerZeroE;                          // Numerator is zero (X or A)
  logic                        AZeroE, BZeroE;                      // A or B is Zero for integer division
  logic                        SignedDivE;                          // signed division
  logic                        AsE, BsE;                            // Signs of integer inputs
  logic [P.XLEN-1:0]           AE;                                  // input A after W64 adjustment
  logic  ALTBE;

  //////////////////////////////////////////////////////
  // Integer Preprocessing
  //////////////////////////////////////////////////////

  if (P.IDIV_ON_FPU) begin:intpreproc // Int Supported
    logic [P.XLEN-1:0] BE, PosA, PosB;

    // Extract inputs, signs, zero, depending on W64 mode if applicable
    assign SignedDivE = ~Funct3E[0];
  
    // Source handling
    if (P.XLEN==64) begin // 64-bit, supports W64
      mux2 #(64)    amux(ForwardedSrcAE, {{32{ForwardedSrcAE[31] & SignedDivE}}, ForwardedSrcAE[31:0]}, W64E, AE);
      mux2 #(64)    bmux(ForwardedSrcBE, {{32{ForwardedSrcBE[31] & SignedDivE}}, ForwardedSrcBE[31:0]}, W64E, BE);
    end else begin // 32 bits only
      assign AE = ForwardedSrcAE;
      assign BE = ForwardedSrcBE;
     end
    assign AZeroE = ~(|AE);
    assign BZeroE = ~(|BE);
    assign AsE = AE[P.XLEN-1] & SignedDivE;
    assign BsE = BE[P.XLEN-1] & SignedDivE; 

    // Force integer inputs to be postiive
    mux2 #(P.XLEN) posamux(AE, -AE, AsE, PosA);
    mux2 #(P.XLEN) posbmux(BE, -BE, BsE, PosB);

    // Select integer or floating point inputs
    mux2 #(P.DIVb+1) ifxmux({Xm, {(P.DIVb-P.NF){1'b0}}}, {PosA, {(P.DIVb-P.XLEN+1){1'b0}}}, IntDivE, IFX);
    mux2 #(P.DIVb+1) ifdmux({Ym, {(P.DIVb-P.NF){1'b0}}}, {PosB, {(P.DIVb-P.XLEN+1){1'b0}}}, IntDivE, IFD);
    mux2 #(1)    numzmux(XZeroE, AZeroE, IntDivE, NumerZeroE);
  end else begin // Int not supported
    assign IFX = {Xm, {(P.DIVb-P.NF){1'b0}}};
    assign IFD = {Ym, {(P.DIVb-P.NF){1'b0}}};
    assign NumerZeroE = XZeroE;
  end

  //////////////////////////////////////////////////////
  // Integer & FP leading zero and normalization shift
  //////////////////////////////////////////////////////

  // count leading zeros for Subnorm FP and to normalize integer inputs
  lzc #(P.DIVb+1) lzcX (IFX, ell);
  lzc #(P.DIVb+1) lzcY (IFD, mE);

  // Normalization shift: shift leading one into most significant bit
  assign Xnorm = (IFX << ell);
  assign Dnorm = (IFD << mE); 

  //////////////////////////////////////////////////////
  // Integer Right Shift to digit boundary
  //  Determine DivXShifted (X shifted to digit boundary)
  //  and nE (number of fractional digits)
  //////////////////////////////////////////////////////

  if (P.IDIV_ON_FPU) begin:intrightshift // Int Supported
    logic [P.DIVBLEN:0] ZeroDiff, p;

    // calculate number of fractional bits p
    assign ZeroDiff = mE - ell;         // Difference in number of leading zeros
    assign ALTBE = ZeroDiff[P.DIVBLEN];  // A less than B (A has more leading zeros)
    mux2 #(P.DIVBLEN+1) pmux(ZeroDiff, '0, ALTBE, p);          

    /* verilator lint_off WIDTH */
    assign IntResultBits = P.LOGR + p;  // Total number of result bits (r integer bits plus p fractional bits)
    /* verilator lint_on WIDTH */

    // Integer special cases (terminate immediately)
    assign ISpecialCaseE = BZeroE | ALTBE;

    // calculate right shift amount RightShiftX to complete in discrete number of steps
    if (P.LOGRK > 0) begin // more than 1 bit per cycle
      logic [P.LOGRK-1:0] IntTrunc, RightShiftX;
      logic [P.DIVBLEN:0] IntSteps;
      /* verilator lint_offf WIDTH */
      assign RightShiftX = P.RK - 1 - ((IntResultBits - 1) % P.RK); // Right shift amount
      assign DivXShifted = DivX >> RightShiftX;                     // shift X by up to R*K-1 to complete in n steps
      /* verilator lint_on WIDTH */
    end else begin // radix 2 1 copy doesn't require shifting
      assign DivXShifted = DivX;
    end
  end else begin
    assign ISpecialCaseE = 0;
  end

  //////////////////////////////////////////////////////
  // Floating-Point Preprocessing
  // Extend to Q4.b format
  // shift square root to be in range [1/4, 1)
  // Normalized numbers are shifted right by 1 if the exponent is odd
  // Subnormal numbers have Xe = 0 and an unbiased exponent of 1-BIAS.  They are shifted right if the number of leading zeros is odd.
  // NOTE: there might be a discrepancy that X is never right shifted by 2.  However
  //  it comes out in the wash and gives the right answer.  Investigate later if possible. ***
  //////////////////////////////////////////////////////

  assign DivX = {3'b000, Xnorm}; // Zero-extend numerator for division

  // Sqrt is initialized on step one as R(X-1), so depends on Radix
  // If X = 0, then special case logic sets sqrt = 0 so this portion doesn't matter
  // Otherwise, X has a leading 1 after possible normalization shift and is now in range [1, 2)
  // Next X is shifted right by 1 or 2 bits to range [1/4, 1) and exponent will be adjusted accordingly to be even
  // Now (X-1) is negative.  Formed by placing all 1s in all four integer bits (in Q4.b) form, keeping X in fraciton bits
  // Then multiply by R is left shift by r (1 or 2 for radix 2 or 4)
  // For Radix 2, this gives 3 leading 1s, followed by the fraction bits
  // For Radix 4, this gives 2 leading 1s, followed by the fraction bits (and a zero in the lsb)
  mux2 #(P.DIVb+1) sqrtxmux(Xnorm, {1'b0, Xnorm[P.DIVb:1]}, (Xe[0] ^ ell[0]), PreSqrtX);
  if (P.RADIX == 2) assign SqrtX = {3'b111, PreSqrtX};
  else              assign SqrtX = {2'b11, PreSqrtX, 1'b0};
  mux2 #(P.DIVb+4) prexmux(DivX, SqrtX, SqrtE, PreShiftX);
  
  //////////////////////////////////////////////////////
  // Selet integer or floating-point operands
  //////////////////////////////////////////////////////

  if (P.IDIV_ON_FPU) begin
    mux2 #(P.DIVb+4) xmux(PreShiftX, DivXShifted, IntDivE, X);
  end else begin
    assign X = PreShiftX;
  end

  // Divisior register
  flopen #(P.DIVb+4) dreg(clk, IFDivStartE, {3'b000, Dnorm}, D);
 
  // Floating-point exponent
  fdivsqrtexpcalc #(P) expcalc(.Fmt(FmtE), .Xe, .Ye, .Sqrt(SqrtE), .XZero(XZeroE), .ell, .m(mE), .Ue(UeE));
  flopen #(P.NE+2) expreg(clk, IFDivStartE, UeE, UeM);

  // Number of FSM cycles (to FSM)
  fdivsqrtcycles #(P) cyclecalc(.FmtE, .SqrtE, .IntDivE, .IntResultBits, .CyclesE);

  if (P.IDIV_ON_FPU) begin:intpipelineregs
    logic [P.DIVBLEN:0] IntDivNormShiftE, IntRemNormShiftE, IntNormShiftE;
    logic               RemOpE;

    /* verilator lint_off WIDTH */
    assign IntDivNormShiftE = P.DIVb - (CyclesE * P.RK - P.LOGR); // b - rn, used for integer normalization right shift.  rn = Cycles * r * k - r ***explain
    assign IntRemNormShiftE = mE + (P.DIVb+1-P.XLEN);             // m + b - (N-1) for remainder normalization shift
    /* verilator lint_on WIDTH */
    assign RemOpE = Funct3E[1];
    mux2 #(P.DIVBLEN+1) normshiftmux(IntDivNormShiftE, IntRemNormShiftE, RemOpE, IntNormShiftE);

    // pipeline registers
    flopen #(1)          mdureg(clk, IFDivStartE, IntDivE,  IntDivM);
    flopen #(1)         altbreg(clk, IFDivStartE, ALTBE,    ALTBM);
    flopen #(1)        bzeroreg(clk, IFDivStartE, BZeroE,   BZeroM);
    flopen #(1)        asignreg(clk, IFDivStartE, AsE,      AsM);
    flopen #(1)        bsignreg(clk, IFDivStartE, BsE,      BsM);
    flopen #(P.DIVBLEN+1) nsreg(clk, IFDivStartE, IntNormShiftE, IntNormShiftM); 
    flopen #(P.XLEN)    srcareg(clk, IFDivStartE, AE,       AM);
    if (P.XLEN==64) 
      flopen #(1)        w64reg(clk, IFDivStartE, W64E,     W64M);
  end

endmodule


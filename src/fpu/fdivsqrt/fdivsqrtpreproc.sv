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
  output logic [P.NE+1:0]      QeM,
  output logic [P.DIVb+3:0]    X, D,
  // Int-specific
  input  logic [P.XLEN-1:0]    ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  input  logic                 IntDivE, W64E,
  output logic                 ISpecialCaseE,
  output logic [P.DURLEN-1:0]  CyclesE,
  output logic [P.DIVBLEN:0]   nM, mM,
  output logic                 NegQuotM, ALTBM, IntDivM, W64M,
  output logic                 AsM, BZeroM,
  output logic [P.XLEN-1:0]    AM
);

  logic [P.DIVb-1:0]           Xfract, Dfract;
  logic [P.DIVb:0]             PreSqrtX;
  logic [P.DIVb+3:0]           DivX, DivXShifted, SqrtX, PreShiftX; // Variations of dividend, to be muxed
  logic [P.NE+1:0]             QeE;                                 // Quotient Exponent (FP only)
  logic [P.DIVb-1:0]           IFX, IFD;                            // Correctly-sized inputs for iterator, selected from int or fp input
  logic [P.DIVBLEN:0]          mE, nE, ell;                         // Leading zeros of inputs
  logic                        NumerZeroE;                          // Numerator is zero (X or A)
  logic                        AZeroE, BZeroE;                      // A or B is Zero for integer division
  logic                        SignedDivE;                          // signed division
  logic                        NegQuotE;                            // Integer quotient is negative
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
    assign NegQuotE = AsE ^ BsE; // Integer Quotient is negative

    // Force integer inputs to be postiive
    mux2 #(P.XLEN) posamux(AE, -AE, AsE, PosA);
    mux2 #(P.XLEN) posbmux(BE, -BE, BsE, PosB);

    // Select integer or floating point inputs
    mux2 #(P.DIVb) ifxmux({Xm, {(P.DIVb-P.NF-1){1'b0}}}, {PosA, {(P.DIVb-P.XLEN){1'b0}}}, IntDivE, IFX);
    mux2 #(P.DIVb) ifdmux({Ym, {(P.DIVb-P.NF-1){1'b0}}}, {PosB, {(P.DIVb-P.XLEN){1'b0}}}, IntDivE, IFD);
    mux2 #(1)    numzmux(XZeroE, AZeroE, IntDivE, NumerZeroE);
  end else begin // Int not supported
    assign IFX = {Xm, {(P.DIVb-P.NF-1){1'b0}}};
    assign IFD = {Ym, {(P.DIVb-P.NF-1){1'b0}}};
    assign NumerZeroE = XZeroE;
  end

  //////////////////////////////////////////////////////
  // Integer & FP leading zero and normalization shift
  //////////////////////////////////////////////////////

  // count leading zeros for Subnorm FP and to normalize integer inputs
  lzc #(P.DIVb) lzcX (IFX, ell);
  lzc #(P.DIVb) lzcY (IFD, mE);

  // Normalization shift: shift off leading one
  assign Xfract = (IFX << ell) << 1;
  assign Dfract = (IFD << mE)  << 1; 

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

    // Integer special cases (terminate immediately)
    assign ISpecialCaseE = BZeroE | ALTBE;

    // calculate number of fractional digits nE and right shift amount RightShiftX to complete in discrete number of steps

    if (P.LOGRK > 0) begin // more than 1 bit per cycle
      logic [P.LOGRK-1:0] IntTrunc, RightShiftX;
      logic [P.DIVBLEN:0] TotalIntBits, IntSteps;
      /* verilator lint_off WIDTH */
      assign TotalIntBits = P.LOGR + p;                            // Total number of result bits (r integer bits plus p fractional bits)
      assign IntTrunc = TotalIntBits % P.RK;                       // Truncation check for ceiling operator
      assign IntSteps = (TotalIntBits >> P.LOGRK) + |IntTrunc;     // Number of steps for int div
      assign nE = (IntSteps * P.DIVCOPIES) - 1;                    // Fractional digits
      assign RightShiftX = P.RK - 1 - ((TotalIntBits - 1) % P.RK); // Right shift amount
      assign DivXShifted = DivX >> RightShiftX;                    // shift X by up to R*K-1 to complete in nE steps
      /* verilator lint_on WIDTH */
    end else begin // radix 2 1 copy doesn't require shifting
      assign nE = p; 
      assign DivXShifted = DivX;
    end
  end else begin
    assign ISpecialCaseE = 0;
  end

  //////////////////////////////////////////////////////
  // Floating-Point Preprocessing
  // append leading 1 (for nonzero inputs)
  // shift square root to be in range [1/4, 1)
  // Normalized numbers are shifted right by 1 if the exponent is odd
  // Subnormal numbers have Xe = 0 and an unbiased exponent of 1-BIAS.  They are shifted right if the number of leading zeros is odd.
  // NOTE: there might be a discrepancy that X is never right shifted by 2.  However
  //  it comes out in the wash and gives the right answer.  Investigate later if possible.
  //////////////////////////////////////////////////////

  assign DivX = {3'b000, ~NumerZeroE, Xfract};

  // Sqrt is initialized on step one as R(X-1), so depends on Radix
  mux2 #(P.DIVb+1) sqrtxmux({~XZeroE, Xfract}, {1'b0, ~XZeroE, Xfract[P.DIVb-1:1]}, (Xe[0] ^ ell[0]), PreSqrtX);
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
  flopen #(P.DIVb+4) dreg(clk, IFDivStartE, {4'b0001, Dfract}, D);
 
  // Floating-point exponent
  fdivsqrtexpcalc #(P) expcalc(.Fmt(FmtE), .Xe, .Ye, .Sqrt(SqrtE), .XZero(XZeroE), .ell, .m(mE), .Qe(QeE));
  flopen #(P.NE+2) expreg(clk, IFDivStartE, QeE, QeM);

  // Number of FSM cycles (to FSM)
  fdivsqrtcycles #(P) cyclecalc(.FmtE, .SqrtE, .IntDivE, .nE, .CyclesE);

  if (P.IDIV_ON_FPU) begin:intpipelineregs
    // pipeline registers
    flopen #(1)        mdureg(clk, IFDivStartE, IntDivE,  IntDivM);
    flopen #(1)       altbreg(clk, IFDivStartE, ALTBE,    ALTBM);
    flopen #(1)    negquotreg(clk, IFDivStartE, NegQuotE, NegQuotM);
    flopen #(1)      bzeroreg(clk, IFDivStartE, BZeroE,   BZeroM);
    flopen #(1)      asignreg(clk, IFDivStartE, AsE,      AsM);
    flopen #(P.DIVBLEN+1) nreg(clk, IFDivStartE, nE,       nM); 
    flopen #(P.DIVBLEN+1) mreg(clk, IFDivStartE, mE,       mM);
    flopen #(P.XLEN)   srcareg(clk, IFDivStartE, AE,       AM);
    if (P.XLEN==64) 
      flopen #(1)      w64reg(clk, IFDivStartE, W64E,     W64M);
  end

endmodule


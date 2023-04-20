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

`include "wally-config.vh"

module fdivsqrtpreproc (
  input  logic                clk,
  input  logic                IFDivStartE, 
  input  logic [`NF:0]        Xm, Ym,
  input  logic [`NE-1:0]      Xe, Ye,
  input  logic [`FMTBITS-1:0] FmtE,
  input  logic                SqrtE,
  input  logic                XZeroE,
  input  logic [2:0]          Funct3E,
  output logic [`NE+1:0]      QeM,
  output logic [`DIVb+3:0]    X, D,
  // Int-specific
  input  logic [`XLEN-1:0]    ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  input  logic                IntDivE, W64E,
  output logic                ISpecialCaseE,
  output logic [`DURLEN-1:0]  CyclesE,
  output logic [`DIVBLEN:0]   nM, mM,
  output logic                NegQuotM, ALTBM, IntDivM, W64M,
  output logic                AsM, BZeroM,
  output logic [`XLEN-1:0]    AM
);

  logic [`DIVb-1:0]           XPreproc, DPreproc;
  logic [`DIVb:0]             PreSqrtX;
  logic [`DIVb+3:0]           DivX, DivXShifted, SqrtX, PreShiftX; // Variations of dividend, to be muxed
  logic [`NE+1:0]             QeE;                                 // Quotient Exponent (FP only)
  logic [`DIVb-1:0]           IFX, IFD;                            // Correctly-sized inputs for iterator, selected from int or fp input
  logic [`DIVBLEN:0]          mE, nE, ell;                             // Leading zeros of inputs
  logic                       NumerZeroE;                          // Numerator is zero (X or A)
  logic                       AZeroE, BZeroE;                      // A or B is Zero for integer division
  logic                       signedDiv;                           // signed division
  logic                       NegQuotE;                            // Integer quotient is negative
  logic                       AsE, BsE;                            // Signs of integer inputs
  logic [`XLEN-1:0]           AE;                                  // input A after W64 adjustment
  logic  ALTBE;

  //////////////////////////////////////////////////////
  // Integer Preprocessing
  //////////////////////////////////////////////////////

  if (`IDIV_ON_FPU) begin:intpreproc // Int Supported
    logic [`XLEN-1:0] BE, PosA, PosB;

    // Extract inputs, signs, zero, depending on W64 mode if applicable
    assign signedDiv = ~Funct3E[0];
  
    // Source handling
    if (`XLEN==64) begin // 64-bit, supports W64
      mux2 #(64)    amux(ForwardedSrcAE, {{32{ForwardedSrcAE[31] & signedDiv}}, ForwardedSrcAE[31:0]}, W64E, AE);
      mux2 #(64)    bmux(ForwardedSrcBE, {{32{ForwardedSrcBE[31] & signedDiv}}, ForwardedSrcBE[31:0]}, W64E, BE);
    end else begin // 32 bits only
      assign AE = ForwardedSrcAE;
      assign BE = ForwardedSrcBE;
     end
    assign AZeroE = ~(|AE);
    assign BZeroE = ~(|BE);
    assign AsE = AE[`XLEN-1] & signedDiv;
    assign BsE = BE[`XLEN-1] & signedDiv; 
    assign NegQuotE = AsE ^ BsE; // Integer Quotient is negative

    // Force integer inputs to be postiive
    mux2 #(`XLEN) posamux(AE, -AE, AsE, PosA);
    mux2 #(`XLEN) posbmux(BE, -BE, BsE, PosB);

    // Select integer or floating point inputs
    mux2 #(`DIVb) ifxmux({Xm, {(`DIVb-`NF-1){1'b0}}}, {PosA, {(`DIVb-`XLEN){1'b0}}}, IntDivE, IFX);
    mux2 #(`DIVb) ifdmux({Ym, {(`DIVb-`NF-1){1'b0}}}, {PosB, {(`DIVb-`XLEN){1'b0}}}, IntDivE, IFD);
    mux2 #(1)    numzmux(XZeroE, AZeroE, IntDivE, NumerZeroE);
  end else begin // Int not supported
    assign IFX = {Xm, {(`DIVb-`NF-1){1'b0}}};
    assign IFD = {Ym, {(`DIVb-`NF-1){1'b0}}};
    assign NumerZeroE = XZeroE;
  end

  //////////////////////////////////////////////////////
  // Integer & FP leading zero and normalization shift
  //////////////////////////////////////////////////////

  // count leading zeros for Subnorm FP and to normalize integer inputs
  lzc #(`DIVb) lzcX (IFX, ell);
  lzc #(`DIVb) lzcY (IFD, mE);

  // Normalization shift: shift off leading one
  assign XPreproc = (IFX << ell) << 1;
  assign DPreproc = (IFD << mE)  << 1; 

  // *** CT: move to fdivsqrtintpreshift

  //////////////////////////////////////////////////////
  // Integer Right Shift to digit boundary
  //  Determine DivXShifted (X shifted to digit boundary)
  //  and nE (number of fractional digits)
  //////////////////////////////////////////////////////

  if (`IDIV_ON_FPU) begin:intrightshift // Int Supported
    logic [`DIVBLEN:0] ZeroDiff, p;

    // calculate number of fractional bits p
    assign ZeroDiff = mE - ell;         // Difference in number of leading zeros
    assign ALTBE = ZeroDiff[`DIVBLEN];  // A less than B (A has more leading zeros)
    mux2 #(`DIVBLEN+1) pmux(ZeroDiff, '0, ALTBE, p);              

    // Integer special cases (terminate immediately)
    assign ISpecialCaseE = BZeroE | ALTBE;

    // calculate number of fractional digits nE and right shift amount RightShiftX to complete in discrete number of steps

    if (`LOGRK > 0) begin // more than 1 bit per cycle
      logic [`LOGRK-1:0] IntTrunc, RightShiftX;
      logic [`DIVBLEN:0] TotalIntBits, IntSteps;
      /* verilator lint_off WIDTH */
      assign TotalIntBits = `LOGR + p;                            // Total number of result bits (r integer bits plus p fractional bits)
      assign IntTrunc = TotalIntBits % `RK;                       // Truncation check for ceiling operator
      assign IntSteps = (TotalIntBits >> `LOGRK) + |IntTrunc;     // Number of steps for int div
      assign nE = (IntSteps * `DIVCOPIES) - 1;                    // Fractional digits
      assign RightShiftX = `RK - 1 - ((TotalIntBits - 1) % `RK);  // Right shift amount
      assign DivXShifted = DivX >> RightShiftX;                   // shift X by up to R*K-1 to complete in nE steps
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
  // Denormalized numbers have Xe = 0 and an unbiased exponent of 1-BIAS.  They are shifted right if the number of leading zeros is odd.
  //////////////////////////////////////////////////////

  mux2 #(`DIVb+1) sqrtxmux({~XZeroE, XPreproc}, {1'b0, ~XZeroE, XPreproc[`DIVb-1:1]}, (Xe[0] ^ ell[0]), PreSqrtX);
  assign DivX = {3'b000, ~NumerZeroE, XPreproc};

  // Sqrt is initialized on step one as R(X-1), so depends on Radix
  if (`RADIX == 2)  assign SqrtX = {3'b111, PreSqrtX};
  else              assign SqrtX = {2'b11, PreSqrtX, 1'b0};
  mux2 #(`DIVb+4) prexmux(DivX, SqrtX, SqrtE, PreShiftX);
  
  //////////////////////////////////////////////////////
  // Selet integer or floating-point operands
  //////////////////////////////////////////////////////

  if (`IDIV_ON_FPU) begin
    mux2 #(`DIVb+4) xmux(PreShiftX, DivXShifted, IntDivE, X);
  end else begin
    assign X = PreShiftX;
  end

   // Divisior register
  flopen #(`DIVb+4) dreg(clk, IFDivStartE, {4'b0001, DPreproc}, D);
 
  // Floating-point exponent
  fdivsqrtexpcalc expcalc(.Fmt(FmtE), .Xe, .Ye, .Sqrt(SqrtE), .XZero(XZeroE), .ell, .m(mE), .Qe(QeE));
  flopen #(`NE+2) expreg(clk, IFDivStartE, QeE, QeM);

  // Number of FSM cycles (to FSM)
  fdivsqrtcycles cyclecalc(.FmtE, .SqrtE, .IntDivE, .nE, .CyclesE);

  if (`IDIV_ON_FPU) begin:intpipelineregs
    // pipeline registers
    flopen #(1)        mdureg(clk, IFDivStartE, IntDivE,     IntDivM);
    flopen #(1)       altbreg(clk, IFDivStartE, ALTBE,    ALTBM);
    flopen #(1)    negquotreg(clk, IFDivStartE, NegQuotE, NegQuotM);
    flopen #(1)      bzeroreg(clk, IFDivStartE, BZeroE,   BZeroM);
    flopen #(1)      asignreg(clk, IFDivStartE, AsE,      AsM);
    flopen #(`DIVBLEN+1) nreg(clk, IFDivStartE, nE,       nM); 
    flopen #(`DIVBLEN+1) mreg(clk, IFDivStartE, mE,       mM);
    flopen #(`XLEN)   srcareg(clk, IFDivStartE, AE,       AM);
    if (`XLEN==64) 
      flopen #(1)      w64reg(clk, IFDivStartE, W64E,     W64M);
  end

endmodule


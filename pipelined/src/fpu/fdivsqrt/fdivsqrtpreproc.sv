///////////////////////////////////////////
// fdivsqrtpreproc.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
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

module fdivsqrtpreproc (
  input  logic clk,
  input  logic IFDivStartE, 
  input  logic [`NF:0] Xm, Ym,
  input  logic [`NE-1:0] Xe, Ye,
  input  logic [`FMTBITS-1:0] Fmt,
  input  logic Sqrt,
  input  logic XZeroE,
	input  logic [2:0] 	Funct3E,
  output logic [`NE+1:0] QeM,
  output logic [`DIVb+3:0] X,
  output logic [`DIVb-1:0] DPreproc,
  // Int-specific
  input  logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
	input  logic MDUE, W64E,
  output logic ISpecialCaseE,
  output logic [`DIVBLEN:0] nE, nM, mM,
  output logic NegQuotM, ALTBM, MDUM, W64M,
  output logic AsM, BZeroM, BZeroE,
  output logic [`XLEN-1:0] AM
);

  logic  [`DIVb-1:0] XPreproc;
  logic  [`DIVb:0] PreSqrtX;
  logic  [`DIVb+3:0] DivX, DivXShifted, SqrtX, PreShiftX;  // Variations of dividend, to be muxed
  logic  [`NE+1:0] QeE;                       // Quotient Exponent (FP only)
  logic  [`DIVb-1:0] IFNormLenX, IFNormLenD;  // Correctly-sized inputs for iterator
  logic  [`DIVBLEN:0] mE, ell;                // Leading zeros of inputs
  logic  NumerZeroE;                          // Numerator is zero (X or A)
  logic  AZeroE;                              // A is Zero for integer division

  if (`IDIV_ON_FPU) begin:intpreproc // Int Supported
    logic signedDiv, NegQuotE;
    logic AsBit, BsBit, AsE, BsE, ALTBE;
    logic [`XLEN-1:0] AE, BE, PosA, PosB;
    logic [`DIVBLEN:0] ZeroDiff, p;

    // Extract inputs, signs, zero, depending on W64 mode if applicable
    assign signedDiv = ~Funct3E[0];
    assign NegQuotE = AsE ^ BsE; // Quotient is negative

    // Source handling
    if (`XLEN==64) begin // 64-bit, supports W64
      mux2 #(1) azeromux(~(|ForwardedSrcAE), ~(|ForwardedSrcAE[31:0]), W64E, AZeroE);
      mux2 #(1) bzeromux(~(|ForwardedSrcBE), ~(|ForwardedSrcBE[31:0]), W64E, BZeroE);
      mux2 #(1)  abitmux(ForwardedSrcAE[63], ForwardedSrcAE[31], W64E, AsBit);
      mux2 #(1)  bbitmux(ForwardedSrcBE[63], ForwardedSrcBE[31], W64E, BsBit);
      mux2 #(64)    amux(ForwardedSrcAE, {{(`XLEN-32){AsE}}, ForwardedSrcAE[31:0]}, W64E, AE);
      mux2 #(64)    bmux(ForwardedSrcBE, {{(`XLEN-32){BsE}}, ForwardedSrcBE[31:0]}, W64E, BE);
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
    mux2 #(`XLEN) posamux(AE, -AE, AsE, PosA);
    mux2 #(`XLEN) posbmux(BE, -BE, BsE, PosB);

    // Select integer or floating point inputs
    mux2 #(`DIVb) ifxmux({Xm, {(`DIVb-`NF-1){1'b0}}}, {PosA, {(`DIVb-`XLEN){1'b0}}}, MDUE, IFNormLenX);
    mux2 #(`DIVb) ifdmux({Ym, {(`DIVb-`NF-1){1'b0}}}, {PosB, {(`DIVb-`XLEN){1'b0}}}, MDUE, IFNormLenD);

    // calculate number of fractional bits p
    assign ZeroDiff = mE - ell;         // Difference in number of leading zeros
    assign ALTBE = ZeroDiff[`DIVBLEN];  // A less than B (A has more leading zeros)
    mux2 #(`DIVBLEN+1) pmux(ZeroDiff, {(`DIVBLEN+1){1'b0}}, ALTBE, p);            // *** is there a more graceful way to write these constants    

    // Integer special cases (terminate immediately)
    assign ISpecialCaseE = BZeroE | ALTBE;

  /* verilator lint_off WIDTH */
    // calculate number of fractional digits nE and right shift amount RightShiftX to complete in discrete number of steps

    if (`LOGRK > 0) begin // more than 1 bit per cycle
      logic [`LOGRK-1:0] IntTrunc, RightShiftX;
      logic [`DIVBLEN:0] TotalIntBits, IntSteps;

      assign TotalIntBits = `LOGR + p;                            // Total number of result bits (r integer bits plus p fractional bits)
      assign IntTrunc = TotalIntBits % `RK;                       // Truncation check for ceiling operator
      assign IntSteps = (TotalIntBits >> `LOGRK) + |IntTrunc;     // Number of steps for int div
      assign nE = (IntSteps * `DIVCOPIES) - 1;                    // Fractional digits
      assign RightShiftX = `RK - 1 - ((TotalIntBits - 1) % `RK);  // Right shift amount
      assign DivXShifted = DivX >> RightShiftX;                   // shift X by up to R*K-1 to complete in nE steps
    end else begin // radix 2 1 copy doesn't require shifting
      assign nE = p; 
      assign DivXShifted = DivX;
    end
  /* verilator lint_on WIDTH */

    // Selet integer or floating-point operands
    mux2 #(1)    numzmux(XZeroE, AZeroE, MDUE, NumerZeroE);
    mux2 #(`DIVb+4) xmux(PreShiftX, DivXShifted, MDUE, X);

    // pipeline registers
    flopen #(1)        mdureg(clk, IFDivStartE, MDUE,     MDUM);
    flopen #(1)        w64reg(clk, IFDivStartE, W64E,     W64M);
    flopen #(1)       altbreg(clk, IFDivStartE, ALTBE,    ALTBM);
    flopen #(1)    negquotreg(clk, IFDivStartE, NegQuotE, NegQuotM);
    flopen #(1)      bzeroreg(clk, IFDivStartE, BZeroE,   BZeroM);
    flopen #(1)      asignreg(clk, IFDivStartE, AsE,      AsM);
    flopen #(`DIVBLEN+1) nreg(clk, IFDivStartE, nE,       nM);
    flopen #(`DIVBLEN+1) mreg(clk, IFDivStartE, mE,       mM);
    flopen #(`XLEN)   srcareg(clk, IFDivStartE, AE,       AM);

  end else begin // Int not supported
    assign IFNormLenX = {Xm, {(`DIVb-`NF-1){1'b0}}};
    assign IFNormLenD = {Ym, {(`DIVb-`NF-1){1'b0}}};
    assign NumerZeroE = XZeroE;
    assign X = PreShiftX;
  end

  // count leading zeros for Subnorm FP and to normalize integer inputs
  lzc #(`DIVb) lzcX (IFNormLenX, ell);
  lzc #(`DIVb) lzcY (IFNormLenD, mE);

  // Normalization shift
  assign XPreproc = IFNormLenX << (ell + {{`DIVBLEN{1'b0}}, 1'b1}); 
  assign DPreproc = IFNormLenD << (mE + {{`DIVBLEN{1'b0}}, 1'b1}); 

  // append leading 1 (for nonzero inputs) and conditionally shift left by one to avoid sqrt(2)
  mux2 #(`DIVb+1) sqrtxmux({~NumerZeroE, XPreproc}, {1'b0, ~NumerZeroE, XPreproc[`DIVb-1:1]}, (Xe[0]^ell[0]), PreSqrtX);
  assign DivX = {3'b000, ~NumerZeroE, XPreproc};

  // Sqrt is initialized on step one as R(X-1), so depends on Radix
  if (`RADIX == 2)  assign SqrtX = {3'b111, PreSqrtX};
  else              assign SqrtX = {2'b11, PreSqrtX, 1'b0};
  mux2 #(`DIVb+4) prexmux(DivX, SqrtX, Sqrt, PreShiftX);
 
  // Floating-point exponent
  fdivsqrtexpcalc expcalc(.Fmt, .Xe, .Ye, .Sqrt, .XZero(XZeroE), .ell, .m(mE), .Qe(QeE));
  flopen #(`NE+2) expreg(clk, IFDivStartE, QeE, QeM);
endmodule


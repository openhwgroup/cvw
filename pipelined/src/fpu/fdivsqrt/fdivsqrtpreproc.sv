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
  input  logic DivStartE, 
  input  logic [`NF:0] Xm, Ym,
  input  logic [`NE-1:0] Xe, Ye,
  input  logic [`FMTBITS-1:0] Fmt,
  input  logic Sqrt,
  input  logic XZero,
  input  logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
	input  logic [2:0] 	Funct3E, Funct3M,
	input  logic MDUE, W64E,
  output logic [`DIVBLEN:0] n, p, m,
  output logic [`NE+1:0] QeM,
  output logic [`DIVb+3:0] X,
  output logic [`DIVN-2:0] Dpreproc
);
  // logic  [`DIVLEN-1:0] ExtraA, ExtraB, PreprocA, PreprocB, PreprocX, PreprocY;
  logic  [`NF-1:0] PreprocA, PreprocX;
  logic  [`NF-1:0] PreprocB, PreprocY;
  logic  [`NF+1:0] SqrtX;
  logic  [`DIVb+3:0] DivX;
  logic  [`DIVBLEN:0] L;
  logic  [`NE+1:0] Qe;
  // Intdiv signals
  logic  [`DIVb-1:0] ZeroBufX, ZeroBufY;
  logic  [`XLEN-1:0] PosA, PosB;
  logic  As, Bs;
  logic  [`XLEN-1:0] A64, B64;
  logic  [`DIVBLEN:0] ZeroDiff, IntBits, RightShiftX;
  logic  [`DIVBLEN:0] pPlusr, pPrCeil;
  logic  [`LOGRK-1:0] pPrTrunc;
  logic  [`DIVb+3:0] PreShiftX;

  // ***can probably merge X LZC with conversion
  // cout the number of leading zeros

  assign As = ForwardedSrcAE[`XLEN-1] & Funct3E[0];
  assign Bs = ForwardedSrcBE[`XLEN-1] & Funct3E[0];
  assign A64 = W64E ? {{(`XLEN-32){As}}, ForwardedSrcAE[31:0]} : ForwardedSrcAE;
  assign B64 = W64E ? {{(`XLEN-32){Bs}}, ForwardedSrcBE[31:0]} : ForwardedSrcBE;
  
  assign PosA = As ? -A64 : A64;
  assign PosB = Bs ? -B64 : B64;

  assign ZeroBufX = MDUE ? {PosA, {`DIVb-`XLEN{1'b0}}} : {Xm, {`DIVb-`NF-1{1'b0}}};
  assign ZeroBufY = MDUE ? {PosB, {`DIVb-`XLEN{1'b0}}} : {Ym, {`DIVb-`NF-1{1'b0}}};
  lzc #(`DIVb) lzcX (ZeroBufX, L);
  lzc #(`DIVb) lzcY (ZeroBufY, m);

  assign PreprocX = Xm[`NF-1:0]<<L;
  assign PreprocY = Ym[`NF-1:0]<<m;

  assign ZeroDiff = m - L;
  assign p = ZeroDiff[`DIVBLEN] ? '0 : ZeroDiff;

  assign pPlusr = (`DIVBLEN)'(`LOGR) + p;
  assign pPrTrunc = pPlusr[`LOGRK-1:0];
  assign pPrCeil = (pPlusr >> `LOGRK) + {{`DIVBLEN-1{1'b0}}, |(pPrTrunc)};
  assign n = (pPrCeil << `LOGK) - 1;
  assign IntBits = (`DIVBLEN)'(`RK) + p;
  assign RightShiftX = (`DIVBLEN)'(`RK) - {{(`DIVBLEN-`RK){1'b0}}, IntBits[`RK-1:0]};

  assign SqrtX = Xe[0]^L[0] ? {1'b0, ~XZero, PreprocX} : {~XZero, PreprocX, 1'b0};
  assign DivX = {3'b000, ~XZero, PreprocX, {`DIVb-`NF{1'b0}}};

  // *** explain why X is shifted between radices (initial assignment of WS=RX)
  if (`RADIX == 2)  assign X = Sqrt ? {3'b111, SqrtX, {`DIVb-1-`NF{1'b0}}} : DivX;
  else              assign X = Sqrt ? {2'b11, SqrtX, {`DIVb-1-`NF{1'b0}}, 1'b0} : DivX;
  // assign X = MDUE ? PreShiftX >> RightShiftX : PreShiftX;
  assign Dpreproc = {PreprocY, {`DIVN-1-`NF{1'b0}}};

  //           radix 2     radix 4
  // 1 copies  DIVLEN+2    DIVLEN+2/2
  // 2 copies  DIVLEN+2/2  DIVLEN+2/2*2
  // 4 copies  DIVLEN+2/4  DIVLEN+2/2*4
  // 8 copies  DIVLEN+2/8  DIVLEN+2/2*8

  // DIVRESLEN = DIVLEN or DIVLEN+2
  // r = 1 or 2
  // DIVRESLEN/(r*`DIVCOPIES)
  flopen #(`NE+2) expflop(clk, DivStartE, Qe, QeM);
  expcalc expcalc(.Fmt, .Xe, .Ye, .Sqrt, .XZero, .L, .m, .Qe);

endmodule

module expcalc(
  input  logic [`FMTBITS-1:0] Fmt,
  input  logic [`NE-1:0] Xe, Ye,
  input  logic Sqrt,
  input  logic XZero, 
  input  logic [`DIVBLEN:0] L, m,
  output logic [`NE+1:0] Qe
  );
  logic [`NE-2:0] Bias;
  logic [`NE+1:0] SXExp;
  logic [`NE+1:0] SExp;
  logic [`NE+1:0] DExp;
  
  if (`FPSIZES == 1) begin
      assign Bias = (`NE-1)'(`BIAS); 

  end else if (`FPSIZES == 2) begin
      assign Bias = Fmt ? (`NE-1)'(`BIAS) : (`NE-1)'(`BIAS1); 

  end else if (`FPSIZES == 3) begin
      always_comb
          case (Fmt)
              `FMT: Bias  =  (`NE-1)'(`BIAS);
              `FMT1: Bias = (`NE-1)'(`BIAS1);
              `FMT2: Bias = (`NE-1)'(`BIAS2);
              default: Bias = 'x;
          endcase

  end else if (`FPSIZES == 4) begin        
    always_comb
        case (Fmt)
            2'h3: Bias =  (`NE-1)'(`Q_BIAS);
            2'h1: Bias =  (`NE-1)'(`D_BIAS);
            2'h0: Bias =  (`NE-1)'(`S_BIAS);
            2'h2: Bias =  (`NE-1)'(`H_BIAS);
        endcase
  end
  assign SXExp = {2'b0, Xe} - {{(`NE+1-`DIVBLEN){1'b0}}, L} - (`NE+2)'(`BIAS);
  assign SExp  = {SXExp[`NE+1], SXExp[`NE+1:1]} + {2'b0, Bias};
  // correct exponent for denormalized input's normalization shifts
  assign DExp  = ({2'b0, Xe} - {{(`NE+1-`DIVBLEN){1'b0}}, L} - {2'b0, Ye} + {{(`NE+1-`DIVBLEN){1'b0}}, m} + {3'b0, Bias}) & {`NE+2{~XZero}};
  
  assign Qe = Sqrt ? SExp : DExp;
endmodule
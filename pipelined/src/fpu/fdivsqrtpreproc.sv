///////////////////////////////////////////
// fdivsqrtpreproc.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, Cedar Turek
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
  input  logic DivStart, 
  input  logic [`NF:0] Xm, Ym,
  input  logic [`NE-1:0] Xe, Ye,
  input  logic [`FMTBITS-1:0] Fmt,
  input  logic Sqrt,
  input logic XZero,
  output logic  [`NE+1:0] QeM,
  output logic [`DIVb+3:0] X,
  output logic [`DIVN-2:0] Dpreproc
);
  // logic  [`XLEN-1:0] PosA, PosB;
  // logic  [`DIVLEN-1:0] ExtraA, ExtraB, PreprocA, PreprocB, PreprocX, PreprocY;
  logic  [`NF-1:0] PreprocA, PreprocX;
  logic  [`NF-1:0] PreprocB, PreprocY;
  logic  [`NF+1:0] SqrtX;
  logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt;
  logic [`NE+1:0] Qe;

  // assign PosA = (Signed & SrcA[`XLEN - 1]) ? -SrcA : SrcA;
  // assign PosB = (Signed & SrcB[`XLEN - 1]) ? -SrcB : SrcB;
  // lzc #(`XLEN) lzcA (PosA, zeroCntA);
  // lzc #(`XLEN) lzcB (PosB, zeroCntB);

  // ***can probably merge X LZC with conversion
  // cout the number of leading zeros
  lzc #(`NF+1) lzcX (Xm, XZeroCnt);
  lzc #(`NF+1) lzcY (Ym, YZeroCnt);

  // assign ExtraA = {PosA, {`DIVLEN-`XLEN{1'b0}}};
  // assign ExtraB = {PosB, {`DIVLEN-`XLEN{1'b0}}};

  // assign PreprocA = ExtraA << zeroCntA;
  // assign PreprocB = ExtraB << (zeroCntB + 1);
  assign PreprocX = Xm[`NF-1:0]<<XZeroCnt;
  assign PreprocY = Ym[`NF-1:0]<<YZeroCnt;

  
  assign SqrtX = Xe[0]^XZeroCnt[0] ? {1'b0, ~XZero, PreprocX} : {~XZero, PreprocX, 1'b0};
  if (`RADIX == 2)
    assign X = Sqrt ? {3'b111, SqrtX, {`DIVb-1-`NF{1'b0}}} : {3'b000, ~XZero, PreprocX, {`DIVb-`NF{1'b0}}};
  else 
    assign X = Sqrt ? {2'b11, SqrtX, {`DIVb-1-`NF{1'b0}}, 1'b0} : {3'b000, ~XZero, PreprocX, {`DIVb-`NF{1'b0}}};
  assign Dpreproc = {PreprocY, {`DIVN-1-`NF{1'b0}}};

  //           radix 2     radix 4
  // 1 copies  DIVLEN+2    DIVLEN+2/2
  // 2 copies  DIVLEN+2/2  DIVLEN+2/2*2
  // 4 copies  DIVLEN+2/4  DIVLEN+2/2*4
  // 8 copies  DIVLEN+2/8  DIVLEN+2/2*8

  // DIVRESLEN = DIVLEN or DIVLEN+2
  // r = 1 or 2
  // DIVRESLEN/(r*`DIVCOPIES)
  flopen #(`NE+2) expflop(clk, DivStart, Qe, QeM);
  expcalc expcalc(.Fmt, .Xe, .Ye, .Sqrt, .XZero, .XZeroCnt, .YZeroCnt, .Qe);

endmodule

module expcalc(
  input logic  [`FMTBITS-1:0] Fmt,
  input  logic [`NE-1:0] Xe, Ye,
  input logic Sqrt,
  input logic XZero, 
  input logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  output logic  [`NE+1:0] Qe
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
  assign SXExp = {2'b0, Xe} - {{`NE+1-$unsigned($clog2(`NF+2)){1'b0}}, XZeroCnt} - (`NE+1)'(`BIAS);
  assign SExp  = {SXExp[`NE+1], SXExp[`NE+1:1]} + {2'b0, Bias};
  // correct exponent for denormalized input's normalization shifts
  assign DExp = ({2'b0, Xe} - {{`NE+1-$unsigned($clog2(`NF+2)){1'b0}}, XZeroCnt} - {2'b0, Ye} + {{`NE+1-$unsigned($clog2(`NF+2)){1'b0}}, YZeroCnt} + {3'b0, Bias})&{`NE+2{~XZero}};
  
  assign Qe = Sqrt ? SExp : DExp;
endmodule
///////////////////////////////////////////
// srt.sv
//
// Written: David_Harris@hmc.edu 13 January 2022
// Modified: cturek@hmc.edu June 2022
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
`define EXTRAFRACBITS ((`NF<(`XLEN)) ? (`XLEN - `NF) : 0)
`define EXTRAINTBITS ((`NF<(`XLEN)) ? 0 : (`NF - `XLEN))

module srt (
  input  logic clk,
  input  logic Start, 
  input  logic Stall, // *** multiple pipe stages
  input  logic Flush, // *** multiple pipe stages
  // Floating Point Inputs
  // later add exponents, signs, special cases
  input  logic       XSign, YSign,
  input  logic [`NE-1:0] XExp, YExp,
  input  logic [`NF-1:0] SrcXFrac, SrcYFrac,
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic [1:0] Fmt, // Floats: 00 = 16 bit, 01 = 32 bit, 10 = 64 bit, 11 = 128 bit
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic       rsign, done,
  output logic [`DIVLEN-1:0] Rem, Quot, // *** later handle integers
  output logic [`NE-1:0] rExp,
  output logic [3:0] Flags
);

  logic           qp, qz, qm; // quotient is +1, 0, or -1
  logic [`NE-1:0] calcExp;
  logic           calcSign;
  logic [`DIVLEN+3:0]  X, Dpreproc;
  logic [`DIVLEN+3:0]  WS, WSA, WSN, WC, WCA, WCN, D, Db, Dsel;
  logic [$clog2(`XLEN+1)-1:0] intExp, dur, calcDur;
  logic           intSign;
 
  srtpreproc preproc(SrcA, SrcB, SrcXFrac, SrcYFrac, XExp, Fmt, W64, Signed, Int, Sqrt, X, Dpreproc, intExp, calcDur, intSign);

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  mux2   #(`DIVLEN+4) wsmux({WSA[`DIVLEN+2:0], 1'b0}, X, Start, WSN);
  flop   #(`DIVLEN+4) wsflop(clk, WSN, WS);
  mux2   #(`DIVLEN+4) wcmux({WCA[`DIVLEN+2:0], 1'b0}, {(`DIVLEN+4){1'b0}}, Start, WCN);
  flop   #(`DIVLEN+4) wcflop(clk, WCN, WC);
  flopen #(`DIVLEN+4) dflop(clk, Start, Dpreproc, D);

  // Quotient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  qsel2 qsel2(WS[`DIVLEN+3:`DIVLEN], WC[`DIVLEN+3:`DIVLEN], qp, qz, qm);

  flopen #(`NE) expflop(clk, Start, calcExp, rExp);
  flopen #(1) signflop(clk, Start, calcSign, rsign);
  flopen #(7) durflop(clk, Start, calcDur, dur);
  
  counter divcounter(clk, Start, dur, done);

  // Divisor Selection logic
  assign Db = ~D;
  mux3onehot #(`DIVLEN) divisorsel(Db, {(`DIVLEN+4){1'b0}}, D, qp, qz, qm, Dsel);

  // Partial Product Generation
  csa    #(`DIVLEN+4) csa(WS, WC, Dsel, qp, WSA, WCA);
  
  otfc2  #(`DIVLEN) otfc2(clk, Start, qp, qz, qm, Quot);

  expcalc expcalc(.XExp, .YExp, .calcExp, .Sqrt);

  signcalc signcalc(.XSign, .YSign, .calcSign);
endmodule

////////////////
// Submodules //
////////////////

///////////////////
// Preprocessing //
///////////////////
module srtpreproc (
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic [`NF-1:0] SrcXFrac, SrcYFrac,
  input  logic [`NE-1:0] XExp,
  input  logic [1:0] Fmt, // Floats: 00 = 16 bit, 01 = 32 bit, 10 = 64 bit, 11 = 128 bit
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic [`DIVLEN+3:0] X, D,
  output logic [$clog2(`XLEN+1)-1:0] intExp, dur, // Quotient integer exponent
  output logic       intSign // Quotient integer sign
);

  logic  [$clog2(`XLEN+1)-1:0] zeroCntA, zeroCntB;
  logic  [`XLEN-1:0] PosA, PosB;
  logic  [`DIVLEN-1:0] ExtraA, ExtraB, PreprocA, PreprocB, PreprocX, PreprocY, DivX, SqrtX;

  assign PosA = (Signed & SrcA[`XLEN - 1]) ? -SrcA : SrcA;
  assign PosB = (Signed & SrcB[`XLEN - 1]) ? -SrcB : SrcB;

  lzc #(`XLEN) lzcA (PosA, zeroCntA);
  lzc #(`XLEN) lzcB (PosB, zeroCntB);

  assign ExtraA = {PosA, {`EXTRAINTBITS{1'b0}}};
  assign ExtraB = {PosB, {`EXTRAINTBITS{1'b0}}};

  assign PreprocA = ExtraA << (zeroCntA + 1);
  assign PreprocB = ExtraB << (zeroCntB + 1);
  assign PreprocX = {SrcXFrac, {`EXTRAFRACBITS{1'b0}}};
  assign PreprocY = {SrcYFrac, {`EXTRAFRACBITS{1'b0}}};

  assign DivX = Int ? PreprocA : PreprocX;
  assign SqrtX = {XExp[0] ? 4'b0000 : 4'b1111, SrcXFrac};

  assign X = Sqrt ? SqrtX : {4'b0001, DivX};
  assign D = {4'b0001, Int ? PreprocB : PreprocY};
  assign intExp = zeroCntB - zeroCntA + 1;
  assign intSign = Signed & (SrcA[`XLEN - 1] ^ SrcB[`XLEN - 1]);

  assign dur = Int ? (intExp & {7{~intExp[6]}}) : (`DIVLEN + 2);
endmodule

/////////////////////////////////
// Quotient Selection, Radix 2 //
/////////////////////////////////
module qsel2 ( // *** eventually just change to 4 bits
  input  logic [`DIVLEN+3:`DIVLEN] ps, pc, 
  output logic         qp, qz, qm
);
 
  logic [`DIVLEN+3:`DIVLEN]  p, g;
  logic          magnitude, sign, cout;

  // The quotient selection logic is presented for simplicity, not
  // for efficiency.  You can probably optimize your logic to
  // select the proper divisor with less delay.

  // Quotient equations from EE371 lecture notes 13-20
  assign p = ps ^ pc;
  assign g = ps & pc;

  assign #1 magnitude = ~(&p[`DIVLEN+2:`DIVLEN]);
  assign #1 cout = g[`DIVLEN+2] | (p[`DIVLEN+2] & (g[`DIVLEN+1] | p[`DIVLEN+1] & g[`DIVLEN]));
  assign #1 sign = p[`DIVLEN+3] ^ cout;
/*  assign #1 magnitude = ~((ps[54]^pc[54]) & (ps[53]^pc[53]) & 
			  (ps[52]^pc[52]));
  assign #1 sign = (ps[55]^pc[55])^
      (ps[54] & pc[54] | ((ps[54]^pc[54]) &
			    (ps[53]&pc[53] | ((ps[53]^pc[53]) &
						(ps[52]&pc[52]))))); */

  // Produce quotient = +1, 0, or -1
  assign #1 qp = magnitude & ~sign;
  assign #1 qz = ~magnitude;
  assign #1 qm = magnitude & sign;
endmodule

////////////////////////////////////
// Adder Input Selection, Radix 2 //
////////////////////////////////////
module fsel2 (
  input  logic sp, sn,
  input  logic [`DIVLEN+3:0] C, S, SM,
  output logic [`DIVLEN+3:0] F
);
  logic [`DIVLEN+3:0] FP, FN;
  
  // Generate for both positive and negative bits
  assign FP = ~S & C;
  assign FN = SM | (C & (~C << 2));

  // Choose which adder input will be used

  assign F = sp ? FP : (sn ? FN : (`DIVLEN+4){1'b0});

endmodule

///////////////////////////////////
// On-The-Fly Converter, Radix 2 //
///////////////////////////////////
module otfc2 #(parameter N=64) (
  input  logic         clk,
  input  logic         Start,
  input  logic         qp, qz, qm,
  output logic [N-1:0] r
);

  //  The on-the-fly converter transfers the quotient 
  //  bits to the quotient as they come. 
  //
  //  This code follows the psuedocode presented in the 
  //  floating point chapter of the book. Right now, 
  //  it is written for Radix-2 division.
  //
  //  QM is Q-1. It allows us to write negative bits 
  //  without using a costly CPA. 
  logic [N+2:0] Q, QM, QNext, QMNext, QMMux;
  //  QR and QMR are the shifted versions of Q and QM.
  //  They are treated as [N-1:r] size signals, and 
  //  discard the r most significant bits of Q and QM. 
  logic [N+1:0] QR, QMR;

  flopr #(N+3) Qreg(clk, Start, QNext, Q);
  mux2 #(`DIVLEN+3) QMmux(QMNext, {`DIVLEN+3{1'b1}}, Start, QMMux);
  flop #(`DIVLEN+3) QMreg(clk, QMMux, QM);

  always_comb begin
    QR  = Q[N+1:0];
    QMR = QM[N+1:0];     // Shift Q and QM
    if (qp) begin
      QNext  = {QR,  1'b1};
      QMNext = {QR,  1'b0};
    end else if (qz) begin
      QNext  = {QR,  1'b0};
      QMNext = {QMR, 1'b1};
    end else begin        // If qp and qz are not true, then qm is
      QNext  = {QMR, 1'b1};
      QMNext = {QMR, 1'b0};
    end 
  end
  assign r = Q[N+2] ? Q[N+1:2] : Q[N:1];

endmodule

///////////////////////////////
// Square Root OTFC, Radix 2 //
///////////////////////////////
module softc2(
  input  logic clk,
  input  logic Start,
  input  logic sp, sn,
  output logic S,
);

endmodule
/////////////
// counter //
/////////////
module counter(input  logic clk, 
               input  logic req, 
               input  logic [$clog2(`XLEN+1)-1:0] dur,
               output logic done);
 
   logic    [$clog2(`XLEN+1)-1:0]  count;

  // This block of control logic sequences the divider
  // through its iterations.  You may modify it if you
  // build a divider which completes in fewer iterations.
  // You are not responsible for the (trivial) circuit
  // design of the block.

  always @(posedge clk)
    begin
      if      (count == dur) done <= #1 1;
      else if (done | req) done <= #1 0;	
      if (req) count <= #1 0;
      else     count <= #1 count+1;
    end
endmodule

//////////
// mux3 //
//////////
module mux3onehot #(parameter N=65) (
  input  logic [N+3:0] in0, in1, in2,
  input  logic         sel0, sel1, sel2,
  output logic [N+3:0] out
);

  // lazy inspection of the selects
  // really we should make sure selects are mutually exclusive
  assign #1 out = sel0 ? in0 : (sel1 ? in1 : in2);
endmodule


/////////
// csa //
/////////
module csa #(parameter N=69) (
  input  logic [N-1:0] in1, in2, in3, 
  input  logic         cin, 
  output logic [N-1:0] out1, out2
);

  // This block adds in1, in2, in3, and cin to produce 
  // a result out1 / out2 in carry-save redundant form.
  // cin is just added to the least significant bit and
  // is required to handle adding a negative divisor.
  // Fortunately, the carry (out2) is shifted left by one
  // bit, leaving room in the least significant bit to 
  // insert cin.

  assign #1 out1 = in1 ^ in2 ^ in3;
  assign #1 out2 = {in1[N-2:0] & (in2[N-2:0] | in3[N-2:0]) | 
		    (in2[N-2:0] & in3[N-2:0]), cin};
endmodule


//////////////
// expcalc  //
//////////////
module expcalc(
  input  logic [`NE-1:0] XExp, YExp,
  input  logic           Sqrt,
  output logic [`NE-1:0] calcExp
);
  logic        [`NE-1:0] SExp, DExp, SXExp;
  assign SXExp = XExp - (`NE)'(`BIAS);
  assign SExp  = {1'b0, SXExp[`NE-1:1]} + (`NE)'(`BIAS);
  assign DExp  = XExp - YExp + (`NE)'(`BIAS);
  assign calcExp = Sqrt ? SExp : DExp;

endmodule

//////////////
// signcalc //
//////////////
module signcalc(
  input logic  XSign, YSign,
  output logic calcSign
);

  assign calcSign = XSign ^ YSign;

endmodule
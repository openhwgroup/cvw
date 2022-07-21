///////////////////////////////////////////
// srt.sv
//
// Written: David_Harris@hmc.edu 13 January 2022
// Modified: cturek@hmc.edu July 2022
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

module srt (
  input  logic clk,
  input  logic Start, 
  input  logic Stall, // *** multiple pipe stages
  input  logic Flush, // *** multiple pipe stages
  // Floating Point
  input  logic       XSign, YSign,
  input  logic [`NE-1:0] XExp, YExp,
  input  logic [`NF-1:0] SrcXFrac, SrcYFrac,
  // Integer
  input  logic [`XLEN-1:0] SrcA, SrcB,
  // Customization
  input  logic [1:0] Fmt, // Floats: 00 = 16 bit, 01 = 32 bit, 10 = 64 bit, 11 = 128 bit
  input  logic       W64, // 32-bit ints on XLEN=64
  // Selection
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic       rsign, done,
  output logic [`DIVLEN-1:0] Rem, Result,
  output logic [`NE-1:0] rExp,
  output logic [3:0] Flags
);

  logic                       qp, qz, qn; // result bits are +1, 0, or -1
  logic [`NE-1:0]             calcExp;
  logic                       calcSign;
  logic [`DIVLEN+3:0]         X, Dpreproc, C, F, S, SM, AddIn;
  logic [`DIVLEN+3:0]         WS, WSA, WSN, WC, WCA, WCN, D, Db, Dsel;
  logic [$clog2(`XLEN+1)-1:0] zeroCntD, intExp, dur, calcDur;
  logic                       intSign;
  logic                       cin;
 
  srtpreproc preproc(SrcA, SrcB, SrcXFrac, SrcYFrac, XExp, Fmt, W64, Signed, Int, Sqrt, X, Dpreproc, zeroCntD, intExp, calcDur, intSign);

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
  qsel2 qsel2(WS[`DIVLEN+3:`DIVLEN], WC[`DIVLEN+3:`DIVLEN], Sqrt, qp, qz, qn);

  flopen #(`NE) expflop(clk, Start, calcExp, rExp);
  flopen #(1) signflop(clk, Start, calcSign, rsign);
  flopen #(7) durflop(clk, Start, calcDur, dur);
  
  srtcounter divcounter(clk, Start, dur, done);

  // Divisor Selection logic
  assign Db = ~D;
  mux3onehot #(`DIVLEN) divisorsel(Db, {(`DIVLEN+4){1'b0}}, D, qp, qz, qn, Dsel);

  // If only implementing division, use divide otfc
  // otfc2  #(`DIVLEN) otfc2(clk, Start, qp, qz, qn, Quot);
  // otherwise use sotfc
  creg   sotfcC(clk, Start, Sqrt, C);
  sotfc2 sotfc2(clk, Start, qp, qn, Sqrt, C, S, SM);
  fsel2 fsel(qp, qn, C, S, SM, F);

  // Adder input selection
  assign AddIn = Sqrt ? F : Dsel;

  // Partial Product Generation
  assign cin = ~Sqrt & qp;
  csa    #(`DIVLEN+4) csa(WS, WC, AddIn, cin, WSA, WCA);
  
  expcalc expcalc(.XExp, .YExp, .calcExp, .Sqrt);

  srtpostproc postproc(.WS, .WC, .X, .D, .S, .SM, .dur, .zeroCntD, .XSign, .YSign, .Signed, .Int, .Result, .Rem, .calcSign);
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
  output logic [$clog2(`XLEN+1)-1:0] zeroCntB, intExp, dur, // Quotient integer exponent
  output logic       intSign // Quotient integer sign
);

  logic  [$clog2(`XLEN+1)-1:0] zeroCntA;
  logic  [`XLEN-1:0] PosA, PosB;
  logic  [`DIVLEN-1:0] ExtraA, ExtraB, PreprocA, PreprocB, PreprocX, PreprocY, DivX;
  logic  [`NF+4:0] SqrtX;

  // Generate positive integer inputs if they are signed
  assign PosA = (Signed & SrcA[`XLEN - 1]) ? -SrcA : SrcA;
  assign PosB = (Signed & SrcB[`XLEN - 1]) ? -SrcB : SrcB;

  // Calculate leading zeros of integer inputs
  lzc #(`XLEN) lzcA (PosA, zeroCntA);
  lzc #(`XLEN) lzcB (PosB, zeroCntB);

  // Make integers have DIVLEN bits
  assign ExtraA = {PosA, {`EXTRAINTBITS{1'b0}}};
  assign ExtraB = {PosB, {`EXTRAINTBITS{1'b0}}};

  // Shift integers to have leading ones
  assign PreprocA = ExtraA << (zeroCntA + 1);
  assign PreprocB = ExtraB << (zeroCntB + 1);

  // Make mantissas have DIVLEN bits
  assign PreprocX = {SrcXFrac, {`EXTRAFRACBITS{1'b0}}};
  assign PreprocY = {SrcYFrac, {`EXTRAFRACBITS{1'b0}}};

  // Selecting correct divider inputs
  assign DivX = Int ? PreprocA : PreprocX;
  assign SqrtX = XExp[0] ? {5'b11101, SrcXFrac} : {4'b1111, SrcXFrac, 1'b0};
  assign X = Sqrt ? {SqrtX, {(`EXTRAFRACBITS-1){1'b0}}} : {4'b0001, DivX};
  assign D = {4'b0001, Int ? PreprocB : PreprocY};

  // Integer exponent and sign calculations
  assign intExp = zeroCntB - zeroCntA + 1;
  assign intSign = Signed & (SrcA[`XLEN - 1] ^ SrcB[`XLEN - 1]);

  // Number of cycles of divider
  assign dur = Int ? (intExp & {7{~intExp[6]}}) : (7)'(`DIVLEN);
endmodule

/////////////////////////////////
// Quotient Selection, Radix 2 //
/////////////////////////////////
module qsel2 (
  input  logic [`DIVLEN+3:`DIVLEN] ps, pc, 
  input  logic         Sqrt,
  output logic         qp, qz, qn
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
  assign #1 cout = g[`DIVLEN+2] | (p[`DIVLEN+2] & (g[`DIVLEN+1] | p[`DIVLEN+1] & (g[`DIVLEN])));
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
  assign #1 qn = magnitude & sign;
endmodule

////////////////////////////////////
// Adder Input Selection, Radix 2 //
////////////////////////////////////
module fsel2 (
  input  logic sp, sn,
  input  logic [`DIVLEN+3:0] C, S, SM,
  output logic [`DIVLEN+3:0] F
);
  logic [`DIVLEN+3:0] FP, FN, FZ;
  
  // Generate for both positive and negative bits
  assign FP = ~(S << 1) & C;
  assign FN = (SM << 1) | (C & (~C << 2));
  assign FZ = '0;

  // Choose which adder input will be used

  always_comb
    if (sp)       F = FP;
    else if (sn)  F = FN;
    else          F = FZ;

  // assign F = sp ? FP : (sn ? FN : FZ);

endmodule

///////////////////////////////////
// On-The-Fly Converter, Radix 2 //
///////////////////////////////////
module otfc2 #(parameter N=66) (
  input  logic         clk,
  input  logic         Start,
  input  logic         qp, qz, qn,
  output logic [N-3:0] Result
);
  //  The on-the-fly converter transfers the quotient 
  //  bits to the quotient as they come.
  //  Use this otfc for division only.
  logic [N+2:0] Q, QM, QNext, QMNext, QMMux;
  logic [N+1:0] QR, QMR;

  flopr #(N+3) Qreg(clk, Start, QNext, Q);
  mux2 #(`DIVLEN+3) Qmux(QMNext, {(`DIVLEN+3){1'b1}}, Start, QMMux);
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
    end else begin        // If qp and qz are not true, then qn is
      QNext  = {QMR, 1'b1};
      QMNext = {QMR, 1'b0};
    end 
  end
  assign Result = Q[N] ? Q[N-1:2] : Q[N-2:1];

endmodule

///////////////////////////////
// Square Root OTFC, Radix 2 //
///////////////////////////////
module sotfc2(
  input  logic         clk,
  input  logic         Start,
  input  logic         sp, sn,
  input  logic         Sqrt,
  input  logic [`DIVLEN+3:0] C,
  output logic [`DIVLEN+3:0] S, SM
);
  //  The on-the-fly converter transfers the square root 
  //  bits to the quotient as they come.
  //  Use this otfc for division and square root.
  logic [`DIVLEN+3:0] SNext, SMNext, SMux;

  flopr #(`DIVLEN+4) SMreg(clk, Start, SMNext, SM);
  mux2 #(`DIVLEN+4) Smux(SNext, {3'b000, Sqrt, {(`DIVLEN){1'b0}}}, Start, SMux);
  flop #(`DIVLEN+4) Sreg(clk, SMux, S);

  always_comb begin
    if (sp) begin
      SNext  = S | (C & ~(C << 1));
      SMNext = S;
    end else if (sn) begin
      SNext  = SM | (C & ~(C << 1));
      SMNext = SM;
    end else begin        // If sp and sn are not true, then sz is
      SNext  = S;
      SMNext = SM | (C & ~(C << 1));
    end 
  end
endmodule

//////////////////////////
// C Register for SOTFC //
//////////////////////////
module creg(input  logic clk,
            input  logic Start,
            input  logic Sqrt,
            output logic [`DIVLEN+3:0] C
);
  logic [`DIVLEN+3:0] CMux;

  mux2 #(`DIVLEN+4) Cmux({1'b1, C[`DIVLEN+3:1]}, {4'b1111, Sqrt, {(`DIVLEN-1){1'b0}}}, Start, CMux);
  flop #(`DIVLEN+4) cflop(clk, CMux, C);
endmodule

/////////////
// counter //
/////////////
module srtcounter(input  logic clk, 
                  input  logic req, 
                  input  logic [$clog2(`XLEN+1)-1:0] dur,
                  output logic done
);
 
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

module srtpostproc(
  input  logic [`DIVLEN+3:0] WS, WC, X, D, S, SM,
  input  logic [$clog2(`XLEN+1)-1:0] dur, zeroCntD,
  input  logic XSign, YSign, Signed, Int,
  output logic [`DIVLEN-1:0]   Result, Rem,
  output logic calcSign
);
  logic [`DIVLEN+3:0] W, shiftRem, intRem, intS; 
  logic [`DIVLEN-1:0] floatRes, intRes;
  logic               WSign;

  assign W = WS + WC;
  assign WSign = W[`DIVLEN+3];
  // Remainder handling
  always_comb begin
    if (zeroCntD == ($clog2(`XLEN+1))'(`XLEN)) begin
      intRem = X;
      intS = -1;
    end
    else if (~Signed) begin
      if (WSign) begin
        intRem = W + D;
        intS = SM;
      end else begin 
        intRem = W;
        intS = S;
      end
    end
    else case ({YSign, XSign, WSign})
      3'b000: begin
        intRem = W; 
        intS = S; 
      end
      3'b001: begin
        intRem = W + D;
        intS = SM;
      end
      3'b010: begin
        intRem = W - D;
        intS = ~S;
      end
      3'b011: begin
        intRem = W;
        intS = ~SM;
      end
      3'b100: begin
        intRem = W;
        intS = ~SM;
      end
      3'b101: begin
        intRem = W + D;
        intS = ~SM + 1;
      end 
      3'b110: begin
        intRem = W - D;
        intS = S + 1;
      end 
      3'b111: begin
        intRem = W;
        intS = S;
      end
    endcase
  end
  assign floatRes = S[`DIVLEN] ? S[`DIVLEN:1] : S[`DIVLEN-1:0];
  assign intRes = intS[`DIVLEN] ? intS[`DIVLEN:1] : intS[`DIVLEN-1:0];
  assign Result = Int ? intRes : floatRes;
  assign calcSign = XSign ^ YSign;
  assign shiftRem = intRem >>> dur;
  assign Rem = shiftRem[`DIVLEN-1:0];
endmodule


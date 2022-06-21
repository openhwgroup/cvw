///////////////////////////////////////////
// srt.sv
//
// Written: David_Harris@hmc.edu 13 January 2022
// Modified: 
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

`define DIVLEN ((`NF<(`XLEN)) ? (`XLEN) : `NF)

module srtradix4 (
  input  logic clk,
  input  logic Start, 
  input  logic Stall, // *** multiple pipe stages
  input  logic Flush, // *** multiple pipe stages
  // Floating Point Inputs
  // later add exponents, signs, special cases
  input  logic       XSign, YSign,
  input  logic [`NE-1:0] XExp, YExp,
  input  logic [`NF-1:0] XFrac, YFrac,
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic [1:0] Fmt, // Floats: 00 = 16 bit, 01 = 32 bit, 10 = 64 bit, 11 = 128 bit
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic       rsign,
  output logic [`DIVLEN-1:0] Quot, Rem, // *** later handle integers
  output logic [`NE-1:0] rExp,
  output logic [3:0] Flags
);

  // logic           qp, qz, qm; // quotient is +1, 0, or -1
  logic [3:0]     q;
  logic [`NE-1:0] calcExp;
  logic           calcSign;
  logic [`DIVLEN-1:0]  X, Dpreproc;
  logic [`DIVLEN+3:0]  WS, WSA, WSN;
  logic [`DIVLEN+3:0]  WC, WCA, WCN;
  logic [`DIVLEN+3:0]  D, DBar, D2, DBar2, Dsel;
  logic [$clog2(`XLEN+1)-1:0] intExp;
  logic           intSign;
 
  srtpreproc preproc(SrcA, SrcB, XFrac, YFrac, Fmt, W64, Signed, Int, Sqrt, X, Dpreproc, intExp, intSign);

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  //  - assumed one is added here since all numbers are normlaized
  //    *** wait what about zero? is that specal case? can the divider handle it?
  //  - when the start signal is asserted X and 0 are loaded into WS and WC
  //  - otherwise load WSA into the flipflop
  //  *** what does N and A stand for?
  //  *** change shift amount for radix4
  mux2   #(`DIVLEN+4) wsmux({WSA[`DIVLEN+1:0], 2'b0}, {4'b0001, X}, Start, WSN);
  flop   #(`DIVLEN+4) wsflop(clk, WSN, WS);
  mux2   #(`DIVLEN+4) wcmux({WCA[`DIVLEN+1:0], 2'b0}, {`DIVLEN+4{1'b0}}, Start, WCN);
  flop   #(`DIVLEN+4) wcflop(clk, WCN, WC);
  flopen #(`DIVLEN+4) dflop(clk, Start, {4'b0001, Dpreproc}, D);

  // Quotient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  // *** change this for radix 4 - generate w/ stine code
  // q encoding:
	// 1000 = +2
	// 0100 = +1
	// 0000 =  0
	// 0010 = -1
	// 0001 = -2
  qsel4 qsel4(.D, .WS, .WC, .q);

  // Store the expoenent and sign until division is done
  flopen #(`NE) expflop(clk, Start, calcExp, rExp);
  flopen #(1) signflop(clk, Start, calcSign, rsign);

  // Divisor Selection logic
  // *** radix 4 change to choose -2 to 2
  // - choose the negitive version of what's being selected
  assign DBar = ~D;
  assign DBar2 = {~D[`DIVLEN+2:0], 1'b1};
  assign D2 = {D[`DIVLEN+2:0], 1'b0};

  always_comb
    case (q)
      4'b1000: Dsel = DBar2;
      4'b0100: Dsel = DBar;
      4'b0000: Dsel = {(`DIVLEN+4){1'b0}};
      4'b0010: Dsel = D;
      4'b0001: Dsel = D2;
      default: Dsel = {`DIVLEN+4{1'bx}};
    endcase

  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  csa    #(`DIVLEN+4) csa(WS, WC, Dsel, |q[3:2], WSA, WCA);
  
  //*** change for radix 4
  otfc4  #(`DIVLEN) otfc4(clk, Start, q, Quot);

  expcalc expcalc(.XExp, .YExp, .calcExp);

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
  input  logic [`NF-1:0] XFrac, YFrac,
  input  logic [1:0] Fmt, // Floats: 00 = 16 bit, 01 = 32 bit, 10 = 64 bit, 11 = 128 bit
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic [`DIVLEN-1:0] X, D,
  output logic [$clog2(`XLEN+1)-1:0] intExp, // Quotient integer exponent
  output logic       intSign // Quotient integer sign
);

  logic  [$clog2(`XLEN+1)-1:0] zeroCntA, zeroCntB;
  logic  [`XLEN-1:0] PosA, PosB;
  logic  [`DIVLEN-1:0] ExtraA, ExtraB, PreprocA, PreprocB, PreprocX, PreprocY;

  assign PosA = (Signed & SrcA[`XLEN - 1]) ? -SrcA : SrcA;
  assign PosB = (Signed & SrcB[`XLEN - 1]) ? -SrcB : SrcB;

  lzc #(`XLEN) lzcA (PosA, zeroCntA);
  lzc #(`XLEN) lzcB (PosB, zeroCntB);

  assign ExtraA = {PosA, {`DIVLEN-`XLEN{1'b0}}};
  assign ExtraB = {PosB, {`DIVLEN-`XLEN{1'b0}}};

  assign PreprocA = ExtraA << zeroCntA;
  assign PreprocB = ExtraB << (zeroCntB + 1);
  assign PreprocX = {XFrac, {`DIVLEN-`NF{1'b0}}};
  assign PreprocY = {YFrac, {`DIVLEN-`NF{1'b0}}};

  
  assign X = Int ? PreprocA : PreprocX;
  assign D = Int ? PreprocB : PreprocY;
  assign intExp = zeroCntB - zeroCntA + 1;
  assign intSign = Signed & (SrcA[`XLEN - 1] ^ SrcB[`XLEN - 1]);
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


///////////////////////////////////
// On-The-Fly Converter, Radix 2 //
///////////////////////////////////
module otfc4 #(parameter N=65) (
  input  logic         clk,
  input  logic         Start,
  input  logic [3:0]   q,
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
  logic [N+2:0] Q, QM, QNext, QMNext, QMux, QMMux;
  //  QR and QMR are the shifted versions of Q and QM.
  //  They are treated as [N-1:r] size signals, and 
  //  discard the r most significant bits of Q and QM. 
  logic [N:0] QR, QMR;
  // if starting a new divison set Q to 0 and QM to -1
  mux2 #(N+3) Qmux(QNext, {N+3{1'b0}}, Start, QMux);
  mux2 #(N+3) QMmux(QMNext, {N+3{1'b1}}, Start, QMMux);
  flop #(N+3) Qreg(clk, QMux, Q);
  flop #(N+3) QMreg(clk, QMMux, QM);

  // shift Q (quotent) and QM (quotent-1)
		// if 	q = 2  	    Q = {Q, 10} 	QM = {Q, 01}		
		// else if 	q = 1   Q = {Q, 01} 	QM = {Q, 00}	
		// else if 	q = 0   Q = {Q, 00} 	QM = {QM, 11}	
		// else if 	q = -1	Q = {QM, 11} 	QM = {QM, 10}
		// else if 	q = -2	Q = {QM, 10} 	QM = {QM, 01}
    // *** how does the 0 concatination numbers work?



  always_comb begin
    QR  = Q[N:0];
    QMR = QM[N:0];     // Shift Q and QM
    if (q[3]) begin // +2
      QNext  = {QR,  2'b10};
      QMNext = {QR,  2'b01};
    end else if (q[2]) begin // +1
      QNext  = {QR,  2'b01};
      QMNext = {QR,  2'b00};
    end else if (q[1]) begin // -1
      QNext  = {QMR,  2'b11};
      QMNext = {QMR,  2'b10};
    end else if (q[0]) begin // -2
      QNext  = {QMR,  2'b10};
      QMNext = {QMR,  2'b01};
    end else begin           // 0
      QNext  = {QR,  2'b00};
      QMNext = {QMR, 2'b11};
    end 
  end
  assign r = Q[N+2] ? Q[N+1:2] : Q[N:1];

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
  input logic  [`NE-1:0] XExp, YExp,
  output logic [`NE-1:0] calcExp
);

  assign calcExp = XExp - YExp + (`NE)'(`BIAS);

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
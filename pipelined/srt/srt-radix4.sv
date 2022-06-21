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
  input  logic DivStart, 
  input  logic       XSgnE, YSgnE,
  input  logic [`NE-1:0] XExpE, YExpE,
  input  logic [`NF-1:0] XFrac, YFrac,
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic       DivDone,
  output logic       DivSgn,
  output logic [`DIVLEN-1:0] Quot, Rem, // *** later handle integers
  output logic [`NE-1:0] DivExp
);

  // logic           qp, qz, qm; // quotient is +1, 0, or -1
  logic [3:0]     q;
  logic [`NE-1:0] DivCalcExp;
  logic           calcSign;
  logic [`DIVLEN-1:0]  X, Dpreproc;
  logic [`DIVLEN+3:0]  WS, WSA, WSN;
  logic [`DIVLEN+3:0]  WC, WCA, WCN;
  logic [`DIVLEN+3:0]  D, DBar, D2, DBar2, Dsel;
  logic [$clog2(`XLEN+1)-1:0] intExp;
  logic           intSign;
 
  srtpreproc preproc(SrcA, SrcB, XFrac, YFrac, W64, Signed, Int, Sqrt, X, Dpreproc, intExp, intSign);

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
  mux2   #(`DIVLEN+4) wsmux({WSA[`DIVLEN+1:0], 2'b0}, {4'b0001, X}, DivStart, WSN);
  flop   #(`DIVLEN+4) wsflop(clk, WSN, WS);
  mux2   #(`DIVLEN+4) wcmux({WCA[`DIVLEN+1:0], 2'b0}, {`DIVLEN+4{1'b0}}, DivStart, WCN);
  flop   #(`DIVLEN+4) wcflop(clk, WCN, WC);
  flopen #(`DIVLEN+4) dflop(clk, DivStart, {4'b0001, Dpreproc}, D);

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

  // Store the expoenent and sign until division is DivDone
  flopen #(`NE) expflop(clk, DivStart, DivCalcExp, DivExp);
  flopen #(1) signflop(clk, DivStart, calcSign, DivSgn);

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
  otfc4  #(`DIVLEN) otfc4(clk, DivStart, q, Quot);

  expcalc expcalc(.XExpE, .YExpE, .DivCalcExp);

  signcalc signcalc(.XSgnE, .YSgnE, .calcSign);

  counter counter(clk, DivStart, DivDone);

endmodule

////////////////
// Submodules //
////////////////

/////////////
// counter //
/////////////
module counter(input  logic clk, 
               input  logic DivStart, 
               output logic DivDone);
 
   logic    [5:0]  count;

  // This block of control logic sequences the divider
  // through its iterations.  You may modify it if you
  // build a divider which completes in fewer iterations.
  // You are not responsible for the (trivial) circuit
  // design of the block.

  always @(posedge clk)
    begin
      if      (count == `DIVLEN/2+1) DivDone <= #1 1;
      else if (DivDone | DivStart) DivDone <= #1 0;	
      if (DivStart) count <= #1 0;
      else     count <= #1 count+1;
    end
endmodule

module qsel4 (
	input logic [`DIVLEN+3:0] D,
	input logic [`DIVLEN+3:0] WS, WC,
	output logic [3:0] q
);
	logic [6:0] Wmsbs;
	logic [7:0] PreWmsbs;
	logic [2:0] Dmsbs;
	assign PreWmsbs = WC[`DIVLEN+3:`DIVLEN-4] + WS[`DIVLEN+3:`DIVLEN-4];
	assign Wmsbs = PreWmsbs[7:1];
	assign Dmsbs = D[`DIVLEN-1:`DIVLEN-3];
	// D = 0001.xxx...
	// Dmsbs = |   |
  // W =      xxxx.xxx...
	// Wmsbs = |        |

	logic [3:0] QSel4[1023:0];
	initial $readmemh("qslc_r4a2b.tv", QSel4);
	assign q = QSel4[{Dmsbs,Wmsbs}];
	
endmodule

///////////////////
// Preprocessing //
///////////////////
module srtpreproc (
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic [`NF-1:0] XFrac, YFrac,
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

///////////////////////////////////
// On-The-Fly Converter, Radix 2 //
///////////////////////////////////
module otfc4 #(parameter N=65) (
  input  logic         clk,
  input  logic         DivStart,
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
  mux2 #(N+3) Qmux(QNext, {N+3{1'b0}}, DivStart, QMux);
  mux2 #(N+3) QMmux(QMNext, {N+3{1'b1}}, DivStart, QMMux);
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
  // is Startuired to handle adding a negative divisor.
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
  input logic  [`NE-1:0] XExpE, YExpE,
  output logic [`NE-1:0] DivCalcExp
);

  assign DivCalcExp = XExpE - YExpE + (`NE)'(`BIAS);

endmodule

//////////////
// signcalc //
//////////////
module signcalc(
  input logic  XSgnE, YSgnE,
  output logic calcSign
);

  assign calcSign = XSgnE ^ YSgnE;

endmodule
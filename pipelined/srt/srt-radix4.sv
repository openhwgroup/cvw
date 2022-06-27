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

module srtradix4 (
  input  logic clk,
  input  logic DivStart, 
  input  logic [`NE-1:0] XExpE, YExpE,
  input  logic [`NF:0] XManE, YManE,
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic XInfE, YInfE, 
  input  logic XZeroE, YZeroE, 
  input  logic XNaNE, YNaNE, 
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic [$clog2(`DIVLEN/2+3)-1:0] EarlyTermShiftDiv2E,
  output logic       DivDone,
  output logic       DivStickyE,
  output logic       DivNegStickyE,
  output logic [`DIVLEN+2:0] Quot,
  output logic [`XLEN-1:0] Rem, // *** later handle integers
  output logic [`NE+1:0] DivCalcExpE
);

  logic [3:0]     q;
  logic [`NE+1:0] DivCalcExp;
  logic [`DIVLEN-1:0]    X;
  logic [`DIVLEN-1:0]  Dpreproc;
  logic [`DIVLEN+3:0]  WS, WSA, WSN;
  logic [`DIVLEN+3:0]  WC, WCA, WCN;
  logic [`DIVLEN+3:0]  D, DBar, D2, DBar2, Dsel;
  logic [$clog2(`XLEN+1)-1:0] intExp;
  logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt;
  logic           intSign;
 
  srtpreproc preproc(.SrcA, .SrcB, .XManE, .YManE, .W64, .Signed, .Int, .Sqrt, .X, 
                    .XZeroCnt, .YZeroCnt, .Dpreproc, .intExp, .intSign);

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  //  - when the start signal is asserted X and 0 are loaded into WS and WC
  //  - otherwise load WSA into the flipflop
  //  - the assumed one is added to D since it's always normalized (and X/0 is a special case handeled by result selection)
  //  - XZeroE is used as the assumed one to avoid creating a sticky bit - all other numbers are normalized
  mux2   #(`DIVLEN+4) wsmux({WSA[`DIVLEN+1:0], 2'b0}, {3'b000, ~XZeroE, X}, DivStart, WSN);
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
  flopen #(`NE+2) expflop(clk, DivStart, DivCalcExp, DivCalcExpE);

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
  otfc4 otfc4(.clk, .DivStart, .q, .Quot);

  expcalc expcalc(.XExpE, .YExpE, .XZeroE, .XZeroCnt, .YZeroCnt, .DivCalcExp);

  earlytermination earlytermination(.clk, .WC, .WS, .XZeroE, .YZeroE, .XInfE, .EarlyTermShiftDiv2E,
                  .YInfE, .XNaNE, .YNaNE, .DivStickyE, .DivNegStickyE, .DivStart, .DivDone);

endmodule

////////////////
// Submodules //
////////////////

module earlytermination(
  input  logic clk, 
	input logic [`DIVLEN+3:0] WS, WC,
  input  logic XInfE, YInfE, 
  input  logic XZeroE, YZeroE, 
  input  logic XNaNE, YNaNE, 
  input  logic DivStart, 
  output logic [$clog2(`DIVLEN/2+3)-1:0] EarlyTermShiftDiv2E,
  output logic DivStickyE,
  output logic DivNegStickyE,
  output logic DivDone);
 
   logic [$clog2(`DIVLEN/2+3)-1:0]  Count;
   logic WZero;

   assign WZero = (WS+WC == 0)|XZeroE|YZeroE|XInfE|YInfE|XNaNE|YNaNE; //*** temporary
   // *** rather than Counting should just be able to check if one of the two msbs of the quotent is 1 then stop???
  assign DivDone = (DivStickyE | WZero);
  assign DivStickyE = ~|Count;
  assign DivNegStickyE = $signed(WS+WC) < 0;
  assign EarlyTermShiftDiv2E = Count;
  // +1 for setup
  // `DIVLEN/2 to get required number of bits
  // +1 for possible .5 and round bit
  // Count down Counter
  always @(posedge clk)
    begin
      if (DivStart) Count <= #1 `DIVLEN/2+2;
      else     Count <= #1 Count-1;
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

  initial begin 
    integer d, w, i, w2;
    for(d=0; d<8; d++)
      for(w=0; w<128; w++)begin
        i = d*128+w;
        w2 = w-128*(w>=64); // convert to two's complement
        case(d)
          0: if($signed(w2)>=$signed(12))      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-4)  QSel4[i] = 4'b0000; 
            else if(w2>=-13) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          1: if(w2>=14)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-15) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          2: if(w2>=15)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-16) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          3: if(w2>=16)      QSel4[i] = 4'b1000;
            else if(w2>=4)   QSel4[i] = 4'b0100; 
            else if(w2>=-6)  QSel4[i] = 4'b0000; 
            else if(w2>=-18) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          4: if(w2>=18)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-20) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          5: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=6)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-20) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          6: if(w2>=20)      QSel4[i] = 4'b1000;
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-22) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
          7: if(w2>=24)      QSel4[i] = 4'b1000;
            else if(w2>=8)   QSel4[i] = 4'b0100; 
            else if(w2>=-8)  QSel4[i] = 4'b0000; 
            else if(w2>=-24) QSel4[i] = 4'b0010; 
            else            QSel4[i] = 4'b0001; 
        endcase
      end
  end
	assign q = QSel4[{Dmsbs,Wmsbs}];
	
endmodule

///////////////////
// Preprocessing //
///////////////////
module srtpreproc (
  input  logic [`XLEN-1:0] SrcA, SrcB,
  input  logic [`NF:0] XManE, YManE,
  input  logic       W64, // 32-bit ints on XLEN=64
  input  logic       Signed, // Interpret integers as signed 2's complement
  input  logic       Int, // Choose integer inputs
  input  logic       Sqrt, // perform square root, not divide
  output logic [`DIVLEN-1:0] X,
  output logic [`DIVLEN-1:0] Dpreproc,
  output logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  output logic [$clog2(`XLEN+1)-1:0] intExp, // Quotient integer exponent
  output logic       intSign // Quotient integer sign
);
  // logic  [`XLEN-1:0] PosA, PosB;
  // logic  [`DIVLEN-1:0] ExtraA, ExtraB, PreprocA, PreprocB, PreprocX, PreprocY;
  logic  [`DIVLEN-1:0] PreprocA, PreprocX;
  logic  [`DIVLEN-1:0] PreprocB, PreprocY;

  // assign PosA = (Signed & SrcA[`XLEN - 1]) ? -SrcA : SrcA;
  // assign PosB = (Signed & SrcB[`XLEN - 1]) ? -SrcB : SrcB;
  // lzc #(`XLEN) lzcA (PosA, zeroCntA);
  // lzc #(`XLEN) lzcB (PosB, zeroCntB);

  // ***can probably merge X LZC with conversion
  // cout the number of leading zeros
  lzc #(`NF+1) lzcA (XManE, XZeroCnt);
  lzc #(`NF+1) lzcB (YManE, YZeroCnt);

  // assign ExtraA = {PosA, {`DIVLEN-`XLEN{1'b0}}};
  // assign ExtraB = {PosB, {`DIVLEN-`XLEN{1'b0}}};

  // assign PreprocA = ExtraA << zeroCntA;
  // assign PreprocB = ExtraB << (zeroCntB + 1);
  assign PreprocX = {XManE[`NF-1:0]<<XZeroCnt, {`DIVLEN-`NF{1'b0}}};
  assign PreprocY = {YManE[`NF-1:0]<<YZeroCnt, {`DIVLEN-`NF{1'b0}}};

  
  assign X = Int ? PreprocA : PreprocX;
  assign Dpreproc = Int ? PreprocB : PreprocY;
  // assign intExp = zeroCntB - zeroCntA + 1;
  // assign intSign = Signed & (SrcA[`XLEN - 1] ^ SrcB[`XLEN - 1]);
endmodule

///////////////////////////////////
// On-The-Fly Converter, Radix 2 //
///////////////////////////////////
module otfc4 (
  input  logic         clk,
  input  logic         DivStart,
  input  logic [3:0]   q,
  output logic [`DIVLEN+2:0] Quot
);

  //  The on-the-fly converter transfers the quotient 
  //  bits to the quotient as they come. 
  //
  //  This code follows the psuedocode presented in the 
  //  floating point chapter of the book. Right now, 
  //  it is written for Radix-4 division.
  //
  //  QM is Q-1. It allows us to write negative bits 
  //  without using a costly CPA. 
  logic [`DIVLEN+2:0] QM, QNext, QMNext, QMux, QMMux;
  //  QR and QMR are the shifted versions of Q and QM.
  //  They are treated as [N-1:r] size signals, and 
  //  discard the r most significant bits of Q and QM. 
  logic [`DIVLEN:0] QR, QMR;
  // if starting a new divison set Q to 0 and QM to -1
  mux2 #(`DIVLEN+3) Qmux(QNext, {`DIVLEN+3{1'b0}}, DivStart, QMux);
  mux2 #(`DIVLEN+3) QMmux(QMNext, {`DIVLEN+3{1'b1}}, DivStart, QMMux);
  flop #(`DIVLEN+3) Qreg(clk, QMux, Quot); // *** have to connect Quot directly to M stage
  flop #(`DIVLEN+3) QMreg(clk, QMMux, QM);

  // shift Q (quotent) and QM (quotent-1)
		// if 	q = 2  	    Q = {Q, 10} 	QM = {Q, 01}		
		// else if 	q = 1   Q = {Q, 01} 	QM = {Q, 00}	
		// else if 	q = 0   Q = {Q, 00} 	QM = {QM, 11}	
		// else if 	q = -1	Q = {QM, 11} 	QM = {QM, 10}
		// else if 	q = -2	Q = {QM, 10} 	QM = {QM, 01}
    // *** how does the 0 concatination numbers work?

  always_comb begin
    QR  = Quot[`DIVLEN:0];
    QMR = QM[`DIVLEN:0];     // Shift Q and QM
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
  // Final Quoteint is in the range [.5, 2)

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
  input logic XZeroE,
  input logic  [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  output logic [`NE+1:0] DivCalcExp
);

  // correct exponent for denormalized input's normalization shifts
  assign DivCalcExp = (XExpE - XZeroCnt - YExpE + YZeroCnt + (`NE)'(`BIAS))&{`NE+2{~XZeroE}};

endmodule

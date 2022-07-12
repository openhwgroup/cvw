///////////////////////////////////////////
// srt.sv
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

module srtradix4(
  input  logic clk,
  input  logic DivStart, 
  input  logic DivBusy, 
  input logic  [`FMTBITS-1:0] FmtE,
  input  logic [`NE-1:0] XExpE, YExpE,
  input  logic XZeroE, YZeroE, 
  input logic [`DIVLEN-1:0] X,
  input logic [`DIVLEN-1:0] Dpreproc,
  input logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  output logic [`QLEN-1:0] Quot,
  output logic [`DIVLEN+3:0]  WSN, WCN,
  output logic [`DIVLEN+3:0]  FirstWS, FirstWC,
  output logic  [`NE+1:0] DivCalcExpM,
  output logic [`XLEN-1:0] Rem
);


 /* verilator lint_off UNOPTFLAT */
  logic [`DIVLEN+3:0]  WSA[`DIVCOPIES-1:0];
  logic [`DIVLEN+3:0]  WCA[`DIVCOPIES-1:0];
  logic [`DIVLEN+3:0]  WS[`DIVCOPIES-1:0];
  logic [`DIVLEN+3:0]  WC[`DIVCOPIES-1:0];
  logic [`QLEN-1:0] Q[`DIVCOPIES-1:0];
  logic [`QLEN-1:0] QM[`DIVCOPIES-1:0];
  logic [`QLEN-1:0] QNext[`DIVCOPIES-1:0];
  logic [`QLEN-1:0] QMNext[`DIVCOPIES-1:0];
 /* verilator lint_on UNOPTFLAT */
  logic [`DIVLEN+3:0]  D, DBar, D2, DBar2;
  logic [`NE+1:0] DivCalcExp;
  logic [$clog2(`XLEN+1)-1:0] intExp;
  logic           intSign;
  logic [`QLEN-1:0] QMux, QMMux;

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  //  - when the start signal is asserted X and 0 are loaded into WS and WC
  //  - otherwise load WSA into the flipflop
  //  - the assumed one is added to D since it's always normalized (and X/0 is a special case handeled by result selection)
  //  - XZeroE is used as the assumed one to avoid creating a sticky bit - all other numbers are normalized
  mux2   #(`DIVLEN+4) wsmux({WSA[`DIVCOPIES-1][`DIVLEN+1:0], 2'b0}, {3'b000, ~XZeroE, X}, DivStart, WSN);
  flop   #(`DIVLEN+4) wsflop(clk, WSN, WS[0]);
  mux2   #(`DIVLEN+4) wcmux({WCA[`DIVCOPIES-1][`DIVLEN+1:0], 2'b0}, {`DIVLEN+4{1'b0}}, DivStart, WCN);
  flop   #(`DIVLEN+4) wcflop(clk, WCN, WC[0]);
  flopen #(`DIVLEN+4) dflop(clk, DivStart, {4'b0001, Dpreproc}, D);
  flopen #(`NE+2) expflop(clk, DivStart, DivCalcExp, DivCalcExpM);


  // Divisor Selections
  // - choose the negitive version of what's being selected
  assign DBar = ~D;
  assign DBar2 = {~D[`DIVLEN+2:0], 1'b1};
  assign D2 = {D[`DIVLEN+2:0], 1'b0};

  genvar i;
  generate
    for(i=0; i<`DIVCOPIES; i++) begin
      divinteration divinteration(.clk, .DivStart, .DivBusy, .D, .DBar, .D2, .DBar2, 
      .WS(WS[i]), .WC(WC[i]), .WSA(WSA[i]), .WCA(WCA[i]), .Q(Q[i]), .QM(QM[i]), .QNext(QNext[i]), .QMNext(QMNext[i]));
      if(i<3) begin 
        assign WS[i+1] = {WSA[i][`DIVLEN+1:0], 2'b0};
        assign WC[i+1] = {WCA[i][`DIVLEN+1:0], 2'b0};
        assign Q[i+1] = QNext[i];
        assign QM[i+1] = QMNext[i];
      end
    end
  endgenerate

  // if starting a new divison set Q to 0 and QM to -1
  mux2 #(`QLEN) Qmux(QNext[`DIVCOPIES-1], {`QLEN{1'b0}}, DivStart, QMux);
  mux2 #(`QLEN) QMmux(QMNext[`DIVCOPIES-1], {`QLEN{1'b1}}, DivStart, QMMux);
  flopen #(`QLEN) Qreg(clk, DivBusy|DivStart, QMux, Q[0]); // *** have to connect Quot directly to M stage
  flop #(`QLEN) QMreg(clk, QMMux, QM[0]);

  assign Quot = Q[0];
  assign FirstWS = WS[0];
  assign FirstWC = WC[0];

  expcalc expcalc(.FmtE, .XExpE, .YExpE, .XZeroE, .XZeroCnt, .YZeroCnt, .DivCalcExp);

endmodule

////////////////
// Submodules //
////////////////

 /* verilator lint_off UNOPTFLAT */
module divinteration (
  input logic clk,
  input logic DivStart,
  input logic DivBusy,
  input logic [`DIVLEN+3:0] D,
  input logic [`DIVLEN+3:0]  DBar, D2, DBar2,
  input logic [`QLEN-1:0] Q, QM,
  input logic [`DIVLEN+3:0]  WS, WC,
  output logic [`QLEN-1:0] QNext, QMNext, 
  output logic [`DIVLEN+3:0]  WSA, WCA
);
 /* verilator lint_on UNOPTFLAT */

  logic [`DIVLEN+3:0]  Dsel;
  logic [3:0]     q;

  // Quotient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  // q encoding:
	// 1000 = +2
	// 0100 = +1
	// 0000 =  0
	// 0010 = -1
	// 0001 = -2
  qsel4 qsel4(.D, .WS, .WC, .q);

  always_comb
    case (q)
      4'b1000: Dsel = DBar2;
      4'b0100: Dsel = DBar;
      4'b0000: Dsel = {`DIVLEN+4{1'b0}};
      4'b0010: Dsel = D;
      4'b0001: Dsel = D2;
      default: Dsel = {`DIVLEN+4{1'bx}};
    endcase

  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  csa    #(`DIVLEN+4) csa(WS, WC, Dsel, |q[3:2], WSA, WCA);

  otfc4 otfc4(.clk, .DivStart, .DivBusy, .q, .Q, .QM, .QNext, .QMNext);

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

///////////////////////////////////
// On-The-Fly Converter, Radix 2 //
///////////////////////////////////
module otfc4 (
  input  logic         clk,
  input  logic         DivStart,
  input  logic         DivBusy,
  input  logic [3:0]   q,
  input logic [`QLEN-1:0] Q, QM,
  output logic [`QLEN-1:0] QNext, QMNext
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

  //  QR and QMR are the shifted versions of Q and QM.
  //  They are treated as [N-1:r] size signals, and 
  //  discard the r most significant bits of Q and QM. 
  logic [`QLEN-3:0] QR, QMR;

  // shift Q (quotent) and QM (quotent-1)
		// if 	q = 2  	    Q = {Q, 10} 	QM = {Q, 01}		
		// else if 	q = 1   Q = {Q, 01} 	QM = {Q, 00}	
		// else if 	q = 0   Q = {Q, 00} 	QM = {QM, 11}	
		// else if 	q = -1	Q = {QM, 11} 	QM = {QM, 10}
		// else if 	q = -2	Q = {QM, 10} 	QM = {QM, 01}
    // *** how does the 0 concatination numbers work?

  always_comb begin
    QR  = Q[`QLEN-3:0];
    QMR = QM[`QLEN-3:0];     // Shift Q and QM
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

  assign out1 = in1 ^ in2 ^ in3;
  assign out2 = {in1[N-2:0] & (in2[N-2:0] | in3[N-2:0]) | 
		    (in2[N-2:0] & in3[N-2:0]), cin};
endmodule

module expcalc(
  input logic  [`FMTBITS-1:0] FmtE,
  input  logic [`NE-1:0] XExpE, YExpE,
  input logic XZeroE, 
  input logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  output logic  [`NE+1:0] DivCalcExp
  );
    logic [`NE-2:0] Bias;
    
    if (`FPSIZES == 1) begin
        assign Bias = (`NE-1)'(`BIAS); 

    end else if (`FPSIZES == 2) begin
        assign Bias = FmtE ? (`NE-1)'(`BIAS) : (`NE-1)'(`BIAS1); 

    end else if (`FPSIZES == 3) begin
        always_comb
            case (FmtE)
                `FMT: Bias  =  (`NE-1)'(`BIAS);
                `FMT1: Bias = (`NE-1)'(`BIAS1);
                `FMT2: Bias = (`NE-1)'(`BIAS2);
                default: Bias = 'x;
            endcase

    end else if (`FPSIZES == 4) begin        
        always_comb
            case (FmtE)
                2'h3: Bias =  (`NE-1)'(`Q_BIAS);
                2'h1: Bias =  (`NE-1)'(`D_BIAS);
                2'h0: Bias =  (`NE-1)'(`S_BIAS);
                2'h2: Bias =  (`NE-1)'(`H_BIAS);
            endcase
    end
    // correct exponent for denormalized input's normalization shifts
    assign DivCalcExp = ({2'b0, XExpE} - {{`NE+1-$clog2(`NF+2){1'b0}}, XZeroCnt} - {2'b0, YExpE} + {{`NE+1-$clog2(`NF+2){1'b0}}, YZeroCnt} + {3'b0, Bias})&{`NE+2{~XZeroE}};
    endmodule
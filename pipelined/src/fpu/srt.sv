///////////////////////////////////////////
// srt.sv
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

module srt(
  input  logic clk,
  input  logic DivStart, 
  input  logic DivBusy, 
  input  logic [`FMTBITS-1:0] FmtE,
  input  logic [`NE-1:0] Xe, Ye,
  input  logic XZeroE, YZeroE, 
  input logic [`DIVLEN-1:0] X,
  input logic [`DIVLEN-1:0] Dpreproc,
  input logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  input logic NegSticky,
  output logic [`QLEN-1-(`RADIX/4):0] Qm,
  output logic [`DIVLEN+3:0]  NextWSN, NextWCN,
  output logic [`DIVLEN+3:0]  StickyWSA,
  output logic [`DIVLEN+3:0]  FirstWS, FirstWC,
  output logic  [`NE+1:0] QeM,
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
  logic [`DIVLEN+3:0]  WSN, WCN;
  logic [`DIVLEN+3:0]  D, DBar, D2, DBar2;
  logic [`NE+1:0] Qe;
  logic [$clog2(`XLEN+1)-1:0] intExp;
  logic           intSign;
  logic [`QLEN-1:0] QMMux;

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  //  - when the start signal is asserted X and 0 are loaded into WS and WC
  //  - otherwise load WSA into the flipflop
  //  - the assumed one is added to D since it's always normalized (and X/0 is a special case handeled by result selection)
  //  - XZeroE is used as the assumed one to avoid creating a sticky bit - all other numbers are normalized
  if (`RADIX == 2) begin : nextw
    assign NextWSN = {WSA[`DIVCOPIES-1][`DIVLEN+2:0], 1'b0};
    assign NextWCN = {WCA[`DIVCOPIES-1][`DIVLEN+2:0], 1'b0};
  end else begin
    assign NextWSN = {WSA[`DIVCOPIES-1][`DIVLEN+1:0], 2'b0};
    assign NextWCN = {WCA[`DIVCOPIES-1][`DIVLEN+1:0], 2'b0};
  end

  mux2   #(`DIVLEN+4) wsmux(NextWSN, {3'b000, ~XZeroE, X}, DivStart, WSN);
  flopen   #(`DIVLEN+4) wsflop(clk, DivStart|DivBusy, WSN, WS[0]);
  mux2   #(`DIVLEN+4) wcmux(NextWCN, {`DIVLEN+4{1'b0}}, DivStart, WCN);
  flopen   #(`DIVLEN+4) wcflop(clk, DivStart|DivBusy, WCN, WC[0]);
  flopen #(`DIVLEN+4) dflop(clk, DivStart, {4'b0001, Dpreproc}, D);
  flopen #(`NE+2) expflop(clk, DivStart, Qe, QeM);


  // Divisor Selections
  // - choose the negitive version of what's being selected
  assign DBar = ~D;
  if(`RADIX == 4) begin : d2
    assign DBar2 = {~D[`DIVLEN+2:0], 1'b1};
    assign D2 = {D[`DIVLEN+2:0], 1'b0};
  end

  genvar i;
  generate
    for(i=0; $unsigned(i)<`DIVCOPIES; i++) begin : interations
      divinteration divinteration(.D, .DBar, .D2, .DBar2, 
      .WS(WS[i]), .WC(WC[i]), .WSA(WSA[i]), .WCA(WCA[i]), .Q(Q[i]), .QM(QM[i]), .QNext(QNext[i]), .QMNext(QMNext[i]));
      if(i<(`DIVCOPIES-1)) begin 
        if (`RADIX==2)begin 
          assign WS[i+1] = {WSA[i][`DIVLEN+1:0], 1'b0};
          assign WC[i+1] = {WCA[i][`DIVLEN+1:0], 1'b0};
        end else begin
          assign WS[i+1] = {WSA[i][`DIVLEN+1:0], 2'b0};
          assign WC[i+1] = {WCA[i][`DIVLEN+1:0], 2'b0};
        end
        assign Q[i+1] = QNext[i];
        assign QM[i+1] = QMNext[i];
      end
    end
  endgenerate

  // if starting a new divison set Q to 0 and QM to -1
  mux2 #(`QLEN) QMmux(QMNext[`DIVCOPIES-1], {`QLEN{1'b1}}, DivStart, QMMux);
  flopenr #(`QLEN) Qreg(clk, DivStart, DivBusy, QNext[`DIVCOPIES-1], Q[0]);
  flopen #(`QLEN) QMreg(clk, DivBusy, QMMux, QM[0]);

  assign Qm = NegSticky ? QM[0][`QLEN-1-(`RADIX/4):0] : Q[0][`QLEN-1-(`RADIX/4):0];
  assign FirstWS = WS[0];
  assign FirstWC = WC[0];
  if(`RADIX==2)
    if (`DIVCOPIES == 1)
      assign StickyWSA = {WSA[0][`DIVLEN+2:0], 1'b0};
    else
      assign StickyWSA = {WSA[1][`DIVLEN+2:0], 1'b0};

  expcalc expcalc(.FmtE, .Xe, .Ye, .XZeroE, .XZeroCnt, .YZeroCnt, .Qe);

endmodule

////////////////
// Submodules //
////////////////

 /* verilator lint_off UNOPTFLAT */
module divinteration (
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
  logic qp, qz;//, qn;

  // Qmient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  // q encoding:
	// 1000 = +2
	// 0100 = +1
	// 0000 =  0
	// 0010 = -1
	// 0001 = -2
  if(`RADIX == 2) begin : qsel
    qsel2 qsel2(WS[`DIVLEN+3:`DIVLEN], WC[`DIVLEN+3:`DIVLEN], qp, qz);//, qn);
  end else begin
    qsel4 qsel4(.D, .WS, .WC, .q);
  end

  if(`RADIX == 2) begin : dsel
    assign Dsel = {`DIVLEN+4{~qz}}&(qp ? DBar : D);
  end else begin
    always_comb
      case (q)
        4'b1000: Dsel = DBar2;
        4'b0100: Dsel = DBar;
        4'b0000: Dsel = '0;
        4'b0010: Dsel = D;
        4'b0001: Dsel = D2;
        default: Dsel = 'x;
      endcase
  end
  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  if (`RADIX == 2) begin : csa
    csa #(`DIVLEN+4) csa(WS, WC, Dsel, qp, WSA, WCA);
  end else begin
    csa #(`DIVLEN+4) csa(WS, WC, Dsel, |q[3:2], WSA, WCA);
  end

  if (`RADIX == 2) begin : otfc
    otfc2 otfc2(.qp, .qz, .Q, .QM, .QNext, .QMNext);
  end else begin
    otfc4 otfc4(.q, .Q, .QM, .QNext, .QMNext);
  end

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
  input  logic [`NE-1:0] Xe, Ye,
  input logic XZeroE, 
  input logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt,
  output logic  [`NE+1:0] Qe
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
    assign Qe = ({2'b0, Xe} - {{`NE+1-$unsigned($clog2(`NF+2)){1'b0}}, XZeroCnt} - {2'b0, Ye} + {{`NE+1-$unsigned($clog2(`NF+2)){1'b0}}, YZeroCnt} + {3'b0, Bias})&{`NE+2{~XZeroE}};
    endmodule
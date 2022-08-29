///////////////////////////////////////////
// fdivsqrtiter.sv
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

module fdivsqrtiter(
  input  logic clk,
  input  logic DivStart, 
  input  logic DivBusy, 
  input  logic [`NE-1:0] Xe, Ye,
  input  logic XZeroE, YZeroE, 
  input  logic SqrtE,
  input  logic SqrtM,
  input  logic [`DIVb:0] X,
  input  logic [`DIVN-2:0] Dpreproc,
  input  logic NegSticky,
  output logic [`DIVb-(`RADIX/4):0] Qm,
  output logic [`DIVN-2:0]  D, // U0.N-1
  output logic [`DIVb+3:0]  NextWSN, NextWCN,
  output logic [`DIVb+3:0]  StickyWSA,
  output logic [`DIVb:0] LastSM,
  output logic [`DIVb-1:0] LastC,
  output logic [`DIVb:0] FirstSM,
  output logic [`DIVb-1:0] FirstC,
  output logic [`DIVCOPIES-1:0] qn,
  output logic [`DIVb+3:0]  FirstWS, FirstWC
);

//QLEN = 1.(number of bits created for division)
// N is NF+1 or XLEN
// WC/WS is dependent on D so 4.N-1 ie N+3 bits or N+2:0 + one more bit in fraction for possible sqrt right shift
// D is 1.N-1, but the msb is always 1 so 0.N-1 or N-1 bits or N-1:0
// Dsel should match WC/WS so 4.N-1 ie N+3 bits or N+2:0
// Q/QM/S/SM should be 1.b so b+1 bits or b:0
// C needs to be the lenght of the final fraction 0.b so b or b-1:0
 /* verilator lint_off UNOPTFLAT */
  logic [`DIVb+3:0]  WSA[`DIVCOPIES-1:0]; // Q4.b
  logic [`DIVb+3:0]  WCA[`DIVCOPIES-1:0]; // Q4.b
  logic [`DIVb+3:0]  WS[`DIVCOPIES-1:0]; // Q4.b
  logic [`DIVb+3:0]  WC[`DIVCOPIES-1:0]; // Q4.b
  logic [`DIVb:0] Q[`DIVCOPIES-1:0]; // U1.b
  logic [`DIVb:0] QM[`DIVCOPIES-1:0];// 1.b
  logic [`DIVb:0] QNext[`DIVCOPIES-1:0];// U1.b
  logic [`DIVb:0] QMNext[`DIVCOPIES-1:0];// U1.b
  logic [`DIVb:0] S[`DIVCOPIES-1:0];// U1.b
  logic [`DIVb:0] SM[`DIVCOPIES-1:0];// U1.b
  logic [`DIVb:0] SNext[`DIVCOPIES-1:0];// U1.b
  logic [`DIVb:0] SMNext[`DIVCOPIES-1:0];// U1.b
  logic [`DIVb-1:0] C[`DIVCOPIES-1:0]; // 0.b
 /* verilator lint_on UNOPTFLAT */
  logic [`DIVb+3:0]  WSN, WCN; // Q4.N-1
  logic [`DIVb+3:0]  DBar, D2, DBar2; // Q4.N-1
  logic [`DIVb:0] QMMux;
  logic [`DIVb-1:0] NextC;
  logic [`DIVb-1:0] CMux;
  logic [`DIVb:0] SMux;

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the partial remainder
  // is fed back for the next iteration.
  //  - when the start signal is asserted X and 0 are loaded into WS and WC
  //  - otherwise load WSA into the flipflop
  //  - the assumed one is added to D since it's always normalized (and X/0 is a special case handeled by result selection)
  //  - XZeroE is used as the assumed one to avoid creating a sticky bit - all other numbers are normalized
  if (`RADIX == 2) begin : nextw
    assign NextWSN = {WSA[`DIVCOPIES-1][`DIVb+2:0], 1'b0};
    assign NextWCN = {WCA[`DIVCOPIES-1][`DIVb+2:0], 1'b0};
    assign NextC   = {1'b1, C[`DIVCOPIES-1][`DIVb-1:1]};
  end else begin
    assign NextWSN = {WSA[`DIVCOPIES-1][`DIVb+1:0], 2'b0};
    assign NextWCN = {WCA[`DIVCOPIES-1][`DIVb+1:0], 2'b0};
    assign NextC   = {2'b11, C[`DIVCOPIES-1][`DIVb-1:2]};
  end


  // mux2   #(`DIVb+4) wsmux(NextWSN, {3'b0, X}, DivStart, WSN);
  mux2   #(`DIVb+4) wsmux(NextWSN, {{3{SqrtE&~XZeroE}}, X}, DivStart, WSN);
  flopen   #(`DIVb+4) wsflop(clk, DivStart|DivBusy, WSN, WS[0]);
  mux2   #(`DIVb+4) wcmux(NextWCN, '0, DivStart, WCN);
  flopen   #(`DIVb+4) wcflop(clk, DivStart|DivBusy, WCN, WC[0]);
  flopen #(`DIVN-1) dflop(clk, DivStart, Dpreproc, D);
  mux2 #(`DIVb) Cmux(NextC, {1'b1, {(`DIVb-1){1'b0}}}, DivStart, CMux);
  flopen #(`DIVb) cflop(clk, DivStart|DivBusy, CMux, C[0]);

  // Divisor Selections
  //  - choose the negitive version of what's being selected
  //  - D is only the fraction
  assign DBar = {3'b111, 1'b0, ~D, {`DIVb-`DIVN+1{1'b1}}};
  if(`RADIX == 4) begin : d2
    assign DBar2 = {2'b11, 1'b0, ~D, {`DIVb+2-`DIVN{1'b1}}};
    assign D2 = {2'b0, 1'b1, D, {`DIVb+2-`DIVN{1'b0}}};
  end

  genvar i;
  generate
    for(i=0; $unsigned(i)<`DIVCOPIES; i++) begin : interations
      divinteration divinteration(.D, .DBar, .D2, .DBar2, .SqrtM,
      .WS(WS[i]), .WC(WC[i]), .WSA(WSA[i]), .WCA(WCA[i]), .Q(Q[i]), .QM(QM[i]), .QNext(QNext[i]), .QMNext(QMNext[i]),
      .C(C[i]), .S(S[i]), .SM(SM[i]), .SNext(SNext[i]), .SMNext(SMNext[i]), .qn(qn[i]));
      if(i<(`DIVCOPIES-1)) begin 
        if (`RADIX==2)begin 
          assign WS[i+1] = {WSA[i][`DIVb+2:0], 1'b0};
          assign WC[i+1] = {WCA[i][`DIVb+2:0], 1'b0};
          assign  C[i+1] = {1'b1, C[i][`DIVb-1:1]};
        end else begin
          assign WS[i+1] = {WSA[i][`DIVb+1:0], 2'b0};
          assign WC[i+1] = {WCA[i][`DIVb+1:0], 2'b0};
          assign  C[i+1] = {2'b11, C[i][`DIVb-1:2]};
        end
        assign Q[i+1] = QNext[i];
        assign QM[i+1] = QMNext[i];
        assign S[i+1] = SNext[i];
        assign SM[i+1] = SMNext[i];
      end
    end
  endgenerate


  // if starting a new divison set Q to 0 and QM to -1
  mux2 #(`DIVb+1) QMmux(QMNext[`DIVCOPIES-1], '1, DivStart, QMMux);
  flopenr #(`DIVb+1) Qreg(clk, DivStart, DivBusy, QNext[`DIVCOPIES-1], Q[0]);
  flopen #(`DIVb+1) QMreg(clk, DivStart|DivBusy, QMMux, QM[0]);

  flopenr #(`DIVb+1) SMreg(clk, DivStart, DivBusy, SMNext[`DIVCOPIES-1], SM[0]);
  mux2 #(`DIVb+1) Smux(SNext[`DIVCOPIES-1], {1'b1, {(`DIVb){1'b0}}}, DivStart, SMux);
  flopen #(`DIVb+1) Sreg(clk, DivStart|DivBusy, SMux, S[0]);
 // division takes the result from the next cycle, which is shifted to the left one more time so the square root also needs to be shifted
  always_comb
    if(SqrtM) // sqrt ouputs in the range (1, .5]
      if(NegSticky) Qm = {SM[0][`DIVb-1-(`RADIX/4):0], 1'b0};
      else          Qm = {S[0][`DIVb-1-(`RADIX/4):0], 1'b0};
    else  
      if(NegSticky) Qm = QM[0][`DIVb-(`RADIX/4):0];
      else          Qm = Q[0][`DIVb-(`RADIX/4):0];

  assign FirstWS = WS[0];
  assign FirstWC = WC[0];

  assign LastSM = SM[`DIVCOPIES-1];
  assign LastC = C[`DIVCOPIES-1];
  assign FirstSM = SM[0];
  assign FirstC = C[0];

  if(`RADIX==2)
    if (`DIVCOPIES == 1)
      assign StickyWSA = {WSA[0][`DIVb+2:0], 1'b0};
    else
      assign StickyWSA = {WSA[1][`DIVb+2:0], 1'b0};


endmodule

////////////////
// Submodules //
////////////////

 /* verilator lint_off UNOPTFLAT */
module divinteration (
  input logic [`DIVN-2:0] D,
  input logic [`DIVb+3:0]  DBar, D2, DBar2,
  input logic [`DIVb:0] Q, QM,
  input logic [`DIVb:0] S, SM,
  input logic [`DIVb+3:0]  WS, WC,
  input logic [`DIVb-1:0] C,
  input logic SqrtM,
  output logic [`DIVb:0] QNext, QMNext, 
  output logic qn,
  output logic [`DIVb:0] SNext, SMNext, 
  output logic [`DIVb+3:0]  WSA, WCA
);
 /* verilator lint_on UNOPTFLAT */

  logic [`DIVb+3:0]  Dsel;
  logic [3:0]     q;
  logic qp, qz;
  logic [`DIVb+3:0] F;
  logic [`DIVb+3:0] AddIn;

  // Qmient Selection logic
  // Given partial remainder, select quotient of +1, 0, or -1 (qp, qz, pm)
  // q encoding:
	// 1000 = +2
	// 0100 = +1
	// 0000 =  0
	// 0010 = -1
	// 0001 = -2
  if(`RADIX == 2) begin : qsel
    qsel2 qsel2(WS[`DIVb+3:`DIVb], WC[`DIVb+3:`DIVb], qp, qz, qn);
    fgen2 fgen2(.sp(qp), .sz(qz), .C, .S, .SM, .F);
  end else begin
    qsel4 qsel4(.D, .WS, .WC, .Sqrt(SqrtM), .q);
    // fgen4 fgen4(.s(q), .C, .S, .SM, .F);
  end

  if(`RADIX == 2) begin : dsel
    assign Dsel = {`DIVb+4{~qz}}&(qp ? DBar : {3'b0, 1'b1, D, {`DIVb-`DIVN+1{1'b0}}});
  end else begin
    always_comb
      case (q)
        4'b1000: Dsel = DBar2;
        4'b0100: Dsel = DBar;
        4'b0000: Dsel = '0;
        4'b0010: Dsel = {3'b0, 1'b1, D, {`DIVb-`DIVN+1{1'b0}}};
        4'b0001: Dsel = D2;
        default: Dsel = 'x;
      endcase
  end
  // Partial Product Generation
  //  WSA, WCA = WS + WC - qD
  assign AddIn = SqrtM ? F : Dsel;
  if (`RADIX == 2) begin : csa
    csa #(`DIVb+4) csa(WS, WC, AddIn, qp&~SqrtM, WSA, WCA);
  end else begin
    csa #(`DIVb+4) csa(WS, WC, AddIn, |q[3:2]&~SqrtM, WSA, WCA);
  end

  if (`RADIX == 2) begin : otfc
    otfc2 otfc2(.qp, .qz, .Q, .QM, .QNext, .QMNext);
    sotfc2 sotfc2(.sp(qp), .sz(qz), .C, .S, .SM, .SNext, .SMNext);
  end else begin
    otfc4 otfc4(.q, .Q, .QM, .QNext, .QMNext);
    // sotfc4 sotfc4(.s(q), .SqrtM, .C, .S, .SM, .SNext, .SMNext);
  end

endmodule





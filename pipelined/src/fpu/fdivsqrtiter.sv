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
  input  logic [`DIVb+3:0] X,
  input  logic [`DIVN-2:0] Dpreproc,
  output logic [`DIVN-2:0]  D, // U0.N-1
  output logic [`DIVb+3:0]  NextWSN, NextWCN,
  output logic [`DIVb:0] FirstS, FirstSM,
  output logic [`DIVb:0] FirstQ, FirstQM,
  output logic [`DIVb-1:0] FirstC,
  output logic             Firstqn,
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
  logic [`DIVb-1:0] C[`DIVCOPIES:0]; // 0.b
  logic [`DIVb-1:0] initC; // 0.b
  logic [`DIVCOPIES-1:0] qn; 


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
  end else begin : nextw
    assign NextWSN = {WSA[`DIVCOPIES-1][`DIVb+1:0], 2'b0};
    assign NextWCN = {WCA[`DIVCOPIES-1][`DIVb+1:0], 2'b0};
  end
  assign initC = 0;

  mux2   #(`DIVb+4) wsmux(NextWSN, X, DivStart, WSN);
  flopen   #(`DIVb+4) wsflop(clk, DivStart|DivBusy, WSN, WS[0]);
  mux2   #(`DIVb+4) wcmux(NextWCN, '0, DivStart, WCN);
  flopen   #(`DIVb+4) wcflop(clk, DivStart|DivBusy, WCN, WC[0]);
  flopen #(`DIVN-1) dflop(clk, DivStart, Dpreproc, D);
  mux2 #(`DIVb) Cmux(C[`DIVCOPIES], initC, DivStart, CMux); 
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
      if (`RADIX == 2) begin: stage
        fdivsqrtstage2 fdivsqrtstage(.D, .DBar, .D2, .DBar2, .SqrtM,
        .WS(WS[i]), .WC(WC[i]), .WSA(WSA[i]), .WCA(WCA[i]), .Q(Q[i]), .QM(QM[i]), .QNext(QNext[i]), .QMNext(QMNext[i]),
        .C(C[i]), .S(S[i]), .SM(SM[i]), .CNext(C[i+1]), .SNext(SNext[i]), .SMNext(SMNext[i]), .qn(qn[i]));
      end else begin: stage
        logic j1;
        assign j1 = (i == 0 &  C[0][`DIVb-2] & ~C[0][`DIVb-3]);
        fdivsqrtstage4 fdivsqrtstage(.D, .DBar, .D2, .DBar2, .SqrtM, .j1,
        .WS(WS[i]), .WC(WC[i]), .WSA(WSA[i]), .WCA(WCA[i]), .Q(Q[i]), .QM(QM[i]), .QNext(QNext[i]), .QMNext(QMNext[i]),
        .C(C[i]), .S(S[i]), .SM(SM[i]), .CNext(C[i+1]), .SNext(SNext[i]), .SMNext(SMNext[i]), .qn(qn[i]));
      end
      if(i<(`DIVCOPIES-1)) begin 
        if (`RADIX==2)begin 
          assign WS[i+1] = {WSA[i][`DIVb+2:0], 1'b0};
          assign WC[i+1] = {WCA[i][`DIVb+2:0], 1'b0};
//          assign  C[i+1] = {1'b1, C[i][`DIVb-1:1]};
        end else begin
          assign WS[i+1] = {WSA[i][`DIVb+1:0], 2'b0};
          assign WC[i+1] = {WCA[i][`DIVb+1:0], 2'b0};
//          assign  C[i+1] = {2'b11, C[i][`DIVb-1:2]};
        end
        assign Q[i+1] = QNext[i];
        assign QM[i+1] = QMNext[i];
        assign S[i+1] = SNext[i];
        assign SM[i+1] = SMNext[i];
      end
    end
  endgenerate


  // if starting a new divison set Q to 0 and QM to -1
  flopenr #(`DIVb+1) Qreg(clk, DivStart, DivBusy, QNext[`DIVCOPIES-1], Q[0]);
  mux2 #(`DIVb+1) QMmux(QMNext[`DIVCOPIES-1], '1, DivStart, QMMux);
  flopen #(`DIVb+1) QMreg(clk, DivStart|DivBusy, QMMux, QM[0]);

  // if starting new square root, set S to 1 and SM to 0
  flopenr #(`DIVb+1) SMreg(clk, DivStart, DivBusy, SMNext[`DIVCOPIES-1], SM[0]);
  mux2 #(`DIVb+1) Smux(SNext[`DIVCOPIES-1], {1'b1, {(`DIVb){1'b0}}}, DivStart, SMux);
  flopen #(`DIVb+1) Sreg(clk, DivStart|DivBusy, SMux, S[0]);

  assign FirstWS = WS[0];
  assign FirstWC = WC[0];

  assign FirstS = S[0];
  assign FirstSM = SM[0];
  assign FirstQ = Q[0];
  assign FirstQM = QM[0];
  assign FirstC = C[0];
  assign Firstqn = qn[0];
endmodule


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
  input  logic IFDivStartE, 
  input  logic FDivBusyE, 
  input  logic [`NE-1:0] Xe, Ye,
  input  logic XZeroE, YZeroE, 
  input  logic SqrtE,
//  input  logic SqrtM,
  input  logic OTFCSwap,
  input  logic [`DIVb+3:0] X,
  input  logic [`DIVb-1:0] DPreproc,
  output logic [`DIVb-1:0] D,
  output logic [`DIVb:0]   FirstU, FirstUM,
  output logic [`DIVb+1:0] FirstC,
  output logic             Firstun,
  output logic [`DIVb+3:0] FirstWS, FirstWC
);

  /* verilator lint_off UNOPTFLAT */
  logic [`DIVb+3:0]      WSNext[`DIVCOPIES-1:0]; // Q4.b
  logic [`DIVb+3:0]      WCNext[`DIVCOPIES-1:0]; // Q4.b
  logic [`DIVb+3:0]      WS[`DIVCOPIES:0];       // Q4.b
  logic [`DIVb+3:0]      WC[`DIVCOPIES:0];       // Q4.b
  logic [`DIVb:0]        U[`DIVCOPIES:0];        // U1.b
  logic [`DIVb:0]        UM[`DIVCOPIES:0];       // U1.b
  logic [`DIVb:0]        UNext[`DIVCOPIES-1:0];  // U1.b
  logic [`DIVb:0]        UMNext[`DIVCOPIES-1:0]; // U1.b
  logic [`DIVb+1:0]      C[`DIVCOPIES:0];        // Q2.b
  logic [`DIVb+1:0]      initC;                  // Q2.b
  logic [`DIVCOPIES-1:0] un; 

  logic [`DIVb+3:0]      WSN, WCN;               // Q4.b
  logic [`DIVb+3:0]      DBar, D2, DBar2;        // Q4.b
  logic [`DIVb+1:0]      NextC;
  logic [`DIVb+1:0]      CMux;
  logic [`DIVb:0]        UMux, UMMux;
  logic [`DIVb:0]        initU, initUM;
  /* verilator lint_on UNOPTFLAT */

  // Top Muxes and Registers
  // When start is asserted, the inputs are loaded into the divider.
  // Otherwise, the divisor is retained and the residual and result
  // are fed back for the next iteration.
 
  // Residual WS/SC registers/initializaiton mux
  mux2   #(`DIVb+4) wsmux(WS[`DIVCOPIES], X, IFDivStartE, WSN);
  mux2   #(`DIVb+4) wcmux(WC[`DIVCOPIES], '0, IFDivStartE, WCN);
  flopen #(`DIVb+4) wsreg(clk, FDivBusyE, WSN, WS[0]);
  flopen #(`DIVb+4) wcreg(clk, FDivBusyE, WCN, WC[0]);

  // UOTFC Result U and UM registers/initialization mux
  // Initialize U to 1.0 and UM to 0 for square root; U to 0 and UM to -1 for division
  assign initU = SqrtE ? {1'b1, {(`DIVb){1'b0}}} : 0;
  assign initUM = SqrtE ? 0 : {1'b1, {(`DIVb){1'b0}}}; 
  mux2   #(`DIVb+1) Umux(UNext[`DIVCOPIES-1], initU, IFDivStartE, UMux);
  mux2   #(`DIVb+1) UMmux(UMNext[`DIVCOPIES-1], initUM, IFDivStartE, UMMux);
  flopen #(`DIVb+1) UReg(clk, IFDivStartE|FDivBusyE, UMux, U[0]);
  flopen #(`DIVb+1) UMReg(clk, IFDivStartE|FDivBusyE, UMMux, UM[0]);

  // C register/initialization mux
  // Initialize C to -1 for sqrt and -R for division
  logic [1:0] initCUpper;
  assign initCUpper = SqrtE ? 2'b11 : (`RADIX == 4) ? 2'b00 : 2'b10;
  assign initC = {initCUpper, {`DIVb{1'b0}}};
  mux2 #(`DIVb+2) Cmux(C[`DIVCOPIES], initC, IFDivStartE, CMux); 
  flopen #(`DIVb+2) creg(clk, IFDivStartE|FDivBusyE, CMux, C[0]);

   // Divisior register
  flopen #(`DIVb) dreg(clk, IFDivStartE, DPreproc, D);

  // Divisor Selections
  //  - choose the negitive version of what's being selected
  //  - D is a 0.b mantissa
  assign DBar    = {3'b111, 1'b0, ~D};
  if(`RADIX == 4) begin : d2
    assign DBar2 = {2'b11, 1'b0, ~D, 1'b1};
    assign D2    = {2'b0, 1'b1, D, 1'b0};
  end

  // k=DIVCOPIES of the recurrence logic
  genvar i;
  generate
    for(i=0; $unsigned(i)<`DIVCOPIES; i++) begin : iterations
      if (`RADIX == 2) begin: stage
        fdivsqrtstage2 fdivsqrtstage(.D, .DBar, .SqrtE, .OTFCSwap,
        .WS(WS[i]), .WC(WC[i]), .WSNext(WSNext[i]), .WCNext(WCNext[i]),
        .C(C[i]), .U(U[i]), .UM(UM[i]), .CNext(C[i+1]), .UNext(UNext[i]), .UMNext(UMNext[i]), .un(un[i]));
      end else begin: stage
        logic j1;
        assign j1 = (i == 0 & ~C[0][`DIVb-1]);
        fdivsqrtstage4 fdivsqrtstage(.D, .DBar, .D2, .DBar2, .SqrtE, .j1, .OTFCSwap,
        .WS(WS[i]), .WC(WC[i]), .WSNext(WSNext[i]), .WCNext(WCNext[i]), 
        .C(C[i]), .U(U[i]), .UM(UM[i]), .CNext(C[i+1]), .UNext(UNext[i]), .UMNext(UMNext[i]), .un(un[i]));
      end
      assign WS[i+1] = WSNext[i];
      assign WC[i+1] = WCNext[i];
      assign U[i+1]  = UNext[i];
      assign UM[i+1] = UMNext[i];
    end
  endgenerate

  // Send values from start of cycle for postprocessing
  assign FirstWS = WS[0];
  assign FirstWC = WC[0];
  assign FirstU  = U[0];
  assign FirstUM = UM[0];
  assign FirstC  = C[0];
  assign Firstun = un[0];
endmodule


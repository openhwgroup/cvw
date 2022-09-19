///////////////////////////////////////////
// fdivsqrtpostproc.sv
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

module fdivsqrtpostproc(
  input logic [`DIVb+3:0] WS, WC,
  input logic [`DIVN-2:0]  D, // U0.N-1
  input logic [`DIVb:0] FirstU, FirstUM, 
  input logic [`DIVb+1:0] FirstC,
  input logic  Firstqn,
  input logic SqrtM,
  output logic [`DIVb-(`RADIX/4):0] QmM,
  output logic WZero,
  output logic DivSM
);
  
  logic [`DIVb+3:0] W;
  logic NegSticky;

  // check for early termination on an exact result.  If the result is not exact, the sticky should be set
  logic weq0;
  aplusbeq0 #(`DIVb+4) wspluswceq0(WS, WC, weq0);

  if (`RADIX == 2) begin
    logic [`DIVb+3:0] FZero;
    logic [`DIVb+2:0] FirstK;
    logic wfeq0;
    logic [`DIVb+3:0] WCF, WSF;

    assign FirstK = ({1'b1, FirstC} & ~({1'b1, FirstC} << 1));
    assign FZero = SqrtM ? {FirstUM[`DIVb], FirstUM, 2'b0} | {FirstK,1'b0} : {3'b1,D,{`DIVb-`DIVN+2{1'b0}}};
    csa #(`DIVb+4) fadd(WS, WC, FZero, 1'b0, WSF, WCF); // compute {WCF, WSF} = {WS + WC + FZero};
    aplusbeq0 #(`DIVb+4) wcfpluswsfeq0(WCF, WSF, wfeq0);
    assign WZero = weq0|(wfeq0 & Firstqn);
  end else begin
    assign WZero = weq0;
  end 
  assign DivSM = ~WZero;

  // Determine if sticky bit is negative
  assign W = WC+WS;
  assign NegSticky = W[`DIVb+3];

   // division takes the result from the next cycle, which is shifted to the left one more time so the square root also needs to be shifted
  always_comb
    if(SqrtM) // sqrt ouputs in the range (1, .5]
      if(NegSticky) QmM = {FirstUM[`DIVb-1-(`RADIX/4):0], 1'b0};
      else          QmM = {FirstU[`DIVb-1-(`RADIX/4):0], 1'b0};
    else  
      if(NegSticky) QmM = FirstUM[`DIVb-(`RADIX/4):0];
      else          QmM = FirstU[`DIVb-(`RADIX/4):0];

endmodule
///////////////////////////////////////////
// fdivsqrtfsm.sv
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

module fdivsqrtfsm(
  input  logic clk, 
  input  logic reset, 
  input logic [`DIVb+3:0] NextWSN, NextWCN, WS, WC,
  input  logic XInfE, YInfE, 
  input  logic XZeroE, YZeroE, 
  input  logic XNaNE, YNaNE, 
  input  logic DivStart, 
  input  logic XsE,
  input  logic SqrtE,
  input  logic SqrtM,
  input  logic StallE,
  input  logic StallM,
  input logic [`DIVN-2:0]  D, // U0.N-1
  input  logic [`DIVb+3:0] StickyWSA,
  input  logic [`DURLEN-1:0] Dur,
  input logic [`DIVb:0] LastSM,
  input logic [`DIVb:0] FirstSM,
  input logic [`DIVb-1:0] LastC,
  input logic [`DIVb-1:0] FirstC,
  input logic [`DIVCOPIES-1:0] qn,
  output logic [`DURLEN-1:0] EarlyTermShiftE,
  output logic DivSE,
  output logic DivDone,
  output logic NegSticky,
  output logic DivBusy
);
  
  typedef enum logic [1:0] {IDLE, BUSY, DONE} statetype;
  statetype state;

  logic [`DURLEN-1:0] step;
  logic WZero;
  //logic [$clog2(`DIVLEN/2+3)-1:0] Dur;
  logic [`DIVb+3:0] W;
  logic SpecialCase;
  logic WZeroDelayed, WZeroD; // *** later remove

  //flopen #($clog2(`DIVLEN/2+3)) durflop(clk, DivStart, CalcDur, Dur);
  assign DivBusy = (state == BUSY);
  // calculate sticky bit
  //    - there is a chance that a value is subtracted infinitly, resulting in an exact QM result
  //      this is only a problem on radix 2 (and possibly maximally redundant 4) since minimally redundant
  //      radix-4 division can't create a QM that continually adds 0's
  if (`RADIX == 2) begin
    logic [`DIVb+3:0] FZero, FSticky;
    logic [`DIVb+2:0] LastK, FirstK;
    assign LastK = ({3'b111, LastC} & ~({3'b111, LastC} << 1));
    assign FirstK = ({3'b111, FirstC<<1} & ~({3'b111, FirstC<<1} << 1));
    assign FZero = SqrtM ? {LastSM[`DIVb], LastSM, 2'b0} | {LastK,1'b0} : {3'b1,D,{`DIVb-`DIVN+2{1'b0}}};
    assign FSticky = SqrtM ? {FirstSM[`DIVb], FirstSM, 2'b0} | {FirstK,1'b0} : {3'b1,D,{`DIVb-`DIVN+2{1'b0}}};
    // *** |... for continual -1 is not efficent fix - also only needed for radix-2
    assign WZero = ((NextWSN^NextWCN)=={NextWSN[`DIVb+2:0]|NextWCN[`DIVb+2:0], 1'b0})|(((NextWSN+NextWCN+FZero)==0)&qn[`DIVCOPIES-1]);
    assign DivSE = |W&~((W+FSticky)==0); //***not efficent fix == and need the & qn *** use next cycle
  end else begin
    assign WZero = ((NextWSN^NextWCN)=={NextWSN[`DIVb+2:0]|NextWCN[`DIVb+2:0], 1'b0});
    assign DivSE = |W;
  end
  
  if (`RADIX == 2) begin
    logic [`DIVb+3:0] FZeroD, FSticky;
    logic [`DIVb+2:0] LastK, FirstK;
    assign LastK = ({3'b111, LastC} & ~({3'b111, LastC} << 1));
    assign FirstK = ({3'b111, FirstC<<1} & ~({3'b111, FirstC<<1} << 1));
    assign FZeroD = SqrtM ? {FirstSM[`DIVb], FirstSM, 2'b0} | {FirstK,1'b0} : {3'b1,D,{`DIVb-`DIVN+2{1'b0}}};
    assign FSticky = SqrtM ? {FirstSM[`DIVb], FirstSM, 2'b0} | {FirstK,1'b0} : {3'b1,D,{`DIVb-`DIVN+2{1'b0}}};
    // *** |... for continual -1 is not efficent fix - also only needed for radix-2
    assign WZeroD = ((WS^WC)=={WS[`DIVb+2:0]|WC[`DIVb+2:0], 1'b0})|(((WS+WC+FZeroD)==0)&qn[`DIVCOPIES-1]);
  end else begin
    assign WZeroD = ((WS^WC)=={WS[`DIVb+2:0]|WC[`DIVb+2:0], 1'b0});
  end

  flopr #(1) WZeroReg(clk, reset | DivStart, WZero, WZeroDelayed);
//  assign DivDone = (state == DONE) | (WZeroD & (state == BUSY));
  assign DivDone = (state == DONE) | (WZeroDelayed & (state == BUSY));
  assign W = WC+WS;
  assign NegSticky = W[`DIVb+3];
  assign EarlyTermShiftE = step;

  // terminate immediately on special cases
  assign SpecialCase = XZeroE | (YZeroE&~SqrtE) | XInfE | YInfE | XNaNE | YNaNE | (XsE&SqrtE);

  always_ff @(posedge clk) begin
      if (reset) begin
          state <= #1 IDLE; 
      end else if (DivStart&~StallE) begin 
          step <= Dur;
          if (SpecialCase) state <= #1 DONE;
          else             state <= #1 BUSY;
      end else if (DivDone) begin
        if (StallM) state <= #1 DONE;
        else        state <= #1 IDLE;
      end else if (state == BUSY) begin
          if (step == 1) begin
              state <= #1 DONE;
          end
          step <= step - 1;
      end 
  end
endmodule
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
  input  logic [`DURLEN-1:0] Dur,
  input logic [`DIVCOPIES-1:0] qn,
  input logic WZero,
  output logic [`DURLEN-1:0] EarlyTermShiftE,
//  output logic DivSE,
  output logic DivDone,
//  output logic NegSticky,
  output logic DivBusy
);
  
  typedef enum logic [1:0] {IDLE, BUSY, DONE} statetype;
  statetype state;

  logic [`DURLEN-1:0] step;
  logic SpecialCase;

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

  assign DivDone = (state == DONE) | (WZero & (state == BUSY));
  assign DivBusy = (state == BUSY & ~DivDone);

endmodule
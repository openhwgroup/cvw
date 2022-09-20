///////////////////////////////////////////
// fdivsqrt.sv
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

module fdivsqrt(
  input  logic clk, 
  input  logic reset, 
  input  logic [`FMTBITS-1:0] FmtE,
  input  logic XsE,
  input  logic [`NF:0] XmE, YmE,
  input  logic [`NE-1:0] XeE, YeE,
  input  logic XInfE, YInfE, 
  input  logic XZeroE, YZeroE, 
  input  logic XNaNE, YNaNE, 
  input  logic DivStartE, 
  input  logic StallM,
  input  logic StallE,
  input  logic SqrtE, SqrtM,
  output logic DivSM,
  output logic DivBusy,
  output logic DivDone,
  output logic [`NE+1:0] QeM,
  output logic [`DIVb:0] QmM
//   output logic [`XLEN-1:0] RemM,
);

  logic [`DIVb+3:0]  NextWSN, NextWCN;
  logic [`DIVb+3:0]  WS, WC;
  logic [`DIVb+3:0] X;
  logic [`DIVN-2:0]  D; // U0.N-1
  logic [`DIVN-2:0] Dpreproc;
  logic [`DIVb:0] FirstU, FirstUM;
  logic [`DIVb+1:0] FirstC;
  logic Firstun;
  logic WZero;

  fdivsqrtpreproc fdivsqrtpreproc(
    .clk, .DivStart(DivStartE), .Xm(XmE), .QeM, .Xe(XeE), .Fmt(FmtE), .Ye(YeE), 
    .Sqrt(SqrtE), .Ym(YmE), .XZero(XZeroE), .X, .Dpreproc);
  fdivsqrtfsm fdivsqrtfsm(
    .clk, .reset, .FmtE, .XsE, .SqrtE, 
    .DivBusy, .DivStart(DivStartE),.StallE, .StallM, .DivDone, .XZeroE, .YZeroE, 
    .XNaNE, .YNaNE,
    .XInfE, .YInfE, .WZero);
  fdivsqrtiter fdivsqrtiter(
    .clk, .Firstun, .D, .FirstU, .FirstUM, .FirstC, .SqrtE, .SqrtM, 
    .X,.Dpreproc, .FirstWS(WS), .FirstWC(WC), .NextWSN, .NextWCN, 
    .DivStart(DivStartE), .Xe(XeE), .Ye(YeE), .XZeroE, .YZeroE,
    .DivBusy);
  fdivsqrtpostproc fdivsqrtpostproc(.WS, .WC, .D, .FirstU, .FirstUM, .FirstC, .Firstun, .SqrtM, .QmM, .WZero, .DivSM);
endmodule
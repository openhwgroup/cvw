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

module divsqrt(
  input  logic clk, 
  input  logic reset, 
  input  logic [`FMTBITS-1:0] FmtE,
  input  logic [`NF:0] XManE, YManE,
  input  logic [`NE-1:0] XExpE, YExpE,
  input  logic XInfE, YInfE, 
  input  logic XZeroE, YZeroE, 
  input  logic XNaNE, YNaNE, 
  input  logic DivStartE, 
  input  logic StallM,
  input logic StallE,
  output logic DivStickyM,
  output logic DivNegStickyM,
  output logic DivBusy,
  output logic DivDone,
  output logic [`NE+1:0] DivCalcExpM,
  output logic [`DURLEN-1:0] EarlyTermShiftM,
  output logic [`QLEN-1:0] QuotM
//   output logic [`XLEN-1:0] RemM,
);

  logic [`DIVLEN+3:0]  WSN, WCN;
  logic [`DIVLEN+3:0]  WS, WC;
  logic [$clog2(`NF+2)-1:0] XZeroCnt, YZeroCnt;
  logic [`DIVLEN-1:0] X;
  logic [`DIVLEN-1:0] Dpreproc;
  logic [`DURLEN-1:0] Dur;

  srtpreproc srtpreproc(.XManE, .Dur, .YManE,.X,.Dpreproc, .XZeroCnt, .YZeroCnt);

  srtfsm srtfsm(.reset, .WSN, .WCN, .WS, .WC, .Dur, .DivBusy, .clk, .DivStart(DivStartE),.StallE, .StallM, .DivDone, .XZeroE, .YZeroE, .DivStickyE(DivStickyM), .XNaNE, .YNaNE,
                .XInfE, .YInfE, .DivNegStickyE(DivNegStickyM), .EarlyTermShiftE(EarlyTermShiftM));
  srtradix4 srtradix4(.clk, .FmtE, .X,.Dpreproc, .XZeroCnt, .YZeroCnt, .FirstWS(WS), .FirstWC(WC), .WSN, .WCN, .DivStart(DivStartE), .XExpE, .YExpE, .XZeroE, .YZeroE,
                .DivBusy, .Quot(QuotM), .Rem(), .DivCalcExpM);
endmodule
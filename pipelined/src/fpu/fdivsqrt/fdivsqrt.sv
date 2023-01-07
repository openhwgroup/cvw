///////////////////////////////////////////
// fdivsqrt.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu, amaiuolo@hmc.edu
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
  input  logic FDivStartE, IDivStartE,
  input  logic StallM,
  input  logic FlushE,
  input  logic SqrtE, SqrtM,
	input  logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // these are the src outputs before the mux choosing between them and PCE to put in srcA/B
	input  logic [2:0] 	Funct3E, Funct3M,
	input  logic MDUE, W64E,
  output logic DivSM,
  output logic FDivBusyE, IFDivStartE, FDivDoneE,
  output logic [`NE+1:0] QeM,
  output logic [`DIVb:0] QmM,
  output logic [`XLEN-1:0] FPIntDivResultM
);

  // Floating-point division and square root module, with optional integer division and remainder
  // Computes X/Y, sqrt(X), A/B, or A%B

  logic [`DIVb+3:0] WS, WC;           // Partial remainder components
  logic [`DIVb+3:0] X;                // Iterator Initial Value (from dividend)
  logic [`DIVb-1:0] DPreproc, D;      // Iterator Divisor
  logic [`DIVb:0]   FirstU, FirstUM;  // Intermediate result values
  logic [`DIVb+1:0] FirstC;           // Step tracker
  logic Firstun;                      // Quotient selection
  logic WZeroE;                       // Early termination flag
  logic SpecialCaseM;                 // Divide by zero, square root of negative, etc.
  logic DivStartE;                    // Enable signal for flops during stall

  // Integer div/rem signals
  logic BZeroM;                       // Denominator is zero
  logic MDUM;                         // Integer operation
  logic [`DIVBLEN:0] nE, nM, mM;      // Shift amounts
  logic NegQuotM, ALTBM, AsM, W64M;   // Special handling for postprocessor
  logic [`XLEN-1:0] AM;               // Original Numerator for postprocessor
  logic ISpecialCaseE;                // Integer div/remainder special cases

  fdivsqrtpreproc fdivsqrtpreproc(                        // Preprocessor
    .clk, .IFDivStartE, .Xm(XmE), .Ym(YmE), .Xe(XeE), .Ye(YeE), 
    .Fmt(FmtE), .Sqrt(SqrtE), .XZeroE, .Funct3E, 
    .QeM, .X, .DPreproc, 
    // Int-specific 
    .ForwardedSrcAE, .ForwardedSrcBE, .MDUE, .W64E, .ISpecialCaseE,
    .nE, .BZeroM, .nM, .mM, .AM, 
    .MDUM, .W64M, .NegQuotM, .ALTBM, .AsM);

  fdivsqrtfsm fdivsqrtfsm(                                // FSM
    .clk, .reset, .FmtE, .XInfE, .YInfE, .XZeroE, .YZeroE, .XNaNE, .YNaNE, 
    .FDivStartE, .XsE, .SqrtE, .WZeroE, .FlushE, .StallM, 
    .FDivBusyE, .IFDivStartE, .FDivDoneE, .SpecialCaseM, 
    // Int-specific 
    .IDivStartE, .ISpecialCaseE, .nE, .MDUE);

  fdivsqrtiter fdivsqrtiter(                              // CSA Iterator
    .clk, .IFDivStartE, .FDivBusyE, .SqrtE, .X, .DPreproc, 
    .D, .FirstU, .FirstUM, .FirstC, .Firstun, .FirstWS(WS), .FirstWC(WC));

  fdivsqrtpostproc fdivsqrtpostproc(                      // Postprocessor
    .clk, .reset, .StallM, .WS, .WC, .D, .FirstU, .FirstUM, .FirstC, 
    .SqrtE, .Firstun, .SqrtM, .SpecialCaseM, 
    .QmM, .WZeroE, .DivSM, 
    // Int-specific 
    .nM, .mM, .ALTBM, .AsM, .BZeroM, .NegQuotM, .W64M, .RemOpM(Funct3M[1]), .AM, 
    .FPIntDivResultM);
endmodule
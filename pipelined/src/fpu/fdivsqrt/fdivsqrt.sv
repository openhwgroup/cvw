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
	input  logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
	input  logic [2:0] 	Funct3E, Funct3M,
	input  logic MDUE, W64E,
  output logic DivSM,
  output logic FDivBusyE, IFDivStartE, FDivDoneE,
//  output logic DivDone,
  output logic [`NE+1:0] QeM,
  output logic [`DIVb:0] QmM,
  output logic [`XLEN-1:0] FPIntDivResultM
//   output logic [`XLEN-1:0] RemM,
);

  // Floating-point division and square root module, with optional integer division and remainder

  logic [`DIVb+3:0] WS, WC;
  logic [`DIVb+3:0] X;
  logic [`DIVb-1:0] D;
  logic [`DIVb-1:0] DPreproc;
  logic [`DIVb:0]   FirstU, FirstUM;
  logic [`DIVb+1:0] FirstC;
  logic Firstun;
  logic WZeroE;
  logic SpecialCaseM;
  logic DivStartE;

  // Integer div/rem signals
  logic AZeroM, BZeroM, AZeroE, BZeroE, MDUM;
  logic [`DIVBLEN:0] nE, nM, mM;
  logic NegQuotM, ALTBM, AsM, W64M;
  logic [`XLEN-1:0] AM;

  fdivsqrtpreproc fdivsqrtpreproc(            // Preprocessor
    // Inputs
    .clk, .IFDivStartE, .Xm(XmE), .Ym(YmE), .Xe(XeE), .Ye(YeE),
    .Fmt(FmtE), .Sqrt(SqrtE), .XZeroE, .Funct3E,
    // Int-specific Inputs
    .ForwardedSrcAE, .ForwardedSrcBE, .MDUE, .W64E,
    // Outputs
    .QeM, .X, .DPreproc, 
    // Int-specific Outputs
    .AZeroE, .BZeroE, .nE, 
    .AZeroM, .BZeroM, .nM, .mM, .AM, 
    .MDUM, .W64M, .NegQuotM, .ALTBM, .AsM);
  fdivsqrtfsm fdivsqrtfsm(                    // FSM
    // Inputs
    .clk, .reset, .FmtE, .XInfE, .YInfE,
    .XZeroE, .YZeroE, .XNaNE, .YNaNE, 
    .FDivStartE, .XsE, .SqrtE, .WZeroE, 
    .FlushE, .StallM, 
    // Int-specific Inputs
    .IDivStartE, .AZeroE, .BZeroE, .nE, .MDUE,
    // Outputs
    .FDivBusyE, .IFDivStartE, .FDivDoneE, .SpecialCaseM);
  fdivsqrtiter fdivsqrtiter(                  // CSA Iterator
    .clk, .Firstun, .D, .FirstU, .FirstUM, .FirstC, .SqrtE, 
    .X,.DPreproc, .FirstWS(WS), .FirstWC(WC),
    .IFDivStartE, .FDivBusyE);
  fdivsqrtpostproc fdivsqrtpostproc(          // Postprocessor
    .clk, .reset, .StallM,
    .WS, .WC, .D, .FirstU, .FirstUM, .FirstC, .SqrtE, .Firstun, 
    .SqrtM, .SpecialCaseM, .RemOpM(Funct3M[1]), .AM,
    .nM, .ALTBM, .mM, .BZeroM, .AsM, .NegQuotM, .W64M,
    .QmM, .WZeroE, .DivSM, .FPIntDivResultM);
endmodule
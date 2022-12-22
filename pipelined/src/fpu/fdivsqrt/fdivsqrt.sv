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
  input  logic StallE,
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

  logic [`DIVb+3:0] WS, WC;
  logic [`DIVb+3:0] X;
  logic [`DIVb-1:0] D;
  logic [`DIVb-1:0] DPreproc;
  logic [`DIVb:0]   FirstU, FirstUM;
  logic [`DIVb+1:0] FirstC;
  logic Firstun;
  logic WZeroM, AZeroM, BZeroM, AZeroE, BZeroE;
  logic SpecialCaseM;
  logic [`DIVBLEN:0] nE, nM, mM;
  logic OTFCSwapE, ALTBM, As;
  logic DivStartE;
  logic [`XLEN-1:0] ForwardedSrcAM;

  fdivsqrtpreproc fdivsqrtpreproc(
    .clk, .IFDivStartE, .Xm(XmE), .QeM, .Xe(XeE), .Fmt(FmtE), .Ye(YeE), 
    .Sqrt(SqrtE), .Ym(YmE), .XZeroE, .X, .DPreproc, .ForwardedSrcAM,
    .nE, .nM, .mM, .OTFCSwapE, .ALTBM, .AZeroM, .BZeroM, .AZeroE, .BZeroE, .As,
    .ForwardedSrcAE, .ForwardedSrcBE, .Funct3E, .Funct3M, .MDUE, .W64E);
  fdivsqrtfsm fdivsqrtfsm(
    .clk, .reset, .FmtE, .XsE, .SqrtE, .nE,
    .FDivBusyE, .FDivStartE, .IDivStartE, .IFDivStartE, .FDivDoneE, .StallE, .StallM, .FlushE, /*.DivDone, */ 
    .XZeroE, .YZeroE, .AZeroE, .BZeroE,
    .XNaNE, .YNaNE, .MDUE,
    .XInfE, .YInfE, .WZeroM, .SpecialCaseM);
  fdivsqrtiter fdivsqrtiter(
    .clk, .Firstun, .D, .FirstU, .FirstUM, .FirstC, .MDUE, .SqrtE, // .SqrtM,
    .X,.DPreproc, .FirstWS(WS), .FirstWC(WC),
    .IFDivStartE, .Xe(XeE), .Ye(YeE), .XZeroE, .YZeroE, .OTFCSwapE,
    .FDivBusyE);
  fdivsqrtpostproc fdivsqrtpostproc(
    .WS, .WC, .D, .FirstU, .FirstUM, .FirstC, .Firstun, 
    .SqrtM, .SpecialCaseM, .RemOpM(Funct3M[1]), .ForwardedSrcAM,
    .nM, .ALTBM, .mM, .BZeroM, .As,
    .QmM, .WZeroM, .DivSM, .FPIntDivResultM);
endmodule
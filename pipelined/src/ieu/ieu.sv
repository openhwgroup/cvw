///////////////////////////////////////////
// ieu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Integer Execution Unit: datapath and controller
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module ieu (
  input logic 		   clk, reset,
  // Decode Stage interface
  input logic [31:0] 	   InstrD,
  input logic 		   IllegalIEUInstrFaultD, 
  output logic 		   IllegalBaseInstrFaultD,
  // Execute Stage interface
  input logic [`XLEN-1:0]  PCE, 
  input logic [`XLEN-1:0]  PCLinkE,
  input logic 		   FWriteIntE, 
  input logic 		   IllegalFPUInstrE,
  input logic [`XLEN-1:0]  FWriteDataE,
  output logic [`XLEN-1:0] IEUAdrE,
  output logic 		   MulDivE, W64E,
  output logic [2:0] 	   Funct3E,
  output logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // these are the src outputs before the mux choosing between them and PCE to put in srcA/B

  // Memory stage interface
  input logic 		   SquashSCW, // from LSU
  output logic [1:0] 	   MemRWM, // read/write control goes to LSU
  output logic [1:0] 	   AtomicE, // atomic control goes to LSU	    
  output logic [1:0] 	   AtomicM, // atomic control goes to LSU
  output logic [`XLEN-1:0] WriteDataM, // Address and write data to LSU

  output logic [2:0] 	   Funct3M, // size and signedness to LSU
  output logic [`XLEN-1:0] SrcAM, // to privilege and fpu
  output logic [4:0]    RdM,
  input logic [`XLEN-1:0]  FIntResM, 
  output logic       InvalidateICacheM, FlushDCacheM,

  // Writeback stage
  input logic [`XLEN-1:0]  CSRReadValW, ReadDataM, MulDivResultW,
  output logic [4:0]       RdW,
  output logic [`XLEN-1:0] ReadDataW,
  // input  logic [`XLEN-1:0] PCLinkW,
  output logic 		   InstrValidM, 
  // hazards
  input logic 		   StallD, StallE, StallM, StallW,
  input logic 		   FlushD, FlushE, FlushM, FlushW,
  output logic 		   FPUStallD, LoadStallD, MulDivStallD, CSRRdStallD,
  output logic 		   PCSrcE,
  output logic 		   CSRReadM, CSRWriteM, PrivilegedM,
  output logic 		   CSRWritePendingDEM,
  output logic             StoreStallD
);

  logic [2:0]  ImmSrcD;
  logic [2:0]  FlagsE;
  logic [2:0]  ALUControlE;
  logic        ALUSrcAE, ALUSrcBE;
  logic [2:0]  ResultSrcW;
  logic        ALUResultSrcE;
  logic        SCE;
  logic [4:0]  RdE;
  logic        FWriteIntM;

  // forwarding signals
  logic [4:0]       Rs1D, Rs2D, Rs1E, Rs2E;
  logic [1:0]       ForwardAE, ForwardBE;
  logic             RegWriteM, RegWriteW;
  logic             MemReadE, CSRReadE;
  logic             JumpE;
           
  controller c(
    .clk, .reset, .StallD, .FlushD, .InstrD, .ImmSrcD,
    .IllegalIEUInstrFaultD, .IllegalBaseInstrFaultD, .StallE, .FlushE, .FlagsE, .FWriteIntE,
    .PCSrcE, .ALUControlE, .ALUSrcAE, .ALUSrcBE, .ALUResultSrcE, .MemReadE, .CSRReadE, 
    .Funct3E, .MulDivE, .W64E, .JumpE, .StallM, .FlushM, .MemRWM,
    .CSRReadM, .CSRWriteM, .PrivilegedM, .SCE, .AtomicE, .AtomicM, .Funct3M,
    .RegWriteM, .InvalidateICacheM, .FlushDCacheM, .InstrValidM, .FWriteIntM,
    .StallW, .FlushW, .RegWriteW, .ResultSrcW, .CSRWritePendingDEM, .StoreStallD);

  datapath   dp(
    .clk, .reset, .ImmSrcD, .InstrD, .StallE, .FlushE, .ForwardAE, .ForwardBE,
    .ALUControlE, .Funct3E, .ALUSrcAE, .ALUSrcBE, .ALUResultSrcE, .JumpE, .IllegalFPUInstrE,
    .FWriteDataE, .PCE, .PCLinkE, .FlagsE, .IEUAdrE, .ForwardedSrcAE, .ForwardedSrcBE, 
    .StallM, .FlushM, .FWriteIntM, .FIntResM, .SrcAM, .WriteDataM,
    .StallW, .FlushW, .RegWriteW, .SquashSCW, .ResultSrcW, .ReadDataW,
    .CSRReadValW, .ReadDataM, .MulDivResultW, .Rs1D, .Rs2D, .Rs1E, .Rs2E, .RdE, .RdM, .RdW);             
  
  forward    fw(
    .Rs1D, .Rs2D, .Rs1E, .Rs2E, .RdE, .RdM, .RdW,
    .MemReadE, .MulDivE, .CSRReadE, .RegWriteM, .RegWriteW,
    .FWriteIntE, .SCE, .ForwardAE, .ForwardBE,
    .FPUStallD, .LoadStallD, .MulDivStallD, .CSRRdStallD);
endmodule


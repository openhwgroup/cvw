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
  output logic [`XLEN-1:0] PCTargetE,
  output logic 		   MulDivE, W64E,
  output logic [2:0] 	   Funct3E,
  output logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  output logic [`XLEN-1:0] SrcAE, SrcBE,
  input logic 		   FWriteIntM,

  // Memory stage interface
  input logic 		   SquashSCW, // from LSU
  output logic [1:0] 	   MemRWM, // read/write control goes to LSU
  output logic [1:0] 	   AtomicE, // atomic control goes to LSU	    
  output logic [1:0] 	   AtomicM, // atomic control goes to LSU
  output logic [`XLEN-1:0] MemAdrM, MemAdrE, WriteDataM, // Address and write data to LSU

  output logic [2:0] 	   Funct3M, // size and signedness to LSU
  output logic [`XLEN-1:0] SrcAM, // to privilege and fpu
  output logic [4:0]    RdM,
  input logic [`XLEN-1:0]  FIntResM, 
  output logic       InvalidateICacheM, FlushDCacheM,

  // Writeback stage
  input logic [`XLEN-1:0]  CSRReadValW, ReadDataM, MulDivResultW,
  input logic 		   FWriteIntW,
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
  logic [4:0]  ALUControlE;
  logic        ALUSrcAE, ALUSrcBE;
  logic [2:0]  ResultSrcW;
  logic        TargetSrcE;
  logic        SCE;
  logic [4:0]  RdE;

  // forwarding signals
  logic [4:0]       Rs1D, Rs2D, Rs1E, Rs2E;
  logic [1:0]       ForwardAE, ForwardBE;
  logic             RegWriteM, RegWriteW;
  logic             MemReadE, CSRReadE;
  logic             JumpE;
           
  controller c(
    .clk, .reset,
    // Decode stage control signals
    .StallD, .FlushD, .InstrD, .ImmSrcD,
    .IllegalIEUInstrFaultD, .IllegalBaseInstrFaultD,
    // Execute stage control signals
    .StallE, .FlushE, .FlagsE, 
    .PCSrcE,        // for datapath and Hazard Unit
    .ALUControlE, .ALUSrcAE, .ALUSrcBE,
    .TargetSrcE,
    .MemReadE, .CSRReadE, // for Hazard Unit
    .Funct3E, .MulDivE, .W64E,
    .JumpE,	
    // Memory stage control signals
    .StallM, .FlushM, .MemRWM,
    .CSRReadM, .CSRWriteM, .PrivilegedM,
    .SCE, .AtomicE, .AtomicM, .Funct3M,
    .RegWriteM,     // for Hazard Unit
    .InvalidateICacheM, .FlushDCacheM, .InstrValidM, 
    // Writeback stage control signals
    .StallW, .FlushW,
    .RegWriteW,     // for datapath and Hazard Unit
    .ResultSrcW,
    // Stall during CSRs
    .CSRWritePendingDEM,
    .StoreStallD
  );

  datapath   dp(
    .clk, .reset,
    // Decode stage signals
    .ImmSrcD, .InstrD,
    // Execute stage signals
    .StallE, .FlushE, .ForwardAE, .ForwardBE,
    .ALUControlE, .ALUSrcAE, .ALUSrcBE,
    .TargetSrcE, .JumpE, .IllegalFPUInstrE,
    .FWriteDataE, .PCE, .PCLinkE, .FlagsE,
    .PCTargetE,
    .ForwardedSrcAE, .ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
    .SrcAE, .SrcBE,
    // Memory stage signals
    .StallM, .FlushM, .FWriteIntM, .FIntResM, 
    .SrcAM, .WriteDataM, .MemAdrM, .MemAdrE,
    // Writeback stage signals
    .StallW, .FlushW, .FWriteIntW, .RegWriteW, 
    .SquashSCW, .ResultSrcW, .ReadDataW,
    // input  logic [`XLEN-1:0] PCLinkW,
    .CSRReadValW, .ReadDataM, .MulDivResultW, 
    // Hazard Unit signals 
    .Rs1D, .Rs2D, .Rs1E, .Rs2E,
    .RdE, .RdM, .RdW 
  );             
  
  forward    fw(
    .Rs1D, .Rs2D, .Rs1E, .Rs2E, .RdE, .RdM, .RdW,
    .MemReadE, .MulDivE, .CSRReadE,
    .RegWriteM, .RegWriteW,
    .FWriteIntE, .FWriteIntM, .FWriteIntW,
    .SCE,
    // Forwarding controls
    .ForwardAE, .ForwardBE,
    .FPUStallD, .LoadStallD, .MulDivStallD, .CSRRdStallD
    );

endmodule


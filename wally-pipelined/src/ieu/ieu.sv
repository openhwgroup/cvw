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
  output logic       RegWriteD,
  // Execute Stage interface
  input logic [`XLEN-1:0]  PCE, 
  input logic [`XLEN-1:0]  PCLinkE,
  input logic 		         FWriteIntE, 
  input logic              IsFPE,
  //input  logic [1:0]       FMemRWE,
  input  logic [`XLEN-1:0] FWriteDataE,
  output logic [`XLEN-1:0] PCTargetE,
  output logic 		   MulDivE, W64E,
  output logic [2:0] 	   Funct3E,
  output logic [`XLEN-1:0] SrcAE, SrcBE,
  // Memory stage interface
  input logic 		   DataMisalignedM,
  input logic 		   DataAccessFaultM,
  input logic	     	   FWriteIntM,
  input  logic [`XLEN-1:0] FIntResM,
  output logic [1:0] 	   MemRWM,
  output logic [1:0] 	   AtomicM,
  output logic [`XLEN-1:0] MemAdrM, WriteDataM,
  output logic [`XLEN-1:0] SrcAM,
  output logic [2:0] 	   Funct3M,
  // Writeback stage
  input logic [`XLEN-1:0]  CSRReadValW, ReadDataW, MulDivResultW,
  input logic             FWriteIntW,
  input logic             SquashSCW,
  // input  logic [`XLEN-1:0] PCLinkW,
  output logic 		   InstrValidM, InstrValidW,
  // hazards
  input logic 		   StallD, StallE, StallM, StallW,
  input logic 		   FlushD, FlushE, FlushM, FlushW,
  output logic 		   FPUStallD, LoadStallD, MulDivStallD, CSRRdStallD,
  output logic 		   PCSrcE,
  input logic 		   DivDoneE,
  input logic 		   DivBusyE,
  output logic 		   CSRReadM, CSRWriteM, PrivilegedM,
  output logic 		   CSRWritePendingDEM
);

  logic [2:0]  ImmSrcD;
  logic [2:0]  FlagsE;
  logic [4:0]  ALUControlE;
  logic        ALUSrcAE, ALUSrcBE;
  logic [2:0]  ResultSrcW;
  logic        TargetSrcE;
  logic        SCE;

  // forwarding signals
  logic [4:0]       Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;
  logic [1:0]       ForwardAE, ForwardBE;
  logic             RegWriteM, RegWriteW;
  logic             MemReadE, CSRReadE;
  logic             JumpE;
  logic [1:0]       MemRWE;
           
  controller c(.*);
  datapath   dp(.*);             
  forward    fw(.*);

endmodule


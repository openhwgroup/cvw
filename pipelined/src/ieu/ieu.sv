///////////////////////////////////////////
// ieu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Integer Execution Unit: datapath and controller
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

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
  input logic 		   FWriteIntE, FCvtIntE, FCvtIntW,
  output logic [`XLEN-1:0] IEUAdrE,
  output logic 		   IntDivE, W64E,
  output logic [2:0] 	   Funct3E,
  output logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // these are the src outputs before the mux choosing between them and PCE to put in srcA/B

  // Memory stage interface
  input logic 		   SquashSCW, // from LSU
  output logic [1:0] 	   MemRWM, // read/write control goes to LSU
  output logic [1:0] 	   AtomicM, // atomic control goes to LSU
  output logic [`XLEN-1:0] WriteDataM, // write data to LSU

  output logic [2:0] 	   Funct3M, // size and signedness to LSU
  output logic [`XLEN-1:0] SrcAM, // to privilege and fpu
  output logic [4:0]    RdE, RdM,
  input logic [`XLEN-1:0]  FIntResM, 
  output logic       InvalidateICacheM, FlushDCacheM,

  // Writeback stage
  input logic [`XLEN-1:0] FIntDivResultW,
  input logic [`XLEN-1:0]  CSRReadValW, MDUResultW,
  input logic [`XLEN-1:0]  FCvtIntResW,
  output logic [4:0]       RdW,
  input logic [`XLEN-1:0] ReadDataW,
  output logic 		   InstrValidM, 
  // hazards
  input logic 		   StallD, StallE, StallM, StallW,
  input logic 		   FlushD, FlushE, FlushM, FlushW,
  output logic 		   FCvtIntStallD, LoadStallD, MDUStallD, CSRRdStallD,
  output logic 		   PCSrcE,
  output logic 		   CSRReadM, CSRWriteM, PrivilegedM,
  output logic 		   CSRWriteFenceM,
  output logic             StoreStallD
);

  logic [2:0]  ImmSrcD;
  logic [1:0]  FlagsE;
  logic [2:0]  ALUControlE;
  logic        ALUSrcAE, ALUSrcBE;
  logic [2:0]  ResultSrcW;
  logic        ALUResultSrcE;
  logic        SCE;
  logic        FWriteIntM;
  logic        IntDivW;

  // forwarding signals
  logic [4:0]       Rs1D, Rs2D, Rs1E, Rs2E;
  logic [1:0]       ForwardAE, ForwardBE;
  logic             RegWriteM, RegWriteW;
  logic             MemReadE, CSRReadE;
  logic             JumpE;
  logic             BranchSignedE;
  logic             MDUE;
           
  controller c(
    .clk, .reset, .StallD, .FlushD, .InstrD, .ImmSrcD,
    .IllegalIEUInstrFaultD, .IllegalBaseInstrFaultD, .StallE, .FlushE, .FlagsE, .FWriteIntE,
    .PCSrcE, .ALUControlE, .ALUSrcAE, .ALUSrcBE, .ALUResultSrcE, .MemReadE, .CSRReadE, 
    .Funct3E, .IntDivE, .MDUE, .W64E, .JumpE, .SCE, .BranchSignedE, .StallM, .FlushM, .MemRWM,
    .CSRReadM, .CSRWriteM, .PrivilegedM, .AtomicM, .Funct3M,
    .RegWriteM, .InvalidateICacheM, .FlushDCacheM, .InstrValidM, .FWriteIntM,
    .StallW, .FlushW, .RegWriteW, .IntDivW, .ResultSrcW, .CSRWriteFenceM, .StoreStallD);

  datapath   dp(
    .clk, .reset, .ImmSrcD, .InstrD, .StallE, .FlushE, .ForwardAE, .ForwardBE,
    .ALUControlE, .Funct3E, .ALUSrcAE, .ALUSrcBE, .ALUResultSrcE, .JumpE, .BranchSignedE, 
    .PCE, .PCLinkE, .FlagsE, .IEUAdrE, .ForwardedSrcAE, .ForwardedSrcBE, 
    .StallM, .FlushM, .FWriteIntM, .FIntResM, .SrcAM, .WriteDataM, .FCvtIntW,
    .StallW, .FlushW, .RegWriteW, .IntDivW, .SquashSCW, .ResultSrcW, .ReadDataW, .FCvtIntResW,
    .CSRReadValW, .MDUResultW, .FIntDivResultW, .Rs1D, .Rs2D, .Rs1E, .Rs2E, .RdE, .RdM, .RdW);             
  
  forward    fw(
    .Rs1D, .Rs2D, .Rs1E, .Rs2E, .RdE, .RdM, .RdW,
    .MemReadE, .MDUE, .CSRReadE, .RegWriteM, .RegWriteW,
    .FCvtIntE, .SCE, .ForwardAE, .ForwardBE,
    .FCvtIntStallD, .LoadStallD, .MDUStallD, .CSRRdStallD);
endmodule


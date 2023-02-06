///////////////////////////////////////////
// ieu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Integer Execution Unit: datapath and controller
// 
// Documentation: RISC-V System on Chip Design Chapter 4 (Figure 4.12)
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
  input  logic 		          clk, reset,
  // Decode stage signals
  input  logic [31:0] 	    InstrD,                          // Instruction
  input  logic 		          IllegalIEUInstrFaultD,           // Illegal instruction
  output logic 		          IllegalBaseInstrFaultD,          // Illegal I-type instruction, or illegal RV32 access to upper 16 registers
  // Execute stage signals
  input  logic [`XLEN-1:0]  PCE,                             // PC
  input  logic [`XLEN-1:0]  PCLinkE,                         // PC + 4
  output logic 		          PCSrcE,                          // Select next PC (between PC+4 and IEUAdrE)
  input  logic 		          FWriteIntE, FCvtIntE,            // FPU writes to integer register file, FPU converts float to int
  output logic [`XLEN-1:0]  IEUAdrE,                         // Memory address
  output logic 		          IntDivE, W64E,                   // Integer divide, RV64 W-type instruction 
  output logic [2:0] 	      Funct3E,                         // Funct3 instruction field
  output logic [`XLEN-1:0]  ForwardedSrcAE, ForwardedSrcBE,  // ALU src inputs before the mux choosing between them and PCE to put in srcA/B
  output logic [4:0]        RdE,                             // Destination register
  // Memory stage signals
  input  logic 		          SquashSCW,                       // Squash store conditional, from LSU
  output logic [1:0] 	      MemRWM,                          // Read/write control goes to LSU
  output logic [1:0] 	      AtomicM,                         // Atomic control goes to LSU
  output logic [`XLEN-1:0]  WriteDataM,                      // Write data to LSU
  output logic [2:0] 	      Funct3M,                         // Funct3 (size and signedness) to LSU
  output logic [`XLEN-1:0]  SrcAM,                           // ALU SrcA to Privileged unit and FPU
  output logic [4:0]        RdM,                             // Destination register
  input  logic [`XLEN-1:0]  FIntResM,                        // Integer result from FPU (fmv, fclass, fcmp)
  output logic              InvalidateICacheM, FlushDCacheM, // Invalidate I$, flush D$
  output logic 		          InstrValidM,                     // Instruction is valid
  // Writeback stage signals
  input  logic [`XLEN-1:0]  FIntDivResultW,                  // Integer divide result from FPU fdivsqrt)
  input  logic [`XLEN-1:0]  CSRReadValW,                     // CSR read value, 
  input  logic [`XLEN-1:0]  MDUResultW,                      // multiply/divide unit result
  input  logic [`XLEN-1:0]  FCvtIntResW,                     // FPU's float to int conversion result
  input  logic              FCvtIntW,                        // FPU converts float to int
  output logic [4:0]        RdW,                             // Destination register
  input  logic [`XLEN-1:0]  ReadDataW,                       // LSU's read data
  // Hazard unit signals
  input  logic 		          StallD, StallE, StallM, StallW,  // Stall signals from hazard unit
  input  logic 		          FlushD, FlushE, FlushM, FlushW,  // Flush signals
  output logic 		          FCvtIntStallD, LoadStallD,       // Stall causes from IEU to hazard unit
  output logic              MDUStallD, CSRRdStallD, StoreStallD,
  output logic 		          CSRReadM, CSRWriteM, PrivilegedM,// CSR read, CSR write, is privileged instruction
  output logic 		          CSRWriteFenceM                   // CSR write or fence instruction needs to flush subsequent instructions
);

  logic [2:0] ImmSrcD;                                       // Select type of immediate extension 
  logic [1:0] FlagsE;                                        // Comparison flags ({eq, lt})
  logic [2:0] ALUControlE;                                   // ALU control indicates function to perform
  logic       ALUSrcAE, ALUSrcBE;                            // ALU source operands
  logic [2:0] ResultSrcW;                                    // Selects result in Writeback stage
  logic       ALUResultSrcE;                                 // Selects ALU result to pass on to Memory stage
  logic       SCE;                                           // Store Conditional instruction
  logic       FWriteIntM;                                    // FPU writing to integer register file
  logic       IntDivW;                                       // Integer divide instruction

  // Forwarding signals
  logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E;                        // Source and destination registers
  logic [1:0] ForwardAE, ForwardBE;                          // Select signals for forwarding multiplexers
  logic       RegWriteM, RegWriteW;                          // Register will be written in Memory, Writeback stages
  logic       MemReadE, CSRReadE;                            // Load, CSRRead instruction
  logic       JumpE;                                         // Jump instruction
  logic       BranchSignedE;                                 // Branch does signed comparison on operands
  logic       MDUE;                                          // Multiply/divide instruction
           
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


///////////////////////////////////////////
// controller.sv
//
// Written: Kevin Kim <kekim@hmc.edu>
// Created: 16 February 2023
// Modified: 
//
// Purpose: Top level B instrution controller module
// 
// Documentation: RISC-V System on Chip Design Chapter 4 (Section 4.1.4, Figure 4.8, Table 4.5)
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

// NOTE: DO we want to make this XLEN parameterized?
module bmuctrl(
  input  logic		    clk, reset,
  // Decode stage control signals
  input  logic        StallD, FlushD,          // Stall, flush Decode stage
  input  logic [31:0] InstrD,                  // Instruction in Decode stage
  output logic [2:0]  ALUSelectD,              // ALU Mux select signal
  output logic [3:0]  BSelectD,                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding in Decode stage
  // Execute stage control signals             
  input  logic 	      StallE, FlushE,          // Stall, flush Execute stage
  output logic [6:0]  Funct7E,                 // Instruction's funct7 field (note: eventually want to get rid of this)
  output logic [2:0]  ALUSelectE,
  output logic [3:0]  BSelectE                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding
);

  logic [6:0] OpD;                             // Opcode in Decode stage
  logic [2:0] Funct3D;                         // Funct3 field in Decode stage
  logic [6:0] Funct7D;                         // Funct7 field in Decode stage
  logic [4:0] Rs1D;                            // Rs1 source register in Decode stage

  `define BMUCTRLW 7

  logic [`BMUCTRLW-1:0] BMUControlsD;                 // Main B Instructions Decoder control signals


  // Extract fields
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7D = InstrD[31:25];
  assign Rs1D = InstrD[19:15];

  // Main Instruction Decoder
  always_comb
    casez({OpD, Funct7D, Funct3D})
    // ALUSelect_BSelect
      17'b0010011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_0001;  // bclri
      17'b0010011_0100101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b111_0001;  // bclri (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000;  // illegal instruction
      17'b0010011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_0001;  // bexti
      17'b0010011_0100101_101: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b101_0001;  // bexti (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000;  // illegal instruction
      17'b0010011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_0001;  // binvi
      17'b0010011_0110101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b100_0001;  // binvi (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000;  // illegal instruction
      17'b0010011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_0001;  // bseti
      17'b0010011_0010101_001: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b110_0001;  // bseti
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000;  // illegal instruction
      17'b0110011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_0001;  // bclr
      17'b0110011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_0001;  // bext
      17'b0110011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_0001;  // binv
      17'b0110011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_0001;  // bset
      17'b0?1?011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_0000;  // sra, srai, srl, srli, sll, slli
      17'b0110011_0000101_0??:   BMUControlsD = `BMUCTRLW'b000_0010;  // ZBC instruction
      17'b0110011_0010000_?01:   BMUControlsD = `BMUCTRLW'b001_1000;  // slli.uw 
      17'b0110011_0010000_010:   BMUControlsD = `BMUCTRLW'b000_1000;  // sh1add
      17'b0110011_0010000_100:   BMUControlsD = `BMUCTRLW'b000_1000;  // sh2add
      17'b0110011_0010000_110:   BMUControlsD = `BMUCTRLW'b000_1000;  // sh3add
      17'b0110011_0000100_000:   BMUControlsD = `BMUCTRLW'b000_1000;  // sh3add
      default:                   BMUControlsD = {Funct3D, {4'b0}};    // not B instruction or shift
    endcase

  // Unpack Control Signals

  assign {ALUSelectD,BSelectD} = BMUControlsD;

   

  // BMU Execute stage pipieline control register
  flopenrc#(14) controlregBMU(clk, reset, FlushE, ~StallE, {Funct7D, ALUSelectD, BSelectD}, {Funct7E, ALUSelectE, BSelectE});
endmodule
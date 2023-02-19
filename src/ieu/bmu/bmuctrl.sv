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
  output logic [2:0]  ZBBSelectD,              // ZBB mux select signal in Decode stage NOTE: do we need this in decode?
  // Execute stage control signals             
  input  logic 	      StallE, FlushE,          // Stall, flush Execute stage
  output logic [2:0]  ALUSelectE,
  output logic [3:0]  BSelectE,                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding
  output logic [2:0]  ZBBSelectE               // ZBB mux select signal
);

  logic [6:0] OpD;                             // Opcode in Decode stage
  logic [2:0] Funct3D;                         // Funct3 field in Decode stage
  logic [6:0] Funct7D;                         // Funct7 field in Decode stage
  logic [4:0] Rs2D;                            // Rs2 source register in Decode stage

  `define BMUCTRLW 10

  logic [`BMUCTRLW-1:0] BMUControlsD;                 // Main B Instructions Decoder control signals


  // Extract fields
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7D = InstrD[31:25];
  assign Rs2D = InstrD[24:20];

  // Main Instruction Decoder
  always_comb
    casez({OpD, Funct7D, Funct3D})
    // ALUSelect_BSelect_ZBBSelect
      // ZBS
      17'b0010011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_0001_000;  // bclri
      17'b0010011_0100101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b111_0001_000;  // bclri (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000;  // illegal instruction
      17'b0010011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_0001_000;  // bexti
      17'b0010011_0100101_101: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b101_0001_000;  // bexti (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000;  // illegal instruction
      17'b0010011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_0001_000;  // binvi
      17'b0010011_0110101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b100_0001_000;  // binvi (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000;  // illegal instruction
      17'b0010011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_0001_000;  // bseti
      17'b0010011_0010101_001: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b110_0001_000;  // bseti
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000;  // illegal instruction
      17'b0110011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_0001_000;  // bclr
      17'b0110011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_0001_000;  // bext
      17'b0110011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_0001_000;  // binv
      17'b0110011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_0001_000;  // bset
      17'b0?1?011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_0000_000;  // sra, srai, srl, srli, sll, slli
      // ZBC
      17'b0110011_0000101_0??:   BMUControlsD = `BMUCTRLW'b000_0010_000;  // ZBC instruction
      // ZBA
      17'b0110011_0010000_010:   BMUControlsD = `BMUCTRLW'b000_1000_000;  // sh1add
      17'b0110011_0010000_100:   BMUControlsD = `BMUCTRLW'b000_1000_000;  // sh2add
      17'b0110011_0010000_110:   BMUControlsD = `BMUCTRLW'b000_1000_000;  // sh3add
      17'b0111011_0010000_010:   BMUControlsD = `BMUCTRLW'b000_1000_000;  // sh1add.uw
      17'b0111011_0010000_100:   BMUControlsD = `BMUCTRLW'b000_1000_000;  // sh2add.uw
      17'b0111011_0010000_110:   BMUControlsD = `BMUCTRLW'b000_1000_000;  // sh3add.uw
      17'b0111011_0000100_000:   BMUControlsD = `BMUCTRLW'b000_1000_000;  // add.uw
      17'b0011011_000010?_001:   BMUControlsD = `BMUCTRLW'b001_1000_000;  // slli.uw
      // ZBB
      17'b0110011_0110000_001:   BMUControlsD = `BMUCTRLW'b001_0100_111;  // rol
      17'b0111011_0110000_001:   BMUControlsD = `BMUCTRLW'b001_0100_111;  // rolw
      17'b0110011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_0100_111;  // ror
      17'b0111011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_0100_111;  // rorw
      17'b0010011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_0100_111;  // rori (rv32)
      17'b0010011_0110001_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b001_0100_111;  // rori (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000;  // illegal instruction
      17'b0011011_0110000_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b001_0100_111;  // roriw 
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000;  // illegal instruction
      17'b0010011_0110000_001: if (Rs2D[2])
                                 BMUControlsD = `BMUCTRLW'b000_0100_000;  // count instruction
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0100_100;  // sign ext instruction
                                 
      default:                   BMUControlsD = {Funct3D, {7'b0}};    // not B instruction or shift
    endcase

  // Unpack Control Signals

  assign {ALUSelectD,BSelectD,ZBBSelectD} = BMUControlsD;

   

  // BMU Execute stage pipieline control register
  flopenrc#(10) controlregBMU(clk, reset, FlushE, ~StallE, {ALUSelectD, BSelectD, ZBBSelectD}, {ALUSelectE, BSelectE, ZBBSelectE});
endmodule
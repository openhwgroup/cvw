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
  output logic        BRegWriteD,              // Indicates if it is a R type B instruction
  output logic        BW64D,                   // Indiciates if it is a W type B instruction
  output logic        BALUOpD,                 // Indicates if it is an ALU B instruction
  output logic        IllegalBitmanipInstrD,   // Indicates if it is unrecognized B instruction
  // Execute stage control signals             
  input  logic 	      StallE, FlushE,          // Stall, flush Execute stage
  output logic [2:0]  ALUSelectE,
  output logic [3:0]  BSelectE,                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding
  output logic [2:0]  ZBBSelectE,              // ZBB mux select signal
  output logic        BRegWriteE               // Indicates if it is a R type B instruction in Execute
);

  logic [6:0] OpD;                             // Opcode in Decode stage
  logic [2:0] Funct3D;                         // Funct3 field in Decode stage
  logic [6:0] Funct7D;                         // Funct7 field in Decode stage
  logic [4:0] Rs2D;                            // Rs2 source register in Decode stage

  `define BMUCTRLW 14

  logic [`BMUCTRLW-1:0] BMUControlsD;                 // Main B Instructions Decoder control signals


  // Extract fields
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7D = InstrD[31:25];
  assign Rs2D = InstrD[24:20];

  // Main Instruction Decoder
  always_comb
    casez({OpD, Funct7D, Funct3D})
    // ALUSelect_BSelect_ZBBSelect_BRegWrite_BW64_BALUOp
      // ZBS
      17'b0010011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_0001_000_1_0_1_0;  // bclri
      17'b0010011_0100101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b111_0001_000_1_0_1_0;  // bclri (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0010011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_0001_000_1_0_1_0;  // bexti
      17'b0010011_0100101_101: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b101_0001_000_1_0_1_0;  // bexti (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0010011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_0001_000_1_0_1_0;  // binvi
      17'b0010011_0110101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b100_0001_000_1_0_1_0;  // binvi (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0010011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_0001_000_1_0_1_0;  // bseti
      17'b0010011_0010101_001: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b110_0001_000_1_0_1_0;  // bseti (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0110011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_0001_000_1_0_1_0;  // bclr
      17'b0110011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_0001_000_1_0_1_0;  // bext
      17'b0110011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_0001_000_1_0_1_0;  // binv
      17'b0110011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_0001_000_1_0_1_0;  // bset
      17'b0?1?011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_0000_000_1_0_1_0;  // sra, srai, srl, srli, sll, slli
      // ZBC
      17'b0110011_0000101_0??:   BMUControlsD = `BMUCTRLW'b000_0010_000_1_0_1_0;  // ZBC instruction
      // ZBA
      17'b0110011_0010000_010:   BMUControlsD = `BMUCTRLW'b000_1000_000_1_0_1_0;  // sh1add
      17'b0110011_0010000_100:   BMUControlsD = `BMUCTRLW'b000_1000_000_1_0_1_0;  // sh2add
      17'b0110011_0010000_110:   BMUControlsD = `BMUCTRLW'b000_1000_000_1_0_1_0;  // sh3add
      17'b0111011_0010000_010:   BMUControlsD = `BMUCTRLW'b000_1000_000_1_1_1_0;  // sh1add.uw
      17'b0111011_0010000_100:   BMUControlsD = `BMUCTRLW'b000_1000_000_1_1_1_0;  // sh2add.uw
      17'b0111011_0010000_110:   BMUControlsD = `BMUCTRLW'b000_1000_000_1_1_1_0;  // sh3add.uw
      17'b0111011_0000100_000:   BMUControlsD = `BMUCTRLW'b000_1000_000_1_1_1_0;  // add.uw
      17'b0011011_000010?_001:   BMUControlsD = `BMUCTRLW'b001_1000_000_1_1_1_0;  // slli.uw
      // ZBB
      17'b0110011_0110000_001:   BMUControlsD = `BMUCTRLW'b001_0100_111_1_0_1_0;  // rol
      17'b0111011_0110000_001:   BMUControlsD = `BMUCTRLW'b001_0100_111_1_1_1_0;  // rolw
      17'b0110011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_0100_111_1_0_1_0;  // ror
      17'b0111011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_0100_111_1_1_1_0;  // rorw
      17'b0010011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_0100_111_1_0_1_0;  // rori (rv32)
      17'b0010011_0110001_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b001_0100_111_1_0_1_0;  // rori (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0011011_0110000_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b001_0100_111_1_1_1_0;  // roriw 
                               else
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0010011_0110000_001: if (Rs2D[2])
                                 BMUControlsD = `BMUCTRLW'b000_0100_100_1_0_1_0;  // sign extend instruction
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0100_000_1_0_1_0;  // count instruction
      17'b0011011_0110000_001:   BMUControlsD = `BMUCTRLW'b000_0100_000_1_1_1_0;  // count word instruction
      17'b0111011_0000100_100: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b000_0100_100_1_0_1_0;  // zexth (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0110011_0000100_100: if (`XLEN == 32)
                                 BMUControlsD = `BMUCTRLW'b000_0100_100_1_0_1_0;  // zexth (rv32)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0110011_0100000_111:   BMUControlsD = `BMUCTRLW'b111_0100_111_1_0_1_0;  // andn
      17'b0110011_0100000_110:   BMUControlsD = `BMUCTRLW'b110_0100_111_1_0_1_0;  // orn
      17'b0110011_0100000_100:   BMUControlsD = `BMUCTRLW'b100_0100_111_1_0_1_0;  // xnor
      17'b0010011_0110101_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b000_0100_011_1_0_1_0;  // rev8 (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0010011_0110100_101: if (`XLEN == 32) 
                                 BMUControlsD = `BMUCTRLW'b000_0100_011_1_0_1_0;  // rev8 (rv32)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_0000_000_0_0_0_1;  // illegal instruction
      17'b0010011_0010100_101:   BMUControlsD = `BMUCTRLW'b000_0100_011_1_0_1_0;  // orc.b
      17'b0110011_0000101_110:   BMUControlsD = `BMUCTRLW'b000_0100_101_1_0_1_0;  // max
      17'b0110011_0000101_111:   BMUControlsD = `BMUCTRLW'b000_0100_101_1_0_1_0;  // maxu
      17'b0110011_0000101_100:   BMUControlsD = `BMUCTRLW'b000_0100_110_1_0_1_0;  // min
      17'b0110011_0000101_101:   BMUControlsD = `BMUCTRLW'b000_0100_110_1_0_1_0;  // minu
                                 
      default:                   BMUControlsD = {Funct3D, {10'b0}, {1'b1}};        // not B instruction or shift
    endcase

  // Unpack Control Signals

  assign {ALUSelectD,BSelectD,ZBBSelectD, BRegWriteD, BW64D, BALUOpD, IllegalBitmanipInstrD} = BMUControlsD;

   

  // BMU Execute stage pipieline control register
  flopenrc#(11) controlregBMU(clk, reset, FlushE, ~StallE, {ALUSelectD, BSelectD, ZBBSelectD, BRegWriteD}, {ALUSelectE, BSelectE, ZBBSelectE, BRegWriteE});
endmodule
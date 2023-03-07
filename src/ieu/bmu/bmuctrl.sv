///////////////////////////////////////////
// bmuctrl.sv
//
// Written: Kevin Kim <kekim@hmc.edu>
// Created: 16 February 2023
// Modified: 6 March 2023
//
// Purpose: Top level bit manipulation instruction decoder
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

module bmuctrl(
  input  logic		    clk, reset,
  // Decode stage control signals
  input  logic        StallD, FlushD,          // Stall, flush Decode stage
  input  logic [31:0] InstrD,                  // Instruction in Decode stage
  output logic [2:0]  ALUSelectD,              // ALU Mux select signal in Decode Stage
  output logic [1:0]  BSelectD,                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding in Decode stage
  output logic [2:0]  ZBBSelectD,              // ZBB mux select signal in Decode stage NOTE: do we need this in decode?
  output logic        BRegWriteD,              // Indicates if it is a R type B instruction in Decode Stage
  output logic        BALUSrcBD,               // Indicates if it is an I/IW (non auipc) type B instruction in Decode Stage
  output logic        BW64D,                   // Indiciates if it is a W type B instruction in Decode Stage
  output logic        BALUOpD,                 // Indicates if it is an ALU B instruction in Decode Stage
  output logic        BSubArithD,              // TRUE if ext, clr, andn, orn, xnor instruction in Decode Stage
  output logic        IllegalBitmanipInstrD,   // Indicates if it is unrecognized B instruction in Decode Stage
  // Execute stage control signals             
  input  logic 	      StallE, FlushE,          // Stall, flush Execute stage
  output logic [2:0]  ALUSelectE,
  output logic [1:0]  BSelectE,                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding
  output logic [2:0]  ZBBSelectE,              // ZBB mux select signal
  output logic        BRegWriteE,              // Indicates if it is a R type B instruction in Execute
  output logic        BComparatorSignedE,      // Indicates if comparator signed in Execute Stage
  output logic [2:0]  BALUControlE             // ALU Control signals for B instructions in Execute Stage
);

  logic [6:0] OpD;                             // Opcode in Decode stage
  logic [2:0] Funct3D;                         // Funct3 field in Decode stage
  logic [6:0] Funct7D;                         // Funct7 field in Decode stage
  logic [4:0] Rs2D;                            // Rs2 source register in Decode stage
  logic       BComparatorSignedD;              // Indicates if comparator signed (max, min instruction) in Decode Stage
  logic       RotateD;                         // Indicates if rotate instruction in Decode Stage
  logic       MaskD;                           // Indicates if zbs instruction in Decode Stage
  logic       PreShiftD;                       // Indicates if sh1add, sh2add, sh3add instruction in Decode Stage
  logic [2:0] BALUControlD;                    // ALU Control signals for B instructions

  `define BMUCTRLW 17

  logic [`BMUCTRLW-1:0] BMUControlsD;                 // Main B Instructions Decoder control signals

  // Extract fields
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7D = InstrD[31:25];
  assign Rs2D = InstrD[24:20];

  // Main Instruction Decoder
  always_comb
    casez({OpD, Funct7D, Funct3D})
    // ALUSelect_BSelect_ZBBSelect_BRegWrite_BALUSrcB_BW64_BALUOp_BSubArithD_RotateD_MaskD_PreShiftD_IllegalBitmanipInstrD
      // ZBS
      17'b0010011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_01_000_1_1_0_1_1_0_1_0_0;  // bclri
      17'b0010011_0100101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b111_01_000_1_1_0_1_1_0_1_0_0;  // bclri (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0010011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_01_000_1_1_0_1_1_0_1_0_0;  // bexti
      17'b0010011_0100101_101: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b101_01_000_1_1_0_1_1_0_1_0_0;  // bexti (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0010011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_01_000_1_1_0_1_0_0_1_0_0;  // binvi
      17'b0010011_0110101_001: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b100_01_000_1_1_0_1_0_0_1_0_0;  // binvi (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0010011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_01_000_1_1_0_1_0_0_1_0_0;  // bseti
      17'b0010011_0010101_001: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b110_01_000_1_1_0_1_0_0_1_0_0;  // bseti (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0110011_0100100_001:   BMUControlsD = `BMUCTRLW'b111_01_000_1_0_0_1_1_0_1_0_0;  // bclr
      17'b0110011_0100100_101:   BMUControlsD = `BMUCTRLW'b101_01_000_1_0_0_1_1_0_1_0_0;  // bext
      17'b0110011_0110100_001:   BMUControlsD = `BMUCTRLW'b100_01_000_1_0_0_1_0_0_1_0_0;  // binv
      17'b0110011_0010100_001:   BMUControlsD = `BMUCTRLW'b110_01_000_1_0_0_1_0_0_1_0_0;  // bset
      //17'b0?1?011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_00_000_1_0_0_1_0_0_0_0_0;  // sra, srai, srl, srli, sll, slli
      17'b0110011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_00_000_1_0_0_1_0_0_0_0_0;  // sra, srl, sll
      17'b0010011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_00_000_1_1_0_1_0_0_0_0_0;  // srai, srli, slli
      17'b0111011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_00_000_1_0_1_1_0_0_0_0_0;  // sraw, srlw, sllw
      17'b0011011_0?0000?_?01:   BMUControlsD = `BMUCTRLW'b001_00_000_1_1_1_1_0_0_0_0_0;  // sraiw, srliw, slliw
      // ZBC
      17'b0110011_0000101_0??:   BMUControlsD = `BMUCTRLW'b000_11_000_1_0_0_1_0_0_0_0_0;  // ZBC instruction
      // ZBA
      17'b0110011_0010000_010:   BMUControlsD = `BMUCTRLW'b000_01_000_1_0_0_1_0_0_0_1_0;  // sh1add
      17'b0110011_0010000_100:   BMUControlsD = `BMUCTRLW'b000_01_000_1_0_0_1_0_0_0_1_0;  // sh2add
      17'b0110011_0010000_110:   BMUControlsD = `BMUCTRLW'b000_01_000_1_0_0_1_0_0_0_1_0;  // sh3add
      17'b0111011_0010000_010:   BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_1_0;  // sh1add.uw
      17'b0111011_0010000_100:   BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_1_0;  // sh2add.uw
      17'b0111011_0010000_110:   BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_1_0;  // sh3add.uw
      17'b0111011_0000100_000:   BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_0_0;  // add.uw
      17'b0011011_000010?_001:   BMUControlsD = `BMUCTRLW'b001_01_000_1_1_1_1_0_0_0_0_0;  // slli.uw
      // ZBB
      17'b0110011_0110000_001:   BMUControlsD = `BMUCTRLW'b001_01_111_1_0_0_1_0_1_0_0_0;  // rol
      17'b0111011_0110000_001:   BMUControlsD = `BMUCTRLW'b001_00_111_1_0_1_1_0_1_0_0_0;  // rolw
      17'b0110011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_01_111_1_0_0_1_0_1_0_0_0;  // ror
      17'b0111011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_00_111_1_0_1_1_0_1_0_0_0;  // rorw
      17'b0010011_0110000_101:   BMUControlsD = `BMUCTRLW'b001_00_111_1_1_0_1_0_1_0_0_0;  // rori (rv32)
      17'b0010011_0110001_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b001_00_111_1_1_0_1_0_1_0_0_0;  // rori (rv64)
                               else
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0011011_0110000_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b001_00_111_1_1_1_1_0_1_0_0_0;  // roriw 
                               else
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0010011_0110000_001: if (Rs2D[2])
                                 BMUControlsD = `BMUCTRLW'b000_10_001_1_1_0_1_0_0_0_0_0;  // sign extend instruction
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_10_000_1_1_0_1_0_0_0_0_0;  // count instruction
      17'b0011011_0110000_001:   BMUControlsD = `BMUCTRLW'b000_10_000_1_1_1_1_0_0_0_0_0;  // count word instruction
      17'b0111011_0000100_100: if (`XLEN == 64)
                                 BMUControlsD = `BMUCTRLW'b000_10_001_1_0_0_1_0_0_0_0_0;  // zexth (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0110011_0000100_100: if (`XLEN == 32)
                                 BMUControlsD = `BMUCTRLW'b000_10_001_1_1_0_1_0_0_0_0_0;  // zexth (rv32)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0110011_0100000_111:   BMUControlsD = `BMUCTRLW'b111_01_111_1_0_0_1_1_0_0_0_0;  // andn
      17'b0110011_0100000_110:   BMUControlsD = `BMUCTRLW'b110_01_111_1_0_0_1_1_0_0_0_0;  // orn
      17'b0110011_0100000_100:   BMUControlsD = `BMUCTRLW'b100_01_111_1_0_0_1_1_0_0_0_0;  // xnor
      17'b0010011_0110101_101: if (`XLEN == 64) 
                                 BMUControlsD = `BMUCTRLW'b000_10_010_1_1_0_1_0_0_0_0_0;  // rev8 (rv64)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0010011_0110100_101: if (`XLEN == 32) 
                                 BMUControlsD = `BMUCTRLW'b000_10_010_1_1_0_1_0_0_0_0_0;  // rev8 (rv32)
                               else 
                                 BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // illegal instruction
      17'b0010011_0010100_101:   BMUControlsD = `BMUCTRLW'b000_10_010_1_1_0_1_0_0_0_0_0;  // orc.b
      17'b0110011_0000101_110:   BMUControlsD = `BMUCTRLW'b000_10_100_1_0_0_1_0_0_0_0_0;  // max
      17'b0110011_0000101_111:   BMUControlsD = `BMUCTRLW'b000_10_100_1_0_0_1_0_0_0_0_0;  // maxu
      17'b0110011_0000101_100:   BMUControlsD = `BMUCTRLW'b000_10_011_1_0_0_1_0_0_0_0_0;  // min
      17'b0110011_0000101_101:   BMUControlsD = `BMUCTRLW'b000_10_011_1_0_0_1_0_0_0_0_0;  // minu
      default:                   BMUControlsD = {Funct3D, {13'b0}, {1'b1}};             // not B instruction or shift
    endcase

  // Unpack Control Signals
  assign {ALUSelectD,BSelectD,ZBBSelectD, BRegWriteD,BALUSrcBD, BW64D, BALUOpD, BSubArithD, RotateD, MaskD, PreShiftD, IllegalBitmanipInstrD} = BMUControlsD;
  
  // Pack BALUControl Signals
  assign BALUControlD = {RotateD, MaskD, PreShiftD};

  // Comparator should perform signed comparison when min/max instruction. We have overlap in funct3 with some branch instructions so we use opcode to differentiate betwen min/max and branches
  assign BComparatorSignedD = (Funct3D[2]^Funct3D[0]) & ~OpD[6];

  // BMU Execute stage pipieline control register
  flopenrc#(13) controlregBMU(clk, reset, FlushE, ~StallE, {ALUSelectD, BSelectD, ZBBSelectD, BRegWriteD, BComparatorSignedD,  BALUControlD}, {ALUSelectE, BSelectE, ZBBSelectE, BRegWriteE, BComparatorSignedE, BALUControlE});
endmodule
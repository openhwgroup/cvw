///////////////////////////////////////////
// bmuctrl.sv
//
// Written: Kevin Kim <kekim@hmc.edu>
// Created: 16 February 2023
// Modified: 6 March 2023
//
// Purpose: Top level bit manipulation instruction decoder
// 
// Documentation: RISC-V System on Chip Design Chapter 15
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

module bmuctrl import cvw::*;  #(parameter cvw_t P) (
  input  logic        clk, reset,
  // Decode stage control signals
  input  logic        StallD, FlushD,          // Stall, flush Decode stage
  input  logic [31:0] InstrD,                  // Instruction in Decode stage
  input  logic        ALUOpD,                  // Regular ALU Operation
  output logic [1:0]  BSelectD,                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding in Decode stage
  output logic [2:0]  ZBBSelectD,              // ZBB mux select signal in Decode stage NOTE: do we need this in decode?
  output logic        BRegWriteD,              // Indicates if it is a R type B instruction in Decode Stage
  output logic        BALUSrcBD,               // Indicates if it is an I/IW (non auipc) type B instruction in Decode Stage
  output logic        BW64D,                   // Indiciates if it is a W type B instruction in Decode Stage
  output logic        BSubArithD,              // TRUE if ext, clr, andn, orn, xnor instruction in Decode Stage
  output logic        IllegalBitmanipInstrD,   // Indicates if it is unrecognized B instruction in Decode Stage
  // Execute stage control signals             
  input  logic        StallE, FlushE,          // Stall, flush Execute stage
  output logic [2:0]  ALUSelectD,              // ALU select
  output logic [1:0]  BSelectE,                // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding
  output logic [2:0]  ZBBSelectE,              // ZBB mux select signal
  output logic        BRegWriteE,              // Indicates if it is a R type B instruction in Execute
  output logic [2:0]  BALUControlE,            // ALU Control signals for B instructions in Execute Stage
  output logic        BMUActiveE               // Bit manipulation instruction being executed
);

  logic [6:0] OpD;                             // Opcode in Decode stage
  logic [2:0] Funct3D;                         // Funct3 field in Decode stage
  logic [6:0] Funct7D;                         // Funct7 field in Decode stage
  logic [4:0] Rs2D;                            // Rs2 source register in Decode stage
  logic       RotateD;                         // Indicates if rotate instruction in Decode Stage
  logic       MaskD;                           // Indicates if zbs instruction in Decode Stage
  logic       PreShiftD;                       // Indicates if sh1add, sh2add, sh3add instruction in Decode Stage
  logic [2:0] BALUControlD;                    // ALU Control signals for B instructions
  logic [2:0] BALUSelectD;                     // ALU Mux select signal in Decode Stage for BMU operations
  logic       BALUOpD;                         // Indicates if it is an ALU B instruction in Decode Stage

  `define BMUCTRLW 17

  logic [`BMUCTRLW-1:0] BMUControlsD;          // Main B Instructions Decoder control signals

  // Extract fields
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7D = InstrD[31:25];
  assign Rs2D = InstrD[24:20];

  // Main Instruction Decoder
  always_comb begin
    // BALUSelect_BSelect_ZBBSelect_BRegWrite_BALUSrcB_BW64_BALUOp_BSubArithD_RotateD_MaskD_PreShiftD_IllegalBitmanipInstrD
    BMUControlsD = `BMUCTRLW'b000_00_000_0_0_0_0_0_0_0_0_1;  // default: Illegal bmu instruction;
    if (P.ZBA_SUPPORTED) begin
      casez({OpD, Funct7D, Funct3D})
        17'b0110011_0010000_010: BMUControlsD = `BMUCTRLW'b000_01_000_1_0_0_1_0_0_0_1_0;  // sh1add
        17'b0110011_0010000_100: BMUControlsD = `BMUCTRLW'b000_01_000_1_0_0_1_0_0_0_1_0;  // sh2add
        17'b0110011_0010000_110: BMUControlsD = `BMUCTRLW'b000_01_000_1_0_0_1_0_0_0_1_0;  // sh3add
      endcase
      if (P.XLEN==64)
        casez({OpD, Funct7D, Funct3D})
          17'b0111011_0010000_010: BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_1_0;  // sh1add.uw
          17'b0111011_0010000_100: BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_1_0;  // sh2add.uw
          17'b0111011_0010000_110: BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_1_0;  // sh3add.uw
          17'b0111011_0000100_000: BMUControlsD = `BMUCTRLW'b000_01_000_1_0_1_1_0_0_0_0_0;  // add.uw
          17'b0011011_000010?_001: BMUControlsD = `BMUCTRLW'b001_01_000_1_1_1_1_0_0_0_0_0;  // slli.uw
        endcase
    end
    if (P.ZBB_SUPPORTED) begin
      casez({OpD, Funct7D, Funct3D})
        17'b0110011_0110000_001: BMUControlsD = `BMUCTRLW'b001_01_111_1_0_0_1_0_1_0_0_0;  // rol
        17'b0110011_0110000_101: BMUControlsD = `BMUCTRLW'b001_01_111_1_0_0_1_0_1_0_0_0;  // ror
        17'b0010011_0110000_001: if ((Rs2D[4:1] == 4'b0010))
                                  BMUControlsD = `BMUCTRLW'b000_10_001_1_1_0_1_0_0_0_0_0;  // sign extend instruction
                                else if ((Rs2D[4:2]==3'b000) & ~(Rs2D[1] & Rs2D[0]))
                                  BMUControlsD = `BMUCTRLW'b000_10_000_1_1_0_1_0_0_0_0_0;  // count instruction
//        // coverage off: This case can't occur in RV64
//        17'b0110011_0000100_100: if (P.XLEN == 32)
//                                  BMUControlsD = `BMUCTRLW'b000_10_001_1_1_0_1_0_0_0_0_0;  // zexth (rv32)
//        // coverage on
        17'b0110011_0100000_111: BMUControlsD = `BMUCTRLW'b111_01_111_1_0_0_1_1_0_0_0_0;  // andn
        17'b0110011_0100000_110: BMUControlsD = `BMUCTRLW'b110_01_111_1_0_0_1_1_0_0_0_0;  // orn
        17'b0110011_0100000_100: BMUControlsD = `BMUCTRLW'b100_01_111_1_0_0_1_1_0_0_0_0;  // xnor
        17'b0010011_011010?_101: if ((P.XLEN == 32 ^ Funct7D[0]) & (Rs2D == 5'b11000))
                                  BMUControlsD = `BMUCTRLW'b000_10_010_1_1_0_1_0_0_0_0_0;  // rev8
        17'b0010011_0010100_101: if (Rs2D[4:0] == 5'b00111)
                                  BMUControlsD = `BMUCTRLW'b000_10_010_1_1_0_1_0_0_0_0_0;  // orc.b
        17'b0110011_0000101_110: BMUControlsD = `BMUCTRLW'b000_10_111_1_0_0_1_1_0_0_0_0;  // max
        17'b0110011_0000101_111: BMUControlsD = `BMUCTRLW'b000_10_111_1_0_0_1_1_0_0_0_0;  // maxu
        17'b0110011_0000101_100: BMUControlsD = `BMUCTRLW'b000_10_011_1_0_0_1_1_0_0_0_0;  // min
        17'b0110011_0000101_101: BMUControlsD = `BMUCTRLW'b000_10_011_1_0_0_1_1_0_0_0_0;  // minu
      endcase
      if (P.XLEN==32)
        casez({OpD, Funct7D, Funct3D})
          17'b0110011_0000100_100: BMUControlsD = `BMUCTRLW'b000_10_001_1_1_0_1_0_0_0_0_0;  // zexth (rv32)
          17'b0010011_0110000_101: BMUControlsD = `BMUCTRLW'b001_00_111_1_1_0_1_0_1_0_0_0;  // rori (rv32)                          
        endcase
      else if (P.XLEN==64)
        casez({OpD, Funct7D, Funct3D})
          17'b0111011_0000100_100: BMUControlsD = `BMUCTRLW'b000_10_001_1_0_0_1_0_0_0_0_0;  // zexth (rv64)
          17'b0111011_0110000_001: BMUControlsD = `BMUCTRLW'b001_00_111_1_0_1_1_0_1_0_0_0;  // rolw
          17'b0111011_0110000_101: BMUControlsD = `BMUCTRLW'b001_00_111_1_0_1_1_0_1_0_0_0;  // rorw
          17'b0010011_011000?_101: BMUControlsD = `BMUCTRLW'b001_00_111_1_1_0_1_0_1_0_0_0;  // rori (rv64)
          17'b0011011_0110000_101: BMUControlsD = `BMUCTRLW'b001_00_111_1_1_1_1_0_1_0_0_0;  // roriw 
          17'b0011011_0110000_001: if ((Rs2D[4:2]==3'b000) & ~(Rs2D[1] & Rs2D[0]))
                                    BMUControlsD = `BMUCTRLW'b000_10_000_1_1_1_1_0_0_0_0_0;  // count word instruction
        endcase
    end
    if (P.ZBC_SUPPORTED)
      casez({OpD, Funct7D, Funct3D})
        17'b0110011_0000101_0??: BMUControlsD = `BMUCTRLW'b000_11_000_1_0_0_1_0_0_0_0_0;  // ZBC instruction
      endcase
    if (P.ZBS_SUPPORTED) begin // ZBS
      casez({OpD, Funct7D, Funct3D})
        17'b0110011_0100100_001: BMUControlsD = `BMUCTRLW'b111_01_000_1_0_0_1_1_0_1_0_0;  // bclr
        17'b0110011_0100100_101: BMUControlsD = `BMUCTRLW'b101_01_000_1_0_0_1_1_0_1_0_0;  // bext
        17'b0110011_0110100_001: BMUControlsD = `BMUCTRLW'b100_01_000_1_0_0_1_0_0_1_0_0;  // binv
        17'b0110011_0010100_001: BMUControlsD = `BMUCTRLW'b110_01_000_1_0_0_1_0_0_1_0_0;  // bset
      endcase
      if (P.XLEN==32) // ZBS 64-bit
        casez({OpD, Funct7D, Funct3D})
          17'b0010011_0100100_001: BMUControlsD = `BMUCTRLW'b111_01_000_1_1_0_1_1_0_1_0_0;  // bclri
          17'b0010011_0100100_101: BMUControlsD = `BMUCTRLW'b101_01_000_1_1_0_1_1_0_1_0_0;  // bexti
          17'b0010011_0110100_001: BMUControlsD = `BMUCTRLW'b100_01_000_1_1_0_1_0_0_1_0_0;  // binvi
          17'b0010011_0010100_001: BMUControlsD = `BMUCTRLW'b110_01_000_1_1_0_1_0_0_1_0_0;  // bseti
        endcase
      else if (P.XLEN==64) // ZBS 64-bit
        casez({OpD, Funct7D, Funct3D})
          17'b0010011_010010?_001: BMUControlsD = `BMUCTRLW'b111_01_000_1_1_0_1_1_0_1_0_0;  // bclri (rv64)
          17'b0010011_010010?_101: BMUControlsD = `BMUCTRLW'b101_01_000_1_1_0_1_1_0_1_0_0;  // bexti (rv64)
          17'b0010011_011010?_001: BMUControlsD = `BMUCTRLW'b100_01_000_1_1_0_1_0_0_1_0_0;  // binvi (rv64)
          17'b0010011_001010?_001: BMUControlsD = `BMUCTRLW'b110_01_000_1_1_0_1_0_0_1_0_0;  // bseti (rv64)
        endcase
    end
    if (P.ZBB_SUPPORTED | P.ZBS_SUPPORTED) // rv32i/64i shift instructions need BMU ALUSelect when BMU shifter is used
      casez({OpD, Funct7D, Funct3D})
        17'b0110011_0?0000?_?01: BMUControlsD = `BMUCTRLW'b001_00_000_1_0_0_1_0_0_0_0_0;  // sra, srl, sll
        17'b0010011_0?0000?_?01: BMUControlsD = `BMUCTRLW'b001_00_000_1_1_0_1_0_0_0_0_0;  // srai, srli, slli
        17'b0111011_0?0000?_?01: BMUControlsD = `BMUCTRLW'b001_00_000_1_0_1_1_0_0_0_0_0;  // sraw, srlw, sllw
        17'b0011011_0?0000?_?01: BMUControlsD = `BMUCTRLW'b001_00_000_1_1_1_1_0_0_0_0_0;  // sraiw, srliw, slliw
      endcase
  end

  // Unpack Control Signals
  assign {BALUSelectD, BSelectD, ZBBSelectD, BRegWriteD,BALUSrcBD, BW64D, BALUOpD, BSubArithD, RotateD, MaskD, PreShiftD, IllegalBitmanipInstrD} = BMUControlsD;
  
  // Pack BALUControl Signals
  assign BALUControlD = {RotateD, MaskD, PreShiftD};

  // Choose ALUSelect brom BMU for BMU operations, Funct3 for IEU operations, or 0 for addition
  assign ALUSelectD = BALUOpD ? BALUSelectD : (ALUOpD ? Funct3D : 3'b000);

  // BMU Execute stage pipieline control register
  flopenrc #(10) controlregBMU(clk, reset, FlushE, ~StallE, {BSelectD, ZBBSelectD, BRegWriteD, BALUControlD, ~IllegalBitmanipInstrD}, {BSelectE, ZBBSelectE, BRegWriteE, BALUControlE, BMUActiveE});
endmodule

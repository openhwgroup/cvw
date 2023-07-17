///////////////////////////////////////////
// bitmanipalu.sv
//
// Written: Kevin Kim <kekim@hmc.edu>
// Created: 23 March 2023
// Modified: 23 March 2023
//
// Purpose: RISC-V Arithmetic/Logic Unit Bit-Manipulation Extension
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

module bitmanipalu import cvw::*; #(parameter cvw_t P, 
                     parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,                    // Operands
  input  logic             W64,                     // W64-type instruction
  input  logic [1:0]       BSelect,                 // Binary encoding of if it's a ZBA_ZBB_ZBC_ZBS instruction
  input  logic [2:0]       ZBBSelect,               // ZBB mux select signal
  input  logic [2:0]       Funct3,                  // Funct3 field of opcode indicates operation to perform
  input  logic             LT,                      // less than flag
  input  logic             LTU,                     // less than unsigned flag
  input  logic [2:0]       BALUControl,             // ALU Control signals for B instructions in Execute Stage
  input  logic             BMUActiveE,              // Bit manipulation instruction being executed
  input  logic [WIDTH-1:0] PreALUResult, FullResult,// PreALUResult, FullResult signals
  output logic [WIDTH-1:0] CondMaskB,               // B is conditionally masked for ZBS instructions
  output logic [WIDTH-1:0] CondShiftA,              // A is conditionally shifted for ShAdd instructions
  output logic [WIDTH-1:0] ALUResult);              // Result

  logic [WIDTH-1:0] ZBBResult, ZBCResult;           // ZBB, ZBC Result
  logic [WIDTH-1:0] MaskB;                          // BitMask of B
  logic [WIDTH-1:0] RevA;                           // Bit-reversed A
  logic             Rotate;                         // Indicates if it is Rotate instruction
  logic             Mask;                           // Indicates if it is ZBS instruction
  logic             PreShift;                       // Inidicates if it is sh1add, sh2add, sh3add instruction
  logic [1:0]       PreShiftAmt;                    // Amount to Pre-Shift A 
  logic [WIDTH-1:0] CondZextA;                      // A Conditional Extend Intermediary Signal
  logic [WIDTH-1:0] ABMU, BBMU;                     // Gated data inputs to reduce BMU activity

  // gate data inputs to BMU to only operate when BMU is active
  assign ABMU = A & {WIDTH{BMUActiveE}};
  assign BBMU = B & {WIDTH{BMUActiveE}};

  // Extract control signals from bitmanip ALUControl.
  assign {Mask, PreShift} = BALUControl[1:0];

  // Mask Generation Mux
  if (P.ZBS_SUPPORTED) begin: zbsdec
    decoder #($clog2(WIDTH)) maskgen(BBMU[$clog2(WIDTH)-1:0], MaskB);
    mux2 #(WIDTH) maskmux(B, MaskB, Mask, CondMaskB);
  end else assign CondMaskB = B;
 
  // 0-3 bit Pre-Shift Mux
  if (P.ZBA_SUPPORTED) begin: zbapreshift
    if (WIDTH == 64) begin
      mux2 #(64) zextmux(A, {{32{1'b0}}, A[31:0]}, W64, CondZextA); 
    end else assign CondZextA = A;
    assign PreShiftAmt = Funct3[2:1] & {2{PreShift}};
    assign CondShiftA = CondZextA << (PreShiftAmt);
  end else begin
    assign PreShiftAmt = 2'b0;
    assign CondShiftA = A;
  end

  // Bit reverse needed for some ZBB, ZBC instructions
  if (P.ZBC_SUPPORTED | P.ZBB_SUPPORTED) begin: bitreverse
    bitreverse #(WIDTH) brA(.A(ABMU), .RevA);
  end

  // ZBC Unit
  if (P.ZBC_SUPPORTED) begin: zbc
    zbc #(WIDTH) ZBC(.A(ABMU), .RevA, .B(BBMU), .Funct3, .ZBCResult);
  end else assign ZBCResult = 0;

  // ZBB Unit
  if (P.ZBB_SUPPORTED) begin: zbb
    zbb #(WIDTH) ZBB(.A(ABMU), .RevA, .B(BBMU), .W64, .LT, .LTU, .BUnsigned(Funct3[0]), .ZBBSelect, .ZBBResult);
  end else assign ZBBResult = 0;

  // Result Select Mux
  always_comb
    case (BSelect)
      // 00: ALU, 01: ZBA/ZBS, 10: ZBB, 11: ZBC
      2'b00: ALUResult = PreALUResult; 
      2'b01: ALUResult = FullResult;         // NOTE: We don't use ALUResult because ZBA/ZBS instructions don't sign extend the MSB of the right-hand word.
      2'b10: ALUResult = ZBBResult; 
      2'b11: ALUResult = ZBCResult;
    endcase
endmodule

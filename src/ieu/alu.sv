///////////////////////////////////////////
// alu.sv
//
// Written: David_Harris@hmc.edu, Sarah.Harris@unlv.edu, kekim@hmc.edu
// Created: 9 January 2021
// Modified: 3 March 2023
//
// Purpose: RISC-V Arithmetic/Logic Unit
//
// Documentation: RISC-V System on Chip Design Chapter 4 (Figure 4.4)
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

module alu #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,        // Operands
  input  logic [2:0]       ALUControl,  // With Funct3, indicates operation to perform
  input  logic [2:0]       ALUSelect,   // ALU mux select signal
  input  logic [1:0]       BSelect,     // One-Hot encoding of if it's a ZBA_ZBB_ZBC_ZBS instruction
  input  logic [2:0]       ZBBSelect,   // ZBB mux select signal
  input  logic [2:0]       Funct3,      // With ALUControl, indicates operation to perform NOTE: Change signal name to ALUSelect
  input  logic [1:0]       CompFlags,   // Comparator flags
  input  logic [2:0]       BALUControl, // ALU Control signals for B instructions in Execute Stage
  output logic [WIDTH-1:0] Result,      // ALU result
  output logic [WIDTH-1:0] Sum);        // Sum of operands

  // CondInvB = ~B when subtracting, B otherwise. Shift = shift result. SLT/U = result of a slt/u instruction.
  // FullResult = ALU result before adjusting for a RV64 w-suffix instruction.
  logic [WIDTH-1:0] CondMaskInvB, Shift, FullResult,ALUResult;                   // Intermediate Signals 
  logic [WIDTH-1:0] ZBCResult, ZBBResult;                                                   // Result of ZBB, ZBC
  logic [WIDTH-1:0] MaskB;                                                                  // BitMask of B
  logic [WIDTH-1:0] CondMaskB;                                                              // Result of B mask select mux
  logic [WIDTH-1:0] CondShiftA;                                                             // Result of A shifted select mux
  logic [WIDTH-1:0] CondExtA;                                                               // Result of Zero Extend A select mux
  logic [WIDTH-1:0] RevA;                                                                   // Bit-reversed A
  logic             Carry, Neg;                                                             // Flags: carry out, negative
  logic             LT, LTU;                                                                // Less than, Less than unsigned
  logic             W64;                                                                    // RV64 W-type instruction
  logic             SubArith;                                                               // Performing subtraction or arithmetic right shift
  logic             ALUOp;                                                                  // 0 for address generation addition or 1 for regular ALU ops
  logic             Asign, Bsign;                                                           // Sign bits of A, B
  logic             shSignA;
  logic [WIDTH-1:0] rotA;                                                                   // XLEN bit input source to shifter
  logic [1:0]       shASelect;                                                              // select signal for shifter source generation mux 
  logic             Rotate;                                                                 // Indicates if it is Rotate instruction
  logic             Mask;                                                                   // Indicates if it is ZBS instruction
  logic             PreShift;                                                               // Inidicates if it is sh1add, sh2add, sh3add instruction
  logic [1:0]       PreShiftAmt;                                                            // Amount to Pre-Shift A 

  // Extract control signals from ALUControl.
  assign {W64, SubArith, ALUOp} = ALUControl;

  // Extract control signals from bitmanip ALUControl.
  assign {Rotate, Mask, PreShift} = BALUControl;

  // Pack control signals into shifter select
  assign shASelect = {W64,SubArith};

  assign PreShiftAmt = Funct3[2:1] & {2{PreShift}};

  if (`ZBS_SUPPORTED) begin: zbsdec
    decoder #($clog2(WIDTH)) maskgen (B[$clog2(WIDTH)-1:0], MaskB);
    assign CondMaskB = (Mask) ? MaskB : B;
  end else assign CondMaskB = B;

  if (WIDTH == 64) begin
    mux3 #(1) signmux(A[63], A[31], 1'b0, {~SubArith, W64}, shSignA);
    mux3 #(64) extendmux({{32{1'b0}}, A[31:0]},{{32{A[31]}}, A[31:0]}, A,{~W64, SubArith}, CondExtA);
  end else begin 
    mux2 #(1) signmux(1'b0, A[31], SubArith, shSignA);
    assign CondExtA = A;
  end

  // shifter rotate source select mux
  if (`ZBB_SUPPORTED) begin
    if (WIDTH == 64) assign rotA = (W64) ? {A[31:0], A[31:0]} : A;
    else assign rotA = A; 
  end else assign rotA = A;
    
  if (`ZBA_SUPPORTED) begin: zbamuxes
    // Pre-Shift
    assign CondShiftA = CondExtA << (PreShiftAmt);
  end else assign CondShiftA = A;

  // Addition
  assign CondMaskInvB = SubArith ? ~CondMaskB : CondMaskB;
  assign {Carry, Sum} = CondShiftA + CondMaskInvB + {{(WIDTH-1){1'b0}}, SubArith};
  
  // Shifts (configurable for rotation)
  shifter sh(.shA(CondExtA), .Sign(shSignA), .rotA(rotA), .Amt(B[`LOG_XLEN-1:0]), .Right(Funct3[2]), .W64(W64), .Y(Shift), .Rotate(Rotate));

  // Condition code flags are based on subtraction output Sum = A-B.
  // Overflow occurs when the numbers being subtracted have the opposite sign 
  // and the result has the opposite sign of A.
  // LT is simplified from Overflow = Asign & Bsign & Asign & Neg; LT = Neg ^ Overflow
  assign Neg  = Sum[WIDTH-1];
  assign Asign = A[WIDTH-1];
  assign Bsign = B[WIDTH-1];
  assign LT = Asign & ~Bsign | Asign & Neg | ~Bsign & Neg; 
  assign LTU = ~Carry;
 
  // Select appropriate ALU Result
  if (`ZBS_SUPPORTED | `ZBB_SUPPORTED) begin
    always_comb
      if (~ALUOp) FullResult = Sum;                         // Always add for ALUOp = 0 (address generation)
      else casez (ALUSelect)                                // Otherwise check Funct3 NOTE: change signal name to ALUSelect
        3'b000: FullResult = Sum;                           // add or sub
        3'b001: FullResult = Shift;                         // sll, sra, or srl
        3'b010: FullResult = {{(WIDTH-1){1'b0}}, LT};       // slt
        3'b011: FullResult = {{(WIDTH-1){1'b0}}, LTU};      // sltu
        3'b100: FullResult = A ^ CondMaskInvB;              // xor, xnor, binv
        3'b110: FullResult = A | CondMaskInvB;              // or, orn, bset
        3'b111: FullResult = A & CondMaskInvB;              // and, bclr
        3'b101: FullResult = {{(WIDTH-1){1'b0}},{|(A & CondMaskB)}};// bext
      endcase
  end
  else begin
    always_comb
      if (~ALUOp) FullResult = Sum;     // Always add for ALUOp = 0 (address generation)
      else casez (ALUSelect)            // Otherwise check Funct3 NOTE: change signal name to ALUSelect
        3'b000: FullResult = Sum;       // add or sub
        3'b?01: FullResult = Shift;     // sll, sra, or srl
        3'b010: FullResult = {{(WIDTH-1){1'b0}}, LT};        // slt
        3'b011: FullResult = {{(WIDTH-1){1'b0}}, LTU};       // sltu
        3'b100: FullResult = A ^ B;     // xor
        3'b110: FullResult = A | B;     // or 
        3'b111: FullResult = A & B;     // and
      endcase
  end

  if (`ZBC_SUPPORTED | `ZBB_SUPPORTED) begin: bitreverse
    bitreverse #(WIDTH) brA(.a(A), .b(RevA));
  end

  if (`ZBC_SUPPORTED) begin: zbc
    zbc #(WIDTH) ZBC(.A(A), .RevA(RevA), .B(B), .Funct3(Funct3), .ZBCResult(ZBCResult));
  end else assign ZBCResult = 0;

  if (`ZBB_SUPPORTED) begin: zbb
    zbb #(WIDTH) ZBB(.A(A), .RevA(RevA), .B(B), .ALUResult(ALUResult), .W64(W64), .lt(CompFlags[0]), .ZBBSelect(ZBBSelect), .ZBBResult(ZBBResult));
  end else assign ZBBResult = 0;

  // Support RV64I W-type addw/subw/addiw/shifts that discard upper 32 bits and sign-extend 32-bit result to 64 bits
  if (WIDTH == 64)  assign ALUResult = W64 ? {{32{FullResult[31]}}, FullResult[31:0]} : FullResult;
  else              assign ALUResult = FullResult;

  // Final Result B instruction select mux
  if (`ZBC_SUPPORTED | `ZBS_SUPPORTED | `ZBA_SUPPORTED | `ZBB_SUPPORTED) begin : zbdecoder
    always_comb
      case (BSelect)
        // 00: ALU, 01: ZBA/ZBS, 10: ZBB, 11: ZBC
        2'b00: Result = ALUResult; 
        2'b01: Result = FullResult;         // NOTE: We don't use ALUResult because ZBA/ZBS instructions don't sign extend the MSB of the right-hand word.
        2'b10: Result = ZBBResult; 
        2'b11: Result = ZBCResult;
      endcase
  end else assign Result = ALUResult;
endmodule
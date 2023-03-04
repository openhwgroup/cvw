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
  input  logic [WIDTH-1:0] A, B,       // Operands
  input  logic [2:0]       ALUControl, // With Funct3, indicates operation to perform
  input  logic [2:0]       ALUSelect,  // ALU mux select signal
  input  logic [3:0]       BSelect,    // One-Hot encoding of if it's a ZBA_ZBB_ZBC_ZBS instruction
  input  logic [2:0]       ZBBSelect,  // ZBB mux select signal
  input  logic [2:0]       Funct3,     // With ALUControl, indicates operation to perform NOTE: Change signal name to ALUSelect
  input  logic [1:0]       CompFlags,  // Comparator flags
  input  logic             Rotate,     // Perform Rotate Operation
  output logic [WIDTH-1:0] ALUResult,     // ALU result
  output logic [WIDTH-1:0] Sum);       // Sum of operands

  // CondInvB = ~B when subtracting, B otherwise. Shift = shift result. SLT/U = result of a slt/u instruction.
  // FullResult = ALU result before adjusting for a RV64 w-suffix instruction.
  logic [WIDTH-1:0] CondInvB, Shift, SLT, SLTU, FullResult,CondExtFullResult, ZBCResult, ZBBResult; // Intermediate results
  logic [WIDTH-1:0] MaskB;                                                                  // BitMask of B
  logic [WIDTH-1:0] CondMaskB;                                                              // Result of B mask select mux
  logic [WIDTH-1:0] CondShiftA;                                                             // Result of A shifted select mux
  logic [WIDTH-1:0] CondZextA;                                                              // Result of Zero Extend A select mux
  logic             Carry, Neg;                                                             // Flags: carry out, negative
  logic             LT, LTU;                                                                // Less than, Less than unsigned
  logic             W64;                                                                    // RV64 W-type instruction
  logic             SubArith;                                                               // Performing subtraction or arithmetic right shift
  logic             ALUOp;                                                                  // 0 for address generation addition or 1 for regular ALU ops
  logic             Asign, Bsign;                                                           // Sign bits of A, B
  logic [WIDTH:0]   shA;                                                                    // XLEN+1 bit input source to shifter
  logic [WIDTH-1:0] rotA;                                                                   // XLEN bit input source to shifter
  logic [1:0]       shASelect;                                                              // select signal for shifter source generation mux 


  // Extract control signals from ALUControl.
  assign {W64, SubArith, ALUOp} = ALUControl;

  // Pack control signals into shifter select
  assign shASelect = {W64,SubArith};

  if (`ZBS_SUPPORTED) begin: zbsdec
    decoder #($clog2(WIDTH)) maskgen (B[$clog2(WIDTH)-1:0], MaskB);
    assign CondMaskB = (BSelect[0]) ? MaskB : B;
  end else assign CondMaskB = B;

  // Sign/Zero extend mux
  if (WIDTH == 64) begin // rv64 must handle word s/z extensions
    always_comb 
      case (shASelect)
        2'b00: shA = {{1'b0}, A};
        2'b01: shA = {A[63], A};
        2'b10: shA = {{33'b0}, A[31:0]};
        2'b11: shA = {{33{A[31]}}, A[31:0]};
      endcase
  end else assign shA = (SubArith) ? {A[31], A} : {{1'b0},A}; // rv32 does need to handle s/z extensions

  // shifter rotate source select mux
  if (`ZBB_SUPPORTED) begin
    if (WIDTH == 64) assign rotA = (W64) ? {A[31:0], A[31:0]} : A;
    else assign rotA = A; 
  end else assign rotA = A;
    
  if (`ZBA_SUPPORTED) begin: zbamuxes
    // Pre-Shift Mux
    always_comb
      case (Funct3[2:1] & {2{BSelect[3]}})
        2'b00: CondShiftA = shA[WIDTH-1:0];
        2'b01: CondShiftA = {shA[WIDTH-2:0],{1'b0}};   // sh1add
        2'b10: CondShiftA = {shA[WIDTH-3:0],{2'b00}};  // sh2add
        2'b11: CondShiftA = {shA[WIDTH-4:0],{3'b000}}; // sh3add
      endcase
  end else assign CondShiftA = A;

  // Addition
  assign CondInvB = SubArith ? ~CondMaskB : CondMaskB;
  assign {Carry, Sum} = CondShiftA + CondInvB + {{(WIDTH-1){1'b0}}, SubArith};
  
  // Shifts (configurable for rotation)
  shifter sh(.shA(shA), .rotA(rotA), .Amt(B[`LOG_XLEN-1:0]), .Right(Funct3[2]), .W64(W64), .Y(Shift), .Rotate(Rotate));

  // Condition code flags are based on subtraction output Sum = A-B.
  // Overflow occurs when the numbers being subtracted have the opposite sign 
  // and the result has the opposite sign of A.
  // LT is simplified from Overflow = Asign & Bsign & Asign & Neg; LT = Neg ^ Overflow
  assign Neg  = Sum[WIDTH-1];
  assign Asign = A[WIDTH-1];
  assign Bsign = B[WIDTH-1];
  assign LT = Asign & ~Bsign | Asign & Neg | ~Bsign & Neg; 
  assign LTU = ~Carry;
 
  // SLT
  assign SLT = {{(WIDTH-1){1'b0}}, LT};
  assign SLTU = {{(WIDTH-1){1'b0}}, LTU};
 
  // Select appropriate ALU Result
  if (`ZBS_SUPPORTED | `ZBB_SUPPORTED) begin
    always_comb
      if (~ALUOp) FullResult = Sum;                         // Always add for ALUOp = 0 (address generation)
      else casez (ALUSelect)                                // Otherwise check Funct3 NOTE: change signal name to ALUSelect
        3'b000: FullResult = Sum;                           // add or sub
        3'b001: FullResult = Shift;                         // sll, sra, or srl
        3'b010: FullResult = SLT;                           // slt
        3'b011: FullResult = SLTU;                          // sltu
        3'b100: FullResult = A ^ CondInvB;                  // xor, xnor, binv
        3'b110: FullResult = A | CondInvB;                  // or, orn, bset
        3'b111: FullResult = A & CondInvB;                  // and, bclr
        3'b101: FullResult = {{(WIDTH-1){1'b0}},{|(A & CondMaskB)}};// bext
      endcase
  end
  else begin
    always_comb
      if (~ALUOp) FullResult = Sum;     // Always add for ALUOp = 0 (address generation)
      else casez (ALUSelect)            // Otherwise check Funct3 NOTE: change signal name to ALUSelect
        3'b000: FullResult = Sum;       // add or sub
        3'b?01: FullResult = Shift;     // sll, sra, or srl
        3'b010: FullResult = SLT;       // slt
        3'b011: FullResult = SLTU;      // sltu
        3'b100: FullResult = A ^ B;     // xor
        3'b110: FullResult = A | B;     // or 
        3'b111: FullResult = A & B;     // and
      endcase
    
  end
  

  // Support RV64I W-type addw/subw/addiw/shifts that discard upper 32 bits and sign-extend 32-bit result to 64 bits
  if (WIDTH == 64)  assign CondExtFullResult = W64 ? {{32{FullResult[31]}}, FullResult[31:0]} : FullResult;
  else              assign CondExtFullResult = FullResult;

  //NOTE: This looks good and can be merged.
  if (`ZBC_SUPPORTED) begin: zbc
    zbc #(WIDTH) ZBC(.A(A), .B(B), .Funct3(Funct3), .ZBCResult(ZBCResult));
  end else assign ZBCResult = 0;

  if (`ZBB_SUPPORTED) begin: zbb
    zbb #(WIDTH) ZBB(.A(A), .B(B), .ALUResult(CondExtFullResult), .W64(W64), .lt(CompFlags[0]), .ZBBSelect(ZBBSelect), .ZBBResult(ZBBResult));
  end else assign ZBBResult = 0;
  
  // Final Result B instruction select mux
  if (`ZBC_SUPPORTED | `ZBS_SUPPORTED | `ZBA_SUPPORTED | `ZBB_SUPPORTED) begin : zbdecoder
    always_comb
      case (BSelect)
      //ZBA_ZBB_ZBC_ZBS
        4'b0001: ALUResult = FullResult;
        4'b0010: ALUResult = ZBCResult;
        4'b1000: ALUResult = FullResult; // NOTE: We don't use ALUResult because ZBA instructions don't sign extend the MSB of the right-hand word.
        4'b0100: ALUResult = ZBBResult;
        default: ALUResult = CondExtFullResult;
      endcase
  end else assign ALUResult = CondExtFullResult;
endmodule
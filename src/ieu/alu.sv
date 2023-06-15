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

module alu import cvw::*; #(parameter cvw_t P, parameter WIDTH) (
  input  logic [WIDTH-1:0] A, B,        // Operands
  input  logic             W64,         // W64-type instruction
  input  logic             SubArith,    // Subtraction or arithmetic shift
  input  logic [2:0]       ALUSelect,   // ALU mux select signal
  input  logic [1:0]       BSelect,     // Binary encoding of if it's a ZBA_ZBB_ZBC_ZBS instruction
  input  logic [2:0]       ZBBSelect,   // ZBB mux select signal
  input  logic [2:0]       Funct3,      // For BMU decoding
  input  logic [2:0]       BALUControl, // ALU Control signals for B instructions in Execute Stage
  input  logic             BMUActiveE,  // Bit manipulation instruction being executed
  output logic [WIDTH-1:0] ALUResult,   // ALU result
  output logic [WIDTH-1:0] Sum);        // Sum of operands

  // CondInvB = ~B when subtracting, B otherwise. Shift = shift result. SLT/U = result of a slt/u instruction.
  // FullResult = ALU result before adjusting for a RV64 w-suffix instruction.
  logic [WIDTH-1:0] CondMaskInvB, Shift, FullResult, PreALUResult;                // Intermediate Signals 
  logic [WIDTH-1:0] CondMaskB;                                                    // Result of B mask select mux
  logic [WIDTH-1:0] CondShiftA;                                                   // Result of A shifted select mux
  logic [WIDTH-1:0] CondExtA;                                                     // Result of Zero Extend A select mux
  logic             Carry, Neg;                                                   // Flags: carry out, negative
  logic             LT, LTU;                                                      // Less than, Less than unsigned
  logic             Asign, Bsign;                                                 // Sign bits of A, B

  // Addition
  assign CondMaskInvB = SubArith ? ~CondMaskB : CondMaskB;
  assign {Carry, Sum} = CondShiftA + CondMaskInvB + {{(WIDTH-1){1'b0}}, SubArith};
  
  // Shifts (configurable for rotation)
  shifter #(P) sh(.A, .Amt(B[P.LOG_XLEN-1:0]), .Right(Funct3[2]), .W64, .SubArith, .Y(Shift), .Rotate(BALUControl[2]));

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
  always_comb begin
    case (ALUSelect)                                
      3'b000: FullResult = Sum;                           // add or sub (including address generation)
      3'b001: FullResult = Shift;                         // sll, sra, or srl
      3'b010: FullResult = {{(WIDTH-1){1'b0}}, LT};       // slt
      3'b011: FullResult = {{(WIDTH-1){1'b0}}, LTU};      // sltu
      3'b100: FullResult = A ^ CondMaskInvB;              // xor, xnor, binv
      3'b101: FullResult = (P.ZBS_SUPPORTED | P.ZBB_SUPPORTED) ? {{(WIDTH-1){1'b0}},{|(A & CondMaskB)}} : Shift; // bext (or IEU shift when BMU not supported)
      3'b110: FullResult = A | CondMaskInvB;              // or, orn, bset
      3'b111: FullResult = A & CondMaskInvB;              // and, bclr
    endcase
  end

  // Support RV64I W-type addw/subw/addiw/shifts that discard upper 32 bits and sign-extend 32-bit result to 64 bits
  if (WIDTH == 64)  assign PreALUResult = W64 ? {{32{FullResult[31]}}, FullResult[31:0]} : FullResult;
  else              assign PreALUResult = FullResult;

  // Final Result B instruction select mux
  if (P.ZBC_SUPPORTED | P.ZBS_SUPPORTED | P.ZBA_SUPPORTED | P.ZBB_SUPPORTED) begin : bitmanipalu
    bitmanipalu #(P, WIDTH) balu(.A, .B, .W64, .BSelect, .ZBBSelect, .BMUActiveE,
      .Funct3, .LT,.LTU, .BALUControl, .PreALUResult, .FullResult,
      .CondMaskB, .CondShiftA, .ALUResult);
  end else begin
    assign ALUResult = PreALUResult;
    assign CondMaskB = B;
    assign CondShiftA = A;
  end
endmodule

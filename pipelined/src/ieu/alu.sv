///////////////////////////////////////////
// alu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: RISC-V Arithmetic/Logic Unit
// 
// A component of the Wally configurable RISC-V project.
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
  input  logic [WIDTH-1:0] A, B,
  input  logic [2:0]       ALUControl,
  input  logic [2:0]       Funct3,
  output logic [WIDTH-1:0] Result,
  output logic [WIDTH-1:0] Sum);

  logic [WIDTH-1:0] CondInvB, Shift, SLT, SLTU, FullResult;
  logic        Carry, Neg;
  logic        LT, LTU;
  logic        W64, SubArith, ALUOp;
  logic        Asign, Bsign;

  // Extract control signals
  // W64 indicates RV64 W-suffix instructions acting on lower 32-bit word
  // SubArith indicates subtraction or arithmetic right shift
  // ALUOp = 0 for address generation addition or 1 for regular ALU
  assign {W64, SubArith, ALUOp} = ALUControl;

  // addition
  assign CondInvB = SubArith ? ~B : B;
  assign {Carry, Sum} = A + CondInvB + {{(WIDTH-1){1'b0}}, SubArith};
  
  // Shifts
  shifter sh(.A, .Amt(B[`LOG_XLEN-1:0]), .Right(Funct3[2]), .Arith(SubArith), .W64, .Y(Shift));

  // condition code flags based on subtract output Sum = A-B
  // Overflow occurs when the numbers being subtracted have the opposite sign 
  // and the result has the opposite sign of A
  assign Neg  = Sum[WIDTH-1];
  assign Asign = A[WIDTH-1];
  assign Bsign = B[WIDTH-1];
  assign LT = Asign & ~Bsign | Asign & Neg | ~Bsign & Neg; // simplified from Overflow = Asign & Bsign & Asign & Neg; LT = Neg ^ Overflow
  assign LTU = ~Carry;
 
  // SLT
  assign SLT = {{(WIDTH-1){1'b0}}, LT};
  assign SLTU = {{(WIDTH-1){1'b0}}, LTU};
 
  // Select appropriate ALU Result
  always_comb
    if (~ALUOp) FullResult = Sum;     // Always add for ALUOp = 0
    else casez (Funct3)               // Otherwise check Funct3
      3'b000: FullResult = Sum;       // add or sub
      3'b?01: FullResult = Shift;     // sll, sra, or srl
      3'b010: FullResult = SLT;       // slt
      3'b011: FullResult = SLTU;      // sltu
      3'b100: FullResult = A ^ B;     // xor
      3'b110: FullResult = A | B;     // or 
      3'b111: FullResult = A & B;     // and
    endcase

  // support W-type RV64I ADDW/SUBW/ADDIW/Shifts that sign-extend 32-bit result to 64 bits
  if (WIDTH==64)  assign Result = W64 ? {{32{FullResult[31]}}, FullResult[31:0]} : FullResult;
  else            assign Result = FullResult;
endmodule


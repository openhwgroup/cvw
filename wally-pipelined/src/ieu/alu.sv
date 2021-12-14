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
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module alu #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,
  input  logic [2:0]       ALUControl,
  input  logic [2:0]       Funct3,
  output logic [WIDTH-1:0] Result,
  output logic [WIDTH-1:0] Sum);

  logic [WIDTH-1:0] CondInvB, SumTrunc, Shift, SLT, SLTU, bor;
  logic        Right;
  logic        Carry, Neg;
  logic        LT, LTU;
  logic        Overflow;
  logic        W64, SubArith, ALUOp;
  logic [2:0]  ALUFunct;

  // Extract control signals
  // W64 indicates RV64 W-suffix instructions acting on lower 32-bit word
  // SubArith indicates subtraction
  // ALUOp = 0 for address generation addition or 1 for regular ALU
  assign {W64, SubArith, ALUOp} = ALUControl;

  // addition
  assign CondInvB = SubArith ? ~B : B;
  assign {Carry, Sum} = A + CondInvB + {{(WIDTH-1){1'b0}}, SubArith};
  
  // support W-type RV64I ADDW/SUBW/ADDIW that sign-extend 32-bit result to 64 bits
  generate
    if (WIDTH==64)
      assign SumTrunc = W64 ? {{32{Sum[31]}}, Sum[31:0]} : Sum;
    else
      assign SumTrunc = Sum;
  endgenerate
  
  // Shifts
  // assign arith = alucontrol[3]; // sra
  // assign w64 = alucontrol[4];
  assign Right = (Funct3[2:0] == 3'b101); // sra or srl
  shifter sh(A, B[5:0], Right, SubArith, W64, Shift);
  
  // condition code flags based on add/subtract output
  // Overflow occurs when the numbers being added have the same sign 
  // and the result has the opposite sign
  assign Overflow = (A[WIDTH-1] ~^ CondInvB[WIDTH-1]) & (A[WIDTH-1] ^ Sum[WIDTH-1]);
  assign Neg  = Sum[WIDTH-1];
  assign LT = Neg ^ Overflow;
  assign LTU = ~Carry;
 
  // SLT
  assign SLT = {{(WIDTH-1){1'b0}}, LT};
  assign SLTU = {{(WIDTH-1){1'b0}}, LTU};
 
  // Select appropriate ALU Result
  assign ALUFunct = Funct3 & {3{ALUOp}}; // Force ALUFunct to 0 to Add when ALUOp = 0
  always_comb
    case (ALUFunct)
      3'b000: Result = SumTrunc;  // add or sub
      3'b001: Result = Shift;     // sll
      3'b010: Result = SLT;       // slt
      3'b011: Result = SLTU;      // sltu
      3'b100: Result = A ^ B;     // xor
      3'b101: Result = Shift;     // sra or srl
      3'b110: Result = A | B;     // or 
      3'b111: Result = A & B;     // and
    endcase
endmodule


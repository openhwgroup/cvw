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
  input  logic [WIDTH-1:0] a, b,
  input  logic [2:0]       ALUControl,
  input  logic [2:0]       Funct3,
  output logic [WIDTH-1:0] result,
  output logic [WIDTH-1:0] sum);

  logic [WIDTH-1:0] condinvb, sumtrunc, shift, slt, sltu, bor;
  logic        right; //, arith, w64;
  logic        carry, neg;
  logic        lt, ltu;
  logic        overflow;
  logic        W64, SubArith, ALUOp;

  assign {W64, SubArith, ALUOp} = ALUControl;
  // addition
  // *** make sure condinvb is only applied when it should be (sub, slt/sltu)
  assign condinvb = SubArith ? ~b : b;
  assign {carry, sum} = a + condinvb + {{(WIDTH-1){1'b0}}, SubArith};
  
  // support W-type RV64I ADDW/SUBW/ADDIW that sign-extend 32-bit result to 64 bits
  generate
    if (WIDTH==64)
      assign sumtrunc = W64 ? {{32{sum[31]}}, sum[31:0]} : sum;
    else
      assign sumtrunc = sum;
  endgenerate
  
  // shifts
 // assign arith = alucontrol[3]; // sra
 // assign w64 = alucontrol[4];
  assign right = (Funct3[2:0] == 3'b101); // sra or srl
  shifter sh(a, b[5:0], right, SubArith, W64, shift);
  
  // OR optionally passes zero when ALUControl[3] is set, supporting lui
  // *** not needed anymore; simplify control
  //assign bor = alucontrol[3] ? b : a|b;
  
  // condition code flags based on add/subtract output
  assign neg  = sum[WIDTH-1];
  // overflow occurs when the numbers being added have the same sign 
  // and the result has the opposite sign
  assign overflow = (a[WIDTH-1] ~^ condinvb[WIDTH-1]) & (a[WIDTH-1] ^ sum[WIDTH-1]);
  assign lt = neg ^ overflow;
  assign ltu = ~carry;
 
  // slt
  assign slt = {{(WIDTH-1){1'b0}}, lt};
  assign sltu = {{(WIDTH-1){1'b0}}, ltu};
 
  always_comb
    if (~ALUOp) result = sumtrunc;
    else 
      case (Funct3)
        3'b000: result = sumtrunc;       // add or sub
        3'b001: result = shift;     // sll
        3'b010: result = slt;       // slt
        3'b011: result = sltu;      // sltu
        3'b100: result = a ^ b;     // xor
        3'b101: result = shift;     // sra or srl
        3'b110: result = a | b;     // or 
        3'b111: result = a & b;     // and
      endcase
endmodule


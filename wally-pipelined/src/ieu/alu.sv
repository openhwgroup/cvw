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
  input  logic [4:0]       alucontrol,
  output logic [WIDTH-1:0] result,
  output logic [2:0]       flags);

  logic [WIDTH-1:0] condinvb, presum, sum, shift, slt, sltu, bor;
  logic        right, arith, w64;
  logic        carry, zero, neg;
  logic        lt, ltu;
  logic        overflow;

  // addition
  assign condinvb = alucontrol[3] ? ~b : b;
  assign {carry, presum} = a + condinvb + {{(WIDTH-1){1'b0}},alucontrol[3]};
  
  // support W-type RV64I ADDW/SUBW/ADDIW that sign-extend 32-bit result to 64 bits
  generate 
    if (WIDTH==64)
      assign sum = w64 ? {{32{presum[31]}}, presum[31:0]} : presum;
    else
      assign sum = presum;
  endgenerate
  
  // shifts
  assign arith = alucontrol[3]; // sra
  assign w64 = alucontrol[4];
  assign right = (alucontrol[2:0] == 3'b101); // sra or srl
  shifter #(WIDTH) sh(a, b[5:0], right, arith, w64, shift);
  
  // OR optionally passes zero when ALUControl[3] is set, supporting lui
  assign bor = alucontrol[3] ? b : a|b;
  
  // condition code flags based on add/subtract output
  assign zero = (sum == 0);
  assign neg  = sum[WIDTH-1];
  // overflow occurs when the numbers being added have the same sign 
  // and the result has the opposite sign
  assign overflow = (a[WIDTH-1] ~^ condinvb[WIDTH-1]) & (a[WIDTH-1] ^ sum[WIDTH-1]);
  assign lt = neg ^ overflow;
  assign ltu = ~carry;
  assign flags = {zero, lt, ltu};

  // slt
  assign slt = {{(WIDTH-1){1'b0}}, lt};
  assign sltu = {{(WIDTH-1){1'b0}}, ltu};
 
  always_comb
    case (alucontrol[2:0])
      3'b000: result = sum;       // add or sub
      3'b001: result = shift;     // sll
      3'b010: result = slt;       // slt
      3'b011: result = sltu;      // sltu
      3'b100: result = a ^ b;     // xor
      3'b101: result = shift;     // sra or srl
      3'b110: result = bor;       // or / pass through input b for lui
      3'b111: result = a & b;     // and
    endcase

endmodule


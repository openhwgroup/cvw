///////////////////////////////////////////
// pcadder.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Determine next PC = PC+2 or PC+4
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

`include "wally-macros.sv"

module pcadder #(parameter XLEN=32) (
  input  logic [XLEN-1:0] pc, 
  input  logic [31:0]     instr,
  output logic [XLEN-1:0] pcplus);
             
  logic [1:0]  op;
  logic [XLEN-3:0] pcplusupper;
  logic        compressed;
  
  // add 2 or 4 to the PC, based on whether the instruction is 16 bits or 32
  assign op = instr[1:0];
  assign compressed = (op != 2'b11); // is it a 16-bit compressed instruction?
  
  assign pcplusupper = pc[XLEN-1:2] + 1; // add 4 to PC
  
  // choose PC+2 or PC+4
  always_comb
    if (compressed) // add 2
      if (pc[1]) pcplus = {pcplusupper, 2'b00}; 
      else       pcplus = {pc[XLEN-1:2], 2'b10};
    else         pcplus = {pcplusupper, pc[1:0]}; // add 4
endmodule


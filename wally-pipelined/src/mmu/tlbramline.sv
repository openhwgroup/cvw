///////////////////////////////////////////
// tlbramline.sv
//
// Written: David_Harris@hmc.edu 4 July 2021
// Modified:
//
// Purpose: One line of the RAM, with enabled flip-flop and logic for reading into distributed OR
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

module tlbramline #(parameter WIDTH)
  (input  logic             clk, reset,
   input  logic             re, we,
   input  logic [WIDTH-1:0] d,
   output logic [WIDTH-1:0] q,
   output logic             PTE_G);

   logic [WIDTH-1:0] line;

   flopenr #(`XLEN) pteflop(clk, reset, we, d, line);
   assign q = re ? line : 0;
   assign PTE_G = line[5]; // send global bit to CAM as part of ASID matching
endmodule
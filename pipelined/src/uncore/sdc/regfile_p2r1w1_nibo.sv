///////////////////////////////////////////
// regfile_p2r1w1_nibo
//
// Written: Ross Thompson September 18, 2021
// Modified: 2 port register file with 1 read and 1 write
//
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module regfile_p2r1w1_nibo #(parameter integer DEPTH = 10, parameter integer WIDTH = 4)
  (input logic 		clk,
   input logic 		    we1,
   input logic [DEPTH-1:0]  ra1,
   output logic [WIDTH-1:0] rd1,
   output logic [(2**DEPTH)*WIDTH-1:0] Rd1All,   
   input logic [DEPTH-1:0]  wa1,
   input logic [WIDTH-1:0]  wd1);
  
  logic [WIDTH-1:0] 	    regs [2**DEPTH-1:0];
  genvar 		    index;
  
  always_ff @(posedge clk) begin
    if(we1) begin
      regs[wa1] <= wd1;
    end
  end

  assign rd1 = regs[ra1];
  for(index = 0; index < 2**DEPTH; index++)
    assign Rd1All[index*WIDTH+WIDTH-1:index*WIDTH] = regs[index];
  
endmodule

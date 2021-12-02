///////////////////////////////////////////
// piso generic ce
//
// Written: Ross Thompson September 18, 2021
// Modified: 
//
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

module piso_generic_ce #(parameter integer g_BUS_WIDTH)
  (
   input logic 			 clk, 
   input logic 			 i_load, 
   input logic [g_BUS_WIDTH-1:0] i_data, 
   input logic 			 i_en,
   output 			 o_data);

  
  logic [g_BUS_WIDTH-1:0] 	 w_reg_d;
  logic [g_BUS_WIDTH-1:0] 	 r_reg_q;

  flopenr #(g_BUS_WIDTH)
  shiftReg(.clk(clk),
	   .reset(1'b0),
	   .en(1'b1),
	   .d(w_reg_d),
	   .q(r_reg_q));

  assign o_data = i_en ? r_reg_q[g_BUS_WIDTH - 1] : 1'b1;
  assign w_reg_d = i_load ? i_data :
		   i_en ? {r_reg_q[g_BUS_WIDTH - 2 : 0], 1'b1} :
		   r_reg_q[g_BUS_WIDTH - 1 : 0];

endmodule

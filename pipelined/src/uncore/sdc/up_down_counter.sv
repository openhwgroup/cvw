///////////////////////////////////////////
// counter.sv
//
// Written: Ross Thompson
// Modified: 
//
// Purpose: basic up counter
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

module up_down_counter #(parameter integer WIDTH=32)
  (
   input logic [WIDTH-1:0]  CountIn,
   output logic [WIDTH-1:0] CountOut,
   input logic 		    Load,
   input logic 		    Enable,
   input logic 		    UpDown,   
   input logic 		    clk,
   input logic 		    reset);

  logic [WIDTH-1:0] NextCount;
  logic [WIDTH-1:0] count_q;
  logic [WIDTH-1:0] CountP1;

  flopenr #(WIDTH) reg1(.clk,
			.reset,
			.en(Enable | Load),
			.d(NextCount),
			.q(CountOut));

  assign CountP1 = UpDown ? CountOut + 1'b1 : CountOut - 1'b1;

  // mux between load and P1
  assign NextCount = Load ? CountIn : CountP1;

endmodule
  
   

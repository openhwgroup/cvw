///////////////////////////////////////////
// arrs.sv
//
// Written: Ross Thompson ross1728@gmail.com
// Modified: November 12, 2021
//
// Purpose: resets are typically asynchronous but need to be synchronized to
//          a clock to prevent changing in the invalid window clock edge.
//          arrs takes in the asynchronous reset and outputs an asynchronous
//          rising edge, but then syncs the falling edge to the posedge clk.
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

module arrs
  (input logic 	clk,
   input logic 	areset,
   output logic reset);

  logic 	metaStable;
  logic 	resetB;
  
  always_ff @(posedge clk , posedge areset) begin
    if(areset) begin
      metaStable <= 1'b0;
      resetB <= 1'b0;
    end else begin
      metaStable <= 1'b1;
      resetB <= metaStable;
    end
  end

  assign reset = ~resetB;
  
endmodule

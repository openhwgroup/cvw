///////////////////////////////////////////
// simple_timer.sv
//
// Written: Ross Thompson September 20, 2021
// Modified: 
//
// Purpose: SD card controller
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

module simple_timer #(parameter BUS_WIDTH = 4)
  (
   input logic [BUS_WIDTH-1:0] VALUE,
   input logic 		       START,
   output logic 	       FLAG,
   input logic 		       RST,
   input logic 		       CLK);


  logic [BUS_WIDTH-1:0]     count;
  logic timer_en;

  assign timer_en = count != 0;

  always_ff @(posedge CLK, posedge RST) begin
    if (RST) begin
      count <= '0;
    end else if (START) begin
      count <= VALUE - 1'b1;
    end else if(timer_en) begin
      count <= count - 1'b1;
    end
  end

  assign FLAG = count != 0;
  
endmodule
   

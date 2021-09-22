///////////////////////////////////////////
// clock divider.sv
//
// Written: Ross Thompson September 18, 2021
// Modified: 
//
// Purpose: clock divider for sd flash
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

module clkdivider #(parameter integer g_COUNT_WIDTH)
  (
   input logic [g_COUNT_WIDTH-1:0] i_COUNT_IN_MAX, //((Divide by value)/2) - 1
   input logic 			   i_EN, //Enable frequency division of i_clk
   input logic 			   i_CLK, // 1.2 GHz Base clock
   input logic 			   i_RST, // at start: clears flip flop and loads counter,
   // i_RST must NOT be a_RST, it needs to be synchronized with the 50 MHz Clock to load the
   // counter's initial value
   output logic 		   o_CLK                                 // frequency divided clock
   ); 


  logic [g_COUNT_WIDTH-1:0] r_count_out;  // wider for sign
  logic w_counter_overflowed;

  logic r_fd_Q;
  logic w_fd_D;

  logic w_load;

  assign  w_load = i_RST | w_counter_overflowed;  // reload when zero occurs or when set by outside

  counter #(.WIDTH(g_COUNT_WIDTH))  // wider for sign, this way the (MSB /= '1') only for zero
  my_counter (.clk(i_CLK),
	      .Load(w_load), //  reload when zero occurs or when set by outside
	      .CountIn(i_COUNT_IN_MAX), // negative signed integer
	      .CountOut(r_count_out),
	      .Enable(1'b1), // ALWAYS COUNT
	      .reset(1'b0)); // no reset, only load
  

  assign w_counter_overflowed = r_count_out[g_COUNT_WIDTH-1] == '0;
  
  flopenr #(1) toggle_flip_flop
      (.d(w_fd_D),
       .q(r_fd_Q),
       .clk(i_CLK),
       .reset(i_RST),                     // reset when told by outside
       .en(w_counter_overflowed));        // only update when counter overflows

  assign w_fd_D = ~ r_fd_Q;

  assign o_CLK = i_EN ? r_fd_Q : i_CLK;

endmodule

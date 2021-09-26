///////////////////////////////////////////
// sipo_generic_ce
//
// Written: Ross Thompson September 20, 2021
// Modified: 
//
// Purpose:  serial to n-bit parallel shift register using register_ce.
// When given a n-bit word as input transmit the message serially MSB (leftmost)
// bit first.

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

module sipo_generic_ce #(g_BUS_WIDTH)
  (input logic clk,
   input logic rst,
   input logic i_enable,      // data valid, write to register
   input logic i_message_bit,      // serial data
   output logic [g_BUS_WIDTH-1:0] o_data  // message received,  parallel data
   );

  logic [g_BUS_WIDTH-1:0] 	  w_reg_d;
  logic [g_BUS_WIDTH-1:0] 	  r_reg_q;

  flopenr #(g_BUS_WIDTH) shiftReg
    (.d(w_reg_d),
     .q(r_reg_q),
     .en(i_enable),
     .reset(rst),
     .clk(clk));
  
  assign w_reg_d = {r_reg_q[g_BUS_WIDTH-2:0], i_message_bit};

  assign o_data = r_reg_q;
  
endmodule

///////////////////////////////////////////
// crc16 sipo np ce
//
// Written: Richard Davis
// Modified: Ross Thompson September 18, 2021
//
// Purpose: CRC7 generator SIPO using register_ce
//          w/o appending any zero-bits othe message
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

module crc7_sipo_np_ce
  (
   input logic 	      clk,
   input logic 	      rst,//      initial CRC value must be b"000_0000"
   input logic 	      i_enable,
   input logic 	      i_message_bit,
   output logic [6:0] o_crc7);


  logic [6:0] 	      w_crc7_d;
  logic [6:0] 	      r_crc7_q;

  flopenr #(7) 
  crc7Reg(.clk(clk),
	  .reset(rst),
	  .en(i_enable),
	  .d(w_crc7_d),
	  .q(r_crc7_q));

  assign w_crc7_d[6] = r_crc7_q[5];
  assign w_crc7_d[5] = r_crc7_q[4];
  assign   w_crc7_d[4] = r_crc7_q[3];
  assign   w_crc7_d[3] = r_crc7_q[2] ^ (i_message_bit ^ r_crc7_q[6]);
  assign   w_crc7_d[2] = r_crc7_q[1];
  assign   w_crc7_d[1] = r_crc7_q[0];
  assign   w_crc7_d[0] = i_message_bit ^ r_crc7_q[6];

  assign   o_crc7 = r_crc7_q;
  

endmodule

   

///////////////////////////////////////////
// crc16 sipo np ce
//
// Written: Ross Thompson September 18, 2021
// Modified: 
//
// Purpose: CRC16 generator SIPO using register_ce
//              w/o appending any zero-bits to the message
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

module crc16_sipo_np_ce
  (input logic CLK, // sequential device
   input logic 	       RST, // initial calue of CRC register must be "0000_0000_0000_0000"
   input logic 	       i_enable, // input is valid
   input logic 	       i_message_bit,
   output logic [15:0] o_crc16);

  logic [15:0] 	       w_crc16_d;

  flopenr #(16) crc16reg(.clk(CLK),
			 .reset(RST),
			 .en(i_enable),
			 .d(w_crc16_d),
			 .q(o_crc16));

  assign   w_crc16_d[15] = o_crc16[14];
  assign   w_crc16_d[14] = o_crc16[13];
  assign   w_crc16_d[13] = o_crc16[12];
  assign   w_crc16_d[12] = o_crc16[11] ^ (i_message_bit ^ o_crc16[15]);
  assign   w_crc16_d[11] = o_crc16[10];
  assign   w_crc16_d[10] = o_crc16[9];
  assign   w_crc16_d[9] = o_crc16[8];
  assign   w_crc16_d[8] = o_crc16[7];
  assign   w_crc16_d[7] = o_crc16[6];
  assign   w_crc16_d[6] = o_crc16[5];
  assign   w_crc16_d[5] = o_crc16[4] ^ (i_message_bit ^ o_crc16[15]);
  assign   w_crc16_d[4] = o_crc16[3];
  assign   w_crc16_d[3] = o_crc16[2];
  assign   w_crc16_d[2] = o_crc16[1];
  assign   w_crc16_d[1] = o_crc16[0];
  assign   w_crc16_d[0] = i_message_bit ^ o_crc16[15];


endmodule

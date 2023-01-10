///////////////////////////////////////////
// crc16 sipo np ce
//
// Written: Richard Davis
// Modified: Ross Thompson September 18, 2021
// Converted to system verilog.
//
// Purpose: CRC16 generator SIPO using register_ce
//              w/o appending any zero-bits to the message
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

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

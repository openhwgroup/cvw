///////////////////////////////////////////
// crc16 sipo np ce
//
// Written: Richard Davis
// Modified: Ross Thompson September 18, 2021
//
// Purpose: CRC7 generator SIPO using register_ce
//          w/o appending any zero-bits othe message
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
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

   

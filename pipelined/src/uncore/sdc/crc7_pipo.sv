///////////////////////////////////////////
// crc7 sipo np ce
//
// Written: Richard Davis
// Modified: Ross Thompson September 18, 2021
// Converted to system verilog.
//
// Purpose:  takes 40 bits of input, generates 7 bit CRC after a single
// clock cycle!
//              w/o appending any zero-bits to the message
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

module crc7_pipo (
  input logic [39:0] i_DATA,
  input logic 	      i_CRC_ENABLE,
  input logic 	      RST,
  input logic 	      CLK,
  output logic [6:0] o_CRC
);
  
  logic [6:0] 	      r_lfsr_q;
  logic [6:0] 	      w_lfsr_d;

  assign o_CRC = r_lfsr_q;
  
  assign w_lfsr_d[0] = r_lfsr_q[1] ^ r_lfsr_q[2] ^ r_lfsr_q[4] ^ r_lfsr_q[6] ^ i_DATA[0] ^ i_DATA[4] ^ i_DATA[7] ^ i_DATA[8] ^ i_DATA[12] ^ i_DATA[14] ^ i_DATA[15] ^ i_DATA[16] ^ i_DATA[18] ^ i_DATA[20] ^ i_DATA[21] ^ i_DATA[23] ^ i_DATA[24] ^ i_DATA[30] ^ i_DATA[31] ^ i_DATA[34] ^ i_DATA[35] ^ i_DATA[37] ^ i_DATA[39];

  assign w_lfsr_d[1] = r_lfsr_q[2] ^ r_lfsr_q[3] ^ r_lfsr_q[5] ^ i_DATA[1] ^ i_DATA[5] ^ i_DATA[8] ^ i_DATA[9] ^ i_DATA[13] ^ i_DATA[15] ^ i_DATA[16] ^ i_DATA[17] ^ i_DATA[19] ^ i_DATA[21] ^ i_DATA[22] ^ i_DATA[24] ^ i_DATA[25] ^ i_DATA[31] ^ i_DATA[32] ^ i_DATA[35] ^ i_DATA[36] ^ i_DATA[38];
  
  assign w_lfsr_d[2] = r_lfsr_q[0] ^ r_lfsr_q[3] ^ r_lfsr_q[4] ^ r_lfsr_q[6] ^ i_DATA[2] ^ i_DATA[6] ^ i_DATA[9] ^ i_DATA[10] ^ i_DATA[14] ^ i_DATA[16] ^ i_DATA[17] ^ i_DATA[18] ^ i_DATA[20] ^ i_DATA[22] ^ i_DATA[23] ^ i_DATA[25] ^ i_DATA[26] ^ i_DATA[32] ^ i_DATA[33] ^ i_DATA[36] ^ i_DATA[37] ^ i_DATA[39];
  
  assign w_lfsr_d[3] = r_lfsr_q[0] ^ r_lfsr_q[2] ^ r_lfsr_q[5] ^ r_lfsr_q[6] ^ i_DATA[0] ^ i_DATA[3] ^ i_DATA[4] ^ i_DATA[8] ^ i_DATA[10] ^ i_DATA[11] ^ i_DATA[12] ^ i_DATA[14] ^ i_DATA[16] ^ i_DATA[17] ^ i_DATA[19] ^ i_DATA[20] ^ i_DATA[26] ^ i_DATA[27] ^ i_DATA[30] ^ i_DATA[31] ^ i_DATA[33] ^ i_DATA[35] ^ i_DATA[38] ^ i_DATA[39];
  
  assign w_lfsr_d[4] = r_lfsr_q[1] ^ r_lfsr_q[3] ^ r_lfsr_q[6] ^ i_DATA[1] ^ i_DATA[4] ^ i_DATA[5] ^ i_DATA[9] ^ i_DATA[11] ^ i_DATA[12] ^ i_DATA[13] ^ i_DATA[15] ^ i_DATA[17] ^ i_DATA[18] ^ i_DATA[20] ^ i_DATA[21] ^ i_DATA[27] ^ i_DATA[28] ^ i_DATA[31] ^ i_DATA[32] ^ i_DATA[34] ^ i_DATA[36] ^ i_DATA[39];
  
  assign w_lfsr_d[5] = r_lfsr_q[0] ^ r_lfsr_q[2] ^ r_lfsr_q[4] ^ i_DATA[2] ^ i_DATA[5] ^ i_DATA[6] ^ i_DATA[10] ^ i_DATA[12] ^ i_DATA[13] ^ i_DATA[14] ^ i_DATA[16] ^ i_DATA[18] ^ i_DATA[19] ^ i_DATA[21] ^ i_DATA[22] ^ i_DATA[28] ^ i_DATA[29] ^ i_DATA[32] ^ i_DATA[33] ^ i_DATA[35] ^ i_DATA[37];
  
  assign w_lfsr_d[6] = r_lfsr_q[0] ^ r_lfsr_q[1] ^ r_lfsr_q[3] ^ r_lfsr_q[5] ^ i_DATA[3] ^ i_DATA[6] ^ i_DATA[7] ^ i_DATA[11] ^ i_DATA[13] ^ i_DATA[14] ^ i_DATA[15] ^ i_DATA[17] ^ i_DATA[19] ^ i_DATA[20] ^ i_DATA[22] ^ i_DATA[23] ^ i_DATA[29] ^ i_DATA[30] ^ i_DATA[33] ^ i_DATA[34] ^ i_DATA[36] ^ i_DATA[38];

  

  flopenr #(7) 
  lfsrReg(.clk(CLK),
	  .reset(RST),
	  .en(i_CRC_ENABLE),
	  .d(w_lfsr_d),
	  .q(r_lfsr_q));


endmodule

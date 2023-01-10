///////////////////////////////////////////
// sipo_generic_ce
//
// Written: Richard Davis
// Modified: Ross Thompson September 20, 2021
//
// Purpose:  serial to n-bit parallel shift register using register_ce.
// When given a n-bit word as input transmit the message serially MSB (leftmost)
// bit first.

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

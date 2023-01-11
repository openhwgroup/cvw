///////////////////////////////////////////
// piso generic ce
//
// Written: Richard Davis
// Modified: Ross Thompson September 18, 2021
//
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

module piso_generic_ce #(parameter integer g_BUS_WIDTH)
  (
   input logic 			 clk, 
   input logic 			 i_load, 
   input logic [g_BUS_WIDTH-1:0] i_data, 
   input logic 			 i_en,
   output 			 o_data);

  
  logic [g_BUS_WIDTH-1:0] 	 w_reg_d;
  logic [g_BUS_WIDTH-1:0] 	 r_reg_q;

  flopenr #(g_BUS_WIDTH)
  shiftReg(.clk(clk),
	   .reset(1'b0),
	   .en(1'b1),
	   .d(w_reg_d),
	   .q(r_reg_q));

  assign o_data = i_en ? r_reg_q[g_BUS_WIDTH - 1] : 1'b1;
  assign w_reg_d = i_load ? i_data :
		   i_en ? {r_reg_q[g_BUS_WIDTH - 2 : 0], 1'b1} :
		   r_reg_q[g_BUS_WIDTH - 1 : 0];

endmodule

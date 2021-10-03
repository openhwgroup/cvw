///////////////////////////////////////////
// sd_clk_fsm.sv
//
// Written: Ross Thompson September 19, 2021
// Modified: 
//
// Purpose: Controls clock dividers.
// Replaces s_disable_sd_clocks, s_select_hs_clk, s_enable_hs_clk
// in sd_cmd_fsm.vhd. Attempts to correct issues with oversampling and
// under-sampling of control signals (for counter_cmd), that were present in my
// previous design.
// This runs on 50 MHz.
// sd_cmd_fsm will run on SD_CLK_Gated (50 MHz or 400 KHz, selected by this)
// asynchronous reset is used for both sd_cmd_fsm and for this.
// It must be synchronized with 50 MHz and held for a minimum period of a full
// 400 KHz pulse width.
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

module sd_clk_fsm
  (
   input logic 	CLK,
   input logic 	i_RST,
   (* mark_debug = "true" *)output logic o_DONE,
   (* mark_debug = "true" *)input logic i_START,
   (* mark_debug = "true" *)input logic i_FATAL_ERROR,
   (* mark_debug = "true" *)output logic o_HS_TO_INIT_CLK_DIVIDER_RST, // resets clock divider that is going from 50 MHz to 400 KHz
   (* mark_debug = "true" *)output logic o_SD_CLK_SELECTED, // which clock is selected ('0'=HS or '1'=init)
   (* mark_debug = "true" *)output logic o_G_CLK_SD_EN);  // Turns gated clock (G_CLK_SD) off and on


  logic [3:0] 	w_next_state;
  (* mark_debug = "true" *) logic [3:0] 	r_curr_state;
  

  // clock selection
  parameter c_sd_clk_init = 1'b1;
  parameter c_sd_clk_hs = 1'b0;

  // States
  localparam s_reset = 4'b0000;
  localparam s_enable_init_clk = 4'b0001;  // enable 400 KHz
  localparam s_disable_sd_clocks = 4'b0010;
  localparam s_select_hs_clk = 4'b0011;
  localparam s_enable_hs_clk = 4'b0100;
  localparam s_done = 4'b0101;
  localparam s_disable_sd_clocks_2 = 4'b0110;  // if error occurs
  localparam s_select_init_clk = 4'b0111;  // if error occurs
  localparam s_safe_state = 4'b1111;  //always provide a safe state return if all states are not used

  flopenr #(4) stateReg(.clk(CLK),
		       .reset(i_RST),
		       .en(1'b1),
		       .d(w_next_state),
		       .q(r_curr_state));

  assign w_next_state = i_RST ? s_reset :
			r_curr_state == s_reset | (r_curr_state == s_enable_init_clk & ~i_START) | (r_curr_state == s_select_init_clk) ? s_enable_init_clk :
			r_curr_state == s_enable_init_clk & i_START ? s_disable_sd_clocks :
			r_curr_state == s_disable_sd_clocks ? s_select_hs_clk :
			r_curr_state == s_select_hs_clk ? s_enable_hs_clk :
			r_curr_state == s_enable_hs_clk | (r_curr_state == s_done & ~i_FATAL_ERROR) ? s_done :
			r_curr_state == s_done & i_FATAL_ERROR ? s_disable_sd_clocks_2 :
			r_curr_state == s_disable_sd_clocks_2 ? s_select_init_clk :
			s_safe_state;


  assign o_HS_TO_INIT_CLK_DIVIDER_RST = r_curr_state == s_reset;

  assign o_SD_CLK_SELECTED = (r_curr_state == s_select_hs_clk) | (r_curr_state == s_enable_hs_clk) | (r_curr_state == s_done) ? c_sd_clk_hs : c_sd_clk_init;

  assign o_G_CLK_SD_EN = (r_curr_state == s_enable_init_clk) | (r_curr_state == s_enable_hs_clk) | (r_curr_state == s_done);
  
  assign o_DONE = r_curr_state == s_done;

endmodule  


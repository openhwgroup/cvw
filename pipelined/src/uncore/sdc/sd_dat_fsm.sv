///////////////////////////////////////////
// sd_dat_fsm.sv
//
// Written: Richard Davis
// Modified: Ross Thompson September 19, 2021
//
// Purpose: Runs in parallel with sd_cmd_fsm to control activity on the DAT
// bus of the SD card.
// 14 State Mealy FSM + Safe state = 15 State Mealy FSM
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

module sd_dat_fsm
  (
    input logic 	CLK, // HS Clock (48 MHz)
    input logic 	i_RST,
    // Timer module control
    input logic 	i_SD_CLK_SELECTED, // Which frequency I'm in determines what count in to load for a 100ms timer
    output logic 	o_TIMER_LOAD, o_TIMER_EN, // Timer Control signals
    output logic [22:0] o_TIMER_IN, // Need Enough bits for 100 milliseconds at 48MHz
    input logic [22:0] i_TIMER_OUT, // (ceiling(log((clk freq)(delay desired)-1)/log(2))-1) downto 0
    // Nibble counter module control
    output logic o_COUNTER_RST, o_COUNTER_EN, // nibble counter
    input logic [10:0] i_COUNTER_OUT, // max nibbles is 1024 + crc16 bits = 1040 bits
    // CRC16 Generation control
    (* mark_debug = "true" *)output logic o_CRC16_EN, o_CRC16_RST, // shared signals for  all 4 CRC16_SIPO (one for each of 4 DAT lines)
    (* mark_debug = "true" *)input logic i_DATA_CRC16_GOOD, // indicates that no errors in transmission when CRC16 are all zero
    // For R1b
    output logic o_BUSY_RST, o_BUSY_EN, // busy signal for R1b
    (* mark_debug = "true" *)input logic i_DAT0_Q,
    // Storage Buffers for DAT bits read
    output logic o_NIBO_EN, // 512 bytes block data (Nibble In Block Out)
    // From LUT
    (* mark_debug = "true" *)input logic [1:0] i_USES_DAT, // current command needs use of DAT bus
    // For communicating with core
    output logic o_DATA_VALID, // indicates that DATA being send over o_DATA to core is valid
    output logic o_LAST_NIBBLE, // indicates that the last nibble has been sent
    // For communication with sd_cmd_fsm
    (* mark_debug = "true" *)input logic i_CMD_TX_DONE, // command transmission completed, begin waiting for DATA
    (* mark_debug = "true" *)output logic o_DAT_RX_DONE, // tell SD_CMD_FSM that DAT communication is completed, send next instruction to sd card
    (* mark_debug = "true" *)output logic o_ERROR_DAT_TIMES_OUT, // error flag for when DAT times out (so don't fetch more instructions)
    (* mark_debug = "true" *)output logic o_DAT_ERROR_FD_RST,
    (* mark_debug = "true" *)output logic o_DAT_ERROR_FD_EN, // tell SD_CMD_FSM to resend command due to error in transmission
    input logic 	LIMIT_SD_TIMERS
   );

  (* mark_debug = "true" *) logic [3:0] 	r_curr_state;
   logic [3:0] 	w_next_state;  
  
  logic r_error_crc16_fd_Q;

  logic [22:0] Identify_Timer_In;
  logic [22:0] Data_TX_Timer_In;

  localparam logic [3:0] s_reset = 4'b0000;
  localparam logic [3:0] s_idle = 4'b0001;
  localparam logic [3:0] s_idle_for_start_bit = 4'b0010;
  localparam logic [3:0] s_read_r1b = 4'b0011;
  localparam logic [3:0] s_notify_r1b_completed = 4'b0100;
  localparam logic [3:0] s_error_time_out = 4'b0101;
  localparam logic [3:0] s_rx_wide_data = 4'b0110;
  localparam logic [3:0] s_rx_block_data = 4'b0111;
  localparam logic [3:0] s_rx_crc16 = 4'b1000;
  localparam logic [3:0] s_error_crc16_fail = 4'b1001;
  localparam logic [3:0] s_publish_block_data = 4'b1010;
  localparam logic [3:0] s_publish_wide_data = 4'b1011;
  localparam logic [3:0] s_reset_wide_data = 4'b1100;
  localparam logic [3:0] s_reset_block_data = 4'b1101;
  localparam logic [3:0] s_reset_nibble_counter = 4'b1110;  // Before publishing CMD17 Block Data

  localparam logic [1:0] c_DAT_none = 2'b00;
  localparam logic [1:0] c_DAT_busy = 2'b01;
  localparam logic [1:0] c_DAT_wide = 2'b10;
  localparam logic [1:0] c_DAT_block = 2'b11;

  localparam logic c_start_bit = 0;
  localparam logic c_busy_bit = 0;

  // load values in for timers and counters
  localparam logic c_slow_clock = 1'b1;  // use during initialization (card identification mode)
  localparam logic c_HS_clock = 1'b0;  // use after CMD6 switches clock frequency (CMD17)


  logic 	   TIMER_OUT_GT_0;
  logic 	   TIMER_OUT_EQ_0;
  logic 	   COUNTER_OUT_EQ_1023;
  logic 	   COUNTER_OUT_LT_1023;
  logic 	   COUNTER_OUT_LT_128;
  logic 	   COUNTER_OUT_EQ_128;
  logic 	   COUNTER_OUT_LT_144;
  logic 	   COUNTER_OUT_EQ_144;
  logic 	   COUNTER_OUT_LT_1040;
  logic 	   COUNTER_OUT_EQ_1040;


  assign Identify_Timer_In = LIMIT_SD_TIMERS ? 23'b00000000000000001100011 : 23'b00000001001110001000000; // 40,000 unsigned.
  assign Data_TX_Timer_In  = LIMIT_SD_TIMERS ? 23'b00000000000000001100011 : 23'b11110100001001000000000; // 8,000,000 unsigned.

  flopenr #(4) stateReg(.clk(CLK),
			.reset(i_RST),
			.en(1'b1),
			.d(w_next_state),
			.q(r_curr_state));

  assign TIMER_OUT_GT_0 = i_TIMER_OUT > 0;
  assign TIMER_OUT_EQ_0 = i_TIMER_OUT == 0;
  assign COUNTER_OUT_EQ_1023 = i_COUNTER_OUT == 1023;
  assign COUNTER_OUT_LT_1023 = i_COUNTER_OUT < 1023;  
  assign COUNTER_OUT_LT_128 = i_COUNTER_OUT < 128;
  assign COUNTER_OUT_EQ_128 = i_COUNTER_OUT == 128;
  assign COUNTER_OUT_LT_144 = i_COUNTER_OUT < 144;  
  assign COUNTER_OUT_EQ_144 = i_COUNTER_OUT == 144;  
  assign COUNTER_OUT_LT_1040 = i_COUNTER_OUT < 1040;
  assign COUNTER_OUT_EQ_1040 = i_COUNTER_OUT == 1040;

  assign w_next_state = ((i_RST) | 
                         (r_curr_state == s_error_time_out) |  // noticed this change is needed during emulation
                         (r_curr_state == s_notify_r1b_completed) |
                         (r_curr_state == s_error_crc16_fail) |
                         (r_curr_state == s_publish_wide_data) | 
                         ((r_curr_state == s_publish_block_data) & (COUNTER_OUT_EQ_1023))) ? s_reset  : 

                  ((r_curr_state == s_reset) | 
                   ((r_curr_state == s_idle) & ((i_USES_DAT == c_DAT_none) | ((i_USES_DAT != c_DAT_none) & (~i_CMD_TX_DONE))))) ? s_idle : 

                  ((r_curr_state == s_idle) & (i_USES_DAT == c_DAT_wide) & (i_CMD_TX_DONE)) ? s_reset_wide_data : 
                  
                  ((r_curr_state == s_idle) & (i_USES_DAT == c_DAT_block) & (i_CMD_TX_DONE)) ? s_reset_block_data :

                  ((r_curr_state == s_reset_wide_data) | 
                   ((r_curr_state == s_idle) & (i_USES_DAT == c_DAT_busy) & (i_CMD_TX_DONE)) | 
                   (r_curr_state == s_reset_block_data) |
                   ((r_curr_state == s_idle_for_start_bit) & (TIMER_OUT_GT_0) & (i_DAT0_Q != c_start_bit))) ? s_idle_for_start_bit :
			
                  ((r_curr_state == s_idle_for_start_bit) &  // Apparently R1b's busy signal is optional,
                   (TIMER_OUT_EQ_0) &          // Even if it never shows up,
                   (i_USES_DAT == c_DAT_busy)) ? s_notify_r1b_completed :          // pretend it did, & move on

                  (((r_curr_state == s_idle_for_start_bit) & (TIMER_OUT_GT_0) &
                    (i_DAT0_Q == c_start_bit) & (i_USES_DAT == c_DAT_busy)) | 
                   ((r_curr_state == s_read_r1b) & (TIMER_OUT_GT_0) & (i_DAT0_Q == c_busy_bit))) ? s_read_r1b :

                  (((r_curr_state == s_read_r1b) & (TIMER_OUT_EQ_0)) | 
                   ((r_curr_state == s_idle_for_start_bit) & (TIMER_OUT_EQ_0) & 
                    (i_USES_DAT != c_DAT_busy))) ? s_error_time_out :

                  ((r_curr_state == s_read_r1b) & (i_DAT0_Q != c_busy_bit)) ? s_notify_r1b_completed :

                  (((r_curr_state == s_idle_for_start_bit) & (TIMER_OUT_GT_0) & (i_DAT0_Q == c_start_bit) &
                    (i_USES_DAT == c_DAT_wide)) |
                   ((r_curr_state == s_rx_wide_data) & (COUNTER_OUT_LT_128))) ? s_rx_wide_data :

                  (((r_curr_state == s_idle_for_start_bit) & (TIMER_OUT_GT_0) & 
                    (i_DAT0_Q == c_start_bit) & (i_USES_DAT == c_DAT_block)) | 
                   ((r_curr_state == s_rx_block_data) & (COUNTER_OUT_LT_1023))) ? s_rx_block_data :

                  (((r_curr_state == s_rx_wide_data) & (COUNTER_OUT_EQ_128)) | 
                   ((r_curr_state == s_rx_block_data) & (COUNTER_OUT_EQ_1023)) | 
                   ((r_curr_state == s_rx_crc16) & 
                    (((i_USES_DAT == c_DAT_wide) & (COUNTER_OUT_LT_144)) | 
                     ((i_USES_DAT == c_DAT_block) & (COUNTER_OUT_LT_1040))))) ? s_rx_crc16 :

                  ((r_curr_state == s_rx_crc16) &
                   (((i_USES_DAT == c_DAT_wide) & (COUNTER_OUT_EQ_144)) |
                    ((i_USES_DAT == c_DAT_block) & (COUNTER_OUT_EQ_1040))) &
                   (~i_DATA_CRC16_GOOD)) ? s_error_crc16_fail :

                  ((r_curr_state == s_rx_crc16) & (i_USES_DAT == c_DAT_wide) & (COUNTER_OUT_EQ_144) &
                   (i_DATA_CRC16_GOOD)) ? s_publish_wide_data :

                  ((r_curr_state == s_rx_crc16) &
                   (i_USES_DAT == c_DAT_block) & (COUNTER_OUT_EQ_1040) & (i_DATA_CRC16_GOOD)) ? s_reset_nibble_counter :

                  ((r_curr_state == s_reset_nibble_counter)) ? s_publish_block_data : 
                  
                  s_reset;

  assign o_TIMER_IN   = (r_curr_state == s_reset) & (i_SD_CLK_SELECTED == c_slow_clock) ? Identify_Timer_In : Data_TX_Timer_In;
  
  assign o_TIMER_LOAD = ((r_curr_state == s_reset) | 
                  (r_curr_state == s_reset_block_data));

  assign o_TIMER_EN = ((r_curr_state == s_idle_for_start_bit) |
                (r_curr_state == s_read_r1b));
  
  // Nibble Counter module
  assign o_COUNTER_RST = (r_curr_state == s_reset) | (r_curr_state == s_reset_nibble_counter);
  
  assign o_COUNTER_EN = ((r_curr_state == s_rx_block_data) |
                  (r_curr_state == s_rx_wide_data) |
                  (r_curr_state == s_rx_crc16)) | (r_curr_state == s_publish_block_data);
  
  // CRC16 Generation module
  assign o_CRC16_RST = (r_curr_state == s_reset);
  
  assign o_CRC16_EN = ((r_curr_state == s_rx_block_data) |
                (r_curr_state == s_rx_wide_data) |
                (r_curr_state == s_rx_crc16));

  // Flip Flop Module (for R1b)
  assign o_BUSY_RST = (r_curr_state == s_reset);
  
  //o_BUSY_EN = '1' when ((r_curr_state == s_idle_for_start_bit) |
  //                       (r_curr_state == s_read_r1b)) else
  //             '0';
  assign o_BUSY_EN = 1'b1;                     // Always sample data

  // DAT Storage Modules
  assign o_NIBO_EN = (r_curr_state == s_rx_block_data);

  // To sd_cmd_fsm
  assign o_DAT_RX_DONE = ((r_curr_state == s_error_time_out) |
                             (r_curr_state == s_notify_r1b_completed) |
                             (r_curr_state == s_error_crc16_fail) |
                             (r_curr_state == s_publish_wide_data) |
                   (r_curr_state == s_publish_block_data));
  
  assign o_ERROR_DAT_TIMES_OUT = (r_curr_state == s_error_time_out);
  
  
  // o_RESEND_READ_WIDE  (Error! This is not defined. Indicates switch command must be re-rent),
  //  should be a function of block busy logic 

  // For Communication with core
  assign o_DATA_VALID = (r_curr_state == s_publish_block_data);
  
  assign o_LAST_NIBBLE = ((r_curr_state == s_publish_block_data)
                     & (COUNTER_OUT_EQ_1023)) | (r_curr_state == s_error_time_out); // notify done if errors occur

  // o_ERROR_CRC16 (note: saved to flip flop because otherwise is only 1 clock cycle, not what I want)
  assign o_DAT_ERROR_FD_RST = (r_curr_state == s_reset_block_data) | (r_curr_state == s_reset_wide_data);
  assign o_DAT_ERROR_FD_EN = (r_curr_state == s_rx_crc16);
  


  

endmodule

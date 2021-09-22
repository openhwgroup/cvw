///////////////////////////////////////////
// sd_clk_fsm.sv
//
// Written: Ross Thompson September 19, 2021
// Modified: 
//
// Purpose: Finite state machine for the SD CMD bus
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

module sd_cmd_fsm
  (

   input logic 	       CLK, // HS
   //i_SLOWER_CLK                          : in  std_logic;
   input logic 	       i_RST, // reset FSM,
   // MUST COME OUT OF RESET
   // SYNCHRONIZED TO THE 1.2 GHZ CLOCK!
   output logic        o_TIMER_LOAD, o_TIMER_EN, // Timer
   output logic [18:0] o_TIMER_IN,
   input logic [18:0]  i_TIMER_OUT,
   output logic        o_COUNTER_LOAD, o_COUNTER_EN, // Counter
   output logic [7:0]  o_COUNTER_IN,
   input logic [7:0]   i_COUNTER_OUT,
   output logic        o_SD_CLK_EN, // Clock Gaters
   input logic 	       i_CLOCK_CHANGE_DONE, // Communication with CLK_FSM
   output logic        o_START_CLOCK_CHANGE, // Communication with CLK_FSM
   output logic        o_IC_RST, o_IC_EN, o_IC_UP_DOWN, // Instruction counter
   input logic [3:0]   i_IC_OUT, // stop when you get to 10 because that is CMD17
   input logic [1:0]   i_USES_DAT,
   input logic [6:0]   i_OPCODE,
   input logic [2:0]   i_R_TYPE,
   // bit masks
   input logic [31:0]  i_NO_REDO_MASK,
   input logic [31:0]  i_NO_REDO_ANS,
   input logic [31:0]  i_NO_ERROR_MASK,
   input logic [31:0]  i_NO_ERROR_ANS,
   output logic        o_SD_CMD_OE, // Enable ouptut on tri-state SD_CMD line
   // TX Components
   output logic        o_TX_PISO40_LOAD, o_TX_PISO40_EN, // Shift register for TX command head
   output logic        o_TX_PISO8_LOAD, o_TX_PISO8_EN, // Shift register for TX command tail
   output logic        o_TX_CRC7_PIPO_RST, o_TX_CRC7_PIPO_EN, // Parallel-to-Parallel CRC7 Generator
   output logic [1:0]  o_TX_SOURCE_SELECT, // What gets sent to CMD_TX
   // TX Memory
   output logic        o_CMD_TX_IS_CMD55_RST,
   output logic        o_CMD_TX_IS_CMD55_EN, // '1' means that the command that was just sent has index
   // 55, so the subsequent command is to be
   // viewed as ACMD by the SD card.
   // RX Components
   input logic 	       i_SD_CMD_RX, // serial response input on SD_CMD
   output logic        o_RX_SIPO48_RST, o_RX_SIPO48_EN, // Shift Register for all 48 bits of Response

   input logic [39:8]  i_RESPONSE_CONTENT, // last 32 bits of RX_SIPO_40_OUT
   input logic [45:40] i_RESPONSE_INDEX, // 6 bits from RX_SIPO_40_OUT
   output logic        o_RX_CRC7_SIPO_RST, o_RX_CRC7_SIPO_EN, // Serial-to-parallel CRC7 Generator
   input logic [6:0]   i_RX_CRC7,
   // RX Memory
   output logic        o_RCA_REGISTER_RST, o_RCA_REGISTER_EN, // Relative Card Address
   // Communication to sd_dat_fsm
   output logic        o_CMD_TX_DONE, // begin waiting for DAT_RX to complete
   input logic 	       i_DAT_RX_DONE, // now go to next state since data block rx was completed
   input logic 	       i_ERROR_CRC16, // repeat last command
   input logic 	       i_ERROR_DAT_TIMES_OUT,
   // Commnuication to core
   output logic        o_READY_FOR_READ, // tell core that I have completed initialization
   output logic        o_SD_RESTARTING, // inform core the need to restart
   input logic 	       i_READ_REQUEST, // core tells me to execute CMD17
   // Communication to Host
   output logic        o_DAT_ERROR_FD_RST,
   output logic [2:0]  o_ERROR_CODE_Q, // Indicates what caused the fatal error
   output logic        o_FATAL_ERROR, // SD Card is damaged beyond recovery, restart entire initialization procedure of card
   input logic 	       LIMIT_SD_TIMERS
   );



  logic  [4:0]  w_next_state, r_curr_state;
  logic 	w_resend_last_command, w_rx_crc7_check, w_rx_index_check, w_rx_bad_crc7, w_rx_bad_index, w_rx_bad_reply, w_bad_card;
  
  logic [31:0] 	w_redo_result, w_error_result;
  logic 	w_ACMD41_init_done;
  logic 	w_fail_cnt_en, w_fail_count_rst;
  logic [10:0] 	r_fail_count_out;

  logic 	w_ACMD41_busy_timer_START, w_ACMD41_times_out_FLAG, w_ACMD41_busy_timer_RST; //give up after 1000 ms of ACMD41
  logic [2:0] 	w_ERROR_CODE_D, r_ERROR_CODE_Q ; // Error Codes for fatal error on SD CMD FSM
  logic 	w_error_code_rst, w_error_code_en;
  logic [18:0] 	Timer_In;


  localparam s_reset_clear_error_reg = 5'b00000;
  localparam s_idle_supply_no_clk    = 5'b00001;
  localparam s_idle_supply_sd_clk    = 5'b00010;
  localparam s_ld_head               = 5'b00011;
  localparam s_tx_head               = 5'b00100;
  localparam s_ld_tail               = 5'b00101;
  localparam s_tx_tail               = 5'b00110;
  localparam s_setup_rx              = 5'b00111;
  localparam s_idle_ncc              = 5'b01000;
  localparam s_fetch_next_cmd        = 5'b01001;
  localparam s_rx_48                 = 5'b01010;
  localparam s_rx_136                = 5'b01011;
  localparam s_error_no_response     = 5'b01100;
  localparam s_idle_for_dat          = 5'b01101;
  localparam s_error_bad_card        = 5'b01110;
  localparam s_idle_nrc              = 5'b01111;
  localparam s_count_attempt         = 5'b10000;
  localparam s_reset_from_error      = 5'b10001;
  //localparam s_enable_hs_clk       = 5'b10010;
  localparam s_idle_for_start_bit    = 5'b10011;
  localparam s_fetch_prev_cmd        = 5'b10100;  // use to resend previous cmd55 if acmd is resent
  // localparam s_setup_rx_b         = 5'b10110;
//  localparam s_idle_for_start_bit_b= 5'b10111;
//  localparam s_rx_48_b             = 5'b11000;
//  localparam s_rx_136_b            = 5'b11001;
  localparam s_error_dat_time_out    = 5'b11010;  // don't advance states if the dat fsm times out
  localparam s_idle_for_clock_change = 5'b11011;  // replaces s_disable_sd_clocks, s_select_hs_clk, s_enable_hs_clk
  localparam s_study_response        = 5'b11100;  // Do error checking here
  localparam s_idle_for_read_request = 5'b11101;  // After power up and initialization sequence is completed
  localparam s_Error_TX_Failed       = 5'b11110;  // when fail_cnt_out exceeds c_max_attempts

  localparam c_MAX_ATTEMPTS  = 3;  // Give up sending a command after 3 failed attempts
  // (except ACMD41) so the processor is not locked up forever

  localparam c_response_type_R0_NONE    = 0;
  localparam c_response_type_R1_NORMAL  = 1;
  localparam c_response_type_R2_CID_CSD = 2;
  localparam c_response_type_R3_OCR     = 3;
  localparam c_response_type_R6_RCA     = 6;
  localparam c_response_type_R7_CIC     = 7;

  localparam c_start_bit = 1'b0;

  localparam c_DAT_none  = 2'b00;
  localparam c_DAT_busy  = 2'b01;
  localparam c_DAT_wide  = 2'b10;
  localparam c_DAT_block = 2'b11;

  // Instructions mnemonics based on index (opcode(5 downto 0))
  localparam logic [45:40] c_Go_Idle_State = 6'd0; //CMD0
  localparam logic [45:40] c_All_Send_CID = 6'd02;  //  CMD2
  localparam logic [45:40] c_SD_Send_RCA = 6'd03;  //  CMD3
  localparam logic [45:40] c_Switch_Function = 6'd06;  //  CMD6
  localparam logic [45:40] c_Set_Bus_Width = 6'd06;  // ACMD6
  localparam logic [45:40] c_Select_Card = 6'd07;  //  CMD7
  localparam logic [45:40] c_Send_IF_State = 6'd08;  //  CMD8
  localparam logic [45:40] c_Read_Single_Block = 6'd17;  //  CMD17
  localparam logic [45:40] c_SD_Send_OCR = 6'd41;  // ACMD41
  localparam logic [45:40] c_App_Command = 6'd55;  //  CMD55

// clock selection
  localparam c_sd_clk_init = 1'b1;
  localparam c_sd_clk_hs = 1'b0;

  //tx source selection
  localparam logic [1:0]   c_tx_low = 2'b00;
  localparam logic [1:0]  c_tx_high = 2'b01;
  localparam logic [1:0] c_tx_head = 2'b10;
  localparam logic [1:0] c_tx_tail = 2'b11;

  // Error Codes for Error Register
  localparam logic [2:0] c_NO_ERRORS = 3'b000;  // no fatal errors occurred
  // (default value when register is cleared during reset)
  localparam [2:0]  C_ERROR_NO_CMD_RESPONSE = 3'b100;  // card timed out while waiting for a response on CMD, no start bit
                                                                             //    of response packet was ever received
                                                                             //    (possible causes: illegal command, card is disconnected,
                                                                             //    not meeting timing (you can fix timing by inverting the clock
                                                                             //    sent to card))
  localparam logic [2:0] c_ERROR_NO_DAT_RESPONSE = 3'b101;  // card timed out while waiting for a data block on DAT, no start bit
                                                                             //    of DAT packet was ever received
                                                                             //    (possible cause: card is disconnected)
  localparam logic [2:0] C_ERROR_BAD_CARD_STATUS = 3'b110;  // status bits of a response indicate a card is not supported
                                                                             //    or that the card is damaged internally
  localparam logic [2:0] C_ERROR_EXCEED_MAX_ATTEMPTS = 3'b111;  // if a command fails it may be resent,
                                                                                 //    but after so many attempts you should just give up

  //Alias for value of SD_CMD_Output_Enable
  localparam c_TX_COMMAND = 1'b1;  // Enable output on SD_CMD
  localparam c_RX_RESPONSE = 1'b0;  // Disable Output on SD_CMD

  // load values in for timers and counters
  localparam logic [7:0] c_NID_max = 8'd63;  // counter_in: should be "4"
                                                                     // downto 0 = 5 bits count
                                                                     // but is not enough time for
                                                                     // sdModel.v
  localparam logic [7:0] c_NCR_max = 8'd63;  // counter_in
  localparam logic [7:0] c_NCC_min = 8'd7;   // counter_in
  localparam logic [7:0] c_NRC_min = 8'd8;   // counter_in

  localparam logic [18:0] c_1000ms = 18'd400000;  // ACMD41 timeout
  
  // command instruction type (opcode(6))
  localparam c_CMD = 1'b0; 
  localparam c_ACMD = 1'b1;

  // counter direction for up_down
  localparam c_increment = 1'b1;  // count <= count + 1
  localparam c_decrement = 1'b0;  // count <= count - 1

  assign Timer_In = LIMIT_SD_TIMERS ? 19'b0000000000000000011 : 19'b0011000011010100000; // 250 ms

  //Fail Counter, tracks how many failed attempts at command transmission
  counter #(11) fail_counter
    (.CountIn(11'b0),
     .CountOut(r_fail_count_out),
     .Load(1'b0),
     .Enable(w_fail_cnt_en),
     .clk(CLK),
     .reset(w_fail_count_rst));

  // Simple timer for ACMD41 busy
  simple_timer #(19) ACMD41_busy_timer
    (.VALUE(c_1000ms),
    .START(w_ACMD41_busy_timer_START),
    .FLAG(w_ACMD41_times_out_FLAG),
    .RST(w_ACMD41_busy_timer_RST),
    .CLK(CLK));

  // State Register, instantiate register_ce. 32 state state machine
  flopenr #(5)  state_reg
    (.d(w_next_state),
     .q(r_curr_state),
     .en(1'b1),
     .reset(i_RST),
     .clk(CLK));
  
  // Error register : indicates what type of fatal error occured for interrupt
  flopenr #(3) error_reg
    (.d(w_ERROR_CODE_D),
     .q(r_ERROR_CODE_Q),
     .en(w_ERROR_CODE_EN),
     .reset(w_ERROR_CODE_RST),
     .clk(CLK));

  assign o_ERROR_CODE_Q = r_ERROR_CODE_Q;

  assign w_next_state = i_RST ? s_reset_clear_error_reg :
		  
                  ((r_curr_state == s_reset_clear_error_reg) |
                   (r_curr_state == s_Error_TX_Failed) |
                   (r_curr_state == s_error_no_response) |
                   (r_curr_state == s_error_bad_card) |
                   (r_curr_state == s_error_dat_time_out)) ? s_reset_from_error :


                  ((r_curr_state == s_reset_from_error) |
                   ((r_curr_state == s_idle_supply_no_clk) & (i_TIMER_OUT > 0))) ? s_idle_supply_no_clk :

                  (((r_curr_state == s_idle_supply_no_clk) & (i_TIMER_OUT == 0)) |
                   ((r_curr_state == s_idle_supply_sd_clk) & (i_COUNTER_OUT > 0))) ? s_idle_supply_sd_clk :
                  
		  (r_curr_state == s_ld_head) ? s_count_attempt : 

		  (((r_curr_state == s_count_attempt) & (r_fail_count_out <= (c_MAX_ATTEMPTS-1))) | 
                   ((r_curr_state == s_count_attempt) & 
                    (((i_IC_OUT == 2) & (i_OPCODE[5:0] == c_App_Command)) |
                     ((i_IC_OUT == 3) & (i_OPCODE == ({c_ACMD, c_SD_Send_OCR}))))   // to work CMD55, ACMD41 MUST be lines 2, 3 of instruction fetch mux of sd_top.vhd
                                                     & (w_ACMD41_times_out_FLAG)
                                                     & (r_fail_count_out > (c_MAX_ATTEMPTS-1)))) ? s_tx_head : 

		  ((r_curr_state == s_count_attempt) & (r_fail_count_out > (c_MAX_ATTEMPTS-1))) ? s_Error_TX_Failed :

		  ((r_curr_state == s_tx_head) | ((r_curr_state == s_ld_tail) & (i_COUNTER_OUT > 8))) ? s_ld_tail : 

		  (((r_curr_state == s_ld_tail) & (i_COUNTER_OUT == 8)) | 
                   ((r_curr_state == s_tx_tail) & (i_COUNTER_OUT > 0))) ? s_tx_tail : 

		  (r_curr_state == s_tx_tail) & (i_COUNTER_OUT == 0) ? s_setup_rx : 
		    
                  (((r_curr_state == s_setup_rx) & (i_R_TYPE == c_response_type_R0_NONE)) |
                   ((r_curr_state == s_idle_ncc) & (i_COUNTER_OUT > 0))) ? s_idle_ncc :

                  (((r_curr_state == s_setup_rx) & (i_R_TYPE != c_response_type_R0_NONE)) |
                   ((r_curr_state == s_idle_for_start_bit) & (i_SD_CMD_RX != c_start_bit) & 
                    (i_COUNTER_OUT > 0))) ? s_idle_for_start_bit : 

                  ((r_curr_state == s_idle_for_start_bit) & (i_SD_CMD_RX != c_start_bit) & 
                   (i_COUNTER_OUT == 0)) ? s_error_no_response :

                  (((r_curr_state == s_idle_for_start_bit) & (i_SD_CMD_RX == c_start_bit) & 
                    (i_COUNTER_OUT >= 0) & (i_R_TYPE == c_response_type_R2_CID_CSD)) | 
                   ((r_curr_state == s_rx_136) & (i_COUNTER_OUT > 0))) ? s_rx_136 :

                  (((r_curr_state == s_idle_for_start_bit) & (i_SD_CMD_RX == c_start_bit) & 
                    (i_COUNTER_OUT >= 0) & (i_R_TYPE != c_response_type_R2_CID_CSD)) | 
                   ((r_curr_state == s_rx_48) & (i_COUNTER_OUT > 0))) ? s_rx_48 :

                  (((r_curr_state == s_rx_136) & (i_COUNTER_OUT == 0)) | 
                   ((r_curr_state == s_rx_48) & (i_COUNTER_OUT) == 0)) ? s_study_response :

                  (r_curr_state == s_study_response) & w_bad_card ? s_error_bad_card :

                  (((r_curr_state == s_study_response) & (~w_bad_card) & (i_USES_DAT != c_DAT_none)) |
                   ((r_curr_state == s_idle_for_dat) & (~i_DAT_RX_DONE))) ? s_idle_for_dat :

                  ((r_curr_state == s_idle_for_dat) & (i_DAT_RX_DONE) & (i_ERROR_DAT_TIMES_OUT)) ? s_error_dat_time_out :

                  (((r_curr_state == s_idle_for_dat) & (i_DAT_RX_DONE) &
                                                  (~i_ERROR_DAT_TIMES_OUT)) | 
                                                ((r_curr_state == s_study_response) & (~w_bad_card) &
                                                  (i_USES_DAT == c_DAT_none)) |
                                                ((r_curr_state == s_idle_nrc) & (i_COUNTER_OUT > 0))) ? s_idle_nrc :

                  ((r_curr_state == s_idle_nrc) & (i_COUNTER_OUT == 0) & 
                                                 (w_resend_last_command) & ((i_OPCODE[6] == c_ACMD) & 
                                                 ((i_OPCODE[5:0]) != c_App_Command))) ? s_fetch_prev_cmd :

                  ((r_curr_state == s_fetch_prev_cmd) |
                   ((r_curr_state == s_idle_supply_sd_clk) & (i_COUNTER_OUT == 0)) | 
                   ((r_curr_state == s_fetch_next_cmd) & // before CMD17
                    (i_IC_OUT < 9)) |        // blindly load head of next command
                   ((r_curr_state == s_idle_for_read_request) & (i_READ_REQUEST)) | // got the request, load head
                   ((r_curr_state == s_idle_nrc) & (i_COUNTER_OUT == 0) & 
                    (w_resend_last_command) & ((i_OPCODE[6] == c_CMD) |
                                               ((i_OPCODE[5:0]) == c_App_Command)))) ? s_ld_head :

                  (((r_curr_state == s_idle_nrc) & (i_COUNTER_OUT == 0) &
                    (~w_resend_last_command) & ((i_OPCODE) == ({c_CMD, c_Switch_Function}))) |
                   ((r_curr_state == s_idle_for_clock_change) & (~i_CLOCK_CHANGE_DONE))) ? s_idle_for_clock_change :

                  (((r_curr_state == s_idle_ncc) & (i_COUNTER_OUT == 0)) | 
                   ((r_curr_state == s_idle_nrc) & (i_COUNTER_OUT == 0) & 
                    (~w_resend_last_command) & ((i_OPCODE) != ({c_CMD, c_Switch_Function}))) | 
                   ((r_curr_state == s_idle_for_clock_change) & (i_CLOCK_CHANGE_DONE))) ? s_fetch_next_cmd :
                  
                  (((r_curr_state == s_fetch_next_cmd) &
                    (i_IC_OUT >= 9)) | // During and after CMD17, wait for request to send CMD17 from core
                                                                                 // waiting for request
                   (r_curr_state == s_idle_for_read_request)) ? s_idle_for_read_request :

                  s_reset_clear_error_reg;
		 

		  

  

  // state outputs
  assign w_ACMD41_busy_timer_START = ((r_curr_state == s_count_attempt) & (i_OPCODE == {c_ACMD, c_SD_Send_OCR}) & (r_fail_count_out == 1));

  assign w_ACMD41_busy_timer_RST = ((r_curr_state == s_reset_from_error) | (w_ACMD41_init_done));
  
  // Error Register
  assign w_ERROR_CODE_RST = (r_curr_state == s_reset_clear_error_reg);
  
  assign w_ERROR_CODE_EN = (r_curr_state == s_error_bad_card) | (r_curr_state == s_error_no_response) | (r_curr_state == s_Error_TX_Failed) | (r_curr_state == s_error_dat_time_out);

  assign w_ERROR_CODE_D = (r_curr_state == s_Error_TX_Failed) ? C_ERROR_EXCEED_MAX_ATTEMPTS :  // give up
                    (r_curr_state == s_error_bad_card) ? C_ERROR_BAD_CARD_STATUS :  // card is damaged or unsupported
                    (r_curr_state == s_error_no_response) ? C_ERROR_NO_CMD_RESPONSE :  // no response was received on CMD line
                    (r_curr_state == s_error_dat_time_out) ? c_ERROR_NO_DAT_RESPONSE :  // no data packet was received on DAT bus
                    c_NO_ERRORS;        // all is well
  
  // Failure counter
  assign w_fail_count_rst = ((r_curr_state == s_reset_from_error) | (r_curr_state == s_fetch_next_cmd & i_OPCODE[5:0] != c_App_Command));
  
  
  assign w_fail_cnt_en = ((r_curr_state == s_count_attempt) & (i_OPCODE[6] != c_ACMD | i_OPCODE[5:0] == c_App_Command));
    //                             & (i_OPCODE != ({c_ACMD, c_SD_Send_OCR})) else  // NOT ACMD41, it can take up to 1 second
      
  // Timer module
  assign o_TIMER_EN = (r_curr_state == s_idle_supply_no_clk);

  assign o_TIMER_LOAD = (r_curr_state == s_reset_from_error);
  
  assign o_TIMER_IN = (r_curr_state == s_reset_from_error) ? Timer_In : '0;

  // Clock selection/gater module(s) ...
  assign o_SD_CLK_EN = ~((r_curr_state == s_reset_from_error) | (r_curr_state == s_idle_supply_no_clk) | (r_curr_state == s_idle_for_clock_change));

  assign o_START_CLOCK_CHANGE = (r_curr_state == s_idle_for_clock_change);
  
  // RCA register module
  assign o_RCA_REGISTER_RST = (r_curr_state == s_reset_from_error);
  
  assign o_RCA_REGISTER_EN = ((r_curr_state == s_idle_nrc) & (i_R_TYPE == c_response_type_R6_RCA));
  
  // Instruction counter module
  assign o_IC_RST = (r_curr_state == s_reset_from_error);
  
  //assign o_IC_EN = (r_curr_state == s_fetch_next_cmd) | (r_curr_state == s_fetch_prev_cmd);

  assign o_IC_EN = (((r_curr_state == s_fetch_next_cmd) & (i_IC_OUT < 10)) | (r_curr_state == s_fetch_prev_cmd));
  
  assign o_IC_UP_DOWN = (r_curr_state == s_fetch_prev_cmd) ? c_decrement : c_increment;

  // "Previous Command sent was CMD55, so the command I'm now sending is ACMD" module
  assign o_CMD_TX_IS_CMD55_RST = (r_curr_state == s_reset_from_error);

  assign o_CMD_TX_IS_CMD55_EN = (r_curr_state == s_ld_head);
  
  // Output signals to DAT FSM
  //o_CMD_TX_DONE = '0' when (r_curr_state == s_reset) else         // reset
  //                 '0' when (r_curr_state == s_idle_supply_no_clk) | (r_curr_state == s_idle_supply_sd_clk) else  // power up
  //                 '0' when ((r_curr_state == s_ld_head)
  //                           | (r_curr_state == s_tx_head)
  //                           | (r_curr_state == s_ld_tail)
  //                           | (r_curr_state == s_tx_tail)) else  // tx
  //                 '1';
  assign o_CMD_TX_DONE = (r_curr_state == s_setup_rx);
  
  // Counter Module
  assign o_COUNTER_LOAD = (r_curr_state == s_idle_supply_no_clk) |
                    (r_curr_state == s_ld_head) |
                    (r_curr_state == s_setup_rx) |
                    (r_curr_state == s_idle_for_start_bit) & (i_SD_CMD_RX == c_start_bit) |
                    (r_curr_state == s_rx_48) & (i_COUNTER_OUT == 0) |
                   (r_curr_state == s_rx_136) & (i_COUNTER_OUT == 0);

  assign o_COUNTER_IN = (r_curr_state == s_idle_supply_no_clk) ? 8'd73 : 
                  // | is it 73 downto 0 == 74 bits
                  (r_curr_state == s_ld_head) ? 8'd47 :  // or is it 48
                  ((r_curr_state == s_setup_rx) & (i_R_TYPE == c_response_type_R0_NONE)) ? c_NCC_min :
                  ((r_curr_state == s_setup_rx)
                   & (i_R_TYPE != c_response_type_R0_NONE)
                   & (((i_OPCODE) == ({c_CMD, c_All_Send_CID})) |
                      ((i_OPCODE) == ({c_ACMD, c_SD_Send_OCR})))) ? c_NID_max :
                  (r_curr_state == s_setup_rx) ? c_NCR_max :
                  ((r_curr_state == s_idle_for_start_bit) & (i_R_TYPE == c_response_type_R2_CID_CSD)) ? 8'd135 :  // | is it 136
                  (r_curr_state == s_idle_for_start_bit) ? 8'd46 :  // | is it not48
                 (r_curr_state == s_rx_48) | (r_curr_state == s_rx_136) ? c_NRC_min :   // | is it 8
		 8'd0;

  assign o_COUNTER_EN = (r_curr_state == s_idle_supply_sd_clk) ? 1'b1 :
                  ((r_curr_state == s_tx_head) | (r_curr_state == s_ld_tail) | (r_curr_state == s_tx_tail)) ? 1'b1 :
                  (r_curr_state == s_idle_for_start_bit) & (i_SD_CMD_RX == c_start_bit) ? 1'b0 :
                  (r_curr_state == s_idle_for_start_bit) ? 1'b1 :
                  (r_curr_state == s_rx_48) & (i_COUNTER_OUT == 0) ? 1'b0 : 
                  (r_curr_state == s_rx_48) ? 1'b1 : 
                  (r_curr_state == s_idle_nrc) ? 1'b1 :
                  (r_curr_state == s_rx_136) & (i_COUNTER_OUT == 0) ? 1'b0 :
                  (r_curr_state == s_rx_136) ? 1'b1 : 
                  (r_curr_state == s_idle_ncc) ? 1'b1 :
                  1'b0;

  // SD_CMD Tri-state Buffer Module
  assign o_SD_CMD_OE = (r_curr_state == s_idle_supply_sd_clk) ? c_TX_COMMAND :
                 ((r_curr_state == s_tx_head)
                  | (r_curr_state == s_ld_tail)
                  | (r_curr_state == s_tx_tail)) ? c_TX_COMMAND :
                 c_RX_RESPONSE;

  // Shift Registers
  // TX_PISO40 Transmit Command Head
  assign o_TX_PISO40_LOAD = (r_curr_state == s_ld_head);
  
  assign o_TX_PISO40_EN = (r_curr_state == s_tx_head) | (r_curr_state == s_ld_tail);

  // TX_CRC7_PIPO Generate Tail
  assign o_TX_CRC7_PIPO_RST = (r_curr_state == s_ld_head);
  
  assign o_TX_CRC7_PIPO_EN = (r_curr_state == s_tx_head);

  // TX_PISO8 Transmit Command Tail
  assign o_TX_PISO8_LOAD = (r_curr_state == s_ld_tail);
  
  assign o_TX_PISO8_EN = (r_curr_state == s_tx_tail);
  
  // RX_CRC7_SIPO Calculate the CRC7 of the first 47-bits of reply (should be zero)
  assign o_RX_CRC7_SIPO_RST = (r_curr_state == s_setup_rx);
  
  assign o_RX_CRC7_SIPO_EN = (r_curr_state == s_rx_48) & (i_COUNTER_OUT > 0);   // or (r_curr_state == s_rx_48_b)

  // RX_SIPO40 Content bits of response
  assign o_RX_SIPO48_RST = (r_curr_state == s_setup_rx);
  
  assign o_RX_SIPO48_EN = (r_curr_state == s_rx_48 | r_curr_state == s_rx_48);

  // Fatal Error Signal Wire
  assign o_FATAL_ERROR = (r_curr_state == s_error_bad_card) | (r_curr_state == s_error_no_response) |
                  (r_curr_state == s_Error_TX_Failed) | (r_curr_state == s_error_dat_time_out);
  
  assign o_DAT_ERROR_FD_RST = (r_curr_state == s_ld_head);
  
  // I'm debating the merit of creating yet another state for sd_cmd_fsm.vhd to go into when and if sd_dat_fsm.vhd
  // times out while waiting for start bit on the DAT bus resulting in Error_Time_Out going high in
  // sd_Dat_fsm.vhd while sd_cmd_fsm.vhd is still in s_idle_for_dat

  // TX source selection bits for mux
  assign o_TX_SOURCE_SELECT = (r_curr_state == s_idle_supply_sd_clk) ? c_tx_high : 
                        ((r_curr_state == s_ld_head)
                         | (r_curr_state == s_tx_head)
                         | (r_curr_state == s_ld_tail)) ? c_tx_head :
                        (r_curr_state == s_tx_tail) ? c_tx_tail :
                        c_tx_high;       // This occurs when not transmitting anything

  // Study Response
  assign w_rx_crc7_check = (r_curr_state == s_idle_nrc) &
                     ((i_R_TYPE != c_response_type_R0_NONE) &
                      (i_R_TYPE != c_response_type_R3_OCR) &
                      (i_R_TYPE != c_response_type_R2_CID_CSD));

  assign w_rx_index_check = (r_curr_state == s_idle_nrc) &
                      ((i_R_TYPE != c_response_type_R0_NONE) &
                       (i_R_TYPE != c_response_type_R3_OCR) &
                       (i_R_TYPE != c_response_type_R2_CID_CSD));

  assign w_redo_result = i_RESPONSE_CONTENT & i_NO_REDO_MASK;

  assign w_rx_bad_reply = ((r_curr_state == s_idle_nrc | r_curr_state == s_study_response) & (w_redo_result != i_NO_REDO_ANS));

  assign w_rx_bad_crc7 = ((r_curr_state == s_idle_nrc | r_curr_state == s_study_response) & ((w_rx_crc7_check) & (i_RX_CRC7 != 7'b0)));
  
  assign w_rx_bad_index = ((r_curr_state == s_idle_nrc | r_curr_state == s_study_response)
                    & ((w_rx_index_check) & (i_RESPONSE_INDEX != i_OPCODE[5:0])));
  
  assign w_resend_last_command = ((r_curr_state == s_idle_nrc | r_curr_state == s_study_response) &
                           ((w_rx_bad_reply) | (w_rx_bad_index) | (w_rx_bad_crc7))) |
                           ((r_curr_state == s_idle_nrc) &
                            ((i_ERROR_CRC16) &
                             ((i_USES_DAT == c_DAT_block) | (i_USES_DAT == c_DAT_wide))));

  assign w_error_result = i_RESPONSE_CONTENT & i_NO_ERROR_MASK;

  // Make assignment based on what was read from the OCR Register.
  // Bit 31, Card power up status bit: '1' == SD Flash Card power up procedure is finished.
  //                                   '0' == SD Flash Card power up procedure is not finished. 
  // Bit 30, Card capacity status bit: '1' == Extended capacity card is in use (64 GB in size or greater).
  //                                   '0' == Extended capacity card is not in use.       
  assign w_ACMD41_init_done = ((i_IC_OUT == 3) & (i_OPCODE == ({c_ACMD, c_SD_Send_OCR}))) &
                       (~w_rx_bad_reply) & (r_curr_state == s_study_response);

  assign w_bad_card = ((r_curr_state == s_study_response) & (w_error_result != i_NO_ERROR_ANS) &
                ((~w_ACMD41_times_out_FLAG) | (w_ACMD41_init_done)));

  // Communication with core
  assign o_READY_FOR_READ = (r_curr_state == s_idle_for_read_request);
  
  assign o_SD_RESTARTING = (r_curr_state == s_Error_TX_Failed) |
                    (r_curr_state == s_error_dat_time_out) |
                    (r_curr_state == s_error_bad_card) |
                    (r_curr_state == s_error_no_response);
  

  
  
endmodule

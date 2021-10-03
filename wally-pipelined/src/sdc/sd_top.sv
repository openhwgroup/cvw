///////////////////////////////////////////
// sd_top.sv
//
// Written: Ross Thompson September 19, 2021
// Modified: 
//
// Purpose: SD card controller
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

module sd_top #(parameter g_COUNT_WIDTH = 8)
  (
   input logic 			   CLK, // 1.2 GHz (1.0 GHz typical)
   input logic 			   a_RST, // Reset signal (Must be held for minimum of 24 clock cycles)
   // a_RST MUST COME OUT OF RESET SYNCHRONIZED TO THE 1.2 GHZ CLOCK!
   // io_SD_CMD_z    : inout std_logic;   // SD CMD Bus
   (* mark_debug = "true" *)input logic 			   i_SD_CMD, // CMD Response from card
   (* mark_debug = "true" *)output logic 		   o_SD_CMD, // CMD Command from host
   (* mark_debug = "true" *)output logic 		   o_SD_CMD_OE, // Direction of SD_CMD
   (* mark_debug = "true" *)input logic [3:0] 		   i_SD_DAT, // SD DAT Bus
   (* mark_debug = "true" *)output logic 		   o_SD_CLK, // SD CLK Bus
   // For communication with core cpu
   input logic [32:9] 		   i_BLOCK_ADDR, // see "Addressing" in parts.fods (only 8GB total capacity is used)
   output logic 		   o_READY_FOR_READ, // tells core that initialization sequence is completed and
   // sd card is ready to read a 512 byte block to the core.
   // Held high during idle until i_READ_REQUEST is received
   output logic 		   o_SD_RESTARTING, // inform core the need to restart
  
   input logic 			   i_READ_REQUEST, // After Ready for read is sent to the core, the core will
   // pulse this bit high to indicate it wants the block at this address
   output logic [3:0] 		   o_DATA_TO_CORE, // nibble being sent to core when DATA block is
   output logic [4095:0] 	   ReadData, // full 512 bytes to Bus
   // being published
   output logic 		   o_DATA_VALID, // held high while data being read to core to indicate that it is valid
   output logic 		   o_LAST_NIBBLE, // pulse when last nibble is sent
   output logic [2:0] 		   o_ERROR_CODE_Q, // indicates which error occured
   output logic 		   o_FATAL_ERROR, // indicates that the FATAL ERROR register has updated
   // For tuning
   input logic [g_COUNT_WIDTH-1:0] i_COUNT_IN_MAX,
   input logic 			   LIMIT_SD_TIMERS
   );

  localparam logic 		   c_CMD = 1'b0;
  localparam logic 		   c_ACMD = 1'b1;

  // packet bit names
  localparam logic 		   c_start_bit = 1'b0;  // bit 47
  localparam logic 		   c_stop_bit = 1'b1;  // bit 0, AKA "end bit"
  // transmitter bit, bit 46
  localparam logic 		   c_tx_host_command = 1'b1;
  localparam logic 		   c_tx_card_response = 1'b0;

  // response types
  localparam logic [2:0] 	   c_response_type_R0_NONE = 3'd0;
  localparam logic [2:0] 	   c_response_type_R1_NORMAL = 3'd1;
  localparam logic [2:0] 	   c_response_type_R2_CID_CSD = 3'd2;
  localparam logic [2:0] 	   c_response_type_R3_OCR = 3'd3;
  localparam logic [2:0] 	   c_response_type_R6_RCA = 3'd6;
  localparam logic [2:0] 	   c_response_type_R7_CIC = 3'd7;

  // uses dat
  localparam logic [1:0] 	   c_DAT_none = 2'b00;
  localparam logic [1:0] 	   c_DAT_busy = 2'b01;
  localparam logic [1:0] 	   c_DAT_wide = 2'b10;
  localparam logic [1:0] 	   c_DAT_block = 2'b11;

  // tx source selection
  localparam logic [1:0] 	   c_tx_low =   2'b00; 
  localparam logic [1:0] 	   c_tx_high =  2'b01; 
  localparam logic [1:0] 	   c_tx_head =  2'b10; 
  localparam logic [1:0] 	   c_tx_tail   = 2'b11;

  // command indexes
  localparam logic [45:40] 	   c_Go_Idle_State = 6'd00;  //  CMD0
  localparam logic [45:40] 	   c_All_Send_CID = 6'd02;  //  CMD2
  localparam logic [45:40] 	   c_SD_Send_RCA = 6'd03;  //  CMD3
  localparam logic [45:40] 	   c_Switch_Function = 6'd06;  //  CMD6
  localparam logic [45:40] 	   c_Set_Bus_Width = 6'd06;  // ACMD6
  localparam logic [45:40] 	   c_Select_Card = 6'd07;  //  CMD7
  localparam logic [45:40] 	   c_Send_IF_State = 6'd08;  //  CMD8
  localparam logic [45:40] 	   c_Read_Single_Block = 6'd17;  //  CMD17
  localparam logic [45:40] 	   c_SD_Send_OCR = 6'd41;  // ACMD41
  localparam logic [45:40] 	   c_App_Command = 6'd55;  //  CMD55

  // bitmasks
  localparam logic [127:96] 	   c_CMD0_mask_check_redo_bits = 32'h00000000;  // Go_Idle_State
  localparam logic [127:96] 	   c_CMD0_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD0_mask_check_error_bits = 32'h00000000;
  localparam logic [127:96] 	   c_CMD0_ans_error_free = 32'h00000000;

  localparam logic [127:96] 	   c_CMD2_mask_check_redo_bits = 32'h00000000;  // All_Send_CID
  localparam logic [127:96] 	   c_CMD2_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD2_mask_check_error_bits = 32'h00000000;
  localparam logic [127:96] 	   c_CMD2_ans_error_free = 32'h00000000;

  localparam logic [127:96] 	   c_CMD3_mask_check_redo_bits = 32'h00000000;  // SD_Send_RCA
  localparam logic [127:96] 	   c_CMD3_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD3_mask_check_error_bits = 32'h00002000;
  localparam logic [127:96] 	   c_CMD3_ans_error_free = 32'h00000000;

  localparam logic [127:96] 	   c_CMD6_mask_check_redo_bits = 32'h00000000;  // Switch_Function
  localparam logic [127:96] 	   c_CMD6_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD6_mask_check_error_bits = 32'h82380000;
  localparam logic [127:96] 	   c_CMD6_ans_error_free = 32'h00000000;

  localparam logic [127:96] 	   c_ACMD6_mask_check_redo_bits = 32'h00000000;  // Set_Bus_Width
  localparam logic [127:96] 	   c_ACMD6_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_ACMD6_mask_check_error_bits = 32'h8F398020;
  localparam logic [127:96] 	   c_ACMD6_ans_error_free = 32'h00000020;

  localparam logic [127:96] 	   c_CMD7_mask_check_redo_bits = 32'h00000000;  // Select_Card
  localparam logic [127:96] 	   c_CMD7_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD7_mask_check_error_bits = 32'h0F398000;
  localparam logic [127:96] 	   c_CMD7_ans_error_free = 32'h00000000;

  localparam logic [127:96] 	   c_CMD8_mask_check_redo_bits = 32'h00000000;  //  Send_IF_State
  localparam logic [127:96] 	   c_CMD8_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD8_mask_check_error_bits = 32'h00000FFF;
  localparam logic [127:96] 	   c_CMD8_ans_error_free = 32'h000001FF;

  localparam logic [127:96] 	   c_CMD17_mask_check_redo_bits = 32'h00000000;  // Read_Single_Block
  localparam logic [127:96] 	   c_CMD17_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD17_mask_check_error_bits = 32'hCF398000;
  localparam logic [127:96] 	   c_CMD17_ans_error_free = 32'h00000000;

  localparam logic [127:96] 	   c_ACMD41_mask_check_redo_bits = 32'h80000000;  // SD_Send_OCR
  localparam logic [127:96] 	   c_ACMD41_ans_dont_redo = 32'h80000000;
  localparam logic [127:96] 	   c_ACMD41_mask_check_error_bits = 32'h01FF8000; // 32'h41FF8000;
  localparam logic [127:96] 	   c_ACMD41_ans_error_free = 32'h00FF8000; // 32'h40FF8000

  localparam logic [127:96] 	   c_CMD55_mask_check_redo_bits = 32'h00000000;  // App_Command
  localparam logic [127:96] 	   c_CMD55_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_CMD55_mask_check_error_bits = 32'h0F398000;
  localparam logic [127:96] 	   c_CMD55_ans_error_free = 32'h00000000;

  localparam logic [127:96] 	   c_ACMD55_mask_check_redo_bits = 32'h00000000;  // App_Command
  localparam logic [127:96] 	   c_ACMD55_ans_dont_redo = 32'h00000000;
  localparam logic [127:96] 	   c_ACMD55_mask_check_error_bits = 32'h0F398000;
  localparam logic [127:96] 	   c_ACMD55_ans_error_free = 32'h00000000;

  // SD_CMD_FSM Connections
  (* mark_debug = "true" *)logic 			   w_TIMER_LOAD, w_TIMER_EN;
  (* mark_debug = "true" *)logic [18:0] 			   w_TIMER_IN;
  (* mark_debug = "true" *)logic [18:0] 			   r_TIMER_OUT;
  (* mark_debug = "true" *)logic 			   w_COUNTER_LOAD, w_COUNTER_EN;
  (* mark_debug = "true" *)logic [7:0] 			   w_COUNTER_IN;
  (* mark_debug = "true" *)logic [7:0] 			   r_COUNTER_OUT;
  (* mark_debug = "true" *)logic 			   w_SD_CLK_EN;
  (* mark_debug = "true" *)logic 			   w_CLOCK_CHANGE_DONE, w_START_CLOCK_CHANGE;  // to clk fsm
  (* mark_debug = "true" *)logic 			   w_HS_TO_INIT_CLK_DIVIDER_RST;
  (* mark_debug = "true" *)logic 			   w_IC_RST, w_IC_EN, w_IC_UP_DOWN;
  //logic w_USES_DAT                            : std_logic_vector(1 downto 0);
  //logic w_OPCODE_Q                              : std_logic_vector(6 downto 0);
  //logic w_R_TYPE                              : std_logic_vector(2 downto 0);
  //logic w_NO_REDO_MASK                        : std_logic_vector(31 downto 0);
  //logic w_NO_REDO_ANS                         : std_logic_vector(31 downto 0);
  //logic w_NO_ERROR_MASK                       : std_logic_vector(31 downto 0);
  //logic w_NO_ERROR_ANS                        : std_logic_vector(31 downto 0);
  (* mark_debug = "true" *)logic 			   w_SD_CMD_OE;
  //logic w_SD_CMD_IE                           : std_logic;  // tri-state buffer - input enable (for simulation only)
  (* mark_debug = "true" *)logic 			   w_TX_PISO40_LOAD, w_TX_PISO40_EN;
  (* mark_debug = "true" *)logic 			   w_TX_PISO8_LOAD, w_TX_PISO8_EN;
  (* mark_debug = "true" *)logic 			   w_TX_CRC7_PIPO_RST, w_TX_CRC7_PIPO_EN;
  (* mark_debug = "true" *)logic [1:0] 			   w_TX_SOURCE_SELECT;
  (* mark_debug = "true" *)logic 			   w_CMD_TX_IS_CMD55_RST;
  (* mark_debug = "true" *)logic 			   w_CMD_TX_IS_CMD55_EN;
  //logic w_CMD_RX;
  (* mark_debug = "true" *)logic 			   w_RX_SIPO48_RST, w_RX_SIPO48_EN;
  (* mark_debug = "true" *)logic [39:8] 			   r_RESPONSE_CONTENT;
  (* mark_debug = "true" *)logic [45:40] 		   r_RESPONSE_INDEX;
  (* mark_debug = "true" *)logic 			   w_RX_CRC7_SIPO_RST, w_RX_CRC7_SIPO_EN;
  (* mark_debug = "true" *)logic [6:0] 			   r_RX_CRC7_Q;
  (* mark_debug = "true" *)logic 			   w_RCA_REGISTER_RST, w_RCA_REGISTER_EN;
  (* mark_debug = "true" *)logic 			   w_CMD_TX_DONE;
  (* mark_debug = "true" *)logic 			   w_DAT_RX_DONE;
  (* mark_debug = "true" *)logic 			   w_DAT_ERROR_FD_RST_DAT, w_DAT_ERROR_FD_RST_CMD, w_DAT_ERROR_FD_RST, w_DAT_ERROR_FD_EN;
  (* mark_debug = "true" *)logic 			   r_DAT_ERROR_Q;     // CRC16 error or time out
  (* mark_debug = "true" *)logic 			   w_NOT_DAT_ERROR_Q;  // '0'=no error, '1'=tx error on DAT bus
  (* mark_debug = "true" *)logic 			   w_ERROR_DAT_TIMES_OUT;
  (* mark_debug = "true" *)logic 			   w_FATAL_ERROR;
  (* mark_debug = "true" *)logic [2:0] 			   r_ERROR_CODE_Q;  // indicates which fatal error occured

  // Communication with core
  (* mark_debug = "true" *)logic 			   w_READY_FOR_READ;
  (* mark_debug = "true" *)logic 			   w_READ_REQUEST;
  (* mark_debug = "true" *)logic [3:0] 			   r_DATA_TO_CORE;
  (* mark_debug = "true" *)logic 			   w_DATA_VALID;
  (* mark_debug = "true" *)logic 			   w_LAST_NIBBLE;

  //SD_DAT_FSM Connections
  (* mark_debug = "true" *)logic 			   w_DAT_TIMER_LOAD, w_DAT_TIMER_EN;
  (* mark_debug = "true" *)logic 			   w_DAT_COUNTER_RST, w_DAT_COUNTER_EN;
  (* mark_debug = "true" *)logic 			   w_CRC16_EN, w_CRC16_RST;
  (* mark_debug = "true" *)logic 			   w_BUSY_RST, w_BUSY_EN;
  (* mark_debug = "true" *)logic 			   w_NIBO_EN;
  (* mark_debug = "true" *)logic 			   w_DATA_CRC16_GOOD;
  (* mark_debug = "true" *)logic 			   w_VALID_BLOCK_D, w_VALID_BLOCK_EN, w_VALID_WIDE_D, w_VALID_WIDE_EN;
  (* mark_debug = "true" *)logic [22:0] 			   w_DAT_TIMER_IN;
  (* mark_debug = "true" *)logic [22:0] 			   r_DAT_TIMER_OUT;
  (* mark_debug = "true" *)logic [10:0] 			   r_DAT_COUNTER_OUT;
  (* mark_debug = "true" *)logic [3:0] 			   r_DAT_Q;

  // RCA Register
  (* mark_debug = "true" *)logic [15:0] 			   w_RCA_D_Q;
  (* mark_debug = "true" *)logic [15:0] 			   r_RCA_Q2;

  // Multiplexer Logics
  (* mark_debug = "true" *) logic [132:0] 		   w_instruction_control_bits;
  (* mark_debug = "true" *)logic [132:130] 		   w_R_TYPE                  ;
  (* mark_debug = "true" *)logic [129:128] 		   w_USES_DAT                ;
  (* mark_debug = "true" *)logic [127:96] 		   w_NO_REDO_MASK            ;
  (* mark_debug = "true" *)logic [95:64] 		   w_NO_REDO_ANS             ;
  (* mark_debug = "true" *)logic [63:32] 		   w_NO_ERROR_MASK           ;
  (* mark_debug = "true" *)logic [31:0] 			   w_NO_ERROR_ANS            ;
  (* mark_debug = "true" *)logic [45:40] 		   w_command_index           ;
  (* mark_debug = "true" *)logic [39:8] 			   w_command_arguments       ;
  (* mark_debug = "true" *)logic [47:8] 			   w_command_head            ;
  (* mark_debug = "true" *)logic [6:0] 			   w_OPCODE_Q                ;

  // TOP_LEVEL Connections
  (* mark_debug = "true" *)logic [40:9] 			   w_BLOCK_ADDR                     ;
  (* mark_debug = "true" *)logic [3:0] 			   r_IC_OUT                         ;
  (* mark_debug = "true" *)logic [2:0] 			   r_command_index_is_55_history    ;  // [0] is live index, [1] is currently saved index, [2] is index of previous command
  (* mark_debug = "true" *)logic 			   r_previous_command_index_was_55_q;  // is index of previous command 55, wired to r_command_index_is_55_history[2]
  (* mark_debug = "true" *)logic 			   r_ACMD_Q;  // if the previous command sent to the SD card successfully had index 55, then the SD card thinks the current command is ACMD
  (* mark_debug = "true" *)logic [4095:0] 		   r_block_data                     ;  // data block from CMD17

  // TX
  (* mark_debug = "true" *)logic [45:8] 			   w_command_content;                  // first 40 bits of command packet
  (* mark_debug = "true" *)logic 			   w_tx_head_Q;            // transmission of first part of command packet
  (* mark_debug = "true" *)logic 			   w_tx_tail_Q;            // transmission of last part of command packet
  (* mark_debug = "true" *)logic [7:0] 			   r_command_tail;  // last 8 bits of command packet
  (* mark_debug = "true" *)logic [6:0] 			   r_TX_CRC7;
  //logic w_TX_Q:= '0';  // actual transmission when tx is enabled

  // RX
  (* mark_debug = "true" *)logic [47:0] 			   r_RX_RESPONSE;

  // Tri state IO Driver BC18MIMS
  (* mark_debug = "true" *)logic 			   w_SD_CMD_TX_Q;  // Write Data
  (* mark_debug = "true" *) logic 			   w_SD_CMD_RX;         // Read Data


  // CLOCKS
  //logic r_CLK_HS := '0';  // 50 MHz Divided Clock [static]
  //logic r_SD_CLK_ungated := '0';  // Selected clock before it is clock gated

  //logic r_SD_CLK := '0';  // GATED CLOCKS
  (* mark_debug = "true" *)logic 			   r_TO_SD_CLK;  // What is actually sent to the SD card

  (* mark_debug = "true" *)logic 			   w_G_CLK_SD_EN;
  (* mark_debug = "true" *)logic 			   r_CLK_SD, r_G_CLK_SD;              // clocks
  (* mark_debug = "true" *)logic 			   r_G_CLK_SD_n;
  (* mark_debug = "true" *)logic [15:0] 			   r_CLK_FSM_RST                 ;  // a_rst logic delayed by one 1.2 GHz period
  (* mark_debug = "true" *)logic 			   w_SD_CLK_SELECTED;

  //DAT FSM Connections
  (* mark_debug = "true" *)logic [15:0] 			   r_DAT3_CRC16, r_DAT2_CRC16, r_DAT1_CRC16;
  (* mark_debug = "true" *)logic [15:0] 			   r_DAT0_CRC16;
  
  
  assign w_BLOCK_ADDR = {8'h00, i_BLOCK_ADDR};  // (40 downto 36 are zero since card is 64 GB)
                                       // (35 downto 32 are zero since memeory is only 8GB total)

  assign o_READY_FOR_READ = w_READY_FOR_READ;
  assign w_READ_REQUEST   = i_READ_REQUEST;
  assign o_DATA_TO_CORE   = r_DATA_TO_CORE;
  assign o_DATA_VALID     = w_DATA_VALID;
  assign o_LAST_NIBBLE    = (w_LAST_NIBBLE | w_FATAL_ERROR);  // indicate done if (last nibble OR Fatal Error go high)
  assign o_FATAL_ERROR    = w_FATAL_ERROR;

    sd_cmd_fsm my_sd_cmd_fsm
    (
      .CLK(r_G_CLK_SD),
      .i_RST(a_RST),
      .o_TIMER_LOAD(w_TIMER_LOAD),
      .o_TIMER_EN(w_TIMER_EN),
      .o_TIMER_IN(w_TIMER_IN),
      .i_TIMER_OUT(r_TIMER_OUT),
      .o_COUNTER_LOAD(w_COUNTER_LOAD),
      .o_COUNTER_EN(w_COUNTER_EN),
      .o_COUNTER_IN(w_COUNTER_IN),
      .i_COUNTER_OUT(r_COUNTER_OUT),
      .o_SD_CLK_EN(w_SD_CLK_EN),
      .i_CLOCK_CHANGE_DONE(w_CLOCK_CHANGE_DONE),
      .o_START_CLOCK_CHANGE(w_START_CLOCK_CHANGE),
      .o_IC_RST(w_IC_RST),
      .o_IC_EN(w_IC_EN),
      .o_IC_UP_DOWN(w_IC_UP_DOWN),
      .i_IC_OUT(r_IC_OUT),
      .i_USES_DAT(w_USES_DAT),
      .i_OPCODE(w_OPCODE_Q),
      .i_R_TYPE(w_R_TYPE),
      .i_NO_REDO_MASK(w_NO_REDO_MASK),
      .i_NO_REDO_ANS(w_NO_REDO_ANS),
      .i_NO_ERROR_MASK(w_NO_ERROR_MASK),
      .i_NO_ERROR_ANS(w_NO_ERROR_ANS),
      .o_SD_CMD_OE(w_SD_CMD_OE),
      .o_TX_PISO40_LOAD(w_TX_PISO40_LOAD),
      .o_TX_PISO40_EN(w_TX_PISO40_EN),
      .o_TX_PISO8_LOAD(w_TX_PISO8_LOAD),
      .o_TX_PISO8_EN(w_TX_PISO8_EN),
      .o_TX_CRC7_PIPO_RST(w_TX_CRC7_PIPO_RST),
      .o_TX_CRC7_PIPO_EN(w_TX_CRC7_PIPO_EN),
      .o_TX_SOURCE_SELECT(w_TX_SOURCE_SELECT),
      .o_CMD_TX_IS_CMD55_RST(w_CMD_TX_IS_CMD55_RST),
      .o_CMD_TX_IS_CMD55_EN(w_CMD_TX_IS_CMD55_EN),
      .i_SD_CMD_RX(w_SD_CMD_RX),
      .o_RX_SIPO48_RST(w_RX_SIPO48_RST),
      .o_RX_SIPO48_EN(w_RX_SIPO48_EN),
      .i_RESPONSE_CONTENT(r_RESPONSE_CONTENT),
      .i_RESPONSE_INDEX(r_RESPONSE_INDEX),
      .o_RX_CRC7_SIPO_RST(w_RX_CRC7_SIPO_RST),
      .o_RX_CRC7_SIPO_EN(w_RX_CRC7_SIPO_EN),
      .i_RX_CRC7(r_RX_CRC7_Q),
      .o_RCA_REGISTER_RST(w_RCA_REGISTER_RST),
      .o_RCA_REGISTER_EN(w_RCA_REGISTER_EN),
      .o_CMD_TX_DONE(w_CMD_TX_DONE),
      .i_DAT_RX_DONE(w_DAT_RX_DONE),
      .i_ERROR_CRC16(w_NOT_DAT_ERROR_Q),
      .i_ERROR_DAT_TIMES_OUT(w_ERROR_DAT_TIMES_OUT),
      .i_READ_REQUEST(w_READ_REQUEST),
      .o_READY_FOR_READ(w_READY_FOR_READ),
      .o_SD_RESTARTING(o_SD_RESTARTING),
      .o_DAT_ERROR_FD_RST(w_DAT_ERROR_FD_RST_CMD),
      .o_ERROR_CODE_Q(r_ERROR_CODE_Q),
      .o_FATAL_ERROR(w_FATAL_ERROR),
      .LIMIT_SD_TIMERS(LIMIT_SD_TIMERS));

  assign o_ERROR_CODE_Q = r_ERROR_CODE_Q;
  
  sd_dat_fsm my_sd_dat_fsm
    (.CLK(r_G_CLK_SD),
    .i_RST(a_RST),
    .o_TIMER_LOAD(w_DAT_TIMER_LOAD),
    .o_TIMER_EN(w_DAT_TIMER_EN),
    .o_TIMER_IN(w_DAT_TIMER_IN),
    .i_TIMER_OUT(r_DAT_TIMER_OUT),
    .i_SD_CLK_SELECTED(w_SD_CLK_SELECTED),
    .o_COUNTER_RST(w_DAT_COUNTER_RST),
    .o_COUNTER_EN(w_DAT_COUNTER_EN),
    .i_COUNTER_OUT(r_DAT_COUNTER_OUT),
    .o_CRC16_EN(w_CRC16_EN),
    .o_CRC16_RST(w_CRC16_RST),
    .i_DATA_CRC16_GOOD(w_DATA_CRC16_GOOD),
    .o_BUSY_RST(w_BUSY_RST),
    .o_BUSY_EN(w_BUSY_EN),
    .i_DAT0_Q(r_DAT_Q[0]),
    .o_NIBO_EN(w_NIBO_EN),
    .i_USES_DAT(w_USES_DAT),
    .i_CMD_TX_DONE(w_CMD_TX_DONE),
    .o_DAT_RX_DONE(w_DAT_RX_DONE),
    .o_ERROR_DAT_TIMES_OUT(w_ERROR_DAT_TIMES_OUT),
    .o_DATA_VALID(w_DATA_VALID),
    .o_LAST_NIBBLE(w_LAST_NIBBLE),
    .o_DAT_ERROR_FD_RST(w_DAT_ERROR_FD_RST_DAT),
    .o_DAT_ERROR_FD_EN(w_DAT_ERROR_FD_EN),
    .LIMIT_SD_TIMERS(LIMIT_SD_TIMERS));

  assign w_DAT_ERROR_FD_RST = w_DAT_ERROR_FD_RST_CMD | w_DAT_ERROR_FD_RST_DAT;

  flopenr #(1) dat_error_fd
    (.clk(r_G_CLK_SD),
    .d(w_DATA_CRC16_GOOD),
    .q(r_DAT_ERROR_Q),
    .en(w_DAT_ERROR_FD_EN),
    .reset((w_DAT_ERROR_FD_RST)));
  
  assign w_NOT_DAT_ERROR_Q = ~r_DAT_ERROR_Q;

  up_down_counter #(23) dat_fsm_timer
    (
    .CountIn(w_DAT_TIMER_IN),
    .CountOut(r_DAT_TIMER_OUT),
    .Load(w_DAT_TIMER_LOAD),
    .Enable(w_DAT_TIMER_EN),
    .UpDown(1'b0),                 // Count DOWN only
    .clk(r_G_CLK_SD),
    .reset(1'b0));                // No Reset, Just Load
  
  counter #(11) dat_nibble_counter
    (
    .CountIn('0),
    .CountOut(r_DAT_COUNTER_OUT),
    .Load(1'b0),
    .Enable(w_DAT_COUNTER_EN),
    .clk(r_G_CLK_SD),
    .reset(w_DAT_COUNTER_RST));

  regfile_p2r1w1_nibo #(.DEPTH(10), .WIDTH(4) ) regfile_cmd17_data_block  // Nibble In - Nibble Out (NINO)
    (.clk(r_G_CLK_SD),
    .we1(w_NIBO_EN),
    .ra1(r_DAT_COUNTER_OUT[9:0]),       // Nibble Read (to core) Address
    .rd1(r_DATA_TO_CORE),                    // output nibble to core
     .Rd1All(ReadData),
    .wa1(r_DAT_COUNTER_OUT[9:0]),     // Nibble Write (to host) Address
    .wd1(r_DAT_Q));                          // input nibble from card
  
  crc16_sipo_np_ce crc16_sipo_np_ce_DAT3
    (.CLK(r_G_CLK_SD),
    .RST(w_CRC16_RST),
    .i_enable(w_CRC16_EN),
    .i_message_bit(r_DAT_Q[3]),
    .o_crc16(r_DAT3_CRC16));

  crc16_sipo_np_ce crc16_sipo_np_ce_DAT2
    (.CLK(r_G_CLK_SD),
    .RST(w_CRC16_RST),
    .i_enable(w_CRC16_EN),
    .i_message_bit(r_DAT_Q[2]),
    .o_crc16(r_DAT2_CRC16));

  crc16_sipo_np_ce crc16_sipo_np_ce_DAT1
    (.CLK(r_G_CLK_SD),
    .RST(w_CRC16_RST),
    .i_enable(w_CRC16_EN),
    .i_message_bit(r_DAT_Q[1]),
    .o_crc16(r_DAT1_CRC16));

  crc16_sipo_np_ce crc16_sipo_np_ce_DAT0
    (.CLK(r_G_CLK_SD),
    .RST(w_CRC16_RST),
    .i_enable(w_CRC16_EN),
    .i_message_bit(r_DAT_Q[0]),
    .o_crc16(r_DAT0_CRC16));


  assign w_DATA_CRC16_GOOD = ({r_DAT3_CRC16, r_DAT2_CRC16, r_DAT1_CRC16, r_DAT0_CRC16}) == 64'h0000000000000000;

  flopenr #(4) busy_bit_fd
    (.en(w_BUSY_EN),
    .clk(r_G_CLK_SD),
    .d(i_SD_DAT),
    .q(r_DAT_Q),
    .reset(w_BUSY_RST));

  sd_clk_fsm my_clk_fsm
    (.CLK(CLK),
    .i_RST(a_RST),
    .o_DONE(w_CLOCK_CHANGE_DONE),
    .i_START(w_START_CLOCK_CHANGE),
    .o_HS_TO_INIT_CLK_DIVIDER_RST(w_HS_TO_INIT_CLK_DIVIDER_RST),
    .o_SD_CLK_SELECTED(w_SD_CLK_SELECTED),
    .i_FATAL_ERROR(w_FATAL_ERROR),
    .o_G_CLK_SD_EN(w_G_CLK_SD_EN));
  
    up_down_counter #(19) cmd_fsm_timer
    (.CountIn(w_TIMER_IN),
      .CountOut(r_TIMER_OUT),
      .Load(w_TIMER_LOAD),
      .Enable(w_TIMER_EN),
      .UpDown(1'b0),                 // Count DOWN only
      .clk(r_G_CLK_SD),
      .reset(1'b0));                // No Reset, Just Load

  up_down_counter #(8) cmd_fsm_counter
    (.CountIn(w_COUNTER_IN),
    .CountOut(r_COUNTER_OUT),
    .Load(w_COUNTER_LOAD),
    .Enable(w_COUNTER_EN),
    .UpDown(1'b0),                 // Count DOWN only
    .clk(r_G_CLK_SD),
    .reset(1'b0));                // No RESET, only LOAD

  up_down_counter #(4) instruction_counter
    (.CountIn('0),     // No CountIn, only RESET
    .CountOut(r_IC_OUT),
    .Load(1'b0),                // No LOAD, only RESET
    .Enable(w_IC_EN),
    .UpDown(w_IC_UP_DOWN),
    .clk(r_G_CLK_SD),
    .reset(w_IC_RST));

  // Clock selection
  clkdivider #(g_COUNT_WIDTH) slow_clk_divider        // Divide 50 MHz to <400 KHz (Initial clock)
    (.i_COUNT_IN_MAX(i_COUNT_IN_MAX),
    //.i_EN(w_SD_CLK_SELECTED),
     .i_EN(1'b1),
    .i_RST(w_HS_TO_INIT_CLK_DIVIDER_RST),
    .i_CLK(CLK),
    .o_CLK(r_CLK_SD));

  clockgater sd_clk_gater              // Select which clock goes to components
    (.CLK(r_CLK_SD),
    .E(w_G_CLK_SD_EN),
    .SE(1'b0),
    .ECLK(r_G_CLK_SD));

  clockgater to_sd_clk_gater           // Enable activity on the SD_CLK line
    (.CLK(r_G_CLK_SD),
    .E(w_SD_CLK_EN),
    .SE(1'b0),
    .ECLK(r_TO_SD_CLK));
  
  flopenr #(16) RCA_register_CE
    (.clk(r_G_CLK_SD),
    .en(w_RCA_REGISTER_EN),
    .d(w_RCA_D_Q),
    .q(r_RCA_Q2),
    .reset(w_RCA_REGISTER_RST));

  // ACMD_Detector
  flopenr #(1) index_history_fd_2to1
    (.clk(r_G_CLK_SD),
    .reset(w_CMD_TX_IS_CMD55_RST),
    .en(w_CMD_TX_IS_CMD55_EN),
    .d(r_command_index_is_55_history[2]),
    .q(r_command_index_is_55_history[1]));

  flopenr #(1) index_history_fd_1to0
    (.clk(r_G_CLK_SD),
    .reset(w_CMD_TX_IS_CMD55_RST),
    .en(w_CMD_TX_IS_CMD55_EN),
    .d(r_command_index_is_55_history[1]),
    .q(r_command_index_is_55_history[0]));



  assign r_command_index_is_55_history[2] = (w_command_index == 55);
  

  assign r_previous_command_index_was_55_q = r_command_index_is_55_history[0];
  assign r_ACMD_Q                          = r_previous_command_index_was_55_q;  // if the previous command WAS 55, the current command is ACMD

  assign o_SD_CLK = r_TO_SD_CLK;



  // Multiplexers
  //Fetch index and argument of command
  assign w_command_content = (r_IC_OUT == 0) ? ({c_Go_Idle_State, 32'h00000000}) :  // CMD0
                             (r_IC_OUT == 1) ? ({c_Send_IF_State, 32'h000001FF}) :   // CMD8
			     (r_IC_OUT == 2) ? ({c_App_Command, 32'h00000000}) :  // CMD55
                             (r_IC_OUT == 3) ? ({c_SD_Send_OCR, 32'h40FF8000}) :  // ACMD41
			     (r_IC_OUT == 4) ? ({c_All_Send_CID, 32'h00000000}) :  // CMD2
			     (r_IC_OUT == 5) ? ({c_SD_Send_RCA, 32'h00000000}) :  // CMD3
			     (r_IC_OUT == 6) ? ({c_Select_Card, r_RCA_Q2[15:0], 16'h0000}) :  // CMD7
			     (r_IC_OUT == 7) ? ({c_App_Command, r_RCA_Q2[15:0], 16'h0000}) :  // CMD55
			     (r_IC_OUT == 8) ? ({c_Set_Bus_Width, 32'h00000002}) :  // ACMD6
			     (r_IC_OUT == 9) ? ({c_Switch_Function, 32'h80FFFFF1}) :  // CMD6
			     (r_IC_OUT == 10) ? ({c_Read_Single_Block, w_BLOCK_ADDR}) :  // CMD17
			     ({c_Read_Single_Block, w_BLOCK_ADDR});  // when in doubt just send CMD17

  assign w_command_index     = w_command_content[45:40];
  assign w_command_arguments = w_command_content[39:8];
  assign w_command_head      = {c_start_bit, c_tx_host_command, w_command_content};

  assign w_OPCODE_Q = {r_ACMD_Q, w_command_index};

  // TX
  
  crc7_pipo tx_crc7_pipo 
    (.CLK(r_G_CLK_SD),
    .i_DATA(w_command_head),
    .i_CRC_ENABLE(w_TX_CRC7_PIPO_EN),
    .RST(w_TX_CRC7_PIPO_RST),
    .o_CRC(r_TX_CRC7));

  assign r_command_tail = {r_TX_CRC7, c_stop_bit};

  piso_generic_ce #(40) tx_piso40_command_head
   (.clk(r_G_CLK_SD),
    .i_load(w_TX_PISO40_LOAD),
    .i_data(w_command_head),
    .i_en(w_TX_PISO40_EN),
    .o_data(w_tx_head_Q));

  piso_generic_ce #(8) tx_piso8_command_tail
    (.clk(r_G_CLK_SD),
    .i_load(w_TX_PISO8_LOAD),
    .i_data(r_command_tail),
    .i_en(w_TX_PISO8_EN),
    .o_data(w_tx_tail_Q));
  
  assign w_SD_CMD_TX_Q = (w_TX_SOURCE_SELECT == c_tx_low) ? 1'b0 :
                   (w_TX_SOURCE_SELECT == c_tx_high) ? 1'b1 :
                   (w_TX_SOURCE_SELECT == c_tx_head) ? w_tx_head_Q : 
                   (w_TX_SOURCE_SELECT == c_tx_tail) ? w_tx_tail_Q :
                   1'b0;

  assign w_SD_CMD_RX = i_SD_CMD;
  assign r_G_CLK_SD_n = ~r_G_CLK_SD;

  flopenr #(1) sd_cmd_out_reg
    (.d(w_SD_CMD_TX_Q),
    .q(o_SD_CMD),
    .en(1'b1),
    .clk(r_G_CLK_SD_n),
    .reset(a_RST));
  
  flopenr #(1) sd_cmd_out_oe_reg
    (.d(w_SD_CMD_OE),
    .q(o_SD_CMD_OE),
    .en(1'b1),
    .clk(r_G_CLK_SD_n),
    .reset(a_RST));
  
  // RX
  sipo_generic_ce #(48) rx_sipo48_response_content
    (.clk(r_G_CLK_SD),
    .rst(w_RX_SIPO48_RST),
    .i_enable(w_RX_SIPO48_EN),
    .i_message_bit(w_SD_CMD_RX),
    .o_data(r_RX_RESPONSE));
  
  assign r_RESPONSE_CONTENT = r_RX_RESPONSE[39:8];
  assign r_RESPONSE_INDEX  = r_RX_RESPONSE[45:40];
  assign w_RCA_D_Q          = r_RESPONSE_CONTENT[39:24];

  crc7_sipo_np_ce  rx_crc7_sipo
    (.clk(r_G_CLK_SD),
    .rst(w_RX_CRC7_SIPO_RST),
    .i_enable(w_RX_CRC7_SIPO_EN),
    .i_message_bit(w_SD_CMD_RX),
    .o_crc7(r_RX_CRC7_Q));

  // Fetch control bits using r_opcode
  assign w_instruction_control_bits = (w_OPCODE_Q == ({c_CMD, c_Go_Idle_State})) ? ({c_response_type_R0_NONE, c_DAT_none, c_CMD0_mask_check_redo_bits, c_CMD0_ans_dont_redo, c_CMD0_mask_check_error_bits, c_CMD0_ans_error_free}) :  // CMD0

                                      (w_OPCODE_Q == ({c_CMD, c_All_Send_CID})) ? ({c_response_type_R2_CID_CSD, c_DAT_none, c_CMD2_mask_check_redo_bits, c_CMD2_ans_dont_redo, c_CMD2_mask_check_error_bits, c_CMD2_ans_error_free}):  // CMD2

				      (w_OPCODE_Q == ({c_CMD, c_SD_Send_RCA})) ? ({c_response_type_R6_RCA, c_DAT_none, c_CMD3_mask_check_redo_bits, c_CMD3_ans_dont_redo, c_CMD3_mask_check_error_bits, c_CMD3_ans_error_free}) : // CMD3

				      (w_OPCODE_Q == ({c_CMD, c_Switch_Function})) ? ({c_response_type_R1_NORMAL, c_DAT_wide, c_CMD6_mask_check_redo_bits, c_CMD6_ans_dont_redo, c_CMD6_mask_check_error_bits, c_CMD6_ans_error_free}):  // CMD6

				      (w_OPCODE_Q == ({c_ACMD, c_Set_Bus_Width})) ? ({c_response_type_R1_NORMAL, c_DAT_none, c_ACMD6_mask_check_redo_bits, c_ACMD6_ans_dont_redo, c_ACMD6_mask_check_error_bits, c_ACMD6_ans_error_free}):  //ACMD6

				      (w_OPCODE_Q == ({c_CMD, c_Select_Card})) ? ({c_response_type_R1_NORMAL, c_DAT_busy, c_CMD7_mask_check_redo_bits, c_CMD7_ans_dont_redo, c_CMD7_mask_check_error_bits, c_CMD7_ans_error_free}):  // CMD7

				      (w_OPCODE_Q == ({c_CMD, c_Send_IF_State})) ? ({c_response_type_R7_CIC, c_DAT_none, c_CMD8_mask_check_redo_bits, c_CMD8_ans_dont_redo, c_CMD8_mask_check_error_bits, c_CMD8_ans_error_free}):  // CMD8

				      (w_OPCODE_Q == ({c_CMD, c_Read_Single_Block})) ? ({c_response_type_R1_NORMAL, c_DAT_block, c_CMD17_mask_check_redo_bits, c_CMD17_ans_dont_redo, c_CMD17_mask_check_error_bits, c_CMD17_ans_error_free}):  // CMD17

                                      (w_OPCODE_Q == ({c_ACMD, c_SD_Send_OCR})) ? ({c_response_type_R3_OCR, c_DAT_none, c_ACMD41_mask_check_redo_bits, c_ACMD41_ans_dont_redo, c_ACMD41_mask_check_error_bits, c_ACMD41_ans_error_free}) : //ACMD41

				      (w_OPCODE_Q == ({c_CMD, c_App_Command})) ? ({c_response_type_R1_NORMAL, c_DAT_none, c_CMD55_mask_check_redo_bits, c_CMD55_ans_dont_redo, c_CMD55_mask_check_error_bits, c_CMD55_ans_error_free}) : // CMD55

				      (w_OPCODE_Q == ({c_ACMD, c_App_Command})) ? ({c_response_type_R1_NORMAL, c_DAT_none, c_ACMD55_mask_check_redo_bits, c_ACMD55_ans_dont_redo, c_ACMD55_mask_check_error_bits, c_ACMD55_ans_error_free}) : //ACMD55

                                      ({c_response_type_R1_NORMAL, c_DAT_none, c_ACMD55_mask_check_redo_bits, c_ACMD55_ans_dont_redo, c_ACMD55_mask_check_error_bits, c_ACMD55_ans_error_free});  // when in doubt just send ACMD55
  
  assign w_R_TYPE        = w_instruction_control_bits[132:130];
  assign w_USES_DAT      = w_instruction_control_bits[129:128];
  assign w_NO_REDO_MASK  = w_instruction_control_bits[127:96];
  assign w_NO_REDO_ANS   = w_instruction_control_bits[95:64];
  assign w_NO_ERROR_MASK = w_instruction_control_bits[63:32];
  assign w_NO_ERROR_ANS  = w_instruction_control_bits[31:0];

    
endmodule


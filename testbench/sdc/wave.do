onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sd_top_tb/DUT/a_RST
add wave -noupdate /sd_top_tb/DUT/CLK
add wave -noupdate /sd_top_tb/DUT/i_BLOCK_ADDR
add wave -noupdate /sd_top_tb/DUT/i_READ_REQUEST
add wave -noupdate /sd_top_tb/DUT/i_COUNT_IN_MAX
add wave -noupdate /sd_top_tb/DUT/LIMIT_SD_TIMERS
add wave -noupdate /sd_top_tb/DUT/o_READY_FOR_READ
add wave -noupdate /sd_top_tb/DUT/o_SD_RESTARTING
add wave -noupdate /sd_top_tb/DUT/o_DATA_TO_CORE
add wave -noupdate /sd_top_tb/DUT/o_DATA_VALID
add wave -noupdate /sd_top_tb/DUT/o_LAST_NIBBLE
add wave -noupdate /sd_top_tb/DUT/o_ERROR_CODE_Q
add wave -noupdate /sd_top_tb/DUT/o_FATAL_ERROR
add wave -noupdate -expand -group interface /sd_top_tb/DUT/o_SD_CLK
add wave -noupdate -expand -group interface /sd_top_tb/DUT/o_SD_CMD
add wave -noupdate -expand -group interface /sd_top_tb/DUT/o_SD_CMD_OE
add wave -noupdate -expand -group interface /sd_top_tb/DUT/i_SD_CMD
add wave -noupdate -expand -group interface /sd_top_tb/DUT/i_SD_DAT
add wave -noupdate -label {cmd fsm} /sd_top_tb/DUT/my_sd_cmd_fsm/r_curr_state
add wave -noupdate -label {dat fsm} /sd_top_tb/DUT/my_sd_dat_fsm/r_curr_state
add wave -noupdate -label {clk fsm} /sd_top_tb/DUT/my_clk_fsm/r_curr_state
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_RST
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_TIMER_OUT
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_COUNTER_OUT
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_CLOCK_CHANGE_DONE
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_IC_OUT
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_USES_DAT
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_OPCODE
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_R_TYPE
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_NO_REDO_MASK
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_NO_REDO_ANS
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_NO_ERROR_MASK
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_NO_ERROR_ANS
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_SD_CMD_RX
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_RESPONSE_CONTENT
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_RESPONSE_INDEX
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_RX_CRC7
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_DAT_RX_DONE
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_ERROR_CRC16
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_ERROR_DAT_TIMES_OUT
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/i_READ_REQUEST
add wave -noupdate -group old /sd_top_tb/DUT/my_sd_cmd_fsm/LIMIT_SD_TIMERS
add wave -noupdate -group old /sd_top_tb/DUT/my_clk_fsm/i_START
add wave -noupdate -group old /sd_top_tb/DUT/my_clk_fsm/i_FATAL_ERROR
add wave -noupdate -group old /sd_top_tb/DUT/my_clk_fsm/i_RST
add wave -noupdate -group old /sd_top_tb/DUT/my_clk_fsm/o_DONE
add wave -noupdate -group old /sd_top_tb/DUT/my_clk_fsm/o_G_CLK_SD_EN
add wave -noupdate -group old /sd_top_tb/DUT/my_clk_fsm/o_HS_TO_INIT_CLK_DIVIDER_RST
add wave -noupdate -group old /sd_top_tb/DUT/my_clk_fsm/o_SD_CLK_SELECTED
add wave -noupdate -group old -expand /sd_top_tb/DUT/w_OPCODE_Q
add wave -noupdate -group old /sd_top_tb/DUT/c_CMD
add wave -noupdate -group old /sd_top_tb/DUT/c_ACMD
add wave -noupdate -group old /sd_top_tb/DUT/c_Go_Idle_State
add wave -noupdate -group old /sd_top_tb/DUT/c_response_type_R0_NONE
add wave -noupdate -group old /sd_top_tb/DUT/c_response_type_R0_NONE
add wave -noupdate -group old /sd_top_tb/DUT/c_response_type_R1_NORMAL
add wave -noupdate -group old /sd_top_tb/DUT/c_response_type_R2_CID_CSD
add wave -noupdate -group old /sd_top_tb/DUT/c_response_type_R3_OCR
add wave -noupdate -group old /sd_top_tb/DUT/c_response_type_R6_RCA
add wave -noupdate -group old /sd_top_tb/DUT/c_response_type_R7_CIC
add wave -noupdate -group old /sd_top_tb/DUT/w_instruction_control_bits
add wave -noupdate -group old /sd_top_tb/DUT/w_command_index
add wave -noupdate -group old /sd_top_tb/DUT/r_IC_OUT
add wave -noupdate -group old /sd_top_tb/DUT/w_BLOCK_ADDR
add wave -noupdate /sd_top_tb/DUT/w_TX_SOURCE_SELECT
add wave -noupdate /sd_top_tb/DUT/w_tx_tail_Q
add wave -noupdate /sd_top_tb/DUT/w_TX_PISO8_LOAD
add wave -noupdate /sd_top_tb/DUT/w_TX_PISO8_EN
add wave -noupdate /sd_top_tb/DUT/r_command_tail
add wave -noupdate /sd_top_tb/DUT/r_TX_CRC7
add wave -noupdate /sd_top_tb/DUT/w_TX_CRC7_PIPO_RST
add wave -noupdate /sd_top_tb/DUT/w_TX_CRC7_PIPO_EN
add wave -noupdate /sd_top_tb/DUT/w_command_head
add wave -noupdate /sd_top_tb/DUT/my_sd_dat_fsm/i_DAT0_Q
add wave -noupdate /sd_top_tb/sdcard/oeDat
add wave -noupdate /sd_top_tb/sdcard/datOut
add wave -noupdate /sd_top_tb/sdcard/dat
add wave -noupdate /sd_top_tb/DUT/my_sd_cmd_fsm/w_resend_last_command
add wave -noupdate /sd_top_tb/DUT/my_sd_cmd_fsm/i_ERROR_CRC16
add wave -noupdate /sd_top_tb/DUT/r_DAT3_CRC16
add wave -noupdate /sd_top_tb/DUT/r_DAT2_CRC16
add wave -noupdate /sd_top_tb/DUT/r_DAT1_CRC16
add wave -noupdate /sd_top_tb/DUT/r_DAT0_CRC16
add wave -noupdate -radix decimal /sd_top_tb/DUT/my_sd_cmd_fsm/i_COUNTER_OUT
add wave -noupdate /sd_top_tb/DUT/CLK
add wave -noupdate /sd_top_tb/DUT/r_CLK_SD
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/i_COUNT_IN_MAX
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/i_EN
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/i_CLK
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/i_RST
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/g_COUNT_WIDTH
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/r_count_out
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/w_counter_overflowed
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/r_fd_Q
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/w_fd_D
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/w_load
add wave -noupdate -expand -group {clock divider} /sd_top_tb/DUT/slow_clk_divider/o_CLK
add wave -noupdate /sd_top_tb/sdcard/ByteAddr
add wave -noupdate /sd_top_tb/sdcard/write_out_index
add wave -noupdate /sd_top_tb/sdcard/inCmd
add wave -noupdate /sd_top_tb/DUT/w_TX_SOURCE_SELECT
add wave -noupdate /sd_top_tb/DUT/w_command_head
add wave -noupdate /sd_top_tb/DUT/r_IC_OUT
add wave -noupdate /sd_top_tb/DUT/w_BLOCK_ADDR
add wave -noupdate /sd_top_tb/DUT/i_BLOCK_ADDR
add wave -noupdate /sd_top_tb/DUT/regfile_cmd17_data_block/regs
add wave -noupdate /sd_top_tb/DUT/regfile_cmd17_data_block/ra1
add wave -noupdate /sd_top_tb/ReadData
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2028326 ns} 0} {{Cursor 2} {4831 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 245
configure wave -valuecolwidth 180
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1979107 ns} {2077545 ns}

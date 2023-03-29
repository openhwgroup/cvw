# adding overhead spi waves
add wave -hex /testbench/dut/uncore/spi/spi/PCLK
add wave -hex /testbench/dut/uncore/spi/spi/PRESETn
add wave -hex /testbench/dut/uncore/spi/spi/PSEL
add wave -hex /testbench/dut/uncore/spi/spi/PADDR
add wave -hex /testbench/dut/uncore/spi/spi/PWDATA
add wave -hex /testbench/dut/uncore/spi/spi/PSTRB
add wave -hex /testbench/dut/uncore/spi/spi/PWRITE
add wave -hex /testbench/dut/uncore/spi/spi/PENABLE
add wave -hex /testbench/dut/uncore/spi/spi/PREADY
add wave -hex /testbench/dut/uncore/spi/spi/PRDATA
add wave -hex /testbench/dut/uncore/spi/spi/SPIOut
add wave -hex /testbench/dut/uncore/spi/spi/SPIIn
add wave -hex /testbench/dut/uncore/spi/spi/SPICS
add wave -hex /testbench/dut/uncore/spi/spi/SPIIntr
add wave -divider

#adding register waves

add wave -hex /testbench/dut/uncore/spi/spi/sclk_div
add wave -hex /testbench/dut/uncore/spi/spi/sclk_mode
add wave -hex /testbench/dut/uncore/spi/spi/cs_id
add wave -hex /testbench/dut/uncore/spi/spi/cs_def
add wave -hex /testbench/dut/uncore/spi/spi/cs_mode
add wave -hex /testbench/dut/uncore/spi/spi/delay0
add wave -hex /testbench/dut/uncore/spi/spi/delay1
add wave -hex /testbench/dut/uncore/spi/spi/fmt
add wave -hex /testbench/dut/uncore/spi/spi/rx_data
add wave -hex /testbench/dut/uncore/spi/spi/tx_data
add wave -hex /testbench/dut/uncore/spi/spi/tx_mark
add wave -hex /testbench/dut/uncore/spi/spi/rx_mark
add wave -hex /testbench/dut/uncore/spi/spi/ie
add wave -hex /testbench/dut/uncore/spi/spi/ip

#adding internal logic

add wave -hex /testbench/dut/uncore/spi/spi/entry
add wave -hex /testbench/dut/uncore/spi/spi/memwrite
add wave -hex /testbench/dut/uncore/spi/spi/Din 
add wave -hex /testbench/dut/uncore/spi/spi/Dout 
add wave -hex /testbench/dut/uncore/spi/spi/busy 
add wave -hex /testbench/dut/uncore/spi/spi/txWMark
add wave -hex /testbench/dut/uncore/spi/spi/txRMark
add wave -hex /testbench/dut/uncore/spi/spi/rxWMark
add wave -hex /testbench/dut/uncore/spi/spi/rxRMark
add wave -hex /testbench/dut/uncore/spi/spi/TXwfull
add wave -hex /testbench/dut/uncore/spi/spi/TXrempty
add wave -hex /testbench/dut/uncore/spi/spi/sck 
add wave -hex /testbench/dut/uncore/spi/spi/div_counter
add wave -hex /testbench/dut/uncore/spi/spi/div_counter_edge
add wave -hex /testbench/dut/uncore/spi/spi/tx_empty
add wave -hex /testbench/dut/uncore/spi/spi/sclk_edge
add wave -hex /testbench/dut/uncore/spi/spi/sclk_duty
add wave -hex /testbench/dut/uncore/spi/spi/delay0_cnt
add wave -hex /testbench/dut/uncore/spi/spi/delay1_cnt
add wave -hex /testbench/dut/uncore/spi/spi/delay0_cmp
add wave -hex /testbench/dut/uncore/spi/spi/delay1_cmp
add wave -hex /testbench/dut/uncore/spi/spi/intercs_cmp
add wave -hex /testbench/dut/uncore/spi/spi/intercs_cnt
add wave -hex /testbench/dut/uncore/spi/spi/interxfr_cmp
add wave -hex /testbench/dut/uncore/spi/spi/interxfr_cnt
add wave -hex /testbench/dut/uncore/spi/spi/cs_internal
add wave -hex /testbench/dut/uncore/spi/spi/frame_cnt
add wave -hex /testbench/dut/uncore/spi/spi/frame_cmp
add wave -hex /testbench/dut/uncore/spi/spi/active
add wave -hex /testbench/dut/uncore/spi/spi/frame_cmp_bol
add wave -hex /testbench/dut/uncore/spi/spi/frame_cnt_shifted
add wave -hex /testbench/dut/uncore/spi/spi/tx_frame_cnt_shifted_pre
add wave -hex /testbench/dut/uncore/spi/spi/tx_penultimate_frame
add wave -hex /testbench/dut/uncore/spi/spi/rx_penultimate_frame
add wave -hex /testbench/dut/uncore/spi/spi/rx_frame_cnt_shifted_pre
add wave -hex /testbench/dut/uncore/spi/spi/tx_frame_cmp_pre_bool
add wave -hex /testbench/dut/uncore/spi/spi/rx_frame_cmp_pre_bool
add wave -hex /testbench/dut/uncore/spi/spi/frame_cmp_protocol
add wave -hex /testbench/dut/uncore/spi/spi/rxShiftFull
add wave -hex /testbench/dut/uncore/spi/spi/TXwinc
add wave -hex /testbench/dut/uncore/spi/spi/TXrinc
add wave -hex /testbench/dut/uncore/spi/spi/RXwinc
add wave -hex /testbench/dut/uncore/spi/spi/RXrinc
add wave -hex /testbench/dut/uncore/spi/spi/RXwfull
add wave -hex /testbench/dut/uncore/spi/spi/RXrempty
add wave -hex /testbench/dut/uncore/spi/spi/TXrdata
add wave -hex /testbench/dut/uncore/spi/spi/RXwdata
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txWWatermarkLevel
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxRWatermarkLevel
add wave -hex /testbench/dut/uncore/uncore/spi/spi/sclk_reset_0
add wave -hex /testbench/dut/uncore/uncore/spi/spi/sclk_reset_1
add wave -hex /testbench/dut/uncore/uncore/spi/spi/state
add wave -hex /testbench/dut/uncore/uncore/spi/spi/active0
add wave -hex /testbench/dut/uncore/uncore/spi/spi/TXrempty_delay
add wave -hex /testbench/dut/uncore/uncore/spi/spi/TXwinc_delay
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftEmpty
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftEmpty
add wave -hex /testbench/dut/uncore/uncore/spi/spi/sck_phase_sel
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShift
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxShift
add wave -hex /testbench/dut/uncore/uncore/spi/spi/sample_edge
add wave -hex /testbench/dut/uncore/uncore/spi/spi/CSauto
add wave -hex /testbench/dut/uncore/uncore/spi/spi/CShold
add wave -hex /testbench/dut/uncore/uncore/spi/spi/CSoff

add wave -divider
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/M
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/N
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wclk
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rclk
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/PRESETn
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/winc
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rinc
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wdata
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/endian
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wwatermarklevel
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rwatermarklevel
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rdata
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wfull
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rempty
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wwatermark
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rwatermark
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/mem
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wq1_rptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wq2_rptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rq1_wptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rq2_wptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rbin
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rgraynext
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rbinnext
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wbin
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wgraynext
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wbinnext
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rempty_val
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wfull_val
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/wq2_rptr_bin
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/rq2_wptr_bin
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/raddr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txFIFO/waddr

add wave -divider

add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/sclk_duty
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/PRESETn
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/TXrempty
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/rx_frame_cmp_pre_bool
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/active0
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/txShiftEmpty
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/tx_state
add wave -hex /testbench/dut/uncore/uncore/spi/spi/txShiftFSM_1/tx_nextstate

add wave -divider

add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/M
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/N
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wclk
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rclk
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/PRESETn
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/winc
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rinc
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wdata
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/endian
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wwatermarklevel
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rwatermarklevel
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rdata
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wfull
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rempty
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wwatermark
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rwatermark
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/mem
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wq1_rptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wq2_rptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFI





















FO/rptr
add wave -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rq1_wptr
add wave -hex -hex/testbench/dut/uncore/uncore/spi/spi/rxFIFO/rq2_wptr
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wptr
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rbin
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rgraynext
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rbinnext
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wbin
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wgraynext
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wbinnext
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rempty_val
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wfull_val
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/wq2_rptr_bin
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/rq2_wptr_bin
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/raddr
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxFIFO/waddr

add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftFSM_1/sclk_duty
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftFSM_1/PRESETn
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftFSM_1/rx_frame_cmp_pre_bool
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftFSM_1/sample_edge
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftFSM_1/rxShiftFull
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftFSM_1/rx_state
add wave -hex -hex /testbench/dut/uncore/uncore/spi/spi/rxShiftFSM_1/rx_nextstate







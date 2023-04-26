///////////////////////////////////////////
//
// WALLY-spi
//
// Author: David_Harris@hmc.edu and Naiche Whyte-Aguayo 
//
// Created 2023-02-01
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

#include "WALLY-TEST-LIB-64.h" 

RVTEST_ISA("RV64I")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",spi)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

END_TESTS

TEST_STACK_AND_DATA

.align 3
test_cases:
# ---------------------------------------------------------------------------------------------
# Test Contents
#
#   Here is where the actual tests are held, or rather, what the actual tests do.
#   each entry consists of 3 values that will be read in as follows:
#   
#   '.8byte [x28 Value], [x29 Value], [x30 value]'
#                     or
#   '.8byte [address], [value], [test type]'
#
#   The encoding for x30 test type values can be found in the test handler in the framework file
# ---------------------------------------------------------------------------------------------

.equ SPI, 0x10040000
.equ sck_div, (SPI+0x00)
.equ sck_mode, (SPI+0x04)
.equ cs_id, (SPI+0x10)
.equ cs_def, (SPI+0x14)
.equ cs_mode, (SPI+0x18)
.equ delay0, (SPI+0x28)
.equ delay1, (SPI+0x2C)
.equ fmt, (SPI+0x40)
.equ tx_data, (SPI+0x48)
.equ rx_data, (SPI+0x4C)
.equ tx_mark, (SPI+0x50)
.equ rx_mark, (SPI+0x54)
.equ ie, (SPI+0x70)
.equ ip, (SPI+0x74)

# =========== Verify all registers reset to correct values ===========

.8byte sck_div, 0x00000003, read32_test     # sck_div reset to 0x3
.8byte sck_mode, 0x00000000, read32_test    # sck_mode reset to 0x0
.8byte cs_id, 0x00000000, read32_test       # cs_id reset to 0x0
.8byte cs_def, 0x00000001, read32_test      # cs_def reset to 0x1
.8byte cs_mode, 0x00000000, read32_test     # cs_mode reset to 0x0
.8byte delay0, 0x00000101, read32_test      # delay0 reset to [31:24] 0x0, [23:16] 0x1, [15:8] 0x0, [7:0] 0x1
.8byte delay1, 0x00000001, read32_test      # delay1 reset to 0x1
.8byte fmt, 0x00000080, read32_test         # fmt reset to [31:20] 0x0, [19:16] 0x8, [15:0] 0x0 for non-flash enabled SPI controllers
.8byte tx_data, 0x00000000, read32_test     # tx_data [30:0] reset to 0x0, [31] read only
.8byte rx_data, 0x00000000, read32_test     # rx_data read only
.8byte tx_mark, 0x00000000, read32_test     # tx_mark reset to 0x0 for non-flash enabled controllers
.8byte rx_mark, 0x00000000, read32_test     # rx_mark reset to 0x0
.8byte ie, 0x00000000, read32_test          # ie reset to 0x0
.8byte ip, 0x00000000, read32_test          # ip reset to 0x0

# ============= test state transition edge cases ==================

# ============= phase = 0 , mode = auto, cs-sck delay = 0

.8byte delay0, 0x00000100, write32_test     # set delay 0 cs-sck delay to 0
.8byte tx_data, 0x44332211, spi_burst_send  # load tx_data
.8byte 0x0, 0x00000003, spi_data_wait       # wait for transmission to end
.8byte rx_data, 0x000000011, read32_test
.8byte rx_data, 0x000000022, read32_test
.8byte rx_data, 0x000000033, read32_test
.8byte rx_data, 0x000000044, read32_test    # check rx_data and clear rx fifo

# ============= phase = 0 , mode = auto, cs-sck delay = A5

.8byte delay0, 0x000001A5, write32_test     # set delay 0 cs-sck delay to 0
.8byte tx_data, 0x44332211, spi_burst_send  # load tx_data
.8byte 0x0, 0x00000003, spi_data_wait       # wait for transmission to end
.8byte rx_data, 0x000000011, read32_test
.8byte rx_data, 0x000000022, read32_test
.8byte rx_data, 0x000000033, read32_test
.8byte rx_data, 0x000000044, read32_test    # check rx_data and clear rx fifo

# ============= phase = 1, mode = auto, sck-cs delay = 0

.8byte delay0, 0x00000001, write32_test     # set delay 0 sck-cs delay to 0
.8byte sck_mode, 0x00000001, write32_test   # set phase to 1
.8byte tx_data, 0x44332211, spi_burst_send  #load tx_data
.8byte 0x0, 0x00000003, spi_data_wait       # wait for transmission to end
.8byte rx_data, 0x000000011, read32_test
.8byte rx_data, 0x000000022, read32_test
.8byte rx_data, 0x000000033, read32_test
.8byte rx_data, 0x000000044, read32_test    # check rx_data and clear rx fifo

# ============= phase = 1, mode = auto, sck-cs delay = A5

.8byte delay0, 0x0000A501, write32_test     # set delay 0 sck-cs delay to 0
.8byte sck_mode, 0x00000001, write32_test   # set phase to 1
.8byte tx_data, 0x44332211, spi_burst_send  #load tx_data
.8byte 0x0, 0x00000003, spi_data_wait       # wait for transmission to end
.8byte rx_data, 0x000000011, read32_test
.8byte rx_data, 0x000000022, read32_test
.8byte rx_data, 0x000000033, read32_test
.8byte rx_data, 0x000000044, read32_test    # check rx_data and clear rx fifo

# ============ mode = hold, inter_xfr delay = 0

.8byte delay0, 0x00000101, write32_test    # reset delay0 register
.8byte sck_mode, 0x00000000, write32_test   # reset sck_mode register
.8byte delay1, 0x00000001, write32_test     # set delay1 inter_xfr delay to 0
.8byte cs_mode, 0x00000002, write32_test
.8byte tx_data, 0x44332211, spi_burst_send  # load tx_data
.8byte 0x0, 0x00000003, spi_data_wait       # wait for transmission to end
.8byte rx_data, 0x000000011, read32_test
.8byte rx_data, 0x000000022, read32_test
.8byte rx_data, 0x000000033, read32_test
.8byte rx_data, 0x000000044, read32_test    # check rx_data and clear rx fifo

# ============ mode = hold, inter_xfr delay = A5

.8byte delay1, 0x0000A501, write32_test     # set delay1 inter_xfr delay to A5
.8byte tx_data, 0x44332211, spi_burst_send  #load tx_data
.8byte 0x0, 0x00000003, spi_data_wait       # wait for transmission to end
.8byte rx_data, 0x000000011, read32_test
.8byte rx_data, 0x000000022, read32_test
.8byte rx_data, 0x000000033, read32_test
.8byte rx_data, 0x000000044, read32_test    # check rx_data and clear rx fifo

# =========== mode = hold, csmode, csid, or csdef change

.8byte delay1, 0x00000001, write32_test     # set delay1 inter_xfr delay to 0
.8byte tx_data, 0x44332211, spi_burst_send  #load tx_data
.8byte 0x0, 0x00000001, spi_data_wait       # wait for transmission to end
.8byte cs_def, 0x0000000E, write32_test
.8byte cs_id, 0x00000002, write32_test
.8byte cs_mode, 0x00000000, write32_test
.8byte 0x0, 0x00000003, spi_data_wait
.8byte rx_data, 0x000000011, read32_test
.8byte rx_data, 0x000000022, read32_test
.8byte rx_data, 0x000000033, read32_test
.8byte rx_data, 0x000000044, read32_test    # check rx_data and clear rx fifo






.8byte 0x0, 0x0, terminate_test

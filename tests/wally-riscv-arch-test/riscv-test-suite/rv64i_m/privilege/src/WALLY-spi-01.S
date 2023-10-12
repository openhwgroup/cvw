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

RVTEST_ISA("RV64I_Zicsr_Zifencei")
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
.8byte cs_def, 0x0000000F, read32_test      # cs_def reset to 0x1
.8byte cs_mode, 0x00000000, read32_test     # cs_mode reset to 0x0
.8byte delay0, 0x00000101, read32_test      # delay0 reset to [31:24] 0x0, [23:16] 0x1, [15:8] 0x0, [7:0] 0x1
.8byte delay1, 0x00000001, read32_test      # delay1 reset to 0x1
.8byte fmt, 0x00000080, read32_test         # fmt reset to [31:20] 0x0, [19:16] 0x8, [15:0] 0x0 for non-flash enabled SPI controllers
.8byte tx_data, 0x00000000, read32_test     # tx_data [30:0] reset to 0x0, [31] read only
.8byte tx_mark, 0x00000000, read32_test     # tx_mark reset to 0x0 for non-flash enabled controllers
.8byte rx_mark, 0x00000000, read32_test     # rx_mark reset to 0x0
.8byte ie, 0x00000000, read32_test          # ie reset to 0x0
.8byte ip, 0x00000000, read32_test          # ip reset to 0x0

# =========== Basic read-write ===========

.8byte tx_data, 0x000000011, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000011, read32_test     # read rx_data

# =========== Different cs_mode, sck_mode, cs_def, sck_div ===========

# Test sck_div

.8byte sck_div, 0x00000101, write32_test    # set sck_div to 0x101
.8byte tx_data, 0x000000FF, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000FF, read32_test     # read rx_data

# Test phase

.8byte sck_div, 0x00000003, write32_test    # reset sck_div to 0x03 so only sck_mode is different
.8byte sck_mode, 0x00000001, write32_test   # change phase to falling edge
.8byte tx_data, 0x000000A0, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000A0, read32_test     # read rx_data

# Test polarity 

.8byte sck_mode, 0x00000000, write32_test   # reset sck phase to rising edge
.8byte sck_mode, 0x00000002, write32_test   # set sck polarity active low
.8byte tx_data, 0x0000000B, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x0000000B, read32_test     # read rx_data

# Test chip select polarity

.8byte sck_mode, 0x00000000, write32_test   # reset sck polarity to active high
.8byte cs_def, 0x0000000E, write32_test     # set cs[0] to inactive low
.8byte tx_data, 0x00000079, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000079, read32_test     # read rx_data

# Test chip id 

.8byte cs_def, 0x0000000F, write32_test     # reset all cs to active low
.8byte cs_id, 0x00000001, write32_test      # select cs[1] 
.8byte tx_data, 0x00000000, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000000, read32_test     # read rx_data

# Test cs hold mode

.8byte cs_id, 0x00000000, write32_test      # select cs[0] 
.8byte cs_mode, 0x00000002, write32_test    # set cs_mode to HOLD
.8byte tx_data, 0x000000C0, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000C0, read32_test     # read rx_data

# Test cs OFF mode

.8byte cs_mode, 0x00000003, write32_test    # set cs_mode to OFF
.8byte tx_data, 0x00000011, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000011, read32_test     # read rx_data

# =========== Test delay0 register ===========

# Test cs-sck delay of 0 with sck phase = 0 (implicit half cycle delay)

.8byte cs_mode, 0x00000000, write32_test    # reset cs_mode to auto, all cs and sck mode settings should be defualt
.8byte delay0, 0x0000100, write32_test     # set cs-sck delay to 0
.8byte tx_data, 0x00000020, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000020, read32_test     # read rx_data

# Test cs-sck delay of 0 with sck phase 1 (no delay)

.8byte sck_mode, 0x00000001, write32_test   # set sck_mode[0] to 1 (sck phase = 1)
.8byte tx_data, 0x00000032, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000032, read32_test     # read rx_data

# Test arbitrary cs-sck delay (sck phase 1)

.8byte delay0, 0x00000105, write32_test     # set cs-sck delay to 5 cycles
.8byte tx_data, 0x00000048, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000048, read32_test     # read rx_data

# Test arbitrary cs-sck delay (sck phase 0)

.8byte sck_mode, 0x00000000, write32_test   # set sck phase to 0
.8byte delay0, 0x00000105, write32_test     # set cs-sck delay to AF cycles
.8byte tx_data, 0x000000AF, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000AF, read32_test     # read rx_data


# Test sck-cs delay of 0 with sck phase = 0 (no delay)

.8byte delay0, 0x00000001, write32_test     # set cs-sck delay to 0
.8byte tx_data, 0x00000050, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000050, read32_test     # read rx_data

# Test sck-cs delay of 0 with sck phase 1 (implicit half cycle delay)

.8byte sck_mode, 0x00000001, write32_test   # set sck_mode[0] to 1 (sck phase = 1)
.8byte tx_data, 0x0000006B, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x0000006B, read32_test     # read rx_data

# Test arbitrary sck-cs delay (sck phase 1)

.8byte delay0, 0x00000501, write32_test     # set cs-sck delay to A5 cycles
.8byte tx_data, 0x00000011, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000011, read32_test     # read rx_data

# Test arbitrary sck-cs delay (sck phase 0)

.8byte sck_mode, 0x00000000, write32_test   # set sck phase to 0
.8byte delay0, 0x00000501, write32_test     # set cs-sck delay to 5 cycles
.8byte tx_data, 0x00000015, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000015, read32_test     # read rx_data

# =========== Test delay1 register ===========

# Test inter cs delay 


.8byte delay0, 0x00000101, write32_test     # reset delay0 register
.8byte delay1, 0x00000005, write32_test     # set inter_cs delay to 5
.8byte tx_data, 0x44332211, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000011, read32_test
.8byte rx_data, 0x00000022, read32_test
.8byte rx_data, 0x00000033, read32_test
.8byte rx_data, 0x00000044, read32_test     

#test long inter_cs delay

.8byte delay1, 0x000000A5, write32_test
.8byte tx_data, 0x0000007B, write32_test
.8byte 0x0, 0x00000000, spi_data_wait
.8byte rx_data, 0x0000007B, read32_test


# Test inter_cs delay set to 0

.8byte delay1, 0x00000000, write32_test     # set inter_cs delay to 5
.8byte tx_data, 0x54433221, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000021, read32_test
.8byte rx_data, 0x00000032, read32_test
.8byte rx_data, 0x00000043, read32_test
.8byte rx_data, 0x00000054, read32_test


# Test inter_xfr delay of 0 (maybe change behavior to half-period instead of period)

.8byte delay1, 0x00000001, write32_test     # reset inter_cs delay to 1
.8byte cs_mode, 0x00000002, write32_test    # set cs_mode to HOLD 
.8byte tx_data, 0x99887766, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000066, read32_test
.8byte rx_data, 0x00000077, read32_test
.8byte rx_data, 0x00000088, read32_test
.8byte rx_data, 0x00000099, read32_test

# Test inter_xfr delay 0 with phase = 1
.8byte sck_mode, 0x00000001, write32_test
.8byte tx_data, 0x99887766, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait
.8byte rx_data, 0x00000066, read32_test
.8byte rx_data, 0x00000077, read32_test
.8byte rx_data, 0x00000088, read32_test
.8byte rx_data, 0x00000099, read32_test


# Test arbitrary inter_xfr delay

.8byte delay1, 0x00000501, write32_test     # set inter_xfr delay to 5
.8byte sck_mode, 0x00000001, write32_test
.8byte tx_data, 0x98877665, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000065, read32_test
.8byte rx_data, 0x00000076, read32_test
.8byte rx_data, 0x00000087, read32_test
.8byte rx_data, 0x00000098, read32_test

# test long inter_xfr delay
.8byte delay1, 0x0000A501, write32_test
.8byte tx_data, 0x00000048, write32_test
.8byte 0x0, 0x00000000, spi_data_wait
.8byte rx_data, 0x00000048, read32_test

# Test cs-sck delay with cs_mode = HOLD

.8byte delay1, 0x00000001, write32_test     # set inter_xfr delay to 0
.8byte delay0, 0x00000105, write32_test     # set cs-sck delay to 5 (should have no effect because cs is never inactive)
.8byte tx_data, 0xAABBCCDD, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000DD, read32_test     # read rx_data
.8byte rx_data, 0x000000CC, read32_test
.8byte rx_data, 0x000000BB, read32_test
.8byte rx_data, 0x000000AA, read32_test

# Test sck-cs delay cs_mode = HOLD

.8byte delay0, 0x00000501, write32_test     # set sck-cs delay to 5 (should have no effect because cs is never inactive)
.8byte tx_data, 0xABBCCDDE, spi_burst_send   # place 8'h11 into tx_data
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000DE, read32_test     # read rx_data
.8byte rx_data, 0x000000CD, read32_test
.8byte rx_data, 0x000000BC, read32_test
.8byte rx_data, 0x000000AB, read32_test

# =========== Test frame format (fmt) register ===========

# Test frame length of 4

.8byte delay1, 0x00000001, write32_test     # reset delay1 register
.8byte delay0, 0x00000101, write32_test     # reset delay0 register
.8byte sck_mode, 0x00000000, write32_test   #reset sckmode register
.8byte cs_mode, 0x00000000, write32_test    # set cs_mode to AUTO 
.8byte fmt, 0x00000040, write32_test        # set frame length to 4
.8byte tx_data, 0x000000F0, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000F0, read32_test     # read rx_data

# Test frame length of 0

#.8byte fmt, 0x00000000, write32_test        # set frame length to 4
#.8byte tx_data, 0x00000077, write32_test   # place 8'h11 into tx_data
#.8byte 0x0, 0x0101, spi_data_wait           # wait for transmission to end
#.8byte rx_data, 0x00000077, read32_test     # read rx_data

# test frame length 1 burst
.8byte fmt, 0x00000010, write32_test
.8byte tx_data, 0x80008000, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait
.8byte rx_data, 0x00000000, read32_test
.8byte rx_data, 0x00000080, read32_test
.8byte rx_data, 0x00000000, read32_test
.8byte rx_data, 0x00000080, read32_test


# Test big endian with frame length = 5

.8byte fmt, 0x00000050, write32_test        # set frame length to 5, big endian
.8byte tx_data, 0x000000A8, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x000000A8, read32_test     # read rx_data

# Test big endian burst with frame length = 5

.8byte tx_data, 0x03774FFF, spi_burst_send 
.8byte 0x0, 0x00000003, spi_data_wait
.8byte rx_data, 0x000000F8, read32_test 
.8byte rx_data, 0x00000048, read32_test
.8byte rx_data, 0x00000070, read32_test
.8byte rx_data, 0x00000000, read32_test




# Test little endian with frame length = 5

.8byte fmt, 0x00000054, write32_test        # set frame length to 5, little-endian
.8byte tx_data, 0x000000A8, write32_test   # place 8'h11 into tx_data
.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.8byte rx_data, 0x00000008, read32_test     # read rx_data -> 08

#test little endian burst with frame length = 5

.8byte tx_data, 0xFF4F7703, spi_burst_send
.8byte 0x0, 0x00000003, spi_data_wait
.8byte rx_data, 0x00000003, read32_test     #03
.8byte rx_data, 0x00000017, read32_test     #17
.8byte rx_data, 0x0000000F, read32_test     #0F
.8byte rx_data, 0x0000001F, read32_test     #1F

# Test dual SPI protocol, frame length = 8, big endian

#.8byte fmt, 0x00000081, write32_test        # set frame length to 8, big-endian, dual SPI
#.8byte tx_data, 0x000000C8, write32_test   # place 8'h11 into tx_data
#.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.8byte rx_data, 0x00000000, read32_test     # read rx_data

# Test dual SPI protocol, frame length = 4

#.8byte fmt, 0x00000041, write32_test        # set frame length to 8, big-endian, dual SPI
#.8byte tx_data, 0x000000A2, write32_test   # place 8'h11 into tx_data
#.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.8byte rx_data, 0x000000A0, read32_test     # read rx_data

# Test dual SPI protocol, frame length = 5

#.8byte fmt, 0x00000051, write32_test        # set frame length to 8, big-endian, dual SPI
#.8byte tx_data, 0x00000075, write32_test   # place 8'h11 into tx_data
#.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.8byte rx_data, 0x00000074, read32_test     # read rx_data

# Test dual SPI protocol burst, frame length = 5
#.8byte tx_data, 0x30733FFF, spi_burst_send
#.8byte 0x0, 0x00000003, spi_data_wait
#.8byte rx_data, 0x000000FC, read32_test
#.8byte rx_data, 0x0000003C, read32_test
#.8byte rx_data, 0x00000070, read32_test
#.8byte rx_data, 0x00000030, read32_test 

# Test quad SPI protocol, frame length = 5

#.8byte fmt, 0x00000052, write32_test        # set frame length to 8, big-endian, dual SPI
#.8byte tx_data, 0x0000003F, write32_test   # place 8'h11 into tx_data
#.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.8byte rx_data, 0x0000003F, read32_test     # read rx_data

# Test quad SPI protocol, frame length = 4

#.8byte fmt, 0x00000042, write32_test        # set frame length to 8, big-endian, dual SPI
#.8byte tx_data, 0x0000000F, write32_test   # place 8'h11 into tx_data
#.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.8byte rx_data, 0x00000000, read32_test     # read rx_data

# Test quad SPI protocol, frame length = 8

#.8byte fmt, 0x00000082, write32_test        # set frame length to 8, big-endian, dual SPI
#.8byte tx_data, 0x000000F0, write32_test   # place 8'h11 into tx_data
#.8byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.8byte rx_data, 0x000000F0, read32_test     # read rx_data

# =========== Test watermark interrupts ===========

# Test transmit watermark interrupt (triggers when entries in tx FIFO < tx watermark) without external enables

SETUP_PLIC

.8byte fmt, 0x00000080, write32_test        # reset fmt register 
.8byte tx_mark, 0x00000004, write32_test    # set transmit watermark to 4
#.8byte ie, 0x00000000, write32_test         # enable transmit interrupt
.8byte ip, 0x00000001, read32_test          # tx watermark interupt should be pending
.8byte 0x0, 0x00000000, readmip_test
.8byte tx_data, 0x55443322, spi_burst_send    # place 4 entries in transmit fifo
.8byte ip, 0x00000000, read32_test          # tx watermark interupt should be off
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end

# test recieve watermark interrupt (triggers when entries in rx FIFO > rx watermark)

.8byte tx_mark, 0x00000000, write32_test      # set tx_mark to 0
.8byte rx_data, 0x00000022, read32_test       # clear one entry from rx FIFO
.8byte rx_mark, 0x00000003, write32_test      # set recieve watermark to 3
#.8byte ie, 0x0000002, write32_test          # enable receive interrupts
.8byte ip, 0x00000000, read32_test          # rx interrupts should be low (rx FIFO has 3 entries)
.8byte rx_mark, 0x00000002, write32_test    # set recieve watermark to 2
.8byte ip, 0x00000002, read32_test          # recieve interrupt should be high
.8byte 0x0, 0x00000000, readmip_test
.8byte rx_data, 0x00000033, read32_test     # clear one more entry from recieve FIFO (2 entries)
.8byte ip, 0x00000000, read32_test          # receive interrupt should be low
.8byte rx_data, 0x00000044, read32_test
.8byte rx_data, 0x00000055, read32_test     # clear rx fifo


.8byte tx_mark, 0x00000004, write32_test    # set transmit watermark to 4
.8byte ie, 0x00000001, write32_test         # enable transmit interrupt
.8byte ip, 0x00000001, read32_test          # tx watermark interupt should be pending
.8byte 0x0, 0x00000800, readmip_test
.8byte tx_data, 0x55443322, spi_burst_send    # place 4 entries in transmit fifo
.8byte tx_mark, 0x00000001, write32_test
.8byte 0x0, 0x00000000, claim_m_plic_interrupts
.8byte ip, 0x00000000, read32_test          # tx watermark interupt should be off
.8byte 0x0, 0x00000000, readmip_test
.8byte ie, 0x00000000, write32_test      # disable tx intr
.8byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end

# test recieve watermark interrupt (triggers when entries in rx FIFO > rx watermark)

.8byte tx_mark, 0x00000000, write32_test
.8byte rx_data, 0x00000022, read32_test       # clear one entry from rx FIFO
.8byte rx_mark, 0x00000003, write32_test      # set recieve watermark to 3
.8byte ie, 0x0000002, write32_test          # enable receive interrupts
.8byte ip, 0x00000000, read32_test          # rx interrupts should be low (rx FIFO has 3 entries)
.8byte 0x0, 0x00000000, readmip_test
.8byte rx_mark, 0x00000002, write32_test    # set recieve watermark to 2
.8byte ip, 0x00000002, read32_test          # recieve interrupt should be high
.8byte 0x0, 0x00000800, readmip_test
.8byte rx_data, 0x00000033, read32_test     # clear one more entry from recieve FIFO (2 entries)
.8byte 0x0, 0x00000000, claim_m_plic_interrupts
.8byte ip, 0x00000000, read32_test          # receive interrupt should be low
.8byte 0x0, 0x00000000, readmip_test

.8byte 0x0, 0x0, terminate_test
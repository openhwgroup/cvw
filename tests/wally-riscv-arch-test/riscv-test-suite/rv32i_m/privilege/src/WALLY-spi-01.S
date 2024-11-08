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

#include "WALLY-TEST-LIB-32.h" 

RVTEST_ISA("RV32I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",spi)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

END_TESTS

TEST_STACK_AND_DATA

.align 2
test_cases:
# ---------------------------------------------------------------------------------------------
# Test Contents
#
#   Here is where the actual tests are held, or rather, what the actual tests do.
#   each entry consists of 3 values that will be read in as follows:
#   
#   '.4byte [x28 Value], [x29 Value], [x30 value]'
#                     or
#   '.4byte [address], [value], [test type]'
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

.4byte sck_div, 0x00000003, read32_test     # sck_div reset to 0x3
.4byte sck_mode, 0x00000000, read32_test    # sck_mode reset to 0x0
.4byte cs_id, 0x00000000, read32_test       # cs_id reset to 0x0
.4byte cs_def, 0x0000000F, read32_test      # cs_def reset to 0x1
.4byte cs_mode, 0x00000000, read32_test     # cs_mode reset to 0x0
.4byte delay0, 0x00010001, read32_test      # delay0 reset to [31:24] 0x0, [23:16] 0x1, [15:8] 0x0, [7:0] 0x1
.4byte delay1, 0x00000001, read32_test      # delay1 reset to 0x1
.4byte fmt, 0x00080000, read32_test         # fmt reset to [31:20] 0x0, [19:16] 0x8, [15:0] 0x0 for non-flash enabled SPI controllers
.4byte tx_data, 0x00000000, read32_test     # tx_data [30:0] reset to 0x0, [31] read only
.4byte tx_mark, 0x00000000, read32_test     # tx_mark reset to 0x0 for non-flash enabled controllers
.4byte rx_mark, 0x00000000, read32_test     # rx_mark reset to 0x0
.4byte ie, 0x00000000, read32_test          # ie reset to 0x0
.4byte ip, 0x00000000, read32_test          # ip reset to 0x0

#test watermark interrupts at beginning where fifo read/write pointers are known b/c reset
# txwmp raised when # of entries in txfifo < txmark, rxwm raised when # of entries in rxfifo > rxmark

.4byte ip, 0x00000000, read32_test          # txfifo entries not < 0, rxfifo entries not > 0;
.4byte tx_mark, 0x00000004, write32_test    # set tx_mark to 4
.4byte rx_mark, 0x00000003, write32_test    # set rx_mark to 3
.4byte ip, 0x00000001, read32_test          # tx entries < 4, rx entries ! > 3
.4byte tx_data, 0x41526374, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte ip, 0x00000003, read32_test          # tx entries < 4, rx entries > 3, visual inspection should see tx TransmitFIFOReadIncrement

# txfifo wptr now at 0011, rxfifo wptr at 0000

.4byte rx_mark, 0x00000007, write32_test    # set rx_mark to 7
.4byte tx_data, 0xD4C3B2A1, spi_burst_send
.4byte 0x0, 0x00000007, spi_data_wait       # rxfifo full, txfifo wptr at 1000, rxfifo wptr at 0000
.4byte ip, 0x00000003, read32_test        
.4byte rx_data, 0x00000074, read32_test
.4byte rx_data, 0x00000063, read32_test     # clear 2 entries, txfifo wptr at 1000, rxfifo wptr at 0010


.4byte tx_data, 0x000000A4, write32_test
.4byte tx_data, 0x000000B4, write32_test    # tx 1010, rx 0010
.4byte 0x0, 0x00000007, spi_data_wait       # 8 tx 1010, rx 0010
.4byte rx_mark, 0x00000004, write32_test
.4byte rx_data, 0x00000052, read32_test     # 7 rx 0011
.4byte rx_data, 0x00000041, read32_test     # 6 rx 0100
.4byte rx_data, 0x000000A1, read32_test     # 5 rx 0101
.4byte ip, 0x00000003, read32_test          # 5 things in rx fifo
.4byte rx_data, 0x000000B2, read32_test     # 4 tx 1010, rx 0110
.4byte ip, 0x00000001, read32_test          # 4 entries in rxfifo, not strictly greater than 4

.4byte rx_mark, 0x00000007, write32_test
.4byte tx_data, 0xD5C5B5A5, spi_burst_send  # 8 tx1110, rx 0110
.4byte 0x0, 0x00000007, spi_data_wait       

.4byte rx_mark, 0x00000005, write32_test
.4byte rx_data, 0x000000C3, read32_test     # tx 1110, rx 0111
.4byte rx_data, 0x000000D4, read32_test     # tx 1110, rx 1000
.4byte ip, 0x00000003, read32_test          # 6 entries
.4byte rx_data, 0x000000A4, read32_test     # tx 1110, rx 1001
.4byte ip, 0x00000001, read32_test          # 5 entries
.4byte rx_data, 0x000000B4, read32_test     # tx 1110, rx 1010
.4byte rx_data, 0x000000A5, read32_test     # tx 1110, rx 1011

.4byte rx_mark, 0x00000006, write32_test
.4byte tx_data, 0xD7C7B7A7, spi_burst_send
.4byte 0x0, 0x00000006, spi_data_wait       # tx 0010, rx 1011
.4byte tx_mark, 0x00000000, write32_test
.4byte rx_mark, 0x00000000, write32_test
.4byte rx_data, 0x000000B5, read32_test     # tx 0010, rx 1100
.4byte rx_data, 0x000000C5, read32_test     # tx 0010, rx 1101
.4byte rx_data, 0x000000D5, read32_test     # tx 0010, rx 1110
.4byte rx_data, 0x000000A7, read32_test     # tx 0010, rx 1111
.4byte rx_data, 0x000000B7, read32_test     # tx 0010, rx 0000
.4byte rx_data, 0x000000C7, read32_test     # tx 0010, rx 0001
.4byte ip, 0x00000002, read32_test
.4byte rx_data, 0x000000D7, read32_test     # tx 0010, rx 1010
.4byte ip, 0x00000000, read32_test
.4byte tx_mark, 0x00000000, write32_test
.4byte rx_mark, 0x00000000, write32_test    # reset watermark registers

# =========== Basic read-write ===========

.4byte tx_data, 0x000000011, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000011, read32_test     # read rx_data

# =========== Different cs_mode, sck_mode, cs_def, sck_div ===========

# Test sck_div

.4byte sck_div, 0x00000101, write32_test    # set sck_div to 0x101
.4byte tx_data, 0x000000FF, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000FF, read32_test     # read rx_data

# Test min sck_div

.4byte sck_div, 0x000000000, write32_test   #set sck_div to 0
.4byte tx_data, 0xABACADAE, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x000000AE, read32_test
.4byte rx_data, 0x000000AD, read32_test
.4byte rx_data, 0x000000AC, read32_test
.4byte rx_data, 0x000000AB, read32_test

# min sck_div, sckmode 01

.4byte sck_mode, 0x00000001, write32_test
.4byte tx_data, 0xABACADAE, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x000000AE, read32_test
.4byte rx_data, 0x000000AD, read32_test
.4byte rx_data, 0x000000AC, read32_test
.4byte rx_data, 0x000000AB, read32_test

#min sck_div, sckmode 10
.4byte sck_mode, 0x00000002, write32_test
.4byte tx_data, 0xABACADAE, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x000000AE, read32_test
.4byte rx_data, 0x000000AD, read32_test
.4byte rx_data, 0x000000AC, read32_test
.4byte rx_data, 0x000000AB, read32_test

#min sck_div, sckmode 11
.4byte sck_mode, 0x00000003, write32_test
.4byte tx_data, 0xABACADAE, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x000000AE, read32_test
.4byte rx_data, 0x000000AD, read32_test
.4byte rx_data, 0x000000AC, read32_test
.4byte rx_data, 0x000000AB, read32_test


# Test phase

.4byte sck_div, 0x00000003, write32_test    # reset sck_div to 0x03 so only sck_mode is different
.4byte sck_mode, 0x00000001, write32_test   # change phase to falling edge
.4byte tx_data, 0x000000A0, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000A0, read32_test     # read rx_data

# Test polarity 

.4byte sck_mode, 0x00000000, write32_test   # reset sck phase to rising edge
.4byte sck_mode, 0x00000002, write32_test   # set sck polarity active low
.4byte tx_data, 0x0000000B, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x0000000B, read32_test     # read rx_data

# Test phase polarity
.4byte sck_mode, 0x00000003, write32_test   # set sck mode to 11
.4byte tx_data, 0x000000F3, write32_test    # place f3 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       # wait for transmission to end
.4byte rx_data, 0x000000F3, read32_test     # read rx_data

# Test chip select polarity

.4byte sck_mode, 0x00000000, write32_test   # reset sck polarity to active high
.4byte cs_def, 0x0000000E, write32_test     # set cs[0] to inactive low
.4byte tx_data, 0x00000079, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000079, read32_test     # read rx_data

# Test chip id 

.4byte cs_def, 0x0000000F, write32_test     # reset all cs to active low
.4byte cs_id, 0x00000001, write32_test      # select cs[1] 
.4byte tx_data, 0x00000000, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000000, read32_test     # read rx_data

# Test cs hold mode

.4byte cs_id, 0x00000000, write32_test      # select cs[0] 
.4byte cs_mode, 0x00000002, write32_test    # set cs_mode to HOLD
.4byte tx_data, 0x000000C0, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000C0, read32_test     # read rx_data

# Test cs OFF mode

.4byte cs_mode, 0x00000003, write32_test    # set cs_mode to OFF
.4byte tx_data, 0x00000011, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000011, read32_test     # read rx_data

# =========== Test delay0 register ===========

# Test cs-sck delay of 0 with sck phase = 0 (implicit half cycle delay)

.4byte cs_mode, 0x00000000, write32_test    # reset cs_mode to auto, all cs and sck mode settings should be defualt
.4byte delay0, 0x00010000, write32_test     # set cs-sck delay to 0
.4byte tx_data, 0x00000020, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000020, read32_test     # read rx_data

# Test cs-sck delay of 0 with sck phase 1 (no delay)

.4byte sck_mode, 0x00000001, write32_test   # set sck_mode[0] to 1 (sck phase = 1)
.4byte tx_data, 0x00000032, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000032, read32_test     # read rx_data

# Test arbitrary cs-sck delay (sck phase 1)

.4byte delay0, 0x00010005, write32_test     # set cs-sck delay to 5 cycles
.4byte tx_data, 0x00000048, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000048, read32_test     # read rx_data

# Test arbitrary cs-sck delay (sck phase 0)

.4byte sck_mode, 0x00000000, write32_test   # set sck phase to 0
.4byte delay0, 0x00010005, write32_test     # set cs-sck delay to AF cycles
.4byte tx_data, 0x000000AF, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000AF, read32_test     # read rx_data


# Test sck-cs delay of 0 with sck phase = 0 (no delay)

.4byte delay0, 0x00000001, write32_test     # set cs-sck delay to 0
.4byte tx_data, 0x00000050, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000050, read32_test     # read rx_data

# Test sck-cs delay of 0 with sck phase 1 (implicit half cycle delay)

.4byte sck_mode, 0x00000001, write32_test   # set sck_mode[0] to 1 (sck phase = 1)
.4byte tx_data, 0x0000006B, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x0000006B, read32_test     # read rx_data

# Test arbitrary sck-cs delay (sck phase 1)

.4byte delay0, 0x00050001, write32_test     # set cs-sck delay to A5 cycles
.4byte tx_data, 0x00000011, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000011, read32_test     # read rx_data

# Test arbitrary sck-cs delay (sck phase 0)

.4byte sck_mode, 0x00000000, write32_test   # set sck phase to 0
.4byte delay0, 0x00050001, write32_test     # set cs-sck delay to 5 cycles
.4byte tx_data, 0x00000015, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000015, read32_test     # read rx_data

# SCKCS Delay of 0, SCKMODE 10
.4byte sck_mode, 0x00000002, write32_test    #set sckmode to 10
.4byte delay0, 0x00000001, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000010, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000010, read32_test     # reade rx_data

# Arbitrary SCKCS delay, SCKMODE 10
.4byte delay0, 0x00050001, write32_test    # set sckcs delay to 5
.4byte tx_data, 0x00000010, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000010, read32_test     # reade rx_data

# Long SCKCS delay, SCKMODE 10
.4byte delay0, 0x00A50001, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000010, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000010, read32_test     # reade rx_data

# CSSCK Delay 0, SCKMODE 10
.4byte delay0, 0x00010000, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000010, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000010, read32_test     # reade rx_data

# Arbitrary CSSCK delay, SCKMODE 10
.4byte delay0, 0x00010005, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000010, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000010, read32_test     # reade rx_data

# Long CSSCK delay, SCKMODE 10
.4byte delay0, 0x000100A5, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000010, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000010, read32_test     # reade rx_data



# SCKCS Delay of 0, SCKMODE 11
.4byte sck_mode, 0x00000003, write32_test
.4byte delay0, 0x00000001, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000011, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000011, read32_test     # reade rx_data

# Arbitrary SCKCS delay, SCKMODE 11
.4byte delay0, 0x00050001, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000011, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000011, read32_test     # reade rx_data

# Long SCKCS delay, SCKMODE 11
.4byte delay0, 0x00A50001, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000011, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000011, read32_test     # reade rx_data

# CSSCK Delay 0, SCKMODE 11
.4byte delay0, 0x00010000, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000011, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000011, read32_test     # reade rx_data

# Arbitrary CSSCK delay, SCKMODE 11
.4byte delay0, 0x00010005, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000011, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000011, read32_test     # reade rx_data

# Long CSSCK delay, SCKMODE 11
.4byte delay0, 0x000100A5, write32_test    # set sckcs delay to 0
.4byte tx_data, 0x00000011, write32_test    # place 10 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait       #wait for transmission
.4byte rx_data, 0x00000011, read32_test     # reade rx_data

# =========== Test delay1 register ===========

# Test inter cs delay 

.4byte sck_mode, 0x00000000, write32_test   #reset sck_mode
.4byte delay0, 0x00010001, write32_test     # reset delay0 register
.4byte delay1, 0x00000005, write32_test     # set inter_cs delay to 5
.4byte rx_mark, 0x0000003, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x44332211, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000011, read32_test
.4byte rx_data, 0x00000022, read32_test
.4byte rx_data, 0x00000033, read32_test
.4byte rx_data, 0x00000044, read32_test     

#test long inter_cs delay

.4byte delay1, 0x000000A5, write32_test
.4byte rx_mark, 0x0000000, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x0000007B, write32_test
.4byte 0x0, 0x00000000, spi_data_wait
.4byte rx_data, 0x0000007B, read32_test


# Test inter_cs delay set to 0

.4byte delay1, 0x00000000, write32_test     # set inter_cs delay to 5
.4byte rx_mark, 0x0000003, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x54433221, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000021, read32_test
.4byte rx_data, 0x00000032, read32_test
.4byte rx_data, 0x00000043, read32_test
.4byte rx_data, 0x00000054, read32_test


# Test inter_xfr delay of 0 (maybe change behavior to half-period instead of period)

.4byte delay1, 0x00000001, write32_test     # reset inter_cs delay to 1
.4byte cs_mode, 0x00000002, write32_test    # set cs_mode to HOLD 
.4byte tx_data, 0x99887766, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000066, read32_test
.4byte rx_data, 0x00000077, read32_test
.4byte rx_data, 0x00000088, read32_test
.4byte rx_data, 0x00000099, read32_test

# Test inter_xfr delay 0 with phase = 1
.4byte sck_mode, 0x00000001, write32_test
.4byte tx_data, 0x99887766, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x00000066, read32_test
.4byte rx_data, 0x00000077, read32_test
.4byte rx_data, 0x00000088, read32_test
.4byte rx_data, 0x00000099, read32_test


# Test arbitrary inter_xfr delay

.4byte delay1, 0x00050001, write32_test     # set inter_xfr delay to 5
.4byte sck_mode, 0x00000001, write32_test
.4byte tx_data, 0x98877665, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000065, read32_test
.4byte rx_data, 0x00000076, read32_test
.4byte rx_data, 0x00000087, read32_test
.4byte rx_data, 0x00000098, read32_test

# test long inter_xfr delay
.4byte delay1, 0x00A50001, write32_test
.4byte rx_mark, 0x0000000, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x00000048, write32_test
.4byte 0x0, 0x00000000, spi_data_wait
.4byte rx_data, 0x00000048, read32_test

# Test cs-sck delay with cs_mode = HOLD

.4byte delay1, 0x00000001, write32_test     # set inter_xfr delay to 0
.4byte delay0, 0x00010005, write32_test     # set cs-sck delay to 5 (should have no effect because cs is never inactive)
.4byte rx_mark, 0x0000003, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0xAABBCCDD, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000DD, read32_test     # read rx_data
.4byte rx_data, 0x000000CC, read32_test
.4byte rx_data, 0x000000BB, read32_test
.4byte rx_data, 0x000000AA, read32_test

# Test sck-cs delay cs_mode = HOLD

.4byte delay0, 0x00000501, write32_test     # set sck-cs delay to 5 (should have no effect because cs is never inactive)
.4byte tx_data, 0xABBCCDDE, spi_burst_send   # place 8'h11 into tx_data
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000DE, read32_test     # read rx_data
.4byte rx_data, 0x000000CD, read32_test
.4byte rx_data, 0x000000BC, read32_test
.4byte rx_data, 0x000000AB, read32_test

# Test hold mode deassert conditions

.4byte delay1, 0x00000001, write32_test     # reset delay1 register
.4byte delay0, 0x00010001, write32_test     # reset delay0 register
.4byte cs_mode, 0x00000002, write32_test    # set cs_mode to hold
.4byte tx_data, 0x000000CE, write32_test    # place data into tx_data
.4byte cs_id, 0x00000001, write32_test      #change selected cs pin. should deassert cs[0] in hold mode
.4byte cs_def, 0x0000000D, write32_test     # change selected cs pins def value. should deassert cs[1]
.4byte cs_mode, 0x00000000, write32_test    # change cs_mode to auto, should deassert cs[1], have now gone through all deassertion conditions
.4byte cs_def, 0x0000000F, write32_test     # reset cs_def
.4byte cs_id, 0x00000000, write32_test      # reset cs_id
.4byte rx_data, 0x000000CE, read32_test     # clear rx_fifo

# =========== Test frame format (fmt) register ===========

# Test frame length of 4

.4byte delay1, 0x00000001, write32_test     # reset delay1 register
.4byte delay0, 0x00010001, write32_test     # reset delay0 register
.4byte sck_mode, 0x00000000, write32_test   #reset sckmode register
.4byte cs_mode, 0x00000000, write32_test    # set cs_mode to AUTO 
.4byte fmt, 0x00040000, write32_test        # set frame length to 4
.4byte rx_mark, 0x0000000, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x000000F0, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000F0, read32_test     # read rx_data

# Test frame length of 0

#.4byte fmt, 0x00000000, write32_test        # set frame length to 4
#.4byte tx_data, 0x00000077, write32_test   # place 8'h11 into tx_data
#.4byte 0x0, 0x0101, spi_data_wait           # wait for transmission to end
#.4byte rx_data, 0x00000077, read32_test     # read rx_data

# test frame length 1 burst
.4byte fmt, 0x00010000, write32_test
.4byte rx_mark, 0x0000003, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x80008000, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x00000000, read32_test
.4byte rx_data, 0x00000080, read32_test
.4byte rx_data, 0x00000000, read32_test
.4byte rx_data, 0x00000080, read32_test


# Test big endian with frame length = 5

.4byte fmt, 0x00050000, write32_test        # set frame length to 5, big endian
.4byte rx_mark, 0x0000000, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x000000A8, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x000000A8, read32_test     # read rx_data

# Test big endian burst with frame length = 5

.4byte rx_mark, 0x0000003, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x03774FFF, spi_burst_send 
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x000000F8, read32_test 
.4byte rx_data, 0x00000048, read32_test
.4byte rx_data, 0x00000070, read32_test
.4byte rx_data, 0x00000000, read32_test




# Test little endian with frame length = 5

.4byte fmt, 0x00050004, write32_test        # set frame length to 5, little-endian
.4byte rx_mark, 0x0000000, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0x000000A8, write32_test   # place 8'h11 into tx_data
.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
.4byte rx_data, 0x00000008, read32_test     # read rx_data -> 08

#test little endian burst with frame length = 5

.4byte rx_mark, 0x0000003, write32_test     # preset rx watermark b/c of hardware interlock
.4byte tx_data, 0xFF4F7703, spi_burst_send
.4byte 0x0, 0x00000003, spi_data_wait
.4byte rx_data, 0x00000003, read32_test     #03
.4byte rx_data, 0x00000017, read32_test     #17
.4byte rx_data, 0x0000000F, read32_test     #0F
.4byte rx_data, 0x0000001F, read32_test     #1F

# Test dual SPI protocol, frame length = 8, big endian

#.4byte fmt, 0x00080001, write32_test        # set frame length to 8, big-endian, dual SPI
#.4byte tx_data, 0x000000C8, write32_test   # place 8'h11 into tx_data
#.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.4byte rx_data, 0x00000000, read32_test     # read rx_data

# Test dual SPI protocol, frame length = 4

#.4byte fmt, 0x00040001, write32_test        # set frame length to 8, big-endian, dual SPI
#.4byte tx_data, 0x000000A2, write32_test   # place 8'h11 into tx_data
#.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.4byte rx_data, 0x000000A0, read32_test     # read rx_data

# Test dual SPI protocol, frame length = 5

#.4byte fmt, 0x00050001, write32_test        # set frame length to 8, big-endian, dual SPI
#.4byte tx_data, 0x00000075, write32_test   # place 8'h11 into tx_data
#.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.4byte rx_data, 0x00000074, read32_test     # read rx_data

# Test dual SPI protocol burst, frame length = 5
#.4byte tx_data, 0x30733FFF, spi_burst_send
#.4byte 0x0, 0x00000003, spi_data_wait
#.4byte rx_data, 0x000000FC, read32_test
#.4byte rx_data, 0x0000003C, read32_test
#.4byte rx_data, 0x00000070, read32_test
#.4byte rx_data, 0x00000030, read32_test 

# Test quad SPI protocol, frame length = 5

#.4byte fmt, 0x00050002, write32_test        # set frame length to 8, big-endian, dual SPI
#.4byte tx_data, 0x0000003F, write32_test   # place 8'h11 into tx_data
#.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.4byte rx_data, 0x0000003F, read32_test     # read rx_data

# Test quad SPI protocol, frame length = 4

#.4byte fmt, 0x00040002, write32_test        # set frame length to 8, big-endian, dual SPI
#.4byte tx_data, 0x0000000F, write32_test   # place 8'h11 into tx_data
#.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.4byte rx_data, 0x00000000, read32_test     # read rx_data

# Test quad SPI protocol, frame length = 8

#.4byte fmt, 0x00080002, write32_test        # set frame length to 8, big-endian, dual SPI
#.4byte tx_data, 0x000000F0, write32_test   # place 8'h11 into tx_data
#.4byte 0x0, 0x00000000, spi_data_wait           # wait for transmission to end
#.4byte rx_data, 0x000000F0, read32_test     # read rx_data


# =========== Test watermark interrupts ===========

# Test transmit watermark interrupt (triggers when entries in tx FIFO < tx watermark) without external enables

SETUP_PLIC
.4byte fmt, 0x00080000, write32_test        # reset format register
.4byte delay1, 0x0000001, write32_test      # reset delay1 register
.4byte cs_mode, 0x00000000, write32_test    # reset cs_mode
.4byte tx_mark, 0x00000001, write32_test    # set transmit watermark to 1 (any entry turns mark off)
.4byte sck_div, 0x00000100, write32_test    # lower SPI clock rate so read32_tests trigger at correct times
#.4byte ie, 0x00000000, write32_test         # enable transmit interrupt
.4byte ip, 0x00000001, read32_test          # tx watermark interupt should be pending
.4byte 0x0, 0x00000000, readmip_test
.4byte tx_data, 0x55443322, spi_burst_send    # place 4 entries in transmit fifo
.4byte ip, 0x00000000, read32_test          # tx watermark interupt should be off 125
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end

# test recieve watermark interrupt (triggers when entries in rx FIFO > rx watermark)

.4byte tx_mark, 0x00000000, write32_test      # set tx_mark to 0
.4byte rx_data, 0x00000022, read32_test       # clear one entry from rx FIFO
.4byte rx_mark, 0x00000003, write32_test      # set recieve watermark to 3
#.4byte ie, 0x0000002, write32_test          # enable receive interrupts
.4byte ip, 0x00000000, read32_test          # rx interrupts should be low (rx FIFO has 3 entries)
.4byte rx_mark, 0x00000002, write32_test    # set recieve watermark to 2
.4byte ip, 0x00000002, read32_test          # recieve interrupt should be high
.4byte 0x0, 0x00000000, readmip_test
.4byte rx_data, 0x00000033, read32_test     # clear one more entry from recieve FIFO (2 entries)
.4byte ip, 0x00000000, read32_test          # receive interrupt should be low
.4byte rx_data, 0x00000044, read32_test
.4byte rx_data, 0x00000055, read32_test     # clear rx fifo


.4byte tx_mark, 0x00000001, write32_test    # set transmit watermark to 0
.4byte ie, 0x00000001, write32_test         # enable transmit interrupt
.4byte ip, 0x00000001, read32_test          # tx watermark interupt should be pending
.4byte 0x0, 0x00000800, readmip_test
.4byte ie, 0x00000000, write32_test      # disable tx intr
.4byte tx_data, 0x55443322, spi_burst_send    # place 4 entries in transmit fifo
.4byte 0x0, 0x00000003, spi_data_wait           # wait for transmission to end

# test recieve watermark interrupt (triggers when entries in rx FIFO > rx watermark)

.4byte tx_mark, 0x00000000, write32_test
.4byte 0x0, 0x00000000, claim_m_plic_interrupts
.4byte rx_data, 0x00000022, read32_test       # clear one entry from rx FIFO
.4byte rx_mark, 0x00000003, write32_test      # set recieve watermark to 3
.4byte ie, 0x0000002, write32_test          # enable receive interrupts
.4byte ip, 0x00000000, read32_test          # rx interrupts should be low (rx FIFO has 3 entries)
.4byte 0x0, 0x00000000, readmip_test
.4byte rx_mark, 0x00000002, write32_test    # set recieve watermark to 2
.4byte ip, 0x00000002, read32_test          # recieve interrupt should be high
.4byte 0x0, 0x00000800, readmip_test
.4byte rx_data, 0x00000033, read32_test     # clear one more entry from recieve FIFO (2 entries)
.4byte 0x0, 0x00000000, claim_m_plic_interrupts
.4byte ip, 0x00000000, read32_test          # receive interrupt should be low
.4byte 0x0, 0x00000000, readmip_test



.4byte 0x0, 0x0, terminate_test

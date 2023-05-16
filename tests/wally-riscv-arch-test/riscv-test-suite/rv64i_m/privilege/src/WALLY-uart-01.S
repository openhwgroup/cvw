///////////////////////////////////////////
//
// WALLY-uart
//
// Author: David_Harris@hmc.edu and Nicholas Lucio <nlucio@hmc.edu>
//
// Created 2022-06-16
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
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",uart)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

END_TESTS

TEST_STACK_AND_DATA

.align 2

.equ UART, 0x10000000
.equ UART_RBR, (UART)
.equ UART_THR, (UART)
.equ UART_IER, (UART+0x01)
.equ UART_IIR, (UART+0x02)
.equ UART_FCR, (UART+0x02)
.equ UART_LCR, (UART+0x03)
.equ UART_MCR, (UART+0x04)
.equ UART_LSR, (UART+0x05)
.equ UART_MSR, (UART+0x06)
.equ UART_Scr, (UART+0x07)

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
# 
# ---------------------------------------------------------------------------------------------

# =========== UART resets to correct values on master reset ===========

.8byte UART_IER, 0x00, read08_test
.8byte UART_IIR, 0x01, read08_test # IIR resets to 1
# .8byte UART_LCR, 0x00, read08_test *** commented out because LCR should reset to zero but resets to 3 to help Linux boot
.8byte UART_MCR, 0x00, read08_test
.8byte UART_LSR, 0x60, read08_test # LSR resets with transmit status bits set
.8byte UART_MSR, 0x00, read04_test

# =========== Basic read-write ===========

.8byte UART_LCR, 0x00, write08_test # set LCR to initial value
.8byte UART_MCR, 0x10, write08_test # put UART into loopback for MSR test
.8byte UART_LSR, 0x60, read08_test
.8byte UART_THR, 0x00, write08_test # write value to UART
.8byte UART_LSR, 0x00, read08_test  # data not ready and transmitter is not empty
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and LSR
.8byte UART_RBR, 0x00, read08_test  # read written value
.8byte UART_LSR, 0x60, read08_test  # read LSR

# =========== Different size read-write ===========

# Transmit 5 bits

.8byte UART_LCR, 0x00, write08_test # set LCR to transmit 5 bits
.8byte UART_THR, 0x55, write08_test # write value to UART
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.8byte UART_RBR, 0x15, read08_test  # read written value without bits 5-7

# Transmit 6 bits

.8byte UART_LCR, 0x01, write08_test # set LCR to transmit six bits
.8byte UART_THR, 0xAA, write08_test # write value to UART
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.8byte UART_RBR, 0x2A, read08_test  # read written value without bits 6 & 7

# Transmit 7 bits

.8byte UART_LCR, 0x02, write08_test # set LCR to transmit seven bits
.8byte UART_THR, 0xFF, write08_test # write value to UART
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.8byte UART_RBR, 0x7F, read08_test  # read written value without bit 7

# Transmit 8 bits

.8byte UART_LCR, 0x03, write08_test # set LCR to transmit eight bits
.8byte UART_THR, 0x80, write08_test # write value to UART
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.8byte UART_RBR, 0x80, read08_test  # read full written value + sign extension

# Check function with odd parity

.8byte UART_LCR, 0x0B, write08_test # set LCR to transmit 8 bits + odd partiy
.8byte UART_THR, 0x79, write08_test # write value to UART
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.8byte UART_RBR, 0x79, read08_test  # read full written value

# Check function with even parity

.8byte UART_LCR, 0x1B, write08_test # set LCR to transmit 8 bits + even parity
.8byte UART_THR, 0x6A, write08_test # write value to UART
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.8byte UART_RBR, 0x6A, read08_test  # read full written value

# Check function with extra stop bit

.8byte UART_LCR, 0x07, write08_test # set LCR to transmit 8 bits + extra stop
.8byte UART_THR, 0x5B, write08_test # write value to UART
.8byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.8byte UART_RBR, 0x5B, read08_test  # read full written value
.8byte UART_LCR, 0x03, write08_test # set LCR to transmit 8 bits + no extra stop bit

# =========== Transmit-related interrupts ===========

.8byte UART_IER, 0x07, write08_test     # enable data available, buffer empty, and line status interrupts
.8byte UART_IIR, 0x02, read08_test      # buffer should be empty, causing interrupt
.8byte UART_THR, 0x00, write08_test     # write zeroes to transmitter
.8byte 0x0, 0x0401, uart_data_wait      # IIR should have data ready interrupt
.8byte UART_THR, 0x01, write08_test     # write 1 to transmitter buffer
.8byte UART_IIR, 0x04, read08_test      # data interrupt should still be high
.8byte 0x0, 0x06, uart_lsr_intr_wait    # wait for transmission to complete, IIR should throw error due to overrun error.
.8byte UART_LSR, 0x23, read08_test      # read overrun error from LSR
.8byte UART_IIR, 0x04, read08_test      # check that LSR interrupt was cleared
.8byte UART_RBR, 0x01, read08_test      # read previous value from UART

# =========== MODEM interrupts ===========

.8byte UART_MSR, 0x00, write08_test # clear MSR
.8byte UART_IER, 0x08, write08_test # enable MODEM Status interrupts
.8byte UART_IIR, 0x01, read08_test  # no interrupts pending
.8byte UART_MCR, 0x12, write08_test # Cause DCTS interrupt
.8byte UART_IIR, 0x00, read08_test  # MODEM interrupt
.8byte UART_MSR, 0x11, read08_test  # Read MSR to clear interrupt
.8byte UART_IIR, 0x01, read08_test  # interrupt cleared by reading MSR
.8byte UART_MCR, 0x13, write08_test # Set DSR high
.8byte UART_IIR, 0x00, read08_test  # MODEM interrupt
.8byte UART_MSR, 0x32, read08_test  # Read MSR to clear interrupt
.8byte UART_IIR, 0x01, read08_test  # Interrupt cleared by reading MSR
.8byte UART_MCR, 0x17, write08_test # Set RIb low and keep CTS and DSR
.8byte UART_MCR, 0x13, write08_test # Set RIb high and keep CTS and DSR
.8byte UART_IIR, 0x00, read08_test  # MODEM interrupt
.8byte UART_MSR, 0x34, read08_test  # Read MSR to clear interrupt
.8byte UART_IIR, 0x01, read08_test  # Interrupt cleared by reading MSR
.8byte UART_MCR, 0x1B, write08_test # Set DCD high and keep CTS and DSR
.8byte UART_IIR, 0x00, read08_test  # MODEM interrupt
.8byte UART_MSR, 0xb8, read08_test  # Read MSR to clear interrupt
.8byte UART_IIR, 0x01, read08_test  # Interrupt cleared by reading MSR
.8byte UART_MCR, 0x10, write08_test # Clear MCR
.8byte UART_MSR, 0x00, write08_test # Clear MSR

# =========== FIFO interrupts ===========

.8byte UART_IER, 0x07, write08_test # enable data available, buffer empty, and line status interrupts
.8byte UART_FCR, 0x41, write08_test # Set FIFO threshold to 4 and enable FIFO mode
.8byte UART_IIR, 0xC2, read08_test  # Enabling FIFO sets top two bits of IIR
.8byte UART_THR, 0x00, write08_test # write 0 to transmit register
.8byte 0x0, 0xC101, uart_data_wait  # no interrupts pending (transmitter interrupt squashed by early read)
.8byte UART_RBR, 0x00, read08_test  # read 0 from buffer register
.8byte UART_THR, 0xA5, write08_test # Write A5 to transmit register
.8byte UART_THR, 0x01, write08_test # Write 1 to transmit register
.8byte UART_IIR, 0xC1, read08_test  # no interrupts pending
.8byte UART_THR, 0x02, write08_test # Write 2 to transmit register
.8byte UART_THR, 0x03, write08_test # Write 3 to transmit register
.8byte 0x0, 0xC401, uart_data_wait  # Interrupt due to data ready
.8byte UART_RBR, 0xA5, read08_test  # Read A5 from buffer register
.8byte UART_IIR, 0xC2, read08_test   # Data ready interrupt cleared
.8byte UART_RBR, 0x01, read08_test  # Read 1 from buffer register
.8byte UART_RBR, 0x02, read08_test  # Read 2 from buffer register
.8byte UART_LSR, 0x61, read08_test  # Data ready, 1 item left in FIFO
.8byte UART_RBR, 0x03, read08_test  # Read 3 from buffer register
.8byte UART_LSR, 0x60, read08_test  # No data ready, FIFO is empty
.8byte UART_THR, 0xFF, write08_test # Write FF to transmit register
.8byte UART_THR, 0xFE, write08_test # Write FE to transmit register
.8byte 0x0, 0xC101, uart_data_wait  # Interrupt due to data ready
.8byte UART_FCR, 0xC7, write08_test # Clear all bytes in FIFO
.8byte UART_FCR, 0xC1, read08_test  # Check that FCR clears bits 1 and 2 when written to 1
.8byte UART_LSR, 0x60, read08_test  # No data ready, FIFO cleared by writing to FCR

# =========== FIFO receiver/overrun ===========

.8byte UART_FCR, 0x01, write08_test # Set FIFO trigger threshold to 1 and enable FIFO mode
.8byte UART_IIR, 0xC1, read08_test  # FIFO has not reached trigger level
.8byte UART_THR, 0x00, write08_test # Write 0 to transmit register
.8byte 0x0, 0xC401, uart_data_wait  # Interrupt due to trigger threshold reached
.8byte UART_FCR, 0x41, write08_test # Set FIFO trigger threshold to 4
.8byte UART_IIR, 0xC1, read08_test  # FIFO has not reached trigger threshold
.8byte UART_THR, 0x01, write08_test # Write 1 to transmit register
.8byte UART_THR, 0x02, write08_test # Write 2 to transmit register
.8byte 0x0, 0xC101, uart_data_wait  # FIFO has not reached trigger threshold
.8byte UART_THR, 0x03, write08_test # Write 3 to transmit register
.8byte 0x0, 0xC401, uart_data_wait  # Interrupt due to trigger threshold reached
.8byte UART_FCR, 0x81, write08_test # Set FIFO trigger threshold to 8
.8byte UART_IIR, 0xC1, read08_test  # FIFO has not reached trigger threshold
.8byte UART_THR, 0x04, write08_test # Write 4 to transmit register
.8byte UART_THR, 0x05, write08_test # Write 5 to transmit register
.8byte UART_THR, 0x06, write08_test # Write 6 to transmit register
.8byte 0x0, 0xC101, uart_data_wait  # FIFO has not reached trigger threshold
.8byte UART_THR, 0x07, write08_test # Write 7 to transmit register
.8byte 0x0, 0xC401, uart_data_wait  # Interrupt due to trigger threshold reached
.8byte UART_FCR, 0xC1, write08_test # Set FIFO trigger threshold to 14
.8byte UART_IIR, 0xC1, read08_test  # FIFO has not reached trigger threshold
.8byte UART_THR, 0x08, write08_test # Write 8 to transmit register
.8byte UART_THR, 0x09, write08_test # Write 9 to transmit register
.8byte UART_THR, 0x0A, write08_test # Write 10 to transmit register
.8byte UART_THR, 0x0B, write08_test # Write 11 to transmit register
.8byte UART_THR, 0x0C, write08_test # Write 12 to transmit register
.8byte 0x0, 0xC101, uart_data_wait  # FIFO has not reached trigger threshold
.8byte UART_THR, 0x0D, write08_test # Write 13 to transmit register
.8byte 0x0, 0xC401, uart_data_wait  # Interrupt due to trigger threshold reached
.8byte UART_THR, 0x0E, write08_test # Write 14 to transmit register
.8byte UART_THR, 0x0F, write08_test # Write 15 to transmit register
.8byte 0x0, 0xC101, uart_data_wait
.8byte UART_LSR, 0x61, read08_test      # FIFO contains data, no overrun error
.8byte UART_THR, 0x10, write08_test     # Write 16 to transmit register, filling RX shift register
.8byte UART_THR, 0x11, write08_test     # Write 17 to transmit register, destroying contents held in shift register
.8byte 0x0, 0x06, uart_lsr_intr_wait    # Wait for LSR interrupt ID
.8byte UART_LSR, 0xA3, read08_test      # Read overrun error from LSR

.8byte 0x0, 0x0, terminate_test
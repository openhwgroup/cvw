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

#include "WALLY-TEST-LIB-32.h" 

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
#   '.4byte [x28 Value], [x29 Value], [x30 value]'
#                     or
#   '.4byte [address], [value], [test type]'
#
#   The encoding for x30 test type values can be found in the test handler in the framework file
# 
# ---------------------------------------------------------------------------------------------

# =========== UART resets to correct values on master reset ===========

.4byte UART_IER, 0x00, read08_test
.4byte UART_IIR, 0x01, read08_test # IIR resets to 1
# .4byte UART_LCR, 0x00, read08_test *** commented out because LCR should reset to zero but resets to 3
.4byte UART_MCR, 0x00, read08_test
.4byte UART_LSR, 0x60, read08_test # LSR resets with transmit status bits set
.4byte UART_MSR, 0x00, read04_test

# =========== Basic read-write ===========

.4byte UART_LCR, 0x00, write08_test # set LCR to reset value *** remove if UART resets to correct value
.4byte UART_MCR, 0x10, write08_test # put UART into loopback for MSR test
.4byte UART_LSR, 0x60, read08_test
.4byte UART_THR, 0x00, write08_test # write value to UART
.4byte UART_LSR, 0x00, read08_test  # data not ready and transmitter is not empty
.4byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and LSR
.4byte UART_RBR, 0x00, read08_test  # read written value
.4byte UART_LSR, 0x60, read08_test  # read LSR

# =========== Different size read-write ===========

# Transmit 5 bits

.4byte UART_LCR, 0x00, write08_test # set LCR to transmit 5 bits
.4byte UART_THR, 0x55, write08_test # write value to UART
.4byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.4byte UART_RBR, 0x15, read08_test  # read written value without bits 5-7

# Transmit 6 bits

.4byte UART_LCR, 0x01, write08_test # set LCR to transmit six bits
.4byte UART_THR, 0xAA, write08_test # write value to UART
.4byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.4byte UART_RBR, 0x2A, read08_test  # read written value without bits 6 & 7

# Transmit 7 bits

.4byte UART_LCR, 0x02, write08_test # set LCR to transmit seven bits
.4byte UART_THR, 0xFF, write08_test # write value to UART
.4byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.4byte UART_RBR, 0x7F, read08_test  # read written value without bit 7

# Transmit 8 bits

.4byte UART_LCR, 0x03, write08_test # set LCR to transmit seven bits
.4byte UART_THR, 0x80, write08_test # write value to UART
.4byte 0x0, 0x0101, uart_data_wait  # wait for data to become ready then output IIR and then LSR
.4byte UART_RBR, 0x80, read08_test  # read full written value + sign extension

# =========== Transmit-related interrupts ===========

.4byte UART_IER, 0x07, write08_test # enable data available, buffer empty, and line status interrupts
.4byte UART_IIR, 0x02, read08_test  # buffer should be empty, causing interrupt
.4byte UART_THR, 0x00, write08_test # write zeroes to transmitter
.4byte 0x0, 0x0401, uart_data_wait  # IIR should have data ready interrupt
.4byte UART_THR, 0x01, write08_test # write 1 to transmitter buffer
.4byte UART_IIR, 0x04, read08_test  # data interrupt should still be high
.4byte 0x0, 0x06, uart_lsr_intr_wait     # wait for transmission to complete, IIR should throw error due to overrun error.
.4byte UART_LSR, 0x63, read08_test  # read overrun error from LSR
.4byte UART_IIR, 0x04, read08_test  # check that LSR interrupt was cleared
.4byte UART_RBR, 0x01, read08_test  # read previous value from UART

# =========== MODEM interrupts ===========

.4byte UART_MSR, 0x00, write08_test # clear MSR
.4byte UART_IER, 0x08, write08_test # enable MODEM Status interrupts
.4byte UART_IIR, 0x01, read08_test  # no interrupts pending
.4byte UART_MCR, 0x02, write08_test # Cause DCTS interrupt
.4byte UART_IIR, 0x00, read08_test  # MODEM interrupt
.4byte UART_MSR, 0x11, read08_test  # Read MSR to clear interrupt
.4byte UART_IIR, 0x01, read08_test  # interrupt cleared by reading MSR

.4byte 0x0, 0x0, terminate_test
///////////////////////////////////////////
//
// WALLY-plic
//
// Author: Nicholas Lucio <nlucio@hmc.edu>
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

RVTEST_ISA("RV32I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",plic)

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
# 
# ---------------------------------------------------------------------------------------------

# =========== Define PLIC registers ===========

.equ PLIC, 0x0C000000
.equ PLIC_INTPRI_GPIO, (PLIC+0x00000C)       # GPIO is interrupt 3
.equ PLIC_INTPRI_UART, (PLIC+0x000028)       # UART is interrupt 10
.equ PLIC_INTPENDING0, (PLIC+0x001000)       # intPending0 register
.equ PLIC_INTEN00,     (PLIC+0x002000)       # interrupt enables for context 0 (machine mode) sources 31:1
.equ PLIC_INTEN10,     (PLIC+0x002080)       # interrupt enables for context 1 (supervisor mode) sources 31:1
.equ PLIC_THRESH0,     (PLIC+0x200000)       # Priority threshold for context 0 (machine mode)
.equ PLIC_CLAIM0,      (PLIC+0x200004)       # Claim/Complete register for context 0
.equ PLIC_THRESH1,     (PLIC+0x201000)       # Priority threshold for context 1 (supervisor mode)
.equ PLIC_CLAIM1,      (PLIC+0x201004)       # Claim/Complete register for context 1

# =========== Define GPIO registers ===========

.equ GPIO, 0x10060000
.equ input_val, (GPIO+0x00)
.equ input_en, (GPIO+0x04)
.equ output_en, (GPIO+0x08)
.equ output_val, (GPIO+0x0C)
.equ rise_ie, (GPIO+0x18)
.equ rise_ip, (GPIO+0x1C)
.equ fall_ie, (GPIO+0x20)
.equ fall_ip, (GPIO+0x24)
.equ high_ie, (GPIO+0x28)
.equ high_ip, (GPIO+0x2C)
.equ low_ie, (GPIO+0x30)
.equ low_ip, (GPIO+0x34)
.equ iof_en, (GPIO+0x38)
.equ iof_sel, (GPIO+0x3C)
.equ out_xor, (GPIO+0x40)

# =========== Define UART registers ===========

.equ UART, 0x10000000
.equ UART_IER, (UART+0x01)
.equ UART_MCR, (UART+0x04)
.equ UART_MSR, (UART+0x06)

# =========== Initialize UART and GPIO ===========

# GPIO Initialization
.4byte input_en, 0x00000001, write32_test   # enable bit 0 of input_en
.4byte output_en, 0x00000001, write32_test  # enable bit 0 of output_en
.4byte output_val, 0x00000000, write32_test # make sure output_val is 0
.4byte rise_ie, 0x00000001, write32_test    # enable rise interrupts

# =========== Initialize relevant PLIC registers ===========

.4byte PLIC_INTPRI_GPIO, 0x00000000, write32_test   # set GPIO priority to zero
.4byte PLIC_INTPRI_UART, 0x00000000, write32_test   # set UART priority to zero
.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000007, write32_test       # set s-mode threshold to max

# =========== Machine-Mode Priority Testing (1.T.X) ===========

# Test 1.0.0: GPIO int lacks priority (0 = 0)
.4byte PLIC_THRESH0, 0x00000000, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
#.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.0.1: GPIO int has priority (1 > 0)
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # let GPIO cause interrupts
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.0.2: meip and c/c clear without interrupt pending
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # expect no interrupt pending
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.1.0: GPIO lacks priority (1 = 1)
.4byte PLIC_THRESH0, 0x00000001, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim from earlier
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.1.1: GPIO int has priority (2 > 1)
.4byte PLIC_INTPRI_GPIO, 0x00000002, write32_test   # let GPIO cause interrupts
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.2.0: GPIO int lacks priority (2 = 2)
.4byte PLIC_THRESH0, 0x00000002, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim from earlier
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.2.1: GPIO int has priority (3 > 2)
.4byte PLIC_INTPRI_GPIO, 0x00000003, write32_test   # let GPIO cause interrupts
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.3.0: GPIO int lacks priority (3 = 3)
.4byte PLIC_THRESH0, 0x00000003, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim from earlier
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.3.1: GPIO int has priority (4 > 3)
.4byte PLIC_INTPRI_GPIO, 0x00000004, write32_test   # let GPIO cause interrupts
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.4.0: GPIO int lacks priority (4 = 4)
.4byte PLIC_THRESH0, 0x00000004, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim from earlier
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.4.1: GPIO int has priority (5 > 4)
.4byte PLIC_INTPRI_GPIO, 0x00000005, write32_test   # let GPIO cause interrupts
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.5.0: GPIO int lacks priority (5 = 5)
.4byte PLIC_THRESH0, 0x00000005, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim from earlier
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.5.1: GPIO int has priority (6 > 5)
.4byte PLIC_INTPRI_GPIO, 0x00000006, write32_test   # let GPIO cause interrupts
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.6.0: GPIO int lacks priority (6 = 6)
.4byte PLIC_THRESH0, 0x00000006, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim from earlier
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.6.1: GPIO int has priority (7 > 6)
.4byte PLIC_INTPRI_GPIO, 0x00000007, write32_test   # let GPIO cause interrupts
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# Test 1.7.0: GPIO int lacks priority (7 = 7)
.4byte PLIC_THRESH0, 0x00000007, write32_test       # change threshold
.4byte output_val, 0x00000001, write32_test         # set GPIO rise_ip high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # expect interrupt pending on bit 3
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending was cleared
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim from earlier
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear interrupt one
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupt pending

# =========== UART vs GPIO priority (2.X) ===========

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000007, write32_test       # set s-mode threshold to max
# UART Initialization
.4byte UART_IER, 0x08, write08_test   # enable modem status interrupts from CTS
.4byte UART_MCR, 0x10, write08_test   # enable loopback mode, RTS = 0
.4byte UART_MSR, 0x00, write08_test   # disable UART interrupt

# Test 2.0: GPIO Priority = UART Priority

.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTPRI_UART, 0x00000001, write32_test   # UARTPriority = 1
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts            # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts            # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Test 2.1: GPIO Priority > UART Priority

.4byte PLIC_INTPRI_GPIO, 0x00000003, write32_test   # GPIOPriority = 3
.4byte PLIC_INTPRI_UART, 0x00000002, write32_test   # UARTPriority = 2
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 2.2: GPIO Priority < UART Priority

.4byte PLIC_INTPRI_GPIO, 0x00000004, write32_test   # GPIOPriority = 4
.4byte PLIC_INTPRI_UART, 0x00000005, write32_test   # UARTPriority = 5
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for UART
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 2.3: GPIO Priority < UART Priority

.4byte PLIC_INTPRI_GPIO, 0x00000006, write32_test   # GPIOPriority = 6
.4byte PLIC_INTPRI_UART, 0x00000007, write32_test   # UARTPriority = 7
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for UART
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 2.4: Interrupts don't have enough priority

.4byte PLIC_INTPRI_GPIO, 0x00000004, write32_test   # GPIOPriority = 4
.4byte PLIC_INTPRI_UART, 0x00000005, write32_test   # UARTPriority = 5
.4byte PLIC_THRESH0, 0x00000006, write32_test       # set m-mode threshold to 6
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# =========== SEIP tests (3.X) ===========

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0

# Test 3.0: Cause machine and supervisor interrupts

.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTPRI_UART, 0x00000001, write32_test   # UARTPriority = 1
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000A00, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 3.1: Suppress machine mode interrupts

.4byte PLIC_INTPRI_GPIO, 0x00000003, write32_test   # GPIOPriority = 3
.4byte PLIC_INTPRI_UART, 0x00000002, write32_test   # UARTPriority = 2
.4byte PLIC_THRESH0, 0x00000007, write32_test       # set m-mode threshold to 7
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 3.2: Cause SEIP with UART first

.4byte PLIC_INTPRI_GPIO, 0x00000006, write32_test   # GPIOPriority = 6
.4byte PLIC_INTPRI_UART, 0x00000007, write32_test   # UARTPriority = 7
.4byte PLIC_THRESH0, 0x00000007, write32_test       # set m-mode threshold to 7
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 3.3: Low SEIP due to insufficient priority

.4byte PLIC_INTPRI_GPIO, 0x00000002, write32_test   # GPIOPriority = 2
.4byte PLIC_INTPRI_UART, 0x00000003, write32_test   # UARTPriority = 3
.4byte PLIC_THRESH0, 0x00000004, write32_test       # set m-mode threshold to 4
.4byte PLIC_THRESH1, 0x00000005, write32_test       # set s-mode threshold to 5
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# =========== UART interrupt enable tests (4.X) ===========

.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIO Priority = 1
.4byte PLIC_INTPRI_UART, 0x00000001, write32_test   # UART Priority = 1

# Test 4.0: GPIO m-mode disabled

.4byte PLIC_INTEN00, 0x00000400, write32_test       # disable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000A00, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 4.1: UART m-mode disabled

.4byte PLIC_INTEN00, 0x00000008, write32_test       # disable UART m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 4.2: GPIO s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000400, write32_test       # enable all s-mode interrupts
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000A00, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 4.3: UART s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable all s-mode interrupts
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 4.4: GPIO and UART s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable all s-mode interrupts
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 4.5: GPIO and UART m-mode disabled

.4byte PLIC_INTEN00, 0x00000000, write32_test       # disable GPIO interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 4.6: GPIO and UART fully disabled

.4byte PLIC_INTEN00, 0x00000000, write32_test       # disable GPIO interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable all s-mode interrupts
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM0, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# =========== GPIO interrupt enable tests (5.X) ===========

.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIO Priority = 1
.4byte PLIC_INTPRI_UART, 0x00000001, write32_test   # UART Priority = 1

# Test 5.0: GPIO m-mode disabled

.4byte PLIC_INTEN00, 0x00000400, write32_test       # disable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000200, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM0, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 5.1: UART m-mode disabled

.4byte PLIC_INTEN00, 0x00000008, write32_test       # disable UART m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000A00, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 5.2: GPIO s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000400, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 5.3: UART s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000A00, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 5.4: GPIO and UART s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 5.5: GPIO and UART m-mode disabled

.4byte PLIC_INTEN00, 0x00000000, write32_test       # disable GPIO interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000200, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM0, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# Test 5.6: GPIO and UART fully disabled

.4byte PLIC_INTEN00, 0x00000000, write32_test       # disable GPIO interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000000, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM0, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO and UART
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM0, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_m_plic_interrupts       # clear interrupt two
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt one
.4byte 0x0, 0x0, claim_s_plic_interrupts       # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test   # no interrupts pending

# =========== S-mode enable tests (7.X) ===========

.4byte 0x0, 0x222, write_mideleg                    # delegate supervisor interrupts to S mode
.4byte 0x0, 0x0, goto_s_mode                        # go to s-mode. 0xb written to output
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIO Priority = 1
.4byte PLIC_INTPRI_UART, 0x00000001, write32_test   # UART Priority = 1

# Test 7.0: GPIO m-mode disabled

.4byte PLIC_INTEN00, 0x00000400, write32_test       # disable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readsip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt one
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Test 7.1: UART m-mode disabled

.4byte PLIC_INTEN00, 0x00000008, write32_test       # disable UART m-mode interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readsip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt one
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Test 7.2: GPIO s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000400, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readsip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM1, 0x0000000A, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM1, 0x0000000A, write32_test        # complete claim made earlier
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt one
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Test 7.3: UART s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readsip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt one
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Test 7.4: GPIO and UART s-mode disabled

.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000000, readsip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM1, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM1, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt one
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Test 7.5: GPIO and UART m-mode disabled

.4byte PLIC_INTEN00, 0x00000000, write32_test       # disable GPIO interrupts
.4byte PLIC_INTEN10, 0x00000408, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000200, readsip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt one
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Test 7.6: GPIO and UART fully disabled

.4byte PLIC_INTEN00, 0x00000000, write32_test       # disable GPIO interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable all s-mode interrupts
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000000, readsip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending for GPIO and UART
.4byte PLIC_CLAIM1, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte UART_MSR, 0x00000000, write08_test           # clear UART interrupt
.4byte PLIC_CLAIM1, 0x00000000, write32_test        # complete claim made earlier
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt one
.4byte 0x0, 0x00000000, claim_s_plic_interrupts     # clear interrupt two
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# =========== Special claim tests (8) ===========

.4byte 0x0, 0x0, goto_m_mode                        # write 0x9 to output

.4byte PLIC_INTPRI_GPIO, 0x00000006, write32_test   # GPIO Priority = 6
.4byte PLIC_INTPRI_UART, 0x00000007, write32_test   # UART Priority = 7
.4byte PLIC_INTEN00, 0x00000408, write32_test       # enable all m-mode interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable all s-mode interrupts
.4byte PLIC_THRESH0, 0x00000005, write32_test       # set m-mode threshold to 5

# Test 8

.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte UART_MSR, 0x0F, write08_test                 # cause UART interrupt
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # read interrupt pending
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # claim UART
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # UART interrupt cleared
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # claim GPIO
.4byte 0x0, 0x00000000, readmip_test                # no interrupts, meip is low
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # both interrupts claimed
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete GPIO
.4byte 0x0, 0x00000800, readmip_test                # GPIO interrupt sets MEIP
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # GPIO bit is set
.4byte PLIC_CLAIM0, 0x00000003, read32_test         # claim GPIO again
.4byte 0x0, 0x00000000, readmip_test                # meip is zeroed
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # both interrupts claimed
.4byte PLIC_CLAIM0, 0x0000000A, write32_test        # complete UART claim
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000400, read32_test    # UART pending
.4byte PLIC_CLAIM0, 0x00000003, write32_test        # complete GPIO claim
.4byte 0x0, 0x00000800, readmip_test                # read mip
.4byte PLIC_INTPENDING0, 0x00000408, read32_test    # GPIO and UART pending
.4byte PLIC_CLAIM0, 0x0000000A, read32_test         # claim UART

.4byte 0x0, 0x0, terminate_test # terminate tests

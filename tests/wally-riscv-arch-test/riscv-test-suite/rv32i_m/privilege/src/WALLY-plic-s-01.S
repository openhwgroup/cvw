///////////////////////////////////////////
//
// WALLY-plic-s
//
// Author: David_Harris@hmc.edu and Nicholas Lucio <nlucio@hmc.edu>
// Test PLIC supervisor context interrupts and claim/complete
//
// Created 2022-07-29
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
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",plic-s)

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
.equ PLIC_INTPRI_UART, (PLIC+0x000028)      # UART is interrupt 10
.equ PLIC_INTPENDING0, (PLIC+0x001000)       # intPending0 register
.equ PLIC_INTPENDING1, (PLIC+0x001004)       # intPending0 register
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

# =========== Initialize  GPIO ===========

# GPIO Initialization
.4byte input_en, 0x00000001, write32_test   # enable bit 0 of input_en
.4byte output_en, 0x00000001, write32_test  # enable bit 0 of output_en
.4byte output_val, 0x00000000, write32_test # make sure output_val is 0
.4byte rise_ie, 0x00000001, write32_test    # enable rise interrupts

# =========== Initialize relevant PLIC registers ===========

.4byte PLIC_INTPRI_UART, 0x00000000, write32_test   # set UART priority to 0 to never interrupt 

# =========== Enter Supervisor Mode ===========

.4byte 0x0, 0x222, write_mideleg                    # delegate supervisor interrupts to S mode
.4byte 0x0, 0x0, goto_s_mode                        # Enter supervisor mode

# =========== Test interrupt enables and priorities ===========

# Case 1.1:
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTEN00, 0x00000008, write32_test       # enable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable GPIO s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000200, readsip_test                # read sip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_s_plic_interrupts	    # clear interrupt from PLIC
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Case 1.2:
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTEN00, 0x00000000, write32_test       # enable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable GPIO s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000200, readsip_test                # read sip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_s_plic_interrupts	    # clear interrupt from PLIC
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Case 1.3:
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTEN00, 0x00000008, write32_test       # enable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable GPIO s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000000, readsip_test                # read sip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO
.4byte PLIC_CLAIM1, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_s_plic_interrupts	    # clear interrupt from PLIC
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Case 1.4:
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTEN00, 0x00000000, write32_test       # enable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000000, write32_test       # enable GPIO s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000000, readsip_test                # read sip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO
.4byte PLIC_CLAIM1, 0x00000000, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_s_plic_interrupts	    # clear interrupt from PLIC
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Case 1.5:
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTEN00, 0x00000008, write32_test       # enable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable GPIO s-mode interrupts
.4byte PLIC_THRESH0, 0x00000000, write32_test       # set m-mode threshold to 0
.4byte PLIC_THRESH1, 0x00000005, write32_test       # set s-mode threshold to 5
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000000, readsip_test                # read sip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_s_plic_interrupts	    # clear interrupt from PLIC
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Case 1.6:
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTEN00, 0x00000008, write32_test       # enable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable GPIO s-mode interrupts
.4byte PLIC_THRESH0, 0x00000005, write32_test       # set m-mode threshold to 5
.4byte PLIC_THRESH1, 0x00000000, write32_test       # set s-mode threshold to 0
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000200, readsip_test                # read sip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_s_plic_interrupts	    # clear interrupt from PLIC
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# Case 1.7:
.4byte PLIC_INTPRI_GPIO, 0x00000001, write32_test   # GPIOPriority = 1
.4byte PLIC_INTEN00, 0x00000008, write32_test       # enable GPIO m-mode interrupts
.4byte PLIC_INTEN10, 0x00000008, write32_test       # enable GPIO s-mode interrupts
.4byte PLIC_THRESH0, 0x00000005, write32_test       # set m-mode threshold to 5
.4byte PLIC_THRESH1, 0x00000005, write32_test       # set s-mode threshold to 5
.4byte output_val, 0x00000001, write32_test         # cause rise_ip to go high
.4byte 0x0, 0x00000000, readsip_test                # read sip
.4byte PLIC_INTPENDING0, 0x00000008, read32_test    # interrupt pending for GPIO
.4byte PLIC_CLAIM1, 0x00000003, read32_test         # read claim register
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # interrupt pending cleared for GPIO
.4byte output_val, 0x00000000, write32_test         # clear output_val
.4byte rise_ip, 0x00000001, write32_test            # clear GPIO interrupt
.4byte PLIC_CLAIM1, 0x00000003, write32_test        # complete claim made earlier
.4byte 0x0, 0x0, claim_s_plic_interrupts	    # clear interrupt from PLIC
.4byte PLIC_INTPENDING0, 0x00000000, read32_test    # no interrupts pending

# All done
	
.4byte 0x0, 0x0, terminate_test # terminate tests

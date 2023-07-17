///////////////////////////////////////////
//
// WALLY-gpio
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

RVTEST_ISA("RV32I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",gpio)

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

# =========== Verify all registers reset to zero ===========

.4byte input_val, 0x00000000, read32_test   # input_val reset to zero
.4byte input_en, 0x00000000, read32_test    # input_en reset to zero
.4byte output_en, 0x00000000, read32_test   # output_en reset to zero
.4byte output_val, 0x00000000, read32_test  # output_val reset to zero
.4byte rise_ie, 0x00000000, read32_test     # rise_ie reset to zero
.4byte fall_ie, 0x00000000, read32_test     # fall_ie reset to zero
.4byte high_ie, 0x00000000, read32_test     # high_ie reset to zero
.4byte low_ie, 0x00000000, read32_test      # low_ie reset to zero
.4byte rise_ip, 0x00000000, read32_test     # rise_ip reset to zero
.4byte fall_ip, 0x00000000, read32_test     # fall_ip reset to zero
.4byte high_ip, 0x00000000, read32_test     # high_ip reset to zero
.4byte low_ip, 0xffffffff, read32_test      # low_ip reset to ones since all zeroes
.4byte out_xor, 0x00000000, read32_test     # out_xor reset to zero

# =========== Test output and input pins ===========

.4byte output_en, 0xFFFFFFFF, write32_test      # enable all output pins
.4byte output_val, 0xA5A5A5A5, write32_test     # write alternating pattern to output pins
.4byte input_en, 0xFFFFFFFF, write32_test       # enable all input pins
.4byte input_val, 0xA5A5A5A5, read32_test       # read pattern from output pins
.4byte output_val, 0x5A5AFFFF, write32_test     # write different pattern to output pins
.4byte input_val, 0x5A5AFFFF, read32_test       # read different pattern from output pins

# =========== Test input enables ===========
.4byte input_en, 0x00000000, write32_test       # disable all input pins
.4byte input_val, 0x00000000, read32_test       # read 0 since input pins are disabled
.4byte input_en, 0xFFFF0000, write32_test       # enable a few input pins
.4byte input_val, 0x5A5A0000, read32_test       # read part of pattern set above.


# =========== Test XOR functionality ===========
.4byte out_xor, 0xFF00FF00, write32_test        # invert certain pin values
.4byte input_val, 0xA55A0000, read32_test       # read inverted pins and verify input enable is working

# =========== Test Interrupt Pending bits ===========

SETUP_PLIC

.4byte low_ip, 0xFFFFFFFF, write32_test             # clear pending low interrupts
.4byte high_ip, 0xFFFFFFFF, write32_test            # clear pending high interrupts
.4byte rise_ip, 0xFFFFFFFF, write32_test            # clear pending rise interrupts
.4byte fall_ip, 0xFFFFFFFF, write32_test            # clear pending fall interrupts
.4byte high_ip, 0xA55A0000, read32_test             # check pending high interrupts
.4byte low_ip, 0x5AA5FFFF, read32_test              # check pending low interrupts
.4byte rise_ip, 0x00000000, read32_test             # check pending rise interrupts
.4byte fall_ip, 0x00000000, read32_test             # check pending fall interrupts
.4byte output_val, 0x5BAA000F, write32_test         # change output pattern to check rise/fall interrupts
.4byte input_val, 0xA4AA0000, read32_test           # check new output matches expected output
.4byte high_ip, 0xA5FA0000, read32_test             # high interrupt pending
.4byte low_ip, 0x5BF5FFFF, read32_test              # low interrupt pending should be opposite high for enabled pins
.4byte rise_ip, 0x00A00000, read32_test             # check for changed bits (rising)
.4byte fall_ip, 0x01500000, read32_test             # check for changed bits (falling)
.4byte 0x0, 0x00000000, readmip_test                # Check no external interrupt has been generated

# =========== Test interrupts can be enabled without being triggered ===========

.4byte high_ie, 0x00010000, write32_test            # enable high interrupt on bit 16, no pending interrupt
.4byte 0x0, 0x00000000, readmip_test                # No external interrupt should be pending
.4byte low_ie, 0x00020000, write32_test             # enable low interrupt on bit 17, no pending interrupt
.4byte 0x0, 0x00000000, readmip_test                # No external interrupt should be pending
.4byte rise_ie, 0x00010000, write32_test            # enable rise interrupt on bit 16, no pending interrupt
.4byte 0x0, 0x00000000, readmip_test                # No external interrupt should be pending
.4byte fall_ie, 0x00010000, write32_test            # enable fall interrupt on bit 16, no pending interrupt
.4byte 0x0, 0x00000000, readmip_test                # No external interrupt should be pending

# =========== Test interrupts can be enabled and triggered ===========

.4byte high_ie, 0x00020000, write32_test            # enable high interrupt on bit 17, which is pending
.4byte 0x0, 0x00000800, readmip_test                # MEIP should be raised
.4byte high_ie, 0x00000000, write32_test            # disable high interrupt on bit 17
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear PLIC pending interrupts
.4byte 0x0, 0x00000000, readmip_test                # MEIP should be released
.4byte low_ie, 0x00010000, write32_test             # enable low interrupt on bit 16, which is pending
.4byte 0x0, 0x00000800, readmip_test                # MEIP should be raised
.4byte low_ie, 0x00000000, write32_test             # disable low interrupt on bit 16
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear PLIC pending interrupts
.4byte 0x0, 0x00000000, readmip_test                # MEIP should be released
.4byte rise_ie, 0x00200000, write32_test            # enable rise interrupt on bit 21, which is pending
.4byte 0x0, 0x00000800, readmip_test                # MEIP should be raised
.4byte rise_ie, 0x00000000, write32_test            # disable rise interrupt on bit 21, which is pending
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear PLIC pending interrupts
.4byte 0x0, 0x00000000, readmip_test                # MEIP should be released
.4byte fall_ie, 0x01000000, write32_test            # enable high interrupt on bit 24, which is pending
.4byte 0x0, 0x00000800, readmip_test                # MEIP should be raised
.4byte fall_ie, 0x00000000, write32_test            # disable high interrupt on bit 24, which is pending
.4byte 0x0, 0x00000000, claim_m_plic_interrupts     # clear PLIC pending interrupts
.4byte 0x0, 0x00000000, readmip_test                # MEIP should be released

.4byte 0x0, 0x0, terminate_test # terminate tests

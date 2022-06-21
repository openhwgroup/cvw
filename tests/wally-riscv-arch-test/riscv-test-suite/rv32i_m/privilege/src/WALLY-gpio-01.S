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

.4byte input_val, 0x00000000, read32_test  # input_val reset to zero
.4byte input_en, 0x00000000, read32_test  # input_en reset to zero

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
.4byte input_val, 0x5A5A0000, read32_test      # read part of pattern set above.

# =========== Test output enables(?) ===========

.4byte output_en, 0xFFFFFFFF, write32_test      # undo changes made to output enable

# =========== Test XOR functionality ===========
.4byte out_xor, 0xFF00FF00, write32_test        # invert certain pin values
.4byte input_val, 0xA55A0000, read32_test           # read inverted pins and verify input enable is working

.4byte 0x0, 0x0, terminate_test # terminate tests

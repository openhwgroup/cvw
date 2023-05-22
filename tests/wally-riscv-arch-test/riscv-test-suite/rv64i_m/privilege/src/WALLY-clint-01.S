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

#include "WALLY-TEST-LIB-64.h" 
RVTEST_ISA("RV64I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",clint) 

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
# 
# ---------------------------------------------------------------------------------------------

# =========== Define CLINT registers ===========

.equ CLINT, 0x02000000
.equ msip, (CLINT+0x00)
.equ mtimecmp, (CLINT+0x4000)   # doesn't necessarily reset to zero
.equ mtimecmph,(CLINT+0x4004)
.equ mtime, (CLINT+0xBFF8)      # resets to zero but cannot be easily tested
.equ mtimeh, (CLINT+0xBFFC)

# =========== Verify verifiable registers reset to zero ===========

.8byte msip, 0x00000000, read32_test    # msip reset to zero

# =========== msip tests ===========

.8byte msip, 0xFFFFFFFE, write32_test   # write to invalid bits of msip
.8byte 0x0, 0x00000000, readmip_test    # msip bit should be zero
.8byte msip, 0x00000001, write32_test   # set msip to one
.8byte 0x0, 0x00000008, readmip_test    # msip bit is set  
.8byte msip, 0x00000000, write32_test   # set msip to zero
.8byte 0x0, 0x00000000, readmip_test    # msip bit is released

# =========== mtime write tests ===========

.8byte mtime, 0x00000000, write32_test  # test we can write to mtime
.8byte mtimeh, 0x00000000, write32_test # test we can write to mtimeh
.8byte 0x0,0x00000000, readmip_test     # mtip bit should be zero

# =========== mtimecmp tests ===========

.8byte mtimecmp, 0xFFFFFFFF, write32_test   # verify mtimecmp is writable
.8byte mtimecmph, 0xA5A5A5A5, write32_test  # verify mtimecmph is writable
.8byte mtimecmp, 0xFFFFFFFF, read32_test    # read back value written to mtimecmp
.8byte mtimecmph, 0xA5A5A5A5, read32_test   # read back value written to mtimecmph
.8byte mtime, 0xFFFFFFFF, write32_test      # write to mtime
.8byte 0x0, 0x00000000, readmip_test        # mtip should still be zero
.8byte mtimeh, 0xA5A5A5A6, write32_test     # cause mtip to go high by making mtime > mtimecmp
.8byte 0x0, 0x00000080, readmip_test        # mtip should be set

.8byte 0x0, 0x0, terminate_test # terminate tests

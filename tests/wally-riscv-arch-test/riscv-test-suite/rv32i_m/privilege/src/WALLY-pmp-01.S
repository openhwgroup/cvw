///////////////////////////////////////////
//
// WALLY-PMP
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2021-06-15
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
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;",pmp)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

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

# These tests follow the testing plan in Chapter 12 of the riscv-wally textbook *** what is it called and how do I refer to it?
# =========== test 12.3.2.2 PMPs ===========

# Test 12.3.2.2.1 Config: Write known values and set PMP config according to table 12.4 in the *** riscv book, copied below

.4byte 0x80100300, 0xFEEDBEEF, write32_test

# write pmpaddr regs
                                         # | Reg   | pmpaddr     | pmpcfg    | L | A     | X | W | R | Comments 		                |
.4byte 0x0, 0x0FFFFFFF, write_pmpaddr_0  # | 0     | 0x0FFFFFFF  | 1F        | 0 | NAPOT | 0 | 1 | 1 | I/O 00000000-7FFFFFFF RW 		|
.4byte 0x1, 0x20040000, write_pmpaddr_1  # | 1     | 0x20040000  | 00        | 0 | OFF   | 0 | 0 | 0 |    		                    |
.4byte 0x2, 0x2004003F, write_pmpaddr_2  # | 2     | 0x2004003F  | 09        | 0 | TOR   | 0 | 0 | 1 | 80100000-801000FF R 		    |
.4byte 0x3, 0x20040080, write_pmpaddr_3  # | 3     | 0x20040080  | 00        | 0 | OFF   | 0 | 0 | 0 |    		                    |
.4byte 0x4, 0x20040084, write_pmpaddr_4  # | 4     | 0x20040084  | 0C        | 0 | TOR   | 1 | 0 | 0 | 80100200-80100210 X 		    |
.4byte 0x5, 0x200400C0, write_pmpaddr_5  # | 5     | 0x200400C0  | 90        | 1 | NA4   | 0 | 0 | 0 | 80100300-80100303 locked out 	|
.4byte 0x6, 0x2004013F, write_pmpaddr_6  # | 6     | 0x2004013F  | 18        | 0 | NAPOT | 0 | 0 | 0 | 80100400-801004FF no access 	|
# Pmpaddr 7-14 are all zeroed out in this test, so they don't need writes.
.4byte 0xF, 0x2FFFFFFF, write_pmpaddr_15 # | 15    | 0x2FFFFFFF  | 1F        | 0 | NAPOT | 1 | 1 | 1 | Main mem 80000000-FFFFFFFF RWX|

# write pmpcfg regs with the information in the table above. this should also write the value of these registers to the output.
.4byte 0x0, 0x0009001F, write_pmpcfg_0 # write pmpcfg0, output 0x0009001F
.4byte 0x1, 0x0018900C, write_pmpcfg_1 # write pmpcfg1, output 0x0018980C because NA4 reads as NAPOT with G > 0
# pmpcfg2 is zeroed out, so it doesn't need a write
.4byte 0x3, 0x1F000000, write_pmpcfg_3 # write pmpcfg3, output 0x1F000000

# write known values to memory where W=0. This should be possible since we're in machine mode.
.4byte 0x80100010, 0x600DAA, write32_test # write to pmpaddr 1-2 range
.4byte 0x80100400, 0x600DBB, write32_test # write to pmpaddr 6 range

# Write executable code to regions where X = 0, 1 in main memory
.4byte 0x80100200, 0x11100393, write32_test # write executable code for "li x7, 0x111; ret" to region with X=1 (PMP4)
.4byte 0x80100204, 0x00008067, write32_test 
.4byte 0x80100020, 0x11100393, write32_test # write same executable code to region with X=0 (PMP2)
.4byte 0x80100024, 0x00008067, write32_test 


# attempt to write to pmpaddr5 and pmp5cfg after lockout
.4byte 0x1, 0x0018FF0C, write_pmpcfg_1 # attempt to edit only pmp5cfg (pmpcfg1[8:15]) after lockout. 
# instruction ignored, output is 0x0018900C, NOT 0x0018FF0C
.4byte 0x5, 0xFFFFFFFF, write_pmpaddr_5 # attempt to edit pmpaddr5 after lockout.
# instruction ignored, output is 0x200400C0, NOT 0xFFFFFFFF

# Test 12.3.2.2.2 Machine mode access

.4byte 0x80100300, 0x0, read32_test # access fault to region with L=1, R=0. This one writes 0x5 as the mcause, not 0xd.
.4byte 0x80100400, 0x0, read32_test # successful access to region with L=X=W=R=0

# Test 12.3.2.2.3 System mode access

.4byte 0x0, 0x0, goto_s_mode # go to S mode. 0xb written to output
# test a write followed by a read to each region with R=W=1
.4byte 0x80200000, 0x600D15, write32_test # Write "good value" to RW range (PMP15)
.4byte 0x80200000, 0x600D15, read32_test # confirm write with read

# test a write followed by a read on the edges of a read-only range
.4byte 0x800FFFF8, 0x600D02, write32_test # Write "good value" just below read-only range (PMP2)
.4byte 0x800FFFF8, 0x600D02, read32_test # confirm write with read
.4byte 0x80100100, 0x600D12, write32_test # Write "good value" just above read-only range (PMP2)
.4byte 0x80100100, 0x600D12, read32_test # confirm write with read

# test a read from each read only range verify a write causes an access fault
.4byte 0x80100010, 0xBAD, write32_test # Write fault in read-only range (PMP2)
.4byte 0x80100010, 0x600DAA, read32_test # read correct value out

# test read and write fault on region with no access
.4byte 0x80100208, 0x600D17, write32_test # Write fault on no-access range (PMP4)
.4byte 0x80100208, 0x600D17, read32_test # read fault on no-access range (PMP4)

# test jalr to region with X=0 causes access fault
.4byte 0x80100020, 0xbad, executable_test # execute fault on no-execute range (PMP2)

# test jalr to region with X=1 returns successfully
.4byte 0x80100200, 0x111, executable_test # execute success when X=1

.4byte 0x0, 0x0, terminate_test // terminate tests

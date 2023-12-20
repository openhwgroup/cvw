///////////////////////////////////////////
// WALLY-LRSC.S
//
// Tests Atomic LR / SC instructions
//
// David_Harris@hmc.edu 7 March 2021
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
// Adapted from Imperas RISCV-TEST_SUITE
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

#include "model_test.h"
#include "arch_test.h"

RVTEST_ISA("RV64IAF")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.A*.F*.*);def TEST_CASE_1=True",lrsc)

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT

    # ---------------------------------------------------------------------------------------------
    # Addresses for test data and results
    la x6, wally_signature
    la  x31, test_data

    # Testcase 0:  Do a successful load-reserved / store conditional word operation
    li x11, 42  
    lr.w x10, (x31)
    sc.w x12, x11, (x31)
    lw x13, 0(x31)
    sd x10, 0(x6)       # should be fffffffffffffffe (sign extended value read from test data)
    sd x12, 8(x6)       # should be 0000000000000000 (sc succeeded)
    sd x13, 16(x6)      # should be 000000000000002A (value written by SC, in hex)

 # Testcase 1:  Do an unsuccessful load-reserved / store conditional word operation
	addi x6, x6, 24
    addi x30, x31, 8    # 8 bytes later (reservation set size is 8 bytes)
    li x11, 43
    lr.w x10, (x30)
    sc.w x12, x11, (x31)  # should fail because not reserved
    lw x13, 0(x31)
    sd x10, 0(x6)       # should be fffffffffffffffd (sign extended value read from test data)
    sd x12, 8(x6)       # should be 0000000000000001 (sc failed)
    sd x13, 16(x6)      # should be 000000000000002A (previous value written by sc)

    # Testcase 2:  Do a successful load-reserved / store conditional doubleword operation
 	addi x6, x6, 24
    addi x31, x30, 8
    li x11, 44
    lr.d x10, (x31)
    sc.d x12, x11, (x31)
    lw x13, 0(x31)
    sd x10, 0(x6)       # should be 0xfffffff7fffffffb (value read from test data)
    sd x12, 8(x6)       # should be 0000000000000000 (sc succeeded)
    sd x13, 16(x6)      # should be 000000000000002C (value written by SC)

 # Testcase 3:  Do an unsuccessful load-reserved / store conditional doubleword operation
	addi x6, x6, 24
    addi x30, x31, 8
    li x11, 45
    lr.d x10, (x30)
    sc.d x12, x11, (x31)  # should fail because not reserved
    lw x13, 0(x31)
    sd x10, 0(x6)       # should be 0xffffffdfffffffef (sign extended value read from test data)
    sd x12, 8(x6)       # should be 0000000000000001 (sc failed)
    sd x13, 16(x6)      # should be 000000000000002C (previous value written by sc)

    # ---------------------------------------------------------------------------------------------
RVMODEL_HALT

RVTEST_DATA_BEGIN
	.align 8
test_data:

	.dword 0xfffffffdfffffffe
	.dword 0xfffffff7fffffffb
	.dword 0xffffffdfffffffef
	.dword 0xffffff7fffffffbf
	.dword 0xfffffdfffffffeff
	.dword 0xfffff7fffffffeff
	.dword 0xffffdfffffffefff
	.dword 0xffff7fffffffefff
	.dword 0xfffdfffffffeffff
	.dword 0xfff7fffffffbffff
	.dword 0xffdfffffffefffff
	.dword 0xff7fffffffbfffff
	.dword 0xfdfffffffeffffff
	.dword 0xf7fffffffeffffff
	.dword 0xdfffffffefffffff
	.dword 0x7fffffffefffffff
	.dword 0x00000001ffffffff
	.dword 0x0000000400000002
	.dword 0x0000001000000008
	.dword 0x0000004000000020
	.dword 0x0000010000000080
	.dword 0x0000040000000200
	.dword 0x0000100000000800
	.dword 0x0000400000002000
	.dword 0x0000000100008000
	.dword 0x0004000000000002
	.dword 0x0000001000080000
	.dword 0x0040000000000020
	.dword 0x0000010000800000
	.dword 0x0400000000000200
	.dword 0x0000100008000000
	.dword 0x4000000000002000
	.dword 0x0000000080000000
#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
# signature output
wally_signature:
.fill 12, 8, -1

sig_end_canary:
.int 0x0
rvtest_sig_end:
RVMODEL_DATA_END

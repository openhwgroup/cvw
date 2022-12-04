///////////////////////////////////////////
// WALLY-AMO.S
//
// Tests Atomic AMO instructions
//
// David_Harris@hmc.edu 11 March 2021
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

RVTEST_ISA("RV32IAF")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*A.*F.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;",amo)

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT

    # ---------------------------------------------------------------------------------------------
    # address for test results
    la x6, wally_signature
    la x31, test_data

    # Testcase 0:  amoswap.w
    li x7, 1
    amoswap.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be fffffffe (sign extended from test data)
    sw x9, 4(x6)        # should be 00000001 (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 1:  amoadd.w
    li x7, 2
    amoadd.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be fffffffb (sign extended from test data)
    sw x9, 4(x6)        # should be fffffffd (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 2:  amoand.w
    li x7, 0x7ff
    amoand.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be ffffffef (sign extended from test data)
    sw x9, 4(x6)        # should be 000007ef (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 3:  amoor.w
    li x7, 0x44
    amoor.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be ffffffbf (sign extended from test data)
    sw x9, 4(x6)        # should be ffffffff (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 4:  amoxor.w
    li x7, 0x381
    amoxor.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be fffffeff (sign extended from test data)
    sw x9, 4(x6)        # should be fffffd7e (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 5:  amomax.w
    li x7, 0x7ff
    amomax.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be fffffeff (sign extended from test data)
    sw x9, 4(x6)        # should be 000007ff (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 6:  amomin.w
    li x7, 0x7fd
    amomin.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be ffffefff (sign extended from test data)
    sw x9, 4(x6)        # should be ffffefff (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 7:  amomaxu.w
    li x7, 0x7fb
    amomaxu.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be ffffefff (sign extended from test data)
    sw x9, 4(x6)        # should be ffffefff (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8

    # Testcase 8:  amominu.w
    li x7, 0x7fa
    amominu.w x8, x7, (x31)
    lw x9, 0(x31)
    sw x8, 0(x6)        # should be fffeffff (sign extended from test data)
    sw x9, 4(x6)        # should be 000007fa (stored by amo)
    addi x31, x31, 8
    addi x6, x6, 8
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
	.dword 0x0fffdfffffffefff
	.dword 0xffff7fffffffefff
	.dword 0x3ffdfffffffeffff
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
.fill 20, 4, -1
RVMODEL_DATA_END

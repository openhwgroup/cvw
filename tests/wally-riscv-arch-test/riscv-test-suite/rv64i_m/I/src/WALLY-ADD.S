///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-ADD.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2022-06-17 22:58:09.914370//
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

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV64I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

RVTEST_SIGBASE( x6, wally_signature)

RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",add)

# Testcase 0:  rs1:x20(0x0000000000000000), rs2:x22(0x0000000000000000), result rd:x3(0x0000000000000000)
li x20, MASK_XLEN(0x0000000000000000)
li x22, MASK_XLEN(0x0000000000000000)
ADD x3, x20, x22
sd x3, 0(x6)

# Testcase 1:  rs1:x1(0x0000000000000000), rs2:x4(0x0000000000000001), result rd:x21(0x0000000000000001)
li x1, MASK_XLEN(0x0000000000000000)
li x4, MASK_XLEN(0x0000000000000001)
ADD x21, x1, x4
sd x21, 8(x6)

# Testcase 2:  rs1:x7(0x0000000000000000), rs2:x20(0xffffffffffffffff), result rd:x27(0xffffffffffffffff)
li x7, MASK_XLEN(0x0000000000000000)
li x20, MASK_XLEN(0xffffffffffffffff)
ADD x27, x7, x20
sd x27, 16(x6)

# Testcase 3:  rs1:x19(0x0000000000000001), rs2:x4(0x0000000000000000), result rd:x13(0x0000000000000001)
li x19, MASK_XLEN(0x0000000000000001)
li x4, MASK_XLEN(0x0000000000000000)
ADD x13, x19, x4
sd x13, 24(x6)

# Testcase 4:  rs1:x3(0x0000000000000001), rs2:x12(0x0000000000000001), result rd:x27(0x0000000000000002)
li x3, MASK_XLEN(0x0000000000000001)
li x12, MASK_XLEN(0x0000000000000001)
ADD x27, x3, x12
sd x27, 32(x6)

# Testcase 5:  rs1:x4(0x0000000000000001), rs2:x2(0xffffffffffffffff), result rd:x20(0x0000000000000000)
li x4, MASK_XLEN(0x0000000000000001)
li x2, MASK_XLEN(0xffffffffffffffff)
ADD x20, x4, x2
sd x20, 40(x6)

# Testcase 6:  rs1:x1(0xffffffffffffffff), rs2:x7(0x0000000000000000), result rd:x31(0xffffffffffffffff)
li x1, MASK_XLEN(0xffffffffffffffff)
li x7, MASK_XLEN(0x0000000000000000)
ADD x31, x1, x7
sd x31, 48(x6)

# Testcase 7:  rs1:x16(0xffffffffffffffff), rs2:x7(0x0000000000000001), result rd:x24(0x0000000000000000)
li x16, MASK_XLEN(0xffffffffffffffff)
li x7, MASK_XLEN(0x0000000000000001)
ADD x24, x16, x7
sd x24, 56(x6)

# Testcase 8:  rs1:x26(0xffffffffffffffff), rs2:x2(0xffffffffffffffff), result rd:x30(0xfffffffffffffffe)
li x26, MASK_XLEN(0xffffffffffffffff)
li x2, MASK_XLEN(0xffffffffffffffff)
ADD x30, x26, x2
sd x30, 64(x6)

# Testcase 9:  rs1:x20(0x05d51433ade9b2b4), rs2:x4(0x6cf55b158b53031d), result rd:x27(0x72ca6f49393cb5d1)
li x20, MASK_XLEN(0x05d51433ade9b2b4)
li x4, MASK_XLEN(0x6cf55b158b53031d)
ADD x27, x20, x4
sd x27, 72(x6)

# Testcase 10:  rs1:x21(0x11ebcd49428a1c22), rs2:x10(0x126cbc8f38884479), result rd:x12(0x245889d87b12609b)
li x21, MASK_XLEN(0x11ebcd49428a1c22)
li x10, MASK_XLEN(0x126cbc8f38884479)
ADD x12, x21, x10
sd x12, 80(x6)

# Testcase 11:  rs1:x15(0x2e2950656fa231e9), rs2:x2(0x80ee526e0fa07a3f), result rd:x20(0xaf17a2d37f42ac28)
li x15, MASK_XLEN(0x2e2950656fa231e9)
li x2, MASK_XLEN(0x80ee526e0fa07a3f)
ADD x20, x15, x2
sd x20, 88(x6)

.EQU NUMTESTS,12

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0x98765432
RVTEST_DATA_END

RVMODEL_DATA_BEGIN


wally_signature:
    .fill NUMTESTS*(XLEN/32),4,0xdeadbeef

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef

#endif
sig_end_canary:
.int 0x0
rvtest_sig_end:

RVMODEL_DATA_END
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-ADD.S
// David_Harris@hmc.edu & Katherine Parry

///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2022-06-17 22:58:09.916813//
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

RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",slt)

# Testcase 0:  rs1:x18(0x0000000000000000), rs2:x9(0x0000000000000000), result rd:x5(0x0000000000000000)
li x18, MASK_XLEN(0x0000000000000000)
li x9, MASK_XLEN(0x0000000000000000)
SLT x5, x18, x9
sd x5, 0(x6)

# Testcase 1:  rs1:x8(0x0000000000000000), rs2:x25(0x0000000000000001), result rd:x31(0x0000000000000001)
li x8, MASK_XLEN(0x0000000000000000)
li x25, MASK_XLEN(0x0000000000000001)
SLT x31, x8, x25
sd x31, 8(x6)

# Testcase 2:  rs1:x16(0x0000000000000000), rs2:x12(0xffffffffffffffff), result rd:x20(0x0000000000000000)
li x16, MASK_XLEN(0x0000000000000000)
li x12, MASK_XLEN(0xffffffffffffffff)
SLT x20, x16, x12
sd x20, 16(x6)

# Testcase 3:  rs1:x10(0x0000000000000001), rs2:x22(0x0000000000000000), result rd:x12(0x0000000000000000)
li x10, MASK_XLEN(0x0000000000000001)
li x22, MASK_XLEN(0x0000000000000000)
SLT x12, x10, x22
sd x12, 24(x6)

# Testcase 4:  rs1:x19(0x0000000000000001), rs2:x31(0x0000000000000001), result rd:x29(0x0000000000000000)
li x19, MASK_XLEN(0x0000000000000001)
li x31, MASK_XLEN(0x0000000000000001)
SLT x29, x19, x31
sd x29, 32(x6)

# Testcase 5:  rs1:x21(0x0000000000000001), rs2:x28(0xffffffffffffffff), result rd:x20(0x0000000000000000)
li x21, MASK_XLEN(0x0000000000000001)
li x28, MASK_XLEN(0xffffffffffffffff)
SLT x20, x21, x28
sd x20, 40(x6)

# Testcase 6:  rs1:x5(0xffffffffffffffff), rs2:x23(0x0000000000000000), result rd:x10(0x0000000000000001)
li x5, MASK_XLEN(0xffffffffffffffff)
li x23, MASK_XLEN(0x0000000000000000)
SLT x10, x5, x23
sd x10, 48(x6)

# Testcase 7:  rs1:x13(0xffffffffffffffff), rs2:x24(0x0000000000000001), result rd:x14(0x0000000000000001)
li x13, MASK_XLEN(0xffffffffffffffff)
li x24, MASK_XLEN(0x0000000000000001)
SLT x14, x13, x24
sd x14, 56(x6)

# Testcase 8:  rs1:x27(0xffffffffffffffff), rs2:x21(0xffffffffffffffff), result rd:x3(0x0000000000000000)
li x27, MASK_XLEN(0xffffffffffffffff)
li x21, MASK_XLEN(0xffffffffffffffff)
SLT x3, x27, x21
sd x3, 64(x6)

# Testcase 9:  rs1:x8(0x983631890063e42f), rs2:x21(0xb2d650af313b32b7), result rd:x15(0x0000000000000001)
li x8, MASK_XLEN(0x983631890063e42f)
li x21, MASK_XLEN(0xb2d650af313b32b7)
SLT x15, x8, x21
sd x15, 72(x6)

# Testcase 10:  rs1:x19(0xb5d97ef760ef1471), rs2:x28(0xac7c8803e01bbf50), result rd:x14(0x0000000000000000)
li x19, MASK_XLEN(0xb5d97ef760ef1471)
li x28, MASK_XLEN(0xac7c8803e01bbf50)
SLT x14, x19, x28
sd x14, 80(x6)

# Testcase 11:  rs1:x19(0x66faf98908135d58), rs2:x14(0xb3ab1b2cdf26f517), result rd:x25(0x0000000000000000)
li x19, MASK_XLEN(0x66faf98908135d58)
li x14, MASK_XLEN(0xb3ab1b2cdf26f517)
SLT x25, x19, x14
sd x25, 88(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry

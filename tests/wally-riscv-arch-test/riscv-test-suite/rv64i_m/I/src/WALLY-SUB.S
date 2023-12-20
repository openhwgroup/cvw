///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SUB.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2022-06-17 22:58:09.915580//
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

RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",sub)

# Testcase 0:  rs1:x4(0x0000000000000000), rs2:x23(0x0000000000000000), result rd:x13(0x0000000000000000)
li x4, MASK_XLEN(0x0000000000000000)
li x23, MASK_XLEN(0x0000000000000000)
SUB x13, x4, x23
sd x13, 0(x6)

# Testcase 1:  rs1:x7(0x0000000000000000), rs2:x9(0x0000000000000001), result rd:x12(0xffffffffffffffff)
li x7, MASK_XLEN(0x0000000000000000)
li x9, MASK_XLEN(0x0000000000000001)
SUB x12, x7, x9
sd x12, 8(x6)

# Testcase 2:  rs1:x29(0x0000000000000000), rs2:x24(0xffffffffffffffff), result rd:x16(0x0000000000000001)
li x29, MASK_XLEN(0x0000000000000000)
li x24, MASK_XLEN(0xffffffffffffffff)
SUB x16, x29, x24
sd x16, 16(x6)

# Testcase 3:  rs1:x27(0x0000000000000001), rs2:x29(0x0000000000000000), result rd:x30(0x0000000000000001)
li x27, MASK_XLEN(0x0000000000000001)
li x29, MASK_XLEN(0x0000000000000000)
SUB x30, x27, x29
sd x30, 24(x6)

# Testcase 4:  rs1:x22(0x0000000000000001), rs2:x7(0x0000000000000001), result rd:x31(0x0000000000000000)
li x22, MASK_XLEN(0x0000000000000001)
li x7, MASK_XLEN(0x0000000000000001)
SUB x31, x22, x7
sd x31, 32(x6)

# Testcase 5:  rs1:x25(0x0000000000000001), rs2:x2(0xffffffffffffffff), result rd:x26(0x0000000000000002)
li x25, MASK_XLEN(0x0000000000000001)
li x2, MASK_XLEN(0xffffffffffffffff)
SUB x26, x25, x2
sd x26, 40(x6)

# Testcase 6:  rs1:x9(0xffffffffffffffff), rs2:x4(0x0000000000000000), result rd:x20(0xffffffffffffffff)
li x9, MASK_XLEN(0xffffffffffffffff)
li x4, MASK_XLEN(0x0000000000000000)
SUB x20, x9, x4
sd x20, 48(x6)

# Testcase 7:  rs1:x30(0xffffffffffffffff), rs2:x15(0x0000000000000001), result rd:x22(0xfffffffffffffffe)
li x30, MASK_XLEN(0xffffffffffffffff)
li x15, MASK_XLEN(0x0000000000000001)
SUB x22, x30, x15
sd x22, 56(x6)

# Testcase 8:  rs1:x22(0xffffffffffffffff), rs2:x14(0xffffffffffffffff), result rd:x29(0x0000000000000000)
li x22, MASK_XLEN(0xffffffffffffffff)
li x14, MASK_XLEN(0xffffffffffffffff)
SUB x29, x22, x14
sd x29, 64(x6)

# Testcase 9:  rs1:x10(0xdff3334b91b15f5d), rs2:x21(0xeae2025e82339e23), result rd:x12(0xf51130ed0f7dc13a)
li x10, MASK_XLEN(0xdff3334b91b15f5d)
li x21, MASK_XLEN(0xeae2025e82339e23)
SUB x12, x10, x21
sd x12, 72(x6)

# Testcase 10:  rs1:x5(0xd670f668637e0edc), rs2:x18(0x403d1f83a859890c), result rd:x23(0x9633d6e4bb2485d0)
li x5, MASK_XLEN(0xd670f668637e0edc)
li x18, MASK_XLEN(0x403d1f83a859890c)
SUB x23, x5, x18
sd x23, 80(x6)

# Testcase 11:  rs1:x11(0x753c7c99032f06ca), rs2:x24(0x143e2e04bdd7d19b), result rd:x2(0x60fe4e944557352f)
li x11, MASK_XLEN(0x753c7c99032f06ca)
li x24, MASK_XLEN(0x143e2e04bdd7d19b)
SUB x2, x11, x24
sd x2, 88(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SUB.S
// David_Harris@hmc.edu & Katherine Parry

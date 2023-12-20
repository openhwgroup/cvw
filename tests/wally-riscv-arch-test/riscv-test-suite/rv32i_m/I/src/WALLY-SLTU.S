///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2022-06-17 22:58:09.911056//
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
RVTEST_ISA("RV32I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

RVTEST_SIGBASE( x6, wally_signature)

RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",sltu)

# Testcase 0:  rs1:x20(0x00000000), rs2:x26(0x00000000), result rd:x13(0x00000000)
li x20, MASK_XLEN(0x00000000)
li x26, MASK_XLEN(0x00000000)
SLTU x13, x20, x26
sw x13, 0(x6)

# Testcase 1:  rs1:x11(0x00000000), rs2:x19(0x00000001), result rd:x8(0x00000001)
li x11, MASK_XLEN(0x00000000)
li x19, MASK_XLEN(0x00000001)
SLTU x8, x11, x19
sw x8, 4(x6)

# Testcase 2:  rs1:x20(0x00000000), rs2:x22(0xffffffff), result rd:x9(0x00000001)
li x20, MASK_XLEN(0x00000000)
li x22, MASK_XLEN(0xffffffff)
SLTU x9, x20, x22
sw x9, 8(x6)

# Testcase 3:  rs1:x16(0x00000001), rs2:x3(0x00000000), result rd:x3(0x00000000)
li x16, MASK_XLEN(0x00000001)
li x3, MASK_XLEN(0x00000000)
SLTU x3, x16, x3
sw x3, 12(x6)

# Testcase 4:  rs1:x22(0x00000001), rs2:x25(0x00000001), result rd:x5(0x00000000)
li x22, MASK_XLEN(0x00000001)
li x25, MASK_XLEN(0x00000001)
SLTU x5, x22, x25
sw x5, 16(x6)

# Testcase 5:  rs1:x29(0x00000001), rs2:x5(0xffffffff), result rd:x30(0x00000001)
li x29, MASK_XLEN(0x00000001)
li x5, MASK_XLEN(0xffffffff)
SLTU x30, x29, x5
sw x30, 20(x6)

# Testcase 6:  rs1:x2(0xffffffff), rs2:x27(0x00000000), result rd:x3(0x00000000)
li x2, MASK_XLEN(0xffffffff)
li x27, MASK_XLEN(0x00000000)
SLTU x3, x2, x27
sw x3, 24(x6)

# Testcase 7:  rs1:x29(0xffffffff), rs2:x23(0x00000001), result rd:x30(0x00000000)
li x29, MASK_XLEN(0xffffffff)
li x23, MASK_XLEN(0x00000001)
SLTU x30, x29, x23
sw x30, 28(x6)

# Testcase 8:  rs1:x27(0xffffffff), rs2:x18(0xffffffff), result rd:x22(0x00000000)
li x27, MASK_XLEN(0xffffffff)
li x18, MASK_XLEN(0xffffffff)
SLTU x22, x27, x18
sw x22, 32(x6)

# Testcase 9:  rs1:x23(0x642bfa42), rs2:x17(0xd67e55fd), result rd:x9(0x00000001)
li x23, MASK_XLEN(0x642bfa42)
li x17, MASK_XLEN(0xd67e55fd)
SLTU x9, x23, x17
sw x9, 36(x6)

# Testcase 10:  rs1:x8(0x85940927), rs2:x28(0xcfc6e625), result rd:x7(0x00000001)
li x8, MASK_XLEN(0x85940927)
li x28, MASK_XLEN(0xcfc6e625)
SLTU x7, x8, x28
sw x7, 40(x6)

# Testcase 11:  rs1:x19(0xe5214606), rs2:x27(0xadf20806), result rd:x31(0x00000000)
li x19, MASK_XLEN(0xe5214606)
li x27, MASK_XLEN(0xadf20806)
SLTU x31, x19, x27
sw x31, 44(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry

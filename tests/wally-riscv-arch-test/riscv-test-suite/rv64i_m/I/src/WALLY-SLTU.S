///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2022-06-17 22:58:09.917963//
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

RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",sltu)

# Testcase 0:  rs1:x22(0x0000000000000000), rs2:x23(0x0000000000000000), result rd:x2(0x0000000000000000)
li x22, MASK_XLEN(0x0000000000000000)
li x23, MASK_XLEN(0x0000000000000000)
SLTU x2, x22, x23
sd x2, 0(x6)

# Testcase 1:  rs1:x15(0x0000000000000000), rs2:x17(0x0000000000000001), result rd:x29(0x0000000000000001)
li x15, MASK_XLEN(0x0000000000000000)
li x17, MASK_XLEN(0x0000000000000001)
SLTU x29, x15, x17
sd x29, 8(x6)

# Testcase 2:  rs1:x16(0x0000000000000000), rs2:x30(0xffffffffffffffff), result rd:x18(0x0000000000000001)
li x16, MASK_XLEN(0x0000000000000000)
li x30, MASK_XLEN(0xffffffffffffffff)
SLTU x18, x16, x30
sd x18, 16(x6)

# Testcase 3:  rs1:x20(0x0000000000000001), rs2:x25(0x0000000000000000), result rd:x1(0x0000000000000000)
li x20, MASK_XLEN(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000000)
SLTU x1, x20, x25
sd x1, 24(x6)

# Testcase 4:  rs1:x29(0x0000000000000001), rs2:x2(0x0000000000000001), result rd:x16(0x0000000000000000)
li x29, MASK_XLEN(0x0000000000000001)
li x2, MASK_XLEN(0x0000000000000001)
SLTU x16, x29, x2
sd x16, 32(x6)

# Testcase 5:  rs1:x11(0x0000000000000001), rs2:x10(0xffffffffffffffff), result rd:x27(0x0000000000000001)
li x11, MASK_XLEN(0x0000000000000001)
li x10, MASK_XLEN(0xffffffffffffffff)
SLTU x27, x11, x10
sd x27, 40(x6)

# Testcase 6:  rs1:x15(0xffffffffffffffff), rs2:x2(0x0000000000000000), result rd:x26(0x0000000000000000)
li x15, MASK_XLEN(0xffffffffffffffff)
li x2, MASK_XLEN(0x0000000000000000)
SLTU x26, x15, x2
sd x26, 48(x6)

# Testcase 7:  rs1:x27(0xffffffffffffffff), rs2:x29(0x0000000000000001), result rd:x26(0x0000000000000000)
li x27, MASK_XLEN(0xffffffffffffffff)
li x29, MASK_XLEN(0x0000000000000001)
SLTU x26, x27, x29
sd x26, 56(x6)

# Testcase 8:  rs1:x14(0xffffffffffffffff), rs2:x7(0xffffffffffffffff), result rd:x18(0x0000000000000000)
li x14, MASK_XLEN(0xffffffffffffffff)
li x7, MASK_XLEN(0xffffffffffffffff)
SLTU x18, x14, x7
sd x18, 64(x6)

# Testcase 9:  rs1:x3(0xf689a4a5ffda0336), rs2:x27(0xfa83ada4a2121ac5), result rd:x24(0x0000000000000001)
li x3, MASK_XLEN(0xf689a4a5ffda0336)
li x27, MASK_XLEN(0xfa83ada4a2121ac5)
SLTU x24, x3, x27
sd x24, 72(x6)

# Testcase 10:  rs1:x31(0xfca055362169df82), rs2:x22(0x66dd779403c54c71), result rd:x14(0x0000000000000000)
li x31, MASK_XLEN(0xfca055362169df82)
li x22, MASK_XLEN(0x66dd779403c54c71)
SLTU x14, x31, x22
sd x14, 80(x6)

# Testcase 11:  rs1:x23(0x00de59f550f0fc2b), rs2:x25(0x03a8987936a98d74), result rd:x1(0x0000000000000001)
li x23, MASK_XLEN(0x00de59f550f0fc2b)
li x25, MASK_XLEN(0x03a8987936a98d74)
SLTU x1, x23, x25
sd x1, 88(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry

///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-XOR.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.480304//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
///////////////////////////////////////////

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV64I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",temp)


RVTEST_SIGBASE( x6, wally_signature)

# Testcase 0:  rs1:x13(0x00000000), rs2:x12(0x00000000), result rd:x15(0x00000000)
li x13, MASK_XLEN(0x00000000)
li x12, MASK_XLEN(0x00000000)
XOR x15, x13, x12
sw x15, 0(x6)

# Testcase 1:  rs1:x31(0x00000000), rs2:x2(0x00000001), result rd:x18(0x00000001)
li x31, MASK_XLEN(0x00000000)
li x2, MASK_XLEN(0x00000001)
XOR x18, x31, x2
sw x18, 4(x6)

# Testcase 2:  rs1:x30(0x00000000), rs2:x14(0x00000002), result rd:x21(0x00000002)
li x30, MASK_XLEN(0x00000000)
li x14, MASK_XLEN(0x00000002)
XOR x21, x30, x14
sw x21, 8(x6)

# Testcase 3:  rs1:x20(0x00000000), rs2:x26(0x000000ff), result rd:x26(0x000000ff)
li x20, MASK_XLEN(0x00000000)
li x26, MASK_XLEN(0x000000ff)
XOR x26, x20, x26
sw x26, 12(x6)

# Testcase 4:  rs1:x25(0x00000000), rs2:x8(0x6c52dd14), result rd:x29(0x6c52dd14)
li x25, MASK_XLEN(0x00000000)
li x8, MASK_XLEN(0x6c52dd14)
XOR x29, x25, x8
sw x29, 16(x6)

# Testcase 5:  rs1:x1(0x00000000), rs2:x12(0x7ffffffe), result rd:x17(0x7ffffffe)
li x1, MASK_XLEN(0x00000000)
li x12, MASK_XLEN(0x7ffffffe)
XOR x17, x1, x12
sw x17, 20(x6)

# Testcase 6:  rs1:x7(0x00000000), rs2:x21(0x7fffffff), result rd:x12(0x7fffffff)
li x7, MASK_XLEN(0x00000000)
li x21, MASK_XLEN(0x7fffffff)
XOR x12, x7, x21
sw x12, 24(x6)

# Testcase 7:  rs1:x21(0x00000000), rs2:x23(0x80000000), result rd:x16(0x80000000)
li x21, MASK_XLEN(0x00000000)
li x23, MASK_XLEN(0x80000000)
XOR x16, x21, x23
sw x16, 28(x6)

# Testcase 8:  rs1:x1(0x00000000), rs2:x24(0x80000001), result rd:x24(0x80000001)
li x1, MASK_XLEN(0x00000000)
li x24, MASK_XLEN(0x80000001)
XOR x24, x1, x24
sw x24, 32(x6)

# Testcase 9:  rs1:x8(0x00000000), rs2:x19(0x9173ab42), result rd:x29(0x9173ab42)
li x8, MASK_XLEN(0x00000000)
li x19, MASK_XLEN(0x9173ab42)
XOR x29, x8, x19
sw x29, 36(x6)

# Testcase 10:  rs1:x31(0x00000000), rs2:x25(0xfffffffe), result rd:x30(0xfffffffe)
li x31, MASK_XLEN(0x00000000)
li x25, MASK_XLEN(0xfffffffe)
XOR x30, x31, x25
sw x30, 40(x6)

# Testcase 11:  rs1:x14(0x00000000), rs2:x3(0xffffffff), result rd:x19(0xffffffff)
li x14, MASK_XLEN(0x00000000)
li x3, MASK_XLEN(0xffffffff)
XOR x19, x14, x3
sw x19, 44(x6)

# Testcase 12:  rs1:x15(0x00000001), rs2:x8(0x00000000), result rd:x24(0x00000001)
li x15, MASK_XLEN(0x00000001)
li x8, MASK_XLEN(0x00000000)
XOR x24, x15, x8
sw x24, 48(x6)

# Testcase 13:  rs1:x23(0x00000001), rs2:x15(0x00000001), result rd:x28(0x00000000)
li x23, MASK_XLEN(0x00000001)
li x15, MASK_XLEN(0x00000001)
XOR x28, x23, x15
sw x28, 52(x6)

# Testcase 14:  rs1:x17(0x00000001), rs2:x29(0x00000002), result rd:x26(0x00000003)
li x17, MASK_XLEN(0x00000001)
li x29, MASK_XLEN(0x00000002)
XOR x26, x17, x29
sw x26, 56(x6)

# Testcase 15:  rs1:x26(0x00000001), rs2:x23(0x000000ff), result rd:x4(0x000000fe)
li x26, MASK_XLEN(0x00000001)
li x23, MASK_XLEN(0x000000ff)
XOR x4, x26, x23
sw x4, 60(x6)

# Testcase 16:  rs1:x15(0x00000001), rs2:x30(0x6c52dd14), result rd:x3(0x6c52dd15)
li x15, MASK_XLEN(0x00000001)
li x30, MASK_XLEN(0x6c52dd14)
XOR x3, x15, x30
sw x3, 64(x6)

# Testcase 17:  rs1:x30(0x00000001), rs2:x14(0x7ffffffe), result rd:x21(0x7fffffff)
li x30, MASK_XLEN(0x00000001)
li x14, MASK_XLEN(0x7ffffffe)
XOR x21, x30, x14
sw x21, 68(x6)

# Testcase 18:  rs1:x13(0x00000001), rs2:x31(0x7fffffff), result rd:x9(0x7ffffffe)
li x13, MASK_XLEN(0x00000001)
li x31, MASK_XLEN(0x7fffffff)
XOR x9, x13, x31
sw x9, 72(x6)

# Testcase 19:  rs1:x9(0x00000001), rs2:x14(0x80000000), result rd:x29(0x80000001)
li x9, MASK_XLEN(0x00000001)
li x14, MASK_XLEN(0x80000000)
XOR x29, x9, x14
sw x29, 76(x6)

# Testcase 20:  rs1:x20(0x00000001), rs2:x11(0x80000001), result rd:x3(0x80000000)
li x20, MASK_XLEN(0x00000001)
li x11, MASK_XLEN(0x80000001)
XOR x3, x20, x11
sw x3, 80(x6)

# Testcase 21:  rs1:x10(0x00000001), rs2:x1(0x9173ab42), result rd:x16(0x9173ab43)
li x10, MASK_XLEN(0x00000001)
li x1, MASK_XLEN(0x9173ab42)
XOR x16, x10, x1
sw x16, 84(x6)

# Testcase 22:  rs1:x1(0x00000001), rs2:x25(0xfffffffe), result rd:x9(0xffffffff)
li x1, MASK_XLEN(0x00000001)
li x25, MASK_XLEN(0xfffffffe)
XOR x9, x1, x25
sw x9, 88(x6)

# Testcase 23:  rs1:x7(0x00000001), rs2:x25(0xffffffff), result rd:x13(0xfffffffe)
li x7, MASK_XLEN(0x00000001)
li x25, MASK_XLEN(0xffffffff)
XOR x13, x7, x25
sw x13, 92(x6)

# Testcase 24:  rs1:x13(0x00000002), rs2:x14(0x00000000), result rd:x25(0x00000002)
li x13, MASK_XLEN(0x00000002)
li x14, MASK_XLEN(0x00000000)
XOR x25, x13, x14
sw x25, 96(x6)

# Testcase 25:  rs1:x13(0x00000002), rs2:x23(0x00000001), result rd:x29(0x00000003)
li x13, MASK_XLEN(0x00000002)
li x23, MASK_XLEN(0x00000001)
XOR x29, x13, x23
sw x29, 100(x6)

# Testcase 26:  rs1:x27(0x00000002), rs2:x2(0x00000002), result rd:x19(0x00000000)
li x27, MASK_XLEN(0x00000002)
li x2, MASK_XLEN(0x00000002)
XOR x19, x27, x2
sw x19, 104(x6)

# Testcase 27:  rs1:x15(0x00000002), rs2:x12(0x000000ff), result rd:x27(0x000000fd)
li x15, MASK_XLEN(0x00000002)
li x12, MASK_XLEN(0x000000ff)
XOR x27, x15, x12
sw x27, 108(x6)

# Testcase 28:  rs1:x19(0x00000002), rs2:x5(0x6c52dd14), result rd:x19(0x6c52dd16)
li x19, MASK_XLEN(0x00000002)
li x5, MASK_XLEN(0x6c52dd14)
XOR x19, x19, x5
sw x19, 112(x6)

# Testcase 29:  rs1:x23(0x00000002), rs2:x9(0x7ffffffe), result rd:x11(0x7ffffffc)
li x23, MASK_XLEN(0x00000002)
li x9, MASK_XLEN(0x7ffffffe)
XOR x11, x23, x9
sw x11, 116(x6)

# Testcase 30:  rs1:x27(0x00000002), rs2:x1(0x7fffffff), result rd:x13(0x7ffffffd)
li x27, MASK_XLEN(0x00000002)
li x1, MASK_XLEN(0x7fffffff)
XOR x13, x27, x1
sw x13, 120(x6)

# Testcase 31:  rs1:x16(0x00000002), rs2:x30(0x80000000), result rd:x17(0x80000002)
li x16, MASK_XLEN(0x00000002)
li x30, MASK_XLEN(0x80000000)
XOR x17, x16, x30
sw x17, 124(x6)

# Testcase 32:  rs1:x5(0x00000002), rs2:x2(0x80000001), result rd:x3(0x80000003)
li x5, MASK_XLEN(0x00000002)
li x2, MASK_XLEN(0x80000001)
XOR x3, x5, x2
sw x3, 128(x6)

# Testcase 33:  rs1:x19(0x00000002), rs2:x28(0x9173ab42), result rd:x12(0x9173ab40)
li x19, MASK_XLEN(0x00000002)
li x28, MASK_XLEN(0x9173ab42)
XOR x12, x19, x28
sw x12, 132(x6)

# Testcase 34:  rs1:x12(0x00000002), rs2:x1(0xfffffffe), result rd:x3(0xfffffffc)
li x12, MASK_XLEN(0x00000002)
li x1, MASK_XLEN(0xfffffffe)
XOR x3, x12, x1
sw x3, 136(x6)

# Testcase 35:  rs1:x7(0x00000002), rs2:x23(0xffffffff), result rd:x4(0xfffffffd)
li x7, MASK_XLEN(0x00000002)
li x23, MASK_XLEN(0xffffffff)
XOR x4, x7, x23
sw x4, 140(x6)

# Testcase 36:  rs1:x22(0x000000ff), rs2:x18(0x00000000), result rd:x16(0x000000ff)
li x22, MASK_XLEN(0x000000ff)
li x18, MASK_XLEN(0x00000000)
XOR x16, x22, x18
sw x16, 144(x6)

# Testcase 37:  rs1:x2(0x000000ff), rs2:x11(0x00000001), result rd:x30(0x000000fe)
li x2, MASK_XLEN(0x000000ff)
li x11, MASK_XLEN(0x00000001)
XOR x30, x2, x11
sw x30, 148(x6)

# Testcase 38:  rs1:x27(0x000000ff), rs2:x28(0x00000002), result rd:x31(0x000000fd)
li x27, MASK_XLEN(0x000000ff)
li x28, MASK_XLEN(0x00000002)
XOR x31, x27, x28
sw x31, 152(x6)

# Testcase 39:  rs1:x31(0x000000ff), rs2:x1(0x000000ff), result rd:x11(0x00000000)
li x31, MASK_XLEN(0x000000ff)
li x1, MASK_XLEN(0x000000ff)
XOR x11, x31, x1
sw x11, 156(x6)

# Testcase 40:  rs1:x13(0x000000ff), rs2:x29(0x6c52dd14), result rd:x5(0x6c52ddeb)
li x13, MASK_XLEN(0x000000ff)
li x29, MASK_XLEN(0x6c52dd14)
XOR x5, x13, x29
sw x5, 160(x6)

# Testcase 41:  rs1:x25(0x000000ff), rs2:x21(0x7ffffffe), result rd:x9(0x7fffff01)
li x25, MASK_XLEN(0x000000ff)
li x21, MASK_XLEN(0x7ffffffe)
XOR x9, x25, x21
sw x9, 164(x6)

# Testcase 42:  rs1:x14(0x000000ff), rs2:x22(0x7fffffff), result rd:x5(0x7fffff00)
li x14, MASK_XLEN(0x000000ff)
li x22, MASK_XLEN(0x7fffffff)
XOR x5, x14, x22
sw x5, 168(x6)

# Testcase 43:  rs1:x20(0x000000ff), rs2:x5(0x80000000), result rd:x13(0x800000ff)
li x20, MASK_XLEN(0x000000ff)
li x5, MASK_XLEN(0x80000000)
XOR x13, x20, x5
sw x13, 172(x6)

# Testcase 44:  rs1:x28(0x000000ff), rs2:x10(0x80000001), result rd:x17(0x800000fe)
li x28, MASK_XLEN(0x000000ff)
li x10, MASK_XLEN(0x80000001)
XOR x17, x28, x10
sw x17, 176(x6)

# Testcase 45:  rs1:x29(0x000000ff), rs2:x5(0x9173ab42), result rd:x30(0x9173abbd)
li x29, MASK_XLEN(0x000000ff)
li x5, MASK_XLEN(0x9173ab42)
XOR x30, x29, x5
sw x30, 180(x6)

# Testcase 46:  rs1:x16(0x000000ff), rs2:x23(0xfffffffe), result rd:x21(0xffffff01)
li x16, MASK_XLEN(0x000000ff)
li x23, MASK_XLEN(0xfffffffe)
XOR x21, x16, x23
sw x21, 184(x6)

# Testcase 47:  rs1:x23(0x000000ff), rs2:x25(0xffffffff), result rd:x24(0xffffff00)
li x23, MASK_XLEN(0x000000ff)
li x25, MASK_XLEN(0xffffffff)
XOR x24, x23, x25
sw x24, 188(x6)

# Testcase 48:  rs1:x2(0x6c52dd14), rs2:x24(0x00000000), result rd:x27(0x6c52dd14)
li x2, MASK_XLEN(0x6c52dd14)
li x24, MASK_XLEN(0x00000000)
XOR x27, x2, x24
sw x27, 192(x6)

# Testcase 49:  rs1:x17(0x6c52dd14), rs2:x2(0x00000001), result rd:x27(0x6c52dd15)
li x17, MASK_XLEN(0x6c52dd14)
li x2, MASK_XLEN(0x00000001)
XOR x27, x17, x2
sw x27, 196(x6)

# Testcase 50:  rs1:x18(0x6c52dd14), rs2:x23(0x00000002), result rd:x24(0x6c52dd16)
li x18, MASK_XLEN(0x6c52dd14)
li x23, MASK_XLEN(0x00000002)
XOR x24, x18, x23
sw x24, 200(x6)

# Testcase 51:  rs1:x23(0x6c52dd14), rs2:x21(0x000000ff), result rd:x13(0x6c52ddeb)
li x23, MASK_XLEN(0x6c52dd14)
li x21, MASK_XLEN(0x000000ff)
XOR x13, x23, x21
sw x13, 204(x6)

# Testcase 52:  rs1:x26(0x6c52dd14), rs2:x19(0x6c52dd14), result rd:x27(0x00000000)
li x26, MASK_XLEN(0x6c52dd14)
li x19, MASK_XLEN(0x6c52dd14)
XOR x27, x26, x19
sw x27, 208(x6)

# Testcase 53:  rs1:x7(0x6c52dd14), rs2:x26(0x7ffffffe), result rd:x9(0x13ad22ea)
li x7, MASK_XLEN(0x6c52dd14)
li x26, MASK_XLEN(0x7ffffffe)
XOR x9, x7, x26
sw x9, 212(x6)

# Testcase 54:  rs1:x11(0x6c52dd14), rs2:x23(0x7fffffff), result rd:x23(0x13ad22eb)
li x11, MASK_XLEN(0x6c52dd14)
li x23, MASK_XLEN(0x7fffffff)
XOR x23, x11, x23
sw x23, 216(x6)

# Testcase 55:  rs1:x9(0x6c52dd14), rs2:x26(0x80000000), result rd:x9(0xec52dd14)
li x9, MASK_XLEN(0x6c52dd14)
li x26, MASK_XLEN(0x80000000)
XOR x9, x9, x26
sw x9, 220(x6)

# Testcase 56:  rs1:x17(0x6c52dd14), rs2:x30(0x80000001), result rd:x15(0xec52dd15)
li x17, MASK_XLEN(0x6c52dd14)
li x30, MASK_XLEN(0x80000001)
XOR x15, x17, x30
sw x15, 224(x6)

# Testcase 57:  rs1:x30(0x6c52dd14), rs2:x5(0x9173ab42), result rd:x25(0xfd217656)
li x30, MASK_XLEN(0x6c52dd14)
li x5, MASK_XLEN(0x9173ab42)
XOR x25, x30, x5
sw x25, 228(x6)

# Testcase 58:  rs1:x29(0x6c52dd14), rs2:x15(0xfffffffe), result rd:x18(0x93ad22ea)
li x29, MASK_XLEN(0x6c52dd14)
li x15, MASK_XLEN(0xfffffffe)
XOR x18, x29, x15
sw x18, 232(x6)

# Testcase 59:  rs1:x5(0x6c52dd14), rs2:x2(0xffffffff), result rd:x21(0x93ad22eb)
li x5, MASK_XLEN(0x6c52dd14)
li x2, MASK_XLEN(0xffffffff)
XOR x21, x5, x2
sw x21, 236(x6)

# Testcase 60:  rs1:x17(0x7ffffffe), rs2:x2(0x00000000), result rd:x29(0x7ffffffe)
li x17, MASK_XLEN(0x7ffffffe)
li x2, MASK_XLEN(0x00000000)
XOR x29, x17, x2
sw x29, 240(x6)

# Testcase 61:  rs1:x25(0x7ffffffe), rs2:x11(0x00000001), result rd:x27(0x7fffffff)
li x25, MASK_XLEN(0x7ffffffe)
li x11, MASK_XLEN(0x00000001)
XOR x27, x25, x11
sw x27, 244(x6)

# Testcase 62:  rs1:x31(0x7ffffffe), rs2:x3(0x00000002), result rd:x7(0x7ffffffc)
li x31, MASK_XLEN(0x7ffffffe)
li x3, MASK_XLEN(0x00000002)
XOR x7, x31, x3
sw x7, 248(x6)

# Testcase 63:  rs1:x21(0x7ffffffe), rs2:x26(0x000000ff), result rd:x15(0x7fffff01)
li x21, MASK_XLEN(0x7ffffffe)
li x26, MASK_XLEN(0x000000ff)
XOR x15, x21, x26
sw x15, 252(x6)

# Testcase 64:  rs1:x20(0x7ffffffe), rs2:x8(0x6c52dd14), result rd:x26(0x13ad22ea)
li x20, MASK_XLEN(0x7ffffffe)
li x8, MASK_XLEN(0x6c52dd14)
XOR x26, x20, x8
sw x26, 256(x6)

# Testcase 65:  rs1:x23(0x7ffffffe), rs2:x11(0x7ffffffe), result rd:x30(0x00000000)
li x23, MASK_XLEN(0x7ffffffe)
li x11, MASK_XLEN(0x7ffffffe)
XOR x30, x23, x11
sw x30, 260(x6)

# Testcase 66:  rs1:x21(0x7ffffffe), rs2:x5(0x7fffffff), result rd:x16(0x00000001)
li x21, MASK_XLEN(0x7ffffffe)
li x5, MASK_XLEN(0x7fffffff)
XOR x16, x21, x5
sw x16, 264(x6)

# Testcase 67:  rs1:x25(0x7ffffffe), rs2:x18(0x80000000), result rd:x2(0xfffffffe)
li x25, MASK_XLEN(0x7ffffffe)
li x18, MASK_XLEN(0x80000000)
XOR x2, x25, x18
sw x2, 268(x6)

# Testcase 68:  rs1:x18(0x7ffffffe), rs2:x3(0x80000001), result rd:x27(0xffffffff)
li x18, MASK_XLEN(0x7ffffffe)
li x3, MASK_XLEN(0x80000001)
XOR x27, x18, x3
sw x27, 272(x6)

# Testcase 69:  rs1:x17(0x7ffffffe), rs2:x11(0x9173ab42), result rd:x1(0xee8c54bc)
li x17, MASK_XLEN(0x7ffffffe)
li x11, MASK_XLEN(0x9173ab42)
XOR x1, x17, x11
sw x1, 276(x6)

# Testcase 70:  rs1:x27(0x7ffffffe), rs2:x25(0xfffffffe), result rd:x3(0x80000000)
li x27, MASK_XLEN(0x7ffffffe)
li x25, MASK_XLEN(0xfffffffe)
XOR x3, x27, x25
sw x3, 280(x6)

# Testcase 71:  rs1:x4(0x7ffffffe), rs2:x14(0xffffffff), result rd:x20(0x80000001)
li x4, MASK_XLEN(0x7ffffffe)
li x14, MASK_XLEN(0xffffffff)
XOR x20, x4, x14
sw x20, 284(x6)

# Testcase 72:  rs1:x12(0x7fffffff), rs2:x19(0x00000000), result rd:x15(0x7fffffff)
li x12, MASK_XLEN(0x7fffffff)
li x19, MASK_XLEN(0x00000000)
XOR x15, x12, x19
sw x15, 288(x6)

# Testcase 73:  rs1:x11(0x7fffffff), rs2:x27(0x00000001), result rd:x13(0x7ffffffe)
li x11, MASK_XLEN(0x7fffffff)
li x27, MASK_XLEN(0x00000001)
XOR x13, x11, x27
sw x13, 292(x6)

# Testcase 74:  rs1:x17(0x7fffffff), rs2:x12(0x00000002), result rd:x27(0x7ffffffd)
li x17, MASK_XLEN(0x7fffffff)
li x12, MASK_XLEN(0x00000002)
XOR x27, x17, x12
sw x27, 296(x6)

# Testcase 75:  rs1:x28(0x7fffffff), rs2:x21(0x000000ff), result rd:x4(0x7fffff00)
li x28, MASK_XLEN(0x7fffffff)
li x21, MASK_XLEN(0x000000ff)
XOR x4, x28, x21
sw x4, 300(x6)

# Testcase 76:  rs1:x5(0x7fffffff), rs2:x11(0x6c52dd14), result rd:x30(0x13ad22eb)
li x5, MASK_XLEN(0x7fffffff)
li x11, MASK_XLEN(0x6c52dd14)
XOR x30, x5, x11
sw x30, 304(x6)

# Testcase 77:  rs1:x5(0x7fffffff), rs2:x1(0x7ffffffe), result rd:x11(0x00000001)
li x5, MASK_XLEN(0x7fffffff)
li x1, MASK_XLEN(0x7ffffffe)
XOR x11, x5, x1
sw x11, 308(x6)

# Testcase 78:  rs1:x29(0x7fffffff), rs2:x20(0x7fffffff), result rd:x7(0x00000000)
li x29, MASK_XLEN(0x7fffffff)
li x20, MASK_XLEN(0x7fffffff)
XOR x7, x29, x20
sw x7, 312(x6)

# Testcase 79:  rs1:x2(0x7fffffff), rs2:x14(0x80000000), result rd:x21(0xffffffff)
li x2, MASK_XLEN(0x7fffffff)
li x14, MASK_XLEN(0x80000000)
XOR x21, x2, x14
sw x21, 316(x6)

# Testcase 80:  rs1:x2(0x7fffffff), rs2:x23(0x80000001), result rd:x10(0xfffffffe)
li x2, MASK_XLEN(0x7fffffff)
li x23, MASK_XLEN(0x80000001)
XOR x10, x2, x23
sw x10, 320(x6)

# Testcase 81:  rs1:x26(0x7fffffff), rs2:x13(0x9173ab42), result rd:x30(0xee8c54bd)
li x26, MASK_XLEN(0x7fffffff)
li x13, MASK_XLEN(0x9173ab42)
XOR x30, x26, x13
sw x30, 324(x6)

# Testcase 82:  rs1:x2(0x7fffffff), rs2:x20(0xfffffffe), result rd:x25(0x80000001)
li x2, MASK_XLEN(0x7fffffff)
li x20, MASK_XLEN(0xfffffffe)
XOR x25, x2, x20
sw x25, 328(x6)

# Testcase 83:  rs1:x12(0x7fffffff), rs2:x30(0xffffffff), result rd:x27(0x80000000)
li x12, MASK_XLEN(0x7fffffff)
li x30, MASK_XLEN(0xffffffff)
XOR x27, x12, x30
sw x27, 332(x6)

# Testcase 84:  rs1:x30(0x80000000), rs2:x3(0x00000000), result rd:x14(0x80000000)
li x30, MASK_XLEN(0x80000000)
li x3, MASK_XLEN(0x00000000)
XOR x14, x30, x3
sw x14, 336(x6)

# Testcase 85:  rs1:x2(0x80000000), rs2:x15(0x00000001), result rd:x12(0x80000001)
li x2, MASK_XLEN(0x80000000)
li x15, MASK_XLEN(0x00000001)
XOR x12, x2, x15
sw x12, 340(x6)

# Testcase 86:  rs1:x20(0x80000000), rs2:x29(0x00000002), result rd:x20(0x80000002)
li x20, MASK_XLEN(0x80000000)
li x29, MASK_XLEN(0x00000002)
XOR x20, x20, x29
sw x20, 344(x6)

# Testcase 87:  rs1:x25(0x80000000), rs2:x9(0x000000ff), result rd:x22(0x800000ff)
li x25, MASK_XLEN(0x80000000)
li x9, MASK_XLEN(0x000000ff)
XOR x22, x25, x9
sw x22, 348(x6)

# Testcase 88:  rs1:x10(0x80000000), rs2:x19(0x6c52dd14), result rd:x28(0xec52dd14)
li x10, MASK_XLEN(0x80000000)
li x19, MASK_XLEN(0x6c52dd14)
XOR x28, x10, x19
sw x28, 352(x6)

# Testcase 89:  rs1:x26(0x80000000), rs2:x15(0x7ffffffe), result rd:x14(0xfffffffe)
li x26, MASK_XLEN(0x80000000)
li x15, MASK_XLEN(0x7ffffffe)
XOR x14, x26, x15
sw x14, 356(x6)

# Testcase 90:  rs1:x26(0x80000000), rs2:x9(0x7fffffff), result rd:x7(0xffffffff)
li x26, MASK_XLEN(0x80000000)
li x9, MASK_XLEN(0x7fffffff)
XOR x7, x26, x9
sw x7, 360(x6)

# Testcase 91:  rs1:x31(0x80000000), rs2:x13(0x80000000), result rd:x3(0x00000000)
li x31, MASK_XLEN(0x80000000)
li x13, MASK_XLEN(0x80000000)
XOR x3, x31, x13
sw x3, 364(x6)

# Testcase 92:  rs1:x12(0x80000000), rs2:x4(0x80000001), result rd:x4(0x00000001)
li x12, MASK_XLEN(0x80000000)
li x4, MASK_XLEN(0x80000001)
XOR x4, x12, x4
sw x4, 368(x6)

# Testcase 93:  rs1:x1(0x80000000), rs2:x12(0x9173ab42), result rd:x1(0x1173ab42)
li x1, MASK_XLEN(0x80000000)
li x12, MASK_XLEN(0x9173ab42)
XOR x1, x1, x12
sw x1, 372(x6)

# Testcase 94:  rs1:x23(0x80000000), rs2:x21(0xfffffffe), result rd:x29(0x7ffffffe)
li x23, MASK_XLEN(0x80000000)
li x21, MASK_XLEN(0xfffffffe)
XOR x29, x23, x21
sw x29, 376(x6)

# Testcase 95:  rs1:x1(0x80000000), rs2:x11(0xffffffff), result rd:x15(0x7fffffff)
li x1, MASK_XLEN(0x80000000)
li x11, MASK_XLEN(0xffffffff)
XOR x15, x1, x11
sw x15, 380(x6)

# Testcase 96:  rs1:x26(0x80000001), rs2:x18(0x00000000), result rd:x24(0x80000001)
li x26, MASK_XLEN(0x80000001)
li x18, MASK_XLEN(0x00000000)
XOR x24, x26, x18
sw x24, 384(x6)

# Testcase 97:  rs1:x28(0x80000001), rs2:x23(0x00000001), result rd:x16(0x80000000)
li x28, MASK_XLEN(0x80000001)
li x23, MASK_XLEN(0x00000001)
XOR x16, x28, x23
sw x16, 388(x6)

# Testcase 98:  rs1:x16(0x80000001), rs2:x3(0x00000002), result rd:x28(0x80000003)
li x16, MASK_XLEN(0x80000001)
li x3, MASK_XLEN(0x00000002)
XOR x28, x16, x3
sw x28, 392(x6)

# Testcase 99:  rs1:x2(0x80000001), rs2:x18(0x000000ff), result rd:x28(0x800000fe)
li x2, MASK_XLEN(0x80000001)
li x18, MASK_XLEN(0x000000ff)
XOR x28, x2, x18
sw x28, 396(x6)

# Testcase 100:  rs1:x13(0x80000001), rs2:x26(0x6c52dd14), result rd:x26(0xec52dd15)
li x13, MASK_XLEN(0x80000001)
li x26, MASK_XLEN(0x6c52dd14)
XOR x26, x13, x26
sw x26, 400(x6)

# Testcase 101:  rs1:x28(0x80000001), rs2:x30(0x7ffffffe), result rd:x9(0xffffffff)
li x28, MASK_XLEN(0x80000001)
li x30, MASK_XLEN(0x7ffffffe)
XOR x9, x28, x30
sw x9, 404(x6)

# Testcase 102:  rs1:x1(0x80000001), rs2:x21(0x7fffffff), result rd:x17(0xfffffffe)
li x1, MASK_XLEN(0x80000001)
li x21, MASK_XLEN(0x7fffffff)
XOR x17, x1, x21
sw x17, 408(x6)

# Testcase 103:  rs1:x4(0x80000001), rs2:x27(0x80000000), result rd:x27(0x00000001)
li x4, MASK_XLEN(0x80000001)
li x27, MASK_XLEN(0x80000000)
XOR x27, x4, x27
sw x27, 412(x6)

# Testcase 104:  rs1:x3(0x80000001), rs2:x11(0x80000001), result rd:x12(0x00000000)
li x3, MASK_XLEN(0x80000001)
li x11, MASK_XLEN(0x80000001)
XOR x12, x3, x11
sw x12, 416(x6)

# Testcase 105:  rs1:x31(0x80000001), rs2:x4(0x9173ab42), result rd:x16(0x1173ab43)
li x31, MASK_XLEN(0x80000001)
li x4, MASK_XLEN(0x9173ab42)
XOR x16, x31, x4
sw x16, 420(x6)

# Testcase 106:  rs1:x31(0x80000001), rs2:x2(0xfffffffe), result rd:x5(0x7fffffff)
li x31, MASK_XLEN(0x80000001)
li x2, MASK_XLEN(0xfffffffe)
XOR x5, x31, x2
sw x5, 424(x6)

# Testcase 107:  rs1:x30(0x80000001), rs2:x17(0xffffffff), result rd:x21(0x7ffffffe)
li x30, MASK_XLEN(0x80000001)
li x17, MASK_XLEN(0xffffffff)
XOR x21, x30, x17
sw x21, 428(x6)

# Testcase 108:  rs1:x26(0x9173ab42), rs2:x10(0x00000000), result rd:x31(0x9173ab42)
li x26, MASK_XLEN(0x9173ab42)
li x10, MASK_XLEN(0x00000000)
XOR x31, x26, x10
sw x31, 432(x6)

# Testcase 109:  rs1:x2(0x9173ab42), rs2:x1(0x00000001), result rd:x13(0x9173ab43)
li x2, MASK_XLEN(0x9173ab42)
li x1, MASK_XLEN(0x00000001)
XOR x13, x2, x1
sw x13, 436(x6)

# Testcase 110:  rs1:x18(0x9173ab42), rs2:x23(0x00000002), result rd:x5(0x9173ab40)
li x18, MASK_XLEN(0x9173ab42)
li x23, MASK_XLEN(0x00000002)
XOR x5, x18, x23
sw x5, 440(x6)

# Testcase 111:  rs1:x22(0x9173ab42), rs2:x8(0x000000ff), result rd:x31(0x9173abbd)
li x22, MASK_XLEN(0x9173ab42)
li x8, MASK_XLEN(0x000000ff)
XOR x31, x22, x8
sw x31, 444(x6)

# Testcase 112:  rs1:x29(0x9173ab42), rs2:x30(0x6c52dd14), result rd:x20(0xfd217656)
li x29, MASK_XLEN(0x9173ab42)
li x30, MASK_XLEN(0x6c52dd14)
XOR x20, x29, x30
sw x20, 448(x6)

# Testcase 113:  rs1:x11(0x9173ab42), rs2:x31(0x7ffffffe), result rd:x1(0xee8c54bc)
li x11, MASK_XLEN(0x9173ab42)
li x31, MASK_XLEN(0x7ffffffe)
XOR x1, x11, x31
sw x1, 452(x6)

# Testcase 114:  rs1:x16(0x9173ab42), rs2:x31(0x7fffffff), result rd:x29(0xee8c54bd)
li x16, MASK_XLEN(0x9173ab42)
li x31, MASK_XLEN(0x7fffffff)
XOR x29, x16, x31
sw x29, 456(x6)

# Testcase 115:  rs1:x21(0x9173ab42), rs2:x22(0x80000000), result rd:x13(0x1173ab42)
li x21, MASK_XLEN(0x9173ab42)
li x22, MASK_XLEN(0x80000000)
XOR x13, x21, x22
sw x13, 460(x6)

# Testcase 116:  rs1:x2(0x9173ab42), rs2:x8(0x80000001), result rd:x8(0x1173ab43)
li x2, MASK_XLEN(0x9173ab42)
li x8, MASK_XLEN(0x80000001)
XOR x8, x2, x8
sw x8, 464(x6)

# Testcase 117:  rs1:x21(0x9173ab42), rs2:x10(0x9173ab42), result rd:x11(0x00000000)
li x21, MASK_XLEN(0x9173ab42)
li x10, MASK_XLEN(0x9173ab42)
XOR x11, x21, x10
sw x11, 468(x6)

# Testcase 118:  rs1:x29(0x9173ab42), rs2:x14(0xfffffffe), result rd:x15(0x6e8c54bc)
li x29, MASK_XLEN(0x9173ab42)
li x14, MASK_XLEN(0xfffffffe)
XOR x15, x29, x14
sw x15, 472(x6)

# Testcase 119:  rs1:x12(0x9173ab42), rs2:x29(0xffffffff), result rd:x19(0x6e8c54bd)
li x12, MASK_XLEN(0x9173ab42)
li x29, MASK_XLEN(0xffffffff)
XOR x19, x12, x29
sw x19, 476(x6)

# Testcase 120:  rs1:x5(0xfffffffe), rs2:x13(0x00000000), result rd:x19(0xfffffffe)
li x5, MASK_XLEN(0xfffffffe)
li x13, MASK_XLEN(0x00000000)
XOR x19, x5, x13
sw x19, 480(x6)

# Testcase 121:  rs1:x30(0xfffffffe), rs2:x19(0x00000001), result rd:x1(0xffffffff)
li x30, MASK_XLEN(0xfffffffe)
li x19, MASK_XLEN(0x00000001)
XOR x1, x30, x19
sw x1, 484(x6)

# Testcase 122:  rs1:x22(0xfffffffe), rs2:x13(0x00000002), result rd:x23(0xfffffffc)
li x22, MASK_XLEN(0xfffffffe)
li x13, MASK_XLEN(0x00000002)
XOR x23, x22, x13
sw x23, 488(x6)

# Testcase 123:  rs1:x11(0xfffffffe), rs2:x17(0x000000ff), result rd:x1(0xffffff01)
li x11, MASK_XLEN(0xfffffffe)
li x17, MASK_XLEN(0x000000ff)
XOR x1, x11, x17
sw x1, 492(x6)

# Testcase 124:  rs1:x30(0xfffffffe), rs2:x4(0x6c52dd14), result rd:x19(0x93ad22ea)
li x30, MASK_XLEN(0xfffffffe)
li x4, MASK_XLEN(0x6c52dd14)
XOR x19, x30, x4
sw x19, 496(x6)

# Testcase 125:  rs1:x20(0xfffffffe), rs2:x5(0x7ffffffe), result rd:x25(0x80000000)
li x20, MASK_XLEN(0xfffffffe)
li x5, MASK_XLEN(0x7ffffffe)
XOR x25, x20, x5
sw x25, 500(x6)

# Testcase 126:  rs1:x5(0xfffffffe), rs2:x22(0x7fffffff), result rd:x26(0x80000001)
li x5, MASK_XLEN(0xfffffffe)
li x22, MASK_XLEN(0x7fffffff)
XOR x26, x5, x22
sw x26, 504(x6)

# Testcase 127:  rs1:x13(0xfffffffe), rs2:x26(0x80000000), result rd:x1(0x7ffffffe)
li x13, MASK_XLEN(0xfffffffe)
li x26, MASK_XLEN(0x80000000)
XOR x1, x13, x26
sw x1, 508(x6)

# Testcase 128:  rs1:x30(0xfffffffe), rs2:x22(0x80000001), result rd:x11(0x7fffffff)
li x30, MASK_XLEN(0xfffffffe)
li x22, MASK_XLEN(0x80000001)
XOR x11, x30, x22
sw x11, 512(x6)

# Testcase 129:  rs1:x23(0xfffffffe), rs2:x8(0x9173ab42), result rd:x30(0x6e8c54bc)
li x23, MASK_XLEN(0xfffffffe)
li x8, MASK_XLEN(0x9173ab42)
XOR x30, x23, x8
sw x30, 516(x6)

# Testcase 130:  rs1:x5(0xfffffffe), rs2:x12(0xfffffffe), result rd:x17(0x00000000)
li x5, MASK_XLEN(0xfffffffe)
li x12, MASK_XLEN(0xfffffffe)
XOR x17, x5, x12
sw x17, 520(x6)

# Testcase 131:  rs1:x7(0xfffffffe), rs2:x18(0xffffffff), result rd:x13(0x00000001)
li x7, MASK_XLEN(0xfffffffe)
li x18, MASK_XLEN(0xffffffff)
XOR x13, x7, x18
sw x13, 524(x6)

# Testcase 132:  rs1:x3(0xffffffff), rs2:x5(0x00000000), result rd:x14(0xffffffff)
li x3, MASK_XLEN(0xffffffff)
li x5, MASK_XLEN(0x00000000)
XOR x14, x3, x5
sw x14, 528(x6)

# Testcase 133:  rs1:x19(0xffffffff), rs2:x22(0x00000001), result rd:x12(0xfffffffe)
li x19, MASK_XLEN(0xffffffff)
li x22, MASK_XLEN(0x00000001)
XOR x12, x19, x22
sw x12, 532(x6)

# Testcase 134:  rs1:x31(0xffffffff), rs2:x4(0x00000002), result rd:x14(0xfffffffd)
li x31, MASK_XLEN(0xffffffff)
li x4, MASK_XLEN(0x00000002)
XOR x14, x31, x4
sw x14, 536(x6)

# Testcase 135:  rs1:x29(0xffffffff), rs2:x14(0x000000ff), result rd:x8(0xffffff00)
li x29, MASK_XLEN(0xffffffff)
li x14, MASK_XLEN(0x000000ff)
XOR x8, x29, x14
sw x8, 540(x6)

# Testcase 136:  rs1:x16(0xffffffff), rs2:x13(0x6c52dd14), result rd:x8(0x93ad22eb)
li x16, MASK_XLEN(0xffffffff)
li x13, MASK_XLEN(0x6c52dd14)
XOR x8, x16, x13
sw x8, 544(x6)

# Testcase 137:  rs1:x30(0xffffffff), rs2:x13(0x7ffffffe), result rd:x8(0x80000001)
li x30, MASK_XLEN(0xffffffff)
li x13, MASK_XLEN(0x7ffffffe)
XOR x8, x30, x13
sw x8, 548(x6)

# Testcase 138:  rs1:x21(0xffffffff), rs2:x16(0x7fffffff), result rd:x13(0x80000000)
li x21, MASK_XLEN(0xffffffff)
li x16, MASK_XLEN(0x7fffffff)
XOR x13, x21, x16
sw x13, 552(x6)

# Testcase 139:  rs1:x30(0xffffffff), rs2:x19(0x80000000), result rd:x3(0x7fffffff)
li x30, MASK_XLEN(0xffffffff)
li x19, MASK_XLEN(0x80000000)
XOR x3, x30, x19
sw x3, 556(x6)

# Testcase 140:  rs1:x27(0xffffffff), rs2:x9(0x80000001), result rd:x9(0x7ffffffe)
li x27, MASK_XLEN(0xffffffff)
li x9, MASK_XLEN(0x80000001)
XOR x9, x27, x9
sw x9, 560(x6)

# Testcase 141:  rs1:x29(0xffffffff), rs2:x17(0x9173ab42), result rd:x12(0x6e8c54bd)
li x29, MASK_XLEN(0xffffffff)
li x17, MASK_XLEN(0x9173ab42)
XOR x12, x29, x17
sw x12, 564(x6)

# Testcase 142:  rs1:x18(0xffffffff), rs2:x1(0xfffffffe), result rd:x20(0x00000001)
li x18, MASK_XLEN(0xffffffff)
li x1, MASK_XLEN(0xfffffffe)
XOR x20, x18, x1
sw x20, 568(x6)

# Testcase 143:  rs1:x20(0xffffffff), rs2:x25(0xffffffff), result rd:x16(0x00000000)
li x20, MASK_XLEN(0xffffffff)
li x25, MASK_XLEN(0xffffffff)
XOR x16, x20, x25
sw x16, 572(x6)

# Testcase 144:  rs1:x9(0xe072caae), rs2:x2(0x3cad275a), result rd:x20(0xdcdfedf4)
li x9, MASK_XLEN(0xe072caae)
li x2, MASK_XLEN(0x3cad275a)
XOR x20, x9, x2
sw x20, 576(x6)

# Testcase 145:  rs1:x26(0x52526d45), rs2:x13(0xde0989b9), result rd:x31(0x8c5be4fc)
li x26, MASK_XLEN(0x52526d45)
li x13, MASK_XLEN(0xde0989b9)
XOR x31, x26, x13
sw x31, 580(x6)

# Testcase 146:  rs1:x18(0xa0483bb2), rs2:x29(0x1b4e1428), result rd:x28(0xbb062f9a)
li x18, MASK_XLEN(0xa0483bb2)
li x29, MASK_XLEN(0x1b4e1428)
XOR x28, x18, x29
sw x28, 584(x6)

.EQU NUMTESTS,147

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

RVMODEL_DATA_END
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-XOR.S
// David_Harris@hmc.edu & Katherine Parry

///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SUB.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.459475//
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

# Testcase 0:  rs1:x30(0x00000000), rs2:x28(0x00000000), result rd:x2(0x00000000)
li x30, MASK_XLEN(0x00000000)
li x28, MASK_XLEN(0x00000000)
SUB x2, x30, x28
sw x2, 0(x6)

# Testcase 1:  rs1:x28(0x00000000), rs2:x24(0x00000001), result rd:x31(0xffffffff)
li x28, MASK_XLEN(0x00000000)
li x24, MASK_XLEN(0x00000001)
SUB x31, x28, x24
sw x31, 4(x6)

# Testcase 2:  rs1:x23(0x00000000), rs2:x20(0x00000002), result rd:x21(0xfffffffe)
li x23, MASK_XLEN(0x00000000)
li x20, MASK_XLEN(0x00000002)
SUB x21, x23, x20
sw x21, 8(x6)

# Testcase 3:  rs1:x16(0x00000000), rs2:x23(0x000000ff), result rd:x21(0xffffff01)
li x16, MASK_XLEN(0x00000000)
li x23, MASK_XLEN(0x000000ff)
SUB x21, x16, x23
sw x21, 12(x6)

# Testcase 4:  rs1:x29(0x00000000), rs2:x15(0x6c52dd14), result rd:x21(0x93ad22ec)
li x29, MASK_XLEN(0x00000000)
li x15, MASK_XLEN(0x6c52dd14)
SUB x21, x29, x15
sw x21, 16(x6)

# Testcase 5:  rs1:x14(0x00000000), rs2:x12(0x7ffffffe), result rd:x28(0x80000002)
li x14, MASK_XLEN(0x00000000)
li x12, MASK_XLEN(0x7ffffffe)
SUB x28, x14, x12
sw x28, 20(x6)

# Testcase 6:  rs1:x13(0x00000000), rs2:x19(0x7fffffff), result rd:x10(0x80000001)
li x13, MASK_XLEN(0x00000000)
li x19, MASK_XLEN(0x7fffffff)
SUB x10, x13, x19
sw x10, 24(x6)

# Testcase 7:  rs1:x1(0x00000000), rs2:x5(0x80000000), result rd:x5(0x80000000)
li x1, MASK_XLEN(0x00000000)
li x5, MASK_XLEN(0x80000000)
SUB x5, x1, x5
sw x5, 28(x6)

# Testcase 8:  rs1:x9(0x00000000), rs2:x11(0x80000001), result rd:x11(0x7fffffff)
li x9, MASK_XLEN(0x00000000)
li x11, MASK_XLEN(0x80000001)
SUB x11, x9, x11
sw x11, 32(x6)

# Testcase 9:  rs1:x26(0x00000000), rs2:x12(0x9173ab42), result rd:x23(0x6e8c54be)
li x26, MASK_XLEN(0x00000000)
li x12, MASK_XLEN(0x9173ab42)
SUB x23, x26, x12
sw x23, 36(x6)

# Testcase 10:  rs1:x3(0x00000000), rs2:x11(0xfffffffe), result rd:x25(0x00000002)
li x3, MASK_XLEN(0x00000000)
li x11, MASK_XLEN(0xfffffffe)
SUB x25, x3, x11
sw x25, 40(x6)

# Testcase 11:  rs1:x20(0x00000000), rs2:x2(0xffffffff), result rd:x2(0x00000001)
li x20, MASK_XLEN(0x00000000)
li x2, MASK_XLEN(0xffffffff)
SUB x2, x20, x2
sw x2, 44(x6)

# Testcase 12:  rs1:x19(0x00000001), rs2:x10(0x00000000), result rd:x12(0x00000001)
li x19, MASK_XLEN(0x00000001)
li x10, MASK_XLEN(0x00000000)
SUB x12, x19, x10
sw x12, 48(x6)

# Testcase 13:  rs1:x13(0x00000001), rs2:x18(0x00000001), result rd:x5(0x00000000)
li x13, MASK_XLEN(0x00000001)
li x18, MASK_XLEN(0x00000001)
SUB x5, x13, x18
sw x5, 52(x6)

# Testcase 14:  rs1:x10(0x00000001), rs2:x4(0x00000002), result rd:x16(0xffffffff)
li x10, MASK_XLEN(0x00000001)
li x4, MASK_XLEN(0x00000002)
SUB x16, x10, x4
sw x16, 56(x6)

# Testcase 15:  rs1:x24(0x00000001), rs2:x8(0x000000ff), result rd:x30(0xffffff02)
li x24, MASK_XLEN(0x00000001)
li x8, MASK_XLEN(0x000000ff)
SUB x30, x24, x8
sw x30, 60(x6)

# Testcase 16:  rs1:x28(0x00000001), rs2:x17(0x6c52dd14), result rd:x24(0x93ad22ed)
li x28, MASK_XLEN(0x00000001)
li x17, MASK_XLEN(0x6c52dd14)
SUB x24, x28, x17
sw x24, 64(x6)

# Testcase 17:  rs1:x3(0x00000001), rs2:x10(0x7ffffffe), result rd:x13(0x80000003)
li x3, MASK_XLEN(0x00000001)
li x10, MASK_XLEN(0x7ffffffe)
SUB x13, x3, x10
sw x13, 68(x6)

# Testcase 18:  rs1:x27(0x00000001), rs2:x11(0x7fffffff), result rd:x10(0x80000002)
li x27, MASK_XLEN(0x00000001)
li x11, MASK_XLEN(0x7fffffff)
SUB x10, x27, x11
sw x10, 72(x6)

# Testcase 19:  rs1:x14(0x00000001), rs2:x4(0x80000000), result rd:x4(0x80000001)
li x14, MASK_XLEN(0x00000001)
li x4, MASK_XLEN(0x80000000)
SUB x4, x14, x4
sw x4, 76(x6)

# Testcase 20:  rs1:x18(0x00000001), rs2:x30(0x80000001), result rd:x16(0x80000000)
li x18, MASK_XLEN(0x00000001)
li x30, MASK_XLEN(0x80000001)
SUB x16, x18, x30
sw x16, 80(x6)

# Testcase 21:  rs1:x16(0x00000001), rs2:x11(0x9173ab42), result rd:x27(0x6e8c54bf)
li x16, MASK_XLEN(0x00000001)
li x11, MASK_XLEN(0x9173ab42)
SUB x27, x16, x11
sw x27, 84(x6)

# Testcase 22:  rs1:x4(0x00000001), rs2:x16(0xfffffffe), result rd:x4(0x00000003)
li x4, MASK_XLEN(0x00000001)
li x16, MASK_XLEN(0xfffffffe)
SUB x4, x4, x16
sw x4, 88(x6)

# Testcase 23:  rs1:x23(0x00000001), rs2:x16(0xffffffff), result rd:x14(0x00000002)
li x23, MASK_XLEN(0x00000001)
li x16, MASK_XLEN(0xffffffff)
SUB x14, x23, x16
sw x14, 92(x6)

# Testcase 24:  rs1:x2(0x00000002), rs2:x10(0x00000000), result rd:x11(0x00000002)
li x2, MASK_XLEN(0x00000002)
li x10, MASK_XLEN(0x00000000)
SUB x11, x2, x10
sw x11, 96(x6)

# Testcase 25:  rs1:x24(0x00000002), rs2:x22(0x00000001), result rd:x29(0x00000001)
li x24, MASK_XLEN(0x00000002)
li x22, MASK_XLEN(0x00000001)
SUB x29, x24, x22
sw x29, 100(x6)

# Testcase 26:  rs1:x21(0x00000002), rs2:x19(0x00000002), result rd:x13(0x00000000)
li x21, MASK_XLEN(0x00000002)
li x19, MASK_XLEN(0x00000002)
SUB x13, x21, x19
sw x13, 104(x6)

# Testcase 27:  rs1:x26(0x00000002), rs2:x21(0x000000ff), result rd:x3(0xffffff03)
li x26, MASK_XLEN(0x00000002)
li x21, MASK_XLEN(0x000000ff)
SUB x3, x26, x21
sw x3, 108(x6)

# Testcase 28:  rs1:x3(0x00000002), rs2:x26(0x6c52dd14), result rd:x3(0x93ad22ee)
li x3, MASK_XLEN(0x00000002)
li x26, MASK_XLEN(0x6c52dd14)
SUB x3, x3, x26
sw x3, 112(x6)

# Testcase 29:  rs1:x7(0x00000002), rs2:x24(0x7ffffffe), result rd:x8(0x80000004)
li x7, MASK_XLEN(0x00000002)
li x24, MASK_XLEN(0x7ffffffe)
SUB x8, x7, x24
sw x8, 116(x6)

# Testcase 30:  rs1:x2(0x00000002), rs2:x13(0x7fffffff), result rd:x1(0x80000003)
li x2, MASK_XLEN(0x00000002)
li x13, MASK_XLEN(0x7fffffff)
SUB x1, x2, x13
sw x1, 120(x6)

# Testcase 31:  rs1:x4(0x00000002), rs2:x13(0x80000000), result rd:x18(0x80000002)
li x4, MASK_XLEN(0x00000002)
li x13, MASK_XLEN(0x80000000)
SUB x18, x4, x13
sw x18, 124(x6)

# Testcase 32:  rs1:x17(0x00000002), rs2:x10(0x80000001), result rd:x15(0x80000001)
li x17, MASK_XLEN(0x00000002)
li x10, MASK_XLEN(0x80000001)
SUB x15, x17, x10
sw x15, 128(x6)

# Testcase 33:  rs1:x30(0x00000002), rs2:x16(0x9173ab42), result rd:x26(0x6e8c54c0)
li x30, MASK_XLEN(0x00000002)
li x16, MASK_XLEN(0x9173ab42)
SUB x26, x30, x16
sw x26, 132(x6)

# Testcase 34:  rs1:x19(0x00000002), rs2:x23(0xfffffffe), result rd:x22(0x00000004)
li x19, MASK_XLEN(0x00000002)
li x23, MASK_XLEN(0xfffffffe)
SUB x22, x19, x23
sw x22, 136(x6)

# Testcase 35:  rs1:x7(0x00000002), rs2:x14(0xffffffff), result rd:x3(0x00000003)
li x7, MASK_XLEN(0x00000002)
li x14, MASK_XLEN(0xffffffff)
SUB x3, x7, x14
sw x3, 140(x6)

# Testcase 36:  rs1:x12(0x000000ff), rs2:x8(0x00000000), result rd:x9(0x000000ff)
li x12, MASK_XLEN(0x000000ff)
li x8, MASK_XLEN(0x00000000)
SUB x9, x12, x8
sw x9, 144(x6)

# Testcase 37:  rs1:x14(0x000000ff), rs2:x7(0x00000001), result rd:x12(0x000000fe)
li x14, MASK_XLEN(0x000000ff)
li x7, MASK_XLEN(0x00000001)
SUB x12, x14, x7
sw x12, 148(x6)

# Testcase 38:  rs1:x4(0x000000ff), rs2:x3(0x00000002), result rd:x27(0x000000fd)
li x4, MASK_XLEN(0x000000ff)
li x3, MASK_XLEN(0x00000002)
SUB x27, x4, x3
sw x27, 152(x6)

# Testcase 39:  rs1:x1(0x000000ff), rs2:x29(0x000000ff), result rd:x17(0x00000000)
li x1, MASK_XLEN(0x000000ff)
li x29, MASK_XLEN(0x000000ff)
SUB x17, x1, x29
sw x17, 156(x6)

# Testcase 40:  rs1:x15(0x000000ff), rs2:x25(0x6c52dd14), result rd:x22(0x93ad23eb)
li x15, MASK_XLEN(0x000000ff)
li x25, MASK_XLEN(0x6c52dd14)
SUB x22, x15, x25
sw x22, 160(x6)

# Testcase 41:  rs1:x7(0x000000ff), rs2:x4(0x7ffffffe), result rd:x16(0x80000101)
li x7, MASK_XLEN(0x000000ff)
li x4, MASK_XLEN(0x7ffffffe)
SUB x16, x7, x4
sw x16, 164(x6)

# Testcase 42:  rs1:x13(0x000000ff), rs2:x9(0x7fffffff), result rd:x7(0x80000100)
li x13, MASK_XLEN(0x000000ff)
li x9, MASK_XLEN(0x7fffffff)
SUB x7, x13, x9
sw x7, 168(x6)

# Testcase 43:  rs1:x21(0x000000ff), rs2:x2(0x80000000), result rd:x31(0x800000ff)
li x21, MASK_XLEN(0x000000ff)
li x2, MASK_XLEN(0x80000000)
SUB x31, x21, x2
sw x31, 172(x6)

# Testcase 44:  rs1:x26(0x000000ff), rs2:x7(0x80000001), result rd:x20(0x800000fe)
li x26, MASK_XLEN(0x000000ff)
li x7, MASK_XLEN(0x80000001)
SUB x20, x26, x7
sw x20, 176(x6)

# Testcase 45:  rs1:x5(0x000000ff), rs2:x4(0x9173ab42), result rd:x7(0x6e8c55bd)
li x5, MASK_XLEN(0x000000ff)
li x4, MASK_XLEN(0x9173ab42)
SUB x7, x5, x4
sw x7, 180(x6)

# Testcase 46:  rs1:x15(0x000000ff), rs2:x13(0xfffffffe), result rd:x12(0x00000101)
li x15, MASK_XLEN(0x000000ff)
li x13, MASK_XLEN(0xfffffffe)
SUB x12, x15, x13
sw x12, 184(x6)

# Testcase 47:  rs1:x18(0x000000ff), rs2:x27(0xffffffff), result rd:x5(0x00000100)
li x18, MASK_XLEN(0x000000ff)
li x27, MASK_XLEN(0xffffffff)
SUB x5, x18, x27
sw x5, 188(x6)

# Testcase 48:  rs1:x4(0x6c52dd14), rs2:x20(0x00000000), result rd:x16(0x6c52dd14)
li x4, MASK_XLEN(0x6c52dd14)
li x20, MASK_XLEN(0x00000000)
SUB x16, x4, x20
sw x16, 192(x6)

# Testcase 49:  rs1:x5(0x6c52dd14), rs2:x19(0x00000001), result rd:x13(0x6c52dd13)
li x5, MASK_XLEN(0x6c52dd14)
li x19, MASK_XLEN(0x00000001)
SUB x13, x5, x19
sw x13, 196(x6)

# Testcase 50:  rs1:x21(0x6c52dd14), rs2:x22(0x00000002), result rd:x14(0x6c52dd12)
li x21, MASK_XLEN(0x6c52dd14)
li x22, MASK_XLEN(0x00000002)
SUB x14, x21, x22
sw x14, 200(x6)

# Testcase 51:  rs1:x29(0x6c52dd14), rs2:x17(0x000000ff), result rd:x16(0x6c52dc15)
li x29, MASK_XLEN(0x6c52dd14)
li x17, MASK_XLEN(0x000000ff)
SUB x16, x29, x17
sw x16, 204(x6)

# Testcase 52:  rs1:x22(0x6c52dd14), rs2:x30(0x6c52dd14), result rd:x29(0x00000000)
li x22, MASK_XLEN(0x6c52dd14)
li x30, MASK_XLEN(0x6c52dd14)
SUB x29, x22, x30
sw x29, 208(x6)

# Testcase 53:  rs1:x11(0x6c52dd14), rs2:x27(0x7ffffffe), result rd:x16(0xec52dd16)
li x11, MASK_XLEN(0x6c52dd14)
li x27, MASK_XLEN(0x7ffffffe)
SUB x16, x11, x27
sw x16, 212(x6)

# Testcase 54:  rs1:x16(0x6c52dd14), rs2:x21(0x7fffffff), result rd:x22(0xec52dd15)
li x16, MASK_XLEN(0x6c52dd14)
li x21, MASK_XLEN(0x7fffffff)
SUB x22, x16, x21
sw x22, 216(x6)

# Testcase 55:  rs1:x28(0x6c52dd14), rs2:x7(0x80000000), result rd:x18(0xec52dd14)
li x28, MASK_XLEN(0x6c52dd14)
li x7, MASK_XLEN(0x80000000)
SUB x18, x28, x7
sw x18, 220(x6)

# Testcase 56:  rs1:x20(0x6c52dd14), rs2:x30(0x80000001), result rd:x8(0xec52dd13)
li x20, MASK_XLEN(0x6c52dd14)
li x30, MASK_XLEN(0x80000001)
SUB x8, x20, x30
sw x8, 224(x6)

# Testcase 57:  rs1:x1(0x6c52dd14), rs2:x11(0x9173ab42), result rd:x23(0xdadf31d2)
li x1, MASK_XLEN(0x6c52dd14)
li x11, MASK_XLEN(0x9173ab42)
SUB x23, x1, x11
sw x23, 228(x6)

# Testcase 58:  rs1:x31(0x6c52dd14), rs2:x24(0xfffffffe), result rd:x29(0x6c52dd16)
li x31, MASK_XLEN(0x6c52dd14)
li x24, MASK_XLEN(0xfffffffe)
SUB x29, x31, x24
sw x29, 232(x6)

# Testcase 59:  rs1:x11(0x6c52dd14), rs2:x27(0xffffffff), result rd:x11(0x6c52dd15)
li x11, MASK_XLEN(0x6c52dd14)
li x27, MASK_XLEN(0xffffffff)
SUB x11, x11, x27
sw x11, 236(x6)

# Testcase 60:  rs1:x2(0x7ffffffe), rs2:x17(0x00000000), result rd:x5(0x7ffffffe)
li x2, MASK_XLEN(0x7ffffffe)
li x17, MASK_XLEN(0x00000000)
SUB x5, x2, x17
sw x5, 240(x6)

# Testcase 61:  rs1:x28(0x7ffffffe), rs2:x9(0x00000001), result rd:x20(0x7ffffffd)
li x28, MASK_XLEN(0x7ffffffe)
li x9, MASK_XLEN(0x00000001)
SUB x20, x28, x9
sw x20, 244(x6)

# Testcase 62:  rs1:x26(0x7ffffffe), rs2:x5(0x00000002), result rd:x27(0x7ffffffc)
li x26, MASK_XLEN(0x7ffffffe)
li x5, MASK_XLEN(0x00000002)
SUB x27, x26, x5
sw x27, 248(x6)

# Testcase 63:  rs1:x13(0x7ffffffe), rs2:x19(0x000000ff), result rd:x10(0x7ffffeff)
li x13, MASK_XLEN(0x7ffffffe)
li x19, MASK_XLEN(0x000000ff)
SUB x10, x13, x19
sw x10, 252(x6)

# Testcase 64:  rs1:x16(0x7ffffffe), rs2:x3(0x6c52dd14), result rd:x26(0x13ad22ea)
li x16, MASK_XLEN(0x7ffffffe)
li x3, MASK_XLEN(0x6c52dd14)
SUB x26, x16, x3
sw x26, 256(x6)

# Testcase 65:  rs1:x3(0x7ffffffe), rs2:x17(0x7ffffffe), result rd:x28(0x00000000)
li x3, MASK_XLEN(0x7ffffffe)
li x17, MASK_XLEN(0x7ffffffe)
SUB x28, x3, x17
sw x28, 260(x6)

# Testcase 66:  rs1:x30(0x7ffffffe), rs2:x2(0x7fffffff), result rd:x3(0xffffffff)
li x30, MASK_XLEN(0x7ffffffe)
li x2, MASK_XLEN(0x7fffffff)
SUB x3, x30, x2
sw x3, 264(x6)

# Testcase 67:  rs1:x8(0x7ffffffe), rs2:x5(0x80000000), result rd:x2(0xfffffffe)
li x8, MASK_XLEN(0x7ffffffe)
li x5, MASK_XLEN(0x80000000)
SUB x2, x8, x5
sw x2, 268(x6)

# Testcase 68:  rs1:x10(0x7ffffffe), rs2:x1(0x80000001), result rd:x25(0xfffffffd)
li x10, MASK_XLEN(0x7ffffffe)
li x1, MASK_XLEN(0x80000001)
SUB x25, x10, x1
sw x25, 272(x6)

# Testcase 69:  rs1:x28(0x7ffffffe), rs2:x15(0x9173ab42), result rd:x11(0xee8c54bc)
li x28, MASK_XLEN(0x7ffffffe)
li x15, MASK_XLEN(0x9173ab42)
SUB x11, x28, x15
sw x11, 276(x6)

# Testcase 70:  rs1:x5(0x7ffffffe), rs2:x28(0xfffffffe), result rd:x21(0x80000000)
li x5, MASK_XLEN(0x7ffffffe)
li x28, MASK_XLEN(0xfffffffe)
SUB x21, x5, x28
sw x21, 280(x6)

# Testcase 71:  rs1:x15(0x7ffffffe), rs2:x31(0xffffffff), result rd:x12(0x7fffffff)
li x15, MASK_XLEN(0x7ffffffe)
li x31, MASK_XLEN(0xffffffff)
SUB x12, x15, x31
sw x12, 284(x6)

# Testcase 72:  rs1:x17(0x7fffffff), rs2:x13(0x00000000), result rd:x29(0x7fffffff)
li x17, MASK_XLEN(0x7fffffff)
li x13, MASK_XLEN(0x00000000)
SUB x29, x17, x13
sw x29, 288(x6)

# Testcase 73:  rs1:x19(0x7fffffff), rs2:x3(0x00000001), result rd:x22(0x7ffffffe)
li x19, MASK_XLEN(0x7fffffff)
li x3, MASK_XLEN(0x00000001)
SUB x22, x19, x3
sw x22, 292(x6)

# Testcase 74:  rs1:x25(0x7fffffff), rs2:x20(0x00000002), result rd:x3(0x7ffffffd)
li x25, MASK_XLEN(0x7fffffff)
li x20, MASK_XLEN(0x00000002)
SUB x3, x25, x20
sw x3, 296(x6)

# Testcase 75:  rs1:x24(0x7fffffff), rs2:x14(0x000000ff), result rd:x29(0x7fffff00)
li x24, MASK_XLEN(0x7fffffff)
li x14, MASK_XLEN(0x000000ff)
SUB x29, x24, x14
sw x29, 300(x6)

# Testcase 76:  rs1:x25(0x7fffffff), rs2:x7(0x6c52dd14), result rd:x10(0x13ad22eb)
li x25, MASK_XLEN(0x7fffffff)
li x7, MASK_XLEN(0x6c52dd14)
SUB x10, x25, x7
sw x10, 304(x6)

# Testcase 77:  rs1:x18(0x7fffffff), rs2:x29(0x7ffffffe), result rd:x20(0x00000001)
li x18, MASK_XLEN(0x7fffffff)
li x29, MASK_XLEN(0x7ffffffe)
SUB x20, x18, x29
sw x20, 308(x6)

# Testcase 78:  rs1:x14(0x7fffffff), rs2:x27(0x7fffffff), result rd:x16(0x00000000)
li x14, MASK_XLEN(0x7fffffff)
li x27, MASK_XLEN(0x7fffffff)
SUB x16, x14, x27
sw x16, 312(x6)

# Testcase 79:  rs1:x28(0x7fffffff), rs2:x26(0x80000000), result rd:x13(0xffffffff)
li x28, MASK_XLEN(0x7fffffff)
li x26, MASK_XLEN(0x80000000)
SUB x13, x28, x26
sw x13, 316(x6)

# Testcase 80:  rs1:x20(0x7fffffff), rs2:x19(0x80000001), result rd:x8(0xfffffffe)
li x20, MASK_XLEN(0x7fffffff)
li x19, MASK_XLEN(0x80000001)
SUB x8, x20, x19
sw x8, 320(x6)

# Testcase 81:  rs1:x1(0x7fffffff), rs2:x22(0x9173ab42), result rd:x29(0xee8c54bd)
li x1, MASK_XLEN(0x7fffffff)
li x22, MASK_XLEN(0x9173ab42)
SUB x29, x1, x22
sw x29, 324(x6)

# Testcase 82:  rs1:x10(0x7fffffff), rs2:x17(0xfffffffe), result rd:x19(0x80000001)
li x10, MASK_XLEN(0x7fffffff)
li x17, MASK_XLEN(0xfffffffe)
SUB x19, x10, x17
sw x19, 328(x6)

# Testcase 83:  rs1:x9(0x7fffffff), rs2:x11(0xffffffff), result rd:x3(0x80000000)
li x9, MASK_XLEN(0x7fffffff)
li x11, MASK_XLEN(0xffffffff)
SUB x3, x9, x11
sw x3, 332(x6)

# Testcase 84:  rs1:x16(0x80000000), rs2:x28(0x00000000), result rd:x9(0x80000000)
li x16, MASK_XLEN(0x80000000)
li x28, MASK_XLEN(0x00000000)
SUB x9, x16, x28
sw x9, 336(x6)

# Testcase 85:  rs1:x31(0x80000000), rs2:x27(0x00000001), result rd:x10(0x7fffffff)
li x31, MASK_XLEN(0x80000000)
li x27, MASK_XLEN(0x00000001)
SUB x10, x31, x27
sw x10, 340(x6)

# Testcase 86:  rs1:x25(0x80000000), rs2:x14(0x00000002), result rd:x13(0x7ffffffe)
li x25, MASK_XLEN(0x80000000)
li x14, MASK_XLEN(0x00000002)
SUB x13, x25, x14
sw x13, 344(x6)

# Testcase 87:  rs1:x26(0x80000000), rs2:x13(0x000000ff), result rd:x2(0x7fffff01)
li x26, MASK_XLEN(0x80000000)
li x13, MASK_XLEN(0x000000ff)
SUB x2, x26, x13
sw x2, 348(x6)

# Testcase 88:  rs1:x5(0x80000000), rs2:x8(0x6c52dd14), result rd:x10(0x13ad22ec)
li x5, MASK_XLEN(0x80000000)
li x8, MASK_XLEN(0x6c52dd14)
SUB x10, x5, x8
sw x10, 352(x6)

# Testcase 89:  rs1:x24(0x80000000), rs2:x27(0x7ffffffe), result rd:x11(0x00000002)
li x24, MASK_XLEN(0x80000000)
li x27, MASK_XLEN(0x7ffffffe)
SUB x11, x24, x27
sw x11, 356(x6)

# Testcase 90:  rs1:x2(0x80000000), rs2:x31(0x7fffffff), result rd:x2(0x00000001)
li x2, MASK_XLEN(0x80000000)
li x31, MASK_XLEN(0x7fffffff)
SUB x2, x2, x31
sw x2, 360(x6)

# Testcase 91:  rs1:x16(0x80000000), rs2:x14(0x80000000), result rd:x5(0x00000000)
li x16, MASK_XLEN(0x80000000)
li x14, MASK_XLEN(0x80000000)
SUB x5, x16, x14
sw x5, 364(x6)

# Testcase 92:  rs1:x16(0x80000000), rs2:x29(0x80000001), result rd:x28(0xffffffff)
li x16, MASK_XLEN(0x80000000)
li x29, MASK_XLEN(0x80000001)
SUB x28, x16, x29
sw x28, 368(x6)

# Testcase 93:  rs1:x20(0x80000000), rs2:x23(0x9173ab42), result rd:x3(0xee8c54be)
li x20, MASK_XLEN(0x80000000)
li x23, MASK_XLEN(0x9173ab42)
SUB x3, x20, x23
sw x3, 372(x6)

# Testcase 94:  rs1:x22(0x80000000), rs2:x23(0xfffffffe), result rd:x5(0x80000002)
li x22, MASK_XLEN(0x80000000)
li x23, MASK_XLEN(0xfffffffe)
SUB x5, x22, x23
sw x5, 376(x6)

# Testcase 95:  rs1:x26(0x80000000), rs2:x12(0xffffffff), result rd:x14(0x80000001)
li x26, MASK_XLEN(0x80000000)
li x12, MASK_XLEN(0xffffffff)
SUB x14, x26, x12
sw x14, 380(x6)

# Testcase 96:  rs1:x2(0x80000001), rs2:x20(0x00000000), result rd:x15(0x80000001)
li x2, MASK_XLEN(0x80000001)
li x20, MASK_XLEN(0x00000000)
SUB x15, x2, x20
sw x15, 384(x6)

# Testcase 97:  rs1:x13(0x80000001), rs2:x15(0x00000001), result rd:x2(0x80000000)
li x13, MASK_XLEN(0x80000001)
li x15, MASK_XLEN(0x00000001)
SUB x2, x13, x15
sw x2, 388(x6)

# Testcase 98:  rs1:x4(0x80000001), rs2:x16(0x00000002), result rd:x25(0x7fffffff)
li x4, MASK_XLEN(0x80000001)
li x16, MASK_XLEN(0x00000002)
SUB x25, x4, x16
sw x25, 392(x6)

# Testcase 99:  rs1:x5(0x80000001), rs2:x1(0x000000ff), result rd:x2(0x7fffff02)
li x5, MASK_XLEN(0x80000001)
li x1, MASK_XLEN(0x000000ff)
SUB x2, x5, x1
sw x2, 396(x6)

# Testcase 100:  rs1:x21(0x80000001), rs2:x11(0x6c52dd14), result rd:x4(0x13ad22ed)
li x21, MASK_XLEN(0x80000001)
li x11, MASK_XLEN(0x6c52dd14)
SUB x4, x21, x11
sw x4, 400(x6)

# Testcase 101:  rs1:x23(0x80000001), rs2:x18(0x7ffffffe), result rd:x21(0x00000003)
li x23, MASK_XLEN(0x80000001)
li x18, MASK_XLEN(0x7ffffffe)
SUB x21, x23, x18
sw x21, 404(x6)

# Testcase 102:  rs1:x12(0x80000001), rs2:x7(0x7fffffff), result rd:x13(0x00000002)
li x12, MASK_XLEN(0x80000001)
li x7, MASK_XLEN(0x7fffffff)
SUB x13, x12, x7
sw x13, 408(x6)

# Testcase 103:  rs1:x26(0x80000001), rs2:x25(0x80000000), result rd:x25(0x00000001)
li x26, MASK_XLEN(0x80000001)
li x25, MASK_XLEN(0x80000000)
SUB x25, x26, x25
sw x25, 412(x6)

# Testcase 104:  rs1:x16(0x80000001), rs2:x4(0x80000001), result rd:x29(0x00000000)
li x16, MASK_XLEN(0x80000001)
li x4, MASK_XLEN(0x80000001)
SUB x29, x16, x4
sw x29, 416(x6)

# Testcase 105:  rs1:x2(0x80000001), rs2:x20(0x9173ab42), result rd:x23(0xee8c54bf)
li x2, MASK_XLEN(0x80000001)
li x20, MASK_XLEN(0x9173ab42)
SUB x23, x2, x20
sw x23, 420(x6)

# Testcase 106:  rs1:x15(0x80000001), rs2:x20(0xfffffffe), result rd:x21(0x80000003)
li x15, MASK_XLEN(0x80000001)
li x20, MASK_XLEN(0xfffffffe)
SUB x21, x15, x20
sw x21, 424(x6)

# Testcase 107:  rs1:x30(0x80000001), rs2:x11(0xffffffff), result rd:x21(0x80000002)
li x30, MASK_XLEN(0x80000001)
li x11, MASK_XLEN(0xffffffff)
SUB x21, x30, x11
sw x21, 428(x6)

# Testcase 108:  rs1:x4(0x9173ab42), rs2:x22(0x00000000), result rd:x23(0x9173ab42)
li x4, MASK_XLEN(0x9173ab42)
li x22, MASK_XLEN(0x00000000)
SUB x23, x4, x22
sw x23, 432(x6)

# Testcase 109:  rs1:x20(0x9173ab42), rs2:x10(0x00000001), result rd:x26(0x9173ab41)
li x20, MASK_XLEN(0x9173ab42)
li x10, MASK_XLEN(0x00000001)
SUB x26, x20, x10
sw x26, 436(x6)

# Testcase 110:  rs1:x28(0x9173ab42), rs2:x5(0x00000002), result rd:x31(0x9173ab40)
li x28, MASK_XLEN(0x9173ab42)
li x5, MASK_XLEN(0x00000002)
SUB x31, x28, x5
sw x31, 440(x6)

# Testcase 111:  rs1:x30(0x9173ab42), rs2:x13(0x000000ff), result rd:x26(0x9173aa43)
li x30, MASK_XLEN(0x9173ab42)
li x13, MASK_XLEN(0x000000ff)
SUB x26, x30, x13
sw x26, 444(x6)

# Testcase 112:  rs1:x10(0x9173ab42), rs2:x30(0x6c52dd14), result rd:x24(0x2520ce2e)
li x10, MASK_XLEN(0x9173ab42)
li x30, MASK_XLEN(0x6c52dd14)
SUB x24, x10, x30
sw x24, 448(x6)

# Testcase 113:  rs1:x28(0x9173ab42), rs2:x31(0x7ffffffe), result rd:x22(0x1173ab44)
li x28, MASK_XLEN(0x9173ab42)
li x31, MASK_XLEN(0x7ffffffe)
SUB x22, x28, x31
sw x22, 452(x6)

# Testcase 114:  rs1:x26(0x9173ab42), rs2:x4(0x7fffffff), result rd:x17(0x1173ab43)
li x26, MASK_XLEN(0x9173ab42)
li x4, MASK_XLEN(0x7fffffff)
SUB x17, x26, x4
sw x17, 456(x6)

# Testcase 115:  rs1:x28(0x9173ab42), rs2:x26(0x80000000), result rd:x7(0x1173ab42)
li x28, MASK_XLEN(0x9173ab42)
li x26, MASK_XLEN(0x80000000)
SUB x7, x28, x26
sw x7, 460(x6)

# Testcase 116:  rs1:x2(0x9173ab42), rs2:x26(0x80000001), result rd:x13(0x1173ab41)
li x2, MASK_XLEN(0x9173ab42)
li x26, MASK_XLEN(0x80000001)
SUB x13, x2, x26
sw x13, 464(x6)

# Testcase 117:  rs1:x15(0x9173ab42), rs2:x12(0x9173ab42), result rd:x25(0x00000000)
li x15, MASK_XLEN(0x9173ab42)
li x12, MASK_XLEN(0x9173ab42)
SUB x25, x15, x12
sw x25, 468(x6)

# Testcase 118:  rs1:x7(0x9173ab42), rs2:x15(0xfffffffe), result rd:x12(0x9173ab44)
li x7, MASK_XLEN(0x9173ab42)
li x15, MASK_XLEN(0xfffffffe)
SUB x12, x7, x15
sw x12, 472(x6)

# Testcase 119:  rs1:x26(0x9173ab42), rs2:x21(0xffffffff), result rd:x3(0x9173ab43)
li x26, MASK_XLEN(0x9173ab42)
li x21, MASK_XLEN(0xffffffff)
SUB x3, x26, x21
sw x3, 476(x6)

# Testcase 120:  rs1:x31(0xfffffffe), rs2:x2(0x00000000), result rd:x29(0xfffffffe)
li x31, MASK_XLEN(0xfffffffe)
li x2, MASK_XLEN(0x00000000)
SUB x29, x31, x2
sw x29, 480(x6)

# Testcase 121:  rs1:x30(0xfffffffe), rs2:x2(0x00000001), result rd:x16(0xfffffffd)
li x30, MASK_XLEN(0xfffffffe)
li x2, MASK_XLEN(0x00000001)
SUB x16, x30, x2
sw x16, 484(x6)

# Testcase 122:  rs1:x9(0xfffffffe), rs2:x29(0x00000002), result rd:x1(0xfffffffc)
li x9, MASK_XLEN(0xfffffffe)
li x29, MASK_XLEN(0x00000002)
SUB x1, x9, x29
sw x1, 488(x6)

# Testcase 123:  rs1:x31(0xfffffffe), rs2:x17(0x000000ff), result rd:x22(0xfffffeff)
li x31, MASK_XLEN(0xfffffffe)
li x17, MASK_XLEN(0x000000ff)
SUB x22, x31, x17
sw x22, 492(x6)

# Testcase 124:  rs1:x7(0xfffffffe), rs2:x8(0x6c52dd14), result rd:x3(0x93ad22ea)
li x7, MASK_XLEN(0xfffffffe)
li x8, MASK_XLEN(0x6c52dd14)
SUB x3, x7, x8
sw x3, 496(x6)

# Testcase 125:  rs1:x25(0xfffffffe), rs2:x27(0x7ffffffe), result rd:x29(0x80000000)
li x25, MASK_XLEN(0xfffffffe)
li x27, MASK_XLEN(0x7ffffffe)
SUB x29, x25, x27
sw x29, 500(x6)

# Testcase 126:  rs1:x29(0xfffffffe), rs2:x21(0x7fffffff), result rd:x25(0x7fffffff)
li x29, MASK_XLEN(0xfffffffe)
li x21, MASK_XLEN(0x7fffffff)
SUB x25, x29, x21
sw x25, 504(x6)

# Testcase 127:  rs1:x17(0xfffffffe), rs2:x23(0x80000000), result rd:x17(0x7ffffffe)
li x17, MASK_XLEN(0xfffffffe)
li x23, MASK_XLEN(0x80000000)
SUB x17, x17, x23
sw x17, 508(x6)

# Testcase 128:  rs1:x14(0xfffffffe), rs2:x17(0x80000001), result rd:x10(0x7ffffffd)
li x14, MASK_XLEN(0xfffffffe)
li x17, MASK_XLEN(0x80000001)
SUB x10, x14, x17
sw x10, 512(x6)

# Testcase 129:  rs1:x31(0xfffffffe), rs2:x4(0x9173ab42), result rd:x5(0x6e8c54bc)
li x31, MASK_XLEN(0xfffffffe)
li x4, MASK_XLEN(0x9173ab42)
SUB x5, x31, x4
sw x5, 516(x6)

# Testcase 130:  rs1:x14(0xfffffffe), rs2:x29(0xfffffffe), result rd:x19(0x00000000)
li x14, MASK_XLEN(0xfffffffe)
li x29, MASK_XLEN(0xfffffffe)
SUB x19, x14, x29
sw x19, 520(x6)

# Testcase 131:  rs1:x14(0xfffffffe), rs2:x30(0xffffffff), result rd:x3(0xffffffff)
li x14, MASK_XLEN(0xfffffffe)
li x30, MASK_XLEN(0xffffffff)
SUB x3, x14, x30
sw x3, 524(x6)

# Testcase 132:  rs1:x30(0xffffffff), rs2:x4(0x00000000), result rd:x14(0xffffffff)
li x30, MASK_XLEN(0xffffffff)
li x4, MASK_XLEN(0x00000000)
SUB x14, x30, x4
sw x14, 528(x6)

# Testcase 133:  rs1:x3(0xffffffff), rs2:x4(0x00000001), result rd:x14(0xfffffffe)
li x3, MASK_XLEN(0xffffffff)
li x4, MASK_XLEN(0x00000001)
SUB x14, x3, x4
sw x14, 532(x6)

# Testcase 134:  rs1:x25(0xffffffff), rs2:x5(0x00000002), result rd:x24(0xfffffffd)
li x25, MASK_XLEN(0xffffffff)
li x5, MASK_XLEN(0x00000002)
SUB x24, x25, x5
sw x24, 536(x6)

# Testcase 135:  rs1:x31(0xffffffff), rs2:x1(0x000000ff), result rd:x26(0xffffff00)
li x31, MASK_XLEN(0xffffffff)
li x1, MASK_XLEN(0x000000ff)
SUB x26, x31, x1
sw x26, 540(x6)

# Testcase 136:  rs1:x15(0xffffffff), rs2:x14(0x6c52dd14), result rd:x22(0x93ad22eb)
li x15, MASK_XLEN(0xffffffff)
li x14, MASK_XLEN(0x6c52dd14)
SUB x22, x15, x14
sw x22, 544(x6)

# Testcase 137:  rs1:x14(0xffffffff), rs2:x1(0x7ffffffe), result rd:x16(0x80000001)
li x14, MASK_XLEN(0xffffffff)
li x1, MASK_XLEN(0x7ffffffe)
SUB x16, x14, x1
sw x16, 548(x6)

# Testcase 138:  rs1:x30(0xffffffff), rs2:x28(0x7fffffff), result rd:x31(0x80000000)
li x30, MASK_XLEN(0xffffffff)
li x28, MASK_XLEN(0x7fffffff)
SUB x31, x30, x28
sw x31, 552(x6)

# Testcase 139:  rs1:x11(0xffffffff), rs2:x24(0x80000000), result rd:x9(0x7fffffff)
li x11, MASK_XLEN(0xffffffff)
li x24, MASK_XLEN(0x80000000)
SUB x9, x11, x24
sw x9, 556(x6)

# Testcase 140:  rs1:x3(0xffffffff), rs2:x12(0x80000001), result rd:x3(0x7ffffffe)
li x3, MASK_XLEN(0xffffffff)
li x12, MASK_XLEN(0x80000001)
SUB x3, x3, x12
sw x3, 560(x6)

# Testcase 141:  rs1:x4(0xffffffff), rs2:x12(0x9173ab42), result rd:x23(0x6e8c54bd)
li x4, MASK_XLEN(0xffffffff)
li x12, MASK_XLEN(0x9173ab42)
SUB x23, x4, x12
sw x23, 564(x6)

# Testcase 142:  rs1:x1(0xffffffff), rs2:x12(0xfffffffe), result rd:x12(0x00000001)
li x1, MASK_XLEN(0xffffffff)
li x12, MASK_XLEN(0xfffffffe)
SUB x12, x1, x12
sw x12, 568(x6)

# Testcase 143:  rs1:x8(0xffffffff), rs2:x27(0xffffffff), result rd:x12(0x00000000)
li x8, MASK_XLEN(0xffffffff)
li x27, MASK_XLEN(0xffffffff)
SUB x12, x8, x27
sw x12, 572(x6)

# Testcase 144:  rs1:x29(0x120d7126), rs2:x5(0x98ba0f0e), result rd:x7(0x79536218)
li x29, MASK_XLEN(0x120d7126)
li x5, MASK_XLEN(0x98ba0f0e)
SUB x7, x29, x5
sw x7, 576(x6)

# Testcase 145:  rs1:x31(0x00d3d1af), rs2:x29(0x346d2b7e), result rd:x4(0xcc66a631)
li x31, MASK_XLEN(0x00d3d1af)
li x29, MASK_XLEN(0x346d2b7e)
SUB x4, x31, x29
sw x4, 580(x6)

# Testcase 146:  rs1:x10(0xbf7b68ae), rs2:x12(0x01d6d903), result rd:x23(0xbda48fab)
li x10, MASK_XLEN(0xbf7b68ae)
li x12, MASK_XLEN(0x01d6d903)
SUB x23, x10, x12
sw x23, 584(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SUB.S
// David_Harris@hmc.edu & Katherine Parry

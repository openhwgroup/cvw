///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.473307//
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

# Testcase 0:  rs1:x18(0x00000000), rs2:x25(0x00000000), result rd:x29(0x00000000)
li x18, MASK_XLEN(0x00000000)
li x25, MASK_XLEN(0x00000000)
SLTU x29, x18, x25
sw x29, 0(x6)

# Testcase 1:  rs1:x27(0x00000000), rs2:x13(0x00000001), result rd:x2(0x00000001)
li x27, MASK_XLEN(0x00000000)
li x13, MASK_XLEN(0x00000001)
SLTU x2, x27, x13
sw x2, 4(x6)

# Testcase 2:  rs1:x16(0x00000000), rs2:x8(0x00000002), result rd:x5(0x00000001)
li x16, MASK_XLEN(0x00000000)
li x8, MASK_XLEN(0x00000002)
SLTU x5, x16, x8
sw x5, 8(x6)

# Testcase 3:  rs1:x27(0x00000000), rs2:x28(0x000000ff), result rd:x9(0x00000001)
li x27, MASK_XLEN(0x00000000)
li x28, MASK_XLEN(0x000000ff)
SLTU x9, x27, x28
sw x9, 12(x6)

# Testcase 4:  rs1:x30(0x00000000), rs2:x12(0x6c52dd14), result rd:x11(0x00000001)
li x30, MASK_XLEN(0x00000000)
li x12, MASK_XLEN(0x6c52dd14)
SLTU x11, x30, x12
sw x11, 16(x6)

# Testcase 5:  rs1:x14(0x00000000), rs2:x4(0x7ffffffe), result rd:x18(0x00000001)
li x14, MASK_XLEN(0x00000000)
li x4, MASK_XLEN(0x7ffffffe)
SLTU x18, x14, x4
sw x18, 20(x6)

# Testcase 6:  rs1:x29(0x00000000), rs2:x10(0x7fffffff), result rd:x20(0x00000001)
li x29, MASK_XLEN(0x00000000)
li x10, MASK_XLEN(0x7fffffff)
SLTU x20, x29, x10
sw x20, 24(x6)

# Testcase 7:  rs1:x18(0x00000000), rs2:x26(0x80000000), result rd:x7(0x00000001)
li x18, MASK_XLEN(0x00000000)
li x26, MASK_XLEN(0x80000000)
SLTU x7, x18, x26
sw x7, 28(x6)

# Testcase 8:  rs1:x23(0x00000000), rs2:x10(0x80000001), result rd:x25(0x00000001)
li x23, MASK_XLEN(0x00000000)
li x10, MASK_XLEN(0x80000001)
SLTU x25, x23, x10
sw x25, 32(x6)

# Testcase 9:  rs1:x15(0x00000000), rs2:x17(0x9173ab42), result rd:x20(0x00000001)
li x15, MASK_XLEN(0x00000000)
li x17, MASK_XLEN(0x9173ab42)
SLTU x20, x15, x17
sw x20, 36(x6)

# Testcase 10:  rs1:x15(0x00000000), rs2:x18(0xfffffffe), result rd:x21(0x00000001)
li x15, MASK_XLEN(0x00000000)
li x18, MASK_XLEN(0xfffffffe)
SLTU x21, x15, x18
sw x21, 40(x6)

# Testcase 11:  rs1:x1(0x00000000), rs2:x4(0xffffffff), result rd:x20(0x00000001)
li x1, MASK_XLEN(0x00000000)
li x4, MASK_XLEN(0xffffffff)
SLTU x20, x1, x4
sw x20, 44(x6)

# Testcase 12:  rs1:x26(0x00000001), rs2:x23(0x00000000), result rd:x4(0x00000000)
li x26, MASK_XLEN(0x00000001)
li x23, MASK_XLEN(0x00000000)
SLTU x4, x26, x23
sw x4, 48(x6)

# Testcase 13:  rs1:x8(0x00000001), rs2:x7(0x00000001), result rd:x10(0x00000000)
li x8, MASK_XLEN(0x00000001)
li x7, MASK_XLEN(0x00000001)
SLTU x10, x8, x7
sw x10, 52(x6)

# Testcase 14:  rs1:x29(0x00000001), rs2:x24(0x00000002), result rd:x22(0x00000001)
li x29, MASK_XLEN(0x00000001)
li x24, MASK_XLEN(0x00000002)
SLTU x22, x29, x24
sw x22, 56(x6)

# Testcase 15:  rs1:x1(0x00000001), rs2:x24(0x000000ff), result rd:x18(0x00000001)
li x1, MASK_XLEN(0x00000001)
li x24, MASK_XLEN(0x000000ff)
SLTU x18, x1, x24
sw x18, 60(x6)

# Testcase 16:  rs1:x17(0x00000001), rs2:x14(0x6c52dd14), result rd:x28(0x00000001)
li x17, MASK_XLEN(0x00000001)
li x14, MASK_XLEN(0x6c52dd14)
SLTU x28, x17, x14
sw x28, 64(x6)

# Testcase 17:  rs1:x2(0x00000001), rs2:x4(0x7ffffffe), result rd:x13(0x00000001)
li x2, MASK_XLEN(0x00000001)
li x4, MASK_XLEN(0x7ffffffe)
SLTU x13, x2, x4
sw x13, 68(x6)

# Testcase 18:  rs1:x21(0x00000001), rs2:x9(0x7fffffff), result rd:x4(0x00000001)
li x21, MASK_XLEN(0x00000001)
li x9, MASK_XLEN(0x7fffffff)
SLTU x4, x21, x9
sw x4, 72(x6)

# Testcase 19:  rs1:x24(0x00000001), rs2:x19(0x80000000), result rd:x12(0x00000001)
li x24, MASK_XLEN(0x00000001)
li x19, MASK_XLEN(0x80000000)
SLTU x12, x24, x19
sw x12, 76(x6)

# Testcase 20:  rs1:x8(0x00000001), rs2:x22(0x80000001), result rd:x23(0x00000001)
li x8, MASK_XLEN(0x00000001)
li x22, MASK_XLEN(0x80000001)
SLTU x23, x8, x22
sw x23, 80(x6)

# Testcase 21:  rs1:x23(0x00000001), rs2:x18(0x9173ab42), result rd:x22(0x00000001)
li x23, MASK_XLEN(0x00000001)
li x18, MASK_XLEN(0x9173ab42)
SLTU x22, x23, x18
sw x22, 84(x6)

# Testcase 22:  rs1:x10(0x00000001), rs2:x8(0xfffffffe), result rd:x24(0x00000001)
li x10, MASK_XLEN(0x00000001)
li x8, MASK_XLEN(0xfffffffe)
SLTU x24, x10, x8
sw x24, 88(x6)

# Testcase 23:  rs1:x27(0x00000001), rs2:x29(0xffffffff), result rd:x8(0x00000001)
li x27, MASK_XLEN(0x00000001)
li x29, MASK_XLEN(0xffffffff)
SLTU x8, x27, x29
sw x8, 92(x6)

# Testcase 24:  rs1:x3(0x00000002), rs2:x17(0x00000000), result rd:x10(0x00000000)
li x3, MASK_XLEN(0x00000002)
li x17, MASK_XLEN(0x00000000)
SLTU x10, x3, x17
sw x10, 96(x6)

# Testcase 25:  rs1:x22(0x00000002), rs2:x11(0x00000001), result rd:x8(0x00000000)
li x22, MASK_XLEN(0x00000002)
li x11, MASK_XLEN(0x00000001)
SLTU x8, x22, x11
sw x8, 100(x6)

# Testcase 26:  rs1:x12(0x00000002), rs2:x21(0x00000002), result rd:x16(0x00000000)
li x12, MASK_XLEN(0x00000002)
li x21, MASK_XLEN(0x00000002)
SLTU x16, x12, x21
sw x16, 104(x6)

# Testcase 27:  rs1:x5(0x00000002), rs2:x26(0x000000ff), result rd:x1(0x00000001)
li x5, MASK_XLEN(0x00000002)
li x26, MASK_XLEN(0x000000ff)
SLTU x1, x5, x26
sw x1, 108(x6)

# Testcase 28:  rs1:x18(0x00000002), rs2:x17(0x6c52dd14), result rd:x11(0x00000001)
li x18, MASK_XLEN(0x00000002)
li x17, MASK_XLEN(0x6c52dd14)
SLTU x11, x18, x17
sw x11, 112(x6)

# Testcase 29:  rs1:x12(0x00000002), rs2:x19(0x7ffffffe), result rd:x21(0x00000001)
li x12, MASK_XLEN(0x00000002)
li x19, MASK_XLEN(0x7ffffffe)
SLTU x21, x12, x19
sw x21, 116(x6)

# Testcase 30:  rs1:x1(0x00000002), rs2:x26(0x7fffffff), result rd:x5(0x00000001)
li x1, MASK_XLEN(0x00000002)
li x26, MASK_XLEN(0x7fffffff)
SLTU x5, x1, x26
sw x5, 120(x6)

# Testcase 31:  rs1:x29(0x00000002), rs2:x13(0x80000000), result rd:x5(0x00000001)
li x29, MASK_XLEN(0x00000002)
li x13, MASK_XLEN(0x80000000)
SLTU x5, x29, x13
sw x5, 124(x6)

# Testcase 32:  rs1:x5(0x00000002), rs2:x25(0x80000001), result rd:x7(0x00000001)
li x5, MASK_XLEN(0x00000002)
li x25, MASK_XLEN(0x80000001)
SLTU x7, x5, x25
sw x7, 128(x6)

# Testcase 33:  rs1:x26(0x00000002), rs2:x30(0x9173ab42), result rd:x25(0x00000001)
li x26, MASK_XLEN(0x00000002)
li x30, MASK_XLEN(0x9173ab42)
SLTU x25, x26, x30
sw x25, 132(x6)

# Testcase 34:  rs1:x16(0x00000002), rs2:x19(0xfffffffe), result rd:x25(0x00000001)
li x16, MASK_XLEN(0x00000002)
li x19, MASK_XLEN(0xfffffffe)
SLTU x25, x16, x19
sw x25, 136(x6)

# Testcase 35:  rs1:x23(0x00000002), rs2:x7(0xffffffff), result rd:x8(0x00000001)
li x23, MASK_XLEN(0x00000002)
li x7, MASK_XLEN(0xffffffff)
SLTU x8, x23, x7
sw x8, 140(x6)

# Testcase 36:  rs1:x24(0x000000ff), rs2:x5(0x00000000), result rd:x27(0x00000000)
li x24, MASK_XLEN(0x000000ff)
li x5, MASK_XLEN(0x00000000)
SLTU x27, x24, x5
sw x27, 144(x6)

# Testcase 37:  rs1:x8(0x000000ff), rs2:x25(0x00000001), result rd:x13(0x00000000)
li x8, MASK_XLEN(0x000000ff)
li x25, MASK_XLEN(0x00000001)
SLTU x13, x8, x25
sw x13, 148(x6)

# Testcase 38:  rs1:x12(0x000000ff), rs2:x20(0x00000002), result rd:x19(0x00000000)
li x12, MASK_XLEN(0x000000ff)
li x20, MASK_XLEN(0x00000002)
SLTU x19, x12, x20
sw x19, 152(x6)

# Testcase 39:  rs1:x5(0x000000ff), rs2:x21(0x000000ff), result rd:x16(0x00000000)
li x5, MASK_XLEN(0x000000ff)
li x21, MASK_XLEN(0x000000ff)
SLTU x16, x5, x21
sw x16, 156(x6)

# Testcase 40:  rs1:x29(0x000000ff), rs2:x30(0x6c52dd14), result rd:x4(0x00000001)
li x29, MASK_XLEN(0x000000ff)
li x30, MASK_XLEN(0x6c52dd14)
SLTU x4, x29, x30
sw x4, 160(x6)

# Testcase 41:  rs1:x20(0x000000ff), rs2:x27(0x7ffffffe), result rd:x1(0x00000001)
li x20, MASK_XLEN(0x000000ff)
li x27, MASK_XLEN(0x7ffffffe)
SLTU x1, x20, x27
sw x1, 164(x6)

# Testcase 42:  rs1:x17(0x000000ff), rs2:x20(0x7fffffff), result rd:x12(0x00000001)
li x17, MASK_XLEN(0x000000ff)
li x20, MASK_XLEN(0x7fffffff)
SLTU x12, x17, x20
sw x12, 168(x6)

# Testcase 43:  rs1:x16(0x000000ff), rs2:x15(0x80000000), result rd:x10(0x00000001)
li x16, MASK_XLEN(0x000000ff)
li x15, MASK_XLEN(0x80000000)
SLTU x10, x16, x15
sw x10, 172(x6)

# Testcase 44:  rs1:x1(0x000000ff), rs2:x31(0x80000001), result rd:x8(0x00000001)
li x1, MASK_XLEN(0x000000ff)
li x31, MASK_XLEN(0x80000001)
SLTU x8, x1, x31
sw x8, 176(x6)

# Testcase 45:  rs1:x22(0x000000ff), rs2:x29(0x9173ab42), result rd:x16(0x00000001)
li x22, MASK_XLEN(0x000000ff)
li x29, MASK_XLEN(0x9173ab42)
SLTU x16, x22, x29
sw x16, 180(x6)

# Testcase 46:  rs1:x26(0x000000ff), rs2:x31(0xfffffffe), result rd:x24(0x00000001)
li x26, MASK_XLEN(0x000000ff)
li x31, MASK_XLEN(0xfffffffe)
SLTU x24, x26, x31
sw x24, 184(x6)

# Testcase 47:  rs1:x16(0x000000ff), rs2:x18(0xffffffff), result rd:x11(0x00000001)
li x16, MASK_XLEN(0x000000ff)
li x18, MASK_XLEN(0xffffffff)
SLTU x11, x16, x18
sw x11, 188(x6)

# Testcase 48:  rs1:x23(0x6c52dd14), rs2:x28(0x00000000), result rd:x3(0x00000000)
li x23, MASK_XLEN(0x6c52dd14)
li x28, MASK_XLEN(0x00000000)
SLTU x3, x23, x28
sw x3, 192(x6)

# Testcase 49:  rs1:x9(0x6c52dd14), rs2:x5(0x00000001), result rd:x20(0x00000000)
li x9, MASK_XLEN(0x6c52dd14)
li x5, MASK_XLEN(0x00000001)
SLTU x20, x9, x5
sw x20, 196(x6)

# Testcase 50:  rs1:x13(0x6c52dd14), rs2:x23(0x00000002), result rd:x7(0x00000000)
li x13, MASK_XLEN(0x6c52dd14)
li x23, MASK_XLEN(0x00000002)
SLTU x7, x13, x23
sw x7, 200(x6)

# Testcase 51:  rs1:x27(0x6c52dd14), rs2:x11(0x000000ff), result rd:x26(0x00000000)
li x27, MASK_XLEN(0x6c52dd14)
li x11, MASK_XLEN(0x000000ff)
SLTU x26, x27, x11
sw x26, 204(x6)

# Testcase 52:  rs1:x10(0x6c52dd14), rs2:x13(0x6c52dd14), result rd:x31(0x00000000)
li x10, MASK_XLEN(0x6c52dd14)
li x13, MASK_XLEN(0x6c52dd14)
SLTU x31, x10, x13
sw x31, 208(x6)

# Testcase 53:  rs1:x2(0x6c52dd14), rs2:x7(0x7ffffffe), result rd:x2(0x00000001)
li x2, MASK_XLEN(0x6c52dd14)
li x7, MASK_XLEN(0x7ffffffe)
SLTU x2, x2, x7
sw x2, 212(x6)

# Testcase 54:  rs1:x11(0x6c52dd14), rs2:x24(0x7fffffff), result rd:x24(0x00000001)
li x11, MASK_XLEN(0x6c52dd14)
li x24, MASK_XLEN(0x7fffffff)
SLTU x24, x11, x24
sw x24, 216(x6)

# Testcase 55:  rs1:x31(0x6c52dd14), rs2:x8(0x80000000), result rd:x11(0x00000001)
li x31, MASK_XLEN(0x6c52dd14)
li x8, MASK_XLEN(0x80000000)
SLTU x11, x31, x8
sw x11, 220(x6)

# Testcase 56:  rs1:x28(0x6c52dd14), rs2:x15(0x80000001), result rd:x22(0x00000001)
li x28, MASK_XLEN(0x6c52dd14)
li x15, MASK_XLEN(0x80000001)
SLTU x22, x28, x15
sw x22, 224(x6)

# Testcase 57:  rs1:x24(0x6c52dd14), rs2:x22(0x9173ab42), result rd:x22(0x00000001)
li x24, MASK_XLEN(0x6c52dd14)
li x22, MASK_XLEN(0x9173ab42)
SLTU x22, x24, x22
sw x22, 228(x6)

# Testcase 58:  rs1:x8(0x6c52dd14), rs2:x9(0xfffffffe), result rd:x12(0x00000001)
li x8, MASK_XLEN(0x6c52dd14)
li x9, MASK_XLEN(0xfffffffe)
SLTU x12, x8, x9
sw x12, 232(x6)

# Testcase 59:  rs1:x1(0x6c52dd14), rs2:x12(0xffffffff), result rd:x19(0x00000001)
li x1, MASK_XLEN(0x6c52dd14)
li x12, MASK_XLEN(0xffffffff)
SLTU x19, x1, x12
sw x19, 236(x6)

# Testcase 60:  rs1:x18(0x7ffffffe), rs2:x2(0x00000000), result rd:x24(0x00000000)
li x18, MASK_XLEN(0x7ffffffe)
li x2, MASK_XLEN(0x00000000)
SLTU x24, x18, x2
sw x24, 240(x6)

# Testcase 61:  rs1:x21(0x7ffffffe), rs2:x5(0x00000001), result rd:x12(0x00000000)
li x21, MASK_XLEN(0x7ffffffe)
li x5, MASK_XLEN(0x00000001)
SLTU x12, x21, x5
sw x12, 244(x6)

# Testcase 62:  rs1:x1(0x7ffffffe), rs2:x16(0x00000002), result rd:x21(0x00000000)
li x1, MASK_XLEN(0x7ffffffe)
li x16, MASK_XLEN(0x00000002)
SLTU x21, x1, x16
sw x21, 248(x6)

# Testcase 63:  rs1:x2(0x7ffffffe), rs2:x1(0x000000ff), result rd:x8(0x00000000)
li x2, MASK_XLEN(0x7ffffffe)
li x1, MASK_XLEN(0x000000ff)
SLTU x8, x2, x1
sw x8, 252(x6)

# Testcase 64:  rs1:x2(0x7ffffffe), rs2:x1(0x6c52dd14), result rd:x8(0x00000000)
li x2, MASK_XLEN(0x7ffffffe)
li x1, MASK_XLEN(0x6c52dd14)
SLTU x8, x2, x1
sw x8, 256(x6)

# Testcase 65:  rs1:x31(0x7ffffffe), rs2:x21(0x7ffffffe), result rd:x11(0x00000000)
li x31, MASK_XLEN(0x7ffffffe)
li x21, MASK_XLEN(0x7ffffffe)
SLTU x11, x31, x21
sw x11, 260(x6)

# Testcase 66:  rs1:x3(0x7ffffffe), rs2:x27(0x7fffffff), result rd:x2(0x00000001)
li x3, MASK_XLEN(0x7ffffffe)
li x27, MASK_XLEN(0x7fffffff)
SLTU x2, x3, x27
sw x2, 264(x6)

# Testcase 67:  rs1:x12(0x7ffffffe), rs2:x22(0x80000000), result rd:x14(0x00000001)
li x12, MASK_XLEN(0x7ffffffe)
li x22, MASK_XLEN(0x80000000)
SLTU x14, x12, x22
sw x14, 268(x6)

# Testcase 68:  rs1:x5(0x7ffffffe), rs2:x29(0x80000001), result rd:x30(0x00000001)
li x5, MASK_XLEN(0x7ffffffe)
li x29, MASK_XLEN(0x80000001)
SLTU x30, x5, x29
sw x30, 272(x6)

# Testcase 69:  rs1:x7(0x7ffffffe), rs2:x15(0x9173ab42), result rd:x14(0x00000001)
li x7, MASK_XLEN(0x7ffffffe)
li x15, MASK_XLEN(0x9173ab42)
SLTU x14, x7, x15
sw x14, 276(x6)

# Testcase 70:  rs1:x5(0x7ffffffe), rs2:x12(0xfffffffe), result rd:x10(0x00000001)
li x5, MASK_XLEN(0x7ffffffe)
li x12, MASK_XLEN(0xfffffffe)
SLTU x10, x5, x12
sw x10, 280(x6)

# Testcase 71:  rs1:x24(0x7ffffffe), rs2:x26(0xffffffff), result rd:x24(0x00000001)
li x24, MASK_XLEN(0x7ffffffe)
li x26, MASK_XLEN(0xffffffff)
SLTU x24, x24, x26
sw x24, 284(x6)

# Testcase 72:  rs1:x14(0x7fffffff), rs2:x13(0x00000000), result rd:x1(0x00000000)
li x14, MASK_XLEN(0x7fffffff)
li x13, MASK_XLEN(0x00000000)
SLTU x1, x14, x13
sw x1, 288(x6)

# Testcase 73:  rs1:x14(0x7fffffff), rs2:x29(0x00000001), result rd:x9(0x00000000)
li x14, MASK_XLEN(0x7fffffff)
li x29, MASK_XLEN(0x00000001)
SLTU x9, x14, x29
sw x9, 292(x6)

# Testcase 74:  rs1:x24(0x7fffffff), rs2:x22(0x00000002), result rd:x23(0x00000000)
li x24, MASK_XLEN(0x7fffffff)
li x22, MASK_XLEN(0x00000002)
SLTU x23, x24, x22
sw x23, 296(x6)

# Testcase 75:  rs1:x15(0x7fffffff), rs2:x25(0x000000ff), result rd:x2(0x00000000)
li x15, MASK_XLEN(0x7fffffff)
li x25, MASK_XLEN(0x000000ff)
SLTU x2, x15, x25
sw x2, 300(x6)

# Testcase 76:  rs1:x19(0x7fffffff), rs2:x30(0x6c52dd14), result rd:x4(0x00000000)
li x19, MASK_XLEN(0x7fffffff)
li x30, MASK_XLEN(0x6c52dd14)
SLTU x4, x19, x30
sw x4, 304(x6)

# Testcase 77:  rs1:x14(0x7fffffff), rs2:x31(0x7ffffffe), result rd:x13(0x00000000)
li x14, MASK_XLEN(0x7fffffff)
li x31, MASK_XLEN(0x7ffffffe)
SLTU x13, x14, x31
sw x13, 308(x6)

# Testcase 78:  rs1:x5(0x7fffffff), rs2:x20(0x7fffffff), result rd:x28(0x00000000)
li x5, MASK_XLEN(0x7fffffff)
li x20, MASK_XLEN(0x7fffffff)
SLTU x28, x5, x20
sw x28, 312(x6)

# Testcase 79:  rs1:x22(0x7fffffff), rs2:x17(0x80000000), result rd:x27(0x00000001)
li x22, MASK_XLEN(0x7fffffff)
li x17, MASK_XLEN(0x80000000)
SLTU x27, x22, x17
sw x27, 316(x6)

# Testcase 80:  rs1:x24(0x7fffffff), rs2:x23(0x80000001), result rd:x5(0x00000001)
li x24, MASK_XLEN(0x7fffffff)
li x23, MASK_XLEN(0x80000001)
SLTU x5, x24, x23
sw x5, 320(x6)

# Testcase 81:  rs1:x3(0x7fffffff), rs2:x11(0x9173ab42), result rd:x8(0x00000001)
li x3, MASK_XLEN(0x7fffffff)
li x11, MASK_XLEN(0x9173ab42)
SLTU x8, x3, x11
sw x8, 324(x6)

# Testcase 82:  rs1:x1(0x7fffffff), rs2:x31(0xfffffffe), result rd:x26(0x00000001)
li x1, MASK_XLEN(0x7fffffff)
li x31, MASK_XLEN(0xfffffffe)
SLTU x26, x1, x31
sw x26, 328(x6)

# Testcase 83:  rs1:x26(0x7fffffff), rs2:x27(0xffffffff), result rd:x22(0x00000001)
li x26, MASK_XLEN(0x7fffffff)
li x27, MASK_XLEN(0xffffffff)
SLTU x22, x26, x27
sw x22, 332(x6)

# Testcase 84:  rs1:x3(0x80000000), rs2:x14(0x00000000), result rd:x30(0x00000000)
li x3, MASK_XLEN(0x80000000)
li x14, MASK_XLEN(0x00000000)
SLTU x30, x3, x14
sw x30, 336(x6)

# Testcase 85:  rs1:x28(0x80000000), rs2:x20(0x00000001), result rd:x4(0x00000000)
li x28, MASK_XLEN(0x80000000)
li x20, MASK_XLEN(0x00000001)
SLTU x4, x28, x20
sw x4, 340(x6)

# Testcase 86:  rs1:x20(0x80000000), rs2:x21(0x00000002), result rd:x15(0x00000000)
li x20, MASK_XLEN(0x80000000)
li x21, MASK_XLEN(0x00000002)
SLTU x15, x20, x21
sw x15, 344(x6)

# Testcase 87:  rs1:x23(0x80000000), rs2:x5(0x000000ff), result rd:x20(0x00000000)
li x23, MASK_XLEN(0x80000000)
li x5, MASK_XLEN(0x000000ff)
SLTU x20, x23, x5
sw x20, 348(x6)

# Testcase 88:  rs1:x20(0x80000000), rs2:x2(0x6c52dd14), result rd:x9(0x00000000)
li x20, MASK_XLEN(0x80000000)
li x2, MASK_XLEN(0x6c52dd14)
SLTU x9, x20, x2
sw x9, 352(x6)

# Testcase 89:  rs1:x11(0x80000000), rs2:x26(0x7ffffffe), result rd:x24(0x00000000)
li x11, MASK_XLEN(0x80000000)
li x26, MASK_XLEN(0x7ffffffe)
SLTU x24, x11, x26
sw x24, 356(x6)

# Testcase 90:  rs1:x24(0x80000000), rs2:x13(0x7fffffff), result rd:x1(0x00000000)
li x24, MASK_XLEN(0x80000000)
li x13, MASK_XLEN(0x7fffffff)
SLTU x1, x24, x13
sw x1, 360(x6)

# Testcase 91:  rs1:x21(0x80000000), rs2:x30(0x80000000), result rd:x29(0x00000000)
li x21, MASK_XLEN(0x80000000)
li x30, MASK_XLEN(0x80000000)
SLTU x29, x21, x30
sw x29, 364(x6)

# Testcase 92:  rs1:x2(0x80000000), rs2:x16(0x80000001), result rd:x3(0x00000001)
li x2, MASK_XLEN(0x80000000)
li x16, MASK_XLEN(0x80000001)
SLTU x3, x2, x16
sw x3, 368(x6)

# Testcase 93:  rs1:x12(0x80000000), rs2:x10(0x9173ab42), result rd:x22(0x00000001)
li x12, MASK_XLEN(0x80000000)
li x10, MASK_XLEN(0x9173ab42)
SLTU x22, x12, x10
sw x22, 372(x6)

# Testcase 94:  rs1:x5(0x80000000), rs2:x15(0xfffffffe), result rd:x8(0x00000001)
li x5, MASK_XLEN(0x80000000)
li x15, MASK_XLEN(0xfffffffe)
SLTU x8, x5, x15
sw x8, 376(x6)

# Testcase 95:  rs1:x24(0x80000000), rs2:x25(0xffffffff), result rd:x13(0x00000001)
li x24, MASK_XLEN(0x80000000)
li x25, MASK_XLEN(0xffffffff)
SLTU x13, x24, x25
sw x13, 380(x6)

# Testcase 96:  rs1:x11(0x80000001), rs2:x9(0x00000000), result rd:x26(0x00000000)
li x11, MASK_XLEN(0x80000001)
li x9, MASK_XLEN(0x00000000)
SLTU x26, x11, x9
sw x26, 384(x6)

# Testcase 97:  rs1:x16(0x80000001), rs2:x31(0x00000001), result rd:x13(0x00000000)
li x16, MASK_XLEN(0x80000001)
li x31, MASK_XLEN(0x00000001)
SLTU x13, x16, x31
sw x13, 388(x6)

# Testcase 98:  rs1:x1(0x80000001), rs2:x10(0x00000002), result rd:x17(0x00000000)
li x1, MASK_XLEN(0x80000001)
li x10, MASK_XLEN(0x00000002)
SLTU x17, x1, x10
sw x17, 392(x6)

# Testcase 99:  rs1:x29(0x80000001), rs2:x10(0x000000ff), result rd:x18(0x00000000)
li x29, MASK_XLEN(0x80000001)
li x10, MASK_XLEN(0x000000ff)
SLTU x18, x29, x10
sw x18, 396(x6)

# Testcase 100:  rs1:x16(0x80000001), rs2:x2(0x6c52dd14), result rd:x25(0x00000000)
li x16, MASK_XLEN(0x80000001)
li x2, MASK_XLEN(0x6c52dd14)
SLTU x25, x16, x2
sw x25, 400(x6)

# Testcase 101:  rs1:x18(0x80000001), rs2:x19(0x7ffffffe), result rd:x18(0x00000000)
li x18, MASK_XLEN(0x80000001)
li x19, MASK_XLEN(0x7ffffffe)
SLTU x18, x18, x19
sw x18, 404(x6)

# Testcase 102:  rs1:x9(0x80000001), rs2:x30(0x7fffffff), result rd:x22(0x00000000)
li x9, MASK_XLEN(0x80000001)
li x30, MASK_XLEN(0x7fffffff)
SLTU x22, x9, x30
sw x22, 408(x6)

# Testcase 103:  rs1:x2(0x80000001), rs2:x15(0x80000000), result rd:x13(0x00000000)
li x2, MASK_XLEN(0x80000001)
li x15, MASK_XLEN(0x80000000)
SLTU x13, x2, x15
sw x13, 412(x6)

# Testcase 104:  rs1:x24(0x80000001), rs2:x4(0x80000001), result rd:x13(0x00000000)
li x24, MASK_XLEN(0x80000001)
li x4, MASK_XLEN(0x80000001)
SLTU x13, x24, x4
sw x13, 416(x6)

# Testcase 105:  rs1:x12(0x80000001), rs2:x16(0x9173ab42), result rd:x2(0x00000001)
li x12, MASK_XLEN(0x80000001)
li x16, MASK_XLEN(0x9173ab42)
SLTU x2, x12, x16
sw x2, 420(x6)

# Testcase 106:  rs1:x1(0x80000001), rs2:x9(0xfffffffe), result rd:x24(0x00000001)
li x1, MASK_XLEN(0x80000001)
li x9, MASK_XLEN(0xfffffffe)
SLTU x24, x1, x9
sw x24, 424(x6)

# Testcase 107:  rs1:x2(0x80000001), rs2:x9(0xffffffff), result rd:x22(0x00000001)
li x2, MASK_XLEN(0x80000001)
li x9, MASK_XLEN(0xffffffff)
SLTU x22, x2, x9
sw x22, 428(x6)

# Testcase 108:  rs1:x22(0x9173ab42), rs2:x19(0x00000000), result rd:x23(0x00000000)
li x22, MASK_XLEN(0x9173ab42)
li x19, MASK_XLEN(0x00000000)
SLTU x23, x22, x19
sw x23, 432(x6)

# Testcase 109:  rs1:x25(0x9173ab42), rs2:x30(0x00000001), result rd:x10(0x00000000)
li x25, MASK_XLEN(0x9173ab42)
li x30, MASK_XLEN(0x00000001)
SLTU x10, x25, x30
sw x10, 436(x6)

# Testcase 110:  rs1:x22(0x9173ab42), rs2:x25(0x00000002), result rd:x7(0x00000000)
li x22, MASK_XLEN(0x9173ab42)
li x25, MASK_XLEN(0x00000002)
SLTU x7, x22, x25
sw x7, 440(x6)

# Testcase 111:  rs1:x25(0x9173ab42), rs2:x17(0x000000ff), result rd:x17(0x00000000)
li x25, MASK_XLEN(0x9173ab42)
li x17, MASK_XLEN(0x000000ff)
SLTU x17, x25, x17
sw x17, 444(x6)

# Testcase 112:  rs1:x11(0x9173ab42), rs2:x13(0x6c52dd14), result rd:x27(0x00000000)
li x11, MASK_XLEN(0x9173ab42)
li x13, MASK_XLEN(0x6c52dd14)
SLTU x27, x11, x13
sw x27, 448(x6)

# Testcase 113:  rs1:x9(0x9173ab42), rs2:x7(0x7ffffffe), result rd:x4(0x00000000)
li x9, MASK_XLEN(0x9173ab42)
li x7, MASK_XLEN(0x7ffffffe)
SLTU x4, x9, x7
sw x4, 452(x6)

# Testcase 114:  rs1:x19(0x9173ab42), rs2:x11(0x7fffffff), result rd:x26(0x00000000)
li x19, MASK_XLEN(0x9173ab42)
li x11, MASK_XLEN(0x7fffffff)
SLTU x26, x19, x11
sw x26, 456(x6)

# Testcase 115:  rs1:x8(0x9173ab42), rs2:x19(0x80000000), result rd:x22(0x00000000)
li x8, MASK_XLEN(0x9173ab42)
li x19, MASK_XLEN(0x80000000)
SLTU x22, x8, x19
sw x22, 460(x6)

# Testcase 116:  rs1:x24(0x9173ab42), rs2:x18(0x80000001), result rd:x22(0x00000000)
li x24, MASK_XLEN(0x9173ab42)
li x18, MASK_XLEN(0x80000001)
SLTU x22, x24, x18
sw x22, 464(x6)

# Testcase 117:  rs1:x30(0x9173ab42), rs2:x28(0x9173ab42), result rd:x29(0x00000000)
li x30, MASK_XLEN(0x9173ab42)
li x28, MASK_XLEN(0x9173ab42)
SLTU x29, x30, x28
sw x29, 468(x6)

# Testcase 118:  rs1:x5(0x9173ab42), rs2:x11(0xfffffffe), result rd:x28(0x00000001)
li x5, MASK_XLEN(0x9173ab42)
li x11, MASK_XLEN(0xfffffffe)
SLTU x28, x5, x11
sw x28, 472(x6)

# Testcase 119:  rs1:x24(0x9173ab42), rs2:x27(0xffffffff), result rd:x1(0x00000001)
li x24, MASK_XLEN(0x9173ab42)
li x27, MASK_XLEN(0xffffffff)
SLTU x1, x24, x27
sw x1, 476(x6)

# Testcase 120:  rs1:x19(0xfffffffe), rs2:x27(0x00000000), result rd:x2(0x00000000)
li x19, MASK_XLEN(0xfffffffe)
li x27, MASK_XLEN(0x00000000)
SLTU x2, x19, x27
sw x2, 480(x6)

# Testcase 121:  rs1:x19(0xfffffffe), rs2:x5(0x00000001), result rd:x31(0x00000000)
li x19, MASK_XLEN(0xfffffffe)
li x5, MASK_XLEN(0x00000001)
SLTU x31, x19, x5
sw x31, 484(x6)

# Testcase 122:  rs1:x21(0xfffffffe), rs2:x10(0x00000002), result rd:x11(0x00000000)
li x21, MASK_XLEN(0xfffffffe)
li x10, MASK_XLEN(0x00000002)
SLTU x11, x21, x10
sw x11, 488(x6)

# Testcase 123:  rs1:x16(0xfffffffe), rs2:x26(0x000000ff), result rd:x13(0x00000000)
li x16, MASK_XLEN(0xfffffffe)
li x26, MASK_XLEN(0x000000ff)
SLTU x13, x16, x26
sw x13, 492(x6)

# Testcase 124:  rs1:x1(0xfffffffe), rs2:x26(0x6c52dd14), result rd:x5(0x00000000)
li x1, MASK_XLEN(0xfffffffe)
li x26, MASK_XLEN(0x6c52dd14)
SLTU x5, x1, x26
sw x5, 496(x6)

# Testcase 125:  rs1:x19(0xfffffffe), rs2:x2(0x7ffffffe), result rd:x15(0x00000000)
li x19, MASK_XLEN(0xfffffffe)
li x2, MASK_XLEN(0x7ffffffe)
SLTU x15, x19, x2
sw x15, 500(x6)

# Testcase 126:  rs1:x5(0xfffffffe), rs2:x11(0x7fffffff), result rd:x30(0x00000000)
li x5, MASK_XLEN(0xfffffffe)
li x11, MASK_XLEN(0x7fffffff)
SLTU x30, x5, x11
sw x30, 504(x6)

# Testcase 127:  rs1:x1(0xfffffffe), rs2:x31(0x80000000), result rd:x24(0x00000000)
li x1, MASK_XLEN(0xfffffffe)
li x31, MASK_XLEN(0x80000000)
SLTU x24, x1, x31
sw x24, 508(x6)

# Testcase 128:  rs1:x16(0xfffffffe), rs2:x30(0x80000001), result rd:x31(0x00000000)
li x16, MASK_XLEN(0xfffffffe)
li x30, MASK_XLEN(0x80000001)
SLTU x31, x16, x30
sw x31, 512(x6)

# Testcase 129:  rs1:x22(0xfffffffe), rs2:x27(0x9173ab42), result rd:x22(0x00000000)
li x22, MASK_XLEN(0xfffffffe)
li x27, MASK_XLEN(0x9173ab42)
SLTU x22, x22, x27
sw x22, 516(x6)

# Testcase 130:  rs1:x25(0xfffffffe), rs2:x9(0xfffffffe), result rd:x24(0x00000000)
li x25, MASK_XLEN(0xfffffffe)
li x9, MASK_XLEN(0xfffffffe)
SLTU x24, x25, x9
sw x24, 520(x6)

# Testcase 131:  rs1:x20(0xfffffffe), rs2:x7(0xffffffff), result rd:x3(0x00000001)
li x20, MASK_XLEN(0xfffffffe)
li x7, MASK_XLEN(0xffffffff)
SLTU x3, x20, x7
sw x3, 524(x6)

# Testcase 132:  rs1:x18(0xffffffff), rs2:x30(0x00000000), result rd:x14(0x00000000)
li x18, MASK_XLEN(0xffffffff)
li x30, MASK_XLEN(0x00000000)
SLTU x14, x18, x30
sw x14, 528(x6)

# Testcase 133:  rs1:x9(0xffffffff), rs2:x31(0x00000001), result rd:x27(0x00000000)
li x9, MASK_XLEN(0xffffffff)
li x31, MASK_XLEN(0x00000001)
SLTU x27, x9, x31
sw x27, 532(x6)

# Testcase 134:  rs1:x3(0xffffffff), rs2:x22(0x00000002), result rd:x21(0x00000000)
li x3, MASK_XLEN(0xffffffff)
li x22, MASK_XLEN(0x00000002)
SLTU x21, x3, x22
sw x21, 536(x6)

# Testcase 135:  rs1:x31(0xffffffff), rs2:x17(0x000000ff), result rd:x21(0x00000000)
li x31, MASK_XLEN(0xffffffff)
li x17, MASK_XLEN(0x000000ff)
SLTU x21, x31, x17
sw x21, 540(x6)

# Testcase 136:  rs1:x26(0xffffffff), rs2:x18(0x6c52dd14), result rd:x20(0x00000000)
li x26, MASK_XLEN(0xffffffff)
li x18, MASK_XLEN(0x6c52dd14)
SLTU x20, x26, x18
sw x20, 544(x6)

# Testcase 137:  rs1:x13(0xffffffff), rs2:x25(0x7ffffffe), result rd:x14(0x00000000)
li x13, MASK_XLEN(0xffffffff)
li x25, MASK_XLEN(0x7ffffffe)
SLTU x14, x13, x25
sw x14, 548(x6)

# Testcase 138:  rs1:x9(0xffffffff), rs2:x10(0x7fffffff), result rd:x10(0x00000000)
li x9, MASK_XLEN(0xffffffff)
li x10, MASK_XLEN(0x7fffffff)
SLTU x10, x9, x10
sw x10, 552(x6)

# Testcase 139:  rs1:x1(0xffffffff), rs2:x14(0x80000000), result rd:x25(0x00000000)
li x1, MASK_XLEN(0xffffffff)
li x14, MASK_XLEN(0x80000000)
SLTU x25, x1, x14
sw x25, 556(x6)

# Testcase 140:  rs1:x27(0xffffffff), rs2:x23(0x80000001), result rd:x9(0x00000000)
li x27, MASK_XLEN(0xffffffff)
li x23, MASK_XLEN(0x80000001)
SLTU x9, x27, x23
sw x9, 560(x6)

# Testcase 141:  rs1:x31(0xffffffff), rs2:x9(0x9173ab42), result rd:x18(0x00000000)
li x31, MASK_XLEN(0xffffffff)
li x9, MASK_XLEN(0x9173ab42)
SLTU x18, x31, x9
sw x18, 564(x6)

# Testcase 142:  rs1:x17(0xffffffff), rs2:x18(0xfffffffe), result rd:x11(0x00000000)
li x17, MASK_XLEN(0xffffffff)
li x18, MASK_XLEN(0xfffffffe)
SLTU x11, x17, x18
sw x11, 568(x6)

# Testcase 143:  rs1:x11(0xffffffff), rs2:x7(0xffffffff), result rd:x23(0x00000000)
li x11, MASK_XLEN(0xffffffff)
li x7, MASK_XLEN(0xffffffff)
SLTU x23, x11, x7
sw x23, 572(x6)

# Testcase 144:  rs1:x26(0xc857d8c3), rs2:x5(0x6e83a7b2), result rd:x28(0x00000000)
li x26, MASK_XLEN(0xc857d8c3)
li x5, MASK_XLEN(0x6e83a7b2)
SLTU x28, x26, x5
sw x28, 576(x6)

# Testcase 145:  rs1:x17(0x01847803), rs2:x5(0xc0037457), result rd:x26(0x00000001)
li x17, MASK_XLEN(0x01847803)
li x5, MASK_XLEN(0xc0037457)
SLTU x26, x17, x5
sw x26, 580(x6)

# Testcase 146:  rs1:x30(0xa93fa902), rs2:x26(0xb38e5adb), result rd:x19(0x00000001)
li x30, MASK_XLEN(0xa93fa902)
li x26, MASK_XLEN(0xb38e5adb)
SLTU x19, x30, x26
sw x19, 584(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry

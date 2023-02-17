///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.466447//
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

# Testcase 0:  rs1:x1(0x00000000), rs2:x30(0x00000000), result rd:x20(0x00000000)
li x1, MASK_XLEN(0x00000000)
li x30, MASK_XLEN(0x00000000)
SLT x20, x1, x30
sw x20, 0(x6)

# Testcase 1:  rs1:x8(0x00000000), rs2:x28(0x00000001), result rd:x5(0x00000001)
li x8, MASK_XLEN(0x00000000)
li x28, MASK_XLEN(0x00000001)
SLT x5, x8, x28
sw x5, 4(x6)

# Testcase 2:  rs1:x16(0x00000000), rs2:x12(0x00000002), result rd:x23(0x00000001)
li x16, MASK_XLEN(0x00000000)
li x12, MASK_XLEN(0x00000002)
SLT x23, x16, x12
sw x23, 8(x6)

# Testcase 3:  rs1:x31(0x00000000), rs2:x9(0x000000ff), result rd:x5(0x00000001)
li x31, MASK_XLEN(0x00000000)
li x9, MASK_XLEN(0x000000ff)
SLT x5, x31, x9
sw x5, 12(x6)

# Testcase 4:  rs1:x1(0x00000000), rs2:x31(0x6c52dd14), result rd:x7(0x00000001)
li x1, MASK_XLEN(0x00000000)
li x31, MASK_XLEN(0x6c52dd14)
SLT x7, x1, x31
sw x7, 16(x6)

# Testcase 5:  rs1:x12(0x00000000), rs2:x11(0x7ffffffe), result rd:x16(0x00000001)
li x12, MASK_XLEN(0x00000000)
li x11, MASK_XLEN(0x7ffffffe)
SLT x16, x12, x11
sw x16, 20(x6)

# Testcase 6:  rs1:x31(0x00000000), rs2:x10(0x7fffffff), result rd:x10(0x00000001)
li x31, MASK_XLEN(0x00000000)
li x10, MASK_XLEN(0x7fffffff)
SLT x10, x31, x10
sw x10, 24(x6)

# Testcase 7:  rs1:x30(0x00000000), rs2:x29(0x80000000), result rd:x31(0x00000000)
li x30, MASK_XLEN(0x00000000)
li x29, MASK_XLEN(0x80000000)
SLT x31, x30, x29
sw x31, 28(x6)

# Testcase 8:  rs1:x18(0x00000000), rs2:x21(0x80000001), result rd:x11(0x00000000)
li x18, MASK_XLEN(0x00000000)
li x21, MASK_XLEN(0x80000001)
SLT x11, x18, x21
sw x11, 32(x6)

# Testcase 9:  rs1:x4(0x00000000), rs2:x18(0x9173ab42), result rd:x19(0x00000000)
li x4, MASK_XLEN(0x00000000)
li x18, MASK_XLEN(0x9173ab42)
SLT x19, x4, x18
sw x19, 36(x6)

# Testcase 10:  rs1:x29(0x00000000), rs2:x5(0xfffffffe), result rd:x31(0x00000000)
li x29, MASK_XLEN(0x00000000)
li x5, MASK_XLEN(0xfffffffe)
SLT x31, x29, x5
sw x31, 40(x6)

# Testcase 11:  rs1:x5(0x00000000), rs2:x26(0xffffffff), result rd:x8(0x00000000)
li x5, MASK_XLEN(0x00000000)
li x26, MASK_XLEN(0xffffffff)
SLT x8, x5, x26
sw x8, 44(x6)

# Testcase 12:  rs1:x11(0x00000001), rs2:x17(0x00000000), result rd:x8(0x00000000)
li x11, MASK_XLEN(0x00000001)
li x17, MASK_XLEN(0x00000000)
SLT x8, x11, x17
sw x8, 48(x6)

# Testcase 13:  rs1:x10(0x00000001), rs2:x12(0x00000001), result rd:x14(0x00000000)
li x10, MASK_XLEN(0x00000001)
li x12, MASK_XLEN(0x00000001)
SLT x14, x10, x12
sw x14, 52(x6)

# Testcase 14:  rs1:x22(0x00000001), rs2:x2(0x00000002), result rd:x28(0x00000001)
li x22, MASK_XLEN(0x00000001)
li x2, MASK_XLEN(0x00000002)
SLT x28, x22, x2
sw x28, 56(x6)

# Testcase 15:  rs1:x5(0x00000001), rs2:x20(0x000000ff), result rd:x1(0x00000001)
li x5, MASK_XLEN(0x00000001)
li x20, MASK_XLEN(0x000000ff)
SLT x1, x5, x20
sw x1, 60(x6)

# Testcase 16:  rs1:x13(0x00000001), rs2:x3(0x6c52dd14), result rd:x23(0x00000001)
li x13, MASK_XLEN(0x00000001)
li x3, MASK_XLEN(0x6c52dd14)
SLT x23, x13, x3
sw x23, 64(x6)

# Testcase 17:  rs1:x3(0x00000001), rs2:x5(0x7ffffffe), result rd:x14(0x00000001)
li x3, MASK_XLEN(0x00000001)
li x5, MASK_XLEN(0x7ffffffe)
SLT x14, x3, x5
sw x14, 68(x6)

# Testcase 18:  rs1:x10(0x00000001), rs2:x18(0x7fffffff), result rd:x14(0x00000001)
li x10, MASK_XLEN(0x00000001)
li x18, MASK_XLEN(0x7fffffff)
SLT x14, x10, x18
sw x14, 72(x6)

# Testcase 19:  rs1:x24(0x00000001), rs2:x30(0x80000000), result rd:x5(0x00000000)
li x24, MASK_XLEN(0x00000001)
li x30, MASK_XLEN(0x80000000)
SLT x5, x24, x30
sw x5, 76(x6)

# Testcase 20:  rs1:x19(0x00000001), rs2:x14(0x80000001), result rd:x10(0x00000000)
li x19, MASK_XLEN(0x00000001)
li x14, MASK_XLEN(0x80000001)
SLT x10, x19, x14
sw x10, 80(x6)

# Testcase 21:  rs1:x21(0x00000001), rs2:x12(0x9173ab42), result rd:x3(0x00000000)
li x21, MASK_XLEN(0x00000001)
li x12, MASK_XLEN(0x9173ab42)
SLT x3, x21, x12
sw x3, 84(x6)

# Testcase 22:  rs1:x8(0x00000001), rs2:x15(0xfffffffe), result rd:x21(0x00000000)
li x8, MASK_XLEN(0x00000001)
li x15, MASK_XLEN(0xfffffffe)
SLT x21, x8, x15
sw x21, 88(x6)

# Testcase 23:  rs1:x12(0x00000001), rs2:x21(0xffffffff), result rd:x31(0x00000000)
li x12, MASK_XLEN(0x00000001)
li x21, MASK_XLEN(0xffffffff)
SLT x31, x12, x21
sw x31, 92(x6)

# Testcase 24:  rs1:x17(0x00000002), rs2:x2(0x00000000), result rd:x13(0x00000000)
li x17, MASK_XLEN(0x00000002)
li x2, MASK_XLEN(0x00000000)
SLT x13, x17, x2
sw x13, 96(x6)

# Testcase 25:  rs1:x14(0x00000002), rs2:x1(0x00000001), result rd:x14(0x00000000)
li x14, MASK_XLEN(0x00000002)
li x1, MASK_XLEN(0x00000001)
SLT x14, x14, x1
sw x14, 100(x6)

# Testcase 26:  rs1:x31(0x00000002), rs2:x24(0x00000002), result rd:x29(0x00000000)
li x31, MASK_XLEN(0x00000002)
li x24, MASK_XLEN(0x00000002)
SLT x29, x31, x24
sw x29, 104(x6)

# Testcase 27:  rs1:x11(0x00000002), rs2:x15(0x000000ff), result rd:x7(0x00000001)
li x11, MASK_XLEN(0x00000002)
li x15, MASK_XLEN(0x000000ff)
SLT x7, x11, x15
sw x7, 108(x6)

# Testcase 28:  rs1:x12(0x00000002), rs2:x10(0x6c52dd14), result rd:x31(0x00000001)
li x12, MASK_XLEN(0x00000002)
li x10, MASK_XLEN(0x6c52dd14)
SLT x31, x12, x10
sw x31, 112(x6)

# Testcase 29:  rs1:x16(0x00000002), rs2:x3(0x7ffffffe), result rd:x31(0x00000001)
li x16, MASK_XLEN(0x00000002)
li x3, MASK_XLEN(0x7ffffffe)
SLT x31, x16, x3
sw x31, 116(x6)

# Testcase 30:  rs1:x9(0x00000002), rs2:x4(0x7fffffff), result rd:x18(0x00000001)
li x9, MASK_XLEN(0x00000002)
li x4, MASK_XLEN(0x7fffffff)
SLT x18, x9, x4
sw x18, 120(x6)

# Testcase 31:  rs1:x20(0x00000002), rs2:x23(0x80000000), result rd:x5(0x00000000)
li x20, MASK_XLEN(0x00000002)
li x23, MASK_XLEN(0x80000000)
SLT x5, x20, x23
sw x5, 124(x6)

# Testcase 32:  rs1:x26(0x00000002), rs2:x23(0x80000001), result rd:x15(0x00000000)
li x26, MASK_XLEN(0x00000002)
li x23, MASK_XLEN(0x80000001)
SLT x15, x26, x23
sw x15, 128(x6)

# Testcase 33:  rs1:x25(0x00000002), rs2:x14(0x9173ab42), result rd:x14(0x00000000)
li x25, MASK_XLEN(0x00000002)
li x14, MASK_XLEN(0x9173ab42)
SLT x14, x25, x14
sw x14, 132(x6)

# Testcase 34:  rs1:x15(0x00000002), rs2:x11(0xfffffffe), result rd:x30(0x00000000)
li x15, MASK_XLEN(0x00000002)
li x11, MASK_XLEN(0xfffffffe)
SLT x30, x15, x11
sw x30, 136(x6)

# Testcase 35:  rs1:x17(0x00000002), rs2:x5(0xffffffff), result rd:x12(0x00000000)
li x17, MASK_XLEN(0x00000002)
li x5, MASK_XLEN(0xffffffff)
SLT x12, x17, x5
sw x12, 140(x6)

# Testcase 36:  rs1:x15(0x000000ff), rs2:x21(0x00000000), result rd:x21(0x00000000)
li x15, MASK_XLEN(0x000000ff)
li x21, MASK_XLEN(0x00000000)
SLT x21, x15, x21
sw x21, 144(x6)

# Testcase 37:  rs1:x3(0x000000ff), rs2:x16(0x00000001), result rd:x25(0x00000000)
li x3, MASK_XLEN(0x000000ff)
li x16, MASK_XLEN(0x00000001)
SLT x25, x3, x16
sw x25, 148(x6)

# Testcase 38:  rs1:x7(0x000000ff), rs2:x10(0x00000002), result rd:x1(0x00000000)
li x7, MASK_XLEN(0x000000ff)
li x10, MASK_XLEN(0x00000002)
SLT x1, x7, x10
sw x1, 152(x6)

# Testcase 39:  rs1:x27(0x000000ff), rs2:x23(0x000000ff), result rd:x15(0x00000000)
li x27, MASK_XLEN(0x000000ff)
li x23, MASK_XLEN(0x000000ff)
SLT x15, x27, x23
sw x15, 156(x6)

# Testcase 40:  rs1:x20(0x000000ff), rs2:x15(0x6c52dd14), result rd:x1(0x00000001)
li x20, MASK_XLEN(0x000000ff)
li x15, MASK_XLEN(0x6c52dd14)
SLT x1, x20, x15
sw x1, 160(x6)

# Testcase 41:  rs1:x7(0x000000ff), rs2:x10(0x7ffffffe), result rd:x4(0x00000001)
li x7, MASK_XLEN(0x000000ff)
li x10, MASK_XLEN(0x7ffffffe)
SLT x4, x7, x10
sw x4, 164(x6)

# Testcase 42:  rs1:x25(0x000000ff), rs2:x21(0x7fffffff), result rd:x10(0x00000001)
li x25, MASK_XLEN(0x000000ff)
li x21, MASK_XLEN(0x7fffffff)
SLT x10, x25, x21
sw x10, 168(x6)

# Testcase 43:  rs1:x18(0x000000ff), rs2:x20(0x80000000), result rd:x5(0x00000000)
li x18, MASK_XLEN(0x000000ff)
li x20, MASK_XLEN(0x80000000)
SLT x5, x18, x20
sw x5, 172(x6)

# Testcase 44:  rs1:x14(0x000000ff), rs2:x23(0x80000001), result rd:x25(0x00000000)
li x14, MASK_XLEN(0x000000ff)
li x23, MASK_XLEN(0x80000001)
SLT x25, x14, x23
sw x25, 176(x6)

# Testcase 45:  rs1:x16(0x000000ff), rs2:x3(0x9173ab42), result rd:x22(0x00000000)
li x16, MASK_XLEN(0x000000ff)
li x3, MASK_XLEN(0x9173ab42)
SLT x22, x16, x3
sw x22, 180(x6)

# Testcase 46:  rs1:x16(0x000000ff), rs2:x25(0xfffffffe), result rd:x31(0x00000000)
li x16, MASK_XLEN(0x000000ff)
li x25, MASK_XLEN(0xfffffffe)
SLT x31, x16, x25
sw x31, 184(x6)

# Testcase 47:  rs1:x8(0x000000ff), rs2:x18(0xffffffff), result rd:x25(0x00000000)
li x8, MASK_XLEN(0x000000ff)
li x18, MASK_XLEN(0xffffffff)
SLT x25, x8, x18
sw x25, 188(x6)

# Testcase 48:  rs1:x13(0x6c52dd14), rs2:x9(0x00000000), result rd:x21(0x00000000)
li x13, MASK_XLEN(0x6c52dd14)
li x9, MASK_XLEN(0x00000000)
SLT x21, x13, x9
sw x21, 192(x6)

# Testcase 49:  rs1:x1(0x6c52dd14), rs2:x4(0x00000001), result rd:x9(0x00000000)
li x1, MASK_XLEN(0x6c52dd14)
li x4, MASK_XLEN(0x00000001)
SLT x9, x1, x4
sw x9, 196(x6)

# Testcase 50:  rs1:x29(0x6c52dd14), rs2:x22(0x00000002), result rd:x2(0x00000000)
li x29, MASK_XLEN(0x6c52dd14)
li x22, MASK_XLEN(0x00000002)
SLT x2, x29, x22
sw x2, 200(x6)

# Testcase 51:  rs1:x1(0x6c52dd14), rs2:x9(0x000000ff), result rd:x13(0x00000000)
li x1, MASK_XLEN(0x6c52dd14)
li x9, MASK_XLEN(0x000000ff)
SLT x13, x1, x9
sw x13, 204(x6)

# Testcase 52:  rs1:x17(0x6c52dd14), rs2:x29(0x6c52dd14), result rd:x19(0x00000000)
li x17, MASK_XLEN(0x6c52dd14)
li x29, MASK_XLEN(0x6c52dd14)
SLT x19, x17, x29
sw x19, 208(x6)

# Testcase 53:  rs1:x23(0x6c52dd14), rs2:x13(0x7ffffffe), result rd:x15(0x00000001)
li x23, MASK_XLEN(0x6c52dd14)
li x13, MASK_XLEN(0x7ffffffe)
SLT x15, x23, x13
sw x15, 212(x6)

# Testcase 54:  rs1:x4(0x6c52dd14), rs2:x24(0x7fffffff), result rd:x9(0x00000001)
li x4, MASK_XLEN(0x6c52dd14)
li x24, MASK_XLEN(0x7fffffff)
SLT x9, x4, x24
sw x9, 216(x6)

# Testcase 55:  rs1:x12(0x6c52dd14), rs2:x10(0x80000000), result rd:x28(0x00000000)
li x12, MASK_XLEN(0x6c52dd14)
li x10, MASK_XLEN(0x80000000)
SLT x28, x12, x10
sw x28, 220(x6)

# Testcase 56:  rs1:x25(0x6c52dd14), rs2:x22(0x80000001), result rd:x30(0x00000000)
li x25, MASK_XLEN(0x6c52dd14)
li x22, MASK_XLEN(0x80000001)
SLT x30, x25, x22
sw x30, 224(x6)

# Testcase 57:  rs1:x7(0x6c52dd14), rs2:x20(0x9173ab42), result rd:x3(0x00000000)
li x7, MASK_XLEN(0x6c52dd14)
li x20, MASK_XLEN(0x9173ab42)
SLT x3, x7, x20
sw x3, 228(x6)

# Testcase 58:  rs1:x2(0x6c52dd14), rs2:x3(0xfffffffe), result rd:x26(0x00000000)
li x2, MASK_XLEN(0x6c52dd14)
li x3, MASK_XLEN(0xfffffffe)
SLT x26, x2, x3
sw x26, 232(x6)

# Testcase 59:  rs1:x9(0x6c52dd14), rs2:x10(0xffffffff), result rd:x18(0x00000000)
li x9, MASK_XLEN(0x6c52dd14)
li x10, MASK_XLEN(0xffffffff)
SLT x18, x9, x10
sw x18, 236(x6)

# Testcase 60:  rs1:x11(0x7ffffffe), rs2:x4(0x00000000), result rd:x17(0x00000000)
li x11, MASK_XLEN(0x7ffffffe)
li x4, MASK_XLEN(0x00000000)
SLT x17, x11, x4
sw x17, 240(x6)

# Testcase 61:  rs1:x28(0x7ffffffe), rs2:x8(0x00000001), result rd:x29(0x00000000)
li x28, MASK_XLEN(0x7ffffffe)
li x8, MASK_XLEN(0x00000001)
SLT x29, x28, x8
sw x29, 244(x6)

# Testcase 62:  rs1:x3(0x7ffffffe), rs2:x14(0x00000002), result rd:x28(0x00000000)
li x3, MASK_XLEN(0x7ffffffe)
li x14, MASK_XLEN(0x00000002)
SLT x28, x3, x14
sw x28, 248(x6)

# Testcase 63:  rs1:x5(0x7ffffffe), rs2:x19(0x000000ff), result rd:x17(0x00000000)
li x5, MASK_XLEN(0x7ffffffe)
li x19, MASK_XLEN(0x000000ff)
SLT x17, x5, x19
sw x17, 252(x6)

# Testcase 64:  rs1:x21(0x7ffffffe), rs2:x7(0x6c52dd14), result rd:x18(0x00000000)
li x21, MASK_XLEN(0x7ffffffe)
li x7, MASK_XLEN(0x6c52dd14)
SLT x18, x21, x7
sw x18, 256(x6)

# Testcase 65:  rs1:x4(0x7ffffffe), rs2:x14(0x7ffffffe), result rd:x31(0x00000000)
li x4, MASK_XLEN(0x7ffffffe)
li x14, MASK_XLEN(0x7ffffffe)
SLT x31, x4, x14
sw x31, 260(x6)

# Testcase 66:  rs1:x21(0x7ffffffe), rs2:x18(0x7fffffff), result rd:x13(0x00000001)
li x21, MASK_XLEN(0x7ffffffe)
li x18, MASK_XLEN(0x7fffffff)
SLT x13, x21, x18
sw x13, 264(x6)

# Testcase 67:  rs1:x24(0x7ffffffe), rs2:x25(0x80000000), result rd:x29(0x00000000)
li x24, MASK_XLEN(0x7ffffffe)
li x25, MASK_XLEN(0x80000000)
SLT x29, x24, x25
sw x29, 268(x6)

# Testcase 68:  rs1:x26(0x7ffffffe), rs2:x9(0x80000001), result rd:x10(0x00000000)
li x26, MASK_XLEN(0x7ffffffe)
li x9, MASK_XLEN(0x80000001)
SLT x10, x26, x9
sw x10, 272(x6)

# Testcase 69:  rs1:x15(0x7ffffffe), rs2:x12(0x9173ab42), result rd:x19(0x00000000)
li x15, MASK_XLEN(0x7ffffffe)
li x12, MASK_XLEN(0x9173ab42)
SLT x19, x15, x12
sw x19, 276(x6)

# Testcase 70:  rs1:x4(0x7ffffffe), rs2:x23(0xfffffffe), result rd:x4(0x00000000)
li x4, MASK_XLEN(0x7ffffffe)
li x23, MASK_XLEN(0xfffffffe)
SLT x4, x4, x23
sw x4, 280(x6)

# Testcase 71:  rs1:x15(0x7ffffffe), rs2:x5(0xffffffff), result rd:x18(0x00000000)
li x15, MASK_XLEN(0x7ffffffe)
li x5, MASK_XLEN(0xffffffff)
SLT x18, x15, x5
sw x18, 284(x6)

# Testcase 72:  rs1:x22(0x7fffffff), rs2:x10(0x00000000), result rd:x12(0x00000000)
li x22, MASK_XLEN(0x7fffffff)
li x10, MASK_XLEN(0x00000000)
SLT x12, x22, x10
sw x12, 288(x6)

# Testcase 73:  rs1:x21(0x7fffffff), rs2:x16(0x00000001), result rd:x24(0x00000000)
li x21, MASK_XLEN(0x7fffffff)
li x16, MASK_XLEN(0x00000001)
SLT x24, x21, x16
sw x24, 292(x6)

# Testcase 74:  rs1:x14(0x7fffffff), rs2:x7(0x00000002), result rd:x16(0x00000000)
li x14, MASK_XLEN(0x7fffffff)
li x7, MASK_XLEN(0x00000002)
SLT x16, x14, x7
sw x16, 296(x6)

# Testcase 75:  rs1:x16(0x7fffffff), rs2:x23(0x000000ff), result rd:x17(0x00000000)
li x16, MASK_XLEN(0x7fffffff)
li x23, MASK_XLEN(0x000000ff)
SLT x17, x16, x23
sw x17, 300(x6)

# Testcase 76:  rs1:x11(0x7fffffff), rs2:x16(0x6c52dd14), result rd:x21(0x00000000)
li x11, MASK_XLEN(0x7fffffff)
li x16, MASK_XLEN(0x6c52dd14)
SLT x21, x11, x16
sw x21, 304(x6)

# Testcase 77:  rs1:x31(0x7fffffff), rs2:x2(0x7ffffffe), result rd:x15(0x00000000)
li x31, MASK_XLEN(0x7fffffff)
li x2, MASK_XLEN(0x7ffffffe)
SLT x15, x31, x2
sw x15, 308(x6)

# Testcase 78:  rs1:x10(0x7fffffff), rs2:x5(0x7fffffff), result rd:x24(0x00000000)
li x10, MASK_XLEN(0x7fffffff)
li x5, MASK_XLEN(0x7fffffff)
SLT x24, x10, x5
sw x24, 312(x6)

# Testcase 79:  rs1:x16(0x7fffffff), rs2:x2(0x80000000), result rd:x29(0x00000000)
li x16, MASK_XLEN(0x7fffffff)
li x2, MASK_XLEN(0x80000000)
SLT x29, x16, x2
sw x29, 316(x6)

# Testcase 80:  rs1:x20(0x7fffffff), rs2:x7(0x80000001), result rd:x1(0x00000000)
li x20, MASK_XLEN(0x7fffffff)
li x7, MASK_XLEN(0x80000001)
SLT x1, x20, x7
sw x1, 320(x6)

# Testcase 81:  rs1:x12(0x7fffffff), rs2:x16(0x9173ab42), result rd:x13(0x00000000)
li x12, MASK_XLEN(0x7fffffff)
li x16, MASK_XLEN(0x9173ab42)
SLT x13, x12, x16
sw x13, 324(x6)

# Testcase 82:  rs1:x29(0x7fffffff), rs2:x1(0xfffffffe), result rd:x28(0x00000000)
li x29, MASK_XLEN(0x7fffffff)
li x1, MASK_XLEN(0xfffffffe)
SLT x28, x29, x1
sw x28, 328(x6)

# Testcase 83:  rs1:x17(0x7fffffff), rs2:x3(0xffffffff), result rd:x22(0x00000000)
li x17, MASK_XLEN(0x7fffffff)
li x3, MASK_XLEN(0xffffffff)
SLT x22, x17, x3
sw x22, 332(x6)

# Testcase 84:  rs1:x28(0x80000000), rs2:x3(0x00000000), result rd:x22(0x00000001)
li x28, MASK_XLEN(0x80000000)
li x3, MASK_XLEN(0x00000000)
SLT x22, x28, x3
sw x22, 336(x6)

# Testcase 85:  rs1:x31(0x80000000), rs2:x24(0x00000001), result rd:x30(0x00000001)
li x31, MASK_XLEN(0x80000000)
li x24, MASK_XLEN(0x00000001)
SLT x30, x31, x24
sw x30, 340(x6)

# Testcase 86:  rs1:x22(0x80000000), rs2:x13(0x00000002), result rd:x1(0x00000001)
li x22, MASK_XLEN(0x80000000)
li x13, MASK_XLEN(0x00000002)
SLT x1, x22, x13
sw x1, 344(x6)

# Testcase 87:  rs1:x12(0x80000000), rs2:x2(0x000000ff), result rd:x4(0x00000001)
li x12, MASK_XLEN(0x80000000)
li x2, MASK_XLEN(0x000000ff)
SLT x4, x12, x2
sw x4, 348(x6)

# Testcase 88:  rs1:x20(0x80000000), rs2:x1(0x6c52dd14), result rd:x9(0x00000001)
li x20, MASK_XLEN(0x80000000)
li x1, MASK_XLEN(0x6c52dd14)
SLT x9, x20, x1
sw x9, 352(x6)

# Testcase 89:  rs1:x28(0x80000000), rs2:x21(0x7ffffffe), result rd:x23(0x00000001)
li x28, MASK_XLEN(0x80000000)
li x21, MASK_XLEN(0x7ffffffe)
SLT x23, x28, x21
sw x23, 356(x6)

# Testcase 90:  rs1:x10(0x80000000), rs2:x24(0x7fffffff), result rd:x29(0x00000001)
li x10, MASK_XLEN(0x80000000)
li x24, MASK_XLEN(0x7fffffff)
SLT x29, x10, x24
sw x29, 360(x6)

# Testcase 91:  rs1:x8(0x80000000), rs2:x5(0x80000000), result rd:x25(0x00000000)
li x8, MASK_XLEN(0x80000000)
li x5, MASK_XLEN(0x80000000)
SLT x25, x8, x5
sw x25, 364(x6)

# Testcase 92:  rs1:x19(0x80000000), rs2:x10(0x80000001), result rd:x7(0x00000001)
li x19, MASK_XLEN(0x80000000)
li x10, MASK_XLEN(0x80000001)
SLT x7, x19, x10
sw x7, 368(x6)

# Testcase 93:  rs1:x4(0x80000000), rs2:x14(0x9173ab42), result rd:x15(0x00000001)
li x4, MASK_XLEN(0x80000000)
li x14, MASK_XLEN(0x9173ab42)
SLT x15, x4, x14
sw x15, 372(x6)

# Testcase 94:  rs1:x23(0x80000000), rs2:x11(0xfffffffe), result rd:x13(0x00000001)
li x23, MASK_XLEN(0x80000000)
li x11, MASK_XLEN(0xfffffffe)
SLT x13, x23, x11
sw x13, 376(x6)

# Testcase 95:  rs1:x21(0x80000000), rs2:x29(0xffffffff), result rd:x22(0x00000001)
li x21, MASK_XLEN(0x80000000)
li x29, MASK_XLEN(0xffffffff)
SLT x22, x21, x29
sw x22, 380(x6)

# Testcase 96:  rs1:x14(0x80000001), rs2:x5(0x00000000), result rd:x15(0x00000001)
li x14, MASK_XLEN(0x80000001)
li x5, MASK_XLEN(0x00000000)
SLT x15, x14, x5
sw x15, 384(x6)

# Testcase 97:  rs1:x30(0x80000001), rs2:x23(0x00000001), result rd:x5(0x00000001)
li x30, MASK_XLEN(0x80000001)
li x23, MASK_XLEN(0x00000001)
SLT x5, x30, x23
sw x5, 388(x6)

# Testcase 98:  rs1:x17(0x80000001), rs2:x11(0x00000002), result rd:x5(0x00000001)
li x17, MASK_XLEN(0x80000001)
li x11, MASK_XLEN(0x00000002)
SLT x5, x17, x11
sw x5, 392(x6)

# Testcase 99:  rs1:x15(0x80000001), rs2:x12(0x000000ff), result rd:x26(0x00000001)
li x15, MASK_XLEN(0x80000001)
li x12, MASK_XLEN(0x000000ff)
SLT x26, x15, x12
sw x26, 396(x6)

# Testcase 100:  rs1:x13(0x80000001), rs2:x14(0x6c52dd14), result rd:x26(0x00000001)
li x13, MASK_XLEN(0x80000001)
li x14, MASK_XLEN(0x6c52dd14)
SLT x26, x13, x14
sw x26, 400(x6)

# Testcase 101:  rs1:x16(0x80000001), rs2:x13(0x7ffffffe), result rd:x24(0x00000001)
li x16, MASK_XLEN(0x80000001)
li x13, MASK_XLEN(0x7ffffffe)
SLT x24, x16, x13
sw x24, 404(x6)

# Testcase 102:  rs1:x8(0x80000001), rs2:x26(0x7fffffff), result rd:x7(0x00000001)
li x8, MASK_XLEN(0x80000001)
li x26, MASK_XLEN(0x7fffffff)
SLT x7, x8, x26
sw x7, 408(x6)

# Testcase 103:  rs1:x15(0x80000001), rs2:x31(0x80000000), result rd:x7(0x00000000)
li x15, MASK_XLEN(0x80000001)
li x31, MASK_XLEN(0x80000000)
SLT x7, x15, x31
sw x7, 412(x6)

# Testcase 104:  rs1:x19(0x80000001), rs2:x23(0x80000001), result rd:x2(0x00000000)
li x19, MASK_XLEN(0x80000001)
li x23, MASK_XLEN(0x80000001)
SLT x2, x19, x23
sw x2, 416(x6)

# Testcase 105:  rs1:x29(0x80000001), rs2:x13(0x9173ab42), result rd:x2(0x00000001)
li x29, MASK_XLEN(0x80000001)
li x13, MASK_XLEN(0x9173ab42)
SLT x2, x29, x13
sw x2, 420(x6)

# Testcase 106:  rs1:x8(0x80000001), rs2:x21(0xfffffffe), result rd:x3(0x00000001)
li x8, MASK_XLEN(0x80000001)
li x21, MASK_XLEN(0xfffffffe)
SLT x3, x8, x21
sw x3, 424(x6)

# Testcase 107:  rs1:x2(0x80000001), rs2:x24(0xffffffff), result rd:x21(0x00000001)
li x2, MASK_XLEN(0x80000001)
li x24, MASK_XLEN(0xffffffff)
SLT x21, x2, x24
sw x21, 428(x6)

# Testcase 108:  rs1:x20(0x9173ab42), rs2:x10(0x00000000), result rd:x20(0x00000001)
li x20, MASK_XLEN(0x9173ab42)
li x10, MASK_XLEN(0x00000000)
SLT x20, x20, x10
sw x20, 432(x6)

# Testcase 109:  rs1:x3(0x9173ab42), rs2:x23(0x00000001), result rd:x28(0x00000001)
li x3, MASK_XLEN(0x9173ab42)
li x23, MASK_XLEN(0x00000001)
SLT x28, x3, x23
sw x28, 436(x6)

# Testcase 110:  rs1:x17(0x9173ab42), rs2:x25(0x00000002), result rd:x10(0x00000001)
li x17, MASK_XLEN(0x9173ab42)
li x25, MASK_XLEN(0x00000002)
SLT x10, x17, x25
sw x10, 440(x6)

# Testcase 111:  rs1:x25(0x9173ab42), rs2:x29(0x000000ff), result rd:x29(0x00000001)
li x25, MASK_XLEN(0x9173ab42)
li x29, MASK_XLEN(0x000000ff)
SLT x29, x25, x29
sw x29, 444(x6)

# Testcase 112:  rs1:x12(0x9173ab42), rs2:x14(0x6c52dd14), result rd:x15(0x00000001)
li x12, MASK_XLEN(0x9173ab42)
li x14, MASK_XLEN(0x6c52dd14)
SLT x15, x12, x14
sw x15, 448(x6)

# Testcase 113:  rs1:x2(0x9173ab42), rs2:x21(0x7ffffffe), result rd:x23(0x00000001)
li x2, MASK_XLEN(0x9173ab42)
li x21, MASK_XLEN(0x7ffffffe)
SLT x23, x2, x21
sw x23, 452(x6)

# Testcase 114:  rs1:x17(0x9173ab42), rs2:x22(0x7fffffff), result rd:x31(0x00000001)
li x17, MASK_XLEN(0x9173ab42)
li x22, MASK_XLEN(0x7fffffff)
SLT x31, x17, x22
sw x31, 456(x6)

# Testcase 115:  rs1:x21(0x9173ab42), rs2:x31(0x80000000), result rd:x18(0x00000000)
li x21, MASK_XLEN(0x9173ab42)
li x31, MASK_XLEN(0x80000000)
SLT x18, x21, x31
sw x18, 460(x6)

# Testcase 116:  rs1:x30(0x9173ab42), rs2:x24(0x80000001), result rd:x30(0x00000000)
li x30, MASK_XLEN(0x9173ab42)
li x24, MASK_XLEN(0x80000001)
SLT x30, x30, x24
sw x30, 464(x6)

# Testcase 117:  rs1:x14(0x9173ab42), rs2:x19(0x9173ab42), result rd:x15(0x00000000)
li x14, MASK_XLEN(0x9173ab42)
li x19, MASK_XLEN(0x9173ab42)
SLT x15, x14, x19
sw x15, 468(x6)

# Testcase 118:  rs1:x16(0x9173ab42), rs2:x9(0xfffffffe), result rd:x23(0x00000001)
li x16, MASK_XLEN(0x9173ab42)
li x9, MASK_XLEN(0xfffffffe)
SLT x23, x16, x9
sw x23, 472(x6)

# Testcase 119:  rs1:x16(0x9173ab42), rs2:x7(0xffffffff), result rd:x11(0x00000001)
li x16, MASK_XLEN(0x9173ab42)
li x7, MASK_XLEN(0xffffffff)
SLT x11, x16, x7
sw x11, 476(x6)

# Testcase 120:  rs1:x9(0xfffffffe), rs2:x2(0x00000000), result rd:x2(0x00000001)
li x9, MASK_XLEN(0xfffffffe)
li x2, MASK_XLEN(0x00000000)
SLT x2, x9, x2
sw x2, 480(x6)

# Testcase 121:  rs1:x1(0xfffffffe), rs2:x10(0x00000001), result rd:x21(0x00000001)
li x1, MASK_XLEN(0xfffffffe)
li x10, MASK_XLEN(0x00000001)
SLT x21, x1, x10
sw x21, 484(x6)

# Testcase 122:  rs1:x1(0xfffffffe), rs2:x5(0x00000002), result rd:x3(0x00000001)
li x1, MASK_XLEN(0xfffffffe)
li x5, MASK_XLEN(0x00000002)
SLT x3, x1, x5
sw x3, 488(x6)

# Testcase 123:  rs1:x26(0xfffffffe), rs2:x14(0x000000ff), result rd:x22(0x00000001)
li x26, MASK_XLEN(0xfffffffe)
li x14, MASK_XLEN(0x000000ff)
SLT x22, x26, x14
sw x22, 492(x6)

# Testcase 124:  rs1:x8(0xfffffffe), rs2:x20(0x6c52dd14), result rd:x13(0x00000001)
li x8, MASK_XLEN(0xfffffffe)
li x20, MASK_XLEN(0x6c52dd14)
SLT x13, x8, x20
sw x13, 496(x6)

# Testcase 125:  rs1:x18(0xfffffffe), rs2:x30(0x7ffffffe), result rd:x8(0x00000001)
li x18, MASK_XLEN(0xfffffffe)
li x30, MASK_XLEN(0x7ffffffe)
SLT x8, x18, x30
sw x8, 500(x6)

# Testcase 126:  rs1:x15(0xfffffffe), rs2:x7(0x7fffffff), result rd:x11(0x00000001)
li x15, MASK_XLEN(0xfffffffe)
li x7, MASK_XLEN(0x7fffffff)
SLT x11, x15, x7
sw x11, 504(x6)

# Testcase 127:  rs1:x20(0xfffffffe), rs2:x4(0x80000000), result rd:x20(0x00000000)
li x20, MASK_XLEN(0xfffffffe)
li x4, MASK_XLEN(0x80000000)
SLT x20, x20, x4
sw x20, 508(x6)

# Testcase 128:  rs1:x29(0xfffffffe), rs2:x3(0x80000001), result rd:x26(0x00000000)
li x29, MASK_XLEN(0xfffffffe)
li x3, MASK_XLEN(0x80000001)
SLT x26, x29, x3
sw x26, 512(x6)

# Testcase 129:  rs1:x15(0xfffffffe), rs2:x29(0x9173ab42), result rd:x11(0x00000000)
li x15, MASK_XLEN(0xfffffffe)
li x29, MASK_XLEN(0x9173ab42)
SLT x11, x15, x29
sw x11, 516(x6)

# Testcase 130:  rs1:x9(0xfffffffe), rs2:x1(0xfffffffe), result rd:x17(0x00000000)
li x9, MASK_XLEN(0xfffffffe)
li x1, MASK_XLEN(0xfffffffe)
SLT x17, x9, x1
sw x17, 520(x6)

# Testcase 131:  rs1:x2(0xfffffffe), rs2:x7(0xffffffff), result rd:x12(0x00000001)
li x2, MASK_XLEN(0xfffffffe)
li x7, MASK_XLEN(0xffffffff)
SLT x12, x2, x7
sw x12, 524(x6)

# Testcase 132:  rs1:x3(0xffffffff), rs2:x7(0x00000000), result rd:x28(0x00000001)
li x3, MASK_XLEN(0xffffffff)
li x7, MASK_XLEN(0x00000000)
SLT x28, x3, x7
sw x28, 528(x6)

# Testcase 133:  rs1:x17(0xffffffff), rs2:x12(0x00000001), result rd:x7(0x00000001)
li x17, MASK_XLEN(0xffffffff)
li x12, MASK_XLEN(0x00000001)
SLT x7, x17, x12
sw x7, 532(x6)

# Testcase 134:  rs1:x27(0xffffffff), rs2:x7(0x00000002), result rd:x9(0x00000001)
li x27, MASK_XLEN(0xffffffff)
li x7, MASK_XLEN(0x00000002)
SLT x9, x27, x7
sw x9, 536(x6)

# Testcase 135:  rs1:x22(0xffffffff), rs2:x24(0x000000ff), result rd:x24(0x00000001)
li x22, MASK_XLEN(0xffffffff)
li x24, MASK_XLEN(0x000000ff)
SLT x24, x22, x24
sw x24, 540(x6)

# Testcase 136:  rs1:x28(0xffffffff), rs2:x13(0x6c52dd14), result rd:x9(0x00000001)
li x28, MASK_XLEN(0xffffffff)
li x13, MASK_XLEN(0x6c52dd14)
SLT x9, x28, x13
sw x9, 544(x6)

# Testcase 137:  rs1:x16(0xffffffff), rs2:x12(0x7ffffffe), result rd:x28(0x00000001)
li x16, MASK_XLEN(0xffffffff)
li x12, MASK_XLEN(0x7ffffffe)
SLT x28, x16, x12
sw x28, 548(x6)

# Testcase 138:  rs1:x23(0xffffffff), rs2:x8(0x7fffffff), result rd:x2(0x00000001)
li x23, MASK_XLEN(0xffffffff)
li x8, MASK_XLEN(0x7fffffff)
SLT x2, x23, x8
sw x2, 552(x6)

# Testcase 139:  rs1:x10(0xffffffff), rs2:x30(0x80000000), result rd:x18(0x00000000)
li x10, MASK_XLEN(0xffffffff)
li x30, MASK_XLEN(0x80000000)
SLT x18, x10, x30
sw x18, 556(x6)

# Testcase 140:  rs1:x3(0xffffffff), rs2:x1(0x80000001), result rd:x15(0x00000000)
li x3, MASK_XLEN(0xffffffff)
li x1, MASK_XLEN(0x80000001)
SLT x15, x3, x1
sw x15, 560(x6)

# Testcase 141:  rs1:x16(0xffffffff), rs2:x24(0x9173ab42), result rd:x15(0x00000000)
li x16, MASK_XLEN(0xffffffff)
li x24, MASK_XLEN(0x9173ab42)
SLT x15, x16, x24
sw x15, 564(x6)

# Testcase 142:  rs1:x2(0xffffffff), rs2:x30(0xfffffffe), result rd:x26(0x00000000)
li x2, MASK_XLEN(0xffffffff)
li x30, MASK_XLEN(0xfffffffe)
SLT x26, x2, x30
sw x26, 568(x6)

# Testcase 143:  rs1:x14(0xffffffff), rs2:x16(0xffffffff), result rd:x15(0x00000000)
li x14, MASK_XLEN(0xffffffff)
li x16, MASK_XLEN(0xffffffff)
SLT x15, x14, x16
sw x15, 572(x6)

# Testcase 144:  rs1:x4(0x70aaf525), rs2:x27(0x1e3d59d0), result rd:x25(0x00000000)
li x4, MASK_XLEN(0x70aaf525)
li x27, MASK_XLEN(0x1e3d59d0)
SLT x25, x4, x27
sw x25, 576(x6)

# Testcase 145:  rs1:x29(0x275f275c), rs2:x30(0x69fcbef0), result rd:x7(0x00000001)
li x29, MASK_XLEN(0x275f275c)
li x30, MASK_XLEN(0x69fcbef0)
SLT x7, x29, x30
sw x7, 580(x6)

# Testcase 146:  rs1:x3(0x70cdc4a8), rs2:x27(0x9cdd9f6c), result rd:x14(0x00000000)
li x3, MASK_XLEN(0x70cdc4a8)
li x27, MASK_XLEN(0x9cdd9f6c)
SLT x14, x3, x27
sw x14, 584(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry

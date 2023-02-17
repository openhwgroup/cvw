///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-ADD.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.452536//
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

# Testcase 0:  rs1:x28(0x00000000), rs2:x13(0x00000000), result rd:x25(0x00000000)
li x28, MASK_XLEN(0x00000000)
li x13, MASK_XLEN(0x00000000)
ADD x25, x28, x13
sw x25, 0(x6)

# Testcase 1:  rs1:x29(0x00000000), rs2:x14(0x00000001), result rd:x2(0x00000001)
li x29, MASK_XLEN(0x00000000)
li x14, MASK_XLEN(0x00000001)
ADD x2, x29, x14
sw x2, 4(x6)

# Testcase 2:  rs1:x9(0x00000000), rs2:x31(0x00000002), result rd:x17(0x00000002)
li x9, MASK_XLEN(0x00000000)
li x31, MASK_XLEN(0x00000002)
ADD x17, x9, x31
sw x17, 8(x6)

# Testcase 3:  rs1:x16(0x00000000), rs2:x13(0x000000ff), result rd:x30(0x000000ff)
li x16, MASK_XLEN(0x00000000)
li x13, MASK_XLEN(0x000000ff)
ADD x30, x16, x13
sw x30, 12(x6)

# Testcase 4:  rs1:x26(0x00000000), rs2:x27(0x6c52dd14), result rd:x10(0x6c52dd14)
li x26, MASK_XLEN(0x00000000)
li x27, MASK_XLEN(0x6c52dd14)
ADD x10, x26, x27
sw x10, 16(x6)

# Testcase 5:  rs1:x31(0x00000000), rs2:x16(0x7ffffffe), result rd:x12(0x7ffffffe)
li x31, MASK_XLEN(0x00000000)
li x16, MASK_XLEN(0x7ffffffe)
ADD x12, x31, x16
sw x12, 20(x6)

# Testcase 6:  rs1:x19(0x00000000), rs2:x29(0x7fffffff), result rd:x30(0x7fffffff)
li x19, MASK_XLEN(0x00000000)
li x29, MASK_XLEN(0x7fffffff)
ADD x30, x19, x29
sw x30, 24(x6)

# Testcase 7:  rs1:x7(0x00000000), rs2:x17(0x80000000), result rd:x5(0x80000000)
li x7, MASK_XLEN(0x00000000)
li x17, MASK_XLEN(0x80000000)
ADD x5, x7, x17
sw x5, 28(x6)

# Testcase 8:  rs1:x10(0x00000000), rs2:x5(0x80000001), result rd:x25(0x80000001)
li x10, MASK_XLEN(0x00000000)
li x5, MASK_XLEN(0x80000001)
ADD x25, x10, x5
sw x25, 32(x6)

# Testcase 9:  rs1:x4(0x00000000), rs2:x20(0x9173ab42), result rd:x26(0x9173ab42)
li x4, MASK_XLEN(0x00000000)
li x20, MASK_XLEN(0x9173ab42)
ADD x26, x4, x20
sw x26, 36(x6)

# Testcase 10:  rs1:x9(0x00000000), rs2:x30(0xfffffffe), result rd:x18(0xfffffffe)
li x9, MASK_XLEN(0x00000000)
li x30, MASK_XLEN(0xfffffffe)
ADD x18, x9, x30
sw x18, 40(x6)

# Testcase 11:  rs1:x23(0x00000000), rs2:x26(0xffffffff), result rd:x20(0xffffffff)
li x23, MASK_XLEN(0x00000000)
li x26, MASK_XLEN(0xffffffff)
ADD x20, x23, x26
sw x20, 44(x6)

# Testcase 12:  rs1:x29(0x00000001), rs2:x5(0x00000000), result rd:x10(0x00000001)
li x29, MASK_XLEN(0x00000001)
li x5, MASK_XLEN(0x00000000)
ADD x10, x29, x5
sw x10, 48(x6)

# Testcase 13:  rs1:x4(0x00000001), rs2:x24(0x00000001), result rd:x3(0x00000002)
li x4, MASK_XLEN(0x00000001)
li x24, MASK_XLEN(0x00000001)
ADD x3, x4, x24
sw x3, 52(x6)

# Testcase 14:  rs1:x29(0x00000001), rs2:x28(0x00000002), result rd:x22(0x00000003)
li x29, MASK_XLEN(0x00000001)
li x28, MASK_XLEN(0x00000002)
ADD x22, x29, x28
sw x22, 56(x6)

# Testcase 15:  rs1:x11(0x00000001), rs2:x16(0x000000ff), result rd:x18(0x00000100)
li x11, MASK_XLEN(0x00000001)
li x16, MASK_XLEN(0x000000ff)
ADD x18, x11, x16
sw x18, 60(x6)

# Testcase 16:  rs1:x4(0x00000001), rs2:x12(0x6c52dd14), result rd:x14(0x6c52dd15)
li x4, MASK_XLEN(0x00000001)
li x12, MASK_XLEN(0x6c52dd14)
ADD x14, x4, x12
sw x14, 64(x6)

# Testcase 17:  rs1:x11(0x00000001), rs2:x20(0x7ffffffe), result rd:x21(0x7fffffff)
li x11, MASK_XLEN(0x00000001)
li x20, MASK_XLEN(0x7ffffffe)
ADD x21, x11, x20
sw x21, 68(x6)

# Testcase 18:  rs1:x30(0x00000001), rs2:x7(0x7fffffff), result rd:x31(0x80000000)
li x30, MASK_XLEN(0x00000001)
li x7, MASK_XLEN(0x7fffffff)
ADD x31, x30, x7
sw x31, 72(x6)

# Testcase 19:  rs1:x18(0x00000001), rs2:x16(0x80000000), result rd:x15(0x80000001)
li x18, MASK_XLEN(0x00000001)
li x16, MASK_XLEN(0x80000000)
ADD x15, x18, x16
sw x15, 76(x6)

# Testcase 20:  rs1:x28(0x00000001), rs2:x17(0x80000001), result rd:x9(0x80000002)
li x28, MASK_XLEN(0x00000001)
li x17, MASK_XLEN(0x80000001)
ADD x9, x28, x17
sw x9, 80(x6)

# Testcase 21:  rs1:x2(0x00000001), rs2:x26(0x9173ab42), result rd:x30(0x9173ab43)
li x2, MASK_XLEN(0x00000001)
li x26, MASK_XLEN(0x9173ab42)
ADD x30, x2, x26
sw x30, 84(x6)

# Testcase 22:  rs1:x18(0x00000001), rs2:x30(0xfffffffe), result rd:x1(0xffffffff)
li x18, MASK_XLEN(0x00000001)
li x30, MASK_XLEN(0xfffffffe)
ADD x1, x18, x30
sw x1, 88(x6)

# Testcase 23:  rs1:x3(0x00000001), rs2:x24(0xffffffff), result rd:x27(0x00000000)
li x3, MASK_XLEN(0x00000001)
li x24, MASK_XLEN(0xffffffff)
ADD x27, x3, x24
sw x27, 92(x6)

# Testcase 24:  rs1:x13(0x00000002), rs2:x23(0x00000000), result rd:x27(0x00000002)
li x13, MASK_XLEN(0x00000002)
li x23, MASK_XLEN(0x00000000)
ADD x27, x13, x23
sw x27, 96(x6)

# Testcase 25:  rs1:x26(0x00000002), rs2:x22(0x00000001), result rd:x21(0x00000003)
li x26, MASK_XLEN(0x00000002)
li x22, MASK_XLEN(0x00000001)
ADD x21, x26, x22
sw x21, 100(x6)

# Testcase 26:  rs1:x1(0x00000002), rs2:x20(0x00000002), result rd:x16(0x00000004)
li x1, MASK_XLEN(0x00000002)
li x20, MASK_XLEN(0x00000002)
ADD x16, x1, x20
sw x16, 104(x6)

# Testcase 27:  rs1:x27(0x00000002), rs2:x28(0x000000ff), result rd:x11(0x00000101)
li x27, MASK_XLEN(0x00000002)
li x28, MASK_XLEN(0x000000ff)
ADD x11, x27, x28
sw x11, 108(x6)

# Testcase 28:  rs1:x8(0x00000002), rs2:x24(0x6c52dd14), result rd:x11(0x6c52dd16)
li x8, MASK_XLEN(0x00000002)
li x24, MASK_XLEN(0x6c52dd14)
ADD x11, x8, x24
sw x11, 112(x6)

# Testcase 29:  rs1:x23(0x00000002), rs2:x28(0x7ffffffe), result rd:x3(0x80000000)
li x23, MASK_XLEN(0x00000002)
li x28, MASK_XLEN(0x7ffffffe)
ADD x3, x23, x28
sw x3, 116(x6)

# Testcase 30:  rs1:x7(0x00000002), rs2:x30(0x7fffffff), result rd:x19(0x80000001)
li x7, MASK_XLEN(0x00000002)
li x30, MASK_XLEN(0x7fffffff)
ADD x19, x7, x30
sw x19, 120(x6)

# Testcase 31:  rs1:x31(0x00000002), rs2:x5(0x80000000), result rd:x26(0x80000002)
li x31, MASK_XLEN(0x00000002)
li x5, MASK_XLEN(0x80000000)
ADD x26, x31, x5
sw x26, 124(x6)

# Testcase 32:  rs1:x18(0x00000002), rs2:x15(0x80000001), result rd:x3(0x80000003)
li x18, MASK_XLEN(0x00000002)
li x15, MASK_XLEN(0x80000001)
ADD x3, x18, x15
sw x3, 128(x6)

# Testcase 33:  rs1:x3(0x00000002), rs2:x11(0x9173ab42), result rd:x29(0x9173ab44)
li x3, MASK_XLEN(0x00000002)
li x11, MASK_XLEN(0x9173ab42)
ADD x29, x3, x11
sw x29, 132(x6)

# Testcase 34:  rs1:x17(0x00000002), rs2:x30(0xfffffffe), result rd:x16(0x00000000)
li x17, MASK_XLEN(0x00000002)
li x30, MASK_XLEN(0xfffffffe)
ADD x16, x17, x30
sw x16, 136(x6)

# Testcase 35:  rs1:x4(0x00000002), rs2:x10(0xffffffff), result rd:x18(0x00000001)
li x4, MASK_XLEN(0x00000002)
li x10, MASK_XLEN(0xffffffff)
ADD x18, x4, x10
sw x18, 140(x6)

# Testcase 36:  rs1:x10(0x000000ff), rs2:x23(0x00000000), result rd:x4(0x000000ff)
li x10, MASK_XLEN(0x000000ff)
li x23, MASK_XLEN(0x00000000)
ADD x4, x10, x23
sw x4, 144(x6)

# Testcase 37:  rs1:x18(0x000000ff), rs2:x11(0x00000001), result rd:x27(0x00000100)
li x18, MASK_XLEN(0x000000ff)
li x11, MASK_XLEN(0x00000001)
ADD x27, x18, x11
sw x27, 148(x6)

# Testcase 38:  rs1:x30(0x000000ff), rs2:x18(0x00000002), result rd:x7(0x00000101)
li x30, MASK_XLEN(0x000000ff)
li x18, MASK_XLEN(0x00000002)
ADD x7, x30, x18
sw x7, 152(x6)

# Testcase 39:  rs1:x31(0x000000ff), rs2:x26(0x000000ff), result rd:x20(0x000001fe)
li x31, MASK_XLEN(0x000000ff)
li x26, MASK_XLEN(0x000000ff)
ADD x20, x31, x26
sw x20, 156(x6)

# Testcase 40:  rs1:x18(0x000000ff), rs2:x19(0x6c52dd14), result rd:x10(0x6c52de13)
li x18, MASK_XLEN(0x000000ff)
li x19, MASK_XLEN(0x6c52dd14)
ADD x10, x18, x19
sw x10, 160(x6)

# Testcase 41:  rs1:x15(0x000000ff), rs2:x3(0x7ffffffe), result rd:x20(0x800000fd)
li x15, MASK_XLEN(0x000000ff)
li x3, MASK_XLEN(0x7ffffffe)
ADD x20, x15, x3
sw x20, 164(x6)

# Testcase 42:  rs1:x26(0x000000ff), rs2:x13(0x7fffffff), result rd:x11(0x800000fe)
li x26, MASK_XLEN(0x000000ff)
li x13, MASK_XLEN(0x7fffffff)
ADD x11, x26, x13
sw x11, 168(x6)

# Testcase 43:  rs1:x19(0x000000ff), rs2:x8(0x80000000), result rd:x10(0x800000ff)
li x19, MASK_XLEN(0x000000ff)
li x8, MASK_XLEN(0x80000000)
ADD x10, x19, x8
sw x10, 172(x6)

# Testcase 44:  rs1:x22(0x000000ff), rs2:x9(0x80000001), result rd:x16(0x80000100)
li x22, MASK_XLEN(0x000000ff)
li x9, MASK_XLEN(0x80000001)
ADD x16, x22, x9
sw x16, 176(x6)

# Testcase 45:  rs1:x25(0x000000ff), rs2:x5(0x9173ab42), result rd:x29(0x9173ac41)
li x25, MASK_XLEN(0x000000ff)
li x5, MASK_XLEN(0x9173ab42)
ADD x29, x25, x5
sw x29, 180(x6)

# Testcase 46:  rs1:x5(0x000000ff), rs2:x30(0xfffffffe), result rd:x2(0x000000fd)
li x5, MASK_XLEN(0x000000ff)
li x30, MASK_XLEN(0xfffffffe)
ADD x2, x5, x30
sw x2, 184(x6)

# Testcase 47:  rs1:x27(0x000000ff), rs2:x3(0xffffffff), result rd:x29(0x000000fe)
li x27, MASK_XLEN(0x000000ff)
li x3, MASK_XLEN(0xffffffff)
ADD x29, x27, x3
sw x29, 188(x6)

# Testcase 48:  rs1:x23(0x6c52dd14), rs2:x30(0x00000000), result rd:x27(0x6c52dd14)
li x23, MASK_XLEN(0x6c52dd14)
li x30, MASK_XLEN(0x00000000)
ADD x27, x23, x30
sw x27, 192(x6)

# Testcase 49:  rs1:x18(0x6c52dd14), rs2:x22(0x00000001), result rd:x13(0x6c52dd15)
li x18, MASK_XLEN(0x6c52dd14)
li x22, MASK_XLEN(0x00000001)
ADD x13, x18, x22
sw x13, 196(x6)

# Testcase 50:  rs1:x27(0x6c52dd14), rs2:x23(0x00000002), result rd:x17(0x6c52dd16)
li x27, MASK_XLEN(0x6c52dd14)
li x23, MASK_XLEN(0x00000002)
ADD x17, x27, x23
sw x17, 200(x6)

# Testcase 51:  rs1:x9(0x6c52dd14), rs2:x17(0x000000ff), result rd:x26(0x6c52de13)
li x9, MASK_XLEN(0x6c52dd14)
li x17, MASK_XLEN(0x000000ff)
ADD x26, x9, x17
sw x26, 204(x6)

# Testcase 52:  rs1:x8(0x6c52dd14), rs2:x28(0x6c52dd14), result rd:x7(0xd8a5ba28)
li x8, MASK_XLEN(0x6c52dd14)
li x28, MASK_XLEN(0x6c52dd14)
ADD x7, x8, x28
sw x7, 208(x6)

# Testcase 53:  rs1:x29(0x6c52dd14), rs2:x22(0x7ffffffe), result rd:x19(0xec52dd12)
li x29, MASK_XLEN(0x6c52dd14)
li x22, MASK_XLEN(0x7ffffffe)
ADD x19, x29, x22
sw x19, 212(x6)

# Testcase 54:  rs1:x27(0x6c52dd14), rs2:x31(0x7fffffff), result rd:x14(0xec52dd13)
li x27, MASK_XLEN(0x6c52dd14)
li x31, MASK_XLEN(0x7fffffff)
ADD x14, x27, x31
sw x14, 216(x6)

# Testcase 55:  rs1:x19(0x6c52dd14), rs2:x9(0x80000000), result rd:x15(0xec52dd14)
li x19, MASK_XLEN(0x6c52dd14)
li x9, MASK_XLEN(0x80000000)
ADD x15, x19, x9
sw x15, 220(x6)

# Testcase 56:  rs1:x16(0x6c52dd14), rs2:x22(0x80000001), result rd:x21(0xec52dd15)
li x16, MASK_XLEN(0x6c52dd14)
li x22, MASK_XLEN(0x80000001)
ADD x21, x16, x22
sw x21, 224(x6)

# Testcase 57:  rs1:x23(0x6c52dd14), rs2:x30(0x9173ab42), result rd:x26(0xfdc68856)
li x23, MASK_XLEN(0x6c52dd14)
li x30, MASK_XLEN(0x9173ab42)
ADD x26, x23, x30
sw x26, 228(x6)

# Testcase 58:  rs1:x12(0x6c52dd14), rs2:x3(0xfffffffe), result rd:x11(0x6c52dd12)
li x12, MASK_XLEN(0x6c52dd14)
li x3, MASK_XLEN(0xfffffffe)
ADD x11, x12, x3
sw x11, 232(x6)

# Testcase 59:  rs1:x20(0x6c52dd14), rs2:x4(0xffffffff), result rd:x16(0x6c52dd13)
li x20, MASK_XLEN(0x6c52dd14)
li x4, MASK_XLEN(0xffffffff)
ADD x16, x20, x4
sw x16, 236(x6)

# Testcase 60:  rs1:x19(0x7ffffffe), rs2:x21(0x00000000), result rd:x11(0x7ffffffe)
li x19, MASK_XLEN(0x7ffffffe)
li x21, MASK_XLEN(0x00000000)
ADD x11, x19, x21
sw x11, 240(x6)

# Testcase 61:  rs1:x28(0x7ffffffe), rs2:x7(0x00000001), result rd:x8(0x7fffffff)
li x28, MASK_XLEN(0x7ffffffe)
li x7, MASK_XLEN(0x00000001)
ADD x8, x28, x7
sw x8, 244(x6)

# Testcase 62:  rs1:x1(0x7ffffffe), rs2:x24(0x00000002), result rd:x9(0x80000000)
li x1, MASK_XLEN(0x7ffffffe)
li x24, MASK_XLEN(0x00000002)
ADD x9, x1, x24
sw x9, 248(x6)

# Testcase 63:  rs1:x4(0x7ffffffe), rs2:x23(0x000000ff), result rd:x8(0x800000fd)
li x4, MASK_XLEN(0x7ffffffe)
li x23, MASK_XLEN(0x000000ff)
ADD x8, x4, x23
sw x8, 252(x6)

# Testcase 64:  rs1:x11(0x7ffffffe), rs2:x14(0x6c52dd14), result rd:x27(0xec52dd12)
li x11, MASK_XLEN(0x7ffffffe)
li x14, MASK_XLEN(0x6c52dd14)
ADD x27, x11, x14
sw x27, 256(x6)

# Testcase 65:  rs1:x2(0x7ffffffe), rs2:x4(0x7ffffffe), result rd:x26(0xfffffffc)
li x2, MASK_XLEN(0x7ffffffe)
li x4, MASK_XLEN(0x7ffffffe)
ADD x26, x2, x4
sw x26, 260(x6)

# Testcase 66:  rs1:x5(0x7ffffffe), rs2:x28(0x7fffffff), result rd:x23(0xfffffffd)
li x5, MASK_XLEN(0x7ffffffe)
li x28, MASK_XLEN(0x7fffffff)
ADD x23, x5, x28
sw x23, 264(x6)

# Testcase 67:  rs1:x8(0x7ffffffe), rs2:x2(0x80000000), result rd:x27(0xfffffffe)
li x8, MASK_XLEN(0x7ffffffe)
li x2, MASK_XLEN(0x80000000)
ADD x27, x8, x2
sw x27, 268(x6)

# Testcase 68:  rs1:x19(0x7ffffffe), rs2:x21(0x80000001), result rd:x30(0xffffffff)
li x19, MASK_XLEN(0x7ffffffe)
li x21, MASK_XLEN(0x80000001)
ADD x30, x19, x21
sw x30, 272(x6)

# Testcase 69:  rs1:x30(0x7ffffffe), rs2:x18(0x9173ab42), result rd:x20(0x1173ab40)
li x30, MASK_XLEN(0x7ffffffe)
li x18, MASK_XLEN(0x9173ab42)
ADD x20, x30, x18
sw x20, 276(x6)

# Testcase 70:  rs1:x22(0x7ffffffe), rs2:x3(0xfffffffe), result rd:x1(0x7ffffffc)
li x22, MASK_XLEN(0x7ffffffe)
li x3, MASK_XLEN(0xfffffffe)
ADD x1, x22, x3
sw x1, 280(x6)

# Testcase 71:  rs1:x4(0x7ffffffe), rs2:x21(0xffffffff), result rd:x7(0x7ffffffd)
li x4, MASK_XLEN(0x7ffffffe)
li x21, MASK_XLEN(0xffffffff)
ADD x7, x4, x21
sw x7, 284(x6)

# Testcase 72:  rs1:x20(0x7fffffff), rs2:x27(0x00000000), result rd:x19(0x7fffffff)
li x20, MASK_XLEN(0x7fffffff)
li x27, MASK_XLEN(0x00000000)
ADD x19, x20, x27
sw x19, 288(x6)

# Testcase 73:  rs1:x4(0x7fffffff), rs2:x13(0x00000001), result rd:x3(0x80000000)
li x4, MASK_XLEN(0x7fffffff)
li x13, MASK_XLEN(0x00000001)
ADD x3, x4, x13
sw x3, 292(x6)

# Testcase 74:  rs1:x12(0x7fffffff), rs2:x27(0x00000002), result rd:x4(0x80000001)
li x12, MASK_XLEN(0x7fffffff)
li x27, MASK_XLEN(0x00000002)
ADD x4, x12, x27
sw x4, 296(x6)

# Testcase 75:  rs1:x2(0x7fffffff), rs2:x20(0x000000ff), result rd:x1(0x800000fe)
li x2, MASK_XLEN(0x7fffffff)
li x20, MASK_XLEN(0x000000ff)
ADD x1, x2, x20
sw x1, 300(x6)

# Testcase 76:  rs1:x23(0x7fffffff), rs2:x4(0x6c52dd14), result rd:x16(0xec52dd13)
li x23, MASK_XLEN(0x7fffffff)
li x4, MASK_XLEN(0x6c52dd14)
ADD x16, x23, x4
sw x16, 304(x6)

# Testcase 77:  rs1:x7(0x7fffffff), rs2:x24(0x7ffffffe), result rd:x26(0xfffffffd)
li x7, MASK_XLEN(0x7fffffff)
li x24, MASK_XLEN(0x7ffffffe)
ADD x26, x7, x24
sw x26, 308(x6)

# Testcase 78:  rs1:x2(0x7fffffff), rs2:x30(0x7fffffff), result rd:x22(0xfffffffe)
li x2, MASK_XLEN(0x7fffffff)
li x30, MASK_XLEN(0x7fffffff)
ADD x22, x2, x30
sw x22, 312(x6)

# Testcase 79:  rs1:x1(0x7fffffff), rs2:x18(0x80000000), result rd:x14(0xffffffff)
li x1, MASK_XLEN(0x7fffffff)
li x18, MASK_XLEN(0x80000000)
ADD x14, x1, x18
sw x14, 316(x6)

# Testcase 80:  rs1:x20(0x7fffffff), rs2:x4(0x80000001), result rd:x27(0x00000000)
li x20, MASK_XLEN(0x7fffffff)
li x4, MASK_XLEN(0x80000001)
ADD x27, x20, x4
sw x27, 320(x6)

# Testcase 81:  rs1:x9(0x7fffffff), rs2:x3(0x9173ab42), result rd:x8(0x1173ab41)
li x9, MASK_XLEN(0x7fffffff)
li x3, MASK_XLEN(0x9173ab42)
ADD x8, x9, x3
sw x8, 324(x6)

# Testcase 82:  rs1:x3(0x7fffffff), rs2:x21(0xfffffffe), result rd:x10(0x7ffffffd)
li x3, MASK_XLEN(0x7fffffff)
li x21, MASK_XLEN(0xfffffffe)
ADD x10, x3, x21
sw x10, 328(x6)

# Testcase 83:  rs1:x2(0x7fffffff), rs2:x17(0xffffffff), result rd:x15(0x7ffffffe)
li x2, MASK_XLEN(0x7fffffff)
li x17, MASK_XLEN(0xffffffff)
ADD x15, x2, x17
sw x15, 332(x6)

# Testcase 84:  rs1:x2(0x80000000), rs2:x20(0x00000000), result rd:x4(0x80000000)
li x2, MASK_XLEN(0x80000000)
li x20, MASK_XLEN(0x00000000)
ADD x4, x2, x20
sw x4, 336(x6)

# Testcase 85:  rs1:x23(0x80000000), rs2:x13(0x00000001), result rd:x7(0x80000001)
li x23, MASK_XLEN(0x80000000)
li x13, MASK_XLEN(0x00000001)
ADD x7, x23, x13
sw x7, 340(x6)

# Testcase 86:  rs1:x9(0x80000000), rs2:x12(0x00000002), result rd:x29(0x80000002)
li x9, MASK_XLEN(0x80000000)
li x12, MASK_XLEN(0x00000002)
ADD x29, x9, x12
sw x29, 344(x6)

# Testcase 87:  rs1:x24(0x80000000), rs2:x16(0x000000ff), result rd:x27(0x800000ff)
li x24, MASK_XLEN(0x80000000)
li x16, MASK_XLEN(0x000000ff)
ADD x27, x24, x16
sw x27, 348(x6)

# Testcase 88:  rs1:x29(0x80000000), rs2:x30(0x6c52dd14), result rd:x19(0xec52dd14)
li x29, MASK_XLEN(0x80000000)
li x30, MASK_XLEN(0x6c52dd14)
ADD x19, x29, x30
sw x19, 352(x6)

# Testcase 89:  rs1:x7(0x80000000), rs2:x31(0x7ffffffe), result rd:x25(0xfffffffe)
li x7, MASK_XLEN(0x80000000)
li x31, MASK_XLEN(0x7ffffffe)
ADD x25, x7, x31
sw x25, 356(x6)

# Testcase 90:  rs1:x2(0x80000000), rs2:x26(0x7fffffff), result rd:x22(0xffffffff)
li x2, MASK_XLEN(0x80000000)
li x26, MASK_XLEN(0x7fffffff)
ADD x22, x2, x26
sw x22, 360(x6)

# Testcase 91:  rs1:x11(0x80000000), rs2:x17(0x80000000), result rd:x9(0x00000000)
li x11, MASK_XLEN(0x80000000)
li x17, MASK_XLEN(0x80000000)
ADD x9, x11, x17
sw x9, 364(x6)

# Testcase 92:  rs1:x4(0x80000000), rs2:x20(0x80000001), result rd:x30(0x00000001)
li x4, MASK_XLEN(0x80000000)
li x20, MASK_XLEN(0x80000001)
ADD x30, x4, x20
sw x30, 368(x6)

# Testcase 93:  rs1:x1(0x80000000), rs2:x16(0x9173ab42), result rd:x22(0x1173ab42)
li x1, MASK_XLEN(0x80000000)
li x16, MASK_XLEN(0x9173ab42)
ADD x22, x1, x16
sw x22, 372(x6)

# Testcase 94:  rs1:x14(0x80000000), rs2:x29(0xfffffffe), result rd:x19(0x7ffffffe)
li x14, MASK_XLEN(0x80000000)
li x29, MASK_XLEN(0xfffffffe)
ADD x19, x14, x29
sw x19, 376(x6)

# Testcase 95:  rs1:x28(0x80000000), rs2:x17(0xffffffff), result rd:x30(0x7fffffff)
li x28, MASK_XLEN(0x80000000)
li x17, MASK_XLEN(0xffffffff)
ADD x30, x28, x17
sw x30, 380(x6)

# Testcase 96:  rs1:x10(0x80000001), rs2:x21(0x00000000), result rd:x12(0x80000001)
li x10, MASK_XLEN(0x80000001)
li x21, MASK_XLEN(0x00000000)
ADD x12, x10, x21
sw x12, 384(x6)

# Testcase 97:  rs1:x13(0x80000001), rs2:x27(0x00000001), result rd:x22(0x80000002)
li x13, MASK_XLEN(0x80000001)
li x27, MASK_XLEN(0x00000001)
ADD x22, x13, x27
sw x22, 388(x6)

# Testcase 98:  rs1:x9(0x80000001), rs2:x5(0x00000002), result rd:x18(0x80000003)
li x9, MASK_XLEN(0x80000001)
li x5, MASK_XLEN(0x00000002)
ADD x18, x9, x5
sw x18, 392(x6)

# Testcase 99:  rs1:x23(0x80000001), rs2:x1(0x000000ff), result rd:x15(0x80000100)
li x23, MASK_XLEN(0x80000001)
li x1, MASK_XLEN(0x000000ff)
ADD x15, x23, x1
sw x15, 396(x6)

# Testcase 100:  rs1:x24(0x80000001), rs2:x3(0x6c52dd14), result rd:x11(0xec52dd15)
li x24, MASK_XLEN(0x80000001)
li x3, MASK_XLEN(0x6c52dd14)
ADD x11, x24, x3
sw x11, 400(x6)

# Testcase 101:  rs1:x24(0x80000001), rs2:x2(0x7ffffffe), result rd:x18(0xffffffff)
li x24, MASK_XLEN(0x80000001)
li x2, MASK_XLEN(0x7ffffffe)
ADD x18, x24, x2
sw x18, 404(x6)

# Testcase 102:  rs1:x9(0x80000001), rs2:x5(0x7fffffff), result rd:x8(0x00000000)
li x9, MASK_XLEN(0x80000001)
li x5, MASK_XLEN(0x7fffffff)
ADD x8, x9, x5
sw x8, 408(x6)

# Testcase 103:  rs1:x25(0x80000001), rs2:x31(0x80000000), result rd:x16(0x00000001)
li x25, MASK_XLEN(0x80000001)
li x31, MASK_XLEN(0x80000000)
ADD x16, x25, x31
sw x16, 412(x6)

# Testcase 104:  rs1:x12(0x80000001), rs2:x20(0x80000001), result rd:x10(0x00000002)
li x12, MASK_XLEN(0x80000001)
li x20, MASK_XLEN(0x80000001)
ADD x10, x12, x20
sw x10, 416(x6)

# Testcase 105:  rs1:x22(0x80000001), rs2:x12(0x9173ab42), result rd:x19(0x1173ab43)
li x22, MASK_XLEN(0x80000001)
li x12, MASK_XLEN(0x9173ab42)
ADD x19, x22, x12
sw x19, 420(x6)

# Testcase 106:  rs1:x31(0x80000001), rs2:x29(0xfffffffe), result rd:x21(0x7fffffff)
li x31, MASK_XLEN(0x80000001)
li x29, MASK_XLEN(0xfffffffe)
ADD x21, x31, x29
sw x21, 424(x6)

# Testcase 107:  rs1:x28(0x80000001), rs2:x20(0xffffffff), result rd:x5(0x80000000)
li x28, MASK_XLEN(0x80000001)
li x20, MASK_XLEN(0xffffffff)
ADD x5, x28, x20
sw x5, 428(x6)

# Testcase 108:  rs1:x23(0x9173ab42), rs2:x10(0x00000000), result rd:x13(0x9173ab42)
li x23, MASK_XLEN(0x9173ab42)
li x10, MASK_XLEN(0x00000000)
ADD x13, x23, x10
sw x13, 432(x6)

# Testcase 109:  rs1:x24(0x9173ab42), rs2:x14(0x00000001), result rd:x27(0x9173ab43)
li x24, MASK_XLEN(0x9173ab42)
li x14, MASK_XLEN(0x00000001)
ADD x27, x24, x14
sw x27, 436(x6)

# Testcase 110:  rs1:x21(0x9173ab42), rs2:x3(0x00000002), result rd:x1(0x9173ab44)
li x21, MASK_XLEN(0x9173ab42)
li x3, MASK_XLEN(0x00000002)
ADD x1, x21, x3
sw x1, 440(x6)

# Testcase 111:  rs1:x20(0x9173ab42), rs2:x7(0x000000ff), result rd:x23(0x9173ac41)
li x20, MASK_XLEN(0x9173ab42)
li x7, MASK_XLEN(0x000000ff)
ADD x23, x20, x7
sw x23, 444(x6)

# Testcase 112:  rs1:x8(0x9173ab42), rs2:x21(0x6c52dd14), result rd:x15(0xfdc68856)
li x8, MASK_XLEN(0x9173ab42)
li x21, MASK_XLEN(0x6c52dd14)
ADD x15, x8, x21
sw x15, 448(x6)

# Testcase 113:  rs1:x13(0x9173ab42), rs2:x23(0x7ffffffe), result rd:x29(0x1173ab40)
li x13, MASK_XLEN(0x9173ab42)
li x23, MASK_XLEN(0x7ffffffe)
ADD x29, x13, x23
sw x29, 452(x6)

# Testcase 114:  rs1:x22(0x9173ab42), rs2:x19(0x7fffffff), result rd:x28(0x1173ab41)
li x22, MASK_XLEN(0x9173ab42)
li x19, MASK_XLEN(0x7fffffff)
ADD x28, x22, x19
sw x28, 456(x6)

# Testcase 115:  rs1:x14(0x9173ab42), rs2:x2(0x80000000), result rd:x13(0x1173ab42)
li x14, MASK_XLEN(0x9173ab42)
li x2, MASK_XLEN(0x80000000)
ADD x13, x14, x2
sw x13, 460(x6)

# Testcase 116:  rs1:x28(0x9173ab42), rs2:x23(0x80000001), result rd:x19(0x1173ab43)
li x28, MASK_XLEN(0x9173ab42)
li x23, MASK_XLEN(0x80000001)
ADD x19, x28, x23
sw x19, 464(x6)

# Testcase 117:  rs1:x14(0x9173ab42), rs2:x25(0x9173ab42), result rd:x22(0x22e75684)
li x14, MASK_XLEN(0x9173ab42)
li x25, MASK_XLEN(0x9173ab42)
ADD x22, x14, x25
sw x22, 468(x6)

# Testcase 118:  rs1:x15(0x9173ab42), rs2:x3(0xfffffffe), result rd:x9(0x9173ab40)
li x15, MASK_XLEN(0x9173ab42)
li x3, MASK_XLEN(0xfffffffe)
ADD x9, x15, x3
sw x9, 472(x6)

# Testcase 119:  rs1:x17(0x9173ab42), rs2:x29(0xffffffff), result rd:x16(0x9173ab41)
li x17, MASK_XLEN(0x9173ab42)
li x29, MASK_XLEN(0xffffffff)
ADD x16, x17, x29
sw x16, 476(x6)

# Testcase 120:  rs1:x30(0xfffffffe), rs2:x18(0x00000000), result rd:x20(0xfffffffe)
li x30, MASK_XLEN(0xfffffffe)
li x18, MASK_XLEN(0x00000000)
ADD x20, x30, x18
sw x20, 480(x6)

# Testcase 121:  rs1:x25(0xfffffffe), rs2:x1(0x00000001), result rd:x29(0xffffffff)
li x25, MASK_XLEN(0xfffffffe)
li x1, MASK_XLEN(0x00000001)
ADD x29, x25, x1
sw x29, 484(x6)

# Testcase 122:  rs1:x2(0xfffffffe), rs2:x16(0x00000002), result rd:x11(0x00000000)
li x2, MASK_XLEN(0xfffffffe)
li x16, MASK_XLEN(0x00000002)
ADD x11, x2, x16
sw x11, 488(x6)

# Testcase 123:  rs1:x10(0xfffffffe), rs2:x27(0x000000ff), result rd:x15(0x000000fd)
li x10, MASK_XLEN(0xfffffffe)
li x27, MASK_XLEN(0x000000ff)
ADD x15, x10, x27
sw x15, 492(x6)

# Testcase 124:  rs1:x2(0xfffffffe), rs2:x26(0x6c52dd14), result rd:x27(0x6c52dd12)
li x2, MASK_XLEN(0xfffffffe)
li x26, MASK_XLEN(0x6c52dd14)
ADD x27, x2, x26
sw x27, 496(x6)

# Testcase 125:  rs1:x29(0xfffffffe), rs2:x26(0x7ffffffe), result rd:x14(0x7ffffffc)
li x29, MASK_XLEN(0xfffffffe)
li x26, MASK_XLEN(0x7ffffffe)
ADD x14, x29, x26
sw x14, 500(x6)

# Testcase 126:  rs1:x7(0xfffffffe), rs2:x18(0x7fffffff), result rd:x31(0x7ffffffd)
li x7, MASK_XLEN(0xfffffffe)
li x18, MASK_XLEN(0x7fffffff)
ADD x31, x7, x18
sw x31, 504(x6)

# Testcase 127:  rs1:x21(0xfffffffe), rs2:x3(0x80000000), result rd:x27(0x7ffffffe)
li x21, MASK_XLEN(0xfffffffe)
li x3, MASK_XLEN(0x80000000)
ADD x27, x21, x3
sw x27, 508(x6)

# Testcase 128:  rs1:x24(0xfffffffe), rs2:x5(0x80000001), result rd:x1(0x7fffffff)
li x24, MASK_XLEN(0xfffffffe)
li x5, MASK_XLEN(0x80000001)
ADD x1, x24, x5
sw x1, 512(x6)

# Testcase 129:  rs1:x13(0xfffffffe), rs2:x31(0x9173ab42), result rd:x22(0x9173ab40)
li x13, MASK_XLEN(0xfffffffe)
li x31, MASK_XLEN(0x9173ab42)
ADD x22, x13, x31
sw x22, 516(x6)

# Testcase 130:  rs1:x14(0xfffffffe), rs2:x11(0xfffffffe), result rd:x1(0xfffffffc)
li x14, MASK_XLEN(0xfffffffe)
li x11, MASK_XLEN(0xfffffffe)
ADD x1, x14, x11
sw x1, 520(x6)

# Testcase 131:  rs1:x7(0xfffffffe), rs2:x1(0xffffffff), result rd:x23(0xfffffffd)
li x7, MASK_XLEN(0xfffffffe)
li x1, MASK_XLEN(0xffffffff)
ADD x23, x7, x1
sw x23, 524(x6)

# Testcase 132:  rs1:x25(0xffffffff), rs2:x1(0x00000000), result rd:x27(0xffffffff)
li x25, MASK_XLEN(0xffffffff)
li x1, MASK_XLEN(0x00000000)
ADD x27, x25, x1
sw x27, 528(x6)

# Testcase 133:  rs1:x22(0xffffffff), rs2:x17(0x00000001), result rd:x20(0x00000000)
li x22, MASK_XLEN(0xffffffff)
li x17, MASK_XLEN(0x00000001)
ADD x20, x22, x17
sw x20, 532(x6)

# Testcase 134:  rs1:x4(0xffffffff), rs2:x7(0x00000002), result rd:x4(0x00000001)
li x4, MASK_XLEN(0xffffffff)
li x7, MASK_XLEN(0x00000002)
ADD x4, x4, x7
sw x4, 536(x6)

# Testcase 135:  rs1:x20(0xffffffff), rs2:x21(0x000000ff), result rd:x7(0x000000fe)
li x20, MASK_XLEN(0xffffffff)
li x21, MASK_XLEN(0x000000ff)
ADD x7, x20, x21
sw x7, 540(x6)

# Testcase 136:  rs1:x28(0xffffffff), rs2:x10(0x6c52dd14), result rd:x9(0x6c52dd13)
li x28, MASK_XLEN(0xffffffff)
li x10, MASK_XLEN(0x6c52dd14)
ADD x9, x28, x10
sw x9, 544(x6)

# Testcase 137:  rs1:x16(0xffffffff), rs2:x28(0x7ffffffe), result rd:x30(0x7ffffffd)
li x16, MASK_XLEN(0xffffffff)
li x28, MASK_XLEN(0x7ffffffe)
ADD x30, x16, x28
sw x30, 548(x6)

# Testcase 138:  rs1:x13(0xffffffff), rs2:x21(0x7fffffff), result rd:x3(0x7ffffffe)
li x13, MASK_XLEN(0xffffffff)
li x21, MASK_XLEN(0x7fffffff)
ADD x3, x13, x21
sw x3, 552(x6)

# Testcase 139:  rs1:x1(0xffffffff), rs2:x9(0x80000000), result rd:x30(0x7fffffff)
li x1, MASK_XLEN(0xffffffff)
li x9, MASK_XLEN(0x80000000)
ADD x30, x1, x9
sw x30, 556(x6)

# Testcase 140:  rs1:x15(0xffffffff), rs2:x26(0x80000001), result rd:x26(0x80000000)
li x15, MASK_XLEN(0xffffffff)
li x26, MASK_XLEN(0x80000001)
ADD x26, x15, x26
sw x26, 560(x6)

# Testcase 141:  rs1:x4(0xffffffff), rs2:x28(0x9173ab42), result rd:x9(0x9173ab41)
li x4, MASK_XLEN(0xffffffff)
li x28, MASK_XLEN(0x9173ab42)
ADD x9, x4, x28
sw x9, 564(x6)

# Testcase 142:  rs1:x5(0xffffffff), rs2:x21(0xfffffffe), result rd:x17(0xfffffffd)
li x5, MASK_XLEN(0xffffffff)
li x21, MASK_XLEN(0xfffffffe)
ADD x17, x5, x21
sw x17, 568(x6)

# Testcase 143:  rs1:x27(0xffffffff), rs2:x21(0xffffffff), result rd:x21(0xfffffffe)
li x27, MASK_XLEN(0xffffffff)
li x21, MASK_XLEN(0xffffffff)
ADD x21, x27, x21
sw x21, 572(x6)

# Testcase 144:  rs1:x28(0x58d87776), rs2:x5(0x1d77ce40), result rd:x9(0x765045b6)
li x28, MASK_XLEN(0x58d87776)
li x5, MASK_XLEN(0x1d77ce40)
ADD x9, x28, x5
sw x9, 576(x6)

# Testcase 145:  rs1:x22(0xd9ead926), rs2:x9(0x04c14982), result rd:x18(0xdeac22a8)
li x22, MASK_XLEN(0xd9ead926)
li x9, MASK_XLEN(0x04c14982)
ADD x18, x22, x9
sw x18, 580(x6)

# Testcase 146:  rs1:x12(0x50910bdc), rs2:x31(0xf24dfdd8), result rd:x19(0x42df09b4)
li x12, MASK_XLEN(0x50910bdc)
li x31, MASK_XLEN(0xf24dfdd8)
ADD x19, x12, x31
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
// ../wally-riscv-arch-test/riscv-test-suite/rv32i_m/I/src/WALLY-ADD.S
// David_Harris@hmc.edu & Katherine Parry

///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-ADD.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.522664//
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

# Testcase 0:  rs1:x18(0x0000000000000000), rs2:x22(0x0000000000000000), result rd:x22(0x0000000000000000)
li x18, MASK_XLEN(0x0000000000000000)
li x22, MASK_XLEN(0x0000000000000000)
ADD x22, x18, x22
sd x22, 0(x6)

# Testcase 1:  rs1:x11(0x0000000000000000), rs2:x1(0x0000000000000001), result rd:x5(0x0000000000000001)
li x11, MASK_XLEN(0x0000000000000000)
li x1, MASK_XLEN(0x0000000000000001)
ADD x5, x11, x1
sd x5, 8(x6)

# Testcase 2:  rs1:x1(0x0000000000000000), rs2:x3(0x0000000000000002), result rd:x11(0x0000000000000002)
li x1, MASK_XLEN(0x0000000000000000)
li x3, MASK_XLEN(0x0000000000000002)
ADD x11, x1, x3
sd x11, 16(x6)

# Testcase 3:  rs1:x25(0x0000000000000000), rs2:x11(0x00000000000000ff), result rd:x15(0x00000000000000ff)
li x25, MASK_XLEN(0x0000000000000000)
li x11, MASK_XLEN(0x00000000000000ff)
ADD x15, x25, x11
sd x15, 24(x6)

# Testcase 4:  rs1:x28(0x0000000000000000), rs2:x7(0x624b3e976c52dd14), result rd:x8(0x624b3e976c52dd14)
li x28, MASK_XLEN(0x0000000000000000)
li x7, MASK_XLEN(0x624b3e976c52dd14)
ADD x8, x28, x7
sd x8, 32(x6)

# Testcase 5:  rs1:x12(0x0000000000000000), rs2:x29(0x7ffffffffffffffe), result rd:x22(0x7ffffffffffffffe)
li x12, MASK_XLEN(0x0000000000000000)
li x29, MASK_XLEN(0x7ffffffffffffffe)
ADD x22, x12, x29
sd x22, 40(x6)

# Testcase 6:  rs1:x19(0x0000000000000000), rs2:x15(0x7fffffffffffffff), result rd:x9(0x7fffffffffffffff)
li x19, MASK_XLEN(0x0000000000000000)
li x15, MASK_XLEN(0x7fffffffffffffff)
ADD x9, x19, x15
sd x9, 48(x6)

# Testcase 7:  rs1:x15(0x0000000000000000), rs2:x13(0x8000000000000000), result rd:x1(0x8000000000000000)
li x15, MASK_XLEN(0x0000000000000000)
li x13, MASK_XLEN(0x8000000000000000)
ADD x1, x15, x13
sd x1, 56(x6)

# Testcase 8:  rs1:x4(0x0000000000000000), rs2:x1(0x8000000000000001), result rd:x4(0x8000000000000001)
li x4, MASK_XLEN(0x0000000000000000)
li x1, MASK_XLEN(0x8000000000000001)
ADD x4, x4, x1
sd x4, 64(x6)

# Testcase 9:  rs1:x11(0x0000000000000000), rs2:x24(0xc365ddeb9173ab42), result rd:x7(0xc365ddeb9173ab42)
li x11, MASK_XLEN(0x0000000000000000)
li x24, MASK_XLEN(0xc365ddeb9173ab42)
ADD x7, x11, x24
sd x7, 72(x6)

# Testcase 10:  rs1:x10(0x0000000000000000), rs2:x18(0xfffffffffffffffe), result rd:x4(0xfffffffffffffffe)
li x10, MASK_XLEN(0x0000000000000000)
li x18, MASK_XLEN(0xfffffffffffffffe)
ADD x4, x10, x18
sd x4, 80(x6)

# Testcase 11:  rs1:x17(0x0000000000000000), rs2:x25(0xffffffffffffffff), result rd:x10(0xffffffffffffffff)
li x17, MASK_XLEN(0x0000000000000000)
li x25, MASK_XLEN(0xffffffffffffffff)
ADD x10, x17, x25
sd x10, 88(x6)

# Testcase 12:  rs1:x29(0x0000000000000001), rs2:x3(0x0000000000000000), result rd:x4(0x0000000000000001)
li x29, MASK_XLEN(0x0000000000000001)
li x3, MASK_XLEN(0x0000000000000000)
ADD x4, x29, x3
sd x4, 96(x6)

# Testcase 13:  rs1:x18(0x0000000000000001), rs2:x20(0x0000000000000001), result rd:x10(0x0000000000000002)
li x18, MASK_XLEN(0x0000000000000001)
li x20, MASK_XLEN(0x0000000000000001)
ADD x10, x18, x20
sd x10, 104(x6)

# Testcase 14:  rs1:x24(0x0000000000000001), rs2:x2(0x0000000000000002), result rd:x8(0x0000000000000003)
li x24, MASK_XLEN(0x0000000000000001)
li x2, MASK_XLEN(0x0000000000000002)
ADD x8, x24, x2
sd x8, 112(x6)

# Testcase 15:  rs1:x30(0x0000000000000001), rs2:x27(0x00000000000000ff), result rd:x4(0x0000000000000100)
li x30, MASK_XLEN(0x0000000000000001)
li x27, MASK_XLEN(0x00000000000000ff)
ADD x4, x30, x27
sd x4, 120(x6)

# Testcase 16:  rs1:x9(0x0000000000000001), rs2:x29(0x624b3e976c52dd14), result rd:x27(0x624b3e976c52dd15)
li x9, MASK_XLEN(0x0000000000000001)
li x29, MASK_XLEN(0x624b3e976c52dd14)
ADD x27, x9, x29
sd x27, 128(x6)

# Testcase 17:  rs1:x23(0x0000000000000001), rs2:x27(0x7ffffffffffffffe), result rd:x19(0x7fffffffffffffff)
li x23, MASK_XLEN(0x0000000000000001)
li x27, MASK_XLEN(0x7ffffffffffffffe)
ADD x19, x23, x27
sd x19, 136(x6)

# Testcase 18:  rs1:x1(0x0000000000000001), rs2:x18(0x7fffffffffffffff), result rd:x13(0x8000000000000000)
li x1, MASK_XLEN(0x0000000000000001)
li x18, MASK_XLEN(0x7fffffffffffffff)
ADD x13, x1, x18
sd x13, 144(x6)

# Testcase 19:  rs1:x1(0x0000000000000001), rs2:x31(0x8000000000000000), result rd:x4(0x8000000000000001)
li x1, MASK_XLEN(0x0000000000000001)
li x31, MASK_XLEN(0x8000000000000000)
ADD x4, x1, x31
sd x4, 152(x6)

# Testcase 20:  rs1:x4(0x0000000000000001), rs2:x10(0x8000000000000001), result rd:x3(0x8000000000000002)
li x4, MASK_XLEN(0x0000000000000001)
li x10, MASK_XLEN(0x8000000000000001)
ADD x3, x4, x10
sd x3, 160(x6)

# Testcase 21:  rs1:x21(0x0000000000000001), rs2:x25(0xc365ddeb9173ab42), result rd:x13(0xc365ddeb9173ab43)
li x21, MASK_XLEN(0x0000000000000001)
li x25, MASK_XLEN(0xc365ddeb9173ab42)
ADD x13, x21, x25
sd x13, 168(x6)

# Testcase 22:  rs1:x7(0x0000000000000001), rs2:x9(0xfffffffffffffffe), result rd:x24(0xffffffffffffffff)
li x7, MASK_XLEN(0x0000000000000001)
li x9, MASK_XLEN(0xfffffffffffffffe)
ADD x24, x7, x9
sd x24, 176(x6)

# Testcase 23:  rs1:x13(0x0000000000000001), rs2:x8(0xffffffffffffffff), result rd:x15(0x0000000000000000)
li x13, MASK_XLEN(0x0000000000000001)
li x8, MASK_XLEN(0xffffffffffffffff)
ADD x15, x13, x8
sd x15, 184(x6)

# Testcase 24:  rs1:x21(0x0000000000000002), rs2:x20(0x0000000000000000), result rd:x17(0x0000000000000002)
li x21, MASK_XLEN(0x0000000000000002)
li x20, MASK_XLEN(0x0000000000000000)
ADD x17, x21, x20
sd x17, 192(x6)

# Testcase 25:  rs1:x18(0x0000000000000002), rs2:x27(0x0000000000000001), result rd:x12(0x0000000000000003)
li x18, MASK_XLEN(0x0000000000000002)
li x27, MASK_XLEN(0x0000000000000001)
ADD x12, x18, x27
sd x12, 200(x6)

# Testcase 26:  rs1:x26(0x0000000000000002), rs2:x1(0x0000000000000002), result rd:x19(0x0000000000000004)
li x26, MASK_XLEN(0x0000000000000002)
li x1, MASK_XLEN(0x0000000000000002)
ADD x19, x26, x1
sd x19, 208(x6)

# Testcase 27:  rs1:x14(0x0000000000000002), rs2:x31(0x00000000000000ff), result rd:x20(0x0000000000000101)
li x14, MASK_XLEN(0x0000000000000002)
li x31, MASK_XLEN(0x00000000000000ff)
ADD x20, x14, x31
sd x20, 216(x6)

# Testcase 28:  rs1:x8(0x0000000000000002), rs2:x10(0x624b3e976c52dd14), result rd:x12(0x624b3e976c52dd16)
li x8, MASK_XLEN(0x0000000000000002)
li x10, MASK_XLEN(0x624b3e976c52dd14)
ADD x12, x8, x10
sd x12, 224(x6)

# Testcase 29:  rs1:x17(0x0000000000000002), rs2:x11(0x7ffffffffffffffe), result rd:x16(0x8000000000000000)
li x17, MASK_XLEN(0x0000000000000002)
li x11, MASK_XLEN(0x7ffffffffffffffe)
ADD x16, x17, x11
sd x16, 232(x6)

# Testcase 30:  rs1:x21(0x0000000000000002), rs2:x28(0x7fffffffffffffff), result rd:x25(0x8000000000000001)
li x21, MASK_XLEN(0x0000000000000002)
li x28, MASK_XLEN(0x7fffffffffffffff)
ADD x25, x21, x28
sd x25, 240(x6)

# Testcase 31:  rs1:x24(0x0000000000000002), rs2:x15(0x8000000000000000), result rd:x29(0x8000000000000002)
li x24, MASK_XLEN(0x0000000000000002)
li x15, MASK_XLEN(0x8000000000000000)
ADD x29, x24, x15
sd x29, 248(x6)

# Testcase 32:  rs1:x24(0x0000000000000002), rs2:x23(0x8000000000000001), result rd:x29(0x8000000000000003)
li x24, MASK_XLEN(0x0000000000000002)
li x23, MASK_XLEN(0x8000000000000001)
ADD x29, x24, x23
sd x29, 256(x6)

# Testcase 33:  rs1:x9(0x0000000000000002), rs2:x12(0xc365ddeb9173ab42), result rd:x9(0xc365ddeb9173ab44)
li x9, MASK_XLEN(0x0000000000000002)
li x12, MASK_XLEN(0xc365ddeb9173ab42)
ADD x9, x9, x12
sd x9, 264(x6)

# Testcase 34:  rs1:x29(0x0000000000000002), rs2:x8(0xfffffffffffffffe), result rd:x29(0x0000000000000000)
li x29, MASK_XLEN(0x0000000000000002)
li x8, MASK_XLEN(0xfffffffffffffffe)
ADD x29, x29, x8
sd x29, 272(x6)

# Testcase 35:  rs1:x15(0x0000000000000002), rs2:x11(0xffffffffffffffff), result rd:x21(0x0000000000000001)
li x15, MASK_XLEN(0x0000000000000002)
li x11, MASK_XLEN(0xffffffffffffffff)
ADD x21, x15, x11
sd x21, 280(x6)

# Testcase 36:  rs1:x1(0x00000000000000ff), rs2:x12(0x0000000000000000), result rd:x16(0x00000000000000ff)
li x1, MASK_XLEN(0x00000000000000ff)
li x12, MASK_XLEN(0x0000000000000000)
ADD x16, x1, x12
sd x16, 288(x6)

# Testcase 37:  rs1:x20(0x00000000000000ff), rs2:x26(0x0000000000000001), result rd:x31(0x0000000000000100)
li x20, MASK_XLEN(0x00000000000000ff)
li x26, MASK_XLEN(0x0000000000000001)
ADD x31, x20, x26
sd x31, 296(x6)

# Testcase 38:  rs1:x23(0x00000000000000ff), rs2:x10(0x0000000000000002), result rd:x22(0x0000000000000101)
li x23, MASK_XLEN(0x00000000000000ff)
li x10, MASK_XLEN(0x0000000000000002)
ADD x22, x23, x10
sd x22, 304(x6)

# Testcase 39:  rs1:x8(0x00000000000000ff), rs2:x1(0x00000000000000ff), result rd:x4(0x00000000000001fe)
li x8, MASK_XLEN(0x00000000000000ff)
li x1, MASK_XLEN(0x00000000000000ff)
ADD x4, x8, x1
sd x4, 312(x6)

# Testcase 40:  rs1:x15(0x00000000000000ff), rs2:x24(0x624b3e976c52dd14), result rd:x17(0x624b3e976c52de13)
li x15, MASK_XLEN(0x00000000000000ff)
li x24, MASK_XLEN(0x624b3e976c52dd14)
ADD x17, x15, x24
sd x17, 320(x6)

# Testcase 41:  rs1:x7(0x00000000000000ff), rs2:x27(0x7ffffffffffffffe), result rd:x13(0x80000000000000fd)
li x7, MASK_XLEN(0x00000000000000ff)
li x27, MASK_XLEN(0x7ffffffffffffffe)
ADD x13, x7, x27
sd x13, 328(x6)

# Testcase 42:  rs1:x31(0x00000000000000ff), rs2:x23(0x7fffffffffffffff), result rd:x20(0x80000000000000fe)
li x31, MASK_XLEN(0x00000000000000ff)
li x23, MASK_XLEN(0x7fffffffffffffff)
ADD x20, x31, x23
sd x20, 336(x6)

# Testcase 43:  rs1:x11(0x00000000000000ff), rs2:x18(0x8000000000000000), result rd:x5(0x80000000000000ff)
li x11, MASK_XLEN(0x00000000000000ff)
li x18, MASK_XLEN(0x8000000000000000)
ADD x5, x11, x18
sd x5, 344(x6)

# Testcase 44:  rs1:x2(0x00000000000000ff), rs2:x16(0x8000000000000001), result rd:x14(0x8000000000000100)
li x2, MASK_XLEN(0x00000000000000ff)
li x16, MASK_XLEN(0x8000000000000001)
ADD x14, x2, x16
sd x14, 352(x6)

# Testcase 45:  rs1:x29(0x00000000000000ff), rs2:x15(0xc365ddeb9173ab42), result rd:x26(0xc365ddeb9173ac41)
li x29, MASK_XLEN(0x00000000000000ff)
li x15, MASK_XLEN(0xc365ddeb9173ab42)
ADD x26, x29, x15
sd x26, 360(x6)

# Testcase 46:  rs1:x31(0x00000000000000ff), rs2:x29(0xfffffffffffffffe), result rd:x15(0x00000000000000fd)
li x31, MASK_XLEN(0x00000000000000ff)
li x29, MASK_XLEN(0xfffffffffffffffe)
ADD x15, x31, x29
sd x15, 368(x6)

# Testcase 47:  rs1:x12(0x00000000000000ff), rs2:x1(0xffffffffffffffff), result rd:x7(0x00000000000000fe)
li x12, MASK_XLEN(0x00000000000000ff)
li x1, MASK_XLEN(0xffffffffffffffff)
ADD x7, x12, x1
sd x7, 376(x6)

# Testcase 48:  rs1:x19(0x624b3e976c52dd14), rs2:x7(0x0000000000000000), result rd:x3(0x624b3e976c52dd14)
li x19, MASK_XLEN(0x624b3e976c52dd14)
li x7, MASK_XLEN(0x0000000000000000)
ADD x3, x19, x7
sd x3, 384(x6)

# Testcase 49:  rs1:x16(0x624b3e976c52dd14), rs2:x5(0x0000000000000001), result rd:x22(0x624b3e976c52dd15)
li x16, MASK_XLEN(0x624b3e976c52dd14)
li x5, MASK_XLEN(0x0000000000000001)
ADD x22, x16, x5
sd x22, 392(x6)

# Testcase 50:  rs1:x3(0x624b3e976c52dd14), rs2:x24(0x0000000000000002), result rd:x17(0x624b3e976c52dd16)
li x3, MASK_XLEN(0x624b3e976c52dd14)
li x24, MASK_XLEN(0x0000000000000002)
ADD x17, x3, x24
sd x17, 400(x6)

# Testcase 51:  rs1:x23(0x624b3e976c52dd14), rs2:x22(0x00000000000000ff), result rd:x31(0x624b3e976c52de13)
li x23, MASK_XLEN(0x624b3e976c52dd14)
li x22, MASK_XLEN(0x00000000000000ff)
ADD x31, x23, x22
sd x31, 408(x6)

# Testcase 52:  rs1:x18(0x624b3e976c52dd14), rs2:x13(0x624b3e976c52dd14), result rd:x20(0xc4967d2ed8a5ba28)
li x18, MASK_XLEN(0x624b3e976c52dd14)
li x13, MASK_XLEN(0x624b3e976c52dd14)
ADD x20, x18, x13
sd x20, 416(x6)

# Testcase 53:  rs1:x9(0x624b3e976c52dd14), rs2:x7(0x7ffffffffffffffe), result rd:x3(0xe24b3e976c52dd12)
li x9, MASK_XLEN(0x624b3e976c52dd14)
li x7, MASK_XLEN(0x7ffffffffffffffe)
ADD x3, x9, x7
sd x3, 424(x6)

# Testcase 54:  rs1:x14(0x624b3e976c52dd14), rs2:x1(0x7fffffffffffffff), result rd:x18(0xe24b3e976c52dd13)
li x14, MASK_XLEN(0x624b3e976c52dd14)
li x1, MASK_XLEN(0x7fffffffffffffff)
ADD x18, x14, x1
sd x18, 432(x6)

# Testcase 55:  rs1:x16(0x624b3e976c52dd14), rs2:x23(0x8000000000000000), result rd:x24(0xe24b3e976c52dd14)
li x16, MASK_XLEN(0x624b3e976c52dd14)
li x23, MASK_XLEN(0x8000000000000000)
ADD x24, x16, x23
sd x24, 440(x6)

# Testcase 56:  rs1:x11(0x624b3e976c52dd14), rs2:x24(0x8000000000000001), result rd:x30(0xe24b3e976c52dd15)
li x11, MASK_XLEN(0x624b3e976c52dd14)
li x24, MASK_XLEN(0x8000000000000001)
ADD x30, x11, x24
sd x30, 448(x6)

# Testcase 57:  rs1:x1(0x624b3e976c52dd14), rs2:x7(0xc365ddeb9173ab42), result rd:x20(0x25b11c82fdc68856)
li x1, MASK_XLEN(0x624b3e976c52dd14)
li x7, MASK_XLEN(0xc365ddeb9173ab42)
ADD x20, x1, x7
sd x20, 456(x6)

# Testcase 58:  rs1:x10(0x624b3e976c52dd14), rs2:x27(0xfffffffffffffffe), result rd:x25(0x624b3e976c52dd12)
li x10, MASK_XLEN(0x624b3e976c52dd14)
li x27, MASK_XLEN(0xfffffffffffffffe)
ADD x25, x10, x27
sd x25, 464(x6)

# Testcase 59:  rs1:x28(0x624b3e976c52dd14), rs2:x29(0xffffffffffffffff), result rd:x25(0x624b3e976c52dd13)
li x28, MASK_XLEN(0x624b3e976c52dd14)
li x29, MASK_XLEN(0xffffffffffffffff)
ADD x25, x28, x29
sd x25, 472(x6)

# Testcase 60:  rs1:x26(0x7ffffffffffffffe), rs2:x14(0x0000000000000000), result rd:x15(0x7ffffffffffffffe)
li x26, MASK_XLEN(0x7ffffffffffffffe)
li x14, MASK_XLEN(0x0000000000000000)
ADD x15, x26, x14
sd x15, 480(x6)

# Testcase 61:  rs1:x23(0x7ffffffffffffffe), rs2:x17(0x0000000000000001), result rd:x23(0x7fffffffffffffff)
li x23, MASK_XLEN(0x7ffffffffffffffe)
li x17, MASK_XLEN(0x0000000000000001)
ADD x23, x23, x17
sd x23, 488(x6)

# Testcase 62:  rs1:x10(0x7ffffffffffffffe), rs2:x3(0x0000000000000002), result rd:x2(0x8000000000000000)
li x10, MASK_XLEN(0x7ffffffffffffffe)
li x3, MASK_XLEN(0x0000000000000002)
ADD x2, x10, x3
sd x2, 496(x6)

# Testcase 63:  rs1:x3(0x7ffffffffffffffe), rs2:x12(0x00000000000000ff), result rd:x13(0x80000000000000fd)
li x3, MASK_XLEN(0x7ffffffffffffffe)
li x12, MASK_XLEN(0x00000000000000ff)
ADD x13, x3, x12
sd x13, 504(x6)

# Testcase 64:  rs1:x21(0x7ffffffffffffffe), rs2:x14(0x624b3e976c52dd14), result rd:x13(0xe24b3e976c52dd12)
li x21, MASK_XLEN(0x7ffffffffffffffe)
li x14, MASK_XLEN(0x624b3e976c52dd14)
ADD x13, x21, x14
sd x13, 512(x6)

# Testcase 65:  rs1:x26(0x7ffffffffffffffe), rs2:x21(0x7ffffffffffffffe), result rd:x23(0xfffffffffffffffc)
li x26, MASK_XLEN(0x7ffffffffffffffe)
li x21, MASK_XLEN(0x7ffffffffffffffe)
ADD x23, x26, x21
sd x23, 520(x6)

# Testcase 66:  rs1:x25(0x7ffffffffffffffe), rs2:x21(0x7fffffffffffffff), result rd:x25(0xfffffffffffffffd)
li x25, MASK_XLEN(0x7ffffffffffffffe)
li x21, MASK_XLEN(0x7fffffffffffffff)
ADD x25, x25, x21
sd x25, 528(x6)

# Testcase 67:  rs1:x8(0x7ffffffffffffffe), rs2:x10(0x8000000000000000), result rd:x16(0xfffffffffffffffe)
li x8, MASK_XLEN(0x7ffffffffffffffe)
li x10, MASK_XLEN(0x8000000000000000)
ADD x16, x8, x10
sd x16, 536(x6)

# Testcase 68:  rs1:x13(0x7ffffffffffffffe), rs2:x18(0x8000000000000001), result rd:x1(0xffffffffffffffff)
li x13, MASK_XLEN(0x7ffffffffffffffe)
li x18, MASK_XLEN(0x8000000000000001)
ADD x1, x13, x18
sd x1, 544(x6)

# Testcase 69:  rs1:x21(0x7ffffffffffffffe), rs2:x14(0xc365ddeb9173ab42), result rd:x21(0x4365ddeb9173ab40)
li x21, MASK_XLEN(0x7ffffffffffffffe)
li x14, MASK_XLEN(0xc365ddeb9173ab42)
ADD x21, x21, x14
sd x21, 552(x6)

# Testcase 70:  rs1:x10(0x7ffffffffffffffe), rs2:x22(0xfffffffffffffffe), result rd:x16(0x7ffffffffffffffc)
li x10, MASK_XLEN(0x7ffffffffffffffe)
li x22, MASK_XLEN(0xfffffffffffffffe)
ADD x16, x10, x22
sd x16, 560(x6)

# Testcase 71:  rs1:x5(0x7ffffffffffffffe), rs2:x13(0xffffffffffffffff), result rd:x22(0x7ffffffffffffffd)
li x5, MASK_XLEN(0x7ffffffffffffffe)
li x13, MASK_XLEN(0xffffffffffffffff)
ADD x22, x5, x13
sd x22, 568(x6)

# Testcase 72:  rs1:x27(0x7fffffffffffffff), rs2:x14(0x0000000000000000), result rd:x30(0x7fffffffffffffff)
li x27, MASK_XLEN(0x7fffffffffffffff)
li x14, MASK_XLEN(0x0000000000000000)
ADD x30, x27, x14
sd x30, 576(x6)

# Testcase 73:  rs1:x31(0x7fffffffffffffff), rs2:x13(0x0000000000000001), result rd:x23(0x8000000000000000)
li x31, MASK_XLEN(0x7fffffffffffffff)
li x13, MASK_XLEN(0x0000000000000001)
ADD x23, x31, x13
sd x23, 584(x6)

# Testcase 74:  rs1:x30(0x7fffffffffffffff), rs2:x29(0x0000000000000002), result rd:x25(0x8000000000000001)
li x30, MASK_XLEN(0x7fffffffffffffff)
li x29, MASK_XLEN(0x0000000000000002)
ADD x25, x30, x29
sd x25, 592(x6)

# Testcase 75:  rs1:x27(0x7fffffffffffffff), rs2:x19(0x00000000000000ff), result rd:x24(0x80000000000000fe)
li x27, MASK_XLEN(0x7fffffffffffffff)
li x19, MASK_XLEN(0x00000000000000ff)
ADD x24, x27, x19
sd x24, 600(x6)

# Testcase 76:  rs1:x20(0x7fffffffffffffff), rs2:x10(0x624b3e976c52dd14), result rd:x16(0xe24b3e976c52dd13)
li x20, MASK_XLEN(0x7fffffffffffffff)
li x10, MASK_XLEN(0x624b3e976c52dd14)
ADD x16, x20, x10
sd x16, 608(x6)

# Testcase 77:  rs1:x18(0x7fffffffffffffff), rs2:x12(0x7ffffffffffffffe), result rd:x10(0xfffffffffffffffd)
li x18, MASK_XLEN(0x7fffffffffffffff)
li x12, MASK_XLEN(0x7ffffffffffffffe)
ADD x10, x18, x12
sd x10, 616(x6)

# Testcase 78:  rs1:x14(0x7fffffffffffffff), rs2:x27(0x7fffffffffffffff), result rd:x30(0xfffffffffffffffe)
li x14, MASK_XLEN(0x7fffffffffffffff)
li x27, MASK_XLEN(0x7fffffffffffffff)
ADD x30, x14, x27
sd x30, 624(x6)

# Testcase 79:  rs1:x19(0x7fffffffffffffff), rs2:x21(0x8000000000000000), result rd:x25(0xffffffffffffffff)
li x19, MASK_XLEN(0x7fffffffffffffff)
li x21, MASK_XLEN(0x8000000000000000)
ADD x25, x19, x21
sd x25, 632(x6)

# Testcase 80:  rs1:x14(0x7fffffffffffffff), rs2:x15(0x8000000000000001), result rd:x31(0x0000000000000000)
li x14, MASK_XLEN(0x7fffffffffffffff)
li x15, MASK_XLEN(0x8000000000000001)
ADD x31, x14, x15
sd x31, 640(x6)

# Testcase 81:  rs1:x15(0x7fffffffffffffff), rs2:x10(0xc365ddeb9173ab42), result rd:x3(0x4365ddeb9173ab41)
li x15, MASK_XLEN(0x7fffffffffffffff)
li x10, MASK_XLEN(0xc365ddeb9173ab42)
ADD x3, x15, x10
sd x3, 648(x6)

# Testcase 82:  rs1:x22(0x7fffffffffffffff), rs2:x8(0xfffffffffffffffe), result rd:x11(0x7ffffffffffffffd)
li x22, MASK_XLEN(0x7fffffffffffffff)
li x8, MASK_XLEN(0xfffffffffffffffe)
ADD x11, x22, x8
sd x11, 656(x6)

# Testcase 83:  rs1:x8(0x7fffffffffffffff), rs2:x13(0xffffffffffffffff), result rd:x1(0x7ffffffffffffffe)
li x8, MASK_XLEN(0x7fffffffffffffff)
li x13, MASK_XLEN(0xffffffffffffffff)
ADD x1, x8, x13
sd x1, 664(x6)

# Testcase 84:  rs1:x20(0x8000000000000000), rs2:x11(0x0000000000000000), result rd:x5(0x8000000000000000)
li x20, MASK_XLEN(0x8000000000000000)
li x11, MASK_XLEN(0x0000000000000000)
ADD x5, x20, x11
sd x5, 672(x6)

# Testcase 85:  rs1:x16(0x8000000000000000), rs2:x29(0x0000000000000001), result rd:x3(0x8000000000000001)
li x16, MASK_XLEN(0x8000000000000000)
li x29, MASK_XLEN(0x0000000000000001)
ADD x3, x16, x29
sd x3, 680(x6)

# Testcase 86:  rs1:x31(0x8000000000000000), rs2:x20(0x0000000000000002), result rd:x2(0x8000000000000002)
li x31, MASK_XLEN(0x8000000000000000)
li x20, MASK_XLEN(0x0000000000000002)
ADD x2, x31, x20
sd x2, 688(x6)

# Testcase 87:  rs1:x1(0x8000000000000000), rs2:x21(0x00000000000000ff), result rd:x17(0x80000000000000ff)
li x1, MASK_XLEN(0x8000000000000000)
li x21, MASK_XLEN(0x00000000000000ff)
ADD x17, x1, x21
sd x17, 696(x6)

# Testcase 88:  rs1:x14(0x8000000000000000), rs2:x22(0x624b3e976c52dd14), result rd:x14(0xe24b3e976c52dd14)
li x14, MASK_XLEN(0x8000000000000000)
li x22, MASK_XLEN(0x624b3e976c52dd14)
ADD x14, x14, x22
sd x14, 704(x6)

# Testcase 89:  rs1:x15(0x8000000000000000), rs2:x10(0x7ffffffffffffffe), result rd:x31(0xfffffffffffffffe)
li x15, MASK_XLEN(0x8000000000000000)
li x10, MASK_XLEN(0x7ffffffffffffffe)
ADD x31, x15, x10
sd x31, 712(x6)

# Testcase 90:  rs1:x29(0x8000000000000000), rs2:x4(0x7fffffffffffffff), result rd:x22(0xffffffffffffffff)
li x29, MASK_XLEN(0x8000000000000000)
li x4, MASK_XLEN(0x7fffffffffffffff)
ADD x22, x29, x4
sd x22, 720(x6)

# Testcase 91:  rs1:x4(0x8000000000000000), rs2:x16(0x8000000000000000), result rd:x27(0x0000000000000000)
li x4, MASK_XLEN(0x8000000000000000)
li x16, MASK_XLEN(0x8000000000000000)
ADD x27, x4, x16
sd x27, 728(x6)

# Testcase 92:  rs1:x24(0x8000000000000000), rs2:x10(0x8000000000000001), result rd:x24(0x0000000000000001)
li x24, MASK_XLEN(0x8000000000000000)
li x10, MASK_XLEN(0x8000000000000001)
ADD x24, x24, x10
sd x24, 736(x6)

# Testcase 93:  rs1:x26(0x8000000000000000), rs2:x10(0xc365ddeb9173ab42), result rd:x10(0x4365ddeb9173ab42)
li x26, MASK_XLEN(0x8000000000000000)
li x10, MASK_XLEN(0xc365ddeb9173ab42)
ADD x10, x26, x10
sd x10, 744(x6)

# Testcase 94:  rs1:x13(0x8000000000000000), rs2:x2(0xfffffffffffffffe), result rd:x19(0x7ffffffffffffffe)
li x13, MASK_XLEN(0x8000000000000000)
li x2, MASK_XLEN(0xfffffffffffffffe)
ADD x19, x13, x2
sd x19, 752(x6)

# Testcase 95:  rs1:x27(0x8000000000000000), rs2:x9(0xffffffffffffffff), result rd:x11(0x7fffffffffffffff)
li x27, MASK_XLEN(0x8000000000000000)
li x9, MASK_XLEN(0xffffffffffffffff)
ADD x11, x27, x9
sd x11, 760(x6)

# Testcase 96:  rs1:x25(0x8000000000000001), rs2:x15(0x0000000000000000), result rd:x3(0x8000000000000001)
li x25, MASK_XLEN(0x8000000000000001)
li x15, MASK_XLEN(0x0000000000000000)
ADD x3, x25, x15
sd x3, 768(x6)

# Testcase 97:  rs1:x2(0x8000000000000001), rs2:x25(0x0000000000000001), result rd:x21(0x8000000000000002)
li x2, MASK_XLEN(0x8000000000000001)
li x25, MASK_XLEN(0x0000000000000001)
ADD x21, x2, x25
sd x21, 776(x6)

# Testcase 98:  rs1:x23(0x8000000000000001), rs2:x27(0x0000000000000002), result rd:x10(0x8000000000000003)
li x23, MASK_XLEN(0x8000000000000001)
li x27, MASK_XLEN(0x0000000000000002)
ADD x10, x23, x27
sd x10, 784(x6)

# Testcase 99:  rs1:x8(0x8000000000000001), rs2:x30(0x00000000000000ff), result rd:x30(0x8000000000000100)
li x8, MASK_XLEN(0x8000000000000001)
li x30, MASK_XLEN(0x00000000000000ff)
ADD x30, x8, x30
sd x30, 792(x6)

# Testcase 100:  rs1:x15(0x8000000000000001), rs2:x21(0x624b3e976c52dd14), result rd:x10(0xe24b3e976c52dd15)
li x15, MASK_XLEN(0x8000000000000001)
li x21, MASK_XLEN(0x624b3e976c52dd14)
ADD x10, x15, x21
sd x10, 800(x6)

# Testcase 101:  rs1:x18(0x8000000000000001), rs2:x30(0x7ffffffffffffffe), result rd:x7(0xffffffffffffffff)
li x18, MASK_XLEN(0x8000000000000001)
li x30, MASK_XLEN(0x7ffffffffffffffe)
ADD x7, x18, x30
sd x7, 808(x6)

# Testcase 102:  rs1:x13(0x8000000000000001), rs2:x29(0x7fffffffffffffff), result rd:x3(0x0000000000000000)
li x13, MASK_XLEN(0x8000000000000001)
li x29, MASK_XLEN(0x7fffffffffffffff)
ADD x3, x13, x29
sd x3, 816(x6)

# Testcase 103:  rs1:x14(0x8000000000000001), rs2:x2(0x8000000000000000), result rd:x2(0x0000000000000001)
li x14, MASK_XLEN(0x8000000000000001)
li x2, MASK_XLEN(0x8000000000000000)
ADD x2, x14, x2
sd x2, 824(x6)

# Testcase 104:  rs1:x26(0x8000000000000001), rs2:x30(0x8000000000000001), result rd:x3(0x0000000000000002)
li x26, MASK_XLEN(0x8000000000000001)
li x30, MASK_XLEN(0x8000000000000001)
ADD x3, x26, x30
sd x3, 832(x6)

# Testcase 105:  rs1:x12(0x8000000000000001), rs2:x1(0xc365ddeb9173ab42), result rd:x10(0x4365ddeb9173ab43)
li x12, MASK_XLEN(0x8000000000000001)
li x1, MASK_XLEN(0xc365ddeb9173ab42)
ADD x10, x12, x1
sd x10, 840(x6)

# Testcase 106:  rs1:x10(0x8000000000000001), rs2:x2(0xfffffffffffffffe), result rd:x1(0x7fffffffffffffff)
li x10, MASK_XLEN(0x8000000000000001)
li x2, MASK_XLEN(0xfffffffffffffffe)
ADD x1, x10, x2
sd x1, 848(x6)

# Testcase 107:  rs1:x2(0x8000000000000001), rs2:x20(0xffffffffffffffff), result rd:x2(0x8000000000000000)
li x2, MASK_XLEN(0x8000000000000001)
li x20, MASK_XLEN(0xffffffffffffffff)
ADD x2, x2, x20
sd x2, 856(x6)

# Testcase 108:  rs1:x5(0xc365ddeb9173ab42), rs2:x28(0x0000000000000000), result rd:x20(0xc365ddeb9173ab42)
li x5, MASK_XLEN(0xc365ddeb9173ab42)
li x28, MASK_XLEN(0x0000000000000000)
ADD x20, x5, x28
sd x20, 864(x6)

# Testcase 109:  rs1:x21(0xc365ddeb9173ab42), rs2:x3(0x0000000000000001), result rd:x19(0xc365ddeb9173ab43)
li x21, MASK_XLEN(0xc365ddeb9173ab42)
li x3, MASK_XLEN(0x0000000000000001)
ADD x19, x21, x3
sd x19, 872(x6)

# Testcase 110:  rs1:x5(0xc365ddeb9173ab42), rs2:x1(0x0000000000000002), result rd:x31(0xc365ddeb9173ab44)
li x5, MASK_XLEN(0xc365ddeb9173ab42)
li x1, MASK_XLEN(0x0000000000000002)
ADD x31, x5, x1
sd x31, 880(x6)

# Testcase 111:  rs1:x24(0xc365ddeb9173ab42), rs2:x18(0x00000000000000ff), result rd:x5(0xc365ddeb9173ac41)
li x24, MASK_XLEN(0xc365ddeb9173ab42)
li x18, MASK_XLEN(0x00000000000000ff)
ADD x5, x24, x18
sd x5, 888(x6)

# Testcase 112:  rs1:x26(0xc365ddeb9173ab42), rs2:x4(0x624b3e976c52dd14), result rd:x3(0x25b11c82fdc68856)
li x26, MASK_XLEN(0xc365ddeb9173ab42)
li x4, MASK_XLEN(0x624b3e976c52dd14)
ADD x3, x26, x4
sd x3, 896(x6)

# Testcase 113:  rs1:x23(0xc365ddeb9173ab42), rs2:x3(0x7ffffffffffffffe), result rd:x20(0x4365ddeb9173ab40)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
li x3, MASK_XLEN(0x7ffffffffffffffe)
ADD x20, x23, x3
sd x20, 904(x6)

# Testcase 114:  rs1:x25(0xc365ddeb9173ab42), rs2:x22(0x7fffffffffffffff), result rd:x4(0x4365ddeb9173ab41)
li x25, MASK_XLEN(0xc365ddeb9173ab42)
li x22, MASK_XLEN(0x7fffffffffffffff)
ADD x4, x25, x22
sd x4, 912(x6)

# Testcase 115:  rs1:x7(0xc365ddeb9173ab42), rs2:x27(0x8000000000000000), result rd:x4(0x4365ddeb9173ab42)
li x7, MASK_XLEN(0xc365ddeb9173ab42)
li x27, MASK_XLEN(0x8000000000000000)
ADD x4, x7, x27
sd x4, 920(x6)

# Testcase 116:  rs1:x30(0xc365ddeb9173ab42), rs2:x16(0x8000000000000001), result rd:x14(0x4365ddeb9173ab43)
li x30, MASK_XLEN(0xc365ddeb9173ab42)
li x16, MASK_XLEN(0x8000000000000001)
ADD x14, x30, x16
sd x14, 928(x6)

# Testcase 117:  rs1:x3(0xc365ddeb9173ab42), rs2:x4(0xc365ddeb9173ab42), result rd:x16(0x86cbbbd722e75684)
li x3, MASK_XLEN(0xc365ddeb9173ab42)
li x4, MASK_XLEN(0xc365ddeb9173ab42)
ADD x16, x3, x4
sd x16, 936(x6)

# Testcase 118:  rs1:x23(0xc365ddeb9173ab42), rs2:x28(0xfffffffffffffffe), result rd:x15(0xc365ddeb9173ab40)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
li x28, MASK_XLEN(0xfffffffffffffffe)
ADD x15, x23, x28
sd x15, 944(x6)

# Testcase 119:  rs1:x17(0xc365ddeb9173ab42), rs2:x24(0xffffffffffffffff), result rd:x29(0xc365ddeb9173ab41)
li x17, MASK_XLEN(0xc365ddeb9173ab42)
li x24, MASK_XLEN(0xffffffffffffffff)
ADD x29, x17, x24
sd x29, 952(x6)

# Testcase 120:  rs1:x5(0xfffffffffffffffe), rs2:x28(0x0000000000000000), result rd:x12(0xfffffffffffffffe)
li x5, MASK_XLEN(0xfffffffffffffffe)
li x28, MASK_XLEN(0x0000000000000000)
ADD x12, x5, x28
sd x12, 960(x6)

# Testcase 121:  rs1:x24(0xfffffffffffffffe), rs2:x28(0x0000000000000001), result rd:x14(0xffffffffffffffff)
li x24, MASK_XLEN(0xfffffffffffffffe)
li x28, MASK_XLEN(0x0000000000000001)
ADD x14, x24, x28
sd x14, 968(x6)

# Testcase 122:  rs1:x17(0xfffffffffffffffe), rs2:x5(0x0000000000000002), result rd:x3(0x0000000000000000)
li x17, MASK_XLEN(0xfffffffffffffffe)
li x5, MASK_XLEN(0x0000000000000002)
ADD x3, x17, x5
sd x3, 976(x6)

# Testcase 123:  rs1:x21(0xfffffffffffffffe), rs2:x17(0x00000000000000ff), result rd:x31(0x00000000000000fd)
li x21, MASK_XLEN(0xfffffffffffffffe)
li x17, MASK_XLEN(0x00000000000000ff)
ADD x31, x21, x17
sd x31, 984(x6)

# Testcase 124:  rs1:x2(0xfffffffffffffffe), rs2:x24(0x624b3e976c52dd14), result rd:x29(0x624b3e976c52dd12)
li x2, MASK_XLEN(0xfffffffffffffffe)
li x24, MASK_XLEN(0x624b3e976c52dd14)
ADD x29, x2, x24
sd x29, 992(x6)

# Testcase 125:  rs1:x18(0xfffffffffffffffe), rs2:x8(0x7ffffffffffffffe), result rd:x4(0x7ffffffffffffffc)
li x18, MASK_XLEN(0xfffffffffffffffe)
li x8, MASK_XLEN(0x7ffffffffffffffe)
ADD x4, x18, x8
sd x4, 1000(x6)

# Testcase 126:  rs1:x24(0xfffffffffffffffe), rs2:x26(0x7fffffffffffffff), result rd:x13(0x7ffffffffffffffd)
li x24, MASK_XLEN(0xfffffffffffffffe)
li x26, MASK_XLEN(0x7fffffffffffffff)
ADD x13, x24, x26
sd x13, 1008(x6)

# Testcase 127:  rs1:x29(0xfffffffffffffffe), rs2:x12(0x8000000000000000), result rd:x17(0x7ffffffffffffffe)
li x29, MASK_XLEN(0xfffffffffffffffe)
li x12, MASK_XLEN(0x8000000000000000)
ADD x17, x29, x12
sd x17, 1016(x6)

# Testcase 128:  rs1:x30(0xfffffffffffffffe), rs2:x11(0x8000000000000001), result rd:x18(0x7fffffffffffffff)
li x30, MASK_XLEN(0xfffffffffffffffe)
li x11, MASK_XLEN(0x8000000000000001)
ADD x18, x30, x11
sd x18, 1024(x6)

# Testcase 129:  rs1:x23(0xfffffffffffffffe), rs2:x19(0xc365ddeb9173ab42), result rd:x18(0xc365ddeb9173ab40)
li x23, MASK_XLEN(0xfffffffffffffffe)
li x19, MASK_XLEN(0xc365ddeb9173ab42)
ADD x18, x23, x19
sd x18, 1032(x6)

# Testcase 130:  rs1:x13(0xfffffffffffffffe), rs2:x30(0xfffffffffffffffe), result rd:x10(0xfffffffffffffffc)
li x13, MASK_XLEN(0xfffffffffffffffe)
li x30, MASK_XLEN(0xfffffffffffffffe)
ADD x10, x13, x30
sd x10, 1040(x6)

# Testcase 131:  rs1:x8(0xfffffffffffffffe), rs2:x19(0xffffffffffffffff), result rd:x23(0xfffffffffffffffd)
li x8, MASK_XLEN(0xfffffffffffffffe)
li x19, MASK_XLEN(0xffffffffffffffff)
ADD x23, x8, x19
sd x23, 1048(x6)

# Testcase 132:  rs1:x3(0xffffffffffffffff), rs2:x5(0x0000000000000000), result rd:x20(0xffffffffffffffff)
li x3, MASK_XLEN(0xffffffffffffffff)
li x5, MASK_XLEN(0x0000000000000000)
ADD x20, x3, x5
sd x20, 1056(x6)

# Testcase 133:  rs1:x13(0xffffffffffffffff), rs2:x28(0x0000000000000001), result rd:x25(0x0000000000000000)
li x13, MASK_XLEN(0xffffffffffffffff)
li x28, MASK_XLEN(0x0000000000000001)
ADD x25, x13, x28
sd x25, 1064(x6)

# Testcase 134:  rs1:x31(0xffffffffffffffff), rs2:x12(0x0000000000000002), result rd:x24(0x0000000000000001)
li x31, MASK_XLEN(0xffffffffffffffff)
li x12, MASK_XLEN(0x0000000000000002)
ADD x24, x31, x12
sd x24, 1072(x6)

# Testcase 135:  rs1:x10(0xffffffffffffffff), rs2:x31(0x00000000000000ff), result rd:x12(0x00000000000000fe)
li x10, MASK_XLEN(0xffffffffffffffff)
li x31, MASK_XLEN(0x00000000000000ff)
ADD x12, x10, x31
sd x12, 1080(x6)

# Testcase 136:  rs1:x17(0xffffffffffffffff), rs2:x12(0x624b3e976c52dd14), result rd:x1(0x624b3e976c52dd13)
li x17, MASK_XLEN(0xffffffffffffffff)
li x12, MASK_XLEN(0x624b3e976c52dd14)
ADD x1, x17, x12
sd x1, 1088(x6)

# Testcase 137:  rs1:x9(0xffffffffffffffff), rs2:x24(0x7ffffffffffffffe), result rd:x22(0x7ffffffffffffffd)
li x9, MASK_XLEN(0xffffffffffffffff)
li x24, MASK_XLEN(0x7ffffffffffffffe)
ADD x22, x9, x24
sd x22, 1096(x6)

# Testcase 138:  rs1:x23(0xffffffffffffffff), rs2:x7(0x7fffffffffffffff), result rd:x21(0x7ffffffffffffffe)
li x23, MASK_XLEN(0xffffffffffffffff)
li x7, MASK_XLEN(0x7fffffffffffffff)
ADD x21, x23, x7
sd x21, 1104(x6)

# Testcase 139:  rs1:x4(0xffffffffffffffff), rs2:x27(0x8000000000000000), result rd:x16(0x7fffffffffffffff)
li x4, MASK_XLEN(0xffffffffffffffff)
li x27, MASK_XLEN(0x8000000000000000)
ADD x16, x4, x27
sd x16, 1112(x6)

# Testcase 140:  rs1:x24(0xffffffffffffffff), rs2:x16(0x8000000000000001), result rd:x22(0x8000000000000000)
li x24, MASK_XLEN(0xffffffffffffffff)
li x16, MASK_XLEN(0x8000000000000001)
ADD x22, x24, x16
sd x22, 1120(x6)

# Testcase 141:  rs1:x5(0xffffffffffffffff), rs2:x9(0xc365ddeb9173ab42), result rd:x31(0xc365ddeb9173ab41)
li x5, MASK_XLEN(0xffffffffffffffff)
li x9, MASK_XLEN(0xc365ddeb9173ab42)
ADD x31, x5, x9
sd x31, 1128(x6)

# Testcase 142:  rs1:x9(0xffffffffffffffff), rs2:x27(0xfffffffffffffffe), result rd:x5(0xfffffffffffffffd)
li x9, MASK_XLEN(0xffffffffffffffff)
li x27, MASK_XLEN(0xfffffffffffffffe)
ADD x5, x9, x27
sd x5, 1136(x6)

# Testcase 143:  rs1:x30(0xffffffffffffffff), rs2:x22(0xffffffffffffffff), result rd:x12(0xfffffffffffffffe)
li x30, MASK_XLEN(0xffffffffffffffff)
li x22, MASK_XLEN(0xffffffffffffffff)
ADD x12, x30, x22
sd x12, 1144(x6)

# Testcase 144:  rs1:x21(0xbf3ba58ed02fe513), rs2:x4(0x333a1d7152d1de24), result rd:x17(0xf275c3002301c337)
li x21, MASK_XLEN(0xbf3ba58ed02fe513)
li x4, MASK_XLEN(0x333a1d7152d1de24)
ADD x17, x21, x4
sd x17, 1152(x6)

# Testcase 145:  rs1:x9(0x7eb78350cb110ef8), rs2:x11(0xa1ddc5a325053d91), result rd:x7(0x209548f3f0164c89)
li x9, MASK_XLEN(0x7eb78350cb110ef8)
li x11, MASK_XLEN(0xa1ddc5a325053d91)
ADD x7, x9, x11
sd x7, 1160(x6)

# Testcase 146:  rs1:x23(0x1da11d7aa281becd), rs2:x8(0xabbf9e6d9e19e188), result rd:x12(0xc960bbe8409ba055)
li x23, MASK_XLEN(0x1da11d7aa281becd)
li x8, MASK_XLEN(0xabbf9e6d9e19e188)
ADD x12, x23, x8
sd x12, 1168(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-ADD.S
// David_Harris@hmc.edu & Katherine Parry

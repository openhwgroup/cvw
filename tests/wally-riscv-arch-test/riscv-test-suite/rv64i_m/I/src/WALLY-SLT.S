///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.536777//
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

# Testcase 0:  rs1:x3(0x0000000000000000), rs2:x5(0x0000000000000000), result rd:x30(0x0000000000000000)
li x3, MASK_XLEN(0x0000000000000000)
li x5, MASK_XLEN(0x0000000000000000)
SLT x30, x3, x5
sd x30, 0(x6)

# Testcase 1:  rs1:x25(0x0000000000000000), rs2:x15(0x0000000000000001), result rd:x14(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000000)
li x15, MASK_XLEN(0x0000000000000001)
SLT x14, x25, x15
sd x14, 8(x6)

# Testcase 2:  rs1:x4(0x0000000000000000), rs2:x12(0x0000000000000002), result rd:x25(0x0000000000000001)
li x4, MASK_XLEN(0x0000000000000000)
li x12, MASK_XLEN(0x0000000000000002)
SLT x25, x4, x12
sd x25, 16(x6)

# Testcase 3:  rs1:x8(0x0000000000000000), rs2:x4(0x00000000000000ff), result rd:x11(0x0000000000000001)
li x8, MASK_XLEN(0x0000000000000000)
li x4, MASK_XLEN(0x00000000000000ff)
SLT x11, x8, x4
sd x11, 24(x6)

# Testcase 4:  rs1:x5(0x0000000000000000), rs2:x7(0x624b3e976c52dd14), result rd:x8(0x0000000000000001)
li x5, MASK_XLEN(0x0000000000000000)
li x7, MASK_XLEN(0x624b3e976c52dd14)
SLT x8, x5, x7
sd x8, 32(x6)

# Testcase 5:  rs1:x20(0x0000000000000000), rs2:x18(0x7ffffffffffffffe), result rd:x11(0x0000000000000001)
li x20, MASK_XLEN(0x0000000000000000)
li x18, MASK_XLEN(0x7ffffffffffffffe)
SLT x11, x20, x18
sd x11, 40(x6)

# Testcase 6:  rs1:x22(0x0000000000000000), rs2:x16(0x7fffffffffffffff), result rd:x28(0x0000000000000001)
li x22, MASK_XLEN(0x0000000000000000)
li x16, MASK_XLEN(0x7fffffffffffffff)
SLT x28, x22, x16
sd x28, 48(x6)

# Testcase 7:  rs1:x11(0x0000000000000000), rs2:x19(0x8000000000000000), result rd:x21(0x0000000000000000)
li x11, MASK_XLEN(0x0000000000000000)
li x19, MASK_XLEN(0x8000000000000000)
SLT x21, x11, x19
sd x21, 56(x6)

# Testcase 8:  rs1:x28(0x0000000000000000), rs2:x16(0x8000000000000001), result rd:x29(0x0000000000000000)
li x28, MASK_XLEN(0x0000000000000000)
li x16, MASK_XLEN(0x8000000000000001)
SLT x29, x28, x16
sd x29, 64(x6)

# Testcase 9:  rs1:x17(0x0000000000000000), rs2:x22(0xc365ddeb9173ab42), result rd:x29(0x0000000000000000)
li x17, MASK_XLEN(0x0000000000000000)
li x22, MASK_XLEN(0xc365ddeb9173ab42)
SLT x29, x17, x22
sd x29, 72(x6)

# Testcase 10:  rs1:x9(0x0000000000000000), rs2:x25(0xfffffffffffffffe), result rd:x10(0x0000000000000000)
li x9, MASK_XLEN(0x0000000000000000)
li x25, MASK_XLEN(0xfffffffffffffffe)
SLT x10, x9, x25
sd x10, 80(x6)

# Testcase 11:  rs1:x1(0x0000000000000000), rs2:x20(0xffffffffffffffff), result rd:x22(0x0000000000000000)
li x1, MASK_XLEN(0x0000000000000000)
li x20, MASK_XLEN(0xffffffffffffffff)
SLT x22, x1, x20
sd x22, 88(x6)

# Testcase 12:  rs1:x9(0x0000000000000001), rs2:x7(0x0000000000000000), result rd:x17(0x0000000000000000)
li x9, MASK_XLEN(0x0000000000000001)
li x7, MASK_XLEN(0x0000000000000000)
SLT x17, x9, x7
sd x17, 96(x6)

# Testcase 13:  rs1:x18(0x0000000000000001), rs2:x23(0x0000000000000001), result rd:x27(0x0000000000000000)
li x18, MASK_XLEN(0x0000000000000001)
li x23, MASK_XLEN(0x0000000000000001)
SLT x27, x18, x23
sd x27, 104(x6)

# Testcase 14:  rs1:x4(0x0000000000000001), rs2:x10(0x0000000000000002), result rd:x15(0x0000000000000001)
li x4, MASK_XLEN(0x0000000000000001)
li x10, MASK_XLEN(0x0000000000000002)
SLT x15, x4, x10
sd x15, 112(x6)

# Testcase 15:  rs1:x15(0x0000000000000001), rs2:x17(0x00000000000000ff), result rd:x17(0x0000000000000001)
li x15, MASK_XLEN(0x0000000000000001)
li x17, MASK_XLEN(0x00000000000000ff)
SLT x17, x15, x17
sd x17, 120(x6)

# Testcase 16:  rs1:x18(0x0000000000000001), rs2:x20(0x624b3e976c52dd14), result rd:x19(0x0000000000000001)
li x18, MASK_XLEN(0x0000000000000001)
li x20, MASK_XLEN(0x624b3e976c52dd14)
SLT x19, x18, x20
sd x19, 128(x6)

# Testcase 17:  rs1:x18(0x0000000000000001), rs2:x24(0x7ffffffffffffffe), result rd:x22(0x0000000000000001)
li x18, MASK_XLEN(0x0000000000000001)
li x24, MASK_XLEN(0x7ffffffffffffffe)
SLT x22, x18, x24
sd x22, 136(x6)

# Testcase 18:  rs1:x13(0x0000000000000001), rs2:x28(0x7fffffffffffffff), result rd:x14(0x0000000000000001)
li x13, MASK_XLEN(0x0000000000000001)
li x28, MASK_XLEN(0x7fffffffffffffff)
SLT x14, x13, x28
sd x14, 144(x6)

# Testcase 19:  rs1:x11(0x0000000000000001), rs2:x20(0x8000000000000000), result rd:x26(0x0000000000000000)
li x11, MASK_XLEN(0x0000000000000001)
li x20, MASK_XLEN(0x8000000000000000)
SLT x26, x11, x20
sd x26, 152(x6)

# Testcase 20:  rs1:x11(0x0000000000000001), rs2:x8(0x8000000000000001), result rd:x11(0x0000000000000000)
li x11, MASK_XLEN(0x0000000000000001)
li x8, MASK_XLEN(0x8000000000000001)
SLT x11, x11, x8
sd x11, 160(x6)

# Testcase 21:  rs1:x16(0x0000000000000001), rs2:x5(0xc365ddeb9173ab42), result rd:x17(0x0000000000000000)
li x16, MASK_XLEN(0x0000000000000001)
li x5, MASK_XLEN(0xc365ddeb9173ab42)
SLT x17, x16, x5
sd x17, 168(x6)

# Testcase 22:  rs1:x1(0x0000000000000001), rs2:x24(0xfffffffffffffffe), result rd:x16(0x0000000000000000)
li x1, MASK_XLEN(0x0000000000000001)
li x24, MASK_XLEN(0xfffffffffffffffe)
SLT x16, x1, x24
sd x16, 176(x6)

# Testcase 23:  rs1:x26(0x0000000000000001), rs2:x5(0xffffffffffffffff), result rd:x1(0x0000000000000000)
li x26, MASK_XLEN(0x0000000000000001)
li x5, MASK_XLEN(0xffffffffffffffff)
SLT x1, x26, x5
sd x1, 184(x6)

# Testcase 24:  rs1:x3(0x0000000000000002), rs2:x18(0x0000000000000000), result rd:x28(0x0000000000000000)
li x3, MASK_XLEN(0x0000000000000002)
li x18, MASK_XLEN(0x0000000000000000)
SLT x28, x3, x18
sd x28, 192(x6)

# Testcase 25:  rs1:x1(0x0000000000000002), rs2:x28(0x0000000000000001), result rd:x5(0x0000000000000000)
li x1, MASK_XLEN(0x0000000000000002)
li x28, MASK_XLEN(0x0000000000000001)
SLT x5, x1, x28
sd x5, 200(x6)

# Testcase 26:  rs1:x25(0x0000000000000002), rs2:x28(0x0000000000000002), result rd:x4(0x0000000000000000)
li x25, MASK_XLEN(0x0000000000000002)
li x28, MASK_XLEN(0x0000000000000002)
SLT x4, x25, x28
sd x4, 208(x6)

# Testcase 27:  rs1:x2(0x0000000000000002), rs2:x11(0x00000000000000ff), result rd:x30(0x0000000000000001)
li x2, MASK_XLEN(0x0000000000000002)
li x11, MASK_XLEN(0x00000000000000ff)
SLT x30, x2, x11
sd x30, 216(x6)

# Testcase 28:  rs1:x10(0x0000000000000002), rs2:x22(0x624b3e976c52dd14), result rd:x7(0x0000000000000001)
li x10, MASK_XLEN(0x0000000000000002)
li x22, MASK_XLEN(0x624b3e976c52dd14)
SLT x7, x10, x22
sd x7, 224(x6)

# Testcase 29:  rs1:x25(0x0000000000000002), rs2:x3(0x7ffffffffffffffe), result rd:x22(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000002)
li x3, MASK_XLEN(0x7ffffffffffffffe)
SLT x22, x25, x3
sd x22, 232(x6)

# Testcase 30:  rs1:x2(0x0000000000000002), rs2:x25(0x7fffffffffffffff), result rd:x8(0x0000000000000001)
li x2, MASK_XLEN(0x0000000000000002)
li x25, MASK_XLEN(0x7fffffffffffffff)
SLT x8, x2, x25
sd x8, 240(x6)

# Testcase 31:  rs1:x26(0x0000000000000002), rs2:x12(0x8000000000000000), result rd:x31(0x0000000000000000)
li x26, MASK_XLEN(0x0000000000000002)
li x12, MASK_XLEN(0x8000000000000000)
SLT x31, x26, x12
sd x31, 248(x6)

# Testcase 32:  rs1:x13(0x0000000000000002), rs2:x21(0x8000000000000001), result rd:x31(0x0000000000000000)
li x13, MASK_XLEN(0x0000000000000002)
li x21, MASK_XLEN(0x8000000000000001)
SLT x31, x13, x21
sd x31, 256(x6)

# Testcase 33:  rs1:x17(0x0000000000000002), rs2:x20(0xc365ddeb9173ab42), result rd:x22(0x0000000000000000)
li x17, MASK_XLEN(0x0000000000000002)
li x20, MASK_XLEN(0xc365ddeb9173ab42)
SLT x22, x17, x20
sd x22, 264(x6)

# Testcase 34:  rs1:x12(0x0000000000000002), rs2:x29(0xfffffffffffffffe), result rd:x14(0x0000000000000000)
li x12, MASK_XLEN(0x0000000000000002)
li x29, MASK_XLEN(0xfffffffffffffffe)
SLT x14, x12, x29
sd x14, 272(x6)

# Testcase 35:  rs1:x7(0x0000000000000002), rs2:x13(0xffffffffffffffff), result rd:x24(0x0000000000000000)
li x7, MASK_XLEN(0x0000000000000002)
li x13, MASK_XLEN(0xffffffffffffffff)
SLT x24, x7, x13
sd x24, 280(x6)

# Testcase 36:  rs1:x2(0x00000000000000ff), rs2:x20(0x0000000000000000), result rd:x24(0x0000000000000000)
li x2, MASK_XLEN(0x00000000000000ff)
li x20, MASK_XLEN(0x0000000000000000)
SLT x24, x2, x20
sd x24, 288(x6)

# Testcase 37:  rs1:x8(0x00000000000000ff), rs2:x19(0x0000000000000001), result rd:x1(0x0000000000000000)
li x8, MASK_XLEN(0x00000000000000ff)
li x19, MASK_XLEN(0x0000000000000001)
SLT x1, x8, x19
sd x1, 296(x6)

# Testcase 38:  rs1:x29(0x00000000000000ff), rs2:x15(0x0000000000000002), result rd:x24(0x0000000000000000)
li x29, MASK_XLEN(0x00000000000000ff)
li x15, MASK_XLEN(0x0000000000000002)
SLT x24, x29, x15
sd x24, 304(x6)

# Testcase 39:  rs1:x1(0x00000000000000ff), rs2:x14(0x00000000000000ff), result rd:x5(0x0000000000000000)
li x1, MASK_XLEN(0x00000000000000ff)
li x14, MASK_XLEN(0x00000000000000ff)
SLT x5, x1, x14
sd x5, 312(x6)

# Testcase 40:  rs1:x25(0x00000000000000ff), rs2:x7(0x624b3e976c52dd14), result rd:x3(0x0000000000000001)
li x25, MASK_XLEN(0x00000000000000ff)
li x7, MASK_XLEN(0x624b3e976c52dd14)
SLT x3, x25, x7
sd x3, 320(x6)

# Testcase 41:  rs1:x19(0x00000000000000ff), rs2:x21(0x7ffffffffffffffe), result rd:x5(0x0000000000000001)
li x19, MASK_XLEN(0x00000000000000ff)
li x21, MASK_XLEN(0x7ffffffffffffffe)
SLT x5, x19, x21
sd x5, 328(x6)

# Testcase 42:  rs1:x26(0x00000000000000ff), rs2:x11(0x7fffffffffffffff), result rd:x25(0x0000000000000001)
li x26, MASK_XLEN(0x00000000000000ff)
li x11, MASK_XLEN(0x7fffffffffffffff)
SLT x25, x26, x11
sd x25, 336(x6)

# Testcase 43:  rs1:x9(0x00000000000000ff), rs2:x29(0x8000000000000000), result rd:x10(0x0000000000000000)
li x9, MASK_XLEN(0x00000000000000ff)
li x29, MASK_XLEN(0x8000000000000000)
SLT x10, x9, x29
sd x10, 344(x6)

# Testcase 44:  rs1:x25(0x00000000000000ff), rs2:x29(0x8000000000000001), result rd:x15(0x0000000000000000)
li x25, MASK_XLEN(0x00000000000000ff)
li x29, MASK_XLEN(0x8000000000000001)
SLT x15, x25, x29
sd x15, 352(x6)

# Testcase 45:  rs1:x11(0x00000000000000ff), rs2:x17(0xc365ddeb9173ab42), result rd:x14(0x0000000000000000)
li x11, MASK_XLEN(0x00000000000000ff)
li x17, MASK_XLEN(0xc365ddeb9173ab42)
SLT x14, x11, x17
sd x14, 360(x6)

# Testcase 46:  rs1:x16(0x00000000000000ff), rs2:x11(0xfffffffffffffffe), result rd:x26(0x0000000000000000)
li x16, MASK_XLEN(0x00000000000000ff)
li x11, MASK_XLEN(0xfffffffffffffffe)
SLT x26, x16, x11
sd x26, 368(x6)

# Testcase 47:  rs1:x9(0x00000000000000ff), rs2:x17(0xffffffffffffffff), result rd:x28(0x0000000000000000)
li x9, MASK_XLEN(0x00000000000000ff)
li x17, MASK_XLEN(0xffffffffffffffff)
SLT x28, x9, x17
sd x28, 376(x6)

# Testcase 48:  rs1:x10(0x624b3e976c52dd14), rs2:x15(0x0000000000000000), result rd:x26(0x0000000000000000)
li x10, MASK_XLEN(0x624b3e976c52dd14)
li x15, MASK_XLEN(0x0000000000000000)
SLT x26, x10, x15
sd x26, 384(x6)

# Testcase 49:  rs1:x18(0x624b3e976c52dd14), rs2:x11(0x0000000000000001), result rd:x13(0x0000000000000000)
li x18, MASK_XLEN(0x624b3e976c52dd14)
li x11, MASK_XLEN(0x0000000000000001)
SLT x13, x18, x11
sd x13, 392(x6)

# Testcase 50:  rs1:x22(0x624b3e976c52dd14), rs2:x11(0x0000000000000002), result rd:x30(0x0000000000000000)
li x22, MASK_XLEN(0x624b3e976c52dd14)
li x11, MASK_XLEN(0x0000000000000002)
SLT x30, x22, x11
sd x30, 400(x6)

# Testcase 51:  rs1:x13(0x624b3e976c52dd14), rs2:x29(0x00000000000000ff), result rd:x25(0x0000000000000000)
li x13, MASK_XLEN(0x624b3e976c52dd14)
li x29, MASK_XLEN(0x00000000000000ff)
SLT x25, x13, x29
sd x25, 408(x6)

# Testcase 52:  rs1:x9(0x624b3e976c52dd14), rs2:x30(0x624b3e976c52dd14), result rd:x23(0x0000000000000000)
li x9, MASK_XLEN(0x624b3e976c52dd14)
li x30, MASK_XLEN(0x624b3e976c52dd14)
SLT x23, x9, x30
sd x23, 416(x6)

# Testcase 53:  rs1:x1(0x624b3e976c52dd14), rs2:x7(0x7ffffffffffffffe), result rd:x27(0x0000000000000001)
li x1, MASK_XLEN(0x624b3e976c52dd14)
li x7, MASK_XLEN(0x7ffffffffffffffe)
SLT x27, x1, x7
sd x27, 424(x6)

# Testcase 54:  rs1:x30(0x624b3e976c52dd14), rs2:x23(0x7fffffffffffffff), result rd:x15(0x0000000000000001)
li x30, MASK_XLEN(0x624b3e976c52dd14)
li x23, MASK_XLEN(0x7fffffffffffffff)
SLT x15, x30, x23
sd x15, 432(x6)

# Testcase 55:  rs1:x25(0x624b3e976c52dd14), rs2:x10(0x8000000000000000), result rd:x13(0x0000000000000000)
li x25, MASK_XLEN(0x624b3e976c52dd14)
li x10, MASK_XLEN(0x8000000000000000)
SLT x13, x25, x10
sd x13, 440(x6)

# Testcase 56:  rs1:x14(0x624b3e976c52dd14), rs2:x24(0x8000000000000001), result rd:x24(0x0000000000000000)
li x14, MASK_XLEN(0x624b3e976c52dd14)
li x24, MASK_XLEN(0x8000000000000001)
SLT x24, x14, x24
sd x24, 448(x6)

# Testcase 57:  rs1:x27(0x624b3e976c52dd14), rs2:x28(0xc365ddeb9173ab42), result rd:x30(0x0000000000000000)
li x27, MASK_XLEN(0x624b3e976c52dd14)
li x28, MASK_XLEN(0xc365ddeb9173ab42)
SLT x30, x27, x28
sd x30, 456(x6)

# Testcase 58:  rs1:x27(0x624b3e976c52dd14), rs2:x22(0xfffffffffffffffe), result rd:x5(0x0000000000000000)
li x27, MASK_XLEN(0x624b3e976c52dd14)
li x22, MASK_XLEN(0xfffffffffffffffe)
SLT x5, x27, x22
sd x5, 464(x6)

# Testcase 59:  rs1:x16(0x624b3e976c52dd14), rs2:x7(0xffffffffffffffff), result rd:x31(0x0000000000000000)
li x16, MASK_XLEN(0x624b3e976c52dd14)
li x7, MASK_XLEN(0xffffffffffffffff)
SLT x31, x16, x7
sd x31, 472(x6)

# Testcase 60:  rs1:x30(0x7ffffffffffffffe), rs2:x7(0x0000000000000000), result rd:x3(0x0000000000000000)
li x30, MASK_XLEN(0x7ffffffffffffffe)
li x7, MASK_XLEN(0x0000000000000000)
SLT x3, x30, x7
sd x3, 480(x6)

# Testcase 61:  rs1:x28(0x7ffffffffffffffe), rs2:x30(0x0000000000000001), result rd:x9(0x0000000000000000)
li x28, MASK_XLEN(0x7ffffffffffffffe)
li x30, MASK_XLEN(0x0000000000000001)
SLT x9, x28, x30
sd x9, 488(x6)

# Testcase 62:  rs1:x17(0x7ffffffffffffffe), rs2:x27(0x0000000000000002), result rd:x17(0x0000000000000000)
li x17, MASK_XLEN(0x7ffffffffffffffe)
li x27, MASK_XLEN(0x0000000000000002)
SLT x17, x17, x27
sd x17, 496(x6)

# Testcase 63:  rs1:x4(0x7ffffffffffffffe), rs2:x16(0x00000000000000ff), result rd:x30(0x0000000000000000)
li x4, MASK_XLEN(0x7ffffffffffffffe)
li x16, MASK_XLEN(0x00000000000000ff)
SLT x30, x4, x16
sd x30, 504(x6)

# Testcase 64:  rs1:x8(0x7ffffffffffffffe), rs2:x14(0x624b3e976c52dd14), result rd:x31(0x0000000000000000)
li x8, MASK_XLEN(0x7ffffffffffffffe)
li x14, MASK_XLEN(0x624b3e976c52dd14)
SLT x31, x8, x14
sd x31, 512(x6)

# Testcase 65:  rs1:x31(0x7ffffffffffffffe), rs2:x2(0x7ffffffffffffffe), result rd:x17(0x0000000000000000)
li x31, MASK_XLEN(0x7ffffffffffffffe)
li x2, MASK_XLEN(0x7ffffffffffffffe)
SLT x17, x31, x2
sd x17, 520(x6)

# Testcase 66:  rs1:x2(0x7ffffffffffffffe), rs2:x23(0x7fffffffffffffff), result rd:x24(0x0000000000000001)
li x2, MASK_XLEN(0x7ffffffffffffffe)
li x23, MASK_XLEN(0x7fffffffffffffff)
SLT x24, x2, x23
sd x24, 528(x6)

# Testcase 67:  rs1:x3(0x7ffffffffffffffe), rs2:x26(0x8000000000000000), result rd:x24(0x0000000000000000)
li x3, MASK_XLEN(0x7ffffffffffffffe)
li x26, MASK_XLEN(0x8000000000000000)
SLT x24, x3, x26
sd x24, 536(x6)

# Testcase 68:  rs1:x24(0x7ffffffffffffffe), rs2:x4(0x8000000000000001), result rd:x29(0x0000000000000000)
li x24, MASK_XLEN(0x7ffffffffffffffe)
li x4, MASK_XLEN(0x8000000000000001)
SLT x29, x24, x4
sd x29, 544(x6)

# Testcase 69:  rs1:x31(0x7ffffffffffffffe), rs2:x19(0xc365ddeb9173ab42), result rd:x5(0x0000000000000000)
li x31, MASK_XLEN(0x7ffffffffffffffe)
li x19, MASK_XLEN(0xc365ddeb9173ab42)
SLT x5, x31, x19
sd x5, 552(x6)

# Testcase 70:  rs1:x5(0x7ffffffffffffffe), rs2:x19(0xfffffffffffffffe), result rd:x7(0x0000000000000000)
li x5, MASK_XLEN(0x7ffffffffffffffe)
li x19, MASK_XLEN(0xfffffffffffffffe)
SLT x7, x5, x19
sd x7, 560(x6)

# Testcase 71:  rs1:x21(0x7ffffffffffffffe), rs2:x12(0xffffffffffffffff), result rd:x12(0x0000000000000000)
li x21, MASK_XLEN(0x7ffffffffffffffe)
li x12, MASK_XLEN(0xffffffffffffffff)
SLT x12, x21, x12
sd x12, 568(x6)

# Testcase 72:  rs1:x16(0x7fffffffffffffff), rs2:x5(0x0000000000000000), result rd:x11(0x0000000000000000)
li x16, MASK_XLEN(0x7fffffffffffffff)
li x5, MASK_XLEN(0x0000000000000000)
SLT x11, x16, x5
sd x11, 576(x6)

# Testcase 73:  rs1:x19(0x7fffffffffffffff), rs2:x29(0x0000000000000001), result rd:x17(0x0000000000000000)
li x19, MASK_XLEN(0x7fffffffffffffff)
li x29, MASK_XLEN(0x0000000000000001)
SLT x17, x19, x29
sd x17, 584(x6)

# Testcase 74:  rs1:x7(0x7fffffffffffffff), rs2:x20(0x0000000000000002), result rd:x8(0x0000000000000000)
li x7, MASK_XLEN(0x7fffffffffffffff)
li x20, MASK_XLEN(0x0000000000000002)
SLT x8, x7, x20
sd x8, 592(x6)

# Testcase 75:  rs1:x25(0x7fffffffffffffff), rs2:x20(0x00000000000000ff), result rd:x19(0x0000000000000000)
li x25, MASK_XLEN(0x7fffffffffffffff)
li x20, MASK_XLEN(0x00000000000000ff)
SLT x19, x25, x20
sd x19, 600(x6)

# Testcase 76:  rs1:x15(0x7fffffffffffffff), rs2:x20(0x624b3e976c52dd14), result rd:x10(0x0000000000000000)
li x15, MASK_XLEN(0x7fffffffffffffff)
li x20, MASK_XLEN(0x624b3e976c52dd14)
SLT x10, x15, x20
sd x10, 608(x6)

# Testcase 77:  rs1:x4(0x7fffffffffffffff), rs2:x5(0x7ffffffffffffffe), result rd:x14(0x0000000000000000)
li x4, MASK_XLEN(0x7fffffffffffffff)
li x5, MASK_XLEN(0x7ffffffffffffffe)
SLT x14, x4, x5
sd x14, 616(x6)

# Testcase 78:  rs1:x27(0x7fffffffffffffff), rs2:x4(0x7fffffffffffffff), result rd:x24(0x0000000000000000)
li x27, MASK_XLEN(0x7fffffffffffffff)
li x4, MASK_XLEN(0x7fffffffffffffff)
SLT x24, x27, x4
sd x24, 624(x6)

# Testcase 79:  rs1:x29(0x7fffffffffffffff), rs2:x7(0x8000000000000000), result rd:x31(0x0000000000000000)
li x29, MASK_XLEN(0x7fffffffffffffff)
li x7, MASK_XLEN(0x8000000000000000)
SLT x31, x29, x7
sd x31, 632(x6)

# Testcase 80:  rs1:x30(0x7fffffffffffffff), rs2:x23(0x8000000000000001), result rd:x9(0x0000000000000000)
li x30, MASK_XLEN(0x7fffffffffffffff)
li x23, MASK_XLEN(0x8000000000000001)
SLT x9, x30, x23
sd x9, 640(x6)

# Testcase 81:  rs1:x9(0x7fffffffffffffff), rs2:x26(0xc365ddeb9173ab42), result rd:x22(0x0000000000000000)
li x9, MASK_XLEN(0x7fffffffffffffff)
li x26, MASK_XLEN(0xc365ddeb9173ab42)
SLT x22, x9, x26
sd x22, 648(x6)

# Testcase 82:  rs1:x23(0x7fffffffffffffff), rs2:x11(0xfffffffffffffffe), result rd:x18(0x0000000000000000)
li x23, MASK_XLEN(0x7fffffffffffffff)
li x11, MASK_XLEN(0xfffffffffffffffe)
SLT x18, x23, x11
sd x18, 656(x6)

# Testcase 83:  rs1:x4(0x7fffffffffffffff), rs2:x25(0xffffffffffffffff), result rd:x3(0x0000000000000000)
li x4, MASK_XLEN(0x7fffffffffffffff)
li x25, MASK_XLEN(0xffffffffffffffff)
SLT x3, x4, x25
sd x3, 664(x6)

# Testcase 84:  rs1:x13(0x8000000000000000), rs2:x1(0x0000000000000000), result rd:x2(0x0000000000000001)
li x13, MASK_XLEN(0x8000000000000000)
li x1, MASK_XLEN(0x0000000000000000)
SLT x2, x13, x1
sd x2, 672(x6)

# Testcase 85:  rs1:x7(0x8000000000000000), rs2:x11(0x0000000000000001), result rd:x14(0x0000000000000001)
li x7, MASK_XLEN(0x8000000000000000)
li x11, MASK_XLEN(0x0000000000000001)
SLT x14, x7, x11
sd x14, 680(x6)

# Testcase 86:  rs1:x29(0x8000000000000000), rs2:x8(0x0000000000000002), result rd:x26(0x0000000000000001)
li x29, MASK_XLEN(0x8000000000000000)
li x8, MASK_XLEN(0x0000000000000002)
SLT x26, x29, x8
sd x26, 688(x6)

# Testcase 87:  rs1:x11(0x8000000000000000), rs2:x30(0x00000000000000ff), result rd:x14(0x0000000000000001)
li x11, MASK_XLEN(0x8000000000000000)
li x30, MASK_XLEN(0x00000000000000ff)
SLT x14, x11, x30
sd x14, 696(x6)

# Testcase 88:  rs1:x19(0x8000000000000000), rs2:x4(0x624b3e976c52dd14), result rd:x11(0x0000000000000001)
li x19, MASK_XLEN(0x8000000000000000)
li x4, MASK_XLEN(0x624b3e976c52dd14)
SLT x11, x19, x4
sd x11, 704(x6)

# Testcase 89:  rs1:x3(0x8000000000000000), rs2:x16(0x7ffffffffffffffe), result rd:x20(0x0000000000000001)
li x3, MASK_XLEN(0x8000000000000000)
li x16, MASK_XLEN(0x7ffffffffffffffe)
SLT x20, x3, x16
sd x20, 712(x6)

# Testcase 90:  rs1:x16(0x8000000000000000), rs2:x10(0x7fffffffffffffff), result rd:x8(0x0000000000000001)
li x16, MASK_XLEN(0x8000000000000000)
li x10, MASK_XLEN(0x7fffffffffffffff)
SLT x8, x16, x10
sd x8, 720(x6)

# Testcase 91:  rs1:x13(0x8000000000000000), rs2:x28(0x8000000000000000), result rd:x23(0x0000000000000000)
li x13, MASK_XLEN(0x8000000000000000)
li x28, MASK_XLEN(0x8000000000000000)
SLT x23, x13, x28
sd x23, 728(x6)

# Testcase 92:  rs1:x2(0x8000000000000000), rs2:x12(0x8000000000000001), result rd:x11(0x0000000000000001)
li x2, MASK_XLEN(0x8000000000000000)
li x12, MASK_XLEN(0x8000000000000001)
SLT x11, x2, x12
sd x11, 736(x6)

# Testcase 93:  rs1:x9(0x8000000000000000), rs2:x31(0xc365ddeb9173ab42), result rd:x15(0x0000000000000001)
li x9, MASK_XLEN(0x8000000000000000)
li x31, MASK_XLEN(0xc365ddeb9173ab42)
SLT x15, x9, x31
sd x15, 744(x6)

# Testcase 94:  rs1:x1(0x8000000000000000), rs2:x26(0xfffffffffffffffe), result rd:x26(0x0000000000000001)
li x1, MASK_XLEN(0x8000000000000000)
li x26, MASK_XLEN(0xfffffffffffffffe)
SLT x26, x1, x26
sd x26, 752(x6)

# Testcase 95:  rs1:x28(0x8000000000000000), rs2:x5(0xffffffffffffffff), result rd:x24(0x0000000000000001)
li x28, MASK_XLEN(0x8000000000000000)
li x5, MASK_XLEN(0xffffffffffffffff)
SLT x24, x28, x5
sd x24, 760(x6)

# Testcase 96:  rs1:x18(0x8000000000000001), rs2:x19(0x0000000000000000), result rd:x11(0x0000000000000001)
li x18, MASK_XLEN(0x8000000000000001)
li x19, MASK_XLEN(0x0000000000000000)
SLT x11, x18, x19
sd x11, 768(x6)

# Testcase 97:  rs1:x22(0x8000000000000001), rs2:x24(0x0000000000000001), result rd:x15(0x0000000000000001)
li x22, MASK_XLEN(0x8000000000000001)
li x24, MASK_XLEN(0x0000000000000001)
SLT x15, x22, x24
sd x15, 776(x6)

# Testcase 98:  rs1:x3(0x8000000000000001), rs2:x26(0x0000000000000002), result rd:x13(0x0000000000000001)
li x3, MASK_XLEN(0x8000000000000001)
li x26, MASK_XLEN(0x0000000000000002)
SLT x13, x3, x26
sd x13, 784(x6)

# Testcase 99:  rs1:x27(0x8000000000000001), rs2:x9(0x00000000000000ff), result rd:x15(0x0000000000000001)
li x27, MASK_XLEN(0x8000000000000001)
li x9, MASK_XLEN(0x00000000000000ff)
SLT x15, x27, x9
sd x15, 792(x6)

# Testcase 100:  rs1:x10(0x8000000000000001), rs2:x1(0x624b3e976c52dd14), result rd:x13(0x0000000000000001)
li x10, MASK_XLEN(0x8000000000000001)
li x1, MASK_XLEN(0x624b3e976c52dd14)
SLT x13, x10, x1
sd x13, 800(x6)

# Testcase 101:  rs1:x28(0x8000000000000001), rs2:x1(0x7ffffffffffffffe), result rd:x26(0x0000000000000001)
li x28, MASK_XLEN(0x8000000000000001)
li x1, MASK_XLEN(0x7ffffffffffffffe)
SLT x26, x28, x1
sd x26, 808(x6)

# Testcase 102:  rs1:x29(0x8000000000000001), rs2:x15(0x7fffffffffffffff), result rd:x26(0x0000000000000001)
li x29, MASK_XLEN(0x8000000000000001)
li x15, MASK_XLEN(0x7fffffffffffffff)
SLT x26, x29, x15
sd x26, 816(x6)

# Testcase 103:  rs1:x4(0x8000000000000001), rs2:x5(0x8000000000000000), result rd:x26(0x0000000000000000)
li x4, MASK_XLEN(0x8000000000000001)
li x5, MASK_XLEN(0x8000000000000000)
SLT x26, x4, x5
sd x26, 824(x6)

# Testcase 104:  rs1:x27(0x8000000000000001), rs2:x10(0x8000000000000001), result rd:x11(0x0000000000000000)
li x27, MASK_XLEN(0x8000000000000001)
li x10, MASK_XLEN(0x8000000000000001)
SLT x11, x27, x10
sd x11, 832(x6)

# Testcase 105:  rs1:x10(0x8000000000000001), rs2:x20(0xc365ddeb9173ab42), result rd:x5(0x0000000000000001)
li x10, MASK_XLEN(0x8000000000000001)
li x20, MASK_XLEN(0xc365ddeb9173ab42)
SLT x5, x10, x20
sd x5, 840(x6)

# Testcase 106:  rs1:x16(0x8000000000000001), rs2:x26(0xfffffffffffffffe), result rd:x15(0x0000000000000001)
li x16, MASK_XLEN(0x8000000000000001)
li x26, MASK_XLEN(0xfffffffffffffffe)
SLT x15, x16, x26
sd x15, 848(x6)

# Testcase 107:  rs1:x1(0x8000000000000001), rs2:x20(0xffffffffffffffff), result rd:x11(0x0000000000000001)
li x1, MASK_XLEN(0x8000000000000001)
li x20, MASK_XLEN(0xffffffffffffffff)
SLT x11, x1, x20
sd x11, 856(x6)

# Testcase 108:  rs1:x30(0xc365ddeb9173ab42), rs2:x5(0x0000000000000000), result rd:x14(0x0000000000000001)
li x30, MASK_XLEN(0xc365ddeb9173ab42)
li x5, MASK_XLEN(0x0000000000000000)
SLT x14, x30, x5
sd x14, 864(x6)

# Testcase 109:  rs1:x26(0xc365ddeb9173ab42), rs2:x1(0x0000000000000001), result rd:x10(0x0000000000000001)
li x26, MASK_XLEN(0xc365ddeb9173ab42)
li x1, MASK_XLEN(0x0000000000000001)
SLT x10, x26, x1
sd x10, 872(x6)

# Testcase 110:  rs1:x19(0xc365ddeb9173ab42), rs2:x26(0x0000000000000002), result rd:x26(0x0000000000000001)
li x19, MASK_XLEN(0xc365ddeb9173ab42)
li x26, MASK_XLEN(0x0000000000000002)
SLT x26, x19, x26
sd x26, 880(x6)

# Testcase 111:  rs1:x28(0xc365ddeb9173ab42), rs2:x25(0x00000000000000ff), result rd:x17(0x0000000000000001)
li x28, MASK_XLEN(0xc365ddeb9173ab42)
li x25, MASK_XLEN(0x00000000000000ff)
SLT x17, x28, x25
sd x17, 888(x6)

# Testcase 112:  rs1:x28(0xc365ddeb9173ab42), rs2:x15(0x624b3e976c52dd14), result rd:x28(0x0000000000000001)
li x28, MASK_XLEN(0xc365ddeb9173ab42)
li x15, MASK_XLEN(0x624b3e976c52dd14)
SLT x28, x28, x15
sd x28, 896(x6)

# Testcase 113:  rs1:x27(0xc365ddeb9173ab42), rs2:x30(0x7ffffffffffffffe), result rd:x18(0x0000000000000001)
li x27, MASK_XLEN(0xc365ddeb9173ab42)
li x30, MASK_XLEN(0x7ffffffffffffffe)
SLT x18, x27, x30
sd x18, 904(x6)

# Testcase 114:  rs1:x21(0xc365ddeb9173ab42), rs2:x25(0x7fffffffffffffff), result rd:x5(0x0000000000000001)
li x21, MASK_XLEN(0xc365ddeb9173ab42)
li x25, MASK_XLEN(0x7fffffffffffffff)
SLT x5, x21, x25
sd x5, 912(x6)

# Testcase 115:  rs1:x30(0xc365ddeb9173ab42), rs2:x14(0x8000000000000000), result rd:x27(0x0000000000000000)
li x30, MASK_XLEN(0xc365ddeb9173ab42)
li x14, MASK_XLEN(0x8000000000000000)
SLT x27, x30, x14
sd x27, 920(x6)

# Testcase 116:  rs1:x31(0xc365ddeb9173ab42), rs2:x11(0x8000000000000001), result rd:x5(0x0000000000000000)
li x31, MASK_XLEN(0xc365ddeb9173ab42)
li x11, MASK_XLEN(0x8000000000000001)
SLT x5, x31, x11
sd x5, 928(x6)

# Testcase 117:  rs1:x23(0xc365ddeb9173ab42), rs2:x30(0xc365ddeb9173ab42), result rd:x18(0x0000000000000000)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
li x30, MASK_XLEN(0xc365ddeb9173ab42)
SLT x18, x23, x30
sd x18, 936(x6)

# Testcase 118:  rs1:x27(0xc365ddeb9173ab42), rs2:x3(0xfffffffffffffffe), result rd:x3(0x0000000000000001)
li x27, MASK_XLEN(0xc365ddeb9173ab42)
li x3, MASK_XLEN(0xfffffffffffffffe)
SLT x3, x27, x3
sd x3, 944(x6)

# Testcase 119:  rs1:x8(0xc365ddeb9173ab42), rs2:x4(0xffffffffffffffff), result rd:x7(0x0000000000000001)
li x8, MASK_XLEN(0xc365ddeb9173ab42)
li x4, MASK_XLEN(0xffffffffffffffff)
SLT x7, x8, x4
sd x7, 952(x6)

# Testcase 120:  rs1:x16(0xfffffffffffffffe), rs2:x29(0x0000000000000000), result rd:x23(0x0000000000000001)
li x16, MASK_XLEN(0xfffffffffffffffe)
li x29, MASK_XLEN(0x0000000000000000)
SLT x23, x16, x29
sd x23, 960(x6)

# Testcase 121:  rs1:x28(0xfffffffffffffffe), rs2:x21(0x0000000000000001), result rd:x31(0x0000000000000001)
li x28, MASK_XLEN(0xfffffffffffffffe)
li x21, MASK_XLEN(0x0000000000000001)
SLT x31, x28, x21
sd x31, 968(x6)

# Testcase 122:  rs1:x7(0xfffffffffffffffe), rs2:x1(0x0000000000000002), result rd:x26(0x0000000000000001)
li x7, MASK_XLEN(0xfffffffffffffffe)
li x1, MASK_XLEN(0x0000000000000002)
SLT x26, x7, x1
sd x26, 976(x6)

# Testcase 123:  rs1:x28(0xfffffffffffffffe), rs2:x13(0x00000000000000ff), result rd:x11(0x0000000000000001)
li x28, MASK_XLEN(0xfffffffffffffffe)
li x13, MASK_XLEN(0x00000000000000ff)
SLT x11, x28, x13
sd x11, 984(x6)

# Testcase 124:  rs1:x9(0xfffffffffffffffe), rs2:x12(0x624b3e976c52dd14), result rd:x19(0x0000000000000001)
li x9, MASK_XLEN(0xfffffffffffffffe)
li x12, MASK_XLEN(0x624b3e976c52dd14)
SLT x19, x9, x12
sd x19, 992(x6)

# Testcase 125:  rs1:x9(0xfffffffffffffffe), rs2:x15(0x7ffffffffffffffe), result rd:x30(0x0000000000000001)
li x9, MASK_XLEN(0xfffffffffffffffe)
li x15, MASK_XLEN(0x7ffffffffffffffe)
SLT x30, x9, x15
sd x30, 1000(x6)

# Testcase 126:  rs1:x17(0xfffffffffffffffe), rs2:x24(0x7fffffffffffffff), result rd:x31(0x0000000000000001)
li x17, MASK_XLEN(0xfffffffffffffffe)
li x24, MASK_XLEN(0x7fffffffffffffff)
SLT x31, x17, x24
sd x31, 1008(x6)

# Testcase 127:  rs1:x2(0xfffffffffffffffe), rs2:x10(0x8000000000000000), result rd:x28(0x0000000000000000)
li x2, MASK_XLEN(0xfffffffffffffffe)
li x10, MASK_XLEN(0x8000000000000000)
SLT x28, x2, x10
sd x28, 1016(x6)

# Testcase 128:  rs1:x15(0xfffffffffffffffe), rs2:x14(0x8000000000000001), result rd:x30(0x0000000000000000)
li x15, MASK_XLEN(0xfffffffffffffffe)
li x14, MASK_XLEN(0x8000000000000001)
SLT x30, x15, x14
sd x30, 1024(x6)

# Testcase 129:  rs1:x28(0xfffffffffffffffe), rs2:x8(0xc365ddeb9173ab42), result rd:x29(0x0000000000000000)
li x28, MASK_XLEN(0xfffffffffffffffe)
li x8, MASK_XLEN(0xc365ddeb9173ab42)
SLT x29, x28, x8
sd x29, 1032(x6)

# Testcase 130:  rs1:x25(0xfffffffffffffffe), rs2:x24(0xfffffffffffffffe), result rd:x24(0x0000000000000000)
li x25, MASK_XLEN(0xfffffffffffffffe)
li x24, MASK_XLEN(0xfffffffffffffffe)
SLT x24, x25, x24
sd x24, 1040(x6)

# Testcase 131:  rs1:x16(0xfffffffffffffffe), rs2:x1(0xffffffffffffffff), result rd:x17(0x0000000000000001)
li x16, MASK_XLEN(0xfffffffffffffffe)
li x1, MASK_XLEN(0xffffffffffffffff)
SLT x17, x16, x1
sd x17, 1048(x6)

# Testcase 132:  rs1:x27(0xffffffffffffffff), rs2:x20(0x0000000000000000), result rd:x24(0x0000000000000001)
li x27, MASK_XLEN(0xffffffffffffffff)
li x20, MASK_XLEN(0x0000000000000000)
SLT x24, x27, x20
sd x24, 1056(x6)

# Testcase 133:  rs1:x13(0xffffffffffffffff), rs2:x23(0x0000000000000001), result rd:x26(0x0000000000000001)
li x13, MASK_XLEN(0xffffffffffffffff)
li x23, MASK_XLEN(0x0000000000000001)
SLT x26, x13, x23
sd x26, 1064(x6)

# Testcase 134:  rs1:x28(0xffffffffffffffff), rs2:x26(0x0000000000000002), result rd:x11(0x0000000000000001)
li x28, MASK_XLEN(0xffffffffffffffff)
li x26, MASK_XLEN(0x0000000000000002)
SLT x11, x28, x26
sd x11, 1072(x6)

# Testcase 135:  rs1:x7(0xffffffffffffffff), rs2:x31(0x00000000000000ff), result rd:x19(0x0000000000000001)
li x7, MASK_XLEN(0xffffffffffffffff)
li x31, MASK_XLEN(0x00000000000000ff)
SLT x19, x7, x31
sd x19, 1080(x6)

# Testcase 136:  rs1:x12(0xffffffffffffffff), rs2:x10(0x624b3e976c52dd14), result rd:x26(0x0000000000000001)
li x12, MASK_XLEN(0xffffffffffffffff)
li x10, MASK_XLEN(0x624b3e976c52dd14)
SLT x26, x12, x10
sd x26, 1088(x6)

# Testcase 137:  rs1:x23(0xffffffffffffffff), rs2:x9(0x7ffffffffffffffe), result rd:x7(0x0000000000000001)
li x23, MASK_XLEN(0xffffffffffffffff)
li x9, MASK_XLEN(0x7ffffffffffffffe)
SLT x7, x23, x9
sd x7, 1096(x6)

# Testcase 138:  rs1:x26(0xffffffffffffffff), rs2:x31(0x7fffffffffffffff), result rd:x4(0x0000000000000001)
li x26, MASK_XLEN(0xffffffffffffffff)
li x31, MASK_XLEN(0x7fffffffffffffff)
SLT x4, x26, x31
sd x4, 1104(x6)

# Testcase 139:  rs1:x12(0xffffffffffffffff), rs2:x24(0x8000000000000000), result rd:x13(0x0000000000000000)
li x12, MASK_XLEN(0xffffffffffffffff)
li x24, MASK_XLEN(0x8000000000000000)
SLT x13, x12, x24
sd x13, 1112(x6)

# Testcase 140:  rs1:x5(0xffffffffffffffff), rs2:x10(0x8000000000000001), result rd:x26(0x0000000000000000)
li x5, MASK_XLEN(0xffffffffffffffff)
li x10, MASK_XLEN(0x8000000000000001)
SLT x26, x5, x10
sd x26, 1120(x6)

# Testcase 141:  rs1:x9(0xffffffffffffffff), rs2:x23(0xc365ddeb9173ab42), result rd:x20(0x0000000000000000)
li x9, MASK_XLEN(0xffffffffffffffff)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
SLT x20, x9, x23
sd x20, 1128(x6)

# Testcase 142:  rs1:x13(0xffffffffffffffff), rs2:x1(0xfffffffffffffffe), result rd:x22(0x0000000000000000)
li x13, MASK_XLEN(0xffffffffffffffff)
li x1, MASK_XLEN(0xfffffffffffffffe)
SLT x22, x13, x1
sd x22, 1136(x6)

# Testcase 143:  rs1:x31(0xffffffffffffffff), rs2:x30(0xffffffffffffffff), result rd:x27(0x0000000000000000)
li x31, MASK_XLEN(0xffffffffffffffff)
li x30, MASK_XLEN(0xffffffffffffffff)
SLT x27, x31, x30
sd x27, 1144(x6)

# Testcase 144:  rs1:x13(0xd2c1d26b13e14526), rs2:x14(0xed3696ce2f914af5), result rd:x3(0x0000000000000001)
li x13, MASK_XLEN(0xd2c1d26b13e14526)
li x14, MASK_XLEN(0xed3696ce2f914af5)
SLT x3, x13, x14
sd x3, 1152(x6)

# Testcase 145:  rs1:x18(0xad358ffc13addef2), rs2:x3(0x3ffdd31f91c73e1d), result rd:x7(0x0000000000000001)
li x18, MASK_XLEN(0xad358ffc13addef2)
li x3, MASK_XLEN(0x3ffdd31f91c73e1d)
SLT x7, x18, x3
sd x7, 1160(x6)

# Testcase 146:  rs1:x18(0xbe0d894c52f29d2c), rs2:x23(0xfc34ed2873e42678), result rd:x20(0x0000000000000001)
li x18, MASK_XLEN(0xbe0d894c52f29d2c)
li x23, MASK_XLEN(0xfc34ed2873e42678)
SLT x20, x18, x23
sd x20, 1168(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry

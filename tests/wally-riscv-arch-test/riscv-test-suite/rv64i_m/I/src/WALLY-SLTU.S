///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.543748//
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

# Testcase 0:  rs1:x26(0x0000000000000000), rs2:x4(0x0000000000000000), result rd:x25(0x0000000000000000)
li x26, MASK_XLEN(0x0000000000000000)
li x4, MASK_XLEN(0x0000000000000000)
SLTU x25, x26, x4
sd x25, 0(x6)

# Testcase 1:  rs1:x19(0x0000000000000000), rs2:x20(0x0000000000000001), result rd:x2(0x0000000000000001)
li x19, MASK_XLEN(0x0000000000000000)
li x20, MASK_XLEN(0x0000000000000001)
SLTU x2, x19, x20
sd x2, 8(x6)

# Testcase 2:  rs1:x28(0x0000000000000000), rs2:x31(0x0000000000000002), result rd:x15(0x0000000000000001)
li x28, MASK_XLEN(0x0000000000000000)
li x31, MASK_XLEN(0x0000000000000002)
SLTU x15, x28, x31
sd x15, 16(x6)

# Testcase 3:  rs1:x25(0x0000000000000000), rs2:x9(0x00000000000000ff), result rd:x7(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000000)
li x9, MASK_XLEN(0x00000000000000ff)
SLTU x7, x25, x9
sd x7, 24(x6)

# Testcase 4:  rs1:x18(0x0000000000000000), rs2:x2(0x624b3e976c52dd14), result rd:x16(0x0000000000000001)
li x18, MASK_XLEN(0x0000000000000000)
li x2, MASK_XLEN(0x624b3e976c52dd14)
SLTU x16, x18, x2
sd x16, 32(x6)

# Testcase 5:  rs1:x3(0x0000000000000000), rs2:x1(0x7ffffffffffffffe), result rd:x21(0x0000000000000001)
li x3, MASK_XLEN(0x0000000000000000)
li x1, MASK_XLEN(0x7ffffffffffffffe)
SLTU x21, x3, x1
sd x21, 40(x6)

# Testcase 6:  rs1:x2(0x0000000000000000), rs2:x20(0x7fffffffffffffff), result rd:x7(0x0000000000000001)
li x2, MASK_XLEN(0x0000000000000000)
li x20, MASK_XLEN(0x7fffffffffffffff)
SLTU x7, x2, x20
sd x7, 48(x6)

# Testcase 7:  rs1:x22(0x0000000000000000), rs2:x7(0x8000000000000000), result rd:x17(0x0000000000000001)
li x22, MASK_XLEN(0x0000000000000000)
li x7, MASK_XLEN(0x8000000000000000)
SLTU x17, x22, x7
sd x17, 56(x6)

# Testcase 8:  rs1:x10(0x0000000000000000), rs2:x19(0x8000000000000001), result rd:x24(0x0000000000000001)
li x10, MASK_XLEN(0x0000000000000000)
li x19, MASK_XLEN(0x8000000000000001)
SLTU x24, x10, x19
sd x24, 64(x6)

# Testcase 9:  rs1:x19(0x0000000000000000), rs2:x3(0xc365ddeb9173ab42), result rd:x5(0x0000000000000001)
li x19, MASK_XLEN(0x0000000000000000)
li x3, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x5, x19, x3
sd x5, 72(x6)

# Testcase 10:  rs1:x12(0x0000000000000000), rs2:x28(0xfffffffffffffffe), result rd:x18(0x0000000000000001)
li x12, MASK_XLEN(0x0000000000000000)
li x28, MASK_XLEN(0xfffffffffffffffe)
SLTU x18, x12, x28
sd x18, 80(x6)

# Testcase 11:  rs1:x29(0x0000000000000000), rs2:x20(0xffffffffffffffff), result rd:x11(0x0000000000000001)
li x29, MASK_XLEN(0x0000000000000000)
li x20, MASK_XLEN(0xffffffffffffffff)
SLTU x11, x29, x20
sd x11, 88(x6)

# Testcase 12:  rs1:x21(0x0000000000000001), rs2:x10(0x0000000000000000), result rd:x29(0x0000000000000000)
li x21, MASK_XLEN(0x0000000000000001)
li x10, MASK_XLEN(0x0000000000000000)
SLTU x29, x21, x10
sd x29, 96(x6)

# Testcase 13:  rs1:x18(0x0000000000000001), rs2:x26(0x0000000000000001), result rd:x8(0x0000000000000000)
li x18, MASK_XLEN(0x0000000000000001)
li x26, MASK_XLEN(0x0000000000000001)
SLTU x8, x18, x26
sd x8, 104(x6)

# Testcase 14:  rs1:x19(0x0000000000000001), rs2:x10(0x0000000000000002), result rd:x1(0x0000000000000001)
li x19, MASK_XLEN(0x0000000000000001)
li x10, MASK_XLEN(0x0000000000000002)
SLTU x1, x19, x10
sd x1, 112(x6)

# Testcase 15:  rs1:x19(0x0000000000000001), rs2:x14(0x00000000000000ff), result rd:x12(0x0000000000000001)
li x19, MASK_XLEN(0x0000000000000001)
li x14, MASK_XLEN(0x00000000000000ff)
SLTU x12, x19, x14
sd x12, 120(x6)

# Testcase 16:  rs1:x3(0x0000000000000001), rs2:x11(0x624b3e976c52dd14), result rd:x31(0x0000000000000001)
li x3, MASK_XLEN(0x0000000000000001)
li x11, MASK_XLEN(0x624b3e976c52dd14)
SLTU x31, x3, x11
sd x31, 128(x6)

# Testcase 17:  rs1:x9(0x0000000000000001), rs2:x27(0x7ffffffffffffffe), result rd:x25(0x0000000000000001)
li x9, MASK_XLEN(0x0000000000000001)
li x27, MASK_XLEN(0x7ffffffffffffffe)
SLTU x25, x9, x27
sd x25, 136(x6)

# Testcase 18:  rs1:x12(0x0000000000000001), rs2:x27(0x7fffffffffffffff), result rd:x4(0x0000000000000001)
li x12, MASK_XLEN(0x0000000000000001)
li x27, MASK_XLEN(0x7fffffffffffffff)
SLTU x4, x12, x27
sd x4, 144(x6)

# Testcase 19:  rs1:x10(0x0000000000000001), rs2:x19(0x8000000000000000), result rd:x5(0x0000000000000001)
li x10, MASK_XLEN(0x0000000000000001)
li x19, MASK_XLEN(0x8000000000000000)
SLTU x5, x10, x19
sd x5, 152(x6)

# Testcase 20:  rs1:x12(0x0000000000000001), rs2:x2(0x8000000000000001), result rd:x24(0x0000000000000001)
li x12, MASK_XLEN(0x0000000000000001)
li x2, MASK_XLEN(0x8000000000000001)
SLTU x24, x12, x2
sd x24, 160(x6)

# Testcase 21:  rs1:x1(0x0000000000000001), rs2:x27(0xc365ddeb9173ab42), result rd:x21(0x0000000000000001)
li x1, MASK_XLEN(0x0000000000000001)
li x27, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x21, x1, x27
sd x21, 168(x6)

# Testcase 22:  rs1:x20(0x0000000000000001), rs2:x30(0xfffffffffffffffe), result rd:x27(0x0000000000000001)
li x20, MASK_XLEN(0x0000000000000001)
li x30, MASK_XLEN(0xfffffffffffffffe)
SLTU x27, x20, x30
sd x27, 176(x6)

# Testcase 23:  rs1:x13(0x0000000000000001), rs2:x1(0xffffffffffffffff), result rd:x14(0x0000000000000001)
li x13, MASK_XLEN(0x0000000000000001)
li x1, MASK_XLEN(0xffffffffffffffff)
SLTU x14, x13, x1
sd x14, 184(x6)

# Testcase 24:  rs1:x8(0x0000000000000002), rs2:x27(0x0000000000000000), result rd:x14(0x0000000000000000)
li x8, MASK_XLEN(0x0000000000000002)
li x27, MASK_XLEN(0x0000000000000000)
SLTU x14, x8, x27
sd x14, 192(x6)

# Testcase 25:  rs1:x19(0x0000000000000002), rs2:x15(0x0000000000000001), result rd:x10(0x0000000000000000)
li x19, MASK_XLEN(0x0000000000000002)
li x15, MASK_XLEN(0x0000000000000001)
SLTU x10, x19, x15
sd x10, 200(x6)

# Testcase 26:  rs1:x23(0x0000000000000002), rs2:x19(0x0000000000000002), result rd:x15(0x0000000000000000)
li x23, MASK_XLEN(0x0000000000000002)
li x19, MASK_XLEN(0x0000000000000002)
SLTU x15, x23, x19
sd x15, 208(x6)

# Testcase 27:  rs1:x18(0x0000000000000002), rs2:x3(0x00000000000000ff), result rd:x21(0x0000000000000001)
li x18, MASK_XLEN(0x0000000000000002)
li x3, MASK_XLEN(0x00000000000000ff)
SLTU x21, x18, x3
sd x21, 216(x6)

# Testcase 28:  rs1:x25(0x0000000000000002), rs2:x1(0x624b3e976c52dd14), result rd:x22(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000002)
li x1, MASK_XLEN(0x624b3e976c52dd14)
SLTU x22, x25, x1
sd x22, 224(x6)

# Testcase 29:  rs1:x2(0x0000000000000002), rs2:x26(0x7ffffffffffffffe), result rd:x3(0x0000000000000001)
li x2, MASK_XLEN(0x0000000000000002)
li x26, MASK_XLEN(0x7ffffffffffffffe)
SLTU x3, x2, x26
sd x3, 232(x6)

# Testcase 30:  rs1:x5(0x0000000000000002), rs2:x13(0x7fffffffffffffff), result rd:x13(0x0000000000000001)
li x5, MASK_XLEN(0x0000000000000002)
li x13, MASK_XLEN(0x7fffffffffffffff)
SLTU x13, x5, x13
sd x13, 240(x6)

# Testcase 31:  rs1:x8(0x0000000000000002), rs2:x21(0x8000000000000000), result rd:x18(0x0000000000000001)
li x8, MASK_XLEN(0x0000000000000002)
li x21, MASK_XLEN(0x8000000000000000)
SLTU x18, x8, x21
sd x18, 248(x6)

# Testcase 32:  rs1:x4(0x0000000000000002), rs2:x1(0x8000000000000001), result rd:x28(0x0000000000000001)
li x4, MASK_XLEN(0x0000000000000002)
li x1, MASK_XLEN(0x8000000000000001)
SLTU x28, x4, x1
sd x28, 256(x6)

# Testcase 33:  rs1:x2(0x0000000000000002), rs2:x13(0xc365ddeb9173ab42), result rd:x13(0x0000000000000001)
li x2, MASK_XLEN(0x0000000000000002)
li x13, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x13, x2, x13
sd x13, 264(x6)

# Testcase 34:  rs1:x27(0x0000000000000002), rs2:x13(0xfffffffffffffffe), result rd:x1(0x0000000000000001)
li x27, MASK_XLEN(0x0000000000000002)
li x13, MASK_XLEN(0xfffffffffffffffe)
SLTU x1, x27, x13
sd x1, 272(x6)

# Testcase 35:  rs1:x22(0x0000000000000002), rs2:x11(0xffffffffffffffff), result rd:x21(0x0000000000000001)
li x22, MASK_XLEN(0x0000000000000002)
li x11, MASK_XLEN(0xffffffffffffffff)
SLTU x21, x22, x11
sd x21, 280(x6)

# Testcase 36:  rs1:x14(0x00000000000000ff), rs2:x17(0x0000000000000000), result rd:x7(0x0000000000000000)
li x14, MASK_XLEN(0x00000000000000ff)
li x17, MASK_XLEN(0x0000000000000000)
SLTU x7, x14, x17
sd x7, 288(x6)

# Testcase 37:  rs1:x30(0x00000000000000ff), rs2:x17(0x0000000000000001), result rd:x26(0x0000000000000000)
li x30, MASK_XLEN(0x00000000000000ff)
li x17, MASK_XLEN(0x0000000000000001)
SLTU x26, x30, x17
sd x26, 296(x6)

# Testcase 38:  rs1:x12(0x00000000000000ff), rs2:x20(0x0000000000000002), result rd:x8(0x0000000000000000)
li x12, MASK_XLEN(0x00000000000000ff)
li x20, MASK_XLEN(0x0000000000000002)
SLTU x8, x12, x20
sd x8, 304(x6)

# Testcase 39:  rs1:x22(0x00000000000000ff), rs2:x2(0x00000000000000ff), result rd:x14(0x0000000000000000)
li x22, MASK_XLEN(0x00000000000000ff)
li x2, MASK_XLEN(0x00000000000000ff)
SLTU x14, x22, x2
sd x14, 312(x6)

# Testcase 40:  rs1:x16(0x00000000000000ff), rs2:x17(0x624b3e976c52dd14), result rd:x21(0x0000000000000001)
li x16, MASK_XLEN(0x00000000000000ff)
li x17, MASK_XLEN(0x624b3e976c52dd14)
SLTU x21, x16, x17
sd x21, 320(x6)

# Testcase 41:  rs1:x2(0x00000000000000ff), rs2:x27(0x7ffffffffffffffe), result rd:x27(0x0000000000000001)
li x2, MASK_XLEN(0x00000000000000ff)
li x27, MASK_XLEN(0x7ffffffffffffffe)
SLTU x27, x2, x27
sd x27, 328(x6)

# Testcase 42:  rs1:x7(0x00000000000000ff), rs2:x11(0x7fffffffffffffff), result rd:x15(0x0000000000000001)
li x7, MASK_XLEN(0x00000000000000ff)
li x11, MASK_XLEN(0x7fffffffffffffff)
SLTU x15, x7, x11
sd x15, 336(x6)

# Testcase 43:  rs1:x7(0x00000000000000ff), rs2:x4(0x8000000000000000), result rd:x10(0x0000000000000001)
li x7, MASK_XLEN(0x00000000000000ff)
li x4, MASK_XLEN(0x8000000000000000)
SLTU x10, x7, x4
sd x10, 344(x6)

# Testcase 44:  rs1:x25(0x00000000000000ff), rs2:x11(0x8000000000000001), result rd:x11(0x0000000000000001)
li x25, MASK_XLEN(0x00000000000000ff)
li x11, MASK_XLEN(0x8000000000000001)
SLTU x11, x25, x11
sd x11, 352(x6)

# Testcase 45:  rs1:x24(0x00000000000000ff), rs2:x10(0xc365ddeb9173ab42), result rd:x26(0x0000000000000001)
li x24, MASK_XLEN(0x00000000000000ff)
li x10, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x26, x24, x10
sd x26, 360(x6)

# Testcase 46:  rs1:x24(0x00000000000000ff), rs2:x14(0xfffffffffffffffe), result rd:x9(0x0000000000000001)
li x24, MASK_XLEN(0x00000000000000ff)
li x14, MASK_XLEN(0xfffffffffffffffe)
SLTU x9, x24, x14
sd x9, 368(x6)

# Testcase 47:  rs1:x2(0x00000000000000ff), rs2:x31(0xffffffffffffffff), result rd:x13(0x0000000000000001)
li x2, MASK_XLEN(0x00000000000000ff)
li x31, MASK_XLEN(0xffffffffffffffff)
SLTU x13, x2, x31
sd x13, 376(x6)

# Testcase 48:  rs1:x25(0x624b3e976c52dd14), rs2:x19(0x0000000000000000), result rd:x26(0x0000000000000000)
li x25, MASK_XLEN(0x624b3e976c52dd14)
li x19, MASK_XLEN(0x0000000000000000)
SLTU x26, x25, x19
sd x26, 384(x6)

# Testcase 49:  rs1:x28(0x624b3e976c52dd14), rs2:x30(0x0000000000000001), result rd:x16(0x0000000000000000)
li x28, MASK_XLEN(0x624b3e976c52dd14)
li x30, MASK_XLEN(0x0000000000000001)
SLTU x16, x28, x30
sd x16, 392(x6)

# Testcase 50:  rs1:x26(0x624b3e976c52dd14), rs2:x8(0x0000000000000002), result rd:x14(0x0000000000000000)
li x26, MASK_XLEN(0x624b3e976c52dd14)
li x8, MASK_XLEN(0x0000000000000002)
SLTU x14, x26, x8
sd x14, 400(x6)

# Testcase 51:  rs1:x25(0x624b3e976c52dd14), rs2:x13(0x00000000000000ff), result rd:x5(0x0000000000000000)
li x25, MASK_XLEN(0x624b3e976c52dd14)
li x13, MASK_XLEN(0x00000000000000ff)
SLTU x5, x25, x13
sd x5, 408(x6)

# Testcase 52:  rs1:x18(0x624b3e976c52dd14), rs2:x21(0x624b3e976c52dd14), result rd:x15(0x0000000000000000)
li x18, MASK_XLEN(0x624b3e976c52dd14)
li x21, MASK_XLEN(0x624b3e976c52dd14)
SLTU x15, x18, x21
sd x15, 416(x6)

# Testcase 53:  rs1:x29(0x624b3e976c52dd14), rs2:x20(0x7ffffffffffffffe), result rd:x23(0x0000000000000001)
li x29, MASK_XLEN(0x624b3e976c52dd14)
li x20, MASK_XLEN(0x7ffffffffffffffe)
SLTU x23, x29, x20
sd x23, 424(x6)

# Testcase 54:  rs1:x27(0x624b3e976c52dd14), rs2:x12(0x7fffffffffffffff), result rd:x30(0x0000000000000001)
li x27, MASK_XLEN(0x624b3e976c52dd14)
li x12, MASK_XLEN(0x7fffffffffffffff)
SLTU x30, x27, x12
sd x30, 432(x6)

# Testcase 55:  rs1:x2(0x624b3e976c52dd14), rs2:x21(0x8000000000000000), result rd:x20(0x0000000000000001)
li x2, MASK_XLEN(0x624b3e976c52dd14)
li x21, MASK_XLEN(0x8000000000000000)
SLTU x20, x2, x21
sd x20, 440(x6)

# Testcase 56:  rs1:x17(0x624b3e976c52dd14), rs2:x8(0x8000000000000001), result rd:x7(0x0000000000000001)
li x17, MASK_XLEN(0x624b3e976c52dd14)
li x8, MASK_XLEN(0x8000000000000001)
SLTU x7, x17, x8
sd x7, 448(x6)

# Testcase 57:  rs1:x17(0x624b3e976c52dd14), rs2:x13(0xc365ddeb9173ab42), result rd:x16(0x0000000000000001)
li x17, MASK_XLEN(0x624b3e976c52dd14)
li x13, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x16, x17, x13
sd x16, 456(x6)

# Testcase 58:  rs1:x8(0x624b3e976c52dd14), rs2:x19(0xfffffffffffffffe), result rd:x24(0x0000000000000001)
li x8, MASK_XLEN(0x624b3e976c52dd14)
li x19, MASK_XLEN(0xfffffffffffffffe)
SLTU x24, x8, x19
sd x24, 464(x6)

# Testcase 59:  rs1:x3(0x624b3e976c52dd14), rs2:x18(0xffffffffffffffff), result rd:x4(0x0000000000000001)
li x3, MASK_XLEN(0x624b3e976c52dd14)
li x18, MASK_XLEN(0xffffffffffffffff)
SLTU x4, x3, x18
sd x4, 472(x6)

# Testcase 60:  rs1:x10(0x7ffffffffffffffe), rs2:x1(0x0000000000000000), result rd:x11(0x0000000000000000)
li x10, MASK_XLEN(0x7ffffffffffffffe)
li x1, MASK_XLEN(0x0000000000000000)
SLTU x11, x10, x1
sd x11, 480(x6)

# Testcase 61:  rs1:x4(0x7ffffffffffffffe), rs2:x5(0x0000000000000001), result rd:x20(0x0000000000000000)
li x4, MASK_XLEN(0x7ffffffffffffffe)
li x5, MASK_XLEN(0x0000000000000001)
SLTU x20, x4, x5
sd x20, 488(x6)

# Testcase 62:  rs1:x31(0x7ffffffffffffffe), rs2:x21(0x0000000000000002), result rd:x17(0x0000000000000000)
li x31, MASK_XLEN(0x7ffffffffffffffe)
li x21, MASK_XLEN(0x0000000000000002)
SLTU x17, x31, x21
sd x17, 496(x6)

# Testcase 63:  rs1:x18(0x7ffffffffffffffe), rs2:x14(0x00000000000000ff), result rd:x9(0x0000000000000000)
li x18, MASK_XLEN(0x7ffffffffffffffe)
li x14, MASK_XLEN(0x00000000000000ff)
SLTU x9, x18, x14
sd x9, 504(x6)

# Testcase 64:  rs1:x1(0x7ffffffffffffffe), rs2:x25(0x624b3e976c52dd14), result rd:x26(0x0000000000000000)
li x1, MASK_XLEN(0x7ffffffffffffffe)
li x25, MASK_XLEN(0x624b3e976c52dd14)
SLTU x26, x1, x25
sd x26, 512(x6)

# Testcase 65:  rs1:x12(0x7ffffffffffffffe), rs2:x5(0x7ffffffffffffffe), result rd:x2(0x0000000000000000)
li x12, MASK_XLEN(0x7ffffffffffffffe)
li x5, MASK_XLEN(0x7ffffffffffffffe)
SLTU x2, x12, x5
sd x2, 520(x6)

# Testcase 66:  rs1:x17(0x7ffffffffffffffe), rs2:x7(0x7fffffffffffffff), result rd:x23(0x0000000000000001)
li x17, MASK_XLEN(0x7ffffffffffffffe)
li x7, MASK_XLEN(0x7fffffffffffffff)
SLTU x23, x17, x7
sd x23, 528(x6)

# Testcase 67:  rs1:x15(0x7ffffffffffffffe), rs2:x22(0x8000000000000000), result rd:x20(0x0000000000000001)
li x15, MASK_XLEN(0x7ffffffffffffffe)
li x22, MASK_XLEN(0x8000000000000000)
SLTU x20, x15, x22
sd x20, 536(x6)

# Testcase 68:  rs1:x9(0x7ffffffffffffffe), rs2:x25(0x8000000000000001), result rd:x14(0x0000000000000001)
li x9, MASK_XLEN(0x7ffffffffffffffe)
li x25, MASK_XLEN(0x8000000000000001)
SLTU x14, x9, x25
sd x14, 544(x6)

# Testcase 69:  rs1:x28(0x7ffffffffffffffe), rs2:x30(0xc365ddeb9173ab42), result rd:x25(0x0000000000000001)
li x28, MASK_XLEN(0x7ffffffffffffffe)
li x30, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x25, x28, x30
sd x25, 552(x6)

# Testcase 70:  rs1:x2(0x7ffffffffffffffe), rs2:x25(0xfffffffffffffffe), result rd:x8(0x0000000000000001)
li x2, MASK_XLEN(0x7ffffffffffffffe)
li x25, MASK_XLEN(0xfffffffffffffffe)
SLTU x8, x2, x25
sd x8, 560(x6)

# Testcase 71:  rs1:x19(0x7ffffffffffffffe), rs2:x9(0xffffffffffffffff), result rd:x7(0x0000000000000001)
li x19, MASK_XLEN(0x7ffffffffffffffe)
li x9, MASK_XLEN(0xffffffffffffffff)
SLTU x7, x19, x9
sd x7, 568(x6)

# Testcase 72:  rs1:x11(0x7fffffffffffffff), rs2:x22(0x0000000000000000), result rd:x4(0x0000000000000000)
li x11, MASK_XLEN(0x7fffffffffffffff)
li x22, MASK_XLEN(0x0000000000000000)
SLTU x4, x11, x22
sd x4, 576(x6)

# Testcase 73:  rs1:x23(0x7fffffffffffffff), rs2:x27(0x0000000000000001), result rd:x9(0x0000000000000000)
li x23, MASK_XLEN(0x7fffffffffffffff)
li x27, MASK_XLEN(0x0000000000000001)
SLTU x9, x23, x27
sd x9, 584(x6)

# Testcase 74:  rs1:x16(0x7fffffffffffffff), rs2:x12(0x0000000000000002), result rd:x27(0x0000000000000000)
li x16, MASK_XLEN(0x7fffffffffffffff)
li x12, MASK_XLEN(0x0000000000000002)
SLTU x27, x16, x12
sd x27, 592(x6)

# Testcase 75:  rs1:x10(0x7fffffffffffffff), rs2:x2(0x00000000000000ff), result rd:x9(0x0000000000000000)
li x10, MASK_XLEN(0x7fffffffffffffff)
li x2, MASK_XLEN(0x00000000000000ff)
SLTU x9, x10, x2
sd x9, 600(x6)

# Testcase 76:  rs1:x23(0x7fffffffffffffff), rs2:x4(0x624b3e976c52dd14), result rd:x12(0x0000000000000000)
li x23, MASK_XLEN(0x7fffffffffffffff)
li x4, MASK_XLEN(0x624b3e976c52dd14)
SLTU x12, x23, x4
sd x12, 608(x6)

# Testcase 77:  rs1:x10(0x7fffffffffffffff), rs2:x7(0x7ffffffffffffffe), result rd:x30(0x0000000000000000)
li x10, MASK_XLEN(0x7fffffffffffffff)
li x7, MASK_XLEN(0x7ffffffffffffffe)
SLTU x30, x10, x7
sd x30, 616(x6)

# Testcase 78:  rs1:x11(0x7fffffffffffffff), rs2:x8(0x7fffffffffffffff), result rd:x8(0x0000000000000000)
li x11, MASK_XLEN(0x7fffffffffffffff)
li x8, MASK_XLEN(0x7fffffffffffffff)
SLTU x8, x11, x8
sd x8, 624(x6)

# Testcase 79:  rs1:x27(0x7fffffffffffffff), rs2:x7(0x8000000000000000), result rd:x7(0x0000000000000001)
li x27, MASK_XLEN(0x7fffffffffffffff)
li x7, MASK_XLEN(0x8000000000000000)
SLTU x7, x27, x7
sd x7, 632(x6)

# Testcase 80:  rs1:x22(0x7fffffffffffffff), rs2:x13(0x8000000000000001), result rd:x4(0x0000000000000001)
li x22, MASK_XLEN(0x7fffffffffffffff)
li x13, MASK_XLEN(0x8000000000000001)
SLTU x4, x22, x13
sd x4, 640(x6)

# Testcase 81:  rs1:x18(0x7fffffffffffffff), rs2:x9(0xc365ddeb9173ab42), result rd:x22(0x0000000000000001)
li x18, MASK_XLEN(0x7fffffffffffffff)
li x9, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x22, x18, x9
sd x22, 648(x6)

# Testcase 82:  rs1:x29(0x7fffffffffffffff), rs2:x13(0xfffffffffffffffe), result rd:x1(0x0000000000000001)
li x29, MASK_XLEN(0x7fffffffffffffff)
li x13, MASK_XLEN(0xfffffffffffffffe)
SLTU x1, x29, x13
sd x1, 656(x6)

# Testcase 83:  rs1:x29(0x7fffffffffffffff), rs2:x18(0xffffffffffffffff), result rd:x22(0x0000000000000001)
li x29, MASK_XLEN(0x7fffffffffffffff)
li x18, MASK_XLEN(0xffffffffffffffff)
SLTU x22, x29, x18
sd x22, 664(x6)

# Testcase 84:  rs1:x2(0x8000000000000000), rs2:x18(0x0000000000000000), result rd:x14(0x0000000000000000)
li x2, MASK_XLEN(0x8000000000000000)
li x18, MASK_XLEN(0x0000000000000000)
SLTU x14, x2, x18
sd x14, 672(x6)

# Testcase 85:  rs1:x22(0x8000000000000000), rs2:x4(0x0000000000000001), result rd:x9(0x0000000000000000)
li x22, MASK_XLEN(0x8000000000000000)
li x4, MASK_XLEN(0x0000000000000001)
SLTU x9, x22, x4
sd x9, 680(x6)

# Testcase 86:  rs1:x26(0x8000000000000000), rs2:x23(0x0000000000000002), result rd:x7(0x0000000000000000)
li x26, MASK_XLEN(0x8000000000000000)
li x23, MASK_XLEN(0x0000000000000002)
SLTU x7, x26, x23
sd x7, 688(x6)

# Testcase 87:  rs1:x17(0x8000000000000000), rs2:x10(0x00000000000000ff), result rd:x24(0x0000000000000000)
li x17, MASK_XLEN(0x8000000000000000)
li x10, MASK_XLEN(0x00000000000000ff)
SLTU x24, x17, x10
sd x24, 696(x6)

# Testcase 88:  rs1:x3(0x8000000000000000), rs2:x29(0x624b3e976c52dd14), result rd:x31(0x0000000000000000)
li x3, MASK_XLEN(0x8000000000000000)
li x29, MASK_XLEN(0x624b3e976c52dd14)
SLTU x31, x3, x29
sd x31, 704(x6)

# Testcase 89:  rs1:x4(0x8000000000000000), rs2:x17(0x7ffffffffffffffe), result rd:x14(0x0000000000000000)
li x4, MASK_XLEN(0x8000000000000000)
li x17, MASK_XLEN(0x7ffffffffffffffe)
SLTU x14, x4, x17
sd x14, 712(x6)

# Testcase 90:  rs1:x22(0x8000000000000000), rs2:x18(0x7fffffffffffffff), result rd:x12(0x0000000000000000)
li x22, MASK_XLEN(0x8000000000000000)
li x18, MASK_XLEN(0x7fffffffffffffff)
SLTU x12, x22, x18
sd x12, 720(x6)

# Testcase 91:  rs1:x4(0x8000000000000000), rs2:x10(0x8000000000000000), result rd:x24(0x0000000000000000)
li x4, MASK_XLEN(0x8000000000000000)
li x10, MASK_XLEN(0x8000000000000000)
SLTU x24, x4, x10
sd x24, 728(x6)

# Testcase 92:  rs1:x28(0x8000000000000000), rs2:x26(0x8000000000000001), result rd:x24(0x0000000000000001)
li x28, MASK_XLEN(0x8000000000000000)
li x26, MASK_XLEN(0x8000000000000001)
SLTU x24, x28, x26
sd x24, 736(x6)

# Testcase 93:  rs1:x16(0x8000000000000000), rs2:x29(0xc365ddeb9173ab42), result rd:x10(0x0000000000000001)
li x16, MASK_XLEN(0x8000000000000000)
li x29, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x10, x16, x29
sd x10, 744(x6)

# Testcase 94:  rs1:x8(0x8000000000000000), rs2:x31(0xfffffffffffffffe), result rd:x30(0x0000000000000001)
li x8, MASK_XLEN(0x8000000000000000)
li x31, MASK_XLEN(0xfffffffffffffffe)
SLTU x30, x8, x31
sd x30, 752(x6)

# Testcase 95:  rs1:x28(0x8000000000000000), rs2:x30(0xffffffffffffffff), result rd:x18(0x0000000000000001)
li x28, MASK_XLEN(0x8000000000000000)
li x30, MASK_XLEN(0xffffffffffffffff)
SLTU x18, x28, x30
sd x18, 760(x6)

# Testcase 96:  rs1:x19(0x8000000000000001), rs2:x23(0x0000000000000000), result rd:x8(0x0000000000000000)
li x19, MASK_XLEN(0x8000000000000001)
li x23, MASK_XLEN(0x0000000000000000)
SLTU x8, x19, x23
sd x8, 768(x6)

# Testcase 97:  rs1:x3(0x8000000000000001), rs2:x16(0x0000000000000001), result rd:x26(0x0000000000000000)
li x3, MASK_XLEN(0x8000000000000001)
li x16, MASK_XLEN(0x0000000000000001)
SLTU x26, x3, x16
sd x26, 776(x6)

# Testcase 98:  rs1:x7(0x8000000000000001), rs2:x12(0x0000000000000002), result rd:x14(0x0000000000000000)
li x7, MASK_XLEN(0x8000000000000001)
li x12, MASK_XLEN(0x0000000000000002)
SLTU x14, x7, x12
sd x14, 784(x6)

# Testcase 99:  rs1:x9(0x8000000000000001), rs2:x30(0x00000000000000ff), result rd:x11(0x0000000000000000)
li x9, MASK_XLEN(0x8000000000000001)
li x30, MASK_XLEN(0x00000000000000ff)
SLTU x11, x9, x30
sd x11, 792(x6)

# Testcase 100:  rs1:x30(0x8000000000000001), rs2:x29(0x624b3e976c52dd14), result rd:x4(0x0000000000000000)
li x30, MASK_XLEN(0x8000000000000001)
li x29, MASK_XLEN(0x624b3e976c52dd14)
SLTU x4, x30, x29
sd x4, 800(x6)

# Testcase 101:  rs1:x26(0x8000000000000001), rs2:x5(0x7ffffffffffffffe), result rd:x15(0x0000000000000000)
li x26, MASK_XLEN(0x8000000000000001)
li x5, MASK_XLEN(0x7ffffffffffffffe)
SLTU x15, x26, x5
sd x15, 808(x6)

# Testcase 102:  rs1:x27(0x8000000000000001), rs2:x21(0x7fffffffffffffff), result rd:x12(0x0000000000000000)
li x27, MASK_XLEN(0x8000000000000001)
li x21, MASK_XLEN(0x7fffffffffffffff)
SLTU x12, x27, x21
sd x12, 816(x6)

# Testcase 103:  rs1:x17(0x8000000000000001), rs2:x5(0x8000000000000000), result rd:x3(0x0000000000000000)
li x17, MASK_XLEN(0x8000000000000001)
li x5, MASK_XLEN(0x8000000000000000)
SLTU x3, x17, x5
sd x3, 824(x6)

# Testcase 104:  rs1:x30(0x8000000000000001), rs2:x25(0x8000000000000001), result rd:x15(0x0000000000000000)
li x30, MASK_XLEN(0x8000000000000001)
li x25, MASK_XLEN(0x8000000000000001)
SLTU x15, x30, x25
sd x15, 832(x6)

# Testcase 105:  rs1:x13(0x8000000000000001), rs2:x25(0xc365ddeb9173ab42), result rd:x16(0x0000000000000001)
li x13, MASK_XLEN(0x8000000000000001)
li x25, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x16, x13, x25
sd x16, 840(x6)

# Testcase 106:  rs1:x11(0x8000000000000001), rs2:x27(0xfffffffffffffffe), result rd:x20(0x0000000000000001)
li x11, MASK_XLEN(0x8000000000000001)
li x27, MASK_XLEN(0xfffffffffffffffe)
SLTU x20, x11, x27
sd x20, 848(x6)

# Testcase 107:  rs1:x10(0x8000000000000001), rs2:x16(0xffffffffffffffff), result rd:x5(0x0000000000000001)
li x10, MASK_XLEN(0x8000000000000001)
li x16, MASK_XLEN(0xffffffffffffffff)
SLTU x5, x10, x16
sd x5, 856(x6)

# Testcase 108:  rs1:x10(0xc365ddeb9173ab42), rs2:x2(0x0000000000000000), result rd:x14(0x0000000000000000)
li x10, MASK_XLEN(0xc365ddeb9173ab42)
li x2, MASK_XLEN(0x0000000000000000)
SLTU x14, x10, x2
sd x14, 864(x6)

# Testcase 109:  rs1:x23(0xc365ddeb9173ab42), rs2:x26(0x0000000000000001), result rd:x3(0x0000000000000000)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
li x26, MASK_XLEN(0x0000000000000001)
SLTU x3, x23, x26
sd x3, 872(x6)

# Testcase 110:  rs1:x3(0xc365ddeb9173ab42), rs2:x25(0x0000000000000002), result rd:x4(0x0000000000000000)
li x3, MASK_XLEN(0xc365ddeb9173ab42)
li x25, MASK_XLEN(0x0000000000000002)
SLTU x4, x3, x25
sd x4, 880(x6)

# Testcase 111:  rs1:x28(0xc365ddeb9173ab42), rs2:x13(0x00000000000000ff), result rd:x8(0x0000000000000000)
li x28, MASK_XLEN(0xc365ddeb9173ab42)
li x13, MASK_XLEN(0x00000000000000ff)
SLTU x8, x28, x13
sd x8, 888(x6)

# Testcase 112:  rs1:x10(0xc365ddeb9173ab42), rs2:x21(0x624b3e976c52dd14), result rd:x4(0x0000000000000000)
li x10, MASK_XLEN(0xc365ddeb9173ab42)
li x21, MASK_XLEN(0x624b3e976c52dd14)
SLTU x4, x10, x21
sd x4, 896(x6)

# Testcase 113:  rs1:x14(0xc365ddeb9173ab42), rs2:x31(0x7ffffffffffffffe), result rd:x21(0x0000000000000000)
li x14, MASK_XLEN(0xc365ddeb9173ab42)
li x31, MASK_XLEN(0x7ffffffffffffffe)
SLTU x21, x14, x31
sd x21, 904(x6)

# Testcase 114:  rs1:x31(0xc365ddeb9173ab42), rs2:x19(0x7fffffffffffffff), result rd:x31(0x0000000000000000)
li x31, MASK_XLEN(0xc365ddeb9173ab42)
li x19, MASK_XLEN(0x7fffffffffffffff)
SLTU x31, x31, x19
sd x31, 912(x6)

# Testcase 115:  rs1:x10(0xc365ddeb9173ab42), rs2:x18(0x8000000000000000), result rd:x30(0x0000000000000000)
li x10, MASK_XLEN(0xc365ddeb9173ab42)
li x18, MASK_XLEN(0x8000000000000000)
SLTU x30, x10, x18
sd x30, 920(x6)

# Testcase 116:  rs1:x1(0xc365ddeb9173ab42), rs2:x19(0x8000000000000001), result rd:x2(0x0000000000000000)
li x1, MASK_XLEN(0xc365ddeb9173ab42)
li x19, MASK_XLEN(0x8000000000000001)
SLTU x2, x1, x19
sd x2, 928(x6)

# Testcase 117:  rs1:x13(0xc365ddeb9173ab42), rs2:x24(0xc365ddeb9173ab42), result rd:x14(0x0000000000000000)
li x13, MASK_XLEN(0xc365ddeb9173ab42)
li x24, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x14, x13, x24
sd x14, 936(x6)

# Testcase 118:  rs1:x17(0xc365ddeb9173ab42), rs2:x12(0xfffffffffffffffe), result rd:x8(0x0000000000000001)
li x17, MASK_XLEN(0xc365ddeb9173ab42)
li x12, MASK_XLEN(0xfffffffffffffffe)
SLTU x8, x17, x12
sd x8, 944(x6)

# Testcase 119:  rs1:x29(0xc365ddeb9173ab42), rs2:x25(0xffffffffffffffff), result rd:x8(0x0000000000000001)
li x29, MASK_XLEN(0xc365ddeb9173ab42)
li x25, MASK_XLEN(0xffffffffffffffff)
SLTU x8, x29, x25
sd x8, 952(x6)

# Testcase 120:  rs1:x4(0xfffffffffffffffe), rs2:x31(0x0000000000000000), result rd:x4(0x0000000000000000)
li x4, MASK_XLEN(0xfffffffffffffffe)
li x31, MASK_XLEN(0x0000000000000000)
SLTU x4, x4, x31
sd x4, 960(x6)

# Testcase 121:  rs1:x18(0xfffffffffffffffe), rs2:x20(0x0000000000000001), result rd:x5(0x0000000000000000)
li x18, MASK_XLEN(0xfffffffffffffffe)
li x20, MASK_XLEN(0x0000000000000001)
SLTU x5, x18, x20
sd x5, 968(x6)

# Testcase 122:  rs1:x10(0xfffffffffffffffe), rs2:x12(0x0000000000000002), result rd:x16(0x0000000000000000)
li x10, MASK_XLEN(0xfffffffffffffffe)
li x12, MASK_XLEN(0x0000000000000002)
SLTU x16, x10, x12
sd x16, 976(x6)

# Testcase 123:  rs1:x17(0xfffffffffffffffe), rs2:x8(0x00000000000000ff), result rd:x14(0x0000000000000000)
li x17, MASK_XLEN(0xfffffffffffffffe)
li x8, MASK_XLEN(0x00000000000000ff)
SLTU x14, x17, x8
sd x14, 984(x6)

# Testcase 124:  rs1:x25(0xfffffffffffffffe), rs2:x5(0x624b3e976c52dd14), result rd:x30(0x0000000000000000)
li x25, MASK_XLEN(0xfffffffffffffffe)
li x5, MASK_XLEN(0x624b3e976c52dd14)
SLTU x30, x25, x5
sd x30, 992(x6)

# Testcase 125:  rs1:x25(0xfffffffffffffffe), rs2:x22(0x7ffffffffffffffe), result rd:x28(0x0000000000000000)
li x25, MASK_XLEN(0xfffffffffffffffe)
li x22, MASK_XLEN(0x7ffffffffffffffe)
SLTU x28, x25, x22
sd x28, 1000(x6)

# Testcase 126:  rs1:x1(0xfffffffffffffffe), rs2:x11(0x7fffffffffffffff), result rd:x5(0x0000000000000000)
li x1, MASK_XLEN(0xfffffffffffffffe)
li x11, MASK_XLEN(0x7fffffffffffffff)
SLTU x5, x1, x11
sd x5, 1008(x6)

# Testcase 127:  rs1:x4(0xfffffffffffffffe), rs2:x17(0x8000000000000000), result rd:x11(0x0000000000000000)
li x4, MASK_XLEN(0xfffffffffffffffe)
li x17, MASK_XLEN(0x8000000000000000)
SLTU x11, x4, x17
sd x11, 1016(x6)

# Testcase 128:  rs1:x20(0xfffffffffffffffe), rs2:x29(0x8000000000000001), result rd:x8(0x0000000000000000)
li x20, MASK_XLEN(0xfffffffffffffffe)
li x29, MASK_XLEN(0x8000000000000001)
SLTU x8, x20, x29
sd x8, 1024(x6)

# Testcase 129:  rs1:x4(0xfffffffffffffffe), rs2:x24(0xc365ddeb9173ab42), result rd:x24(0x0000000000000000)
li x4, MASK_XLEN(0xfffffffffffffffe)
li x24, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x24, x4, x24
sd x24, 1032(x6)

# Testcase 130:  rs1:x29(0xfffffffffffffffe), rs2:x18(0xfffffffffffffffe), result rd:x30(0x0000000000000000)
li x29, MASK_XLEN(0xfffffffffffffffe)
li x18, MASK_XLEN(0xfffffffffffffffe)
SLTU x30, x29, x18
sd x30, 1040(x6)

# Testcase 131:  rs1:x4(0xfffffffffffffffe), rs2:x24(0xffffffffffffffff), result rd:x22(0x0000000000000001)
li x4, MASK_XLEN(0xfffffffffffffffe)
li x24, MASK_XLEN(0xffffffffffffffff)
SLTU x22, x4, x24
sd x22, 1048(x6)

# Testcase 132:  rs1:x16(0xffffffffffffffff), rs2:x17(0x0000000000000000), result rd:x20(0x0000000000000000)
li x16, MASK_XLEN(0xffffffffffffffff)
li x17, MASK_XLEN(0x0000000000000000)
SLTU x20, x16, x17
sd x20, 1056(x6)

# Testcase 133:  rs1:x23(0xffffffffffffffff), rs2:x30(0x0000000000000001), result rd:x30(0x0000000000000000)
li x23, MASK_XLEN(0xffffffffffffffff)
li x30, MASK_XLEN(0x0000000000000001)
SLTU x30, x23, x30
sd x30, 1064(x6)

# Testcase 134:  rs1:x16(0xffffffffffffffff), rs2:x10(0x0000000000000002), result rd:x11(0x0000000000000000)
li x16, MASK_XLEN(0xffffffffffffffff)
li x10, MASK_XLEN(0x0000000000000002)
SLTU x11, x16, x10
sd x11, 1072(x6)

# Testcase 135:  rs1:x29(0xffffffffffffffff), rs2:x20(0x00000000000000ff), result rd:x3(0x0000000000000000)
li x29, MASK_XLEN(0xffffffffffffffff)
li x20, MASK_XLEN(0x00000000000000ff)
SLTU x3, x29, x20
sd x3, 1080(x6)

# Testcase 136:  rs1:x7(0xffffffffffffffff), rs2:x2(0x624b3e976c52dd14), result rd:x21(0x0000000000000000)
li x7, MASK_XLEN(0xffffffffffffffff)
li x2, MASK_XLEN(0x624b3e976c52dd14)
SLTU x21, x7, x2
sd x21, 1088(x6)

# Testcase 137:  rs1:x30(0xffffffffffffffff), rs2:x13(0x7ffffffffffffffe), result rd:x9(0x0000000000000000)
li x30, MASK_XLEN(0xffffffffffffffff)
li x13, MASK_XLEN(0x7ffffffffffffffe)
SLTU x9, x30, x13
sd x9, 1096(x6)

# Testcase 138:  rs1:x17(0xffffffffffffffff), rs2:x23(0x7fffffffffffffff), result rd:x11(0x0000000000000000)
li x17, MASK_XLEN(0xffffffffffffffff)
li x23, MASK_XLEN(0x7fffffffffffffff)
SLTU x11, x17, x23
sd x11, 1104(x6)

# Testcase 139:  rs1:x8(0xffffffffffffffff), rs2:x19(0x8000000000000000), result rd:x29(0x0000000000000000)
li x8, MASK_XLEN(0xffffffffffffffff)
li x19, MASK_XLEN(0x8000000000000000)
SLTU x29, x8, x19
sd x29, 1112(x6)

# Testcase 140:  rs1:x11(0xffffffffffffffff), rs2:x9(0x8000000000000001), result rd:x24(0x0000000000000000)
li x11, MASK_XLEN(0xffffffffffffffff)
li x9, MASK_XLEN(0x8000000000000001)
SLTU x24, x11, x9
sd x24, 1120(x6)

# Testcase 141:  rs1:x26(0xffffffffffffffff), rs2:x24(0xc365ddeb9173ab42), result rd:x23(0x0000000000000000)
li x26, MASK_XLEN(0xffffffffffffffff)
li x24, MASK_XLEN(0xc365ddeb9173ab42)
SLTU x23, x26, x24
sd x23, 1128(x6)

# Testcase 142:  rs1:x29(0xffffffffffffffff), rs2:x3(0xfffffffffffffffe), result rd:x26(0x0000000000000000)
li x29, MASK_XLEN(0xffffffffffffffff)
li x3, MASK_XLEN(0xfffffffffffffffe)
SLTU x26, x29, x3
sd x26, 1136(x6)

# Testcase 143:  rs1:x27(0xffffffffffffffff), rs2:x15(0xffffffffffffffff), result rd:x26(0x0000000000000000)
li x27, MASK_XLEN(0xffffffffffffffff)
li x15, MASK_XLEN(0xffffffffffffffff)
SLTU x26, x27, x15
sd x26, 1144(x6)

# Testcase 144:  rs1:x15(0x09ca574d20979829), rs2:x30(0x18cb4e11abe04a61), result rd:x23(0x0000000000000001)
li x15, MASK_XLEN(0x09ca574d20979829)
li x30, MASK_XLEN(0x18cb4e11abe04a61)
SLTU x23, x15, x30
sd x23, 1152(x6)

# Testcase 145:  rs1:x9(0xfcfa3a3b47f050aa), rs2:x15(0x55b3b1acc34920a7), result rd:x1(0x0000000000000000)
li x9, MASK_XLEN(0xfcfa3a3b47f050aa)
li x15, MASK_XLEN(0x55b3b1acc34920a7)
SLTU x1, x9, x15
sd x1, 1160(x6)

# Testcase 146:  rs1:x8(0xbb8bb9ae57e061c6), rs2:x27(0xa35c56b352403e1d), result rd:x12(0x0000000000000000)
li x8, MASK_XLEN(0xbb8bb9ae57e061c6)
li x27, MASK_XLEN(0xa35c56b352403e1d)
SLTU x12, x8, x27
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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLTU.S
// David_Harris@hmc.edu & Katherine Parry

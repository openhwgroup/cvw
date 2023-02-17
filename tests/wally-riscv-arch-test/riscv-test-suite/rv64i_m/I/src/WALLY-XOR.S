///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-XOR.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.550760//
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

# Testcase 0:  rs1:x24(0x0000000000000000), rs2:x12(0x0000000000000000), result rd:x12(0x0000000000000000)
li x24, MASK_XLEN(0x0000000000000000)
li x12, MASK_XLEN(0x0000000000000000)
XOR x12, x24, x12
sd x12, 0(x6)

# Testcase 1:  rs1:x30(0x0000000000000000), rs2:x31(0x0000000000000001), result rd:x23(0x0000000000000001)
li x30, MASK_XLEN(0x0000000000000000)
li x31, MASK_XLEN(0x0000000000000001)
XOR x23, x30, x31
sd x23, 8(x6)

# Testcase 2:  rs1:x13(0x0000000000000000), rs2:x7(0x0000000000000002), result rd:x1(0x0000000000000002)
li x13, MASK_XLEN(0x0000000000000000)
li x7, MASK_XLEN(0x0000000000000002)
XOR x1, x13, x7
sd x1, 16(x6)

# Testcase 3:  rs1:x13(0x0000000000000000), rs2:x31(0x00000000000000ff), result rd:x21(0x00000000000000ff)
li x13, MASK_XLEN(0x0000000000000000)
li x31, MASK_XLEN(0x00000000000000ff)
XOR x21, x13, x31
sd x21, 24(x6)

# Testcase 4:  rs1:x19(0x0000000000000000), rs2:x18(0x624b3e976c52dd14), result rd:x10(0x624b3e976c52dd14)
li x19, MASK_XLEN(0x0000000000000000)
li x18, MASK_XLEN(0x624b3e976c52dd14)
XOR x10, x19, x18
sd x10, 32(x6)

# Testcase 5:  rs1:x13(0x0000000000000000), rs2:x26(0x7ffffffffffffffe), result rd:x20(0x7ffffffffffffffe)
li x13, MASK_XLEN(0x0000000000000000)
li x26, MASK_XLEN(0x7ffffffffffffffe)
XOR x20, x13, x26
sd x20, 40(x6)

# Testcase 6:  rs1:x1(0x0000000000000000), rs2:x18(0x7fffffffffffffff), result rd:x28(0x7fffffffffffffff)
li x1, MASK_XLEN(0x0000000000000000)
li x18, MASK_XLEN(0x7fffffffffffffff)
XOR x28, x1, x18
sd x28, 48(x6)

# Testcase 7:  rs1:x29(0x0000000000000000), rs2:x4(0x8000000000000000), result rd:x11(0x8000000000000000)
li x29, MASK_XLEN(0x0000000000000000)
li x4, MASK_XLEN(0x8000000000000000)
XOR x11, x29, x4
sd x11, 56(x6)

# Testcase 8:  rs1:x1(0x0000000000000000), rs2:x14(0x8000000000000001), result rd:x5(0x8000000000000001)
li x1, MASK_XLEN(0x0000000000000000)
li x14, MASK_XLEN(0x8000000000000001)
XOR x5, x1, x14
sd x5, 64(x6)

# Testcase 9:  rs1:x3(0x0000000000000000), rs2:x27(0xc365ddeb9173ab42), result rd:x5(0xc365ddeb9173ab42)
li x3, MASK_XLEN(0x0000000000000000)
li x27, MASK_XLEN(0xc365ddeb9173ab42)
XOR x5, x3, x27
sd x5, 72(x6)

# Testcase 10:  rs1:x2(0x0000000000000000), rs2:x22(0xfffffffffffffffe), result rd:x30(0xfffffffffffffffe)
li x2, MASK_XLEN(0x0000000000000000)
li x22, MASK_XLEN(0xfffffffffffffffe)
XOR x30, x2, x22
sd x30, 80(x6)

# Testcase 11:  rs1:x18(0x0000000000000000), rs2:x10(0xffffffffffffffff), result rd:x31(0xffffffffffffffff)
li x18, MASK_XLEN(0x0000000000000000)
li x10, MASK_XLEN(0xffffffffffffffff)
XOR x31, x18, x10
sd x31, 88(x6)

# Testcase 12:  rs1:x7(0x0000000000000001), rs2:x25(0x0000000000000000), result rd:x21(0x0000000000000001)
li x7, MASK_XLEN(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000000)
XOR x21, x7, x25
sd x21, 96(x6)

# Testcase 13:  rs1:x12(0x0000000000000001), rs2:x8(0x0000000000000001), result rd:x19(0x0000000000000000)
li x12, MASK_XLEN(0x0000000000000001)
li x8, MASK_XLEN(0x0000000000000001)
XOR x19, x12, x8
sd x19, 104(x6)

# Testcase 14:  rs1:x3(0x0000000000000001), rs2:x25(0x0000000000000002), result rd:x8(0x0000000000000003)
li x3, MASK_XLEN(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000002)
XOR x8, x3, x25
sd x8, 112(x6)

# Testcase 15:  rs1:x22(0x0000000000000001), rs2:x14(0x00000000000000ff), result rd:x11(0x00000000000000fe)
li x22, MASK_XLEN(0x0000000000000001)
li x14, MASK_XLEN(0x00000000000000ff)
XOR x11, x22, x14
sd x11, 120(x6)

# Testcase 16:  rs1:x21(0x0000000000000001), rs2:x10(0x624b3e976c52dd14), result rd:x1(0x624b3e976c52dd15)
li x21, MASK_XLEN(0x0000000000000001)
li x10, MASK_XLEN(0x624b3e976c52dd14)
XOR x1, x21, x10
sd x1, 128(x6)

# Testcase 17:  rs1:x3(0x0000000000000001), rs2:x15(0x7ffffffffffffffe), result rd:x9(0x7fffffffffffffff)
li x3, MASK_XLEN(0x0000000000000001)
li x15, MASK_XLEN(0x7ffffffffffffffe)
XOR x9, x3, x15
sd x9, 136(x6)

# Testcase 18:  rs1:x21(0x0000000000000001), rs2:x31(0x7fffffffffffffff), result rd:x13(0x7ffffffffffffffe)
li x21, MASK_XLEN(0x0000000000000001)
li x31, MASK_XLEN(0x7fffffffffffffff)
XOR x13, x21, x31
sd x13, 144(x6)

# Testcase 19:  rs1:x30(0x0000000000000001), rs2:x15(0x8000000000000000), result rd:x1(0x8000000000000001)
li x30, MASK_XLEN(0x0000000000000001)
li x15, MASK_XLEN(0x8000000000000000)
XOR x1, x30, x15
sd x1, 152(x6)

# Testcase 20:  rs1:x30(0x0000000000000001), rs2:x2(0x8000000000000001), result rd:x3(0x8000000000000000)
li x30, MASK_XLEN(0x0000000000000001)
li x2, MASK_XLEN(0x8000000000000001)
XOR x3, x30, x2
sd x3, 160(x6)

# Testcase 21:  rs1:x12(0x0000000000000001), rs2:x25(0xc365ddeb9173ab42), result rd:x2(0xc365ddeb9173ab43)
li x12, MASK_XLEN(0x0000000000000001)
li x25, MASK_XLEN(0xc365ddeb9173ab42)
XOR x2, x12, x25
sd x2, 168(x6)

# Testcase 22:  rs1:x22(0x0000000000000001), rs2:x8(0xfffffffffffffffe), result rd:x28(0xffffffffffffffff)
li x22, MASK_XLEN(0x0000000000000001)
li x8, MASK_XLEN(0xfffffffffffffffe)
XOR x28, x22, x8
sd x28, 176(x6)

# Testcase 23:  rs1:x8(0x0000000000000001), rs2:x16(0xffffffffffffffff), result rd:x9(0xfffffffffffffffe)
li x8, MASK_XLEN(0x0000000000000001)
li x16, MASK_XLEN(0xffffffffffffffff)
XOR x9, x8, x16
sd x9, 184(x6)

# Testcase 24:  rs1:x10(0x0000000000000002), rs2:x19(0x0000000000000000), result rd:x26(0x0000000000000002)
li x10, MASK_XLEN(0x0000000000000002)
li x19, MASK_XLEN(0x0000000000000000)
XOR x26, x10, x19
sd x26, 192(x6)

# Testcase 25:  rs1:x12(0x0000000000000002), rs2:x24(0x0000000000000001), result rd:x21(0x0000000000000003)
li x12, MASK_XLEN(0x0000000000000002)
li x24, MASK_XLEN(0x0000000000000001)
XOR x21, x12, x24
sd x21, 200(x6)

# Testcase 26:  rs1:x18(0x0000000000000002), rs2:x11(0x0000000000000002), result rd:x21(0x0000000000000000)
li x18, MASK_XLEN(0x0000000000000002)
li x11, MASK_XLEN(0x0000000000000002)
XOR x21, x18, x11
sd x21, 208(x6)

# Testcase 27:  rs1:x25(0x0000000000000002), rs2:x23(0x00000000000000ff), result rd:x16(0x00000000000000fd)
li x25, MASK_XLEN(0x0000000000000002)
li x23, MASK_XLEN(0x00000000000000ff)
XOR x16, x25, x23
sd x16, 216(x6)

# Testcase 28:  rs1:x30(0x0000000000000002), rs2:x20(0x624b3e976c52dd14), result rd:x17(0x624b3e976c52dd16)
li x30, MASK_XLEN(0x0000000000000002)
li x20, MASK_XLEN(0x624b3e976c52dd14)
XOR x17, x30, x20
sd x17, 224(x6)

# Testcase 29:  rs1:x2(0x0000000000000002), rs2:x8(0x7ffffffffffffffe), result rd:x5(0x7ffffffffffffffc)
li x2, MASK_XLEN(0x0000000000000002)
li x8, MASK_XLEN(0x7ffffffffffffffe)
XOR x5, x2, x8
sd x5, 232(x6)

# Testcase 30:  rs1:x24(0x0000000000000002), rs2:x7(0x7fffffffffffffff), result rd:x31(0x7ffffffffffffffd)
li x24, MASK_XLEN(0x0000000000000002)
li x7, MASK_XLEN(0x7fffffffffffffff)
XOR x31, x24, x7
sd x31, 240(x6)

# Testcase 31:  rs1:x8(0x0000000000000002), rs2:x4(0x8000000000000000), result rd:x5(0x8000000000000002)
li x8, MASK_XLEN(0x0000000000000002)
li x4, MASK_XLEN(0x8000000000000000)
XOR x5, x8, x4
sd x5, 248(x6)

# Testcase 32:  rs1:x4(0x0000000000000002), rs2:x2(0x8000000000000001), result rd:x20(0x8000000000000003)
li x4, MASK_XLEN(0x0000000000000002)
li x2, MASK_XLEN(0x8000000000000001)
XOR x20, x4, x2
sd x20, 256(x6)

# Testcase 33:  rs1:x18(0x0000000000000002), rs2:x3(0xc365ddeb9173ab42), result rd:x19(0xc365ddeb9173ab40)
li x18, MASK_XLEN(0x0000000000000002)
li x3, MASK_XLEN(0xc365ddeb9173ab42)
XOR x19, x18, x3
sd x19, 264(x6)

# Testcase 34:  rs1:x27(0x0000000000000002), rs2:x24(0xfffffffffffffffe), result rd:x26(0xfffffffffffffffc)
li x27, MASK_XLEN(0x0000000000000002)
li x24, MASK_XLEN(0xfffffffffffffffe)
XOR x26, x27, x24
sd x26, 272(x6)

# Testcase 35:  rs1:x20(0x0000000000000002), rs2:x14(0xffffffffffffffff), result rd:x15(0xfffffffffffffffd)
li x20, MASK_XLEN(0x0000000000000002)
li x14, MASK_XLEN(0xffffffffffffffff)
XOR x15, x20, x14
sd x15, 280(x6)

# Testcase 36:  rs1:x21(0x00000000000000ff), rs2:x15(0x0000000000000000), result rd:x13(0x00000000000000ff)
li x21, MASK_XLEN(0x00000000000000ff)
li x15, MASK_XLEN(0x0000000000000000)
XOR x13, x21, x15
sd x13, 288(x6)

# Testcase 37:  rs1:x1(0x00000000000000ff), rs2:x24(0x0000000000000001), result rd:x20(0x00000000000000fe)
li x1, MASK_XLEN(0x00000000000000ff)
li x24, MASK_XLEN(0x0000000000000001)
XOR x20, x1, x24
sd x20, 296(x6)

# Testcase 38:  rs1:x25(0x00000000000000ff), rs2:x21(0x0000000000000002), result rd:x17(0x00000000000000fd)
li x25, MASK_XLEN(0x00000000000000ff)
li x21, MASK_XLEN(0x0000000000000002)
XOR x17, x25, x21
sd x17, 304(x6)

# Testcase 39:  rs1:x21(0x00000000000000ff), rs2:x29(0x00000000000000ff), result rd:x31(0x0000000000000000)
li x21, MASK_XLEN(0x00000000000000ff)
li x29, MASK_XLEN(0x00000000000000ff)
XOR x31, x21, x29
sd x31, 312(x6)

# Testcase 40:  rs1:x11(0x00000000000000ff), rs2:x23(0x624b3e976c52dd14), result rd:x17(0x624b3e976c52ddeb)
li x11, MASK_XLEN(0x00000000000000ff)
li x23, MASK_XLEN(0x624b3e976c52dd14)
XOR x17, x11, x23
sd x17, 320(x6)

# Testcase 41:  rs1:x7(0x00000000000000ff), rs2:x5(0x7ffffffffffffffe), result rd:x20(0x7fffffffffffff01)
li x7, MASK_XLEN(0x00000000000000ff)
li x5, MASK_XLEN(0x7ffffffffffffffe)
XOR x20, x7, x5
sd x20, 328(x6)

# Testcase 42:  rs1:x10(0x00000000000000ff), rs2:x18(0x7fffffffffffffff), result rd:x10(0x7fffffffffffff00)
li x10, MASK_XLEN(0x00000000000000ff)
li x18, MASK_XLEN(0x7fffffffffffffff)
XOR x10, x10, x18
sd x10, 336(x6)

# Testcase 43:  rs1:x22(0x00000000000000ff), rs2:x13(0x8000000000000000), result rd:x20(0x80000000000000ff)
li x22, MASK_XLEN(0x00000000000000ff)
li x13, MASK_XLEN(0x8000000000000000)
XOR x20, x22, x13
sd x20, 344(x6)

# Testcase 44:  rs1:x17(0x00000000000000ff), rs2:x25(0x8000000000000001), result rd:x2(0x80000000000000fe)
li x17, MASK_XLEN(0x00000000000000ff)
li x25, MASK_XLEN(0x8000000000000001)
XOR x2, x17, x25
sd x2, 352(x6)

# Testcase 45:  rs1:x15(0x00000000000000ff), rs2:x19(0xc365ddeb9173ab42), result rd:x19(0xc365ddeb9173abbd)
li x15, MASK_XLEN(0x00000000000000ff)
li x19, MASK_XLEN(0xc365ddeb9173ab42)
XOR x19, x15, x19
sd x19, 360(x6)

# Testcase 46:  rs1:x8(0x00000000000000ff), rs2:x30(0xfffffffffffffffe), result rd:x13(0xffffffffffffff01)
li x8, MASK_XLEN(0x00000000000000ff)
li x30, MASK_XLEN(0xfffffffffffffffe)
XOR x13, x8, x30
sd x13, 368(x6)

# Testcase 47:  rs1:x9(0x00000000000000ff), rs2:x18(0xffffffffffffffff), result rd:x22(0xffffffffffffff00)
li x9, MASK_XLEN(0x00000000000000ff)
li x18, MASK_XLEN(0xffffffffffffffff)
XOR x22, x9, x18
sd x22, 376(x6)

# Testcase 48:  rs1:x10(0x624b3e976c52dd14), rs2:x24(0x0000000000000000), result rd:x4(0x624b3e976c52dd14)
li x10, MASK_XLEN(0x624b3e976c52dd14)
li x24, MASK_XLEN(0x0000000000000000)
XOR x4, x10, x24
sd x4, 384(x6)

# Testcase 49:  rs1:x27(0x624b3e976c52dd14), rs2:x11(0x0000000000000001), result rd:x19(0x624b3e976c52dd15)
li x27, MASK_XLEN(0x624b3e976c52dd14)
li x11, MASK_XLEN(0x0000000000000001)
XOR x19, x27, x11
sd x19, 392(x6)

# Testcase 50:  rs1:x23(0x624b3e976c52dd14), rs2:x9(0x0000000000000002), result rd:x31(0x624b3e976c52dd16)
li x23, MASK_XLEN(0x624b3e976c52dd14)
li x9, MASK_XLEN(0x0000000000000002)
XOR x31, x23, x9
sd x31, 400(x6)

# Testcase 51:  rs1:x23(0x624b3e976c52dd14), rs2:x17(0x00000000000000ff), result rd:x9(0x624b3e976c52ddeb)
li x23, MASK_XLEN(0x624b3e976c52dd14)
li x17, MASK_XLEN(0x00000000000000ff)
XOR x9, x23, x17
sd x9, 408(x6)

# Testcase 52:  rs1:x30(0x624b3e976c52dd14), rs2:x19(0x624b3e976c52dd14), result rd:x27(0x0000000000000000)
li x30, MASK_XLEN(0x624b3e976c52dd14)
li x19, MASK_XLEN(0x624b3e976c52dd14)
XOR x27, x30, x19
sd x27, 416(x6)

# Testcase 53:  rs1:x10(0x624b3e976c52dd14), rs2:x11(0x7ffffffffffffffe), result rd:x23(0x1db4c16893ad22ea)
li x10, MASK_XLEN(0x624b3e976c52dd14)
li x11, MASK_XLEN(0x7ffffffffffffffe)
XOR x23, x10, x11
sd x23, 424(x6)

# Testcase 54:  rs1:x3(0x624b3e976c52dd14), rs2:x23(0x7fffffffffffffff), result rd:x14(0x1db4c16893ad22eb)
li x3, MASK_XLEN(0x624b3e976c52dd14)
li x23, MASK_XLEN(0x7fffffffffffffff)
XOR x14, x3, x23
sd x14, 432(x6)

# Testcase 55:  rs1:x28(0x624b3e976c52dd14), rs2:x11(0x8000000000000000), result rd:x24(0xe24b3e976c52dd14)
li x28, MASK_XLEN(0x624b3e976c52dd14)
li x11, MASK_XLEN(0x8000000000000000)
XOR x24, x28, x11
sd x24, 440(x6)

# Testcase 56:  rs1:x1(0x624b3e976c52dd14), rs2:x26(0x8000000000000001), result rd:x4(0xe24b3e976c52dd15)
li x1, MASK_XLEN(0x624b3e976c52dd14)
li x26, MASK_XLEN(0x8000000000000001)
XOR x4, x1, x26
sd x4, 448(x6)

# Testcase 57:  rs1:x27(0x624b3e976c52dd14), rs2:x31(0xc365ddeb9173ab42), result rd:x23(0xa12ee37cfd217656)
li x27, MASK_XLEN(0x624b3e976c52dd14)
li x31, MASK_XLEN(0xc365ddeb9173ab42)
XOR x23, x27, x31
sd x23, 456(x6)

# Testcase 58:  rs1:x11(0x624b3e976c52dd14), rs2:x27(0xfffffffffffffffe), result rd:x19(0x9db4c16893ad22ea)
li x11, MASK_XLEN(0x624b3e976c52dd14)
li x27, MASK_XLEN(0xfffffffffffffffe)
XOR x19, x11, x27
sd x19, 464(x6)

# Testcase 59:  rs1:x4(0x624b3e976c52dd14), rs2:x18(0xffffffffffffffff), result rd:x7(0x9db4c16893ad22eb)
li x4, MASK_XLEN(0x624b3e976c52dd14)
li x18, MASK_XLEN(0xffffffffffffffff)
XOR x7, x4, x18
sd x7, 472(x6)

# Testcase 60:  rs1:x19(0x7ffffffffffffffe), rs2:x22(0x0000000000000000), result rd:x22(0x7ffffffffffffffe)
li x19, MASK_XLEN(0x7ffffffffffffffe)
li x22, MASK_XLEN(0x0000000000000000)
XOR x22, x19, x22
sd x22, 480(x6)

# Testcase 61:  rs1:x1(0x7ffffffffffffffe), rs2:x30(0x0000000000000001), result rd:x30(0x7fffffffffffffff)
li x1, MASK_XLEN(0x7ffffffffffffffe)
li x30, MASK_XLEN(0x0000000000000001)
XOR x30, x1, x30
sd x30, 488(x6)

# Testcase 62:  rs1:x24(0x7ffffffffffffffe), rs2:x15(0x0000000000000002), result rd:x4(0x7ffffffffffffffc)
li x24, MASK_XLEN(0x7ffffffffffffffe)
li x15, MASK_XLEN(0x0000000000000002)
XOR x4, x24, x15
sd x4, 496(x6)

# Testcase 63:  rs1:x17(0x7ffffffffffffffe), rs2:x22(0x00000000000000ff), result rd:x30(0x7fffffffffffff01)
li x17, MASK_XLEN(0x7ffffffffffffffe)
li x22, MASK_XLEN(0x00000000000000ff)
XOR x30, x17, x22
sd x30, 504(x6)

# Testcase 64:  rs1:x1(0x7ffffffffffffffe), rs2:x16(0x624b3e976c52dd14), result rd:x24(0x1db4c16893ad22ea)
li x1, MASK_XLEN(0x7ffffffffffffffe)
li x16, MASK_XLEN(0x624b3e976c52dd14)
XOR x24, x1, x16
sd x24, 512(x6)

# Testcase 65:  rs1:x8(0x7ffffffffffffffe), rs2:x9(0x7ffffffffffffffe), result rd:x28(0x0000000000000000)
li x8, MASK_XLEN(0x7ffffffffffffffe)
li x9, MASK_XLEN(0x7ffffffffffffffe)
XOR x28, x8, x9
sd x28, 520(x6)

# Testcase 66:  rs1:x30(0x7ffffffffffffffe), rs2:x17(0x7fffffffffffffff), result rd:x10(0x0000000000000001)
li x30, MASK_XLEN(0x7ffffffffffffffe)
li x17, MASK_XLEN(0x7fffffffffffffff)
XOR x10, x30, x17
sd x10, 528(x6)

# Testcase 67:  rs1:x26(0x7ffffffffffffffe), rs2:x30(0x8000000000000000), result rd:x9(0xfffffffffffffffe)
li x26, MASK_XLEN(0x7ffffffffffffffe)
li x30, MASK_XLEN(0x8000000000000000)
XOR x9, x26, x30
sd x9, 536(x6)

# Testcase 68:  rs1:x7(0x7ffffffffffffffe), rs2:x31(0x8000000000000001), result rd:x24(0xffffffffffffffff)
li x7, MASK_XLEN(0x7ffffffffffffffe)
li x31, MASK_XLEN(0x8000000000000001)
XOR x24, x7, x31
sd x24, 544(x6)

# Testcase 69:  rs1:x13(0x7ffffffffffffffe), rs2:x20(0xc365ddeb9173ab42), result rd:x15(0xbc9a22146e8c54bc)
li x13, MASK_XLEN(0x7ffffffffffffffe)
li x20, MASK_XLEN(0xc365ddeb9173ab42)
XOR x15, x13, x20
sd x15, 552(x6)

# Testcase 70:  rs1:x30(0x7ffffffffffffffe), rs2:x16(0xfffffffffffffffe), result rd:x10(0x8000000000000000)
li x30, MASK_XLEN(0x7ffffffffffffffe)
li x16, MASK_XLEN(0xfffffffffffffffe)
XOR x10, x30, x16
sd x10, 560(x6)

# Testcase 71:  rs1:x11(0x7ffffffffffffffe), rs2:x1(0xffffffffffffffff), result rd:x25(0x8000000000000001)
li x11, MASK_XLEN(0x7ffffffffffffffe)
li x1, MASK_XLEN(0xffffffffffffffff)
XOR x25, x11, x1
sd x25, 568(x6)

# Testcase 72:  rs1:x28(0x7fffffffffffffff), rs2:x19(0x0000000000000000), result rd:x25(0x7fffffffffffffff)
li x28, MASK_XLEN(0x7fffffffffffffff)
li x19, MASK_XLEN(0x0000000000000000)
XOR x25, x28, x19
sd x25, 576(x6)

# Testcase 73:  rs1:x20(0x7fffffffffffffff), rs2:x31(0x0000000000000001), result rd:x20(0x7ffffffffffffffe)
li x20, MASK_XLEN(0x7fffffffffffffff)
li x31, MASK_XLEN(0x0000000000000001)
XOR x20, x20, x31
sd x20, 584(x6)

# Testcase 74:  rs1:x25(0x7fffffffffffffff), rs2:x10(0x0000000000000002), result rd:x4(0x7ffffffffffffffd)
li x25, MASK_XLEN(0x7fffffffffffffff)
li x10, MASK_XLEN(0x0000000000000002)
XOR x4, x25, x10
sd x4, 592(x6)

# Testcase 75:  rs1:x11(0x7fffffffffffffff), rs2:x23(0x00000000000000ff), result rd:x3(0x7fffffffffffff00)
li x11, MASK_XLEN(0x7fffffffffffffff)
li x23, MASK_XLEN(0x00000000000000ff)
XOR x3, x11, x23
sd x3, 600(x6)

# Testcase 76:  rs1:x5(0x7fffffffffffffff), rs2:x13(0x624b3e976c52dd14), result rd:x15(0x1db4c16893ad22eb)
li x5, MASK_XLEN(0x7fffffffffffffff)
li x13, MASK_XLEN(0x624b3e976c52dd14)
XOR x15, x5, x13
sd x15, 608(x6)

# Testcase 77:  rs1:x9(0x7fffffffffffffff), rs2:x27(0x7ffffffffffffffe), result rd:x12(0x0000000000000001)
li x9, MASK_XLEN(0x7fffffffffffffff)
li x27, MASK_XLEN(0x7ffffffffffffffe)
XOR x12, x9, x27
sd x12, 616(x6)

# Testcase 78:  rs1:x9(0x7fffffffffffffff), rs2:x20(0x7fffffffffffffff), result rd:x30(0x0000000000000000)
li x9, MASK_XLEN(0x7fffffffffffffff)
li x20, MASK_XLEN(0x7fffffffffffffff)
XOR x30, x9, x20
sd x30, 624(x6)

# Testcase 79:  rs1:x22(0x7fffffffffffffff), rs2:x31(0x8000000000000000), result rd:x24(0xffffffffffffffff)
li x22, MASK_XLEN(0x7fffffffffffffff)
li x31, MASK_XLEN(0x8000000000000000)
XOR x24, x22, x31
sd x24, 632(x6)

# Testcase 80:  rs1:x25(0x7fffffffffffffff), rs2:x8(0x8000000000000001), result rd:x23(0xfffffffffffffffe)
li x25, MASK_XLEN(0x7fffffffffffffff)
li x8, MASK_XLEN(0x8000000000000001)
XOR x23, x25, x8
sd x23, 640(x6)

# Testcase 81:  rs1:x16(0x7fffffffffffffff), rs2:x4(0xc365ddeb9173ab42), result rd:x3(0xbc9a22146e8c54bd)
li x16, MASK_XLEN(0x7fffffffffffffff)
li x4, MASK_XLEN(0xc365ddeb9173ab42)
XOR x3, x16, x4
sd x3, 648(x6)

# Testcase 82:  rs1:x18(0x7fffffffffffffff), rs2:x2(0xfffffffffffffffe), result rd:x25(0x8000000000000001)
li x18, MASK_XLEN(0x7fffffffffffffff)
li x2, MASK_XLEN(0xfffffffffffffffe)
XOR x25, x18, x2
sd x25, 656(x6)

# Testcase 83:  rs1:x9(0x7fffffffffffffff), rs2:x12(0xffffffffffffffff), result rd:x31(0x8000000000000000)
li x9, MASK_XLEN(0x7fffffffffffffff)
li x12, MASK_XLEN(0xffffffffffffffff)
XOR x31, x9, x12
sd x31, 664(x6)

# Testcase 84:  rs1:x28(0x8000000000000000), rs2:x11(0x0000000000000000), result rd:x12(0x8000000000000000)
li x28, MASK_XLEN(0x8000000000000000)
li x11, MASK_XLEN(0x0000000000000000)
XOR x12, x28, x11
sd x12, 672(x6)

# Testcase 85:  rs1:x2(0x8000000000000000), rs2:x13(0x0000000000000001), result rd:x22(0x8000000000000001)
li x2, MASK_XLEN(0x8000000000000000)
li x13, MASK_XLEN(0x0000000000000001)
XOR x22, x2, x13
sd x22, 680(x6)

# Testcase 86:  rs1:x29(0x8000000000000000), rs2:x16(0x0000000000000002), result rd:x2(0x8000000000000002)
li x29, MASK_XLEN(0x8000000000000000)
li x16, MASK_XLEN(0x0000000000000002)
XOR x2, x29, x16
sd x2, 688(x6)

# Testcase 87:  rs1:x18(0x8000000000000000), rs2:x17(0x00000000000000ff), result rd:x10(0x80000000000000ff)
li x18, MASK_XLEN(0x8000000000000000)
li x17, MASK_XLEN(0x00000000000000ff)
XOR x10, x18, x17
sd x10, 696(x6)

# Testcase 88:  rs1:x11(0x8000000000000000), rs2:x30(0x624b3e976c52dd14), result rd:x9(0xe24b3e976c52dd14)
li x11, MASK_XLEN(0x8000000000000000)
li x30, MASK_XLEN(0x624b3e976c52dd14)
XOR x9, x11, x30
sd x9, 704(x6)

# Testcase 89:  rs1:x25(0x8000000000000000), rs2:x20(0x7ffffffffffffffe), result rd:x21(0xfffffffffffffffe)
li x25, MASK_XLEN(0x8000000000000000)
li x20, MASK_XLEN(0x7ffffffffffffffe)
XOR x21, x25, x20
sd x21, 712(x6)

# Testcase 90:  rs1:x11(0x8000000000000000), rs2:x3(0x7fffffffffffffff), result rd:x27(0xffffffffffffffff)
li x11, MASK_XLEN(0x8000000000000000)
li x3, MASK_XLEN(0x7fffffffffffffff)
XOR x27, x11, x3
sd x27, 720(x6)

# Testcase 91:  rs1:x12(0x8000000000000000), rs2:x27(0x8000000000000000), result rd:x1(0x0000000000000000)
li x12, MASK_XLEN(0x8000000000000000)
li x27, MASK_XLEN(0x8000000000000000)
XOR x1, x12, x27
sd x1, 728(x6)

# Testcase 92:  rs1:x26(0x8000000000000000), rs2:x15(0x8000000000000001), result rd:x27(0x0000000000000001)
li x26, MASK_XLEN(0x8000000000000000)
li x15, MASK_XLEN(0x8000000000000001)
XOR x27, x26, x15
sd x27, 736(x6)

# Testcase 93:  rs1:x29(0x8000000000000000), rs2:x20(0xc365ddeb9173ab42), result rd:x10(0x4365ddeb9173ab42)
li x29, MASK_XLEN(0x8000000000000000)
li x20, MASK_XLEN(0xc365ddeb9173ab42)
XOR x10, x29, x20
sd x10, 744(x6)

# Testcase 94:  rs1:x23(0x8000000000000000), rs2:x9(0xfffffffffffffffe), result rd:x16(0x7ffffffffffffffe)
li x23, MASK_XLEN(0x8000000000000000)
li x9, MASK_XLEN(0xfffffffffffffffe)
XOR x16, x23, x9
sd x16, 752(x6)

# Testcase 95:  rs1:x8(0x8000000000000000), rs2:x12(0xffffffffffffffff), result rd:x31(0x7fffffffffffffff)
li x8, MASK_XLEN(0x8000000000000000)
li x12, MASK_XLEN(0xffffffffffffffff)
XOR x31, x8, x12
sd x31, 760(x6)

# Testcase 96:  rs1:x8(0x8000000000000001), rs2:x4(0x0000000000000000), result rd:x28(0x8000000000000001)
li x8, MASK_XLEN(0x8000000000000001)
li x4, MASK_XLEN(0x0000000000000000)
XOR x28, x8, x4
sd x28, 768(x6)

# Testcase 97:  rs1:x21(0x8000000000000001), rs2:x2(0x0000000000000001), result rd:x13(0x8000000000000000)
li x21, MASK_XLEN(0x8000000000000001)
li x2, MASK_XLEN(0x0000000000000001)
XOR x13, x21, x2
sd x13, 776(x6)

# Testcase 98:  rs1:x15(0x8000000000000001), rs2:x26(0x0000000000000002), result rd:x13(0x8000000000000003)
li x15, MASK_XLEN(0x8000000000000001)
li x26, MASK_XLEN(0x0000000000000002)
XOR x13, x15, x26
sd x13, 784(x6)

# Testcase 99:  rs1:x21(0x8000000000000001), rs2:x28(0x00000000000000ff), result rd:x20(0x80000000000000fe)
li x21, MASK_XLEN(0x8000000000000001)
li x28, MASK_XLEN(0x00000000000000ff)
XOR x20, x21, x28
sd x20, 792(x6)

# Testcase 100:  rs1:x27(0x8000000000000001), rs2:x2(0x624b3e976c52dd14), result rd:x11(0xe24b3e976c52dd15)
li x27, MASK_XLEN(0x8000000000000001)
li x2, MASK_XLEN(0x624b3e976c52dd14)
XOR x11, x27, x2
sd x11, 800(x6)

# Testcase 101:  rs1:x1(0x8000000000000001), rs2:x22(0x7ffffffffffffffe), result rd:x1(0xffffffffffffffff)
li x1, MASK_XLEN(0x8000000000000001)
li x22, MASK_XLEN(0x7ffffffffffffffe)
XOR x1, x1, x22
sd x1, 808(x6)

# Testcase 102:  rs1:x15(0x8000000000000001), rs2:x31(0x7fffffffffffffff), result rd:x9(0xfffffffffffffffe)
li x15, MASK_XLEN(0x8000000000000001)
li x31, MASK_XLEN(0x7fffffffffffffff)
XOR x9, x15, x31
sd x9, 816(x6)

# Testcase 103:  rs1:x15(0x8000000000000001), rs2:x4(0x8000000000000000), result rd:x23(0x0000000000000001)
li x15, MASK_XLEN(0x8000000000000001)
li x4, MASK_XLEN(0x8000000000000000)
XOR x23, x15, x4
sd x23, 824(x6)

# Testcase 104:  rs1:x25(0x8000000000000001), rs2:x24(0x8000000000000001), result rd:x13(0x0000000000000000)
li x25, MASK_XLEN(0x8000000000000001)
li x24, MASK_XLEN(0x8000000000000001)
XOR x13, x25, x24
sd x13, 832(x6)

# Testcase 105:  rs1:x18(0x8000000000000001), rs2:x2(0xc365ddeb9173ab42), result rd:x9(0x4365ddeb9173ab43)
li x18, MASK_XLEN(0x8000000000000001)
li x2, MASK_XLEN(0xc365ddeb9173ab42)
XOR x9, x18, x2
sd x9, 840(x6)

# Testcase 106:  rs1:x4(0x8000000000000001), rs2:x5(0xfffffffffffffffe), result rd:x2(0x7fffffffffffffff)
li x4, MASK_XLEN(0x8000000000000001)
li x5, MASK_XLEN(0xfffffffffffffffe)
XOR x2, x4, x5
sd x2, 848(x6)

# Testcase 107:  rs1:x1(0x8000000000000001), rs2:x9(0xffffffffffffffff), result rd:x14(0x7ffffffffffffffe)
li x1, MASK_XLEN(0x8000000000000001)
li x9, MASK_XLEN(0xffffffffffffffff)
XOR x14, x1, x9
sd x14, 856(x6)

# Testcase 108:  rs1:x17(0xc365ddeb9173ab42), rs2:x22(0x0000000000000000), result rd:x25(0xc365ddeb9173ab42)
li x17, MASK_XLEN(0xc365ddeb9173ab42)
li x22, MASK_XLEN(0x0000000000000000)
XOR x25, x17, x22
sd x25, 864(x6)

# Testcase 109:  rs1:x27(0xc365ddeb9173ab42), rs2:x19(0x0000000000000001), result rd:x10(0xc365ddeb9173ab43)
li x27, MASK_XLEN(0xc365ddeb9173ab42)
li x19, MASK_XLEN(0x0000000000000001)
XOR x10, x27, x19
sd x10, 872(x6)

# Testcase 110:  rs1:x26(0xc365ddeb9173ab42), rs2:x3(0x0000000000000002), result rd:x11(0xc365ddeb9173ab40)
li x26, MASK_XLEN(0xc365ddeb9173ab42)
li x3, MASK_XLEN(0x0000000000000002)
XOR x11, x26, x3
sd x11, 880(x6)

# Testcase 111:  rs1:x16(0xc365ddeb9173ab42), rs2:x19(0x00000000000000ff), result rd:x11(0xc365ddeb9173abbd)
li x16, MASK_XLEN(0xc365ddeb9173ab42)
li x19, MASK_XLEN(0x00000000000000ff)
XOR x11, x16, x19
sd x11, 888(x6)

# Testcase 112:  rs1:x9(0xc365ddeb9173ab42), rs2:x11(0x624b3e976c52dd14), result rd:x8(0xa12ee37cfd217656)
li x9, MASK_XLEN(0xc365ddeb9173ab42)
li x11, MASK_XLEN(0x624b3e976c52dd14)
XOR x8, x9, x11
sd x8, 896(x6)

# Testcase 113:  rs1:x2(0xc365ddeb9173ab42), rs2:x24(0x7ffffffffffffffe), result rd:x17(0xbc9a22146e8c54bc)
li x2, MASK_XLEN(0xc365ddeb9173ab42)
li x24, MASK_XLEN(0x7ffffffffffffffe)
XOR x17, x2, x24
sd x17, 904(x6)

# Testcase 114:  rs1:x8(0xc365ddeb9173ab42), rs2:x15(0x7fffffffffffffff), result rd:x17(0xbc9a22146e8c54bd)
li x8, MASK_XLEN(0xc365ddeb9173ab42)
li x15, MASK_XLEN(0x7fffffffffffffff)
XOR x17, x8, x15
sd x17, 912(x6)

# Testcase 115:  rs1:x23(0xc365ddeb9173ab42), rs2:x1(0x8000000000000000), result rd:x22(0x4365ddeb9173ab42)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
li x1, MASK_XLEN(0x8000000000000000)
XOR x22, x23, x1
sd x22, 920(x6)

# Testcase 116:  rs1:x27(0xc365ddeb9173ab42), rs2:x13(0x8000000000000001), result rd:x11(0x4365ddeb9173ab43)
li x27, MASK_XLEN(0xc365ddeb9173ab42)
li x13, MASK_XLEN(0x8000000000000001)
XOR x11, x27, x13
sd x11, 928(x6)

# Testcase 117:  rs1:x2(0xc365ddeb9173ab42), rs2:x17(0xc365ddeb9173ab42), result rd:x29(0x0000000000000000)
li x2, MASK_XLEN(0xc365ddeb9173ab42)
li x17, MASK_XLEN(0xc365ddeb9173ab42)
XOR x29, x2, x17
sd x29, 936(x6)

# Testcase 118:  rs1:x7(0xc365ddeb9173ab42), rs2:x23(0xfffffffffffffffe), result rd:x24(0x3c9a22146e8c54bc)
li x7, MASK_XLEN(0xc365ddeb9173ab42)
li x23, MASK_XLEN(0xfffffffffffffffe)
XOR x24, x7, x23
sd x24, 944(x6)

# Testcase 119:  rs1:x4(0xc365ddeb9173ab42), rs2:x18(0xffffffffffffffff), result rd:x8(0x3c9a22146e8c54bd)
li x4, MASK_XLEN(0xc365ddeb9173ab42)
li x18, MASK_XLEN(0xffffffffffffffff)
XOR x8, x4, x18
sd x8, 952(x6)

# Testcase 120:  rs1:x1(0xfffffffffffffffe), rs2:x27(0x0000000000000000), result rd:x24(0xfffffffffffffffe)
li x1, MASK_XLEN(0xfffffffffffffffe)
li x27, MASK_XLEN(0x0000000000000000)
XOR x24, x1, x27
sd x24, 960(x6)

# Testcase 121:  rs1:x18(0xfffffffffffffffe), rs2:x11(0x0000000000000001), result rd:x5(0xffffffffffffffff)
li x18, MASK_XLEN(0xfffffffffffffffe)
li x11, MASK_XLEN(0x0000000000000001)
XOR x5, x18, x11
sd x5, 968(x6)

# Testcase 122:  rs1:x26(0xfffffffffffffffe), rs2:x23(0x0000000000000002), result rd:x8(0xfffffffffffffffc)
li x26, MASK_XLEN(0xfffffffffffffffe)
li x23, MASK_XLEN(0x0000000000000002)
XOR x8, x26, x23
sd x8, 976(x6)

# Testcase 123:  rs1:x19(0xfffffffffffffffe), rs2:x16(0x00000000000000ff), result rd:x18(0xffffffffffffff01)
li x19, MASK_XLEN(0xfffffffffffffffe)
li x16, MASK_XLEN(0x00000000000000ff)
XOR x18, x19, x16
sd x18, 984(x6)

# Testcase 124:  rs1:x2(0xfffffffffffffffe), rs2:x12(0x624b3e976c52dd14), result rd:x31(0x9db4c16893ad22ea)
li x2, MASK_XLEN(0xfffffffffffffffe)
li x12, MASK_XLEN(0x624b3e976c52dd14)
XOR x31, x2, x12
sd x31, 992(x6)

# Testcase 125:  rs1:x22(0xfffffffffffffffe), rs2:x10(0x7ffffffffffffffe), result rd:x28(0x8000000000000000)
li x22, MASK_XLEN(0xfffffffffffffffe)
li x10, MASK_XLEN(0x7ffffffffffffffe)
XOR x28, x22, x10
sd x28, 1000(x6)

# Testcase 126:  rs1:x28(0xfffffffffffffffe), rs2:x24(0x7fffffffffffffff), result rd:x11(0x8000000000000001)
li x28, MASK_XLEN(0xfffffffffffffffe)
li x24, MASK_XLEN(0x7fffffffffffffff)
XOR x11, x28, x24
sd x11, 1008(x6)

# Testcase 127:  rs1:x21(0xfffffffffffffffe), rs2:x9(0x8000000000000000), result rd:x8(0x7ffffffffffffffe)
li x21, MASK_XLEN(0xfffffffffffffffe)
li x9, MASK_XLEN(0x8000000000000000)
XOR x8, x21, x9
sd x8, 1016(x6)

# Testcase 128:  rs1:x13(0xfffffffffffffffe), rs2:x1(0x8000000000000001), result rd:x2(0x7fffffffffffffff)
li x13, MASK_XLEN(0xfffffffffffffffe)
li x1, MASK_XLEN(0x8000000000000001)
XOR x2, x13, x1
sd x2, 1024(x6)

# Testcase 129:  rs1:x28(0xfffffffffffffffe), rs2:x29(0xc365ddeb9173ab42), result rd:x25(0x3c9a22146e8c54bc)
li x28, MASK_XLEN(0xfffffffffffffffe)
li x29, MASK_XLEN(0xc365ddeb9173ab42)
XOR x25, x28, x29
sd x25, 1032(x6)

# Testcase 130:  rs1:x22(0xfffffffffffffffe), rs2:x31(0xfffffffffffffffe), result rd:x4(0x0000000000000000)
li x22, MASK_XLEN(0xfffffffffffffffe)
li x31, MASK_XLEN(0xfffffffffffffffe)
XOR x4, x22, x31
sd x4, 1040(x6)

# Testcase 131:  rs1:x5(0xfffffffffffffffe), rs2:x20(0xffffffffffffffff), result rd:x11(0x0000000000000001)
li x5, MASK_XLEN(0xfffffffffffffffe)
li x20, MASK_XLEN(0xffffffffffffffff)
XOR x11, x5, x20
sd x11, 1048(x6)

# Testcase 132:  rs1:x1(0xffffffffffffffff), rs2:x2(0x0000000000000000), result rd:x26(0xffffffffffffffff)
li x1, MASK_XLEN(0xffffffffffffffff)
li x2, MASK_XLEN(0x0000000000000000)
XOR x26, x1, x2
sd x26, 1056(x6)

# Testcase 133:  rs1:x31(0xffffffffffffffff), rs2:x19(0x0000000000000001), result rd:x5(0xfffffffffffffffe)
li x31, MASK_XLEN(0xffffffffffffffff)
li x19, MASK_XLEN(0x0000000000000001)
XOR x5, x31, x19
sd x5, 1064(x6)

# Testcase 134:  rs1:x3(0xffffffffffffffff), rs2:x5(0x0000000000000002), result rd:x5(0xfffffffffffffffd)
li x3, MASK_XLEN(0xffffffffffffffff)
li x5, MASK_XLEN(0x0000000000000002)
XOR x5, x3, x5
sd x5, 1072(x6)

# Testcase 135:  rs1:x13(0xffffffffffffffff), rs2:x1(0x00000000000000ff), result rd:x12(0xffffffffffffff00)
li x13, MASK_XLEN(0xffffffffffffffff)
li x1, MASK_XLEN(0x00000000000000ff)
XOR x12, x13, x1
sd x12, 1080(x6)

# Testcase 136:  rs1:x10(0xffffffffffffffff), rs2:x12(0x624b3e976c52dd14), result rd:x25(0x9db4c16893ad22eb)
li x10, MASK_XLEN(0xffffffffffffffff)
li x12, MASK_XLEN(0x624b3e976c52dd14)
XOR x25, x10, x12
sd x25, 1088(x6)

# Testcase 137:  rs1:x19(0xffffffffffffffff), rs2:x25(0x7ffffffffffffffe), result rd:x1(0x8000000000000001)
li x19, MASK_XLEN(0xffffffffffffffff)
li x25, MASK_XLEN(0x7ffffffffffffffe)
XOR x1, x19, x25
sd x1, 1096(x6)

# Testcase 138:  rs1:x8(0xffffffffffffffff), rs2:x19(0x7fffffffffffffff), result rd:x30(0x8000000000000000)
li x8, MASK_XLEN(0xffffffffffffffff)
li x19, MASK_XLEN(0x7fffffffffffffff)
XOR x30, x8, x19
sd x30, 1104(x6)

# Testcase 139:  rs1:x1(0xffffffffffffffff), rs2:x12(0x8000000000000000), result rd:x25(0x7fffffffffffffff)
li x1, MASK_XLEN(0xffffffffffffffff)
li x12, MASK_XLEN(0x8000000000000000)
XOR x25, x1, x12
sd x25, 1112(x6)

# Testcase 140:  rs1:x25(0xffffffffffffffff), rs2:x12(0x8000000000000001), result rd:x11(0x7ffffffffffffffe)
li x25, MASK_XLEN(0xffffffffffffffff)
li x12, MASK_XLEN(0x8000000000000001)
XOR x11, x25, x12
sd x11, 1120(x6)

# Testcase 141:  rs1:x3(0xffffffffffffffff), rs2:x19(0xc365ddeb9173ab42), result rd:x22(0x3c9a22146e8c54bd)
li x3, MASK_XLEN(0xffffffffffffffff)
li x19, MASK_XLEN(0xc365ddeb9173ab42)
XOR x22, x3, x19
sd x22, 1128(x6)

# Testcase 142:  rs1:x22(0xffffffffffffffff), rs2:x12(0xfffffffffffffffe), result rd:x12(0x0000000000000001)
li x22, MASK_XLEN(0xffffffffffffffff)
li x12, MASK_XLEN(0xfffffffffffffffe)
XOR x12, x22, x12
sd x12, 1136(x6)

# Testcase 143:  rs1:x3(0xffffffffffffffff), rs2:x14(0xffffffffffffffff), result rd:x7(0x0000000000000000)
li x3, MASK_XLEN(0xffffffffffffffff)
li x14, MASK_XLEN(0xffffffffffffffff)
XOR x7, x3, x14
sd x7, 1144(x6)

# Testcase 144:  rs1:x9(0xf277b8b75c63aa0f), rs2:x26(0x933d7d62f4b119a0), result rd:x5(0x614ac5d5a8d2b3af)
li x9, MASK_XLEN(0xf277b8b75c63aa0f)
li x26, MASK_XLEN(0x933d7d62f4b119a0)
XOR x5, x9, x26
sd x5, 1152(x6)

# Testcase 145:  rs1:x20(0xd60bd6f7367a120c), rs2:x5(0x2f7cf76a863d18c9), result rd:x31(0xf977219db0470ac5)
li x20, MASK_XLEN(0xd60bd6f7367a120c)
li x5, MASK_XLEN(0x2f7cf76a863d18c9)
XOR x31, x20, x5
sd x31, 1160(x6)

# Testcase 146:  rs1:x4(0x816db439d2a679ac), rs2:x11(0xec85a655c8a8135a), result rd:x19(0x6de8126c1a0e6af6)
li x4, MASK_XLEN(0x816db439d2a679ac)
li x11, MASK_XLEN(0xec85a655c8a8135a)
XOR x19, x4, x11
sd x19, 1168(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-XOR.S
// David_Harris@hmc.edu & Katherine Parry

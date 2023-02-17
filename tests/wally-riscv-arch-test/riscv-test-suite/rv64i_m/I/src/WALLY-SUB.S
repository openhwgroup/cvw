///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SUB.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2023-02-15 19:20:03.529671//
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

# Testcase 0:  rs1:x26(0x0000000000000000), rs2:x13(0x0000000000000000), result rd:x25(0x0000000000000000)
li x26, MASK_XLEN(0x0000000000000000)
li x13, MASK_XLEN(0x0000000000000000)
SUB x25, x26, x13
sd x25, 0(x6)

# Testcase 1:  rs1:x4(0x0000000000000000), rs2:x31(0x0000000000000001), result rd:x9(0xffffffffffffffff)
li x4, MASK_XLEN(0x0000000000000000)
li x31, MASK_XLEN(0x0000000000000001)
SUB x9, x4, x31
sd x9, 8(x6)

# Testcase 2:  rs1:x25(0x0000000000000000), rs2:x30(0x0000000000000002), result rd:x13(0xfffffffffffffffe)
li x25, MASK_XLEN(0x0000000000000000)
li x30, MASK_XLEN(0x0000000000000002)
SUB x13, x25, x30
sd x13, 16(x6)

# Testcase 3:  rs1:x18(0x0000000000000000), rs2:x12(0x00000000000000ff), result rd:x2(0xffffffffffffff01)
li x18, MASK_XLEN(0x0000000000000000)
li x12, MASK_XLEN(0x00000000000000ff)
SUB x2, x18, x12
sd x2, 24(x6)

# Testcase 4:  rs1:x21(0x0000000000000000), rs2:x11(0x624b3e976c52dd14), result rd:x8(0x9db4c16893ad22ec)
li x21, MASK_XLEN(0x0000000000000000)
li x11, MASK_XLEN(0x624b3e976c52dd14)
SUB x8, x21, x11
sd x8, 32(x6)

# Testcase 5:  rs1:x13(0x0000000000000000), rs2:x2(0x7ffffffffffffffe), result rd:x31(0x8000000000000002)
li x13, MASK_XLEN(0x0000000000000000)
li x2, MASK_XLEN(0x7ffffffffffffffe)
SUB x31, x13, x2
sd x31, 40(x6)

# Testcase 6:  rs1:x25(0x0000000000000000), rs2:x14(0x7fffffffffffffff), result rd:x18(0x8000000000000001)
li x25, MASK_XLEN(0x0000000000000000)
li x14, MASK_XLEN(0x7fffffffffffffff)
SUB x18, x25, x14
sd x18, 48(x6)

# Testcase 7:  rs1:x9(0x0000000000000000), rs2:x25(0x8000000000000000), result rd:x26(0x8000000000000000)
li x9, MASK_XLEN(0x0000000000000000)
li x25, MASK_XLEN(0x8000000000000000)
SUB x26, x9, x25
sd x26, 56(x6)

# Testcase 8:  rs1:x2(0x0000000000000000), rs2:x24(0x8000000000000001), result rd:x9(0x7fffffffffffffff)
li x2, MASK_XLEN(0x0000000000000000)
li x24, MASK_XLEN(0x8000000000000001)
SUB x9, x2, x24
sd x9, 64(x6)

# Testcase 9:  rs1:x24(0x0000000000000000), rs2:x3(0xc365ddeb9173ab42), result rd:x11(0x3c9a22146e8c54be)
li x24, MASK_XLEN(0x0000000000000000)
li x3, MASK_XLEN(0xc365ddeb9173ab42)
SUB x11, x24, x3
sd x11, 72(x6)

# Testcase 10:  rs1:x21(0x0000000000000000), rs2:x14(0xfffffffffffffffe), result rd:x1(0x0000000000000002)
li x21, MASK_XLEN(0x0000000000000000)
li x14, MASK_XLEN(0xfffffffffffffffe)
SUB x1, x21, x14
sd x1, 80(x6)

# Testcase 11:  rs1:x25(0x0000000000000000), rs2:x22(0xffffffffffffffff), result rd:x9(0x0000000000000001)
li x25, MASK_XLEN(0x0000000000000000)
li x22, MASK_XLEN(0xffffffffffffffff)
SUB x9, x25, x22
sd x9, 88(x6)

# Testcase 12:  rs1:x8(0x0000000000000001), rs2:x21(0x0000000000000000), result rd:x30(0x0000000000000001)
li x8, MASK_XLEN(0x0000000000000001)
li x21, MASK_XLEN(0x0000000000000000)
SUB x30, x8, x21
sd x30, 96(x6)

# Testcase 13:  rs1:x27(0x0000000000000001), rs2:x28(0x0000000000000001), result rd:x25(0x0000000000000000)
li x27, MASK_XLEN(0x0000000000000001)
li x28, MASK_XLEN(0x0000000000000001)
SUB x25, x27, x28
sd x25, 104(x6)

# Testcase 14:  rs1:x12(0x0000000000000001), rs2:x30(0x0000000000000002), result rd:x31(0xffffffffffffffff)
li x12, MASK_XLEN(0x0000000000000001)
li x30, MASK_XLEN(0x0000000000000002)
SUB x31, x12, x30
sd x31, 112(x6)

# Testcase 15:  rs1:x27(0x0000000000000001), rs2:x17(0x00000000000000ff), result rd:x21(0xffffffffffffff02)
li x27, MASK_XLEN(0x0000000000000001)
li x17, MASK_XLEN(0x00000000000000ff)
SUB x21, x27, x17
sd x21, 120(x6)

# Testcase 16:  rs1:x7(0x0000000000000001), rs2:x28(0x624b3e976c52dd14), result rd:x19(0x9db4c16893ad22ed)
li x7, MASK_XLEN(0x0000000000000001)
li x28, MASK_XLEN(0x624b3e976c52dd14)
SUB x19, x7, x28
sd x19, 128(x6)

# Testcase 17:  rs1:x20(0x0000000000000001), rs2:x19(0x7ffffffffffffffe), result rd:x3(0x8000000000000003)
li x20, MASK_XLEN(0x0000000000000001)
li x19, MASK_XLEN(0x7ffffffffffffffe)
SUB x3, x20, x19
sd x3, 136(x6)

# Testcase 18:  rs1:x14(0x0000000000000001), rs2:x10(0x7fffffffffffffff), result rd:x27(0x8000000000000002)
li x14, MASK_XLEN(0x0000000000000001)
li x10, MASK_XLEN(0x7fffffffffffffff)
SUB x27, x14, x10
sd x27, 144(x6)

# Testcase 19:  rs1:x23(0x0000000000000001), rs2:x22(0x8000000000000000), result rd:x2(0x8000000000000001)
li x23, MASK_XLEN(0x0000000000000001)
li x22, MASK_XLEN(0x8000000000000000)
SUB x2, x23, x22
sd x2, 152(x6)

# Testcase 20:  rs1:x9(0x0000000000000001), rs2:x1(0x8000000000000001), result rd:x1(0x8000000000000000)
li x9, MASK_XLEN(0x0000000000000001)
li x1, MASK_XLEN(0x8000000000000001)
SUB x1, x9, x1
sd x1, 160(x6)

# Testcase 21:  rs1:x13(0x0000000000000001), rs2:x8(0xc365ddeb9173ab42), result rd:x19(0x3c9a22146e8c54bf)
li x13, MASK_XLEN(0x0000000000000001)
li x8, MASK_XLEN(0xc365ddeb9173ab42)
SUB x19, x13, x8
sd x19, 168(x6)

# Testcase 22:  rs1:x18(0x0000000000000001), rs2:x27(0xfffffffffffffffe), result rd:x7(0x0000000000000003)
li x18, MASK_XLEN(0x0000000000000001)
li x27, MASK_XLEN(0xfffffffffffffffe)
SUB x7, x18, x27
sd x7, 176(x6)

# Testcase 23:  rs1:x30(0x0000000000000001), rs2:x31(0xffffffffffffffff), result rd:x2(0x0000000000000002)
li x30, MASK_XLEN(0x0000000000000001)
li x31, MASK_XLEN(0xffffffffffffffff)
SUB x2, x30, x31
sd x2, 184(x6)

# Testcase 24:  rs1:x21(0x0000000000000002), rs2:x18(0x0000000000000000), result rd:x25(0x0000000000000002)
li x21, MASK_XLEN(0x0000000000000002)
li x18, MASK_XLEN(0x0000000000000000)
SUB x25, x21, x18
sd x25, 192(x6)

# Testcase 25:  rs1:x28(0x0000000000000002), rs2:x29(0x0000000000000001), result rd:x7(0x0000000000000001)
li x28, MASK_XLEN(0x0000000000000002)
li x29, MASK_XLEN(0x0000000000000001)
SUB x7, x28, x29
sd x7, 200(x6)

# Testcase 26:  rs1:x15(0x0000000000000002), rs2:x29(0x0000000000000002), result rd:x18(0x0000000000000000)
li x15, MASK_XLEN(0x0000000000000002)
li x29, MASK_XLEN(0x0000000000000002)
SUB x18, x15, x29
sd x18, 208(x6)

# Testcase 27:  rs1:x22(0x0000000000000002), rs2:x15(0x00000000000000ff), result rd:x19(0xffffffffffffff03)
li x22, MASK_XLEN(0x0000000000000002)
li x15, MASK_XLEN(0x00000000000000ff)
SUB x19, x22, x15
sd x19, 216(x6)

# Testcase 28:  rs1:x20(0x0000000000000002), rs2:x31(0x624b3e976c52dd14), result rd:x11(0x9db4c16893ad22ee)
li x20, MASK_XLEN(0x0000000000000002)
li x31, MASK_XLEN(0x624b3e976c52dd14)
SUB x11, x20, x31
sd x11, 224(x6)

# Testcase 29:  rs1:x31(0x0000000000000002), rs2:x27(0x7ffffffffffffffe), result rd:x12(0x8000000000000004)
li x31, MASK_XLEN(0x0000000000000002)
li x27, MASK_XLEN(0x7ffffffffffffffe)
SUB x12, x31, x27
sd x12, 232(x6)

# Testcase 30:  rs1:x12(0x0000000000000002), rs2:x4(0x7fffffffffffffff), result rd:x25(0x8000000000000003)
li x12, MASK_XLEN(0x0000000000000002)
li x4, MASK_XLEN(0x7fffffffffffffff)
SUB x25, x12, x4
sd x25, 240(x6)

# Testcase 31:  rs1:x26(0x0000000000000002), rs2:x1(0x8000000000000000), result rd:x14(0x8000000000000002)
li x26, MASK_XLEN(0x0000000000000002)
li x1, MASK_XLEN(0x8000000000000000)
SUB x14, x26, x1
sd x14, 248(x6)

# Testcase 32:  rs1:x28(0x0000000000000002), rs2:x29(0x8000000000000001), result rd:x8(0x8000000000000001)
li x28, MASK_XLEN(0x0000000000000002)
li x29, MASK_XLEN(0x8000000000000001)
SUB x8, x28, x29
sd x8, 256(x6)

# Testcase 33:  rs1:x24(0x0000000000000002), rs2:x22(0xc365ddeb9173ab42), result rd:x24(0x3c9a22146e8c54c0)
li x24, MASK_XLEN(0x0000000000000002)
li x22, MASK_XLEN(0xc365ddeb9173ab42)
SUB x24, x24, x22
sd x24, 264(x6)

# Testcase 34:  rs1:x28(0x0000000000000002), rs2:x21(0xfffffffffffffffe), result rd:x26(0x0000000000000004)
li x28, MASK_XLEN(0x0000000000000002)
li x21, MASK_XLEN(0xfffffffffffffffe)
SUB x26, x28, x21
sd x26, 272(x6)

# Testcase 35:  rs1:x29(0x0000000000000002), rs2:x24(0xffffffffffffffff), result rd:x24(0x0000000000000003)
li x29, MASK_XLEN(0x0000000000000002)
li x24, MASK_XLEN(0xffffffffffffffff)
SUB x24, x29, x24
sd x24, 280(x6)

# Testcase 36:  rs1:x29(0x00000000000000ff), rs2:x21(0x0000000000000000), result rd:x29(0x00000000000000ff)
li x29, MASK_XLEN(0x00000000000000ff)
li x21, MASK_XLEN(0x0000000000000000)
SUB x29, x29, x21
sd x29, 288(x6)

# Testcase 37:  rs1:x30(0x00000000000000ff), rs2:x13(0x0000000000000001), result rd:x25(0x00000000000000fe)
li x30, MASK_XLEN(0x00000000000000ff)
li x13, MASK_XLEN(0x0000000000000001)
SUB x25, x30, x13
sd x25, 296(x6)

# Testcase 38:  rs1:x20(0x00000000000000ff), rs2:x1(0x0000000000000002), result rd:x22(0x00000000000000fd)
li x20, MASK_XLEN(0x00000000000000ff)
li x1, MASK_XLEN(0x0000000000000002)
SUB x22, x20, x1
sd x22, 304(x6)

# Testcase 39:  rs1:x28(0x00000000000000ff), rs2:x30(0x00000000000000ff), result rd:x7(0x0000000000000000)
li x28, MASK_XLEN(0x00000000000000ff)
li x30, MASK_XLEN(0x00000000000000ff)
SUB x7, x28, x30
sd x7, 312(x6)

# Testcase 40:  rs1:x20(0x00000000000000ff), rs2:x24(0x624b3e976c52dd14), result rd:x16(0x9db4c16893ad23eb)
li x20, MASK_XLEN(0x00000000000000ff)
li x24, MASK_XLEN(0x624b3e976c52dd14)
SUB x16, x20, x24
sd x16, 320(x6)

# Testcase 41:  rs1:x14(0x00000000000000ff), rs2:x25(0x7ffffffffffffffe), result rd:x13(0x8000000000000101)
li x14, MASK_XLEN(0x00000000000000ff)
li x25, MASK_XLEN(0x7ffffffffffffffe)
SUB x13, x14, x25
sd x13, 328(x6)

# Testcase 42:  rs1:x14(0x00000000000000ff), rs2:x13(0x7fffffffffffffff), result rd:x15(0x8000000000000100)
li x14, MASK_XLEN(0x00000000000000ff)
li x13, MASK_XLEN(0x7fffffffffffffff)
SUB x15, x14, x13
sd x15, 336(x6)

# Testcase 43:  rs1:x27(0x00000000000000ff), rs2:x31(0x8000000000000000), result rd:x24(0x80000000000000ff)
li x27, MASK_XLEN(0x00000000000000ff)
li x31, MASK_XLEN(0x8000000000000000)
SUB x24, x27, x31
sd x24, 344(x6)

# Testcase 44:  rs1:x24(0x00000000000000ff), rs2:x21(0x8000000000000001), result rd:x24(0x80000000000000fe)
li x24, MASK_XLEN(0x00000000000000ff)
li x21, MASK_XLEN(0x8000000000000001)
SUB x24, x24, x21
sd x24, 352(x6)

# Testcase 45:  rs1:x7(0x00000000000000ff), rs2:x9(0xc365ddeb9173ab42), result rd:x3(0x3c9a22146e8c55bd)
li x7, MASK_XLEN(0x00000000000000ff)
li x9, MASK_XLEN(0xc365ddeb9173ab42)
SUB x3, x7, x9
sd x3, 360(x6)

# Testcase 46:  rs1:x30(0x00000000000000ff), rs2:x19(0xfffffffffffffffe), result rd:x1(0x0000000000000101)
li x30, MASK_XLEN(0x00000000000000ff)
li x19, MASK_XLEN(0xfffffffffffffffe)
SUB x1, x30, x19
sd x1, 368(x6)

# Testcase 47:  rs1:x10(0x00000000000000ff), rs2:x30(0xffffffffffffffff), result rd:x24(0x0000000000000100)
li x10, MASK_XLEN(0x00000000000000ff)
li x30, MASK_XLEN(0xffffffffffffffff)
SUB x24, x10, x30
sd x24, 376(x6)

# Testcase 48:  rs1:x9(0x624b3e976c52dd14), rs2:x17(0x0000000000000000), result rd:x29(0x624b3e976c52dd14)
li x9, MASK_XLEN(0x624b3e976c52dd14)
li x17, MASK_XLEN(0x0000000000000000)
SUB x29, x9, x17
sd x29, 384(x6)

# Testcase 49:  rs1:x21(0x624b3e976c52dd14), rs2:x14(0x0000000000000001), result rd:x11(0x624b3e976c52dd13)
li x21, MASK_XLEN(0x624b3e976c52dd14)
li x14, MASK_XLEN(0x0000000000000001)
SUB x11, x21, x14
sd x11, 392(x6)

# Testcase 50:  rs1:x18(0x624b3e976c52dd14), rs2:x24(0x0000000000000002), result rd:x14(0x624b3e976c52dd12)
li x18, MASK_XLEN(0x624b3e976c52dd14)
li x24, MASK_XLEN(0x0000000000000002)
SUB x14, x18, x24
sd x14, 400(x6)

# Testcase 51:  rs1:x16(0x624b3e976c52dd14), rs2:x15(0x00000000000000ff), result rd:x4(0x624b3e976c52dc15)
li x16, MASK_XLEN(0x624b3e976c52dd14)
li x15, MASK_XLEN(0x00000000000000ff)
SUB x4, x16, x15
sd x4, 408(x6)

# Testcase 52:  rs1:x9(0x624b3e976c52dd14), rs2:x20(0x624b3e976c52dd14), result rd:x11(0x0000000000000000)
li x9, MASK_XLEN(0x624b3e976c52dd14)
li x20, MASK_XLEN(0x624b3e976c52dd14)
SUB x11, x9, x20
sd x11, 416(x6)

# Testcase 53:  rs1:x10(0x624b3e976c52dd14), rs2:x13(0x7ffffffffffffffe), result rd:x20(0xe24b3e976c52dd16)
li x10, MASK_XLEN(0x624b3e976c52dd14)
li x13, MASK_XLEN(0x7ffffffffffffffe)
SUB x20, x10, x13
sd x20, 424(x6)

# Testcase 54:  rs1:x17(0x624b3e976c52dd14), rs2:x1(0x7fffffffffffffff), result rd:x16(0xe24b3e976c52dd15)
li x17, MASK_XLEN(0x624b3e976c52dd14)
li x1, MASK_XLEN(0x7fffffffffffffff)
SUB x16, x17, x1
sd x16, 432(x6)

# Testcase 55:  rs1:x30(0x624b3e976c52dd14), rs2:x21(0x8000000000000000), result rd:x17(0xe24b3e976c52dd14)
li x30, MASK_XLEN(0x624b3e976c52dd14)
li x21, MASK_XLEN(0x8000000000000000)
SUB x17, x30, x21
sd x17, 440(x6)

# Testcase 56:  rs1:x31(0x624b3e976c52dd14), rs2:x17(0x8000000000000001), result rd:x7(0xe24b3e976c52dd13)
li x31, MASK_XLEN(0x624b3e976c52dd14)
li x17, MASK_XLEN(0x8000000000000001)
SUB x7, x31, x17
sd x7, 448(x6)

# Testcase 57:  rs1:x14(0x624b3e976c52dd14), rs2:x9(0xc365ddeb9173ab42), result rd:x24(0x9ee560abdadf31d2)
li x14, MASK_XLEN(0x624b3e976c52dd14)
li x9, MASK_XLEN(0xc365ddeb9173ab42)
SUB x24, x14, x9
sd x24, 456(x6)

# Testcase 58:  rs1:x21(0x624b3e976c52dd14), rs2:x25(0xfffffffffffffffe), result rd:x14(0x624b3e976c52dd16)
li x21, MASK_XLEN(0x624b3e976c52dd14)
li x25, MASK_XLEN(0xfffffffffffffffe)
SUB x14, x21, x25
sd x14, 464(x6)

# Testcase 59:  rs1:x24(0x624b3e976c52dd14), rs2:x2(0xffffffffffffffff), result rd:x31(0x624b3e976c52dd15)
li x24, MASK_XLEN(0x624b3e976c52dd14)
li x2, MASK_XLEN(0xffffffffffffffff)
SUB x31, x24, x2
sd x31, 472(x6)

# Testcase 60:  rs1:x1(0x7ffffffffffffffe), rs2:x14(0x0000000000000000), result rd:x18(0x7ffffffffffffffe)
li x1, MASK_XLEN(0x7ffffffffffffffe)
li x14, MASK_XLEN(0x0000000000000000)
SUB x18, x1, x14
sd x18, 480(x6)

# Testcase 61:  rs1:x3(0x7ffffffffffffffe), rs2:x31(0x0000000000000001), result rd:x26(0x7ffffffffffffffd)
li x3, MASK_XLEN(0x7ffffffffffffffe)
li x31, MASK_XLEN(0x0000000000000001)
SUB x26, x3, x31
sd x26, 488(x6)

# Testcase 62:  rs1:x9(0x7ffffffffffffffe), rs2:x23(0x0000000000000002), result rd:x26(0x7ffffffffffffffc)
li x9, MASK_XLEN(0x7ffffffffffffffe)
li x23, MASK_XLEN(0x0000000000000002)
SUB x26, x9, x23
sd x26, 496(x6)

# Testcase 63:  rs1:x22(0x7ffffffffffffffe), rs2:x26(0x00000000000000ff), result rd:x13(0x7ffffffffffffeff)
li x22, MASK_XLEN(0x7ffffffffffffffe)
li x26, MASK_XLEN(0x00000000000000ff)
SUB x13, x22, x26
sd x13, 504(x6)

# Testcase 64:  rs1:x31(0x7ffffffffffffffe), rs2:x18(0x624b3e976c52dd14), result rd:x12(0x1db4c16893ad22ea)
li x31, MASK_XLEN(0x7ffffffffffffffe)
li x18, MASK_XLEN(0x624b3e976c52dd14)
SUB x12, x31, x18
sd x12, 512(x6)

# Testcase 65:  rs1:x18(0x7ffffffffffffffe), rs2:x16(0x7ffffffffffffffe), result rd:x17(0x0000000000000000)
li x18, MASK_XLEN(0x7ffffffffffffffe)
li x16, MASK_XLEN(0x7ffffffffffffffe)
SUB x17, x18, x16
sd x17, 520(x6)

# Testcase 66:  rs1:x15(0x7ffffffffffffffe), rs2:x18(0x7fffffffffffffff), result rd:x24(0xffffffffffffffff)
li x15, MASK_XLEN(0x7ffffffffffffffe)
li x18, MASK_XLEN(0x7fffffffffffffff)
SUB x24, x15, x18
sd x24, 528(x6)

# Testcase 67:  rs1:x24(0x7ffffffffffffffe), rs2:x23(0x8000000000000000), result rd:x29(0xfffffffffffffffe)
li x24, MASK_XLEN(0x7ffffffffffffffe)
li x23, MASK_XLEN(0x8000000000000000)
SUB x29, x24, x23
sd x29, 536(x6)

# Testcase 68:  rs1:x26(0x7ffffffffffffffe), rs2:x19(0x8000000000000001), result rd:x25(0xfffffffffffffffd)
li x26, MASK_XLEN(0x7ffffffffffffffe)
li x19, MASK_XLEN(0x8000000000000001)
SUB x25, x26, x19
sd x25, 544(x6)

# Testcase 69:  rs1:x1(0x7ffffffffffffffe), rs2:x20(0xc365ddeb9173ab42), result rd:x12(0xbc9a22146e8c54bc)
li x1, MASK_XLEN(0x7ffffffffffffffe)
li x20, MASK_XLEN(0xc365ddeb9173ab42)
SUB x12, x1, x20
sd x12, 552(x6)

# Testcase 70:  rs1:x7(0x7ffffffffffffffe), rs2:x10(0xfffffffffffffffe), result rd:x14(0x8000000000000000)
li x7, MASK_XLEN(0x7ffffffffffffffe)
li x10, MASK_XLEN(0xfffffffffffffffe)
SUB x14, x7, x10
sd x14, 560(x6)

# Testcase 71:  rs1:x3(0x7ffffffffffffffe), rs2:x8(0xffffffffffffffff), result rd:x4(0x7fffffffffffffff)
li x3, MASK_XLEN(0x7ffffffffffffffe)
li x8, MASK_XLEN(0xffffffffffffffff)
SUB x4, x3, x8
sd x4, 568(x6)

# Testcase 72:  rs1:x15(0x7fffffffffffffff), rs2:x21(0x0000000000000000), result rd:x5(0x7fffffffffffffff)
li x15, MASK_XLEN(0x7fffffffffffffff)
li x21, MASK_XLEN(0x0000000000000000)
SUB x5, x15, x21
sd x5, 576(x6)

# Testcase 73:  rs1:x30(0x7fffffffffffffff), rs2:x16(0x0000000000000001), result rd:x11(0x7ffffffffffffffe)
li x30, MASK_XLEN(0x7fffffffffffffff)
li x16, MASK_XLEN(0x0000000000000001)
SUB x11, x30, x16
sd x11, 584(x6)

# Testcase 74:  rs1:x28(0x7fffffffffffffff), rs2:x15(0x0000000000000002), result rd:x28(0x7ffffffffffffffd)
li x28, MASK_XLEN(0x7fffffffffffffff)
li x15, MASK_XLEN(0x0000000000000002)
SUB x28, x28, x15
sd x28, 592(x6)

# Testcase 75:  rs1:x23(0x7fffffffffffffff), rs2:x5(0x00000000000000ff), result rd:x16(0x7fffffffffffff00)
li x23, MASK_XLEN(0x7fffffffffffffff)
li x5, MASK_XLEN(0x00000000000000ff)
SUB x16, x23, x5
sd x16, 600(x6)

# Testcase 76:  rs1:x26(0x7fffffffffffffff), rs2:x31(0x624b3e976c52dd14), result rd:x28(0x1db4c16893ad22eb)
li x26, MASK_XLEN(0x7fffffffffffffff)
li x31, MASK_XLEN(0x624b3e976c52dd14)
SUB x28, x26, x31
sd x28, 608(x6)

# Testcase 77:  rs1:x9(0x7fffffffffffffff), rs2:x16(0x7ffffffffffffffe), result rd:x11(0x0000000000000001)
li x9, MASK_XLEN(0x7fffffffffffffff)
li x16, MASK_XLEN(0x7ffffffffffffffe)
SUB x11, x9, x16
sd x11, 616(x6)

# Testcase 78:  rs1:x23(0x7fffffffffffffff), rs2:x17(0x7fffffffffffffff), result rd:x24(0x0000000000000000)
li x23, MASK_XLEN(0x7fffffffffffffff)
li x17, MASK_XLEN(0x7fffffffffffffff)
SUB x24, x23, x17
sd x24, 624(x6)

# Testcase 79:  rs1:x26(0x7fffffffffffffff), rs2:x8(0x8000000000000000), result rd:x25(0xffffffffffffffff)
li x26, MASK_XLEN(0x7fffffffffffffff)
li x8, MASK_XLEN(0x8000000000000000)
SUB x25, x26, x8
sd x25, 632(x6)

# Testcase 80:  rs1:x2(0x7fffffffffffffff), rs2:x12(0x8000000000000001), result rd:x30(0xfffffffffffffffe)
li x2, MASK_XLEN(0x7fffffffffffffff)
li x12, MASK_XLEN(0x8000000000000001)
SUB x30, x2, x12
sd x30, 640(x6)

# Testcase 81:  rs1:x17(0x7fffffffffffffff), rs2:x9(0xc365ddeb9173ab42), result rd:x13(0xbc9a22146e8c54bd)
li x17, MASK_XLEN(0x7fffffffffffffff)
li x9, MASK_XLEN(0xc365ddeb9173ab42)
SUB x13, x17, x9
sd x13, 648(x6)

# Testcase 82:  rs1:x27(0x7fffffffffffffff), rs2:x18(0xfffffffffffffffe), result rd:x21(0x8000000000000001)
li x27, MASK_XLEN(0x7fffffffffffffff)
li x18, MASK_XLEN(0xfffffffffffffffe)
SUB x21, x27, x18
sd x21, 656(x6)

# Testcase 83:  rs1:x29(0x7fffffffffffffff), rs2:x20(0xffffffffffffffff), result rd:x4(0x8000000000000000)
li x29, MASK_XLEN(0x7fffffffffffffff)
li x20, MASK_XLEN(0xffffffffffffffff)
SUB x4, x29, x20
sd x4, 664(x6)

# Testcase 84:  rs1:x10(0x8000000000000000), rs2:x29(0x0000000000000000), result rd:x5(0x8000000000000000)
li x10, MASK_XLEN(0x8000000000000000)
li x29, MASK_XLEN(0x0000000000000000)
SUB x5, x10, x29
sd x5, 672(x6)

# Testcase 85:  rs1:x17(0x8000000000000000), rs2:x5(0x0000000000000001), result rd:x5(0x7fffffffffffffff)
li x17, MASK_XLEN(0x8000000000000000)
li x5, MASK_XLEN(0x0000000000000001)
SUB x5, x17, x5
sd x5, 680(x6)

# Testcase 86:  rs1:x3(0x8000000000000000), rs2:x30(0x0000000000000002), result rd:x11(0x7ffffffffffffffe)
li x3, MASK_XLEN(0x8000000000000000)
li x30, MASK_XLEN(0x0000000000000002)
SUB x11, x3, x30
sd x11, 688(x6)

# Testcase 87:  rs1:x7(0x8000000000000000), rs2:x2(0x00000000000000ff), result rd:x1(0x7fffffffffffff01)
li x7, MASK_XLEN(0x8000000000000000)
li x2, MASK_XLEN(0x00000000000000ff)
SUB x1, x7, x2
sd x1, 696(x6)

# Testcase 88:  rs1:x19(0x8000000000000000), rs2:x17(0x624b3e976c52dd14), result rd:x2(0x1db4c16893ad22ec)
li x19, MASK_XLEN(0x8000000000000000)
li x17, MASK_XLEN(0x624b3e976c52dd14)
SUB x2, x19, x17
sd x2, 704(x6)

# Testcase 89:  rs1:x5(0x8000000000000000), rs2:x21(0x7ffffffffffffffe), result rd:x15(0x0000000000000002)
li x5, MASK_XLEN(0x8000000000000000)
li x21, MASK_XLEN(0x7ffffffffffffffe)
SUB x15, x5, x21
sd x15, 712(x6)

# Testcase 90:  rs1:x19(0x8000000000000000), rs2:x5(0x7fffffffffffffff), result rd:x19(0x0000000000000001)
li x19, MASK_XLEN(0x8000000000000000)
li x5, MASK_XLEN(0x7fffffffffffffff)
SUB x19, x19, x5
sd x19, 720(x6)

# Testcase 91:  rs1:x9(0x8000000000000000), rs2:x3(0x8000000000000000), result rd:x10(0x0000000000000000)
li x9, MASK_XLEN(0x8000000000000000)
li x3, MASK_XLEN(0x8000000000000000)
SUB x10, x9, x3
sd x10, 728(x6)

# Testcase 92:  rs1:x12(0x8000000000000000), rs2:x30(0x8000000000000001), result rd:x5(0xffffffffffffffff)
li x12, MASK_XLEN(0x8000000000000000)
li x30, MASK_XLEN(0x8000000000000001)
SUB x5, x12, x30
sd x5, 736(x6)

# Testcase 93:  rs1:x29(0x8000000000000000), rs2:x15(0xc365ddeb9173ab42), result rd:x30(0xbc9a22146e8c54be)
li x29, MASK_XLEN(0x8000000000000000)
li x15, MASK_XLEN(0xc365ddeb9173ab42)
SUB x30, x29, x15
sd x30, 744(x6)

# Testcase 94:  rs1:x12(0x8000000000000000), rs2:x2(0xfffffffffffffffe), result rd:x11(0x8000000000000002)
li x12, MASK_XLEN(0x8000000000000000)
li x2, MASK_XLEN(0xfffffffffffffffe)
SUB x11, x12, x2
sd x11, 752(x6)

# Testcase 95:  rs1:x4(0x8000000000000000), rs2:x29(0xffffffffffffffff), result rd:x4(0x8000000000000001)
li x4, MASK_XLEN(0x8000000000000000)
li x29, MASK_XLEN(0xffffffffffffffff)
SUB x4, x4, x29
sd x4, 760(x6)

# Testcase 96:  rs1:x20(0x8000000000000001), rs2:x22(0x0000000000000000), result rd:x4(0x8000000000000001)
li x20, MASK_XLEN(0x8000000000000001)
li x22, MASK_XLEN(0x0000000000000000)
SUB x4, x20, x22
sd x4, 768(x6)

# Testcase 97:  rs1:x10(0x8000000000000001), rs2:x22(0x0000000000000001), result rd:x10(0x8000000000000000)
li x10, MASK_XLEN(0x8000000000000001)
li x22, MASK_XLEN(0x0000000000000001)
SUB x10, x10, x22
sd x10, 776(x6)

# Testcase 98:  rs1:x25(0x8000000000000001), rs2:x1(0x0000000000000002), result rd:x22(0x7fffffffffffffff)
li x25, MASK_XLEN(0x8000000000000001)
li x1, MASK_XLEN(0x0000000000000002)
SUB x22, x25, x1
sd x22, 784(x6)

# Testcase 99:  rs1:x25(0x8000000000000001), rs2:x16(0x00000000000000ff), result rd:x13(0x7fffffffffffff02)
li x25, MASK_XLEN(0x8000000000000001)
li x16, MASK_XLEN(0x00000000000000ff)
SUB x13, x25, x16
sd x13, 792(x6)

# Testcase 100:  rs1:x13(0x8000000000000001), rs2:x21(0x624b3e976c52dd14), result rd:x7(0x1db4c16893ad22ed)
li x13, MASK_XLEN(0x8000000000000001)
li x21, MASK_XLEN(0x624b3e976c52dd14)
SUB x7, x13, x21
sd x7, 800(x6)

# Testcase 101:  rs1:x3(0x8000000000000001), rs2:x14(0x7ffffffffffffffe), result rd:x28(0x0000000000000003)
li x3, MASK_XLEN(0x8000000000000001)
li x14, MASK_XLEN(0x7ffffffffffffffe)
SUB x28, x3, x14
sd x28, 808(x6)

# Testcase 102:  rs1:x9(0x8000000000000001), rs2:x31(0x7fffffffffffffff), result rd:x16(0x0000000000000002)
li x9, MASK_XLEN(0x8000000000000001)
li x31, MASK_XLEN(0x7fffffffffffffff)
SUB x16, x9, x31
sd x16, 816(x6)

# Testcase 103:  rs1:x14(0x8000000000000001), rs2:x22(0x8000000000000000), result rd:x16(0x0000000000000001)
li x14, MASK_XLEN(0x8000000000000001)
li x22, MASK_XLEN(0x8000000000000000)
SUB x16, x14, x22
sd x16, 824(x6)

# Testcase 104:  rs1:x29(0x8000000000000001), rs2:x13(0x8000000000000001), result rd:x5(0x0000000000000000)
li x29, MASK_XLEN(0x8000000000000001)
li x13, MASK_XLEN(0x8000000000000001)
SUB x5, x29, x13
sd x5, 832(x6)

# Testcase 105:  rs1:x14(0x8000000000000001), rs2:x26(0xc365ddeb9173ab42), result rd:x7(0xbc9a22146e8c54bf)
li x14, MASK_XLEN(0x8000000000000001)
li x26, MASK_XLEN(0xc365ddeb9173ab42)
SUB x7, x14, x26
sd x7, 840(x6)

# Testcase 106:  rs1:x25(0x8000000000000001), rs2:x14(0xfffffffffffffffe), result rd:x21(0x8000000000000003)
li x25, MASK_XLEN(0x8000000000000001)
li x14, MASK_XLEN(0xfffffffffffffffe)
SUB x21, x25, x14
sd x21, 848(x6)

# Testcase 107:  rs1:x25(0x8000000000000001), rs2:x7(0xffffffffffffffff), result rd:x9(0x8000000000000002)
li x25, MASK_XLEN(0x8000000000000001)
li x7, MASK_XLEN(0xffffffffffffffff)
SUB x9, x25, x7
sd x9, 856(x6)

# Testcase 108:  rs1:x3(0xc365ddeb9173ab42), rs2:x26(0x0000000000000000), result rd:x5(0xc365ddeb9173ab42)
li x3, MASK_XLEN(0xc365ddeb9173ab42)
li x26, MASK_XLEN(0x0000000000000000)
SUB x5, x3, x26
sd x5, 864(x6)

# Testcase 109:  rs1:x15(0xc365ddeb9173ab42), rs2:x11(0x0000000000000001), result rd:x12(0xc365ddeb9173ab41)
li x15, MASK_XLEN(0xc365ddeb9173ab42)
li x11, MASK_XLEN(0x0000000000000001)
SUB x12, x15, x11
sd x12, 872(x6)

# Testcase 110:  rs1:x10(0xc365ddeb9173ab42), rs2:x26(0x0000000000000002), result rd:x26(0xc365ddeb9173ab40)
li x10, MASK_XLEN(0xc365ddeb9173ab42)
li x26, MASK_XLEN(0x0000000000000002)
SUB x26, x10, x26
sd x26, 880(x6)

# Testcase 111:  rs1:x15(0xc365ddeb9173ab42), rs2:x11(0x00000000000000ff), result rd:x8(0xc365ddeb9173aa43)
li x15, MASK_XLEN(0xc365ddeb9173ab42)
li x11, MASK_XLEN(0x00000000000000ff)
SUB x8, x15, x11
sd x8, 888(x6)

# Testcase 112:  rs1:x23(0xc365ddeb9173ab42), rs2:x11(0x624b3e976c52dd14), result rd:x26(0x611a9f542520ce2e)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
li x11, MASK_XLEN(0x624b3e976c52dd14)
SUB x26, x23, x11
sd x26, 896(x6)

# Testcase 113:  rs1:x8(0xc365ddeb9173ab42), rs2:x16(0x7ffffffffffffffe), result rd:x5(0x4365ddeb9173ab44)
li x8, MASK_XLEN(0xc365ddeb9173ab42)
li x16, MASK_XLEN(0x7ffffffffffffffe)
SUB x5, x8, x16
sd x5, 904(x6)

# Testcase 114:  rs1:x4(0xc365ddeb9173ab42), rs2:x18(0x7fffffffffffffff), result rd:x19(0x4365ddeb9173ab43)
li x4, MASK_XLEN(0xc365ddeb9173ab42)
li x18, MASK_XLEN(0x7fffffffffffffff)
SUB x19, x4, x18
sd x19, 912(x6)

# Testcase 115:  rs1:x20(0xc365ddeb9173ab42), rs2:x15(0x8000000000000000), result rd:x24(0x4365ddeb9173ab42)
li x20, MASK_XLEN(0xc365ddeb9173ab42)
li x15, MASK_XLEN(0x8000000000000000)
SUB x24, x20, x15
sd x24, 920(x6)

# Testcase 116:  rs1:x9(0xc365ddeb9173ab42), rs2:x30(0x8000000000000001), result rd:x12(0x4365ddeb9173ab41)
li x9, MASK_XLEN(0xc365ddeb9173ab42)
li x30, MASK_XLEN(0x8000000000000001)
SUB x12, x9, x30
sd x12, 928(x6)

# Testcase 117:  rs1:x22(0xc365ddeb9173ab42), rs2:x23(0xc365ddeb9173ab42), result rd:x4(0x0000000000000000)
li x22, MASK_XLEN(0xc365ddeb9173ab42)
li x23, MASK_XLEN(0xc365ddeb9173ab42)
SUB x4, x22, x23
sd x4, 936(x6)

# Testcase 118:  rs1:x4(0xc365ddeb9173ab42), rs2:x13(0xfffffffffffffffe), result rd:x11(0xc365ddeb9173ab44)
li x4, MASK_XLEN(0xc365ddeb9173ab42)
li x13, MASK_XLEN(0xfffffffffffffffe)
SUB x11, x4, x13
sd x11, 944(x6)

# Testcase 119:  rs1:x25(0xc365ddeb9173ab42), rs2:x11(0xffffffffffffffff), result rd:x10(0xc365ddeb9173ab43)
li x25, MASK_XLEN(0xc365ddeb9173ab42)
li x11, MASK_XLEN(0xffffffffffffffff)
SUB x10, x25, x11
sd x10, 952(x6)

# Testcase 120:  rs1:x11(0xfffffffffffffffe), rs2:x28(0x0000000000000000), result rd:x25(0xfffffffffffffffe)
li x11, MASK_XLEN(0xfffffffffffffffe)
li x28, MASK_XLEN(0x0000000000000000)
SUB x25, x11, x28
sd x25, 960(x6)

# Testcase 121:  rs1:x28(0xfffffffffffffffe), rs2:x1(0x0000000000000001), result rd:x7(0xfffffffffffffffd)
li x28, MASK_XLEN(0xfffffffffffffffe)
li x1, MASK_XLEN(0x0000000000000001)
SUB x7, x28, x1
sd x7, 968(x6)

# Testcase 122:  rs1:x22(0xfffffffffffffffe), rs2:x21(0x0000000000000002), result rd:x10(0xfffffffffffffffc)
li x22, MASK_XLEN(0xfffffffffffffffe)
li x21, MASK_XLEN(0x0000000000000002)
SUB x10, x22, x21
sd x10, 976(x6)

# Testcase 123:  rs1:x16(0xfffffffffffffffe), rs2:x31(0x00000000000000ff), result rd:x8(0xfffffffffffffeff)
li x16, MASK_XLEN(0xfffffffffffffffe)
li x31, MASK_XLEN(0x00000000000000ff)
SUB x8, x16, x31
sd x8, 984(x6)

# Testcase 124:  rs1:x3(0xfffffffffffffffe), rs2:x23(0x624b3e976c52dd14), result rd:x17(0x9db4c16893ad22ea)
li x3, MASK_XLEN(0xfffffffffffffffe)
li x23, MASK_XLEN(0x624b3e976c52dd14)
SUB x17, x3, x23
sd x17, 992(x6)

# Testcase 125:  rs1:x29(0xfffffffffffffffe), rs2:x9(0x7ffffffffffffffe), result rd:x29(0x8000000000000000)
li x29, MASK_XLEN(0xfffffffffffffffe)
li x9, MASK_XLEN(0x7ffffffffffffffe)
SUB x29, x29, x9
sd x29, 1000(x6)

# Testcase 126:  rs1:x23(0xfffffffffffffffe), rs2:x4(0x7fffffffffffffff), result rd:x2(0x7fffffffffffffff)
li x23, MASK_XLEN(0xfffffffffffffffe)
li x4, MASK_XLEN(0x7fffffffffffffff)
SUB x2, x23, x4
sd x2, 1008(x6)

# Testcase 127:  rs1:x13(0xfffffffffffffffe), rs2:x24(0x8000000000000000), result rd:x3(0x7ffffffffffffffe)
li x13, MASK_XLEN(0xfffffffffffffffe)
li x24, MASK_XLEN(0x8000000000000000)
SUB x3, x13, x24
sd x3, 1016(x6)

# Testcase 128:  rs1:x13(0xfffffffffffffffe), rs2:x15(0x8000000000000001), result rd:x16(0x7ffffffffffffffd)
li x13, MASK_XLEN(0xfffffffffffffffe)
li x15, MASK_XLEN(0x8000000000000001)
SUB x16, x13, x15
sd x16, 1024(x6)

# Testcase 129:  rs1:x22(0xfffffffffffffffe), rs2:x5(0xc365ddeb9173ab42), result rd:x23(0x3c9a22146e8c54bc)
li x22, MASK_XLEN(0xfffffffffffffffe)
li x5, MASK_XLEN(0xc365ddeb9173ab42)
SUB x23, x22, x5
sd x23, 1032(x6)

# Testcase 130:  rs1:x5(0xfffffffffffffffe), rs2:x2(0xfffffffffffffffe), result rd:x30(0x0000000000000000)
li x5, MASK_XLEN(0xfffffffffffffffe)
li x2, MASK_XLEN(0xfffffffffffffffe)
SUB x30, x5, x2
sd x30, 1040(x6)

# Testcase 131:  rs1:x4(0xfffffffffffffffe), rs2:x5(0xffffffffffffffff), result rd:x21(0xffffffffffffffff)
li x4, MASK_XLEN(0xfffffffffffffffe)
li x5, MASK_XLEN(0xffffffffffffffff)
SUB x21, x4, x5
sd x21, 1048(x6)

# Testcase 132:  rs1:x4(0xffffffffffffffff), rs2:x27(0x0000000000000000), result rd:x13(0xffffffffffffffff)
li x4, MASK_XLEN(0xffffffffffffffff)
li x27, MASK_XLEN(0x0000000000000000)
SUB x13, x4, x27
sd x13, 1056(x6)

# Testcase 133:  rs1:x20(0xffffffffffffffff), rs2:x29(0x0000000000000001), result rd:x4(0xfffffffffffffffe)
li x20, MASK_XLEN(0xffffffffffffffff)
li x29, MASK_XLEN(0x0000000000000001)
SUB x4, x20, x29
sd x4, 1064(x6)

# Testcase 134:  rs1:x10(0xffffffffffffffff), rs2:x3(0x0000000000000002), result rd:x19(0xfffffffffffffffd)
li x10, MASK_XLEN(0xffffffffffffffff)
li x3, MASK_XLEN(0x0000000000000002)
SUB x19, x10, x3
sd x19, 1072(x6)

# Testcase 135:  rs1:x19(0xffffffffffffffff), rs2:x4(0x00000000000000ff), result rd:x7(0xffffffffffffff00)
li x19, MASK_XLEN(0xffffffffffffffff)
li x4, MASK_XLEN(0x00000000000000ff)
SUB x7, x19, x4
sd x7, 1080(x6)

# Testcase 136:  rs1:x28(0xffffffffffffffff), rs2:x24(0x624b3e976c52dd14), result rd:x29(0x9db4c16893ad22eb)
li x28, MASK_XLEN(0xffffffffffffffff)
li x24, MASK_XLEN(0x624b3e976c52dd14)
SUB x29, x28, x24
sd x29, 1088(x6)

# Testcase 137:  rs1:x10(0xffffffffffffffff), rs2:x28(0x7ffffffffffffffe), result rd:x27(0x8000000000000001)
li x10, MASK_XLEN(0xffffffffffffffff)
li x28, MASK_XLEN(0x7ffffffffffffffe)
SUB x27, x10, x28
sd x27, 1096(x6)

# Testcase 138:  rs1:x17(0xffffffffffffffff), rs2:x15(0x7fffffffffffffff), result rd:x23(0x8000000000000000)
li x17, MASK_XLEN(0xffffffffffffffff)
li x15, MASK_XLEN(0x7fffffffffffffff)
SUB x23, x17, x15
sd x23, 1104(x6)

# Testcase 139:  rs1:x9(0xffffffffffffffff), rs2:x25(0x8000000000000000), result rd:x11(0x7fffffffffffffff)
li x9, MASK_XLEN(0xffffffffffffffff)
li x25, MASK_XLEN(0x8000000000000000)
SUB x11, x9, x25
sd x11, 1112(x6)

# Testcase 140:  rs1:x26(0xffffffffffffffff), rs2:x13(0x8000000000000001), result rd:x9(0x7ffffffffffffffe)
li x26, MASK_XLEN(0xffffffffffffffff)
li x13, MASK_XLEN(0x8000000000000001)
SUB x9, x26, x13
sd x9, 1120(x6)

# Testcase 141:  rs1:x24(0xffffffffffffffff), rs2:x3(0xc365ddeb9173ab42), result rd:x7(0x3c9a22146e8c54bd)
li x24, MASK_XLEN(0xffffffffffffffff)
li x3, MASK_XLEN(0xc365ddeb9173ab42)
SUB x7, x24, x3
sd x7, 1128(x6)

# Testcase 142:  rs1:x21(0xffffffffffffffff), rs2:x17(0xfffffffffffffffe), result rd:x27(0x0000000000000001)
li x21, MASK_XLEN(0xffffffffffffffff)
li x17, MASK_XLEN(0xfffffffffffffffe)
SUB x27, x21, x17
sd x27, 1136(x6)

# Testcase 143:  rs1:x29(0xffffffffffffffff), rs2:x25(0xffffffffffffffff), result rd:x12(0x0000000000000000)
li x29, MASK_XLEN(0xffffffffffffffff)
li x25, MASK_XLEN(0xffffffffffffffff)
SUB x12, x29, x25
sd x12, 1144(x6)

# Testcase 144:  rs1:x29(0xbc5115e7acfd0130), rs2:x22(0xde7b2c4274b20954), result rd:x27(0xddd5e9a5384af7dc)
li x29, MASK_XLEN(0xbc5115e7acfd0130)
li x22, MASK_XLEN(0xde7b2c4274b20954)
SUB x27, x29, x22
sd x27, 1152(x6)

# Testcase 145:  rs1:x15(0x54fedaa0173e585c), rs2:x26(0x6ca1250d842f9c65), result rd:x2(0xe85db592930ebbf7)
li x15, MASK_XLEN(0x54fedaa0173e585c)
li x26, MASK_XLEN(0x6ca1250d842f9c65)
SUB x2, x15, x26
sd x2, 1160(x6)

# Testcase 146:  rs1:x8(0x5961640123d8c480), rs2:x30(0x7fdf22292ce42e41), result rd:x8(0xd98241d7f6f4963f)
li x8, MASK_XLEN(0x5961640123d8c480)
li x30, MASK_XLEN(0x7fdf22292ce42e41)
SUB x8, x8, x30
sd x8, 1168(x6)

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
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SUB.S
// David_Harris@hmc.edu & Katherine Parry

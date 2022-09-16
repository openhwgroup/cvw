///////////////////////////////////////////
//
// WALLY-endianness
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-09-05
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

#include "WALLY-TEST-LIB-64.h" 

RVTEST_ISA("RV64I")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True; def NO_SAIL=True;",endianness)

INIT_TESTS

TRAP_HANDLER m

// Test ***Number: testing that accesses to sub-word memory acceses not on a word boundary go 
// correctly with the relevant status bit indicating endianness for each mode. 
// do this by going to each mode with and testing loads with the big endian bit on and off work correctly

// *** It appears  has the MBE, SBE, and UBE bits of mstatus hardwired to zero

li x28, 0xAABBCCDDEEFF1122
li x29, 0x8000F000
sd x28, 0(x29) // Store test value into memory address in little endian mode
// in little endian mode, byte at 0x1(x29) is 0x11
// in big endian mode, 0x1(x29) should be 0xBB

lb x30, 0x1(x29) // Test M Mode Little endianness, should return 0x11
sd x30, 0(t1) // store recorded M mode Little endian value to output
addi t1, t1, 8
addi a6, a6, 8

li x28, 0x2000000000
csrs mstatus, x28 // turn on big endianness for M mode

lb x30, 0x1(x29) // Test M mode big endaianness, should return 0xBB
sd x30, 0(t1) // store recorded M mode big endian value to output
addi t1, t1, 8 
addi a6, a6, 8

li x28, 0x2000000000
csrc mstatus, x28 // Turn off big endianness for M mode before going into the trap handler

GOTO_S_MODE

lb x30, 0x1(x29) // Test S Mode Little endianness, should return 0x11
sd x30, 0(t1) // store recorded M mode Little endian value to output
addi t1, t1, 8
addi a6, a6, 8

GOTO_M_MODE // Go back to M mode to be able to toggle SBE bit of mstatus

li x28, 0x1000000000
csrs mstatus, x28 // turn on big endianness for S mode

GOTO_S_MODE 

lb x30, 0x1(x29) // Test S mode big endaianness, should return 0xBB
sd x30, 0(t1) // store recorded S mode big endian value to output
addi t1, t1, 8 
addi a6, a6, 8

# li x28, 0x1000000000
# csrc sstatus, x28 // Turn off big endianness for S mode before going into the trap handler

GOTO_U_MODE

lb x30, 0x1(x29) // Test U Mode Little endianness, should return 0x11
sd x30, 0(t1) // store recorded M mode Little endian value to output
addi t1, t1, 8
addi a6, a6, 8

GOTO_M_MODE // go to M mode in order to be able to toggle the UBE bit

li x28, 0x40
csrs mstatus, x28 // turn on big endianness for U mode

GOTO_U_MODE

lb x30, 0x1(x29) // Test U mode big endaianness, should return 0xBB
sd x30, 0(t1) // store recorded U mode big endian value to output
addi t1, t1, 8
addi a6, a6, 8

END_TESTS

TEST_STACK_AND_DATA
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

#include "WALLY-TEST-LIB-32.h" 

RVTEST_ISA("RV32I_Zicsr")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",endianness)

INIT_TESTS

TRAP_HANDLER m

// Test 5.3.2.4: testing that accesses to sub-word memory accesses not on a word boundary go 
// correctly with the relevant status bit indicating endianness for each mode. 
// do this by going to each mode with and testing loads with the big endian bit on and off work correctly

// *** It appears Sail has the MBE, SBE, and UBE bits of mstatus hardwired to zero

// M Mode little endianness tests:

li x28, 0xAABBCCDD
li x29, 0x8000F000
sw x28, 0(x29) // value stored in memory as 0xAABBCCDD

lw x30, 0(x29) // test load word, should read out 0xAABBCCDD
sw x30, 0(t1) // test store word, should save 0xAABBCCDD
addi t1, t1, 4
addi a6, a6, 4

lh x30, 0(x29) // test load half, should read out 0xCCDD
sh x30, 0(t1) // test store half, should save 0xCCDD
addi t1, t1, 4
addi a6, a6, 4

lb x30, 0(x29) // test load byte, should read out 0xDD
sb x30, 0(t1) // test store byte, should save 0xDD
addi t1, t1, 4
addi a6, a6, 4

li x28, 0x20
csrs 0x310, x28 // turn on big endianness for M mode // using '0x310' instead of mstatush because GCC doesn't recognize just mstatush

// M mode Big endianness tests
// In big endian modes, all values are sign extended to the right, rather than left

li x28, 0xAABBCCDD
li x29, 0x8000F000
sw x28, 0(x29) // value stored in memory as 0xDDCCBBAA

lw x30, 0(x29) // test load word, should read out 0xAABBCCDD
sw x30, 0(t1) // test store word, should save 0xDDCCBBAA
addi t1, t1, 4
addi a6, a6, 4

lh x30, 0(x29) // test load half, should read out 0xAABB
sh x30, 0(t1) // test store half, should save 0xBBAA
addi t1, t1, 4
addi a6, a6, 4

lb x30, 0(x29) // test load byte, should read out 0xAA
sb x30, 0(t1) // test store byte, should save 0xAA
addi t1, t1, 4
addi a6, a6, 4

li x28, 0x20
csrc 0x310, x28 // Turn off big endianness for M mode before going into the trap handler // using '0x310' instead of mstatush because GCC doesn't recognize just mstatush

GOTO_S_MODE

// S mode Little endian tests

li x28, 0xAABBCCDD
li x29, 0x8000F000
sw x28, 0(x29) // value stored in memory as 0xAABBCCDD

lw x30, 0(x29) // test load word, should read out 0xAABBCCDD
sw x30, 0(t1) // test store word, should save 0xAABBCCDD
addi t1, t1, 4
addi a6, a6, 4

lh x30, 0(x29) // test load half, should read out 0xCCDD
sh x30, 0(t1) // test store half, should save 0xCCDD
addi t1, t1, 4
addi a6, a6, 4

lb x30, 0(x29) // test load byte, should read out 0xDD
sb x30, 0(t1) // test store byte, should save 0xDD
addi t1, t1, 4
addi a6, a6, 4

GOTO_M_MODE // Go back to M mode to be able to toggle SBE bit of mstatus

li x28, 0x10
csrs 0x310, x28 // turn on big endianness for S mode // using '0x310' instead of mstatush because GCC doesn't recognize just mstatush

GOTO_S_MODE 

// S mode Big endian tests

li x28, 0xAABBCCDD
li x29, 0x8000F000
sw x28, 0(x29) // value stored in memory as 0xDDCCBBAA

lw x30, 0(x29) // test load word, should read out 0xAABBCCDD
sw x30, 0(t1) // test store word, should save 0xDDCCBBAA
addi t1, t1, 4
addi a6, a6, 4

lh x30, 0(x29) // test load half, should read out 0xAABB
sh x30, 0(t1) // test store half, should save 0xBBAA
addi t1, t1, 4
addi a6, a6, 4

lb x30, 0(x29) // test load byte, should read out 0xAA
sb x30, 0(t1) // test store byte, should save 0xAA
addi t1, t1, 4
addi a6, a6, 4

GOTO_U_MODE

// U mode Little endian tests

li x28, 0xAABBCCDD
li x29, 0x8000F000
sw x28, 0(x29) // value stored in memory as 0xAABBCCDD

lw x30, 0(x29) // test load word, should read out 0xAABBCCDD
sw x30, 0(t1) // test store word, should save 0xAABBCCDD
addi t1, t1, 4
addi a6, a6, 4

lh x30, 0(x29) // test load half, should read out 0xCCDD
sh x30, 0(t1) // test store half, should save 0xCCDD
addi t1, t1, 4
addi a6, a6, 4

lb x30, 0(x29) // test load byte, should read out 0xDD
sb x30, 0(t1) // test store byte, should save 0xDD
addi t1, t1, 4
addi a6, a6, 4

GOTO_M_MODE // go to M mode in order to be able to toggle the UBE bit

li x28, 0x40
csrs mstatus, x28 // turn on big endianness for U mode

GOTO_U_MODE

// U mode Big endian tests

li x28, 0xAABBCCDD
li x29, 0x8000F000
sw x28, 0(x29) // value stored in memory as 0xDDCCBBAA

lw x30, 0(x29) // test load word, should read out 0xAABBCCDD
sw x30, 0(t1) // test store word, should save 0xDDCCBBAA
addi t1, t1, 4
addi a6, a6, 4

lh x30, 0(x29) // test load half, should read out 0xAABB
sh x30, 0(t1) // test store half, should save 0xBBAA
addi t1, t1, 4
addi a6, a6, 4

lb x30, 0(x29) // test load byte, should read out 0xAA
sb x30, 0(t1) // test store byte, should save 0xAA
addi t1, t1, 4
addi a6, a6, 4

//store_location:
//.fill

END_TESTS

TEST_STACK_AND_DATA
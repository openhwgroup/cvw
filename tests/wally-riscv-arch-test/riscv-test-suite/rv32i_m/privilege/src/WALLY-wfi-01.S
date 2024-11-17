///////////////////////////////////////////
//
// WALLY-wait-for-interrupt
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-04-24
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
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",wfi)

INIT_TESTS

TRAP_HANDLER m, EXT_SIGNATURE=1 // turn on recording mtval and status bits on traps

li x28, 0x8
csrs mstatus, x28 // set mstatus.MIE bit to 1
WRITE_READ_CSR mie, 0xFFF // Enable interrupts from all sources

// Code copied from test library to cause m time interrupt, with time loop replaced with wfi.

/* Note: the following line might cause problems in the future. If more than 0x100 cycles are needed before the wfi 
 instruction begins, then the program might fall into a loop and run forever*/
    li x28, 0x100          // Desired offset from the present time
    mv a3, x28            // copy value in to know to stop waiting for interrupt after this many cycles
    la x29, 0x02004000    // MTIMECMP register in CLINT
    la x30, 0x0200BFF8    // MTIME register in CLINT
    lw x7, 0(x30)         // low word of MTIME
    lw x31, 4(x30)         // high word of MTIME
    add x28, x7, x28       // add desired offset to the current time
    bgtu x28, x7, nowrap  // check new time exceeds current time (no wraparound)
    addi x31, x31, 1       // if wrap, increment most significant word

nowrap:
    sw x31,4(x29)          // store into most significant word of MTIMECMP
    sw x28, 0(x29)         // store into least significant word of MTIMECMP

auipc ra, 0x0
addi ra, ra, 0xC // load address after wfi into ra so we return to the right place after handling the time interrupt

wfi // test wfi until trap goes off

li x28, 0x600d111 // magic number "good 111" to write to output after interrupt goes off.
// this tests whether wfi is a nop or not since we should get the output for the interrupt before this one
sw x28, 0(x6)
addi x6, x6, 4
addi x16, x16, 4

END_TESTS

TEST_STACK_AND_DATA



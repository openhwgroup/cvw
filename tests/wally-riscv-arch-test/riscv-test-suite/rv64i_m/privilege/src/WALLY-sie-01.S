///////////////////////////////////////////
//
// WALLY-SIE
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-04-29
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
RVTEST_ISA("RV64I_Zicsr")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;def NO_SAIL=True;",sie)

INIT_TESTS

CAUSE_TRAP_TRIGGERS // initialize code that will cause traps for consistent mtval addresses

TRAP_HANDLER m, EXT_SIGNATURE=1 // turn on recording mtval and status bits on traps

li x28, 0x2
csrs sstatus, x28 // set sstatus.SIE bit to 1
li x28, 0x8
csrc mstatus, x28 // clear mstatus.MIE bit
WRITE_READ_CSR sie, 0x0 // force zeroing out mie CSR.


// test 5.3.1.6 Interrupt enabling and priority tests 
// testing with SIE bits set already tested in WALLY-trap-s
// note that none of these interrupts should be caught or handled.

jal cause_s_time_interrupt // write this from M mode to attempt to make s time interrupt pending
GOTO_S_MODE // this would cause S mode interrupt to fire, but it shouldn't since SIE is zeroed out.
jal cause_s_soft_interrupt
li a3, 0x40 // these interrupts involve a time loop waiting for the interrupt to go off.
// since interrupts are not always enabled, we need to make it stop after a certain number of loops, which is the number in a3
jal cause_s_ext_interrupt_GPIO

END_TESTS

TEST_STACK_AND_DATA

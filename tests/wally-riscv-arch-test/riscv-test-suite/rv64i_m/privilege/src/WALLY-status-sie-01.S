///////////////////////////////////////////
//
// WALLY-privilege-interrupt-enable-stack
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-04-10
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
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;def NO_SAIL=True;",status-sie)

INIT_TESTS

CAUSE_TRAP_TRIGGERS // initialize code that will cause traps for consistent mtval addresses

TRAP_HANDLER m, EXT_SIGNATURE=1 // necessary so we can go to S mode
TRAP_HANDLER s, EXT_SIGNATURE=1 // necessary to handle s mode interrupts. 

li x28, 0x2
csrs sstatus, x28 // set sstatus.SIE bit to 1
li x28, 0x8
csrc mstatus, x28 // clear mstatus.MIE bit
WRITE_READ_CSR mie, 0xFFF // enable all interrupts, including supervisor ones
WRITE_READ_CSR mideleg 0xFFFF // delegate all interrupts to S mode.

// test 5.3.1.6 Interrupt enabling and priority tests 

GOTO_S_MODE

jal cause_s_soft_interrupt // only cause one interrupt because we just want to test the status stack

li x28, 0x2
csrc sstatus, x28 // set sstatus.SIE bit to 0. interrupts from S mode should not happen

// attempt to cause interrupt, it should not go through
jal cause_s_soft_interrupt

END_TESTS

TEST_STACK_AND_DATA

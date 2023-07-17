///////////////////////////////////////////
//
// WALLY-trap
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-02-20
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
RVTEST_ISA("RV64I_Sstc_Zicsr")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;def NO_SAIL=True;",trap)

INIT_TESTS

CAUSE_TRAP_TRIGGERS // initialize code that will cause traps for consistent mtval addresses

TRAP_HANDLER m, EXT_SIGNATURE=1 // turn on recording mtval and status bits on traps

li x28, 0x8
csrs mstatus, x28 // set mstatus.MIE bit to 1
WRITE_READ_CSR stimecmp, 0xFFFFFFFF // set timer to high value so it doesn't go off immediately
WRITE_READ_CSR menvcfg, 0x8000000000000000 // Enable menvcfg.STCE
WRITE_READ_CSR mie, 0xFFF // Enable interrupts from all sources 

// test 5.3.1.4 Basic trap tests 

// instr address misaligned instructions are excluded from this test since they are impossible to cause when compressed instructions are enabled.
jal cause_instr_access
jal cause_illegal_instr
jal cause_breakpnt
jal cause_load_addr_misaligned
jal cause_load_acc
jal cause_store_addr_misaligned
jal cause_store_acc
GOTO_U_MODE // Causes M mode ecall
GOTO_S_MODE // Causes U mode ecall
GOTO_M_MODE // Causes S mode ecall


jal cause_s_soft_from_m_interrupt
jal cause_m_soft_interrupt
jal cause_s_time_interrupt
jal cause_m_time_interrupt
jal cause_s_ext_interrupt_GPIO
jal cause_m_ext_interrupt


// try the traps again with mideleg = medeleg = all 1's to ensure traps still go to M mode from M mode

WRITE_READ_CSR medeleg, 0xFFFFFFFFFFFFFFFF
WRITE_READ_CSR mideleg, 0xFFFFFFFFFFFFFFFF

jal cause_instr_access
jal cause_illegal_instr
jal cause_breakpnt
jal cause_load_addr_misaligned
jal cause_load_acc
jal cause_store_addr_misaligned
jal cause_store_acc
jal cause_ecall // M mode ecall

jal cause_s_soft_interrupt // S Mode Interrupts Ignored in M mode. sip writeable when mideleg = 1
jal cause_m_soft_interrupt
jal cause_s_time_interrupt 
jal cause_m_time_interrupt
li a3, 0x40 // these interrupts involve a time loop waiting for the interrupt to go off.
// since interrupts are not always enabled, we need to make it stop after a certain number of loops, which is the number in a3
jal cause_s_ext_interrupt_GPIO
jal cause_m_ext_interrupt


END_TESTS

TEST_STACK_AND_DATA


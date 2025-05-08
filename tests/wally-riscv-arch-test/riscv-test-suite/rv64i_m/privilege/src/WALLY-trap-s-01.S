///////////////////////////////////////////
//
// WALLY-trap-s
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-03-11
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
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;def NO_SAIL=True;",trap-s)

INIT_TESTS

CAUSE_TRAP_TRIGGERS // initialize code that will cause traps for consistent mtval addresses

// test 5.3.1.4 Basic trap tests 

TRAP_HANDLER m, EXT_SIGNATURE=1 // necessary to handle switching privilege modes
TRAP_HANDLER s, EXT_SIGNATURE=1 // have S mode trap handler as well

// Like WALLY-trap, cause all the same traps from S mode and make sure they go to machine mode with zeroed mideleg, medeleg

li x28, 0x2
csrs sstatus, x28 // set sstatus.SIE bit to 1
li x28, 0x8
csrc mstatus, x28 // clear mstatus.MIE bit
WRITE_READ_CSR mie, 0xFFFF // sie is a subset of mie, so writing this also enables sie.

GOTO_S_MODE

// instr address misaligned instructions are excluded from this test since they are impossible to cause when compressed instructions are enabled.
jal cause_instr_access
jal cause_illegal_instr
jal cause_breakpnt
jal cause_load_addr_misaligned
jal cause_load_acc
jal cause_store_addr_misaligned
jal cause_store_acc
GOTO_U_MODE // Causes S mode ecall
GOTO_S_MODE // Causes U mode ecall


// some interrupts excluded because writing MIP is illegal from S mode and writing SIP is only possible when delegated, which is tested below (priv spec 3.1.9)
//jal cause_s_soft_interrupt 
jal cause_m_soft_interrupt
jal cause_m_time_interrupt
li a3, 0x40 // this interrupt involves a time loop waiting for the interrupt to go off.
// since interrupts are not always enabled, we need to make it stop after a certain number of loops, which is the number in a3
jal cause_s_ext_interrupt_GPIO
li a3, 0x40
jal cause_m_ext_interrupt

// Now delegate all traps to S mode and attempt them again, ensuring they now go to the S mode trap handler
// We can tell which one because the different trap handler modes write different bits of the status register 
// to the output when EXT_SIGNATURE is on.

GOTO_M_MODE // so we can write the delegate registers

WRITE_READ_CSR medeleg, 0xFFFFFFFFFFFFFFFF
WRITE_READ_CSR mideleg, 0xFFFFFFFFFFFFFFFF

GOTO_S_MODE // Since we're running in M mode, this ecall will NOT be delegated to S mode

jal cause_instr_access
jal cause_illegal_instr
jal cause_breakpnt
jal cause_load_addr_misaligned
jal cause_load_acc
jal cause_store_addr_misaligned
jal cause_store_acc
GOTO_U_MODE // Causes S mode ecall
GOTO_S_MODE // Causes U mode ecall

// M mode interrupts cannot be delegated in this implementation, so they are excluded from tests
jal cause_s_soft_interrupt
li a3, 0x40
jal cause_s_ext_interrupt_GPIO

END_TESTS

TEST_STACK_AND_DATA


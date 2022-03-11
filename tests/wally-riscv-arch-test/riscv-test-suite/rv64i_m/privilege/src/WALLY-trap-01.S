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

INIT_TESTS

TRAP_HANDLER m, DEBUG=1 // turn on recording mtval and status bits on traps

li x28, 0x8
csrs mstatus, x28 // set mstatus.MIE bit to 1
// WRITE_READ_CSR mie, 0xFFFF *** commented out until I can get the trap handler (and spike for time interrupts) to work correctly with interrupts

// test 5.3.1.4 Basic trap tests 

// CAUSE_INSTR_ADDR_MISALIGNED //skipped becuase this exception may be impossible when compressed instructions are enabled)
CAUSE_INSTR_ACCESS
CAUSE_ILLEGAL_INSTR
CAUSE_BREAKPNT
CAUSE_LOAD_ADDR_MISALIGNED
CAUSE_LOAD_ACC
CAUSE_STORE_ADDR_MISALIGNED
CAUSE_STORE_ACC
GOTO_U_MODE // Causes M mode ecall
GOTO_S_MODE // Causes U mode ecall
GOTO_M_MODE // Causes S mode ecall

// CAUSE_TIME_INTERRUPT *** intentionally causing this trap seems difficult in spike. although it is possible for it to accidentally happen. 
// CAUSE_SOFT_INTERRUPT *** exiting out of the trap handler after these is current;y broken
// CAUSE_EXT_INTERRUPT

// try the traps again with mideleg = medeleg = all 1's to ensure traps still go to M mode from M mode

WRITE_READ_CSR medeleg, 0xFFFFFFFFFFFFFFFF
WRITE_READ_CSR mideleg, 0xFFFFFFFFFFFFFFFF

// CAUSE_INSTR_ADDR_MISALIGNED //skipped becuase this exception may be impossible when compressed instructions are enabled)
CAUSE_INSTR_ACCESS
CAUSE_ILLEGAL_INSTR
CAUSE_BREAKPNT
CAUSE_LOAD_ADDR_MISALIGNED
CAUSE_LOAD_ACC
CAUSE_STORE_ADDR_MISALIGNED
CAUSE_STORE_ACC
CAUSE_ECALL // M mode ecall
// GOTO_U_MODE // leave these untested since we only need to ensure that from M mode are not delegated
// GOTO_S_MODE 

// CAUSE_TIME_INTERRUPT *** intentionally causing this trap seems difficult in spike. although it is possible for it to accidentally happen. 
// CAUSE_SOFT_INTERRUPT *** exiting out of the trap handler after these is current;y broken
// CAUSE_EXT_INTERRUPT

END_TESTS

TEST_STACK_AND_DATA


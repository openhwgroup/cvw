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

INIT_TESTS

// test 5.3.1.4 Basic trap tests 

TRAP_HANDLER m, DEBUG=1 // turn on recording mtval and status bits on traps
TRAP_HANDLER s, DEBUG=1 // have S mode trap handler as well

// Like WALLY-trap, cause all the same traps from S mode and make sure they go to machine mode with zeroed mideleg, medeleg

GOTO_S_MODE

li x28, 0x8
csrs sstatus, x28 // set sstatus.MIE bit to 1 // *** might be unneccessary for s mode
// WRITE_READ_CSR mie, 0xFFFF *** commented out until I can get the trap handler (and spike for time interrupts) to work correctly with interrupts


// CAUSE_INSTR_ADDR_MISALIGNED //skipped becuase this exception may be impossible when compressed instructions are enabled)
CAUSE_INSTR_ACCESS
CAUSE_ILLEGAL_INSTR
CAUSE_BREAKPNT
CAUSE_LOAD_ADDR_MISALIGNED
CAUSE_LOAD_ACC
CAUSE_STORE_ADDR_MISALIGNED
CAUSE_STORE_ACC
CAUSE_ECALL

// CAUSE_TIME_INTERRUPT *** intentionally causing this trap seems difficult in spike. although it is possible for it to accidentally happen. 
// CAUSE_SOFT_INTERRUPT *** exiting out of the trap handler after these is current;y broken
// CAUSE_EXT_INTERRUPT


// Now delegate all traps to S mode and attempt them again, ensuring they now go to the S mode trap handler
// We can tell which one becuase the different trap handler modes write different bits of the status register 
// to the output when debug is on.

GOTO_M_MODE // so we can write the delegate registers

WRITE_READ_CSR medeleg, 0xFFFFFFFFFFFFFFFF
WRITE_READ_CSR mideleg, 0xFFFFFFFFFFFFFFFF

GOTO_S_MODE

// CAUSE_INSTR_ADDR_MISALIGNED //skipped becuase this exception may be impossible when compressed instructions are enabled)
CAUSE_INSTR_ACCESS
CAUSE_ILLEGAL_INSTR
CAUSE_BREAKPNT
CAUSE_LOAD_ADDR_MISALIGNED
CAUSE_LOAD_ACC
CAUSE_STORE_ADDR_MISALIGNED
CAUSE_STORE_ACC
CAUSE_ECALL

// CAUSE_TIME_INTERRUPT *** intentionally causing this trap seems difficult in spike. although it is possible for it to accidentally happen. 
// CAUSE_SOFT_INTERRUPT *** exiting out of the trap handler after these is current;y broken
// CAUSE_EXT_INTERRUPT

END_TESTS

TEST_STACK_AND_DATA


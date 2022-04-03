///////////////////////////////////////////
//
// WALLY-unvectored-interrupt
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

// test 5.3.1.5 Unvectored interrupt tests 

TRAP_HANDLER s, VECTORED=0, DEBUG=1 // turn off vectored interrupts, while turning on recording of mstatus bits.

// li x28, 0x8
// csrs sstatus, x28 // set sstatus.MIE bit to 1 // *** might be unneccessary for s mode
// WRITE_READ_CSR mie, 0xFFFF *** commented out until I can get the trap handler (and spike for time interrupts) to work correctly with interrupts

WRITE_READ_CSR mideleg, 0xFFFFFFFFFFFFFFFF

GOTO_S_MODE

// cause traps, ensuring that we DONT go through the vectored part of the trap handler
// *** this assumes that interrupt code 0 remains reserved

// CAUSE_TIME_INTERRUPT *** intentionally causing this trap seems difficult in spike. although it is possible for it to accidentally happen. 
// CAUSE_SOFT_INTERRUPT *** exiting out of the trap handler after these is current;y broken
// CAUSE_EXT_INTERRUPT

GOTO_U_MODE 

// CAUSE_TIME_INTERRUPT *** intentionally causing this trap seems difficult in spike. although it is possible for it to accidentally happen. 
// CAUSE_SOFT_INTERRUPT *** exiting out of the trap handler after these is current;y broken
// CAUSE_EXT_INTERRUPT

END_TESTS

TEST_STACK_AND_DATA

///////////////////////////////////////////
//
// WALLY-MMU
//
// Author: Kip Macsai-Goren <kmacsaigoren@hmc.edu>
//
// Created 2022-11-18
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
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True; def TEST_CASE_1=True;",satp-invalid)

INIT_TESTS

TRAP_HANDLER m

la t4, pre_trap
csrw mtvec, t4 // set the new trap handler to do the pre behavior first.

GOTO_S_MODE // go to S mode to attempt to turn on virtual memory

la ra, post_satp // load the address after the failing address into ra so it doesn't get confused
GOTO_SV39 0x0, 0x0 // attempt to turn on virtual memory with satp pointing to an invalid address. Should cause invalid instruction exception

post_satp:
    j test_end

pre_trap:
    csrwi satp, 0x0 // zero out the satp, turning off virtual memory with incorrect address, then jumping to the normal trap handler.
    j trap_handler_m

test_end:

END_TESTS

TEST_STACK_AND_DATA

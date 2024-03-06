///////////////////////////////////////////
//
// WALLY-status-tvm
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-12-22
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
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;", status-tvm)

INIT_TESTS

TRAP_HANDLER m//, EXT_SIGNATURE=1 // turn on recording mtval and status bits on traps

li x28, 0x100000
csrs mstatus, x28 // set mstatus.TVM bit to 1

GOTO_S_MODE // go to S mode so the TVM can be triggered

csrw satp, x28 // attempt to write satp should cause illegal instruction with TVM
csrr x28, satp // attempt to read satp should cause illegal instruction with TVM
sfence.vma x0, x0 // attempt to call sfence should cause illegal instruction with TVM

END_TESTS

TEST_STACK_AND_DATA

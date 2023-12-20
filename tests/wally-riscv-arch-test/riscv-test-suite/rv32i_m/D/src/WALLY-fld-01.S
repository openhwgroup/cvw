///////////////////////////////////////////
// ../../wally-riscv-arch-test/riscv-test-suite/rv32i_m/D/src/WALLY-fld.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2022-07-07 16:55:21.991349//
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

#include "model_test.h"
#include "arch_test.h"

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

#ifdef TEST_CASE_1

RVTEST_FP_ENABLE()
RVTEST_VALBASEUPD(x7,test_fp)
RVTEST_SIGBASE( x6, wally_signature)
RVTEST_ISA("RV32IFD")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*F.*D.*);def TEST_CASE_1=True;",WALLY-fld)
inst_0:
 li x1,2
 fcvt.d.w f3, x1
 la x16, rvtest_data
 fsd f3,0(x16)
 fld f4,0(x16)
 fsd f4,0(x6)

 #endif

.EQU NUMTESTS,3

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0x98765432
.word 0x55555555
test_fp:
RVTEST_DATA_END

RVMODEL_DATA_BEGIN


wally_signature:
    .fill NUMTESTS*(XLEN/32),4,0xdeadbeef

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef

#endif

sig_end_canary:
.int 0x0
rvtest_sig_end:

RVMODEL_DATA_END
// ../../wally-riscv-arch-test/riscv-test-suite/rv32i_m/D/src/WALLY-fld.S
// David_Harris@hmc.edu & Katherine Parry

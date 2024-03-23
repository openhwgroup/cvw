///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-ADD.S
// David_Harris@hmc.edu & Rose Thompson
// Created 07 March 2024 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////
#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV64IFDQZfh_Zicsr")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

#ifdef TEST_CASE_1

RVTEST_CASE(0,"//check ISA:=regex(.*Q.*);def TEST_CASE_1=True;def NO_SAIL=True",flq-align)

RVTEST_FP_ENABLE()
RVTEST_VALBASEUPD(x3,test_dataset_0)
RVTEST_SIGBASE(x1,signature_x1_1)

#endif

# turn on the floating point unit
li x7, 1
slli x7, x7, 13
csrw mstatus, x7

li x4, 1        # 3fff 0000 0000 0000 0000 0000 0000 0000
li x2, 2        # 4000 0000 0000 0000 0000 0000 0000 0000
fcvt.q.w f2, x2
fcvt.q.w f4, x4

fcvt.h.w f5, x2  # 4000

# test quad load/store
fsq f4, 0(x3)
flq f7, 0(x3)
fsq f7, 0(x1)

# test half load/store
fsh f5, 16(x3)
flh f6, 16(x3)
fsh f6, 16(x1)
	
# 1 + 2 = 3           # 4000 8000 0000 0000 0000 0000 0000 0000
fadd.q f8, f2, f4
fsq f8, 32(x1)
	
# 1 - 2 = -1
fsub.q f9, f4, f2     # bfff 0000000000000000000000000000
fsq f9, 48(x1)
	
# 2 * 3 = 6
fmul.q f10, f2, f8     # 4001 8000000000000000000000000000
fsq f10, 64(x1)

# 6 * (-1) + 2 = -4
fmadd.q f11, f10, f9, f2     # C001 0000000000000000000000000000
fsq f11, 80(x1)

# -4 / 2 = -2
fdiv.q f12, f11, f2     # C000 0000000000000000000000000000
fsq f12, 96(x1)

# sign injection (-4, 1)  = 4
fsgnj.q f13, f11, f4    # 4001 0000000000000000000000000000
fsq f13, 112(x1)

# sqrt(4)  = 2
fsqrt.q f14, f13    # 4000 0000000000000000000000000000
fsq f14, 128(x1)
        

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
test_dataset_0:
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
.word 0xbabecafe
.word 0xabecafeb
.word 0xbecafeba
.word 0xecafebab
test_dataset_1:
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
rvtest_sig_begin:




signature_x1_1:
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
    .int 0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef
rvtest_sig_end:
RVMODEL_DATA_END

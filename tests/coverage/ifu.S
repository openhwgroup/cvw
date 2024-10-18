///////////////////////////////////////////
// ifu.S
//
// Written: sriley@g.hmc.edu 28 March 2023
//
// Purpose: Test coverage for IFU
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
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

// load code to initalize stack, handle interrupts, terminate
#include "WALLY-init-lib.h"

main:
    # turn floating point on
    li t0, 0x2000
    csrs mstatus, t0

    # calling compressed floating point load double instruction
    //.hword 0x2000 // CL type compressed floating-point ld-->funct3,imm,rs1',imm,rd',op
                        // binary version 0000 0000 0000 0000 0010 0000 0000 0000
    mv s0, sp
    c.fld fs0, 0(s0)    // Previously uncovered instructions
    c.fsd fs0, 0(s0)
    .hword 0x2002      // c.fldsp fs0, 0
    .hword 0xA002      // c.fsdsp fs0, 0
    .hword 0x9C41      // line 134 Illegal compressed instruction

    # Zcb coverage tests
    # could restore assembly language versions when GCC supports Zcb
    mv s0, sp
    #c.lbu s1, 0(s0)   // exercise c.lbu
    .hword 0x8004      // c.lbu s1, 0(s0)
    #c.lh s1, 0(s0)    // exercise c.lh
    .hword 0x8444      // c.lh s1, 0(s0)
    #c.lhu s1, 0(s0)   // exercise c.lhu
    .hword 0x8404      // c.lhu s1, 0(s0)
    #c.sb s1, 0(s0)    // exercise c.sb
    .hword 0x8804      // c.sb s1, 0(s0)
    #c.sh s1, 0(s0)    // exercise c.sh
    .hword 0x8C04      // c.sh s1, 0(s0)

    .hword 0x8C44      // Illegal compressed instruction with op = 00, Instr[15:10] = 100011, Instr[6] = 1 and 0's everywhere else. Line 119 illegal instruction
    .hword 0x9C00      // Illegal compressed instruction with op = 00, Instr[15:10] = 100111, and 0's everywhere else. Line 119 illegal instruction

    li s0, 0xFF
    # c.zext.b s0      // exercise c.zext.b
    .hword 0x9C61      // c.zext.b s0
    # c.sext.b s0      // exercise c.sext.b
    .hword 0x9C65      // c.sext.b s0
    # c.zext.h s0      // exercise c.zext.h
    .hword 0x9C69      // c.zext.h s0
    # c.sext.h s0      // exercise c.sext.h
    .hword 0x9C6D      // c.sext.h s0
    # c.zext.w s0      // exercise c.zext.w
    .hword 0x9C71      // c.zext.w s0
    # c.not s0         // exercise c.not
    .hword 0x9C75      // c.not s0

    .hword 0x9C7D      // Reserved instruction from line 187 with op = 01, Instr[15:10] = 100111, Instr[6:5] = 11, and 0's everywhere else

    # exercise all the cache ways
    j way0code

# stress test cache ways by loading stuff from each one and then doing fence.i to invalidate
.align 12
way0code:
    jal way1code
    fence.i
    j done

.align 12
way1code:
    j way2code

.align 12
way2code:
    j way3code

.align 12
way3code:
    j way00code

.align 12
way00code:
    ret


    j done

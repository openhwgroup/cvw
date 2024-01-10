///////////////////////////////////////////
// ifu.S
//
// Written: sriley@g.hmc.edu 28 March 2023
//
// Purpose: Test coverage for IFU
//
// A component of the CORE-V-WALLY configurable RISC-V project.
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
    # could restore assembly language versions when GCC supports Zcb
#    c.lbu s1, 0(s0)    // exercise c.lbu
    mv s0, sp
    .hword 0x8004      // c.lbu s1, 0(s0)
    
    //.hword 0x9C01     //# Illegal compressed instruction with op = 01, instr[15:10] = 100111, and 0's everywhere else


    
   
    j done

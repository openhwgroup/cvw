///////////////////////////////////////////
// tlbNAPOT.S
//
// Written: mmendozamanriquez@hmc.edu 4 April 2023
//          nlimpert@hmc.edu
// Adapted David_Harris@hmc.edu 8/29/23 to exercise NAPOT huge pages
//
// Purpose: Test coverage for LSU NAPOT
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

# run-elf.bash find this in project description
main:
    # Page table root address at 0x80010000; SV48
    li t5, 0x9000000000080010  
    csrw satp, t5

    # sfence.vma x0, x0

    # switch to supervisor mode
    li a0, 1   
    ecall

    li t0, 0x80215240

    li t2, 0             # i = 0
    li t3, 33     # Max amount of Loops = 32
    li t4, 0x200000
    li t5, 0x8082 # return instruction opcode

loop: bge t2, t3, finished   # exit loop if i >= loops
    sw t5, 0(t0)   # store a return at this address to exercise DTLB
    lw t1, 0(t0)   # read it back
    fence.i    # synchronize with I$
    jalr ra, t0 # jump to the return statement to exercise the ITLB
    add t0, t0, t4
    addi t2, t2, 1
    j loop

finished:
    j done

.data

.align 16
# root Page table situated at 0x80010000
pagetable: 
    .8byte 0x200044C1 // old page table was 200040 which just pointed to itself! wrong

# next page table at 0x80011000
.align 12
    .8byte 0x0000000000000000
    .8byte 0x00000000200048C1
    .8byte 0x00000000200048C1
    

# Next page table at 0x80012000
.align 12
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1
    .8byte 0x0000000020004CC1

# Leaf page table at 0x80013000
.align 12
    #80000000
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF

    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF

    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF

    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF
    .8byte 0x80000000200020CF

    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF

    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF

    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF

    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    .8byte 0x80000000200060CF
    
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF

    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF

    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF

    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF
    .8byte 0x800000002000A0CF

    .8byte 0x800000002000E0CF
    .8byte 0x800000002000E0CF
    .8byte 0x800000002000E0CF
    .8byte 0x800000002000E0CF

    .8byte 0x800000002000E0CF
    .8byte 0x800000002000E0CF

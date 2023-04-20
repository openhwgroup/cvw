///////////////////////////////////////////
// tlbGLB.S
//
// Written: mmendozamanriquez@hmc.edu 4 April 2023
//          nlimpert@hmc.edu
//
// Purpose: coverage for the global check. 
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
    # Page table root address at 0x80010000
    li t5, 0x9000000000080080 // try making asid = 0. 
    csrw satp, t5

    # sfence.vma x0, x0

    # switch to supervisor mode
    li a0, 1   
    ecall

    li t0, 0xC0000000

    li t2, 0             # i = 0
    li t5, 0            # j = 0 // now use as a counter for new asid loop 
    li t3, 32     # Max amount of Loops = 32

loop: bge t2, t3, nASID   # exit loop if i >= loops
    lw t1, 0(t0)
    li t4, 0x1000
    add t0, t0, t4
    addi t2, t2, 1
    j loop

nASID: bne t5, zero, finished
    li a0, 3   // go
    ecall
    li t5, 0x9000100000080080 // try making asid = 1 
    csrw satp, t5
    li a0, 1   
    ecall
    li t2, 0
    li t0, 0xC0000000
    li t5, 1 // make this not zero. 
    j loop


finished:
    j done

.data
.align 19
# level 3 Page table situated at 0x8008 0000, should point to 8008,1000
pagetable: 
    .8byte 0x200204C1
    
.align 12 // level 2 page table, contains direction to a gigapageg
    .8byte 0x0
    .8byte 0x0
    .8byte 0x200000CF // gigapage that starts at 8000 0000 goes to C000 0000
    .8byte 0x200208C1 // pointer to next page table entry at 8008 2000

.align 12 // level 1 page table, points to level 0 page table
    .8byte 0x20020CE1

.align 12 // level 0 page table, points to address C000 0000 // FOR NOW ALL OF THESE GO TO 8 instead of C cause they start with 2
    .8byte 0x200000CF // access xC000 0000
    .8byte 0x200004CF // access xC000 1000
    .8byte 0x200008CF // access xC000 2000
    .8byte 0x20000CCF // access xC000 3000

    .8byte 0x200010EF // access xC000 4000
    .8byte 0x200014EF
    .8byte 0x200018EF
    .8byte 0x20001CEF

    .8byte 0x200020EF // access xC000 8000
    .8byte 0x200024EF
    .8byte 0x200028EF
    .8byte 0x20002CEF

    .8byte 0x200030EF // access xC000 C000
    .8byte 0x200034EF
    .8byte 0x200038EF
    .8byte 0x20003CEF

    .8byte 0x200040EF // access xC001 0000
    .8byte 0x200044EF
    .8byte 0x200048EF
    .8byte 0x20004CEF

    .8byte 0x200050EF // access xC001 4000
    .8byte 0x200054EF
    .8byte 0x200058EF
    .8byte 0x20005CEF

    .8byte 0x200060EF // access xC001 8000
    .8byte 0x200064EF
    .8byte 0x200068EF
    .8byte 0x20006CEF

    .8byte 0x200070EF // access xC001 C000
    .8byte 0x200074eF
    .8byte 0x200078EF
    .8byte 0x20007CEF

    .8byte 0x200080EF // access xC002 0000
    .8byte 0x200084EF
    .8byte 0x200088EF
    .8byte 0x20008CEF

    
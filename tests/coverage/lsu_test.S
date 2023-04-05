///////////////////////////////////////////
// lsu_test.S
//
// Written: mmendozamanriquez@hmc.edu 4 April 2023
//          nlimpert@hmc.edu
//
// Purpose: Test coverage for LSU
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
    li t5, 0x9000000000090000
    csrw satp, t5

    # sfence.vma

    # switch to supervisor mode
    li a0, 1   
    ecall

    li t0, 0x80000000

    li t2, 0             # i = 0
    li t3, 33           # loops = 33

loop: bge t2, t3, done   # exit loop if i >= loops
    lw t1, 0(t0)
    addi t0, t0, 0x400
    addi t0, t0, 0x400
    addi t0, t0, 0x400
    addi t0, t0, 0x400
    addi t2, t2, 1
    j loop


.data

.align 28
pagetable: 
    # 0x90001
    .8byte 0x240000C1 # Read through chapter 8, see page table process/ level 1 pointer

.align 12
    .8byte 0x0
    .8byte 0x240008C1

.align 12
    .8byte 0x24000CC1

.align 12
#80000
    .8byte 0x200000CF
    .8byte 0x200004CF
    .8byte 0x200008CF
    .8byte 0x20000CCF
    .8byte 0x200010CF
    .8byte 0x200014CF
    .8byte 0x200018CF
    .8byte 0x20001CCF
    .8byte 0x200020CF
    .8byte 0x200024CF
    .8byte 0x200028CF
    .8byte 0x20002CCF
    .8byte 0x200030CF
    .8byte 0x200034CF
    .8byte 0x200038CF
    .8byte 0x20003CCF
    .8byte 0x200040CF
    .8byte 0x200044CF
    .8byte 0x200048CF
    .8byte 0x20004CCF
    .8byte 0x200050CF
    .8byte 0x200054CF
    .8byte 0x200058CF
    .8byte 0x20005CCF
    .8byte 0x200060CF
    .8byte 0x200064CF
    .8byte 0x200068CF
    .8byte 0x20006CCF
    .8byte 0x200070CF
    .8byte 0x200074CF
    .8byte 0x200078CF
    .8byte 0x20007CCF
    .8byte 0x200080CF


.text
///////////////////////////////////////////
// tlbmisc.S
//
// Written David_Harris@hmc.edu 1/1/24
//
// Purpose: Test coverage for other TLB issues
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
    li t5, 0x1
    slli t5, t5, 62
    ori t5, t5, 0xF0
    csrs menvcfg, t5  # menvcfg.PBMTE = 1, CBZE, CBCFE, CBIE all 1

    # store ret instruction in case we jump to an address mapping to 80000000
    li t0, 0x80000000
    li t5, 0x8082 # return instruction opcode
    sw t5, 0(t0)    
    fence.i

    # Page table root address at 0x80010000; SV48
    li t5, 0x9000000000080010  
    csrw satp, t5

    # sfence.vma x0, x0

    # switch to supervisor mode
    li a0, 1   
    ecall

    # Instruction fetch from misaligned pages
    jal changetoipfhandler  # set up trap handler to return from instruction page fault if necessary
    li t0, 0x8000000000
    jalr ra, t0 # jump misaligned terapage
    li t0, 0x00000000
    jalr ra, t0 # jump to misaligned gigapage
    li t0, 0x80200000
    jalr ra, t0 # jump to misaligned megapage


    # exercise malformed PBMT pages

    # page has PBMT = 3 (reserved)
    li t0, 0x80400000
    lw t1, 0(t0)    # read from page
    sw t1, 0(t0)    # write to page
    jalr ra, t0     # jump to page

    # Nonleaf PTE has PBMT != 0     # this should cause a page fault during page walking.  However, as of issue 546 1/1/24, both ImperasDV and Wally don't detect this
    li t0, 0x80600000
    lw t1, 0(t0)    # read from page
    sw t1, 0(t0)    # write to page
    jalr ra, t0     # jump to page


    # change back to default trap handler after checking everything that might cause an instruction page fault
    jal changetodefaulthandler

    # exercise CBOM instructions with various permissions
    li t0, 0x80800000
    cbo.zero (t0)
    cbo.clean (t0)
    li t0, 0x80801000
    cbo.zero (t0)
    cbo.clean (t0)
    li t0, 0x80802000
    cbo.zero (t0)
    cbo.clean (t0)
    li t0, 0x80803000
    cbo.zero (t0)
    cbo.clean (t0)

    # set mstatus.MXR
    li a0, 3
    ecall
    li t0, 1
    slli t0, t0, 19
    csrs mstatus, t0 # mstatus.mxr = 1
    li a0, 1
    ecall

    # exercise CBOM again now that MXR is set
    li t0, 0x80800000
    cbo.zero (t0)
    cbo.clean (t0)
    li t0, 0x80801000
    cbo.zero (t0)
    cbo.clean (t0)
    li t0, 0x80802000
    cbo.zero (t0)
    cbo.clean (t0)
    li t0, 0x80803000
    cbo.zero (t0)
    cbo.clean (t0)

    # clear mstatus.MXR
    li a0, 3
    ecall
    li t0, 1
    slli t0, t0, 19
    csrc mstatus, t0 # mstatus.mxr = 1
    li a0, 1
    ecall


    # wrap up
    li a0, 3 # switch back to machine mode because code at 0x80000000 may not have clean page table entry
    ecall
    j done


changetoipfhandler:
    li a0, 3    
    ecall       # switch to machine mode
    la a0, ipf_handler
    csrw mtvec, a0 # point to new handler
    li a0, 1
    ecall       # switch back to supervisor mode
    ret

changetodefaulthandler:
    li a0, 3    
    ecall       # switch to machine mode
    la a0, trap_handler
    csrw mtvec, a0 # point to new handler
    li a0, 1
    ecall       # switch back to supervisor mode
    ret

instructionpagefaulthandler:
    csrw mepc, ra # go back to calling function
    mret

.align 4                # trap handlers must be aligned to multiple of 4
ipf_handler:
    # Load trap handler stack pointer tp
    csrrw tp, mscratch, tp  # swap MSCRATCH and tp
    sd t0, 0(tp)        # Save t0 and t1 on the stack
    sd t1, -8(tp)
    csrr t0, mcause     # Check the cause
    li t1, 8            # is it an ecall trap?
    andi t0, t0, 0xFC   # if CAUSE = 8, 9, or 11
    beq t0, t1, ecall   # yes, take ecall
    csrr t0, mcause
    li t1, 12           # is it an instruction page fault
    beq t0, t1, ipf     # yes, return to calling function
    j trap_return

ipf:
    csrw mepc, ra       # return to calling function
    ld t1, -8(tp)       # restore t1 and t0
    ld t0, 0(tp)
    csrrw tp, mscratch, tp  # restore tp
    mret                # return from trap

.data

.align 16
# root Page table situated at 0x80010000
pagetable: 
    .8byte 0x200044C1  # 0x00000000-0x80_00000000: PTE at 0x80011000 C1 dirty, accessed, valid
    .8byte 0x00000000000010CF # misaligned terapage at 0x80_00000000

# next page table at 0x80011000
.align 12
    .8byte 0x00000000000010CF # misaligned gigapage at 0x00000000
    .8byte 0x00000000200058C1 # PTE for pages at 0x40000000
    .8byte 0x00000000200048C1 # gigapage at 0x80000000 pointing to 0x80120000
 

# Next page table at 0x80012000 for gigapage at 0x80000000
.align 12
    .8byte 0x0000000020004CC1  # for VA starting at 80000000 (pointer to NAPOT 64 KiB pages)
    .8byte 0x0000000020014CCF  # for VA starting at 80200000 (misaligned megapage)
    .8byte 0x00000000200050C1  # for VA starting at 80400000 (bad PBMT pages)
    .8byte 0x4000000020004CC1  # for VA starting at 80600000 (bad entry: nonleaf PTE can't have PBMT != 0)
    .8byte 0x00000000200054C1  # for VA starting at 80800000 (testing rwx permissiosn with cbom/cboz)
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

# Leaf page table at 0x80013000 with NAPOT pages
.align 12
    #80000000
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF

    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF

    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF

    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF
    .8byte 0xA0000000200020CF

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

# Leaf page table at 0x80014000 with PBMT pages
.align 12
    #80400000
    .8byte 0x60000000200020CF   # reserved entry

# Leaf page table at 0x80015000 with various permissions for testing CBOM and CBOZ
.align 12
    #80800000
    .8byte 0x00000000200000CF   # valid rwx for VA 80800000
    .8byte 0x00000000200000CF   # valid r x for VA 80801000
    .8byte 0x00000000200000CF   # valid r   for VA 80802000
    .8byte 0x00000000200000CF   # valid   x for CA 80003000



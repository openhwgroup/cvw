///////////////////////////////////////////
//
// WALLY-TEST-LIB-32.S
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2021-07-19
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

#include "model_test.h"
#include "arch_test.h"

.macro INIT_TESTS

RVTEST_ISA("RV32I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

    // ---------------------------------------------------------------------------------------------
    // Initialization Overview:
    //   
    //   Initialize x6 as a virtual pointer to the test results
    //   Initialize x16 as a physical pointer to the test results
    //   Set up stack pointer, mscratch, sscratch
    //   
	// ---------------------------------------------------------------------------------------------

    // address for test results
    la x6, test_1_res
    la x16, test_1_res // x16 reserved for the physical address equivalent of x6 to be used in trap handlers
                        // any time either is used, both must be updated.

    // address for normal user stack, mscratch stack, and sscratch stack
    la sp, mscratch_top
    csrw mscratch, sp
    la sp, sscratch_top
    csrw sscratch, sp
    la sp, stack_top

.endm

// Code to trigger traps goes here so we have consistent mtvals for instruction adresses
// Even if more tests are added.  
.macro CAUSE_TRAP_TRIGGERS
j end_trap_triggers

// The following tests involve causing many of the interrupts and exceptions that are easily done in a few lines
//      This effectively includes everything that isn't to do with page faults (virtual memory)
//      
//      INPUTS: a3 (x13): the number of times one of the infinitely looping interrupt causes should loop before giving up and continuing without the interrupt firing.
//
cause_instr_addr_misaligned:
    // cause a misaligned address trap
    auipc x28, 0      // get current PC, which is aligned
    addi x28, x28, 0x2  // add 2 to pc to create misaligned address (Assumes compressed instructions are disabled)
    jr x28 // cause instruction address midaligned trap
    ret

cause_instr_access:
    la x28, 0x0 // address zero is an address with no memory
    sw x1, -4(sp) // push the return adress ontot the stack
    addi sp, sp, -4
    jalr x28 // cause instruction access trap
    lw x1, 0(sp) // pop return adress back from the stack
    addi sp, sp, 4
    ret

cause_illegal_instr:
    .word 0x00000000 // 32 bit zero is an illegal instruction
    ret

cause_breakpnt:
    ebreak
    ret

cause_load_addr_misaligned:
    auipc x28, 0      // get current PC, which is aligned
    addi x28, x28, 1
    lw x29, 0(x28)    // load from a misaligned address
    ret

cause_load_acc:
    la x28, 0         // 0 is an address with no memory
    lw x29, 0(x28)    // load from unimplemented address
    ret

cause_store_addr_misaligned:
    auipc x28, 0      // get current PC, which is aligned
    addi x28, x28, 1
    sw x29, 0(x28)     // store to a misaligned address
    ret

cause_store_acc: 
    la x28, 0         // 0 is an address with no memory
    sw x29, 0(x28)     // store to unimplemented address
    ret

cause_ecall:
    // *** ASSUMES you have already gone to the mode you need to call this from.
    ecall
    ret

cause_m_time_interrupt:
    // The following code works for both RV32 and RV64.  
    // RV64 alone would be easier using double-word adds and stores
    li x28, 0x30          // Desired offset from the present time
    mv a3, x28            // copy value in to know to stop waiting for interrupt after this many cycles
    la x29, 0x02004000    // MTIMECMP register in CLINT
    la x30, 0x0200BFF8    // MTIME register in CLINT
    lw x7, 0(x30)         // low word of MTIME
    lw x31, 4(x30)         // high word of MTIME
    add x28, x7, x28       // add desired offset to the current time
    bgtu x28, x7, nowrap  // check new time exceeds current time (no wraparound)
    addi x31, x31, 1       // if wrap, increment most significant word
    sw x31,4(x29)          // store into most significant word of MTIMECMP
nowrap:
    sw x28, 0(x29)         // store into least significant word of MTIMECMP
time_loop:
    //wfi // *** this may now spin us forever in the loop???
    addi a3, a3, -1
    bnez a3, time_loop // go through this loop for [a3 value] iterations before returning without performing interrupt
    ret

cause_s_time_interrupt:
    li x28, 0x20
    csrs mip, x28 // set supervisor time interrupt pending. SIP is a subset of MIP, so writing this should also change MIP.
    nop // added extra nops in so the csrs can get through the pipeline before returning.
    ret

cause_m_soft_interrupt:
    la x28, 0x02000000      // MSIP register in CLINT
    li x29, 1               // 1 in the lsb
    sw x29, 0(x28)          // Write MSIP bit
    ret

cause_s_soft_interrupt:
    li x28, 0x2
    csrs sip, x28 // set supervisor software interrupt pending. SIP is a subset of MIP, so writing this should also change MIP.
    ret

cause_m_ext_interrupt:
    # ========== Configure PLIC ==========
    # m priority threshold = 0
    li x28, 0xC200000
    li x29, 0
    sw x29, 0(x28)
    # s priority threshold = 7
    li x28, 0xC201000
    li x29, 7
    sw x29, 0(x28)
    # source 3 (GPIO) priority = 1
    li x28, 0xC000000
    li x29, 1
    sw x29, 0x0C(x28)
    # enable source 3 in M Mode
    li x28, 0x0C002000
    li x29, 0b1000 
    sw x29, 0(x28)

    li x28, 0x10060000 // load base GPIO memory location
    li x29, 0x1
    sw x29, 0x08(x28)  // enable the first pin as an output
    sw x29, 0x04(x28)  // enable the first pin as an input as well to cause the interrupt to fire

    sw x0, 0x1C(x28) // clear rise_ip
    sw x0, 0x24(x28) // clear fall_ip
    sw x0, 0x2C(x28) // clear high_ip
    sw x0, 0x34(x28) // clear low_ip

    sw x29, 0x28(x28)  // set first pin to interrupt on a rising value
    sw x29, 0x0C(x28)  // write a 1 to the first output pin (cause interrupt)
m_ext_loop:
    //wfi
    addi a3, a3, -1
    bnez a3, m_ext_loop // go through this loop for [a3 value] iterations before returning without performing interrupt
    ret

cause_s_ext_interrupt_GPIO:
    # ========== Configure PLIC ==========
    # s priority threshold = 0
    li x28, 0xC201000
    li x29, 0
    sw x29, 0(x28)
    # m priority threshold = 7
    li x28, 0xC200000
    li x29, 7
    sw x29, 0(x28)
    # source 3 (GPIO) priority = 1
    li x28, 0xC000000
    li x29, 1
    sw x29, 0x0C(x28)
    # enable source 3 in S mode
    li x28, 0x0C002080
    li x29, 0b1000 
    sw x29, 0(x28)

    li x28, 0x10060000 // load base GPIO memory location
    li x29, 0x1
    sw x29, 0x08(x28)  // enable the first pin as an output
    sw x29, 0x04(x28)  // enable the first pin as an input as well to cause the interrupt to fire

    sw x0, 0x1C(x28) // clear rise_ip
    sw x0, 0x24(x28) // clear fall_ip
    sw x0, 0x2C(x28) // clear high_ip
    sw x0, 0x34(x28) // clear low_ip

    sw x29, 0x28(x28)  // set first pin to interrupt on a rising value
    sw x29, 0x0C(x28)  // write a 1 to the first output pin (cause interrupt)
s_ext_loop:
    //wfi
    addi a3, a3, -1
    bnez a3, s_ext_loop // go through this loop for [a3 value] iterations before returning without performing interrupt
    ret

end_trap_triggers:
.endm

.macro TRAP_HANDLER MODE, VECTORED=1, DEBUG=0
    // MODE decides which mode this trap handler will be taken in (M or S mode)
    // Vectored decides whether interrupts are handled with the vector table at trap_handler_MODE (1)
    //      vs Using the non-vector approach the rest of the trap handler takes (0)
    // DEBUG decides whether we will print mtval a string with status.mpie, status.mie, and status.mpp to the signature (1)
    //      vs not saving that info to the signature (0)


    //   Set up the exception Handler, keeping the original handler in x4.
    la x1, trap_handler_\MODE\()
    ori x1, x1, \VECTORED // set mode field of tvec to VECTORED, which will force vectored interrupts if it's 1.

.if (\MODE\() == m)
    csrrw x4, \MODE\()tvec, x1  // x4 reserved for "default" trap handler address that needs to be restored before halting this test.
.else
    csrw \MODE\()tvec, x1 // we only neet save the machine trap handler and this if statement ensures it isn't overwritten
.endif

    li a0, 0
    li a1, 0 
    li a2, 0 // reset trap handler inputs to zero

    la x29, 0x02004000    // MTIMECMP register in CLINT
    li x30, 0xFFFFFFFF
    sw x30, 0(x29) // set mtimecmp to 0xFFFFFFFF to really make sure time interrupts don't go off immediately after being enabled

    j trap_handler_end_\MODE\() // skip the trap handler when it is being defined.

	// ---------------------------------------------------------------------------------------------
    // General traps Handler
    // 
    //   Handles traps by branching to different behaviors based on mcause.
    //   
    //   Note that allowing the exception handler to change mode for a program is a huge security
    //   hole, but this is an expedient way of writing tests that need different modes
    // 
    // input parameters:
    // 
    //   a0 (x10): 
    //       0: halt program with no failures
    //       1: halt program with failure in x11 = a1
    //       2: go to machine mode
    //       3: go to supervisor mode
    //       4: go to user mode
    //       others: do nothing
    //
    //   a1 (x11): 
    //       VPN for return address after changing privilege mode.
    //       This should be the base VPN with no offset.
    //       0x0 : defaults to next instruction on the same page the trap was called on.
    //
    //   a2 (x12): 
    //       Pagetype of the current address VPN before changing privilge mode
    //       Used so that we can know how many bits of the adress are the offset.
    //       Ignored if a1 == 0x0
    //       0: Kilopage
    //       1: Megapage
    //      
    // --------------------------------------------------------------------------------------------


.align 2
trap_handler_\MODE\():
    j trap_unvectored_\MODE\() // for the unvectored implimentation: jump past this table of addresses into the actual handler
    // *** ASSUMES that a cause value of 0 for an interrupt is unimplemented
    // otherwise, a vectored interrupt handler should jump to trap_handler_\MODE\() + 4 * Interrupt cause code
    // No matter the value of VECTORED, exceptions (not interrupts) are handled in an unvecotred way
    j s_soft_vector_\MODE\()    // 1: instruction access fault // the zero spot is taken up by the instruction to skip this table.
    j segfault_\MODE\()            // 2: reserved
    j m_soft_vector_\MODE\()    // 3: breakpoint
    j segfault_\MODE\()            // 4: reserved
    j s_time_vector_\MODE\()    // 5: load access fault
    j segfault_\MODE\()            // 6: reserved
    j m_time_vector_\MODE\()    // 7: store access fault
    j segfault_\MODE\()            // 8: reserved
    j s_ext_vector_\MODE\()     // 9: ecall from S-mode
    j segfault_\MODE\()            // 10: reserved
    j m_ext_vector_\MODE\()     // 11: ecall from M-mode
    // 12 through >=16 are reserved or designated for platform use

trap_unvectored_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap hanler without messing up sp's value or the stack itself.
    // *** NOTE: this means that nested traps will be screwed up but they shouldn't happen in any of these tests

trap_stack_saved_\MODE\(): // jump here after handling vectored interupt since we already switch sp and scratch there
    // save registers on stack before using
    sw x1, -4(sp)       
    sw x5, -8(sp)
    sw x7, -12(sp)       

    // Record trap
    csrr x1, \MODE\()cause     // record the mcause
    sw x1, 0(x16)        
    addi x6, x6, 4     
    addi x16, x16, 4    // update pointers for logging results

.if (\DEBUG\() == 1) // record extra information (MTVAL, some status bits) about traps
    csrr x1, \MODE\()tval
    sw x1, 0(x16)
    addi x6, x6, 4     
    addi x16, x16, 4

    csrr x1, \MODE\()status
    .if (\MODE\() == m) // Taking traps in different modes means we want to get different bits from the status register.
        li x5, 0x1888 // mask bits to select MPP, MPIE, and MIE.
    .else
        li x5, 0x122 // mask bits to select SPP, SPIE, and SIE.
    .endif
    and x5, x5, x1
    sw x5, 0(x16) // store masked out status bits to the output
    addi x6, x6, 4
    addi x16, x16, 4

.endif

    // Respond to trap based on cause
    // All interrupts should return after being logged
    csrr x1, \MODE\()cause
    li x5, 0x80000000   // if msb is set, it is an interrupt
    and x5, x5, x1
    bnez x5, interrupt_handler_\MODE\()
    // Other trap handling is specified in the vector Table
    la x5, exception_vector_table_\MODE\()
    slli x1, x1, 2          // multiply cause by 4 to get offset in vector Table
    add x5, x5, x1      // compute address of vector in Table
    lw x5, 0(x5)        // fectch address of handler from vector Table
    jr x5               // and jump to the handler

interrupt_handler_\MODE\():
    la x5, interrupt_vector_table_\MODE\() // NOTE THIS IS NOT THE SAME AS VECTORED INTERRUPTS!!!
    slli x1, x1, 2          // multiply cause by 4 to get offset in vector Table
    add x5, x5, x1      // compute address of vector in Table
    lw x5, 0(x5)        // fectch address of handler from vector Table
    jr x5               // and jump to the handler

segfault_\MODE\():
    lw x7, -12(sp)  // restore registers from stack before faulting 
    lw x5, -8(sp)
    lw x1, -4(sp)       
    j terminate_test          // halt program.

trapreturn_\MODE\():
    csrr x1, \MODE\()epc       // get the mepc
    addi x1, x1, 4

trapreturn_specified_\MODE\():
    // reset the necessary pointers and registers (x1, x5, x6, and the return address going to mepc)
    // note that we don't need to change x7 since it was a temporary register with no important address in it.
    // so that when we return to a new virtual address, they're all in the right spot as well.

    beqz a1, trapreturn_finished_\MODE\() // either update values, of go to default return address.

    la x5, trap_return_pagetype_table_\MODE\()
    slli a2, a2, 2
    add x5, x5, a2
    lw a2, 0(x5) // a2 = number of offset bits in current page type
    
    li x5, 1
    sll x5, x5, a2
    addi x5, x5, -1 // x5 = mask bits for offset into current pagetype

    // reset the top of the stack, x1
    lw x7, -4(sp) 
    and x7, x5, x7 // x7 = offset for x1
    add x7, x7, a1 // x7 = new address for x1
    sw x7, -4(sp)

    // reset the second spot in the stack, x5
    lw x7, -8(sp)
    and x7, x5, x7 // x7 = offset for x5
    add x7, x7, a1 // x7 = new address for x5
    sw x7, -8(sp)

    // reset x6, the pointer for the virtual address of the output of the tests
    and x7, x5, x6 // x7 = offset for x6
    add x6, x7, a1 // x6 = new address for the result pointer
    
    // reset x1, which temporarily holds the return address that will be written to mepc.
    and x1, x5, x1 // x1 = offset for the return address
    add x1, x1, a1 // x1 = new return address.

    li a1, 0 
    li a2, 0 // reset trapreturn inputs to the trap handler

trapreturn_finished_\MODE\():
    csrw \MODE\()epc, x1   // update the mepc with address of next instruction
    lw x7, -12(sp)     // restore registers from stack before returning
    lw x5, -8(sp)   
    lw x1, -4(sp)
    csrrw sp, \MODE\()scratch, sp // switch sp and scratch stack back to restore the non-trap stack pointer
    \MODE\()ret  // return from trap

// specific exception handlers

ecallhandler_\MODE\():
    // Check input parameter a0. encoding above. 
    li x5, 2            // case 2: change to machine mode
    beq a0, x5, ecallhandler_changetomachinemode_\MODE\()
    li x5, 3            // case 3: change to supervisor mode
    beq a0, x5, ecallhandler_changetosupervisormode_\MODE\()
    li x5, 4            // case 4: change to user mode
    beq a0, x5, ecallhandler_changetousermode_\MODE\()
    // unsupported ecalls should segfault
    j segfault_\MODE\()

ecallhandler_changetomachinemode_\MODE\():
    // Force status.MPP (bits 12:11) to 11 to enter machine mode after mret
    // note that it is impossible to return to M mode after a trap delegated to S mode
    li x1, 0b1100000000000
    csrs \MODE\()status, x1
    j trapreturn_\MODE\()

ecallhandler_changetosupervisormode_\MODE\():
    // Force status.MPP (bits 12:11) and status.SPP (bit 8) to 01 to enter supervisor mode after (m/s)ret
    li x1, 0b1000000000000  
    csrc \MODE\()status, x1
    li x1, 0b0100100000000
    csrs \MODE\()status, x1
    j trapreturn_\MODE\()

ecallhandler_changetousermode_\MODE\():
    // Force status.MPP (bits 12:11) and status.SPP (bit 8) to 00 to enter user mode after (m/s)ret
    li x1, 0b1100100000000  
    csrc \MODE\()status, x1
    j trapreturn_\MODE\()

instrpagefault_\MODE\():
    lw x1, -4(sp) // load return address int x1 (the address AFTER the jal into faulting page)
    j trapreturn_finished_\MODE\() // puts x1 into mepc, restores stack and returns to program (outside of faulting page)

instrfault_\MODE\():
    lw x1, -4(sp) // load return address int x1 (the address AFTER the jal to the faulting address)
    j trapreturn_finished_\MODE\() // return to the code after recording the mcause

illegalinstr_\MODE\():
    j trapreturn_\MODE\() // return to the code after recording the mcause

accessfault_\MODE\():
    j trapreturn_\MODE\()

addr_misaligned_\MODE\():
    j trapreturn_\MODE\()

breakpt_\MODE\():
    j trapreturn_\MODE\()

// Vectored interrupt handlers: record the fact that the handler went to the correct vector and then continue to handling
// note: does not mess up any registers, saves and restores them to the stack instead.

s_soft_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap hanler without messing up sp's value or the stack itself.
    sw x5, -4(sp) // put x5 on the scratch stack before messing with it
    li x5, 0x7EC01 // write 0x7ec01 (for "VEC"tored and 01 for the interrupt code)
    j vectored_int_end_\MODE\()

m_soft_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap hanler without messing up sp's value or the stack itself.
    sw x5, -4(sp) // put x5 on the scratch stack before messing with it
    li x5, 0x7EC03 // write 0x7ec03 (for "VEC"tored and 03 for the interrupt code)
    j vectored_int_end_\MODE\()

s_time_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap hanler without messing up sp's value or the stack itself.
    sw x5, -4(sp) // put x5 on the scratch stack before messing with it
    li x5, 0x7EC05 // write 0x7ec05 (for "VEC"tored and 05 for the interrupt code)
    j vectored_int_end_\MODE\()

m_time_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap hanler without messing up sp's value or the stack itself.
    sw x5, -4(sp) // put x5 on the scratch stack before messing with it
    li x5, 0x7EC07 // write 0x7ec07 (for "VEC"tored and 07 for the interrupt code)
    j vectored_int_end_\MODE\()

s_ext_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap hanler without messing up sp's value or the stack itself.
    sw x5, -4(sp) // put x5 on the scratch stack before messing with it
    li x5, 0x7EC09 // write 0x7ec09 (for "VEC"tored and 08 for the interrupt code)
    j vectored_int_end_\MODE\()

m_ext_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap hanler without messing up sp's value or the stack itself.
    sw x5, -4(sp) // put x5 on the scratch stack before messing with it
    li x5, 0x7EC0B // write 0x7ec0B (for "VEC"tored and 0B for the interrupt code)
    j vectored_int_end_\MODE\()

vectored_int_end_\MODE\():
    sw x5, 0(x16) // store to signature to show vectored interrupts succeeded. 
    addi x6, x6, 4
    addi x16, x16, 4
    lw x5, -4(sp) // restore x5 before continuing to handle trap in case its needed.
    j trap_stack_saved_\MODE\()

// specific interrupt handlers

soft_interrupt_\MODE\():
    la x5, 0x02000000 // Reset by clearing MSIP interrupt from CLINT
    sw x0, 0(x5)

    csrci \MODE\()ip, 0x2 // clear supervisor software interrupt pending bit 
    lw x1, -4(sp) // load return address from stack into ra (the address to return to after causing this interrupt)
    // Note: we do this because the mepc loads in the address of the instruction after the sw that causes the interrupt
    //  This means that this trap handler will return to the next address after that one, which might be unpredictable behavior.
    j trapreturn_finished_\MODE\() // return to the code at ra value from before trap

time_interrupt_\MODE\():
    la x5, 0x02004000    // MTIMECMP register in CLINT
    li x7, 0xFFFFFFFF
    sw x7, 0(x5) // reset interrupt by setting mtimecmp to 0xFFFFFFFF
    
    li x5, 0x20
    csrc \MODE\()ip, x5
    lw x1, -4(sp) // load return address from stack into ra (the address to return to after the loop is complete)
    j trapreturn_finished_\MODE\() // return to the code at ra value from before trap

ext_interrupt_\MODE\():
    li x28, 0x10060000 // reset interrupt by clearing all the GPIO bits
    sw x0, 8(x28) // disable the first pin as an output
    sw x0, 40(x28) // write a 0 to the first output pin (reset interrupt)

    # reset PLIC to turn off external interrupts
    # m priority threshold = 7
    li x28, 0xC200000
    li x5, 0x7
    sw x5, 0(x28)
    # s priority threshold = 7
    li x28, 0xC201000
    li x5, 0x7
    sw x5, 0(x28)
    # source 3 (GPIO) priority = 0
    li x28, 0xC000000
    li x5, 0
    sw x5, 0x0C(x28)
    # disable source 3 in M mode
    li x28, 0x0C002000
    li x5, 0b0000
    sw x5, 0(x28)
    # enable source 3 in S mode
    li x28, 0x0C002080
    li x29, 0b0000
    sw x29, 0(x28)

    li x5, 0x200
    csrc \MODE\()ip, x5

    lw x1, -4(sp) // load return address from stack into ra (the address to return to after the loop is complete)
    j trapreturn_finished_\MODE\() // return to the code at ra value from before trap


    // Table of trap behavior
    // lists what to do on each exception (not interrupts)
    // unexpected exceptions should cause segfaults for easy detection
    // Expected exceptions should increment the EPC to the next instruction and return

    .align 2 // aligns this data table to an 4 byte boundary
exception_vector_table_\MODE\():
    .4byte addr_misaligned_\MODE\()      // 0: instruction address misaligned
    .4byte instrfault_\MODE\()    // 1: instruction access fault
    .4byte illegalinstr_\MODE\()  // 2: illegal instruction
    .4byte breakpt_\MODE\()      // 3: breakpoint
    .4byte addr_misaligned_\MODE\()      // 4: load address misaligned
    .4byte accessfault_\MODE\()   // 5: load access fault
    .4byte addr_misaligned_\MODE\()      // 6: store address misaligned
    .4byte accessfault_\MODE\()   // 7: store access fault
    .4byte ecallhandler_\MODE\()  // 8: ecall from U-mode
    .4byte ecallhandler_\MODE\()  // 9: ecall from S-mode
    .4byte segfault_\MODE\()      // 10: reserved
    .4byte ecallhandler_\MODE\()  // 11: ecall from M-mode
    .4byte instrpagefault_\MODE\()    // 12: instruction page fault
    .4byte trapreturn_\MODE\()    // 13: load page fault
    .4byte segfault_\MODE\()      // 14: reserved
    .4byte trapreturn_\MODE\()    // 15: store page fault

   .align 2 // aligns this data table to an 4 byte boundary
interrupt_vector_table_\MODE\():
    .4byte segfault_\MODE\()            // 0: reserved
    .4byte soft_interrupt_\MODE\()    // 1: instruction access fault // the zero spot is taken up by the instruction to skip this table.
    .4byte segfault_\MODE\()            // 2: reserved
    .4byte soft_interrupt_\MODE\()    // 3: breakpoint
    .4byte segfault_\MODE\()            // 4: reserved
    .4byte time_interrupt_\MODE\()    // 5: load access fault
    .4byte segfault_\MODE\()            // 6: reserved
    .4byte time_interrupt_\MODE\()    // 7: store access fault
    .4byte segfault_\MODE\()            // 8: reserved
    .4byte ext_interrupt_\MODE\()     // 9: ecall from S-mode
    .4byte segfault_\MODE\()            // 10: reserved
    .4byte ext_interrupt_\MODE\()     // 11: ecall from M-mode


.align 2
trap_return_pagetype_table_\MODE\():
    .4byte 0xC  // 0: kilopage has 12 offset bits
    .4byte 0x16 // 1: megapage has 22 offset bits

trap_handler_end_\MODE\(): // place to jump to so we can skip the trap handler and continue with the test
.endm

// Test Summary table!

// Test Name            : Description                               : Fault output value                        : Normal output values
// ---------------------:-------------------------------------------:-------------------------------------------:------------------------------------------------------
//   write64_test       : Write 64 bits to address                  : 0x6, 0x7, or 0xf                          : None
//   write32_test       : Write 32 bits to address                  : 0x6, 0x7, or 0xf                          : None 
//   write16_test       : Write 16 bits to address                  : 0x6, 0x7, or 0xf                          : None 
//   write08_test       : Write 8 bits to address                   : 0x6, 0x7, or 0xf                          : None
//   read64_test        : Read 64 bits from address                 : 0x4, 0x5, or 0xd, then 0xbad              : readvalue in hex
//   read32_test        : Read 32 bitsfrom address                  : 0x4, 0x5, or 0xd, then 0xbad              : readvalue in hex
//   read16_test        : Read 16 bitsfrom address                  : 0x4, 0x5, or 0xd, then 0xbad              : readvalue in hex
//   read08_test        : Read 8 bitsfrom address                   : 0x4, 0x5, or 0xd, then 0xbad              : readvalue in hex
//   executable_test    : test executable on virtual page           : 0x0, 0x1, or 0xc, then 0xbad              : value of x7 modified by exectuion code (usually 0x111)
//   terminate_test     : terminate tests                           : mcause value for fault                    : from M 0xb, from S 0x9, from U 0x8  
//   goto_baremetal     : satp.MODE = bare metal                    : None                                      : None 
//   goto_sv32          : satp.MODE = sv32                          : None                                      : None 
//   goto_m_mode        : go to mahcine mode                        : mcause value for fault                    : from M 0xb, from S 0x9, from U 0x8  
//   goto_s_mode        : go to supervisor mode                     : mcause value for fault                    : from M 0xb, from S 0x9, from U 0x8
//   goto_u_mode        : go to user mode                           : mcause value for fault                    : from M 0xb, from S 0x9, from U 0x8 
//   write_read_csr     : write to specified CSR                    : old CSR value, 0x2, depending on perms    : value written to CSR
//   csr_r_access       : test read-only permissions on CSR         : 0xbad                                     : 0x2, then 0x11

// *** TESTS TO ADD: execute inline, read unknown value out, read CSR unknown value, just read CSR value

.macro WRITE32 ADDR VAL
    // attempt to write VAL to ADDR
    // Success outputs:
    //      None
    // Fault outputs:
    //      0x6: misaligned address
    //      0x7: access fault
    //      0xf: page fault
    li x29, \VAL
    li x30, \ADDR
    sw x29, 0(x30)
.endm

.macro WRITE16 ADDR VAL
    // all write tests have the same description/outputs as write64
    li x29, \VAL
    li x30, \ADDR
    sh x29, 0(x30)
.endm

.macro WRITE08 ADDR VAL
    // all write tests have the same description/outputs as write64
    li x29, \VAL
    li x30, \ADDR
    sb x29, 0(x30)
.endm

.macro READ32 ADDR
    // Attempt read at ADDR. Write the value read out to the output *** Consider adding specific test for reading a non known value
    // Success outputs:
    //      value read out from ADDR
    // Fault outputs:
    //      One of the following followed by 0xBAD
    //      0x4: misaligned address
    //      0x5: access fault
    //      0xD: page fault
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    li x29, \ADDR 
    lw x7, 0(x29) 
    sw x7, 0(x6)
    addi x6, x6, 4 
    addi x16, x16, 4
.endm

.macro READ16 ADDR
    // All reads have the same description/outputs as read32. 
    // They will store the sign extended value of what was read out at ADDR
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    li x29, \ADDR 
    lh x7, 0(x29) 
    sw x7, 0(x6)
    addi x6, x6, 4 
    addi x16, x16, 4
.endm

.macro READ08 ADDR
    // All reads have the same description/outputs as read64. 
    // They will store the sign extended value of what was read out at ADDR
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    li x29, \ADDR 
    lb x7, 0(x29) 
    sw x7, 0(x6)
    addi x6, x6, 4 
    addi x16, x16, 4
.endm

// These goto_x_mode tests all involve invoking the trap handler,
// So their outputs are inevitably:
//      0x8: test called from U mode
//      0x9: test called from S mode
//      0xB: test called from M mode
// they generally do not fault or cause issues as long as these modes are enabled 
// *** add functionality to check if modes are enabled before jumping? maybe cause a fault if not?

.macro GOTO_M_MODE RETURN_VPN=0x0 RETURN_PAGETYPE=0x0
    li a0, 2 // determine trap handler behavior (go to machine mode)
    li a1, \RETURN_VPN // return VPN
    li a2, \RETURN_PAGETYPE // return page types
    ecall // writes mcause to the output.
    // now in S mode
.endm

.macro GOTO_S_MODE RETURN_VPN=0x0 RETURN_PAGETYPE=0x0
    li a0, 3 // determine trap handler behavior (go to supervisor mode)
    li a1, \RETURN_VPN // return VPN
    li a2, \RETURN_PAGETYPE // return page types
    ecall // writes mcause to the output.
    // now in S mode
.endm

.macro GOTO_U_MODE RETURN_VPN=0x0 RETURN_PAGETYPE=0x0
    li a0, 4 // determine trap handler behavior (go to user mode)
    li a1, \RETURN_VPN // return VPN
    li a2, \RETURN_PAGETYPE // return page types
    ecall // writes mcause to the output.
    // now in S mode
.endm

// These tests change virtual memory settings, turning it on/off and changing between types.
// They don't have outputs as any error with turning on virtual memory should reveal itself in the tests *** Consider changing this policy?

.macro GOTO_BAREMETAL
    // Turn translation off
    li x7, 0 // satp.MODE value for bare metal (0)
    slli x7, x7, 31
    csrw satp, x7
    //sfence.vma x0, x0 // *** flushes global pte's as well
.endm

.macro GOTO_SV32 ASID BASE_PPN
    // Turn on sv39 virtual memory
    li x7, 1 // satp.MODE value for Sv32 (1)
    slli x7, x7, 31
    li x29, \ASID
    slli x29, x29, 22
    or x7, x7, x29 // put ASID into the correct field of SATP
    li x28, \BASE_PPN // Base Pagetable physical page number, satp.PPN field.
    add x7, x7, x28
    csrw satp, x7
    //sfence.vma x0, x0 // *** flushes global pte's as well
.endm

.macro WRITE_READ_CSR CSR VAL
    // attempt to write CSR with VAL. Note: this also tests read access to CSR
    // Success outputs:
    //      value read back out from CSR after writing
    // Fault outputs:
    //      The previous CSR value before write attempt
    //      *** Most likely 0x2, the mcause for illegal instruction if we don't have write or read access
    li x30, 0xbad // load bad value to be overwritten by csrr
    li x29, \VAL
    csrw \CSR\(), x29
    csrr x30, \CSR
    sw x30, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
.endm

.macro CSR_R_ACCESS CSR
    // verify that a csr is accessible to read but not to write
    // Success outputs:
    //      0x2, then
    //      0x11 *** consider changing to something more meaningful
    // Fault outputs:
    //      0xBAD *** consider changing this one as well. in general, do we need the branching if it hould cause an illegal instruction fault? 
    csrr x29, \CSR
    csrwi \CSR\(), 0xA // Attempt to write a 'random' value to the CSR
    csrr x30, \CSR
    bne x30, x29, 1f // 1f represents write_access
    li x30, 0x11 // Write failed, confirming read only permissions.
    j 2f // j r_access_end
1: // w_access (write succeeded, violating read-only)
    li x30, 0xBAD
2: // r_access end
    sw x30, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
.endm

.macro EXECUTE_AT_ADDRESS ADDR
    // Execute the code already written to ADDR, returning the value in x7. 
    // *** Note: this test itself doesn't write the code to ADDR because it might be callled at a point where we dont have write access to ADDR
    // Assumes the code modifies x7, usually to become 0x111. 
    // Sample code:  0x11100393 (li x7, 0x111), 0x00008067 (ret)
    // Success outputs:
    //      modified value of x7. (0x111 if you use the sample code)
    // Fault outputs:
    //      One of the following followed by 0xBAD
    //      0x0: misaligned address
    //      0x1: access fault
    //      0xC: page fault
    fence.i // forces caches and main memory to sync so execution code written to ADDR can run.
    li x7, 0xBAD
    li x28, \ADDR
    jalr x28 // jump to executable test code 
    sw x7, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4 
.endm

.macro END_TESTS
    // invokes one final ecall to return to machine mode then terminates this program, so the output is
    //      0x8: termination called from U mode
    //      0x9: termination called from S mode
    //      0xB: termination called from M mode
    j terminate_test

.endm

	// ---------------------------------------------------------------------------------------------
    // Test Handler
    //
    // This test handler works in a similar wy to the trap handler. It takes in a few things by reading from a table in memory
    // (see test_cases) and performing certain behavior based on them.
    //
    // Input parameters: 
    //
    // x28:
    //     Address input for the test taking place (think: address to read/write, new address to return to, etc...)
    //
    // x29:
    //     Value input for the test taking place (think: value to write, any other extra info needed)
    //
    // x30:
    //     Label for the location of the test that's about to take place
    // ------------------------------------------------------------------------------------------------------------------------------------

.macro INIT_TEST_TABLE // *** Consider renaming this test. to what???

test_loop_setup:
    la x5, test_cases

test_loop:
    lw x28, 0(x5) // fetch test case address
    lw x29, 4(x5) // fetch test case value
    lw x30, 8(x5) // fetch test case flag
    addi x5, x5, 12 // set x5 to next test case

    // x5 has the symbol for a test's location in the assembly
    li x7, 0x3FFFFF 
    and x30, x30, x7 // This program is always on at least a megapage, so this masks out the megapage offset.
    auipc x7, 0x0
    srli x7, x7, 22
    slli x7, x7, 22 // zero out the bottom 22 bits so the megapage offset of the symbol can be placed there
    or x30, x7, x30 // x30 = virtual address of the symbol for this type of test.

    jr x30

// Test Name             : Description                               : Fault output value     : Normal output values
// ----------------------:-------------------------------------------:------------------------:------------------------------------------------------
//   write32_test        : Write 32 bits to address                  : 0xf                    : None 
//   write16_test        : Write 16 bits to address                  : 0xf                    : None 
//   write08_test        : Write 8 bits to address                   : 0xf                    : None
//   read32_test         : Read 32 bits from address                  : 0xd, 0xbad             : readvalue in hex
//   read16_test         : Read 16 bits from address                  : 0xd, 0xbad             : readvalue in hex
//   read08_test         : Read 8 bits from address                   : 0xd, 0xbad             : readvalue in hex
//   executable_test     : test executable on virtual page           : 0xc, 0xbad             : value of x7 modified by exectuion code (usually 0x111)
//   terminate_test      : terminate tests                           : mcause value for fault : from M 0xb, from S 0x9, from U 0x8  
//   goto_baremetal      : satp.MODE = bare metal                    : None                   : None 
//   goto_sv39           : satp.MODE = sv39                          : None                   : None 
//   goto_sv48           : satp.MODE = sv48                          : None                   : None
//   write_mxr_sum       : write sstatus.[19:18] = MXR, SUM bits     : None                   : None
//   goto_m_mode         : go to mahcine mode                        : mcause value for fault : from M 0xb, from S 0x9, from U 0x8  
//   goto_s_mode         : go to supervisor mode                     : mcause value for fault : from M 0xb, from S 0x9, from U 0x8
//   goto_u_mode         : go to user mode                           : mcause value for fault : from M 0xb, from S 0x9, from U 0x8 
//   write_pmpcfg_x      : Write one of the pmpcfg csr's             : mstatuses?, 0xD        : readback of pmpcfg value
//   write_pmpaddr_x     : Write one of the pmpaddr csr's            : None                   : readback of pmpaddr value

write32_test:
    // address to write in x28, word value in x29
    sw x29, 0(x28)
    j test_loop // go to next test case

write16_test:
    // address to write in x28, halfword value in x29
    sh x29, 0(x28)
    j test_loop // go to next test case

write08_test:
    // address to write in x28, value in x29
    sb x29, 0(x28)
    j test_loop // go to next test case

read32_test:
    // address to read in x28, expected 32 bit value in x29 (unused, but there for your perusal).
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    lw x7, 0(x28)
    sw x7, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop // go to next test case

read16_test:
    // address to read in x28, expected 16 bit value in x29 (unused, but there for your perusal).
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    lh x7, 0(x28)
    sw x7, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop // go to next test case

read08_test:
    // address to read in x28, expected 8 bit value in x29 (unused, but there for your perusal).
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    lb x7, 0(x28)
    sw x7, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop // go to next test case

goto_s_mode:
    // return to address in x28, 
    li a0, 3 // Trap handler behavior (go to supervisor mode)
    mv a1, x28 // return VPN
    mv a2, x29 // return page types
    ecall // writes mcause to the output.
    // now in S mode
    j test_loop

goto_m_mode:
    li a0, 2 // Trap handler behavior (go to machine mode)
    mv a1, x28 // return VPN
    mv a2, x29 // return page types
    ecall // writes mcause to the output.
    j test_loop

goto_u_mode:
    li a0, 4 // Trap handler behavior (go to user mode)
    mv a1, x28 // return VPN
    mv a2, x29 // return page types
    ecall // writes mcause to the output.
    j test_loop

goto_baremetal:
    // Turn translation off
    GOTO_BAREMETAL
    j test_loop // go to next test case

goto_sv32:
    // Turn sv48 translation on
    // Base PPN in x28, ASID in x29
    li x7, 1 // satp.MODE value for sv32 (1)
    slli x7, x7, 31
    slli x29, x29, 22
    or x7, x7, x29 // put ASID into the correct field of SATP
    or x7, x7, x28 // Base Pagetable physical page number, satp.PPN field.
    csrw satp, x7
    j test_loop // go to next test case

write_mxr_sum:
    // writes sstatus.[mxr, sum] with the (assumed to be) 2 bit value in x29. also assumes we're in S. M mode
    li x30, 0xC0000 // mask bits for MXR, SUM
    not x7, x29
    slli x7, x7, 18
    and x7, x7, x30
    slli x29, x29, 18
    csrc sstatus, x7
    csrs sstatus, x29
    j test_loop

read_write_mprv:
    // reads old mstatus.mprv value to output, then
    // Writes mstatus.mprv with the 1 bit value in x29. assumes we're in m mode
    li x30, 0x20000 // mask bits for mprv
    csrr x7, mstatus
    and x7, x7, x30
    srli x7, x7, 17
    sw x7, 0(x6) // store old mprv to output
    addi x6, x6, 4
    addi x16, x16, 4 

    not x7, x29
    slli x7, x7, 17
    slli x29, x29, 17
    csrc mstatus, x7
    csrs mstatus, x29 // clear or set mprv bit
    li x7, 0x1800  
    csrc mstatus, x7
    li x7, 0x800
    csrs mstatus, x7 // set mpp to supervisor mode to see if mprv=1 really executes in the mpp mode
    j test_loop


write_pmpcfg_0:
    // writes the value in x29 to the pmpcfg register specified in x28.
    // then writes the final value of pmpcfgX to the output.
    csrw pmpcfg0, x29
    csrr x30, pmpcfg0
    j write_pmpcfg_end

write_pmpcfg_1:
    csrw pmpcfg1, x29
    csrr x30, pmpcfg1
    j write_pmpcfg_end

write_pmpcfg_2:
    csrw pmpcfg2, x29
    csrr x30, pmpcfg2
    j write_pmpcfg_end

write_pmpcfg_3:
    csrw pmpcfg3, x29
    csrr x30, pmpcfg3
    j write_pmpcfg_end

write_pmpcfg_end:
    sw x30, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop

write_pmpaddr_0:
    // write_read_csr pmpaddr0, x29
    // writes the value in x29 to the pmpaddr register specified in x28.
    // then writes the final value of pmpaddrX to the output.
    csrw pmpaddr0, x29
    csrr x30, pmpaddr0
    j write_pmpaddr_end

write_pmpaddr_1:
    csrw pmpaddr1, x29
    csrr x30, pmpaddr1
    j write_pmpaddr_end

write_pmpaddr_2:
    csrw pmpaddr2, x29
    csrr x30, pmpaddr2
    j write_pmpaddr_end

write_pmpaddr_3:
    csrw pmpaddr3, x29
    csrr x30, pmpaddr3
    j write_pmpaddr_end

write_pmpaddr_4:
    csrw pmpaddr4, x29
    csrr x30, pmpaddr4
    j write_pmpaddr_end

write_pmpaddr_5:
    csrw pmpaddr5, x29
    csrr x30, pmpaddr5
    j write_pmpaddr_end

write_pmpaddr_6:
    csrw pmpaddr6, x29
    csrr x30, pmpaddr6
    j write_pmpaddr_end

write_pmpaddr_7:
    csrw pmpaddr7, x29
    csrr x30, pmpaddr7
    j write_pmpaddr_end

write_pmpaddr_8:
    csrw pmpaddr8, x29
    csrr x30, pmpaddr8
    j write_pmpaddr_end

write_pmpaddr_9:
    csrw pmpaddr9, x29
    csrr x30, pmpaddr9
    j write_pmpaddr_end

write_pmpaddr_10:
    csrw pmpaddr10, x29
    csrr x30, pmpaddr10
    j write_pmpaddr_end

write_pmpaddr_11:
    csrw pmpaddr11, x29
    csrr x30, pmpaddr11
    j write_pmpaddr_end

write_pmpaddr_12:
    csrw pmpaddr12, x29
    csrr x30, pmpaddr12
    j write_pmpaddr_end

write_pmpaddr_13:
    csrw pmpaddr13, x29
    csrr x30, pmpaddr13
    j write_pmpaddr_end

write_pmpaddr_14:
    csrw pmpaddr14, x29
    csrr x30, pmpaddr14
    j write_pmpaddr_end

write_pmpaddr_15:
    csrw pmpaddr15, x29
    csrr x30, pmpaddr15
    j write_pmpaddr_end

write_pmpaddr_end:
    sw x30, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop

executable_test:
    // Execute the code at the address in x28, returning the value in x7.
    // Assumes the code modifies x7, to become the value stored in x29 for this test.  
    fence.i // forces cache and main memory to sync so execution code written by the program can run.
    li x7, 0xBAD
    jalr x28 
    sw x7, 0(x6) 
    addi x6, x6, 4
    addi x16, x16, 4 
    j test_loop

.endm 

// notably, terminate_test is not a part of the test table macro because it needs to be defined 
// in any type of test, macro or test table, for the trap handler to work
terminate_test:

    li a0, 2 // Trap handler behavior (go to machine mode)
    ecall //  writes mcause to the output.
    csrw mtvec, x4  // restore original trap handler to halt program

RVTEST_CODE_END
RVMODEL_HALT

.macro TEST_STACK_AND_DATA

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0xbabecafe
RVTEST_DATA_END

.align 2 // align stack to 4 byte boundary
stack_bottom:
    .fill 1024, 4, 0xdeadbeef 
stack_top:

.align 2
mscratch_bottom:
    .fill 512, 4, 0xdeadbeef
mscratch_top:

.align 2
sscratch_bottom:
    .fill 512, 4, 0xdeadbeef
sscratch_top:


RVMODEL_DATA_BEGIN

test_1_res:
    .fill 1024, 4, 0xdeadbeef

RVMODEL_DATA_END

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef

#endif

.endm

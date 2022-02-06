///////////////////////////////////////////
//
// WALLY-TEST-LIB-64.h
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-01-30
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


.macro INIT_TESTS

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV64I")

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
    //   Set up stack pointer (sp = x2)
    //   Set up the exception Handler, keeping the original handler in x4.
    //   
	// ---------------------------------------------------------------------------------------------

    // address for test results
    la x6, test_1_res
    la x16, test_1_res // x16 reserved for the physical address equivalent of x6 to be used in trap handlers
                        // any time either is used, both must be updated.

    // address for stack
    la sp, top_of_stack

    // trap handler setup
    la x1, machine_trap_handler
    csrrw x4, mtvec, x1  // x4 reserved for "default" trap handler address that needs to be restored before halting this test.
    li a0, 0
    li a1, 0 
    li a2, 0 // reset trap handler inputs to zero

    // go to first test!
    j begin_test


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
    //       2: Gigapage
    //       3: Terapage
    //     
    // --------------------------------------------------------------------------------------------


machine_trap_handler:
    // The processor is always in machine mode when a trap takes us here
    // save registers on stack before using
    sd x1, -8(sp)       
    sd x5, -16(sp)     

    // Record trap
    csrr x1, mcause     // record the mcause
    sd x1, 0(x16)        
    addi x6, x6, 8     
    addi x16, x16, 8    // update pointers for logging results

    // Respond to trap based on cause
    // All interrupts should return after being logged
    li x5, 0x8000000000000000   // if msb is set, it is an interrupt
    and x5, x5, x1
    bnez x5, trapreturn   // return from interrupt
    // Other trap handling is specified in the vector Table
    slli x1, x1, 3      // multiply cause by 8 to get offset in vector Table
    la x5, trap_handler_vector_table
    add x5, x5, x1      // compute address of vector in Table
    ld x5, 0(x5)        // fectch address of handler from vector Table
    jr x5               // and jump to the handler
    
segfault:
    ld x5, -16(sp)      // restore registers from stack before faulting
    ld x1, -8(sp)       
    j terminate_test          // halt program.

trapreturn:
    // look at the instruction to figure out whether to add 2 or 4 bytes to PC, or go to address specified in a1
    csrr x1, mepc       // get the mepc
    addi x1, x1, 4 // *** should be 2 for compressed instructions, see note.


// ****** KMG: the following is no longer as easy to determine. mepc gets the virtual address of the trapped instruction, 
// ********     but in the handler, we work in M mode with physical addresses
//              This means the address in mepc is suddenly pointing somewhere else.
//              to get this to work, We could either retranslate the vaddr back into a paddr (probably on the scale of difficult to intractible)
//              or we could come up with some other ingenious way to stay in M mode and see if the instruction was compressed.

//     lw x5, 0(x1)        // read the faulting instruction
//     li x1, 3            // check bottom 2 bits of instruction to see if compressed
//     and x5, x5, x1      // mask the other bits
//     beq x5, x1, trapreturn_uncompressed  // if 11, the instruction is return_uncompressed

// trapreturn_compressed:
//     csrr x1, mepc       // get the mepc again
//     addi x1, x1, 2      // add 2 to find the next instruction
//     j trapreturn_specified // and return

// trapreturn_uncompressed:
//     csrr x1, mepc       // get the mepc again    
//     addi x1, x1, 4      // add 4 to find the next instruction

trapreturn_specified:
    // reset the necessary pointers and registers (x1, x5, x6, and the return address going to mepc)
    // so that when we return to a new virtual address, they're all in the right spot as well.

    beqz a1, trapreturn_finished // either update values, of go to default return address.

    la x5, trap_return_pagetype_table
    slli a2, a2, 3
    add x5, x5, a2
    ld a2, 0(x5) // a2 = number of offset bits in current page type
    
    li x5, 1
    sll x5, x5, a2
    addi x5, x5, -1 // x5 = mask bits for offset into current pagetype

    // reset the top of the stack, x1
    ld x7, -8(sp) 
    and x7, x5, x7 // x7 = offset for x1
    add x7, x7, a1 // x7 = new address for x1
    sd x7, -8(sp)

    // reset the second spot in the stack, x5
    ld x7, -16(sp)
    and x7, x5, x7 // x7 = offset for x5
    add x7, x7, a1 // x7 = new address for x5
    sd x7, -16(sp)

    // reset x6, the pointer for the virtual address of the output of the tests
    and x7, x5, x6 // x7 = offset for x6
    add x6, x7, a1 // x6 = new address for the result pointer
    
    // set return address, stored temporarily in x1, to the next instruction, but in the new virtual page.
    and x1, x5, x1 // x1 = offset for the return address
    add x1, x1, a1 // x1 = new return address.

    li a1, 0 
    li a2, 0 // reset trapreturn inputs to the trap handler

trapreturn_finished:
    csrw mepc, x1       // update the mepc with address of next instruction
    ld x5, -16(sp)      // restore registers from stack before returning
    ld x1, -8(sp)
    mret  // return from trap

ecallhandler:
    // Check input parameter a0. encoding above. 
    // *** ASSUMES: that this trap is being handled in machine mode. in other words, that nothing odd has been written to the medeleg or mideleg csrs.
    li x5, 2            // case 2: change to machine mode
    beq a0, x5, ecallhandler_changetomachinemode
    li x5, 3            // case 3: change to supervisor mode
    beq a0, x5, ecallhandler_changetosupervisormode
    li x5, 4            // case 4: change to user mode
    beq a0, x5, ecallhandler_changetousermode
    // unsupported ecalls should segfault
    j segfault

ecallhandler_changetomachinemode:
    // Force mstatus.MPP (bits 12:11) to 11 to enter machine mode after mret
    li x1, 0b1100000000000
    csrs mstatus, x1
    j trapreturn        

ecallhandler_changetosupervisormode:
    // Force mstatus.MPP (bits 12:11) to 01 to enter supervisor mode after mret
    li x1, 0b1100000000000  
    csrc mstatus, x1
    li x1, 0b0100000000000
    csrs mstatus, x1
    j trapreturn

ecallhandler_changetousermode:
    // Force mstatus.MPP (bits 12:11) to 00 to enter user mode after mret
    li x1, 0b1100000000000  
    csrc mstatus, x1
    j trapreturn

instrfault:
    ld x1, -8(sp) // load return address int x1 (the address AFTER the jal into faulting page)
    j trapreturn_finished // puts x1 into mepc, restores stack and returns to program (outside of faulting page)

illegalinstr:
    j trapreturn // return to the code after recording the mcause

accessfault:
    // *** What do I have to do here?
    j trapreturn

    // Table of trap behavior
    // lists what to do on each exception (not interrupts)
    // unexpected exceptions should cause segfaults for easy detection
    // Expected exceptions should increment the EPC to the next instruction and return

    .align 3 // aligns this data table to an 8 byte boundary
trap_handler_vector_table:
    .8byte segfault      // 0: instruction address misaligned
    .8byte instrfault    // 1: instruction access fault
    .8byte illegalinstr  // 2: illegal instruction
    .8byte segfault      // 3: breakpoint
    .8byte segfault      // 4: load address misaligned
    .8byte accessfault   // 5: load access fault
    .8byte segfault      // 6: store address misaligned
    .8byte accessfault   // 7: store access fault
    .8byte ecallhandler  // 8: ecall from U-mode
    .8byte ecallhandler  // 9: ecall from S-mode
    .8byte segfault      // 10: reserved
    .8byte ecallhandler  // 11: ecall from M-mode
    .8byte instrfault    // 12: instruction page fault
    .8byte trapreturn    // 13: load page fault
    .8byte segfault      // 14: reserved
    .8byte trapreturn    // 15: store page fault

.align 3
trap_return_pagetype_table:
    .8byte 0xC  // 0: kilopage has 12 offset bits
    .8byte 0x15 // 1: megapage has 21 offset bits
    .8byte 0x1E // 2: gigapage has 30 offset bits
    .8byte 0x27 // 3: terapage has 39 offset bits

begin_test: // label here to jump to so we dont go through the trap handler before starting the test

.endm // Ends the initialization macro that set up the begginnning of the tests and the trap handler.


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
//   goto_sv39          : satp.MODE = sv39                          : None                                      : None 
//   goto_sv48          : satp.MODE = sv48                          : None                                      : None
//   goto_m_mode        : go to mahcine mode                        : mcause value for fault                    : from M 0xb, from S 0x9, from U 0x8  
//   goto_s_mode        : go to supervisor mode                     : mcause value for fault                    : from M 0xb, from S 0x9, from U 0x8
//   goto_u_mode        : go to user mode                           : mcause value for fault                    : from M 0xb, from S 0x9, from U 0x8 
//   write_read_csr     : write to specified CSR                    : old CSR value, 0x2, depending on perms    : value written to CSR
//   csr_r_access       : test read-only permissions on CSR         : 0xbad                                     : 0x2, then 0x11

// *** TESTS TO ADD: execute inline, read unknown value out, read CSR unknown value, just read CSR value

.macro write64_test ADDR VAL
    // attempt to write VAL to ADDR
    // Success outputs:
    //      None
    // Fault outputs:
    //      0x6: misaligned address
    //      0x7: access fault
    //      0xf: page fault     
    li x29, \VAL
    li x30, \ADDR
    sd x29, 0(x30)
.endm

.macro write32_test ADDR VAL
    // all write tests have the same description/outputs as write64
    li x29, \VAL
    li x30, \ADDR
    sw x29, 0(x30)
.endm

.macro write16_test ADDR VAL
    // all write tests have the same description/outputs as write64
    li x29, \VAL
    li x30, \ADDR
    sh x29, 0(x30)
.endm

.macro write08_test ADDR VAL
    // all write tests have the same description/outputs as write64
    li x29, \VAL
    li x30, \ADDR
    sb x29, 0(x30)
.endm

.macro read64_test ADDR
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
    ld x7, 0(x29) 
    sd x7, 0(x6)
    addi x6, x6, 8 
    addi x16, x16, 8
.endm

.macro read32_test ADDR
    // All reads have the same description/outputs as read64. 
    // They will store the sign extended value of what was read out at ADDR
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    li x29, \ADDR 
    lw x7, 0(x29) 
    sd x7, 0(x6)
    addi x6, x6, 8 
    addi x16, x16, 8
.endm

.macro read16_test ADDR
    // All reads have the same description/outputs as read64. 
    // They will store the sign extended value of what was read out at ADDR
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    li x29, \ADDR 
    lh x7, 0(x29) 
    sd x7, 0(x6)
    addi x6, x6, 8 
    addi x16, x16, 8
.endm

.macro read08_test ADDR
    // All reads have the same description/outputs as read64. 
    // They will store the sign extended value of what was read out at ADDR
    li x7, 0xBAD // bad value that will be overwritten on good reads.
    li x29, \ADDR 
    lb x7, 0(x29) 
    sd x7, 0(x6)
    addi x6, x6, 8 
    addi x16, x16, 8
.endm

// These goto_x_mode tests all involve invoking the trap handler,
// So their outputs are inevitably:
//      0x8: test called from U mode
//      0x9: test called from S mode
//      0xB: test called from M mode
// they generally do not fault or cause issues as long as these modes are enabled 
// *** add functionality to check if modes are enabled before jumping? maybe cause a fault if not?

.macro goto_m_mode RETURN_VPN RETURN_PAGETYPE
    li a0, 2 // determine trap handler behavior (go to supervisor mode)
    li a1, \RETURN_VPN // return VPN
    li a2, \RETURN_PAGETYPE // return page types
    ecall // writes mcause to the output.
    // now in S mode
.endm

.macro goto_s_mode RETURN_VPN RETURN_PAGETYPE
    li a0, 3 // determine trap handler behavior (go to supervisor mode)
    li a1, \RETURN_VPN // return VPN
    li a2, \RETURN_PAGETYPE // return page types
    ecall // writes mcause to the output.
    // now in S mode
.endm

.macro goto_u_mode RETURN_VPN RETURN_PAGETYPE
    li a0, 4 // determine trap handler behavior (go to supervisor mode)
    li a1, \RETURN_VPN // return VPN
    li a2, \RETURN_PAGETYPE // return page types
    ecall // writes mcause to the output.
    // now in S mode
.endm

// These tests change virtual memory settings, turning it on/off and changing between types.
// They don't have outputs as any error with turning on virtual memory should reveal itself in the tests *** Consider changing this policy?

.macro goto_baremetal
    // Turn translation off
    li x7, 0 // satp.MODE value for bare metal (0)
    slli x7, x7, 60
    li x28, 0x8000D // Base Pagetable physical page number, satp.PPN field. *** add option for different pagetable location
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 // *** flushes global pte's as well
.endm

.macro goto_sv39
    // Turn on sv39 virtual memory
    li x7, 8 // satp.MODE value for Sv39 (8)
    slli x7, x7, 60
    li x28, 0x8000D // Base Pagetable physical page number, satp.PPN field. *** add option for different pagetable location
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 // *** flushes global pte's as well
.endm

.macro goto_sv48
    // Turn on sv48 virtual memory
    li x7, 9 // satp.MODE value for Sv39 (8)
    slli x7, x7, 60
    li x28, 0x8000D // Base Pagetable physical page number, satp.PPN field. *** add option for different pagetable location
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 // *** flushes global pte's as well
.endm

.macro write_read_csr CSR VAL
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
    sd x30, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
.endm

.macro csr_r_access CSR
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
    sd x30, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
.endm

.macro execute_at_address ADDR
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
    sd x7, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8 
.endm

.macro END_TESTS
// invokes one final ecall to return to machine mode then terminates this program, so the output is
//      0x8: termination called from U mode
//      0x9: termination called from S mode
//      0xB: termination called from M mode

terminate_test:

    li a0, 2 // Trap handler behavior (go to machine mode)
    ecall //  writes mcause to the output.
    csrw mtvec, x4  // restore original trap handler to halt program

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0xbabecafe
RVTEST_DATA_END

.align 3 // align stack to 8 byte boundary
bottom_of_stack:
    .fill 1024, 4, 0xdeadbeef 
top_of_stack:


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

.endm // ends the macro that terminates this test program.
///////////////////////////////////////////
//
// WALLY-TEST-LIB-64.S
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
RVTEST_ISA("RV64I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

/*
#include "riscv_test_macros.h"
#include "compliance_test.h"
#include "compliance_io.h"

RV_COMPLIANCE_RV64M

RV_COMPLIANCE_CODE_BEGIN


	RVTEST_IO_INIT
	RVTEST_IO_ASSERT_GPR_EQ(x31, x0, 0x00000000)
	RVTEST_IO_WRITE_STR(x31, "Test Begin\n")

	# ---------------------------------------------------------------------------------------------

	RVTEST_IO_WRITE_STR(x31, "# Test group 1\n")
*/

	# ---------------------------------------------------------------------------------------------
    # Initialization Overview:
    #   
    #   Initialize x6 as a virtual pointer to the test results
    #   Initialize x16 as a physical pointer to the test results
    #   Set up stack pointer (sp = x2)
    #   Set up the exception Handler, keeping the original handler in x4.
    #   
	# ---------------------------------------------------------------------------------------------

    # address for test results
    la x6, test_1_res
    la x16, test_1_res # x16 reserved for the physical address equivalent of x6 to be used in trap handlers
                        # any time either is used, both must be updated.

    # address for stack
    la sp, top_of_stack

    # address for trap handler
    la x1, machine_trap_handler
    csrrw x4, mtvec, x1  # x4 reserved for "default" trap handler address that needs to be restored before halting this test.
    j test_setup


	# ---------------------------------------------------------------------------------------------
    # General traps Handler
    # 
    #   Handles traps by branching to different behaviors based on mcause.
    #   
    #   Note that allowing the exception handler to change mode for a program is a huge security
    #   hole, but this is an expedient way of writing tests that need different modes
    # 
    # input parameters:
    # 
    #   a0 (x10): 
    #       0: halt program with no failures
    #       1: halt program with failure in x11 = a1
    #       2: go to machine mode
    #       3: go to supervisor mode
    #       4: go to user mode
    #       others: do nothing
    #
    #   a1 (x11): Upper bits of change of return address after trap
    #             Put it in the bottom bits of a1. *** soon to be changed to just the base address of the return page. 
    #             Default : 0x0 (defaults to the next instruction in the same location as the return address)
    #             Terapage: returnAddr[END-1:39]
    #             Gigapage: returnAddr[END-1:30]
    #             Megapage: returnAddr[END-1:21]  
    #             Kilopage: returnAddr[END-1:12] (this value also works for baremetal)

    #   a2 (x12): Pagetype for change of return address after trap
    #             Put the Source page in a2[7:4] and Dest page in a2[3:0]
    #               Ex: giga -> mega a2=0x21
    #
    #             Default : Ignored if a1 == 0x0
    #             Terapage: 3
    #             Gigapage: 2
    #             Megapage: 1  
    #             Kilopage: 0
    #     
    # --------------------------------------------------------------------------------------------


machine_trap_handler:
    # The processor is always in machine mode when a trap takes us here
    # save registers on stack before using
    sd x1, -8(sp)       
    sd x5, -16(sp)      

    # Record trap
    csrr x1, mcause     # record the mcause
    sd x1, 0(x16)        
    addi x6, x6, 8     
    addi x16, x16, 8    # update pointers for logging results

    # Respond to trap based on cause
    # All interrupts should return after being logged
    li x5, 0x8000000000000000   # if msb is set, it is an interrupt
    and x5, x5, x1
    bnez x5, trapreturn   # return from interrupt
    # Other trap handling is specified in the vector Table
    slli x1, x1, 3      # multiply cause by 8 to get offset in vector Table
    la x5, trap_handler_vector_table
    add x5, x5, x1      # compute address of vector in Table
    ld x5, 0(x5)        # fectch address of handler from vector Table
    jr x5               # and jump to the handler
    
segfault:
    ld x5, -16(sp)      # restore registers from stack before faulting
    ld x1, -8(sp)       
    j terminate_test          # halt program.

trapreturn:
    # look at the instruction to figure out whether to add 2 or 4 bytes to PC, or go to address specified in a1
    csrr x1, mepc       # get the mepc
    addi x1, x1, 4 # *** should be 2 for compressed instructions, see note.


# ****** KMG: the following is no longer as easy to determine. mepc gets the virtual address of the trapped instruction, 
# ********     but in the handler, we work in M mode with physical addresses
#              This means the address in mepc is suddenly pointing somewhere else.
#              to get this to work, We could either retranslate the vaddr back into a paddr (probably on the scale of difficult to intractible)
#              or we could come up with some other ingenious way to stay in M mode and see if the instruction was compressed.

#     lw x5, 0(x1)        # read the faulting instruction
#     li x1, 3            # check bottom 2 bits of instruction to see if compressed
#     and x5, x5, x1      # mask the other bits
#     beq x5, x1, trapreturn_uncompressed  # if 11, the instruction is return_uncompressed

# trapreturn_compressed:
#     csrr x1, mepc       # get the mepc again
#     addi x1, x1, 2      # add 2 to find the next instruction
#     j trapreturn_specified # and return

# trapreturn_uncompressed:
#     csrr x1, mepc       # get the mepc again    
#     addi x1, x1, 4      # add 4 to find the next instruction

trapreturn_specified:
    # reset the necessary pointers and registers (x1, x5, x6, and the return address going to mepc)
    # so that when we return to a new virtual address, they're all in the right spot as well.

    beqz a1, trapreturn_finished # either update values, of go to default return address.

    # Get Mask Bits
    la x5, trap_return_pagetype_table
    mv x7, a2
    li x28, 0xF0 # mask bits for current pagetype 
    and x7, x28, x7
    srli x7, x7, 1
    add x5, x5, x7
    ld x7, 0(x5) # x7 = number of offset bits in current page type

    la x5, trap_return_pagetype_table
    li x28, 0xF # mask bits for new pagetype
    and a2, x28, a2
    slli a2, a2, 3
    add x5, x5, a2
    ld a2, 0(x5) # a2 = number of offset bits in new page type
    
    li x5, 1
    sll x5, x5, x7
    addi x5, x5, -1 # x5 = mask bits for offset into current pagetype

    # *** This shoulf be removed 
    sll a1, a1, a2 # a1 = the VPN of the new return page.

    # set x1, the stack pointer, to the new virtual address
    ld x7, -8(sp)
    and x7, x5, x7 # x7 = offset for x1
    add x7, x7, a1 # x7 = new address for x1
    sd x7, -8(sp)

    # set x5, the pointer for where we are in the test cases, to the new virtual address
    ld x7, -16(sp)
    and x7, x5, x7 # x7 = offset for x5
    add x7, x7, a1 # x7 = new address for x5
    sd x7, -16(sp)

    # set x6, the pointer for the virtual address of the output of the tests, to the new virtual address
    and x7, x5, x6 # x7 = offset for x6
    add x6, x7, a1 # x6 = new address for the result pointer
    
    # set return address to the next instruction, but in the new virtual page.
    and x1, x5, x1 # x1 = offset for the return address
    add x1, x1, a1 # x1 = new return address.

    li a1, 0 
    li a2, 0 # reset inputs to the trap handler

trapreturn_finished:
    csrw mepc, x1       # update the mepc with address of next instruction
    ld x5, -16(sp)      # restore registers from stack before returning
    ld x1, -8(sp)
    mret  # return from trap

ecallhandler:
    # Check input parameter a0. encoding above. 
    # *** ASSUMES: that this trap is being handled in machine mode. in other words, that nothing odd has been written to the medeleg or mideleg csrs.
    li x5, 2            # case 2: change to machine mode
    beq a0, x5, ecallhandler_changetomachinemode
    li x5, 3            # case 3: change to supervisor mode
    beq a0, x5, ecallhandler_changetosupervisormode
    li x5, 4            # case 4: change to user mode
    beq a0, x5, ecallhandler_changetousermode
    # unsupported ecalls should segfault
    j segfault

ecallhandler_changetomachinemode:
    # Force mstatus.MPP (bits 12:11) to 11 to enter machine mode after mret
    li x1, 0b1100000000000
    csrs mstatus, x1
    j trapreturn        

ecallhandler_changetosupervisormode:
    # Force mstatus.MPP (bits 12:11) to 01 to enter supervisor mode after mret
    li x1, 0b1100000000000  
    csrc mstatus, x1
    li x1, 0b0100000000000
    csrs mstatus, x1
    j trapreturn

ecallhandler_changetousermode:
    # Force mstatus.MPP (bits 12:11) to 00 to enter user mode after mret
    li x1, 0b1100000000000  
    csrc mstatus, x1
    j trapreturn

instrfault:
    ld x1, -8(sp) # load return address int x1 (the address AFTER the jal into faulting page)
    j trapreturn_finished # puts x1 into mepc, restores stack and returns to program (outside of faulting page)

accessfault:
    # *** What do I have to do here?
    j trapreturn

    # Table of trap behavior
    # lists what to do on each exception (not interrupts)
    # unexpected exceptions should cause segfaults for easy detection
    # Expected exceptions should increment the EPC to the next instruction and return

    .align 3 # aligns this data table to an 8 byte boundary
trap_handler_vector_table:
    .8byte segfault      # 0: instruction address misaligned
    .8byte instrfault    # 1: instruction access fault
    .8byte segfault      # 2: illegal instruction
    .8byte segfault      # 3: breakpoint
    .8byte segfault      # 4: load address misaligned
    .8byte accessfault   # 5: load access fault
    .8byte segfault      # 6: store address misaligned
    .8byte accessfault   # 7: store access fault
    .8byte ecallhandler  # 8: ecall from U-mode
    .8byte ecallhandler  # 9: ecall from S-mode
    .8byte segfault      # 10: reserved
    .8byte ecallhandler  # 11: ecall from M-mode
    .8byte instrfault    # 12: instruction page fault
    .8byte trapreturn    # 13: load page fault
    .8byte segfault      # 14: reserved
    .8byte trapreturn    # 15: store page fault

.align 3
trap_return_pagetype_table:
    .8byte 0xC  # 0: kilopage has 12 offset bits
    .8byte 0x15 # 1: megapage has 21 offset bits
    .8byte 0x1E # 2: gigapage has 30 offset bits
    .8byte 0x27 # 3: terapage has 39 offset bits

	# ---------------------------------------------------------------------------------------------
    # Test Handler
    #
    # This test handler works in a similar wy to the trap handler. It takes in a few things by reading from a table in memory
    # (see test_cases) and performing certain behavior based on them.
    #
    # Input parameters: 
    #
    # x28:
    #     Address input for the test taking place (think address to read/write, new address to return to, etc...)
    #
    # x29:
    #     Value input for the test taking place (think value to write, any other extra info needed)
    #
    # x30:
    #     Test type input that determines which kind of test will take place. Encoding for this input is in the table/case statements below
    #
    # ------------------------------------------------------------------------------------------------------------------------------------

test_setup:
    la x5, test_cases

test_loop:
    ld x28, 0(x5) # fetch test case address
    ld x29, 8(x5) # fetch test case value
    ld x30, 16(x5) # fetch test case flag
    addi x5, x5, 24 # set x5 to next test case

    # case statements for which test behavior to perform. 
    # *** We would use the same table method as the test types and trap handler,
    #     but using the la command to load the base of the table loads only the physical address
    #     So it doesn't work with virtual memory.
                                    #   x30 Value : Function                              : Fault output value     : Normal output values
                                    #   ----------:---------------------------------------:------------------------:------------------------------------------------------
    li x7, 0x0                      #             :                                       :                        : 
    beq x30, x7, write64_test       #         0x0 : Write 64 bits to address              : 0xf                    : None
    li x7, 0x11                     #             :                                       :                        : 
    beq x30, x7, write32_test       #        0x11 : Write 32 bits to address              : 0xf                    : None
    li x7, 0x12                     #             :                                       :                        : 
    beq x30, x7, write16_test       #        0x12 : Write 16 bits to address              : 0xf                    : None
    li x7, 0x13                     #             :                                       :                        : 
    beq x30, x7, write08_test       #        0x13 : Write 8 bits to address               : 0xf                    : None
    li x7, 0x1                      #             :                                       :                        :
    beq x30, x7, read64_test        #         0x1 : Read 64 bits from address             : 0xd, 0xbad             : readvalue in hex
    li x7, 0x14                     #             :                                       :                        :
    beq x30, x7, read32_test        #        0x14 : Read 32 bitsfrom address              : 0xd, 0xbad             : readvalue in hex
    li x7, 0x15                     #             :                                       :                        :
    beq x30, x7, read16_test        #        0x15 : Read 16 bitsfrom address              : 0xd, 0xbad             : readvalue in hex
    li x7, 0x16                     #             :                                       :                        :
    beq x30, x7, read08_test        #        0x16 : Read 8 bitsfrom address               : 0xd, 0xbad             : readvalue in hex
    li x7, 0x2                      #             :                                       :                        :
    beq x30, x7, executable_test    #         0x2 : test executable on virtual page       : 0xc, 0xbad             : value of x7 modified by exectuion code (usually 0x111)
    li x7, 0x3                      #             :                                       :                        :
    beq x30, x7, terminate_test     #         0x3 : terminate tests                       : mcause value for fault : from M 0xb, from S 0x9, from U 0x8  
    li x7, 0x4                      #             :                                       :                        :
    beq x30, x7, goto_baremetal     #         0x4 : satp.MODE = bare metal                : None                   : None 
    li x7, 0x5                      #             :                                       :                        :
    beq x30, x7, goto_sv39          #         0x5 : satp.MODE = sv39                      : None                   : None 
    li x7, 0x6                      #             :                                       :                        :
    beq x30, x7, goto_sv48          #         0x6 : satp.MODE = sv48                      : None                   : None
    li x7, 0x7                      #             :                                       :                        :
    beq x30, x7, write_mxr_sum      #         0x7 : write sstatus.[19:18] = MXR, SUM bits : None                   : None
    li x7, 0xD                      #             :                                       :                        :
    beq x30, x7, write_pmpcfg_0     #         0xD : Write one of the pmpcfg csr's         : mstatuses?, 0xD        : readback of pmpcfg value
    li x7, 0xE                      #             :                                       :                        :
    beq x30, x7, write_pmpaddr_0    #         0xE : Write one of the pmpaddr csr's        : None                   : None
    li x7, 0x8                      #             :                                       :                        :
    beq x30, x7, goto_m_mode        #         0x8 : go to mahcine mode                    : mcause value for fault : from M 0xb, from S 0x9, from U 0x8  
    li x7, 0x9                      #             :                                       :                        :
    beq x30, x7, goto_s_mode        #         0x9 : go to supervisor mode                 : mcause value for fault : from M 0xb, from S 0x9, from U 0x8
    li x7, 0xA                      #             :                                       :                        :
    beq x30, x7, goto_u_mode        #         0xA : go to user mode                       : mcause value for fault : from M 0xb, from S 0x9, from U 0x8 
                                    # ------------------------------------------------------------------------------------------------------------------------------------
    j terminate_test # default case: break

write64_test:
    # address to write in x28, double value in x29
    sd x29, 0(x28)
    j test_loop # go to next test case

write32_test:
    # address to write in x28, word value in x29
    sw x29, 0(x28)
    j test_loop # go to next test case

write16_test:
    # address to write in x28, halfword value in x29
    sh x29, 0(x28)
    j test_loop # go to next test case

write08_test:
    # address to write in x28, value in x29
    sb x29, 0(x28)
    j test_loop # go to next test case

read64_test:
    # address to read in x28, expected 64 bit value in x29 (unused, but there for your perusal).
    li x7, 0xBAD # bad value that will be overwritten on good reads.
    ld x7, 0(x28)
    sd x7, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
    j test_loop # go to next test case

read32_test:
    # address to read in x28, expected 32 bit value in x29 (unused, but there for your perusal).
    li x7, 0xBAD # bad value that will be overwritten on good reads.
    lw x7, 0(x28)
    sd x7, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
    j test_loop # go to next test case

read16_test:
    # address to read in x28, expected 16 bit value in x29 (unused, but there for your perusal).
    li x7, 0xBAD # bad value that will be overwritten on good reads.
    lh x7, 0(x28)
    sd x7, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
    j test_loop # go to next test case

read08_test:
    # address to read in x28, expected 8 bit value in x29 (unused, but there for your perusal).
    li x7, 0xBAD # bad value that will be overwritten on good reads.
    lb x7, 0(x28)
    sd x7, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
    j test_loop # go to next test case

goto_s_mode:
    # return to address in x28, 
    li a0, 3 # Trap handler behavior (go to supervisor mode)
    mv a1, x28 # return VPN
    mv a2, x29 # return page types
    ecall # writes mcause to the output.
    # now in S mode
    j test_loop

goto_m_mode:
    li a0, 2 # Trap handler behavior (go to machine mode)
    mv a1, x28 # return VPN
    mv a2, x29 # return page types
    ecall # writes mcause to the output.
    j test_loop

goto_u_mode:
    li a0, 4 # Trap handler behavior (go to user mode)
    mv a1, x28 # return VPN
    mv a2, x29 # return page types
    ecall # writes mcause to the output.
    j test_loop

goto_baremetal:
    # Turn translation off
    li x7, 0 # satp.MODE value for bare metal (0)
    slli x7, x7, 60
    li x28, 0x8000D # Base Pagetable physical page number, satp.PPN field.
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 # *** flushes global pte's as well
    j test_loop # go to next test case

goto_sv39:
    li x7, 8 # satp.MODE value for Sv39 (8)
    slli x7, x7, 60
    li x28, 0x8000D # Base Pagetable physical page number, satp.PPN field.
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 # *** flushes global pte's as well
    j test_loop # go to next test case

goto_sv48:
    li x7, 9 # satp.MODE value for Sv48
    slli x7, x7, 60
    li x28, 0x8000D # Base Pagetable physical page number, satp.PPN field.
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 # *** flushes global pte's as well
    j test_loop # go to next test case

write_mxr_sum:
    # writes sstatus.[mxr, sum] with the (assumed to be) 2 bit value in x29. also assumes we're in S. M mode
    li x30, 0xC0000 # mask bits for MXR, SUM
    not x7, x29
    slli x7, x7, 18
    and x7, x7, x30
    slli x29, x29, 18
    csrc sstatus, x7
    csrs sstatus, x29
    j test_loop

write_pmpcfg_0:
    # writes the value in x29 to the pmpcfg register specified in x28.
    # then writes the final value of pmpcfgX to the output.
    li x7, 0x0
    bne x7, x28, write_pmpcfg_2
    csrw pmpcfg0, x29
    csrr x30, pmpcfg0
write_pmpcfg_2:
    li x7, 0x2
    bne x7, x28, write_pmpcfg_end
    csrw pmpcfg2, x29
    csrr x30, pmpcfg2 # I would use csrrw but we need the value AFTER the csr has been written
write_pmpcfg_end:
    sd x30, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
    j test_loop

write_pmpaddr_0:
    # writes the value in x29 to the pmpaddr register specified in x28.
    # then writes the final value of pmpaddrX to the output.
    li x7, 0x0
    bne x7, x28, write_pmpaddr_1
    csrw pmpaddr0, x29
    csrr x30, pmpaddr0
    j write_pmpaddr_end
write_pmpaddr_1:
    li x7, 0x1
    bne x7, x28, write_pmpaddr_2
    csrw pmpaddr1, x29
    csrr x30, pmpaddr1
    j write_pmpaddr_end
write_pmpaddr_2:
    li x7, 0x2
    bne x7, x28, write_pmpaddr_3
    csrw pmpaddr2, x29
    csrr x30, pmpaddr2
    j write_pmpaddr_end
write_pmpaddr_3:
    li x7, 0x3
    bne x7, x28, write_pmpaddr_4
    csrw pmpaddr3, x29
    csrr x30, pmpaddr3
    j write_pmpaddr_end
write_pmpaddr_4:
    li x7, 0x4
    bne x7, x28, write_pmpaddr_5
    csrw pmpaddr4, x29
    csrr x30, pmpaddr4
    j write_pmpaddr_end
write_pmpaddr_5:
    li x7, 0x5
    bne x7, x28, write_pmpaddr_6
    csrw pmpaddr5, x29
    csrr x30, pmpaddr5
    j write_pmpaddr_end
write_pmpaddr_6:
    li x7, 0x6
    bne x7, x28, write_pmpaddr_7
    csrw pmpaddr6, x29
    csrr x30, pmpaddr6
    j write_pmpaddr_end
write_pmpaddr_7:
    li x7, 0x7
    bne x7, x28, write_pmpaddr_8
    csrw pmpaddr7, x29
    csrr x30, pmpaddr7
    j write_pmpaddr_end
write_pmpaddr_8:
    li x7, 0x8
    bne x7, x28, write_pmpaddr_9
    csrw pmpaddr8, x29
    csrr x30, pmpaddr8
    j write_pmpaddr_end
write_pmpaddr_9:
    li x7, 0x9
    bne x7, x28, write_pmpaddr_10
    csrw pmpaddr9, x29
    csrr x30, pmpaddr9
    j write_pmpaddr_end
write_pmpaddr_10:
    li x7, 0xA
    bne x7, x28, write_pmpaddr_11
    csrw pmpaddr10, x29
    csrr x30, pmpaddr10
    j write_pmpaddr_end
write_pmpaddr_11:
    li x7, 0xB
    bne x7, x28, write_pmpaddr_12
    csrw pmpaddr11, x29
    csrr x30, pmpaddr11
    j write_pmpaddr_end
write_pmpaddr_12:
    li x7, 0xC
    bne x7, x28, write_pmpaddr_13
    csrw pmpaddr12, x29
    csrr x30, pmpaddr12
    j write_pmpaddr_end
write_pmpaddr_13:
    li x7, 0xD
    bne x7, x28, write_pmpaddr_14
    csrw pmpaddr13, x29
    csrr x30, pmpaddr13
    j write_pmpaddr_end
write_pmpaddr_14:
    li x7, 0xE
    bne x7, x28, write_pmpaddr_15
    csrw pmpaddr14, x29
    csrr x30, pmpaddr14
    j write_pmpaddr_end
write_pmpaddr_15:
    li x7, 0xF
    bne x7, x28, write_pmpaddr_end
    csrw pmpaddr15, x29
    csrr x30, pmpaddr15
    j write_pmpaddr_end
write_pmpaddr_end:
    sd x30, 0(x6)
    addi x6, x6, 8
    addi x16, x16, 8
    j test_loop

executable_test:
    # Execute the code at the address in x28, returning the value in x7.
    # Assumes the code modifies x7, to become the value stored in x29 for this test.  
    fence.i # forces cache and main memory to sync so execution code written by the program can run.
    li x7, 0xBAD
    jalr x28 
    sd x7, 0(x6) 
    addi x6, x6, 8
    addi x16, x16, 8 
    j test_loop

terminate_test:

    li a0, 2 # Trap handler behavior (go to machine mode)
    ecall #  writes mcause to the output.
    csrw mtvec, x4  # restore original trap handler to halt program

/*
	# ---------------------------------------------------------------------------------------------

	RVTEST_IO_WRITE_STR(x31, "Test End\n")

	# ---------------------------------------------------------------------------------------------

	RV_COMPLIANCE_HALT

RV_COMPLIANCE_CODE_END

# Input data section.
	.data

.align 3 # align stack to 8 byte boundary
bottom_of_stack:
    .fill 1024, 4, -1 
top_of_stack:


# Output data section.
RV_COMPLIANCE_DATA_BEGIN

.align 3 # align output to 8 byte boundary
test_1_res:
    .fill 1024, 4, -1 

RV_COMPLIANCE_DATA_END


.align 3
test_cases:
*/

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0xbabecafe
RVTEST_DATA_END

.align 3 # align stack to 8 byte boundary
bottom_of_stack:
    .fill 1024, 4, -1 
top_of_stack:



RVMODEL_DATA_BEGIN

// next lines through test cases copied over from old framework
test_1_res:
    .fill 1024, 4, -1 

RVMODEL_DATA_END


/*
signature_x8_0:
    .fill 0*(XLEN/32),4,0xdeadbeef


signature_x8_1:
    .fill 19*(XLEN/32),4,0xdeadbeef


signature_x1_0:
    .fill 256*(XLEN/32),4,0xdeadbeef


signature_x1_1:
    .fill 256*(XLEN/32),4,0xdeadbeef


signature_x1_2:
    .fill 148*(XLEN/32),4,0xdeadbeef
*/

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef

#endif

.align 3
test_cases:


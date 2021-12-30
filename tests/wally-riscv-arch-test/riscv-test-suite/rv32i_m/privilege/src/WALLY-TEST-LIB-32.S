///////////////////////////////////////////
//
// WALLY-TEST-LIB-32.S
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2021-07-20
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
RVTEST_ISA("RV32I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

	# ---------------------------------------------------------------------------------------------


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
    #             Put it in the bottom bits of a1.
    #               
    #             Default : 0x0 (defaults to the next instruction in the same location as the return address)
    #             Megapage: returnAddr[END-1:22]  
    #             Kilopage: returnAddr[END-1:12] (this value also works for baremetal)
    #
    #   a2 (x12): Pagetype for change of return address after trap
    #             Put the Source page in a2[7:4] and Dest page in a2[3:0]
    #               Ex: giga -> mega a2=0x21
    #
    #             Default : Ignored if a1 == 0x0
    #             Megapage: 1  
    #             Kilopage: 0
    #     
    # --------------------------------------------------------------------------------------------


machine_trap_handler:
    # The processor is always in machine mode when a trap takes us here
    # save registers on stack before using
    sw x1, -4(sp)       
    sw x5, -8(sp)      

    # Record trap
    csrr x1, mcause     # record the mcause
    sw x1, 0(x16)        
    addi x6, x6, 4     
    addi x16, x16, 4    # update pointers for logging results

    # Respond to trap based on cause
    # All interrupts should return after being logged
    li x5, 0x8000000000000000   # if msb is set, it is an interrupt
    and x5, x5, x1
    bnez x5, trapreturn   # return from interrupt
    # Other trap handling is specified in the vector Table
    slli x1, x1, 2      # multiply cause by 4 to get offset in vector Table
    la x5, trap_handler_vector_table
    add x5, x5, x1      # compute address of vector in Table
    lw x5, 0(x5)        # fectch address of handler from vector Table
    jr x5               # and jump to the handler
    
segfault:
    lw x5, -8(sp)      # restore registers from stack before faulting
    lw x1, -4(sp)       
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
    # update mepc and stack (x1 and x5) to have new virtual addresses.
    beqz a1, trapreturn_finished # either update values, of go to default return address.

    # Get Mask Bits
    la x5, trap_return_pagetype_table
    mv x7, a2
    li x28, 0xF0 # mask bits for current pagetype 
    and x7, x28, x7
    srli x7, x7, 2
    add x5, x5, x7
    lw x7, 0(x5) # x7 = number of offset bits in current page type

    la x5, trap_return_pagetype_table
    li x28, 0xF # mask bits for new pagetype
    and a2, x28, a2
    slli a2, a2, 2
    add x5, x5, a2
    lw a2, 0(x5) # a2 = number of offset bits in new page type
    
    li x5, 1
    sll x5, x5, x7
    addi x5, x5, -1 # x5 = mask bits for offset into current pagetype

    sll a1, a1, a2 # a1 = the VPN of the new return page.

    # set x1 stack spot
    lw x7, -4(sp)
    and x7, x5, x7 # x7 = offset for x1
    add x7, x7, a1 # x7 = new address for x1
    sw x7, -4(sp)

    # set x5 stack spot
    lw x7, -8(sp)
    and x7, x5, x7 # x7 = offset for x5
    add x7, x7, a1 # x7 = new address for x5
    sw x7, -8(sp)

    # set x6
    and x7, x5, x6 # x7 = offset for the result pointer (x6)
    add x6, x7, a1 # x6 = new address for the result pointer
    
    # set return address
    and x1, x5, x1 # x1 = offset for the return address
    add x1, x1, a1 # x1 = new return address.

    li a1, 0 
    li a2, 0 # reset inputs

trapreturn_finished:
    csrw mepc, x1   # update the mepc with address of next instruction
    lw x5, -8(sp)   # restore registers from stack before returning
    lw x1, -4(sp)
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
    lw x1, -4(sp) # load return address int x1 (the address after the jal into faulting page)
    j trapreturn_finished # puts x1 into mepc, restores stack and returns to program (outside of faulting page)

accessfault:
    # *** What do I have to do here?
    j trapreturn
    # Table of trap behavior
    # lists what to do on each exception (not interrupts)
    # unexpected exceptions should cause segfaults for easy detection
    # Expected exceptions should increment the EPC to the next instruction and return

    .align 2 # aligns this data table to an 4 byte boundary
trap_handler_vector_table:
    .4byte segfault      # 0: instruction address misaligned
    .4byte instrfault      # 1: instruction access fault
    .4byte segfault      # 2: illegal instruction
    .4byte segfault      # 3: breakpoint
    .4byte segfault      # 4: load address misaligned
    .4byte accessfault      # 5: load access fault
    .4byte segfault      # 6: store address misaligned
    .4byte accessfault      # 7: store access fault
    .4byte ecallhandler  # 8: ecall from U-mode
    .4byte ecallhandler  # 9: ecall from S-mode
    .4byte segfault      # 10: reserved
    .4byte ecallhandler  # 11: ecall from M-mode
    .4byte instrfault    # 12: instruction page fault
    .4byte trapreturn    # 13: load page fault
    .4byte segfault      # 14: reserved
    .4byte trapreturn    # 15: store page fault

.align 2
trap_return_pagetype_table:
    .4byte 0xC  # 0: kilopage has 12 offset bits
    .4byte 0x16 # 1: megapage has 22 offset bits

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
    lw x28, 0(x5) # fetch test case address
    lw x29, 4(x5) # fetch test case value
    lw x30, 8(x5) # fetch test case flag
    addi x5, x5, 12 # set x5 to next test case

    # case statements for which test behavior to perform. 
    # *** We would use the same table method as the test types and trap handler,
    #     but that presents problems with virtual addressing and updating the address after the la command

                                    #   x30 Value : Function                              : Fault output value     : Normal output values
                                    #   ----------:---------------------------------------:------------------------:------------------------------------------------------
    li x7, 0x0                      #             :                                       :                        : 
    beq x30, x7, write_test         #         0x0 : Write to address                      : 0xf                    : None
    li x7, 0x1                      #             :                                       :                        :
    beq x30, x7, read_test          #         0x1 : Read from address                     : 0xd, 0xbad             : readvalue in hex
    li x7, 0xB                      #             :                                       :                        :
    beq x30, x7, access_test        #         0xB : Mem access at any width (see table)   : 0x1, 0x5, or 0x7       : 0x32001608, 0x32001608, 0x1608, 0x08, // *** Execute, cahceable, etc values
    li x7, 0xC                      #             :                                       :                        :
    beq x30, x7, access_denied_test #         0xC : Access memory regions with no device  : 0x7, 0x5, 0x1, 0x600d  : 0xbad, 0x3
    li x7, 0x2                      #             :                                       :                        :
    beq x30, x7, executable_test    #         0x2 : test executable at address            : 0xc, 0xbad             : leading 12 bits of the li instr written to address. (be sure to also write a return instruction)
    li x7, 0x3                      #             :                                       :                        :
    beq x30, x7, terminate_test     #         0x3 : terminate tests                       : mcause value for fault : from M 0xb, from S 0x9, from U 0x8  
    li x7, 0xF                      #             :                                       :                        :
    beq x30, x7, edit_pte           #         0xF : edit an already instantiated pte      : None                   : None
    li x7, 0x10                     #             :                                       :                        :
    beq x30, x7, push_to_stack      #        0x10 : put a value onto the top of the stack : None                   : None
    li x7, 0x4                      #             :                                       :                        :
    beq x30, x7, goto_baremetal     #         0x4 : satp.MODE = bare metal                : None                   : None 
    li x7, 0x5                      #             :                                       :                        :
    beq x30, x7, goto_sv32          #         0x5 : satp.MODE = sv32                      : None                   : None
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

write_test:
    # address to write in x28, value in x29
    sw x29, 0(x28)
    j test_loop # go to next test case

read_test:
    # address to read in x28, expected value in x29 (unused, but there for your perusal).
    li x7, 0xBAD # bad value that will be overwritten on good reads.
    lw x7, 0(x28)
    sw x7, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop # go to next test case

goto_s_mode:
    li a0, 3 # Trap handler behavior (go to machine mode)
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
    slli x7, x7, 31
    li x28, 0x8000D # Base Pagetable physical page number, satp.PPN field.
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 # *** flushes global pte's as well. Be careful
    j test_loop # go to next test case

goto_sv32:
    li x7, 1 # satp.MODE value for Sv39 (1)
    slli x7, x7, 31
    li x28, 0x8000D # Base Pagetable physical page number, satp.PPN field.
    add x7, x7, x28
    csrw satp, x7
    sfence.vma x0, x0 # *** flushes global pte's as well. Be careful
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
    li x7, 0x0
    bne x7, x28, write_pmpcfg_1
    csrw pmpcfg0, x29
    csrr x30, pmpcfg0
write_pmpcfg_1:
    li x7, 0x1
    bne x7, x28, write_pmpcfg_2
    csrw pmpcfg1, x29
    csrr x30, pmpcfg1 
write_pmpcfg_2:
    li x7, 0x2
    bne x7, x28, write_pmpcfg_3
    csrw pmpcfg2, x29
    csrr x30, pmpcfg2
write_pmpcfg_3:
    li x7, 0x3
    bne x7, x28, write_pmpcfg_end
    csrw pmpcfg3, x29
    csrr x30, pmpcfg3
write_pmpcfg_end:
    sw x30, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop

write_pmpaddr_0:
    # writes the value in x29 to the pmpaddr register specified in x28.
    li x7, 0x0
    bne x7, x28, write_pmpaddr_1
    csrw pmpaddr0, x29
write_pmpaddr_1:
    li x7, 0x1
    bne x7, x28, write_pmpaddr_2
    csrw pmpaddr1, x29
write_pmpaddr_2:
    li x7, 0x2
    bne x7, x28, write_pmpaddr_3
    csrw pmpaddr2, x29
write_pmpaddr_3:
    li x7, 0x3
    bne x7, x28, write_pmpaddr_4
    csrw pmpaddr3, x29
write_pmpaddr_4:
    li x7, 0x4
    bne x7, x28, write_pmpaddr_5
    csrw pmpaddr4, x29
write_pmpaddr_5:
    li x7, 0x5
    bne x7, x28, write_pmpaddr_6
    csrw pmpaddr5, x29
write_pmpaddr_6:
    li x7, 0x6
    bne x7, x28, write_pmpaddr_7
    csrw pmpaddr6, x29
write_pmpaddr_7:
    li x7, 0x7
    bne x7, x28, write_pmpaddr_8
    csrw pmpaddr7, x29
write_pmpaddr_8:
    li x7, 0x8
    bne x7, x28, write_pmpaddr_9
    csrw pmpaddr8, x29
write_pmpaddr_9:
    li x7, 0x9
    bne x7, x28, write_pmpaddr_10
    csrw pmpaddr9, x29
write_pmpaddr_10:
    li x7, 0xA
    bne x7, x28, write_pmpaddr_11
    csrw pmpaddr10, x29
write_pmpaddr_11:
    li x7, 0xB
    bne x7, x28, write_pmpaddr_12
    csrw pmpaddr11, x29
write_pmpaddr_12:
    li x7, 0xC
    bne x7, x28, write_pmpaddr_13
    csrw pmpaddr12, x29
write_pmpaddr_13:
    li x7, 0xD
    bne x7, x28, write_pmpaddr_14
    csrw pmpaddr13, x29
write_pmpaddr_14:
    li x7, 0xE
    bne x7, x28, write_pmpaddr_15
    csrw pmpaddr14, x29
write_pmpaddr_15:
    li x7, 0xF
    bne x7, x28, write_pmpaddr_end
    csrw pmpaddr15, x29
write_pmpaddr_end:
    j test_loop

executable_test:
    # using a virtual page number in x28, and the page type in x29, test execution on that virtual page  
    # note: that x28 page must point to program and data memory
    #       Another unfortunate case of not being able to use a little table like above, again because of the virtual addressing problem
    
    li x7, 0x0
    beq x7, x29, exe_kilopage
    li x7, 0x1
    beq x7, x29, exe_megapage
    li x7, 0xF
    beq x7, x29, exe_physical

exe_kilopage:    
    li x7, 0xFFFFF000
    and x28, x28, x7 # x28 = virtual page number
    li x29, 0xFFF
    j exe_combine_and_test

exe_megapage:    
    li x7, 0xFFE00000
    and x28, x28, x7 # x28 = virtual page number
    li x29, 0x1FFFFF
    j exe_combine_and_test

exe_combine_and_test: # at this point x28 is the VPN and x29 physical offset mask bits
    la x7, exe_code
    and x7, x7, x29
    or x28, x28, x7 # x28 = full virtual address for executable_code

exe_physical:
    li x7, 0xBAD # load a bad value into x7 in case this fetch doesnt work.
    jalr x28 # jump to executable code virtual address
    sw x7, 0(x6)
    addi x6, x6, 4
    addi x16, x16, 4
    j test_loop

exe_code:
    li x7, 0xE600D
    ret #jumps back to the original virtual PC and continues with this program.

access_test:
    # test write, read, and *** Execute permissions on the region of memory beginning at the address in x28
    

    # Load output: (None) if pass, (0x7) if fail
    # Store output: (0x600DXX) if pass, (0x5, 0xBAD) if fail
    # execute output: *** N/A
    # *** idempotent, atomic, etc...  
    
    # *** unfortunately, there's no guarantee that this write will work since the access width applies to writes and reads
    #           So I'm sorry, but I'm going to have to do loads and stores at all widths. its either that or have a test for every width
    li x7, 0x32001608
    sw x7, 0(x28) # test 32 bit write
    sh x7, 4(x28) # test 16 bit write
    sb x7, 12(x28) # test 8 bit write

    # *** Double unfortunately, there are cases where we aren't allowed to write a known value to the range of addresses
    # so instead I have to do all this work to check if ANY value get read out of memory, but I can't verfy the value in the output necessarily.
    li x7, 0xBAD
access_32:
    li x29, 0xBAD
    lw x29, 0(x28)
    beq x29, x7, access_16 
    li x29, 0x600D32
access_16:
    sw x29, 0(x6)

    li x29, 0xBAD
    lh x29, 4(x28)
    beq x29, x7, access_08 
    li x29, 0x600D16
access_08:
    sw x29, 4(x6)

    li x29, 0xBAD
    lb x29, 8(x28)
    beq x29, x7, access_end 
    li x29, 0x600D08
access_end:
    sw x29, 8(x6)

    /* *** EXECUTE, idempotent atomic, etc tests. how do we do it? */

    addi x6, x6, 12
    addi x16, x16, 12
    j test_loop

access_denied_test:
    # check that lw, sw and jalr all cause faults in a memory region (beginning at x28 address) where no device is intantiated.
    lw x7, 0(x28) # cause a load access fault

    li x7, 0xBADBAD // *** Necessary?
    sw x7, 0(x28) # cause a store access fault
    jalr x7, 0(x28) # cause an instruction access fault 
    j test_loop

edit_pte:
    # write the PTE (value in x29) to address x28. This is different from a normal write since it includes an sfence.vma
    sw x29, 0(x28)
    lw x30, 0(sp) # the sfence.vma requires a virtual address within the page, it needs to be loaded into the stack.
    addi sp, sp, 4 # put the stack pointer one value down, effectively popping this value by allowing it to be overwritten.
    sfence.vma x0, x30
    j test_loop

push_to_stack:
    # write the value in x29 to the stack address pointed to by sp. update sp.
    # this for those handy times when address, value, test type isn't enough info and you need more so you put it on the stack.
    # any test that uses this info is also respnsible for removing the value or moving the stack pointer back.
    sw x29, -4(sp)
    addi sp, sp, -4
    j test_loop

terminate_test:

    li a0, 2 # Trap handler behavior (go to machine mode)
    ecall #  writes mcause to the output.
    csrw mtvec, x4  # restore original trap handler to halt program


RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0xbabecafe
RVTEST_DATA_END

.align 2 # align stack to 4 byte boundary
bottom_of_stack:
    .fill 1024, 4, -1 
top_of_stack:



RVMODEL_DATA_BEGIN

// next lines through test cases copied over from old framework
test_1_res:
    .fill 1024, 4, -1 

RVMODEL_DATA_END

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef

#endif

.align 2
test_cases:


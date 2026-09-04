///////////////////////////////////////////
//
// WALLY-TEST-LIB.h
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

#include "WALLY-env.h"

// ---------------------------------------------------------------------------------------------
// Self-checking
//
//   Each test embeds its expected signature as a table of XLEN-bit values between the labels
//   expected_signature and expected_signature_end.  s11 walks that table in lockstep with the
//   signature pointers (t1/a6).  SIG_NEXT is invoked after every signature write: it compares the
//   entry just written at 0(a6) against the expected value at 0(s11), and on a mismatch jumps to
//   selfcheck_fail, which records the entry index, address, expected and actual values in
//   selfcheck_record and halts.  terminate_test also confirms that exactly the expected number of
//   entries were written.  s9, s10, and s11 are reserved for this purpose.
//
//   selfcheck_record layout (XLEN-bit entries):
//      0: status: 0 = test did not finish, 1 = passed, 2 = entry mismatch, 3 = wrong number of entries
//      1: index of the failing entry (or number of entries written)
//      2: address of the failing entry
//      3: expected value (or number of entries expected)
//      4: actual value (or number of entries written)
// ---------------------------------------------------------------------------------------------

.macro SIG_NEXT
    LREG s9, 0(a6)                // value just written to the signature
    LREG s10, 0(s11)              // expected value
    beq s9, s10, 1f
    j selfcheck_fail
1:
    addi s11, s11, REGBYTES
    addi t1, t1, REGBYTES
    addi a6, a6, REGBYTES
.endm

.macro INIT_TESTS


.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:

    // ---------------------------------------------------------------------------------------------
    // Initialization Overview:
    //
    //   Initialize t1 as a virtual pointer to the test results
    //   Initialize a6 as a physical pointer to the test results
    //   Set up stack pointer, mscratch, sscratch
    //
    // ---------------------------------------------------------------------------------------------

    // address for test results
    la t1, test_1_res
    la a6, test_1_res // a6 reserved for the physical address equivalent of t1 to be used in trap handlers
                        // any time either is used, both must be updated.
    la s11, expected_signature // s11 walks the table of expected signature values

    // address for normal user stack, mscratch stack, and sscratch stack
    la sp, mscratch_top
    csrw mscratch, sp
    la sp, sscratch_top
    csrw sscratch, sp
    la sp, stack_top

    // set up PMP so user and supervisor mode can access full address space
    csrw pmpcfg0, 0xF   # configure PMP0 to TOR RWX
    li t0, 0xFFFFFFFF
    csrw pmpaddr0, t0   # configure PMP0 top of range to 0xFFFFFFFF to allow all addresses used by the tests


.endm

.macro TRAP_HANDLER MODE, VECTORED=1, EXT_SIGNATURE=0
    // MODE decides which mode this trap handler will be taken in (M or S mode)
    // Vectored decides whether interrupts are handled with the vector table at trap_handler_MODE (1)
    //      vs Using the non-vector approach the rest of the trap handler takes (0)
    // EXT_SIGNATURE decides whether we will print mtval a string with status.mpie, status.mie, and status.mpp to the signature (1)
    //      vs not saving that info to the signature (0)


    //   Set up the exception Handler, keeping the original handler in tp.
    la ra, trap_handler_\MODE\()
    ori ra, ra, \VECTORED // set mode field of tvec to VECTORED, which will force vectored interrupts if it's 1.

.if (\MODE\() == m)
    csrrw tp, \MODE\()tvec, ra  // tp reserved for "default" trap handler address that needs to be restored before halting this test.
.else
    csrw \MODE\()tvec, ra // we only need save the machine trap handler and this if statement ensures it isn't overwritten
.endif

    li a0, 0 // reset trap handler input to zero

    la t4, 0x02004000    // MTIMECMP register in CLINT
    li t5, 0xFFFFFFFF
    SREG t5, 0(t4) // set mtimecmp to 0xFFFFFFFF to really make sure time interrupts don't go off immediately after being enabled

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
    // --------------------------------------------------------------------------------------------


.align 6
trap_handler_\MODE\():
    j trap_unvectored_\MODE\() // for the unvectored implementation: jump past this table of addresses into the actual handler
    // ASSUMES that a cause value of 0 for an interrupt is unimplemented
    // otherwise, a vectored interrupt handler should jump to trap_handler_\MODE\() + 4 * Interrupt cause code
    // No matter the value of VECTORED, exceptions (not interrupts) are handled in an unvecotred way
    j s_soft_vector_\MODE\()    // 1: instruction access fault // the zero spot is taken up by the instruction to skip this table.
    j segfault_\MODE\()
    j m_soft_vector_\MODE\()
    j segfault_\MODE\()
    j s_time_vector_\MODE\()
    j segfault_\MODE\()
    j m_time_vector_\MODE\()
    j segfault_\MODE\()
    j s_ext_vector_\MODE\()
    j segfault_\MODE\()
    j m_ext_vector_\MODE\()
    // 12 through >=16 are reserved or designated for platform use

trap_unvectored_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap handler without messing up sp's value or the stack itself.
    // NOTE: this means that nested traps will be screwed up but they shouldn't happen in any of these tests

trap_stack_saved_\MODE\(): // jump here after handling vectored interrupt since we already switch sp and scratch there
    // save registers on stack before using
    SREG ra, -REGBYTES(sp)
    SREG t0, -(2*REGBYTES)(sp)
    SREG t2, -(3*REGBYTES)(sp)

    // Record trap
    csrr ra, \MODE\()cause     // record the mcause
    SREG ra, 0(a6)
    SIG_NEXT          // update pointers for logging results

.if (\EXT_SIGNATURE\() == 1) // record extra information (MTVAL, some status bits) about traps
    csrr ra, \MODE\()tval
    SREG ra, 0(a6)
    SIG_NEXT

    csrr ra, \MODE\()status
    .if (\MODE\() == m) // Taking traps in different modes means we want to get different bits from the status register.
        li t0, 0x1888 // mask bits to select MPP, MPIE, and MIE.
    .else
        li t0, 0x122 // mask bits to select SPP, SPIE, and SIE.
    .endif
    and t0, t0, ra
    SREG t0, 0(a6) // store masked out status bits to the output
    SIG_NEXT

.endif

    // Respond to trap based on cause
    // All interrupts should return after being logged
    csrr ra, \MODE\()cause
    bltz ra, interrupt_handler_\MODE\() // if msb is set, it is an interrupt
    // Other trap handling is specified in the vector Table
    la t0, exception_vector_table_\MODE\()
    slli ra, ra, REGSHIFT   // multiply cause by REGBYTES to get offset in vector Table
    add t0, t0, ra      // compute address of vector in Table
    LREG t0, 0(t0)      // fetch address of handler from vector Table
    jr t0               // and jump to the handler

interrupt_handler_\MODE\():
    la t0, interrupt_vector_table_\MODE\() // NOTE THIS IS NOT THE SAME AS VECTORED INTERRUPTS!!!
    slli ra, ra, REGSHIFT   // multiply cause by REGBYTES to get offset in vector Table
    add t0, t0, ra      // compute address of vector in Table
    LREG t0, 0(t0)      // fetch address of handler from vector Table
    jr t0               // and jump to the handler

segfault_\MODE\():
    LREG t2, -(3*REGBYTES)(sp)  // restore registers from stack before faulting
    LREG t0, -(2*REGBYTES)(sp)
    LREG ra, -REGBYTES(sp)
    j terminate_test          // halt program.

trapreturn_\MODE\():
    csrr ra, \MODE\()epc       // get the mepc
    addi ra, ra, 4


trapreturn_finished_\MODE\():
    csrw \MODE\()epc, ra   // update the mepc with address of next instruction
    LREG t2, -(3*REGBYTES)(sp)  // restore registers from stack before returning
    LREG t0, -(2*REGBYTES)(sp)
    LREG ra, -REGBYTES(sp)
    csrrw sp, \MODE\()scratch, sp // switch sp and scratch stack back to restore the non-trap stack pointer
    \MODE\()ret  // return from trap

// specific exception handlers

ecallhandler_\MODE\():
    // Check input parameter a0. encoding above.
    li t0, 2            // case 2: change to machine mode
    beq a0, t0, ecallhandler_changetomachinemode_\MODE\()
    li t0, 3            // case 3: change to supervisor mode
    beq a0, t0, ecallhandler_changetosupervisormode_\MODE\()
    li t0, 4            // case 4: change to user mode
    beq a0, t0, ecallhandler_changetousermode_\MODE\()
    // unsupported ecalls should segfault
    j segfault_\MODE\()

ecallhandler_changetomachinemode_\MODE\():
    // Force status.MPP (bits 12:11) to 11 to enter machine mode after mret
    // note that it is impossible to return to M mode after a trap delegated to S mode
    li ra, 0b1100000000000
    csrs \MODE\()status, ra
    j trapreturn_\MODE\()

ecallhandler_changetosupervisormode_\MODE\():
    // Force status.MPP (bits 12:11) and status.SPP (bit 8) to 01 to enter supervisor mode after (m/s)ret
    li ra, 0b1000000000000
    csrc \MODE\()status, ra
    li ra, 0b0100100000000
    csrs \MODE\()status, ra
    j trapreturn_\MODE\()

ecallhandler_changetousermode_\MODE\():
    // Force status.MPP (bits 12:11) and status.SPP (bit 8) to 00 to enter user mode after (m/s)ret
    li ra, 0b1100100000000
    csrc \MODE\()status, ra
    j trapreturn_\MODE\()

instrpagefault_\MODE\():
    LREG ra, -REGBYTES(sp) // load return address into ra (the address AFTER the jal into faulting page)
    j trapreturn_finished_\MODE\() // puts ra into mepc, restores stack and returns to program (outside of faulting page)

instrfault_\MODE\():
    LREG ra, -REGBYTES(sp) // load return address into ra (the address AFTER the jal to the faulting address)
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
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap handler without messing up sp's value or the stack itself.
    SREG t0, -REGBYTES(sp) // put t0 on the scratch stack before messing with it
    li t0, 0x7EC01 // write 0x7ec01 (for "VEC"tored and 01 for the interrupt code)
    j vectored_int_end_\MODE\()

m_soft_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap handler without messing up sp's value or the stack itself.
    SREG t0, -REGBYTES(sp) // put t0 on the scratch stack before messing with it
    li t0, 0x7EC03 // write 0x7ec03 (for "VEC"tored and 03 for the interrupt code)
    j vectored_int_end_\MODE\()

s_time_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap handler without messing up sp's value or the stack itself.
    SREG t0, -REGBYTES(sp) // put t0 on the scratch stack before messing with it
    li t0, 0x7EC05 // write 0x7ec05 (for "VEC"tored and 05 for the interrupt code)
    j vectored_int_end_\MODE\()

m_time_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap handler without messing up sp's value or the stack itself.
    SREG t0, -REGBYTES(sp) // put t0 on the scratch stack before messing with it
    li t0, 0x7EC07 // write 0x7ec07 (for "VEC"tored and 07 for the interrupt code)
    j vectored_int_end_\MODE\()

s_ext_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap handler without messing up sp's value or the stack itself.
    SREG t0, -REGBYTES(sp) // put t0 on the scratch stack before messing with it
    li t0, 0x7EC09 // write 0x7ec09 (for "VEC"tored and 08 for the interrupt code)
    j vectored_int_end_\MODE\()

m_ext_vector_\MODE\():
    csrrw sp, \MODE\()scratch, sp // swap sp and scratch so we can use the scratch stack in the trap handler without messing up sp's value or the stack itself.
    SREG t0, -REGBYTES(sp) // put t0 on the scratch stack before messing with it
    li t0, 0x7EC0B // write 0x7ec0B (for "VEC"tored and 0B for the interrupt code)
    j vectored_int_end_\MODE\()

vectored_int_end_\MODE\():
    SREG t0, 0(a6) // store to signature to show vectored interrupts succeeded.
    SIG_NEXT
    LREG t0, -REGBYTES(sp) // restore t0 before continuing to handle trap in case its needed.
    j trap_stack_saved_\MODE\()

// specific interrupt handlers

soft_interrupt_\MODE\():
    la t0, 0x02000000 // Reset by clearing MSIP interrupt from CLINT
    sw zero, 0(t0)

    csrci \MODE\()ip, 0x2 // clear supervisor software interrupt pending bit
    LREG ra, -REGBYTES(sp) // load return address from stack into ra (the address to return to after causing this interrupt)
    // Note: we do this because the mepc loads in the address of the instruction after the sw that causes the interrupt
    //  This means that this trap handler will return to the next address after that one, which might be unpredictable behavior.
    j trapreturn_finished_\MODE\() // return to the code at ra value from before trap

time_interrupt_\MODE\():
    la t0, 0x02004000    // MTIMECMP register in CLINT
    li t2, 0xFFFFFFFF
    SREG t2, 0(t0) // reset interrupt by setting mtimecmp to max
    csrw stimecmp, t2 // reset stime interrupts by doing the same to stimecmp (and stimecmph on RV32)
#if __riscv_xlen == 32
    csrw stimecmph, t2
#endif


    li t0, 0x20
    csrc \MODE\()ip, t0
    LREG ra, -REGBYTES(sp) // load return address from stack into ra (the address to return to after the loop is complete)
    j trapreturn_finished_\MODE\() // return to the code at ra value from before trap

ext_interrupt_\MODE\():
    li t3, 0x10060000 // reset interrupt by clearing all the GPIO bits
    sw zero, 8(t3) // disable the first pin as an output
    sw zero, 40(t3) // write a 0 to the first output pin (reset interrupt)

    // reset PLIC to turn off external interrupts
    // m priority threshold = 7
    li t3, 0xC200000
    li t0, 0x7
    sw t0, 0(t3)
    // s priority threshold = 7
    li t3, 0xC201000
    li t0, 0x7
    sw t0, 0(t3)
    // source 3 (GPIO) priority = 0
    li t3, 0xC000000
    li t0, 0
    sw t0, 0x0C(t3)
    // disable source 3 in M mode
    li t3, 0x0C002000
    li t0, 0b0000
    sw t0, 0(t3)
    // enable source 3 in S mode
    li t3, 0x0C002080
    li t4, 0b0000
    sw t4, 0(t3)

    li t0, 0x200
    csrc \MODE\()ip, t0

    LREG ra, -REGBYTES(sp) // load return address from stack into ra (the address to return to after the loop is complete)
    j trapreturn_finished_\MODE\() // return to the code at ra value from before trap


    // Table of trap behavior
    // lists what to do on each exception (not interrupts)
    // unexpected exceptions should cause segfaults for easy detection
    // Expected exceptions should increment the EPC to the next instruction and return
.data
    .align REGSHIFT // aligns this data table to an XLEN-bit boundary
exception_vector_table_\MODE\():
    WORD addr_misaligned_\MODE\()      // 0: instruction address misaligned
    WORD instrfault_\MODE\()    // 1: instruction access fault
    WORD illegalinstr_\MODE\()  // 2: illegal instruction
    WORD breakpt_\MODE\()      // 3: breakpoint
    WORD addr_misaligned_\MODE\()      // 4: load address misaligned
    WORD accessfault_\MODE\()   // 5: load access fault
    WORD addr_misaligned_\MODE\()      // 6: store address misaligned
    WORD accessfault_\MODE\()   // 7: store access fault
    WORD ecallhandler_\MODE\()  // 8: ecall from U-mode
    WORD ecallhandler_\MODE\()  // 9: ecall from S-mode
    WORD segfault_\MODE\()      // 10: reserved
    WORD ecallhandler_\MODE\()  // 11: ecall from M-mode
    WORD instrpagefault_\MODE\()    // 12: instruction page fault
    WORD trapreturn_\MODE\()    // 13: load page fault
    WORD segfault_\MODE\()      // 14: reserved
    WORD trapreturn_\MODE\()    // 15: store page fault

    .align REGSHIFT // aligns this data table to an XLEN-bit boundary
interrupt_vector_table_\MODE\():
    WORD segfault_\MODE\()            // 0: reserved
    WORD soft_interrupt_\MODE\()    // 1: instruction access fault // the zero spot is taken up by the instruction to skip this table.
    WORD segfault_\MODE\()            // 2: reserved
    WORD soft_interrupt_\MODE\()    // 3: breakpoint
    WORD segfault_\MODE\()            // 4: reserved
    WORD time_interrupt_\MODE\()    // 5: load access fault
    WORD segfault_\MODE\()            // 6: reserved
    WORD time_interrupt_\MODE\()    // 7: store access fault
    WORD segfault_\MODE\()            // 8: reserved
    WORD ext_interrupt_\MODE\()     // 9: ecall from S-mode
    WORD segfault_\MODE\()            // 10: reserved
    WORD ext_interrupt_\MODE\()     // 11: ecall from M-mode



.section .text.init
trap_handler_end_\MODE\(): // place to jump to so we can skip the trap handler and continue with the test
.endm

.macro WRITE08 ADDR VAL
    li t4, \VAL
    li t5, \ADDR
    sb t4, 0(t5)
.endm




// These goto_x_mode tests all involve invoking the trap handler,
// So their outputs are inevitably:
//      0x8: test called from U mode
//      0x9: test called from S mode
//      0xB: test called from M mode
// they generally do not fault or cause issues as long as these modes are enabled




// These tests change virtual memory settings, turning it on/off and changing between types.
// They don't have outputs as any error with turning on virtual memory should reveal itself in the tests *** Consider changing this policy?






// Place this macro in peripheral tests to setup all the PLIC registers to generate external interrupts
.macro SETUP_PLIC
    # Setup PLIC with a series of register writes

    .equ PLIC_INTPRI_GPIO, 0x0C00000C       # GPIO is interrupt 3
    .equ PLIC_INTPRI_UART, 0x0C000028       # UART is interrupt 10
    .equ PLIC_INTPRI_SPI,  0x0C000018       # SPI is interrupt 6
    .equ PLIC_INTPENDING0, 0x0C001000       # intPending0 register
    .equ PLIC_INTEN00,     0x0C002000       # interrupt enables for context 0 (machine mode) sources 31:1
    .equ PLIC_INTEN10,     0x0C002080       # interrupt enables for context 1 (supervisor mode) sources 31:1
    .equ PLIC_THRESH0,     0x0C200000       # Priority threshold for context 0 (machine mode)
    .equ PLIC_CLAIM0,      0x0C200004       # Claim/Complete register for context 0
    .equ PLIC_THRESH1,     0x0C201000       # Priority threshold for context 1 (supervisor mode)
    .equ PLIC_CLAIM1,      0x0C201004       # Claim/Complete register for context 1

    WORD PLIC_THRESH0, 0, write32_test    # Set PLIC machine mode interrupt threshold to 0 to accept all interrupts
    WORD PLIC_THRESH1, 7, write32_test    # Set PLIC supervisor mode interrupt threshold to 7 to accept no interrupts
    WORD PLIC_INTPRI_GPIO, 7, write32_test # Set GPIO to high priority
    WORD PLIC_INTPRI_UART, 7, write32_test # Set UART to high priority
    WORD PLIC_INTPRI_SPI, 7, write32_test # Set SPI to high priority
    WORD PLIC_INTEN00, 0xFFFFFFFF, write32_test # Enable all interrupt sources for machine mode
    WORD PLIC_INTEN10, 0x00000000, write32_test # Disable all interrupt sources for supervisor mode
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
    // This test handler works in a similar way to the trap handler. It takes in a few things by reading from a table in memory
    // (see test_cases) and performing certain behavior based on them.
    //
    // Input parameters:
    //
    // t3:
    //     Address input for the test taking place (think: address to read/write, new address to return to, etc...)
    //
    // t4:
    //     Value input for the test taking place (think: value to write, any other extra info needed)
    //
    // t5:
    //     Label for the location of the test that's about to take place
    // ------------------------------------------------------------------------------------------------------------------------------------

.macro INIT_TEST_TABLE

run_test_loop:
    la t0, test_cases

test_loop:
    LREG t3, 0(t0)            // fetch test case address
    LREG t4, REGBYTES(t0)     // fetch test case value
    LREG t5, (2*REGBYTES)(t0) // fetch test case flag
    addi t0, t0, 3*REGBYTES   // set t0 to next test case

    jr t5

// Test types.  Each entry of the test table is (address, value, test type); t3 = address, t4 = value.
//
//   Test type              : Description                                        : Signature output
//   -----------------------:----------------------------------------------------:-----------------------------------------
//   write32_test           : write 32 bits (t4) to address t3                   : none
//   write08_test           : write 8 bits (t4) to address t3                    : none
//   read32_test            : read 32 bits from address t3                       : value read
//   read08_test            : read 8 bits from address t3                        : value read, sign extended
//   read04_test            : read 8 bits from address t3, keep the low nibble   : value read
//   readmip_test           : read mip                                           : mip
//   readsip_test           : read sip                                           : sip
//   claim_m_plic_interrupts: claim and complete a pending M-mode PLIC interrupt : claim ID
//   claim_s_plic_interrupts: claim and complete a pending S-mode PLIC interrupt : claim ID
//   uart_data_wait         : wait for UART data ready, servicing FIFO interrupts: {IIR, LSR & 0x9F}
//   uart_lsr_intr_wait     : wait for a UART line status interrupt              : IIR & 7
//   spi_data_wait          : wait for SPI receive watermark t4                  : none
//   spi_burst_send         : write the 4 bytes of t4 to SPI address t3          : none
//   goto_m_mode            : ecall into machine mode                            : mcause (0xb from M, 0x9 from S)
//   goto_s_mode            : ecall into supervisor mode                         : mcause (0xb from M, 0x9 from S)
//   write_mideleg          : write t4 to mideleg                                : none
//   terminate_test         : ecall into machine mode, then halt                 : mcause (0xb from M, 0x9 from S)
//
// A trap taken during any test type appends mcause (see TRAP_HANDLER) before the test type's own output.

write32_test:
    // address to write in t3, word value in t4
    sw t4, 0(t3)
    j test_loop // go to next test case

write08_test:
    // address to write in t3, value in t4
    sb t4, 0(t3)
    j test_loop // go to next test case

read32_test:
    // address to read in t3, expected 32 bit value in t4 (unused, but there for your perusal).
    li t2, 0xBAD // bad value that will be overwritten on good reads.
    lw t2, 0(t3)
    SREG t2, 0(t1)
    SIG_NEXT
    j test_loop // go to next test case

read08_test:
    // address to read in t3, expected 8 bit value in t4 (unused, but there for your perusal).
    li t2, 0xBAD // bad value that will be overwritten on good reads.
    lb t2, 0(t3)
    SREG t2, 0(t1)
    SIG_NEXT
    j test_loop // go to next test case

read04_test:
    // address to read in t3, expected 8 bit value in t4 (unused, but there for your perusal).
    li t2, 0xBAD // bad value that will be overwritten on good reads.
    lb t2, 0(t3)
    andi t2, t2, 15 // mask lower 4 bits
    SREG t2, 0(t1)
    SIG_NEXT
    j test_loop // go to next test case

readmip_test:  // read the MIP into the signature
    csrr t2, mip
    SREG t2, 0(t1)
    SIG_NEXT
    j test_loop // go to next test case

readsip_test:  // read the MIP into the signature
    csrr t2, sip
    SREG t2, 0(t1)
    SIG_NEXT
    j test_loop // go to next test case

claim_m_plic_interrupts: // clears one non-pending PLIC interrupt
    li t2, 0x0C00000C // GPIO priority
    li t3, 7
    lw t4, 0(t2)
    sw t3, 0(t2)
    sw t4, -4(sp)
    addi sp, sp, -4
    li t2, 0x0C000028 // UART priority
    li t3, 7
    lw t4, 0(t2)
    sw t3, 0(t2)
    sw t4, -4(sp)
    addi sp, sp, -4
    li t2, 0x0C000018 // SPI priority
    li t3, 7
    lw t4, 0(t2)
    sw t3, 0(t2)
    sw t4, -4(sp)
    addi sp, sp, -4
    li t2, 0x0C002000
    li t3, 0x0C200004
    li t4, 0xFFF
    lw t6, 0(t2) // save current enable status
    sw t4, 0(t2) // enable all relevant interrupts on PLIC
    lw t5, 0(t3) // make PLIC claim
    sw t5, 0(t3) // complete claim made
    sw t6, 0(t2) // restore saved enable status
    li t2, 0x0C00000C // GPIO priority
    lw t4, 8(sp) // restore stored GPIO priority
    sw t4, 0(t2)
    li t2, 0x0C000028 // UART priority
    lw t4, 4(sp) // restore stored UART priority
    sw t4, 0(t2)
    li t2, 0x0C000018 // SPI priority
    lw t4, 0(sp) // restore stored SPI priority
    sw t4, 0(t2)
    addi sp, sp, 12 // restore stack pointer
    j test_loop

claim_s_plic_interrupts: // clears one non-pending PLIC interrupt
    li t2, 0x0C00000C // GPIO priority
    li t3, 7
    lw t4, 0(t2)
    sw t3, 0(t2)
    sw t4, -4(sp)
    addi sp, sp, -4
    li t2, 0x0C000028 // UART priority
    li t3, 7
    lw t4, 0(t2)
    sw t3, 0(t2)
    sw t4, -4(sp)
    addi sp, sp, -4
    li t2, 0x0C002080
    li t3, 0x0C201004
    li t4, 0xFFF
    lw t6, 0(t2) // save current enable status
    sw t4, 0(t2) // enable all relevant interrupts on PLIC
    lw t5, 0(t3) // make PLIC claim
    sw t5, 0(t3) // complete claim made
    sw t6, 0(t2) // restore saved enable status
    li t2, 0x0C00000C // GPIO priority
    li t3, 0x0C000028 // UART priority
    lw t4, 4(sp) // load stored GPIO and UART priority
    lw t5, 0(sp)
    addi sp, sp, 8 // restore stack pointer
    sw t4, 0(t2)
    sw t5, 0(t3)
    j test_loop

uart_lsr_intr_wait: // waits for interrupts to be ready
    li t2, 0x10000002 // IIR
    li t4, 0x6
uart_lsr_intr_loop:
    lb t3, 0(t2)
    andi t3, t3, 0x7
    bne t3, t4, uart_lsr_intr_loop
uart_save_iir_status:
    SREG t3, 0(t1)
    SIG_NEXT
    j test_loop

uart_data_wait:
    li t2, 0x10000002
    lbu t3, 0(t2) // save IIR before reading LSR might clear it
    // Check IIR to see if theres an rxfifio or txempty interrupt and handle it before continuing.
    li t2, 0xCC // Value in IIR for Fifo Enabled, with timeout interrupt pending
    beq t3, t2, uart_rxfifo_timout
    li t2, 0xC2 // Value in IIR for Fifo Enabled, with txempty interrupt pending.
    beq t3, t2, uart_txempty_intr
    li t2, 0x10000005 // There needs to be an instruction here between the beq and the lb or the tests will hang
    lb t4, 0(t2) // read LSR
    li t2, 0x61
    bne t4, t2, uart_data_wait // wait until all transmissions are done and data is ready
    j uart_data_ready
uart_rxfifo_timout:
    li t2, 0x10000000 // read from the fifo to clear the rx timeout error
    lb t5, 0(t2)
    sb t5, 0(t2) // write back to the fifo to make sure we have the same data so expected future overrun errors still occur.
    j uart_data_wait
uart_txempty_intr:
    li t2, 0x10000002
    lb t5, 0(t2) // Read IIR to clear this bit in LSR
    j uart_data_wait

uart_data_ready:
    li t2, 0x10000002
    lbu t3, 0(t2) // re read IIR
    andi t4, t4, 0x9F // mask THRE and TEMT from IIR signature
    li t2, 0
    SREG t2, 0(t1) // clear entry deadbeef from memory
    sb t3, 1(t1) // IIR
    sb t4, 0(t1) // LSR
    SIG_NEXT
    j test_loop

spi_data_wait:
    li t2, 0x10040054
    sw t4, 0(t2) // set rx watermark level
    li t2, 0x10040074
    lw t3, 0(t2) //read ip (interrupt pending register)
    andi t3, t3, 0xF
    li t2, 0x00000002
    bge t3, t2, spi_data_ready //branch to done if transmission complete
    j spi_data_wait //else check again

spi_data_ready:
    li t2, 0x10040070
    li t3, 0x00000000
    sw t3, 0(t2) //disable rx watermark interrupt
    j test_loop

spi_burst_send: //function for loading multiple frames at once to test delays without returning to test loop
    mv t2, t4
    sw t2, 0(t3)
    srli t2, t2, 8
    sw t2, 0(t3)
    srli t2, t2, 8
    sw t2, 0(t3)
    srli t2, t2, 8
    sw t2, 0(t3)
    j test_loop

goto_s_mode:
    li a0, 3 // Trap handler behavior (go to supervisor mode)
    ecall // writes mcause to the output.
    // now in S mode
    j test_loop

goto_m_mode:
    li a0, 2 // Trap handler behavior (go to machine mode)
    ecall // writes mcause to the output.
    j test_loop

write_mideleg:
    // writes the value in t4 to the mideleg register
    // Doesn't log anything
    csrw mideleg, t4
    j test_loop

.endm

// notably, terminate_test is not a part of the test table macro because it needs to be defined
// in any type of test, macro or test table, for the trap handler to work
terminate_test:

    li a0, 2 // Trap handler behavior (go to machine mode)
    ecall //  writes mcause to the output.
    csrw mtvec, tp  // restore original trap handler to halt program

    la s9, expected_signature_end
    bne s11, s9, selfcheck_length_fail // fewer or more signature entries were written than expected
    la s9, selfcheck_record
    li s10, 1
    SREG s10, 0(s9)   // record that all signature entries matched

TEST_HALT

// Reached from SIG_NEXT when a signature entry does not match its expected value.
// s9 = actual value, s10 = expected value, a6 = address of the entry
selfcheck_fail:
    la t0, selfcheck_record
    li t2, 2
    SREG t2, 0(t0)      // status: entry mismatch
    la t2, test_1_res
    sub t2, a6, t2
    srli t2, t2, REGSHIFT      // index of the entry
    SREG t2, REGBYTES(t0)
    SREG a6, (2*REGBYTES)(t0)  // address of the entry
    SREG s10, (3*REGBYTES)(t0) // expected value
    SREG s9, (4*REGBYTES)(t0)  // actual value
    li x1, 1
    j write_tohost      // halt

// Reached from terminate_test when the number of signature entries written differs from the number expected.
// s9 = expected_signature_end, s11 = expected pointer, a6 = signature pointer
selfcheck_length_fail:
    la t0, selfcheck_record
    li t2, 3
    SREG t2, 0(t0)      // status: wrong number of entries
    la t2, test_1_res
    sub t2, a6, t2
    srli t2, t2, REGSHIFT      // number of entries written
    SREG t2, REGBYTES(t0)
    SREG a6, (2*REGBYTES)(t0)
    SREG t2, (4*REGBYTES)(t0)
    la t2, expected_signature
    sub t2, s9, t2
    srli t2, t2, REGSHIFT      // number of entries expected
    SREG t2, (3*REGBYTES)(t0)
    li x1, 1
    j write_tohost      // halt

.macro TEST_STACK_AND_DATA

.data

.align REGSHIFT // align stack to an XLEN-bit boundary
stack_bottom:
    .fill 1024, 4, 0xdeadbeef
stack_top:

.align REGSHIFT
mscratch_bottom:
    .fill 512, 4, 0xdeadbeef
mscratch_top:

.align REGSHIFT
sscratch_bottom:
    .fill 512, 4, 0xdeadbeef
sscratch_top:


SIGNATURE_BEGIN

test_1_res:
    .fill 1024, 4, 0xdeadbeef

sig_end_canary:
.int 0x0
rvtest_sig_end:

.align 3
    .fill 2, 4, 0   // pad so selfcheck_record does not share an address with end_signature (objdump only labels one symbol per address)
.globl selfcheck_record
selfcheck_record:
    .fill 8, REGBYTES, 0



.endm

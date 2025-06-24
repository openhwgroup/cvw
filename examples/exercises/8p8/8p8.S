.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:

    # set up trap trap_handler
    la t0, trap_handler # address of trap trap_handler
    csrw mtvec, t0      # mtvec = pointer to trap handler
    la t0, trapstack    # address of trap stack
    csrw mscratch, t0   # mscratch = pointer to trap stack
    sw zero, 12(t0)     # size of buffer

wait:
    nop
    j wait              # wait for uart communication


self_loop:
    j self_loop


trap_handler:
    csrrw tp, mscratch, tp  # swap tp and mscratch to put a trap stack pointer in tp

    # save some registers on trap stack. ß
    sw t0, 0(tp)            
    sw t1, 4(tp)
    sw t2, 8(tp)
 
    lw t0, 12(tp)           # get current length of buffer
    li t1, 0x10000000       # UART base address
    lbu t1, 0(t1)           # fetch next character
    add t2, tp, t0          # address in buffer
    sb t1, 0(t2)            # store character in buffer
    li t2, 79               # maximum buffer length
    beq t0, t2, skip        # is buffer full?
    addi t0, t0, 1          # increase buffer pointer
skip:
    sw t0, 12(tp)           # update buffer length

trap_return:                # return to next instruction
    csrr t0, mepc           # read mepc
    addi t0, t0, 4          # mepc + 4
    csrw mepc, t0           # mepc = mpec + 4 (return to next instruction)
    # restore all of the registers from the trap stack (rd could be in any one)
    lw t0, 0(tp)
    lw t1, 4(tp)
    lw t2, 8(tp)
    csrrw tp, mscratch, tp  # restore tp and trap stack pointer
    mret

buffer:
   .fill 80, 1              # room for buffer

trapstack:
    .fill 34, 4             # room to save registers and buffer length
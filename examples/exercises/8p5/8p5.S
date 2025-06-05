.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:

    # set up trap trap_handler
    la t0, trap_handler # address of trap trap_handler
    csrw mtvec, t0      # mtvec = pointer to trap handler
    la t0, trapstack    # address of trap stack
    csrw mscratch, t0   # mscratch = pointer to trap stack

    lw t0, 1(zero)      # cause access or misaligned load fault to invoke trap handler

self_loop:
    j self_loop


trap_handler:
    csrrw tp, mscratch, tp  # swap tp and mscratch to put a trap stack pointer in tp
    sw t0, 0(tp)            # save t0 on trap stack
    csrr t0, mepc           # read mepc
    addi t0, t0, 4          # mepc + 4
    csrw mepc, t0           # mepc = mpec + 4 (return to next instruction)
    lw t0, 0(tp)            # restore t0 from trap stack
    csrrw tp, mscratch, tp  # restore tp and trap stack pointer
    mret

trapstack:
    .word 0                 # room to save a register
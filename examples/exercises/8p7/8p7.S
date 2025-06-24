.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:

    # set up trap trap_handler
    la t0, trap_handler # address of trap trap_handler
    csrw mtvec, t0      # mtvec = pointer to trap handler
    la t0, trapstack    # address of trap stack
    csrw mscratch, t0   # mscratch = pointer to trap stack

    la t0, destination  # get address to make a load
    lw t0, 3(t0)        # misaligned load will invoke trap handler
    # should return 0x23456789 in t0

self_loop:
    j self_loop


trap_handler:
    csrrw tp, mscratch, tp  # swap tp and mscratch to put a trap stack pointer in tp

    # save all registers on trap stack.  We will need to index into them to find the arguments to emulate multiply
    sw x0, 0(tp)            # x0 is 0, but we might want to use it
    sw x1, 4(tp)
    sw x2, 8(tp)
    sw x3, 12(tp)
    sw x4, 16(tp)
    sw x5, 20(tp)
    sw x6, 24(tp)
    sw x7, 28(tp)
    sw x8, 32(tp)
    sw x9, 36(tp)
    sw x10, 40(tp)
    sw x11, 44(tp)
    sw x12, 48(tp)
    sw x13, 52(tp)
    sw x14, 56(tp)
    sw x15, 60(tp)
    sw x16, 64(tp)
    sw x17, 68(tp)
    sw x18, 72(tp)
    sw x19, 76(tp)
    sw x20, 80(tp)
    sw x21, 84(tp)
    sw x22, 88(tp)
    sw x23, 92(tp)
    sw x24, 96(tp)
    sw x25, 100(tp)
    sw x26, 104(tp)
    sw x27, 108(tp)
    sw x28, 112(tp)
    sw x29, 116(tp)
    sw x30, 120(tp)
    sw x31, 124(tp)

    csrr t0, mcause         # check cause of trap
    li t1, 4                # cause 4 is misaligned load
    bne t0, t1, trap_return # return for any other cause

    # check if instruction is lw (op=0000011, funct3 = 010)
    csrr t0, mepc           # address of faulting instruction
    lw t3, 0(t0)            # fetch the instruction.  It must have been a load.
    srli t1, t3, 12         # get funct3 field (instr[14:12])
    andi t1, t1, 7          # mask off other bits.
    xori t1, t1, 0b010      # should produce 0 if funct3 = 010
    bnez t1, trap_return    # return if any other kind of load

    # emulate lw by performing four byte loads
    csrr t0, mtval          # address of load instruction
    lbu t1, 0(t0)           # read zeroth byte
    lbu t2, 1(t0)           # read the first byte
    slli t2, t2, 8          # shift into position
    or t1, t1, t2           # merge with zeroth byte
    lbu t2, 2(t0)           # read the second byte
    slli t2, t2, 16         # shift into position
    or t1, t1, t2           # merge with previous two bytes
    lbu t2, 3(t0)           # read the third byte
    slli t2, t2, 24         # shift into position
    or t2, t1, t2           # merge with previous three bytes

    # find rd and put result there
    srli t1, t3, 7          # extract rd from instr[11:7]
    andi t1, t1, 31         # mask off other bits
    slli t1, t1, 2          # multiply rd by 4 to make it a word index
    add t1, tp, t1          # find location of rd on trap stack
    sw t2, 0(t1)            # store result into rd storage on trap stack

    # return to next instruction

trap_return:
    csrr t0, mepc           # read mepc
    addi t0, t0, 4          # mepc + 4
    csrw mepc, t0           # mepc = mpec + 4 (return to next instruction)
    # restore all of the registers from the trap stack (rd could be in any one)
    lw x1, 4(tp)
    lw x2, 8(tp)
    lw x3, 12(tp)
    lw x4, 16(tp)
    lw x5, 20(tp)
    lw x6, 24(tp)
    lw x7, 28(tp)
    lw x8, 32(tp)
    lw x9, 36(tp)
    lw x10, 40(tp)
    lw x11, 44(tp)
    lw x12, 48(tp)
    lw x13, 52(tp)
    lw x14, 56(tp)
    lw x15, 60(tp)
    lw x16, 64(tp)
    lw x17, 68(tp)
    lw x18, 72(tp)
    lw x19, 76(tp)
    lw x20, 80(tp)
    lw x21, 84(tp)
    lw x22, 88(tp)
    lw x23, 92(tp)
    lw x24, 96(tp)
    lw x25, 100(tp)
    lw x26, 104(tp)
    lw x27, 108(tp)
    lw x28, 112(tp)
    lw x29, 116(tp)
    lw x30, 120(tp)
    lw x31, 124(tp)
    csrrw tp, mscratch, tp  # restore tp and trap stack pointer
    mret

destination:
    .dword 0x0123456789ABCDEF   # fill destination with some stuff

trapstack:
    .fill 32, 4             # room to save registers
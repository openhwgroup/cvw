.option nopic
.option relax

.include "common.inc"

.equiv EXCEPTION_ILLEGAL_INSTRUCTION, 2

.attribute stack_align, 16

.weak atpg_func_end
.globl csr_trap_handler

.extern atpg_values
.extern atpg_func

.text
.p2align 8
csr_trap_handler:

    #sw t2, 8(sp) #used for signature

    csrr t4, mepc #-->pc che ha fatto scattare exception
    csrr t1, mcause
    add  t2, t2, t1
    la   t1, atpg_func
    sub  t1,t4,t1 #mepc
    add  t2,t2,t1
    addi t4, t4, 4
    csrw mepc, t4

    mret



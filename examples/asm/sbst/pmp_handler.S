.option nopic
.option relax

#.include "common.inc"

.equiv EXCEPTION_ILLEGAL_INSTRUCTION, 2

.attribute stack_align, 16

#.weak atpg_func_end
.align 2 
.globl pmp_handler
.extern restore_section


.text
.p2align 8
pmp_handler:

    li   t2,0xdeba     

    csrr t1, mcause
    li   t0, 8
    beq  t1, t0, handle_ecall
    li   t0, 2
    beq  t1,t0, handle_pmp_fault

not_from_u_mode:
        #ebreak

handle_pmp_fault:
    li t2,0xdebf
    csrr t0, mepc
   # xor  t6,t6,t2
   # add t2, t2, t6
    addi t0, t0, 4
    csrw mepc, t0
    j    trap_exit

handle_ecall:
    # set MPP=11 (Machine) and mepc->restore_section
    li t2,0xdebe
    csrr t0, mstatus
    li   t5, 0x1800         # mask = ~(0x1800)
    or   t0, t0, t5             # set MPP to 11
    csrw mstatus, t0
    la   t0, restore_section
    csrw mepc, t0
    #j    trap_exit

trap_exit:

    li t2,0xdebaa
    mret

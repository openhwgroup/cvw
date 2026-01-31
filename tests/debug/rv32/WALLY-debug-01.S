//////////////////////////////////////////////////////////////////////
// WALLY-debug-01-rv32.S
//////////////////////////////////////////////////////////////////////
    .text
    .globl rvtest_entry_point
rvtest_entry_point:
    j rvtest_entry_point

test_end:
    j tohost_exit

    .globl tohost_exit
tohost_exit:
    slli a0, a0, 1
    ori  a0, a0, 1
    la   t0, tohost
    sw   a0, 0(t0)
1:  j    1b

    .section .tohost, "aw", @progbits
    .align 2                 # 2^2 = 4-byte alignment for RV32
    .globl tohost
tohost:   .word 0            # RV32-sized host word

    .align 2
    .globl fromhost
fromhost: .word 0

    # a syscall buffer?
    .align 2
magic_mem: .word 0, 0, 0, 0, 0, 0, 0, 0

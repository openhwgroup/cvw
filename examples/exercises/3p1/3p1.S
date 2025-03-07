.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:
    li t0, 0x42
    li t1, 0xED
    add t2, t0, t1

self_loop:
    j self_loop

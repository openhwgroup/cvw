.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
    li a0, 42

self_loop:
    j self_loop

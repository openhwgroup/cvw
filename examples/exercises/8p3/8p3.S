.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:
    li t0, 32			# 1 in bit 5
    csrs mstatush, t0	# set bit 5 (mstatush.MBE)

self_loop:
    j self_loop

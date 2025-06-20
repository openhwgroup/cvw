.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:
    csrr a0, cycle      # read cycle register before computation

    # add up numbers from 1 to 10.  Place result in s0
    li s0, 0            # initialize sum to 0 in s0
    li s1, 1            # initialize loop variable i to 1 in s1
    li t0, 10           # temporary for maximum number
loop:
    add s0, s0, s1      # sum = sum + i
    addi s1, s1, 1      # i = i + 1
    ble s1, t0, loop    # repeat while i <= 10

    csrr a1, cycle      # read cycle register after computation
    sub a0, a1, a0      # compute difference in a0

self_loop:
    j self_loop

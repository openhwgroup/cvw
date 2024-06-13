.section .text
.globl config_pll
.type config_pll, @function

config_pll:
    # Configure memory-mapped registers for PLL clock generation
    # This config generates a 2GHz clock at the PLL output, which we divide down

    # clkr
    li t1, 0x00020000
    li t2, 0x00
    sd t2, 0(t1)

    # clkf
    addi t1, t1, 8
    li t2, 0x0027
    sd t2, 0(t1)

    # clkod
    addi t1, t1, 8
    li t2, 0x0
    sd t2, 0(t1)

    # bwadj
    addi t1, t1, 8
    li t2, 0x13
    sd t2, 0(t1)

    # test
    addi t1, t1, 8
    li t2, 0x0
    sd t2, 0(t1)

    # fasten
    addi t1, t1, 8
    li t2, 0x0
    sd t2, 0(t1)

    # wait for lock
    addi t1, t1, 8
    ld t2, 0(t1)
wait_until_pll_locked:
    bne t2, zero, pll_locked
    ld t2, 0(t1)
pll_locked:
    ret

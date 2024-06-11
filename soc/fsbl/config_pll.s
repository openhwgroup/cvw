.section .text
.globl config_pll
.type config_pll, @function

config_pll:
    # Configure memory-mapped registers for PLL clock generation

    # clkr
    li t1, 0x00020000
    li t2, 0x1
    sd t2, 0(t1)

    # clkf
    addi t1, t1, 8
    li t2, 0x14
    sd t2, 0(t1)

    # clkod
    addi t1, t1, 8
    li t2, 0x2
    sd t2, 0(t1)

    # bwadj
    addi t1, t1, 8
    li t2, 0xa
    sd t2, 0(t1)

    # test
    addi t1, t1, 8
    li t2, 0x0
    sd t2, 0(t1)

    # fasten
    addi t1, t1, 8
    li t2, 0x0
    sd t2, 0(t1)

    ret

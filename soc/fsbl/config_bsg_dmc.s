.section .text
.globl config_bsg_dmc
.type config_bsg_dmc, @function

config_bsg_dmc:
    # Configure memory-mapped registers for bsg_dmc memory sizing,
    # timing parameters, and initialization sequence
    # These values work with Micron LPDDR model provided by BSG

    # trefi
    li t1, 0x00030000
    li t2, 0x3ff
    sd t2, 0(t1)

    # tmrd
    addi t1, t1, 8
    li t2, 0x1
    sd t2, 0(t1)

    # trfc
    addi t1, t1, 8
    li t2, 0xf
    sd t2, 0(t1)

    # trc
    addi t1, t1, 8
    li t2, 0xa
    sd t2, 0(t1)

    # trp
    addi t1, t1, 8
    li t2, 0x2
    sd t2, 0(t1)

    # tras
    addi t1, t1, 8
    li t2, 0x7
    sd t2, 0(t1)

    # trrd
    addi t1, t1, 8
    li t2, 0x1
    sd t2, 0(t1)

    # trcd
    addi t1, t1, 8
    li t2, 0x2
    sd t2, 0(t1)

    # twr
    addi t1, t1, 8
    li t2, 0xa
    sd t2, 0(t1)

    # twtr
    addi t1, t1, 8
    li t2, 0x7
    sd t2, 0(t1)

    # trtp
    addi t1, t1, 8
    li t2, 0xa
    sd t2, 0(t1)

    # tcas
    addi t1, t1, 8
    li t2, 0x3
    sd t2, 0(t1)

    # col_width
    addi t1, t1, 8
    li t2, 0xb
    sd t2, 0(t1)

    # row_width
    addi t1, t1, 8
    li t2, 0xe
    sd t2, 0(t1)

    # bank_width
    addi t1, t1, 8
    li t2, 0x2
    sd t2, 0(t1)

    # bank_pos
    addi t1, t1, 8
    li t2, 0x19
    sd t2, 0(t1)

    # dqs_sel_cal
    addi t1, t1, 8
    li t2, 0x3
    sd t2, 0(t1)

    # init_cycles
    addi t1, t1, 8
    li t2, 0x9c4a
    sd t2, 0(t1)

    ret

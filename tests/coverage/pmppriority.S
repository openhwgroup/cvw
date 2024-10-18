// pmppriority test cases
// Kevin Wan kewan@hmc.edu 4/27/2023
// want memory ranges to match:
// 1. only the most significant address and none of the lower ones,
// 2. the most significant address and ANY of the lower ones.



#include "WALLY-init-lib.h"
main:

    li t1, 0x21FFFFFF // start at 0x8000000 with a range of 1000000. Address format is set to NAPOT in pmpcfg.
    csrw pmpaddr0, t1
    csrw pmpaddr1, t1
    csrw pmpaddr2, t1
    csrw pmpaddr3, t1
    csrw pmpaddr4, t1
    csrw pmpaddr5, t1
    csrw pmpaddr6, t1
    csrw pmpaddr7, t1

    csrw pmpaddr8, t1
    csrw pmpaddr9, t1
    csrw pmpaddr10, t1
    csrw pmpaddr11, t1
    csrw pmpaddr12, t1
    csrw pmpaddr13, t1
    csrw pmpaddr14, t1
    csrw pmpaddr15, t1


    li t0, 0x1F
    csrw pmpcfg0, t0 //set to XWR and NAPOT
    sw zero, 0(sp)

    li t0, 0x1F00
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F1F
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F0000
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F000000
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F00000000
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F0000000000
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F1F
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F000000000000
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F1F1F
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F00000000000000
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F1F1F1F
    csrw pmpcfg0, t0
    sw zero, 0(sp)

    li t0, 0x0
    csrw pmpcfg0, t0
    li t0, 0x1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F00
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F0000
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F00000000
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F0000000000
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F000000000000
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F00000000000000
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F1F1F1F
    csrw pmpcfg0, t0
    li t0, 0x1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F1F1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)

    li t0, 0x1F1F1F1F1F1F1F1F
    csrw pmpcfg2, t0
    sw zero, 0(sp)



    j done

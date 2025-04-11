// pmpadrdecs
// Liam Chalk, lchalk@hmc.edu, 4/27/2023
// Setting AdrMode to 2 or 3 for pmpadrdecs[0-4]

#include "WALLY-init-lib.h"
main:

    # Writing values to pmpcfg0 to change AdrMode to 2 or 3
    # pmpadrdec[0]
    li t0, 0x0000000010
    csrw pmpcfg0, t0
    # pmpadrdec[1]
    li t0, 0x0000001800
    csrw pmpcfg0, t0
    # pmpadrdec[2]
    li t0, 0x0000180000
    csrw pmpcfg0, t0
    # pmpadrdec[4]
    li t0, 0x1000000000
    csrw pmpcfg0, t0

    # test hitting each region in NA4 mode for DMMU
    li t0, 0x20000000 # address 0x80000000
    csrw pmpaddr15, t0
    csrw pmpaddr14, t0
    csrw pmpaddr13, t0
    csrw pmpaddr12, t0
    li t0, 0x1717171717171717 # every region is NA4 XWR
    csrw pmpcfg0, t0
    csrw pmpcfg2, t0

    li t0, 0x80000000 
    lw t1, 0(t0)

    # test hitting region in NA4 mode for IMMU
    la t0, pmpjump # address of a jump destination to exercise immu pmpchecker
    srli t1, t0, 2 # shift right by 2 to convert to PMP format
    csrw pmpaddr15, t1
    csrw pmpaddr14, t1
    csrw pmpaddr13, t1
    csrw pmpaddr12, t1
    csrw pmpaddr11, t1
    csrw pmpaddr10, t1
    csrw pmpaddr9, t1
    csrw pmpaddr8, t1
    csrw pmpaddr7, t1
    csrw pmpaddr6, t1
    csrw pmpaddr5, t1
    csrw pmpaddr4, t1
    csrw pmpaddr3, t1
    csrw pmpaddr2, t1
    csrw pmpaddr1, t1
    csrw pmpaddr0, t1
    jalr t0

    j done

pmpjump:
    ret
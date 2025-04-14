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

    # test hitting region in TOR mode for IMMU
    add t2, t1, 1   # top of range

    # region 0 TOR at pmpjump
    li t3, 0x0F # TOR XWR
    csrw pmpcfg0, t3
    csrw pmpcfg2, 0
    csrw pmpaddr0, t2
    jalr t0

    # region 1 TOR at pmpjump
    li t3, 0x0F00 # TOR XWR
    csrw pmpcfg0, t3
    csrw pmpcfg2, 0
    csrw pmpaddr0, t1
    csrw pmpaddr1, t2
    jalr t0

    # region 1 TOR at pmpjump
    li t3, 0x0F00 # TOR XWR
    csrw pmpcfg0, t3
    csrw pmpcfg2, 0
    csrw pmpaddr0, t1
    csrw pmpaddr1, t2
    jalr t0

    # region 8 TOR at pmpjump
    li t3, 0x0F # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr7, t1
    csrw pmpaddr8, t2
    jalr t0

    # region 9 TOR at pmpjump
    li t3, 0x0F00 # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr8, t1
    csrw pmpaddr9, t2
    jalr t0

    # region 10 TOR at pmpjump
    li t3, 0x0F0000 # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr9, t1
    csrw pmpaddr10, t2
    jalr t0

    # region 11 TOR at pmpjump
    li t3, 0x0F000000 # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr10, t1
    csrw pmpaddr11, t2
    jalr t0

    # region 12 TOR at pmpjump
    li t3, 0x0F00000000 # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr11, t1
    csrw pmpaddr12, t2
    jalr t0

    # region 13 TOR at pmpjump
    li t3, 0x0F0000000000 # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr12, t1
    csrw pmpaddr13, t2
    jalr t0

    # region 14 TOR at pmpjump
    li t3, 0x0F000000000000 # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr13, t1
    csrw pmpaddr14, t2
    jalr t0

    # region 15 TOR at pmpjump
    li t3, 0x0F00000000000000 # TOR XWR
    csrw pmpcfg2, t3
    csrw pmpcfg0, 0
    csrw pmpaddr14, t1
    csrw pmpaddr15, t2
    jalr t0



    # test AMO not causing Load access fault
    # assign PMPLoadAccessFaultM      = EnforcePMP & ReadAccessM & ~WriteAccessM & ~MatchingR;
    la s0, scratch

    li t0, 0x0F000C00 # region 3 encompassing all addresses has TOR XWR, region 1 has TOR X only
    csrw pmpcfg0, t0

    # give only execute access to scratch
    # set up TOR region 0-1 to do this (yes, NA4 would work too)
    srli t0, s0, 2 # drop bottom two bits
    csrw pmpaddr0, t0
    addi t0, t0, 1 # next word
    csrw pmpaddr1, t0

    # everything else has full access, with a big TOR from 0 t0 FFFFFFFF
    csrw pmpaddr2, zero
    li t0, 0xFFFFFFFF  # full range
    csrw pmpaddr3, t0
    
    # switch to supervisor mode
    li a0, 1
    ecall

    # test the AMO
    amoswap.w t1, zero, (s0)  # attempt amo; should get store but not load access fault because this region is X only

    li a0, 3
    ecall     # return to M mode
   
    j done

.align 2
pmpjump:
    ret

.align 2
scratch:
    .word 0

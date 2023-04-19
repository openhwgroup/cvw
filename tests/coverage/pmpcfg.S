// pmpcfg supplemental

#include "WALLY-init-lib.h" 
main: 
    li t0, 0x8800000000000000
    csrw pmpcfg2, t0
    li t0, 0x88000000000000
    csrw pmpcfg2, t0
    li t0, 0x880000000000
    csrw pmpcfg2, t0
    li t0, 0x8800000000
    csrw pmpcfg2, t0
    li t0, 0x88000000
    csrw pmpcfg2, t0
    li t0, 0x880000
    csrw pmpcfg2, t0
    li t0, 0x8800
    csrw pmpcfg2, t0
    li t0, 0x8800000000000000
    csrw pmpcfg0, t0
    li t0, 0x88000000000000
    csrw pmpcfg0, t0
    li t0, 0x880000000000
    csrw pmpcfg0, t0
    li t0, 0x8800000000
    csrw pmpcfg0, t0
    li t0, 0x88000000
    csrw pmpcfg0, t0
    li t0, 0x880000
    csrw pmpcfg0, t0
    li t0, 0x8800
    csrw pmpcfg0, t0
    j done

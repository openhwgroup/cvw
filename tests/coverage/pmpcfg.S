// pmpcfg part 1
// Kevin Wan, kewan@hmc.edu, 4/18/2023
// locks each pmpXcfg bit field in order, from X = 15 to X = 0, with the A[1:0] field set to TOR. 
// See the next part in pmpcfg1.S

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
    li t0, 0x88
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

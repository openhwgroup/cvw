// another set of pmpcfg tests. A new file is made because pmpcfg register fields are
// locked forever after writing 1 to the lock bit for the first time.

// Kevin Wan, kewan@hmc.edu, 4/13/2023
// This set tests locking the pmpXcfg fields in descending order again, without setting the TOR bits.
// for the other part of the tests, see pmpcfg.S

#include "WALLY-init-lib.h"
main:
    li t0, 0x800
    csrw pmpcfg0, t0
    li t0, 0x8000000
    csrw pmpcfg0, t0

    li t0, 0x8000000000000000
    csrw pmpcfg2, t0
    li t0, 0x80000000000000
    csrw pmpcfg2, t0
    li t0, 0x800000000000
    csrw pmpcfg2, t0
    li t0, 0x8000000000
    csrw pmpcfg2, t0
    li t0, 0x80000000
    csrw pmpcfg2, t0
    li t0, 0x800000
    csrw pmpcfg2, t0
    li t0, 0x8000
    csrw pmpcfg2, t0
    li t0, 0x80
    csrw pmpcfg2, t0
    li t0, 0x8000000000000000
    csrw pmpcfg0, t0
    li t0, 0x80000000000000
    csrw pmpcfg0, t0
    li t0, 0x800000000000
    csrw pmpcfg0, t0
    li t0, 0x8000000000
    csrw pmpcfg0, t0
    li t0, 0x80000000
    csrw pmpcfg0, t0
    li t0, 0x800000
    csrw pmpcfg0, t0
    li t0, 0x8000
    csrw pmpcfg0, t0



    j done

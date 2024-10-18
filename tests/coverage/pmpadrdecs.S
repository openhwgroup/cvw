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

    j done

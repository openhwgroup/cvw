# fround.s

#include "WALLY-init-lib.h"

# run-elf.bash find this in project description
main:

    bseti t0, zero, 14  # turn on FPU
    csrs mstatus, t0

    # test fround behavior on NaN
    li t0, 0x7FC00001
    fmv.w.x ft0, t0
    fround.s ft1, ft0
    j done

.align 10
data_start:

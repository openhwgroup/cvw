///////////////////////////////////////////
// zama16b.S
//
// Purpose: Check Zama16b misaligned AMO behavior.  A misaligned AMO that stays inside one naturally
//          aligned 16 byte granule is performed in hardware; one that crosses a granule still takes a
//          store/AMO access fault, which WALLY-init-lib.h's handler skips, leaving memory untouched.
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
////////////////////////////////////////////////////////////////////////////////////////////////

#include "WALLY-init-lib.h"
#include "WALLY-selfcheck.h"

main:
    la a2, zamadata             # 16 byte aligned scratch
    sd zero, 0(a2)
    sd zero, 8(a2)
    sd zero, 16(a2)

    # A doubleword AMO at offset 4 covers bytes 4-11, inside the first granule, so Zama16b performs it
    addi a3, a2, 4
    li a4, 0x1234
    li a5, -1                   # sentinel the AMO must replace with the old value
    amoadd.d a5, a4, (a3)
    SC_CHECK_EQ a5, zero, 1     # returned the old value
    ld a6, 4(a2)                # misaligned load is handled by Zicclsm
    SC_CHECK_EQ a6, a4, 2       # memory was updated

    # A doubleword AMO at offset 12 covers bytes 12-19, crossing into the next granule, so it faults
    addi a3, a2, 12
    li a4, 0x5678
    li a5, -1                   # sentinel must survive the skipped instruction
    amoadd.d a5, a4, (a3)
    li a7, -1
    SC_CHECK_EQ a5, a7, 3       # destination untouched
    ld a6, 12(a2)
    SC_CHECK_EQ a6, zero, 4     # memory untouched

    SC_PASS
    j done

.section .data
.align 4
zamadata:
    .dword 0, 0, 0, 0

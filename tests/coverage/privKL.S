///////////////////////////////////////////
// privKL.S
//
// Written: David_Harris@hmc.edu 23 March 2023
//
// Purpose: Test coverage for EBU
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

// load code to initalize stack, handle interrupts, terminate

#include "WALLY-init-lib.h"

main:


    li a0, 3
    ecall
    wfi
    li t3, 0x10          // Desired offset from the present time
    mv a3, t3            // copy value in to know to stop waiting for interrupt after this many cycles
    la t4, 0x02004000    // MTIMECMP register in CLINT
    la t5, 0x0200BFF8    // MTIME register in CLINT
    lw t2, 0(t5)         // low word of MTIME
    lw t6, 4(t5)         // high word of MTIME
    add t3, t2, t3       // add desired offset to the current time
    bgtu t3, t2, nowrap_m  // check new time exceeds current time (no wraparound)
    addi t6, t6, 1       // if wrap, increment most significant word
    sw t6,4(t4)          // store into most significant word of MTIMECMP
    nowrap_m:
        sw t3, 0(t4)         // store into least significant word of MTIMECMP
    time_loop_m:
        addi a3, a3, -1
        bnez a3, time_loop_m // go through this loop for [a3 value] iterations before returning without performing interrupt
        ret
    j done
    



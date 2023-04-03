///////////////////////////////////////////
// priv.S
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

    # switch to supervisor mode
    li a0, 1   
    ecall

    # Test read to stimecmp fails when MCOUNTEREN_TM is not set
    addi t0, zero, 0
    csrr t0, stimecmp 

    # Test write to STVAL, SCAUSE, SEPC, and STIMECMP CSRs
    li t0, 0
    csrw stval, t0
    csrw scause, t0
    csrw sepc, t0
    csrw stimecmp, t0
    
    j done

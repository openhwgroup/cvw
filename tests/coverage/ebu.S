///////////////////////////////////////////
// ebu.S
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

    # Test clz with all bits being 0
    li t0, 0
    clz t1, t0
    li t0, -1
    clz t1, t0
    li t0, 1
    clz t1, t0

    # Test forwarding from store conditional
    lr.w t0, 0(a0)
    sc.w t0, a1, 0(a0)
    addi t0, t0, 1

    j done


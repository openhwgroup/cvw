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
    li t1, -3
    csrw stimecmp, t1
    csrr t0, stimecmp 


    # satp write with mstatus.TVM = 1
    bseti t0, zero, 20 
    csrs mstatus, t0
    csrw satp, zero

    # STIMECMP from S mode
    li t0, 1
    ecall   # enter S-mode
    csrw stimecmp, zero
    li t0, 3
    ecall   # return to M-mode
    csrsi mcounteren, 2 # mcounteren_tm = 1
    li t0, 1
    ecall   # supervisor mode again
    csrw stimecmp, zero
    li t0, 3
    ecall  # machine mode again


    # switch to supervisor mode
    li a0, 1   
    ecall

    # Test write to STVAL, SCAUSE, SEPC, and STIMECMP CSRs
    li t0, 0
    csrw stval, t0
    csrw scause, t0
    csrw sepc, t0
    csrw stimecmp, t0
    csrw scounteren, zero
    csrw satp, zero


    # Switch to machine mode
    li a0, 3   
    ecall 

    # Write to MCOUNTINHIBIT CSR
    csrw mcountinhibit, t0

    # Testing the HPMCOUNTERM performance counter: writing
    # Base address is 2816 (MHPMCOUNTERBASE)
    # There are 32 HPMCOUNTER registers
    csrw 2816, t0
    csrw 2817, t0
    csrw 2818, t0
    csrw 2819, t0
    csrw 2820, t0
    csrw 2821, t0
    csrw 2822, t0
    csrw 2823, t0
    csrw 2824, t0
    csrw 2825, t0
    csrw 2826, t0
    csrw 2827, t0
    csrw 2828, t0
    csrw 2829, t0
    csrw 2830, t0
    csrw 2831, t0  
    csrw 2832, t0
    csrw 2833, t0
    csrw 2834, t0
    csrw 2835, t0
    csrw 2836, t0
    csrw 2837, t0
    csrw 2838, t0
    csrw 2839, t0
    csrw 2840, t0
    csrw 2841, t0
    csrw 2842, t0
    csrw 2843, t0
    csrw 2844, t0
    csrw 2845, t0
    csrw 2846, t0
    csrw 2847, t0      

    # Testing the HPMCOUNTERM performance counter: reading
    csrr t0, 2817

    # Test writes to pmp address registers
    csrw 951, t0
    csrw 952, t0
    csrw 953, t0
    csrw 954, t0
    csrw 955, t0
    csrw 956, t0
    csrw 957, t0
    csrw 958, t0


    # Testing writes to MTVAL, MCAUSE    
    li t0, 0
    csrw mtval, t0
    csrw mcause, t0

    # set mstatus to enable floating point registers (mstatus.FS = 11)
    bseti t1, zero, 13
    csrs mstatus, t1
    bseti t1, zero, 14
    csrs mstatus, t1

    # Test writes to floating point CSRs
    csrw frm, t0
    csrw fflags, t0

    j done




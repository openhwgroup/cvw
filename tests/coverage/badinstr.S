///////////////////////////////////////////
// badinstr.S
//
// Written: David_Harris@hmc.edu 21 March 2023
//
// Purpose: Test illegal instruction opcodes
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
    .word 0x00000033 // legal R-type instruction
    .word 0x80000033 // illegal R-type instruction
    .word 0x00007003 // illegal Load instruction
    .word 0x80005013 // illegal I-type instruction: srli: op = 0010011, funct3 = 101, funct7 = 1000000
    .word 0x00000000 // illegal instruction
    .word 0x0000701B  // Illegal IW instruction
    .word 0x00004023  // Illegal store instruction
    .word 0x0400003B  // Illegal RW or MulDivW instruction
    .word 0x00007067  // Illegal JALR instruction
    .word 0x00002063  // Illegal branch instruction

    j done


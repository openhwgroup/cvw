///////////////////////////////////////////////////////////////////////
// fail.c
//
// Written: Jaocb Pease jacob.pease@okstate.edu 7/22/2024
//
// Purpose: Prints information on the uart when a fatal bug is
//          encountered. Will expand this later.
//
// 
//
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the
// “License”); you may not use this file except in compliance with the
// License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an “AS IS” BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied. See the License for the specific language governing
// permissions and limitations under the License.
///////////////////////////////////////////////////////////////////////

#include "fail.h"
#include "uart.h"
#include "riscv.h"
#include "time.h"

void fail() {
  // Get address that led to failure
  register uint64_t addr;
  asm volatile ("mv %0, ra" : "=r"(addr) : : "memory"); 

  // Print message
  print_time();
  println_with_addr("Failed at: 0x", addr);
  
  // Loop forever
  while(1) {

  }
}

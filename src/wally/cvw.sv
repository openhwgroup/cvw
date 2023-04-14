//////////////////////////////////////////
// cvw.sv
//
// Written: David_Harris@hmc.edu 27 January 2022
//
// Purpose: package with shared CORE-V-Wally global parameters
//
// A component of the Wally configurable RISC-V project.
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
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

// Usiing global `define statements isn't ideal in a large SystemVerilog system because
// of the risk of `define name conflicts across different subsystems.
// Instead, CORE-V-Wally loads the appropriate configuration one time and places it in a package
// that is referenced by all Wally modules but not by other subsystems.

`ifndef CVW_T

`define CVW_T 1

package cvw;

typedef struct packed {
  byte          FPGA;   // Modifications to tare
  byte          QEMU;   // Hacks to agree with QEMU during Linux boot
  byte          XLEN;   // Machine width (32 or 64)
  logic         IEEE754;  // IEEE754 NaN handling (0 = use RISC-V NaN propagation instead)
  logic [31:0]  MISA;   // Machine Instruction Set Architecture
  byte          AHBW;   // AHB bus width (usually = XLEN)

  // RISC-V Features
  logic         ZICSR_SUPPORTED;
  logic         ZIFENCEI_SUPPORTED;
  byte          COUNTERS;
  logic         ZICOUNTERS_SUPPORTED;
  logic         ZFH_SUPPORTED;
  logic         SSTC_SUPPORTED;
  logic         VIRTMEM_SUPPORTED;
  logic         VECTORED_INTERRUPTS_SUPPORTED;
  logic         BIGENDIAN_SUPPORTED;
  logic         SVADU_SUPPORTED;
  logic         ZMMUL_SUPPORTED;

  // Microarchitectural Features
  logic         BUS_SUPPORTED;
  logic         DCACHE_SUPPORTED;
  logic         ICACHE_SUPPORTED;

// TLB configuration.  Entries should be a power of 2
  byte         ITLB_ENTRIES;
  byte         DTLB_ENTRIES;

// Cache configuration.  Sizes should be a power of two
// typical configuration 4 ways, 4096 bytes per way, 256 bit or more lines
  byte         DCACHE_NUMWAYS;
  shortint         DCACHE_WAYSIZEINBYTES;
  shortint         DCACHE_LINELENINBITS;
  byte         ICACHE_NUMWAYS;
  shortint         ICACHE_WAYSIZEINBYTES;
  shortint         ICACHE_LINELENINBITS;

// Integer Divider Configuration
// IDIV_BITSPERCYCLE must be 1, 2, or 4
  byte         IDIV_BITSPERCYCLE;
  logic         IDIV_ON_FPU;

// Legal number of PMP entries are 0, 16, or 64
  byte         PMP_ENTRIES;

// Address space
  logic [31:0]         RESET_VECTOR;

// WFI Timeout Wait
  byte         WFI_TIMEOUT_BIT;

// Peripheral Addresses
// Peripheral memory space extends from BASE to BASE+RANGE
// Range should be a thermometer code with 0's in the upper bits and 1s in the lower bits
  logic         DTIM_SUPPORTED;
  logic [33:0]         DTIM_BASE;
  logic [33:0]         DTIM_RANGE;
  logic         IROM_SUPPORTED;
  logic [33:0]         IROM_BASE;
  logic [33:0]         IROM_RANGE;
  logic         BOOTROM_SUPPORTED;
  logic [33:0]         BOOTROM_BASE;
  logic [33:0]         BOOTROM_RANGE;
  logic         UNCORE_RAM_SUPPORTED;
  logic [33:0]         UNCORE_RAM_BASE;
  logic [33:0]         UNCORE_RAM_RANGE;
  logic         EXT_MEM_SUPPORTED;
  logic [33:0]         EXT_MEM_BASE;
  logic [33:0]         EXT_MEM_RANGE;
  logic         CLINT_SUPPORTED;
  logic [33:0]         CLINT_BASE;
  logic [33:0]         CLINT_RANGE;
  logic         GPIO_SUPPORTED;
  logic [33:0]         GPIO_BASE;
  logic [33:0]         GPIO_RANGE;
  logic         UART_SUPPORTED;
  logic [33:0]         UART_BASE;
  logic [33:0]         UART_RANGE;
  logic         PLIC_SUPPORTED;
  logic [33:0]         PLIC_BASE;
  logic [33:0]         PLIC_RANGE;
  logic         SDC_SUPPORTED;
  logic [33:0]         SDC_BASE;
  logic [33:0]         SDC_RANGE;

// Test modes

// Tie GPIO outputs back to inputs
  logic         GPIO_LOOPBACK_TEST;

// Hardware configuration
  logic         UART_PRESCALE ;

// Interrupt configuration
  byte         PLIC_NUM_SRC;
  logic        PLIC_NUM_SRC_LT_32;
  byte         PLIC_GPIO_ID;
  byte         PLIC_UART_ID;

  logic         BPRED_SUPPORTED;
  //parameter         BPRED_TYPE "BP_GSHARE" // BP_GSHARE_BASIC, BP_GLOBAL, BP_GLOBAL_BASIC, BP_TWOBIT
  byte         BPRED_SIZE;
  byte         BTB_SIZE;


// FPU division architecture
  byte         RADIX;
  byte         DIVCOPIES;

// bit manipulation
  logic         ZBA_SUPPORTED;
  logic         ZBB_SUPPORTED;
  logic         ZBC_SUPPORTED;
  logic         ZBS_SUPPORTED;

// Memory synthesis configuration
  logic         USE_SRAM;
  
  logic M_SUPPORTED;
  logic F_SUPPORTED;
  logic [63:0] LLEN;
  logic [63:0] FLEN;

  // 
  byte VPN_SEGMENT_BITS;
  byte          PA_BITS;  // size of physical address

} cvw_t;

endpackage

`endif
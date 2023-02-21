//////////////////////////////////////////
// wally-config.vh
//
// Written: David_Harris@hmc.edu 4 January 2021
// Modified: 
//
// Purpose: Specify which features are configured
//          Macros to determine which modes are supported based on MISA
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

// include shared configuration
`include "wally-shared.vh"

`define FPGA 0
`define QEMU 0

// RV32 or RV64: XLEN = 32 or 64
`define XLEN 32

// IEEE 754 compliance
`define IEEE754 0

`define MISA (32'h00000104 | 1 << 20 | 1 << 18 | 1 << 12)
`define ZICSR_SUPPORTED 1
`define ZIFENCEI_SUPPORTED 1
`define COUNTERS 32
`define ZICOUNTERS_SUPPORTED 1
`define ZFH_SUPPORTED 0
`define SSTC_SUPPORTED 0

// LSU microarchitectural Features
`define BUS_SUPPORTED 1
`define DCACHE_SUPPORTED 0
`define ICACHE_SUPPORTED 0
`define VIRTMEM_SUPPORTED 0
`define VECTORED_INTERRUPTS_SUPPORTED 1 
`define BIGENDIAN_SUPPORTED 0

// TLB configuration.  Entries should be a power of 2
`define ITLB_ENTRIES 0
`define DTLB_ENTRIES 0

// Cache configuration.  Sizes should be a power of two
// typical configuration 4 ways, 4096 bytes per way, 256 bit or more lines
`define DCACHE_NUMWAYS 4
`define DCACHE_WAYSIZEINBYTES 4096
`define DCACHE_LINELENINBITS 512
`define ICACHE_NUMWAYS 4
`define ICACHE_WAYSIZEINBYTES 4096
`define ICACHE_LINELENINBITS 512

// Integer Divider Configuration
// IDIV_BITSPERCYCLE must be 1, 2, or 4
`define IDIV_BITSPERCYCLE 2
`define IDIV_ON_FPU 0

// Legal number of PMP entries are 0, 16, or 64
`define PMP_ENTRIES 0

// Address space
`define RESET_VECTOR 32'h80000000

// WFI Timeout Wait
`define WFI_TIMEOUT_BIT 16

// Peripheral Addresses
// Peripheral memory space extends from BASE to BASE+RANGE
// Range should be a thermometer code with 0's in the upper bits and 1s in the lower bits
`define DTIM_SUPPORTED 1'b1
`define DTIM_BASE       34'h80000000
`define DTIM_RANGE      34'h007FFFFF
`define IROM_SUPPORTED 1'b1
`define IROM_BASE       34'h80000000
`define IROM_RANGE      34'h007FFFFF
`define BOOTROM_SUPPORTED 1'b0
`define BOOTROM_BASE   34'h00001000 
`define BOOTROM_RANGE  34'h00000FFF
`define UNCORE_RAM_SUPPORTED 1'b0
`define UNCORE_RAM_BASE       34'h80000000
`define UNCORE_RAM_RANGE      34'h07FFFFFF
`define EXT_MEM_SUPPORTED 1'b0
`define EXT_MEM_BASE       34'h80000000
`define EXT_MEM_RANGE      34'h07FFFFFF
`define CLINT_SUPPORTED 1'b1
`define CLINT_BASE  34'h02000000
`define CLINT_RANGE 34'h0000FFFF
`define GPIO_SUPPORTED 1'b1
`define GPIO_BASE   34'h10060000
`define GPIO_RANGE  34'h000000FF
`define UART_SUPPORTED 1'b1
`define UART_BASE   34'h10000000
`define UART_RANGE  34'h00000007
`define PLIC_SUPPORTED 1'b1
`define PLIC_BASE   34'h0C000000
`define PLIC_RANGE  34'h03FFFFFF
`define SDC_SUPPORTED 1'b0
`define SDC_BASE   34'h00012100
`define SDC_RANGE  34'h0000001F

// Bus Interface width
`define AHBW 32

// Test modes

// Tie GPIO outputs back to inputs
`define GPIO_LOOPBACK_TEST 1

// Hardware configuration
`define UART_PRESCALE 1

// Interrupt configuration
`define PLIC_NUM_SRC 10
// comment out the following if >=32 sources
`define PLIC_NUM_SRC_LT_32
`define PLIC_GPIO_ID 3
`define PLIC_UART_ID 10

`define BPRED_SUPPORTED 0
`define BPRED_TYPE "BP_GSHARE" // BP_GSHARE_BASIC, BP_GLOBAL, BP_GLOBAL_BASIC, BP_TWOBIT
`define BPRED_SIZE 10
`define BTB_SIZE 10

`define HPTW_WRITES_SUPPORTED 0

// FPU division architecture
`define RADIX 32'h4
`define DIVCOPIES 32'h4

// bit manipulation
`define ZBA_SUPPORTED 0
`define ZBB_SUPPORTED 0
`define ZBC_SUPPORTED 0
`define ZBS_SUPPORTED 0

// Memory synthesis configuration
`define USE_SRAM 0

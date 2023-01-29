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

`define FPGA 1
`define QEMU 0

// RV32 or RV64: XLEN = 32 or 64
`define XLEN 64

// IEEE 754 compliance
`define IEEE754 0

`define MISA (32'h0014112D)
`define ZICSR_SUPPORTED 1
`define ZIFENCEI_SUPPORTED 1
`define ZICOUNTERS_SUPPORTED 1
`define ZFH_SUPPORTED 0
`define COUNTERS 32

// LSU microarchitectural Features
`define BUS_SUPPORTED 1
`define DCACHE_SUPPORTED 1
`define ICACHE_SUPPORTED 1
`define VIRTMEM_SUPPORTED 1
`define VECTORED_INTERRUPTS_SUPPORTED 1 
`define BIGENDIAN_SUPPORTED 1

// TLB configuration.  Entries should be a power of 2
`define ITLB_ENTRIES 32
`define DTLB_ENTRIES 32

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
`define IDIV_BITSPERCYCLE 4
`define IDIV_ON_FPU 1

// Legal number of PMP entries are 0, 16, or 64
`define PMP_ENTRIES 16

// Address space
`define RESET_VECTOR 64'h0000000000001000

// WFI Timeout Wait
`define WFI_TIMEOUT_BIT 16

// Peripheral Addresses
// Peripheral memory space extends from BASE to BASE+RANGE
// Range should be a thermometer code with 0's in the upper bits and 1s in the lower bits
`define DTIM_SUPPORTED 1'b0
`define DTIM_BASE       56'h80000000
`define DTIM_RANGE      56'h00001FFF
`define IROM_SUPPORTED 1'b0
`define IROM_BASE       56'h80000000
`define IROM_RANGE      56'h00001FFF

`define BOOTROM_SUPPORTED 1'b1
`define BOOTROM_BASE   56'h00001000 
`define BOOTROM_RANGE  56'h00000FFF

`define UNCORE_RAM_SUPPORTED 1'b0
`define UNCORE_RAM_BASE       56'h100000000
`define UNCORE_RAM_RANGE      56'h07FFFFFF

`define EXT_MEM_SUPPORTED 1'b1
`define EXT_MEM_BASE       56'h80000000
`define EXT_MEM_RANGE      56'h07FFFFFF

`define EXT_SUPPORTED 1'b0
`define EXT_BASE       56'h80000000
`define EXT_RANGE      56'h07FFFFFF

`define CLINT_SUPPORTED 1'b1
`define CLINT_BASE  56'h02000000
`define CLINT_RANGE 56'h0000FFFF
`define GPIO_SUPPORTED 1'b1
`define GPIO_BASE   56'h10060000
`define GPIO_RANGE  56'h000000FF
`define UART_SUPPORTED 1'b1
`define UART_BASE   56'h10000000
`define UART_RANGE  56'h00000007
`define PLIC_SUPPORTED 1'b1
`define PLIC_BASE   56'h0C000000
`define PLIC_RANGE  56'h03FFFFFF
`define SDC_SUPPORTED 1'b1
`define SDC_BASE   56'h00012100
`define SDC_RANGE  56'h0000001F

// Bus Interface width
`define AHBW 64

// Test modes

// Tie GPIO outputs back to inputs
`define GPIO_LOOPBACK_TEST 0

// Hardware configuration
`define UART_PRESCALE 0

// Interrupt configuration
`define PLIC_NUM_SRC 53
`define PLIC_UART_ID 10
`define PLIC_GPIO_ID 3

`define BPRED_SUPPORTED 1
`define BPRED_TYPE "BPSPECULATIVEGSHARE" // BPLOCALPAg or BPGLOBAL or BPTWOBIT or BPGSHARE or BPSPECULATIVEGLOBAL or BPSPECULATIVEGSHARE or BPOLDGSHARE or BPOLDGSHARE2
`define TESTSBP 1
`define BPRED_SIZE 10


`define HPTW_WRITES_SUPPORTED 1

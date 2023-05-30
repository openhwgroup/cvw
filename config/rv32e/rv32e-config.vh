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

localparam PA_BITS = 34;
//localparam AHBW = 32;
//localparam XLEN = 32;
//localparam MISA = (32'h00000104 | 1 << 5 | 1 << 3 | 1 << 18 | 1 << 20 | 1 << 12 | 1 << 0 );
////localparam    BUS_SUPPORTED = 1'b1;
//localparam    ZICSR_SUPPORTED = 1'b0;
localparam    M_SUPPORTED = 1'b0;
localparam    F_SUPPORTED = 1'b0;
//localparam    ZMMUL_SUPPORTED = 1'b0;
//localparam    F_SUPPORTED = 1'b0;
//localparam    PMP_ENTRIES = 0;
localparam    LLEN =     32;
//localparam    FPGA =     1'b0;
//localparam    QEMU =     1'b0;
 //   //VPN_SEGMENT_BITS: (LLEN == 32 ? 10 : 9),
   // `include "test-shared.vh"
localparam    FLEN =     32;

`include "test-shared.vh"
 

 
// include shared configuration
//`include "wally-shared.vh"

localparam FPGA = 0;
localparam QEMU = 0;

// RV32 or RV64: XLEN = 32 or 64
localparam XLEN = 32;

// IEEE 754 compliance
localparam IEEE754 = 0;

// E
localparam MISA = (32'h00000010); 
localparam ZICSR_SUPPORTED = 0;
localparam ZIFENCEI_SUPPORTED = 0;
localparam COUNTERS = 0;
localparam ZICOUNTERS_SUPPORTED = 0;
localparam ZFH_SUPPORTED = 0;
localparam SSTC_SUPPORTED = 0;

// LSU microarchitectural Features
localparam BUS_SUPPORTED = 1;
localparam DCACHE_SUPPORTED = 0;
localparam ICACHE_SUPPORTED = 0;
localparam VIRTMEM_SUPPORTED = 0;
localparam VECTORED_INTERRUPTS_SUPPORTED = 0; 
localparam BIGENDIAN_SUPPORTED = 0;

// TLB configuration.  Entries should be a power of 2
localparam ITLB_ENTRIES = 0;
localparam DTLB_ENTRIES = 0;

// Cache configuration.  Sizes should be a power of two
// typical configuration 4 ways, 4096 bytes per way, 256 bit or more lines
localparam DCACHE_NUMWAYS = 4;
localparam DCACHE_WAYSIZEINBYTES = 4096;
localparam DCACHE_LINELENINBITS = 512;
localparam ICACHE_NUMWAYS = 4;
localparam ICACHE_WAYSIZEINBYTES = 4096;
localparam ICACHE_LINELENINBITS = 512;

// Integer Divider Configuration
// IDIV_BITSPERCYCLE must be 1, 2, or 4
localparam IDIV_BITSPERCYCLE = 1;
localparam IDIV_ON_FPU = 0;

// Legal number of PMP entries are 0, 16, or 64
localparam PMP_ENTRIES = 0;

// Address space
localparam RESET_VECTOR = 32'h80000000;

// WFI Timeout Wait
localparam WFI_TIMEOUT_BIT = 16;

// Peripheral Addresses
// Peripheral memory space extends from BASE to BASE+RANGE
// Range should be a thermometer code with 0's in the upper bits and 1s in the lower bits
localparam DTIM_SUPPORTED = 1'b0;
localparam DTIM_BASE = 34'h80000000;      
localparam DTIM_RANGE = 34'h007FFFFF;     
localparam IROM_SUPPORTED = 1'b0;
localparam IROM_BASE = 34'h80000000;     
localparam IROM_RANGE = 34'h007FFFFF;     
localparam BOOTROM_SUPPORTED = 1'b1;
localparam BOOTROM_BASE = 34'h00001000;  
localparam BOOTROM_RANGE = 34'h00000FFF; 
localparam UNCORE_RAM_SUPPORTED = 1'b1;
localparam UNCORE_RAM_BASE = 34'h80000000;      
localparam UNCORE_RAM_RANGE = 34'h07FFFFFF;     
localparam EXT_MEM_SUPPORTED = 1'b0;
localparam EXT_MEM_BASE = 34'h80000000;      
localparam EXT_MEM_RANGE = 34'h07FFFFFF;     
localparam CLINT_SUPPORTED = 1'b0;
localparam CLINT_BASE = 34'h02000000; 
localparam CLINT_RANGE = 34'h0000FFFF;
localparam GPIO_SUPPORTED = 1'b0;
localparam GPIO_BASE = 34'h10060000;  
localparam GPIO_RANGE = 34'h000000FF; 
localparam UART_SUPPORTED = 1'b0;
localparam UART_BASE = 34'h10000000;  
localparam UART_RANGE = 34'h00000007; 
localparam PLIC_SUPPORTED = 1'b0;
localparam PLIC_BASE = 34'h0C000000;  
localparam PLIC_RANGE = 34'h03FFFFFF; 
localparam SDC_SUPPORTED = 1'b0;
localparam SDC_BASE = 34'h00012100;  
localparam SDC_RANGE = 34'h0000001F; 

// Bus Interface width
localparam AHBW = 32;

// Test modes

// Tie GPIO outputs back to inputs
localparam GPIO_LOOPBACK_TEST = 1;

// Hardware configuration
localparam UART_PRESCALE = 1;

// Interrupt configuration
localparam PLIC_NUM_SRC = 10; 
// comment out the following if >=32 sources
localparam PLIC_NUM_SRC_LT_32 = (PLIC_NUM_SRC < 32);
localparam PLIC_GPIO_ID = 3;
localparam PLIC_UART_ID = 10;

localparam BPRED_SUPPORTED = 0;
localparam BPRED_TYPE = "BP_GSHARE"; // BP_GSHARE_BASIC, BP_GLOBAL, BP_GLOBAL_BASIC, BP_TWOBIT
localparam BPRED_SIZE = 10;
localparam BTB_SIZE = 10;

localparam SVADU_SUPPORTED = 0;
localparam ZMMUL_SUPPORTED = 0;

// FPU division architecture
localparam RADIX = 4;
localparam DIVCOPIES = 4;

// bit manipulation
localparam ZBA_SUPPORTED = 0;
localparam ZBB_SUPPORTED = 0;
localparam ZBC_SUPPORTED = 0;
localparam ZBS_SUPPORTED = 0;

// Memory synthesis configuration
localparam USE_SRAM = 0;
 
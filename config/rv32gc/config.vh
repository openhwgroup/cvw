//////////////////////////////////////////
// config.vh
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
// `include "wally-shared.vh"
`include "BranchPredictorType.vh"

localparam FPGA = 0;

// RV32 or RV64: XLEN = 32 or 64
localparam XLEN = 32'd32;

// IEEE 754 compliance
localparam IEEE754 = 0;

localparam MISA = (32'h00000104 | 1 << 20 | 1 << 18 | 1 << 12 | 1 << 0 | 1 <<3 | 1 << 5);
localparam ZICSR_SUPPORTED = 1;
localparam ZIFENCEI_SUPPORTED = 1;
localparam COUNTERS = 12'd32;
localparam ZICNTR_SUPPORTED = 1;
localparam ZIHPM_SUPPORTED = 1;
localparam ZFH_SUPPORTED = 0;
localparam SSTC_SUPPORTED = 1;
localparam ZICBOM_SUPPORTED = 1;
localparam ZICBOZ_SUPPORTED = 1;
localparam ZICBOP_SUPPORTED = 0;
localparam ZICCLSM_SUPPORTED = 0;
localparam SVPBMT_SUPPORTED = 0;
localparam SVNAPOT_SUPPORTED = 0;
localparam SVINVAL_SUPPORTED = 1;

// LSU microarchitectural Features
localparam BUS_SUPPORTED = 1;
localparam DCACHE_SUPPORTED = 1;
localparam ICACHE_SUPPORTED = 1;
localparam VIRTMEM_SUPPORTED = 1;
localparam VECTORED_INTERRUPTS_SUPPORTED = 1;
localparam BIGENDIAN_SUPPORTED = 1;

// TLB configuration.  Entries should be a power of 2
localparam ITLB_ENTRIES = 32'd32;
localparam DTLB_ENTRIES = 32'd32;

// Cache configuration.  Sizes should be a power of two
// typical configuration 4 ways, 4096 bytes per way, 256 bit or more lines
localparam DCACHE_NUMWAYS = 32'd4;
localparam DCACHE_WAYSIZEINBYTES = 32'd4096;
localparam DCACHE_LINELENINBITS = 32'd512;
localparam ICACHE_NUMWAYS = 32'd4;
localparam ICACHE_WAYSIZEINBYTES = 32'd4096;
localparam ICACHE_LINELENINBITS = 32'd512;

// Integer Divider Configuration
// IDIV_BITSPERCYCLE must be 1, 2, or 4
localparam IDIV_BITSPERCYCLE = 32'd4;
localparam IDIV_ON_FPU = 1;

// Legal number of PMP entries are 0, 16, or 64
localparam PMP_ENTRIES = 32'd16;

// Address space
localparam logic [63:0] RESET_VECTOR = 64'h80000000;

// WFI Timeout Wait
localparam WFI_TIMEOUT_BIT = 32'd16;

// Peripheral Addresses
// Peripheral memory space extends from BASE to BASE+RANGE
// Range should be a thermometer code with 0's in the upper bits and 1s in the lower bits
localparam DTIM_SUPPORTED = 1'b0;
localparam logic [63:0] DTIM_BASE       = 64'h80000000;
localparam logic [63:0] DTIM_RANGE      = 64'h007FFFFF;
localparam IROM_SUPPORTED = 1'b0;
localparam logic [63:0] IROM_BASE       = 64'h80000000;
localparam logic [63:0] IROM_RANGE      = 64'h007FFFFF;
localparam BOOTROM_SUPPORTED = 1'b1;
localparam logic [63:0] BOOTROM_BASE   = 64'h00001000;
localparam logic [63:0] BOOTROM_RANGE  = 64'h00000FFF;
localparam UNCORE_RAM_SUPPORTED = 1'b1;
localparam logic [63:0] UNCORE_RAM_BASE       = 64'h80000000;
localparam logic [63:0] UNCORE_RAM_RANGE      = 64'h07FFFFFF;
localparam EXT_MEM_SUPPORTED = 1'b0;
localparam logic [63:0] EXT_MEM_BASE       = 64'h80000000;
localparam logic [63:0] EXT_MEM_RANGE      = 64'h07FFFFFF;
localparam CLINT_SUPPORTED = 1'b1;
localparam logic [63:0] CLINT_BASE  = 64'h02000000;
localparam logic [63:0] CLINT_RANGE = 64'h0000FFFF;
localparam GPIO_SUPPORTED = 1'b1;
localparam logic [63:0] GPIO_BASE   = 64'h10060000;
localparam logic [63:0] GPIO_RANGE  = 64'h000000FF;
localparam UART_SUPPORTED = 1'b1;
localparam logic [63:0] UART_BASE   = 64'h10000000;
localparam logic [63:0] UART_RANGE  = 64'h00000007;
localparam PLIC_SUPPORTED = 1'b1;
localparam logic [63:0] PLIC_BASE   = 64'h0C000000;
localparam logic [63:0] PLIC_RANGE  = 64'h03FFFFFF;
localparam  SDC_SUPPORTED = 1'b0;
localparam logic [63:0] SDC_BASE =  64'h00013000;
localparam logic [63:0] SDC_RANGE = 64'h0000007F;

// Bus Interface width
localparam AHBW = 32'd32;

// Test modes

// Tie GPIO outputs back to inputs
localparam GPIO_LOOPBACK_TEST = 1;

// Hardware configuration
localparam UART_PRESCALE = 32'd1;

// Interrupt configuration
localparam PLIC_NUM_SRC = 32'd10;
// comment out the following if >=32 sources
localparam PLIC_NUM_SRC_LT_32 = (PLIC_NUM_SRC < 32);
localparam PLIC_GPIO_ID = 32'd3;
localparam PLIC_UART_ID = 32'd10;
localparam PLIC_SDC_ID = 32'd9;

localparam BPRED_SUPPORTED = 1;
// this is an annoying hack for the branch predictor parameterization override.
`ifdef BPRED_OVERRIDE
localparam BPRED_TYPE = `BPRED_TYPE;
localparam BPRED_SIZE = `BPRED_SIZE;
`else
localparam BPRED_TYPE = `BP_GSHARE; // BP_GSHARE_BASIC, BP_GLOBAL, BP_GLOBAL_BASIC, BP_TWOBIT
localparam BPRED_SIZE = 32'd10;
`endif
localparam BPRED_NUM_LHR = 32'd6;
`ifdef BTB_OVERRIDE
localparam BTB_SIZE = `BTB_SIZE;
localparam RAS_SIZE = `RAS_SIZE;
`else
localparam BTB_SIZE = 32'd10;
localparam RAS_SIZE = 32'd16;
`endif

localparam SVADU_SUPPORTED = 1;
localparam ZMMUL_SUPPORTED = 0;

// FPU division architecture
localparam RADIX = 32'd4;
localparam DIVCOPIES = 32'd4;

// bit manipulation
localparam ZBA_SUPPORTED = 1;
localparam ZBB_SUPPORTED = 1;
localparam ZBC_SUPPORTED = 1;
localparam ZBS_SUPPORTED = 1;

// New compressed instructions
localparam ZCB_SUPPORTED = 1;
localparam ZCA_SUPPORTED = 0;
localparam ZCF_SUPPORTED = 0;
localparam ZCD_SUPPORTED = 0;

// Memory synthesis configuration
localparam USE_SRAM = 0;

`include "config-shared.vh"

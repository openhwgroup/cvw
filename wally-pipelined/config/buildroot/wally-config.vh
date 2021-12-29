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
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

// include shared configuration
`include "wally-shared.vh"

`define FPGA 1
`define QEMU 1
`define BUILDROOT 1
`define BUSYBEAR 0
`define LINUX_FIX_READ {'h10000005}
`define LINUX_TEST_VECTORS "../../tests/linux-testgen/linux-testvectors/"
// RV32 or RV64: XLEN = 32 or 64
`define XLEN 64

// IEEE 754 compliance
`define IEEE754 0

`define MISA (32'h0014112D)
`define ZICSR_SUPPORTED 1
`define ZIFENCEI_SUPPORTED 1
`define ZICOUNTERS_SUPPORTED 1
`define COUNTERS 32
`define DESIGN_COMPILER 0

// Microarchitectural Features
`define UARCH_PIPELINED 1
`define UARCH_SUPERSCALR 0
`define UARCH_SINGLECYCLE 0
`define MEM_DTIM 1
`define MEM_DCACHE 1
`define MEM_IROM 1
`define MEM_ICACHE 1
`define MEM_VIRTMEM 1
`define VECTORED_INTERRUPTS_SUPPORTED 1 

// TLB configuration.  Entries should be a power of 2
`define ITLB_ENTRIES 32
`define DTLB_ENTRIES 32

// Cache configuration.  Sizes should be a power of two
// typical configuration 4 ways, 4096 bytes per way, 256 bit or more blocks
`define DCACHE_NUMWAYS 4
`define DCACHE_WAYSIZEINBYTES 4096
`define DCACHE_BLOCKLENINBITS 256
`define DCACHE_REPLBITS 3
`define ICACHE_NUMWAYS 4
`define ICACHE_WAYSIZEINBYTES 4096
`define ICACHE_BLOCKLENINBITS 256

// Integer Divider Configuration
// DIV_BITSPERCYCLE must be 1, 2, or 4
`define DIV_BITSPERCYCLE 4

// Legal number of PMP entries are 0, 16, or 64
`define PMP_ENTRIES 16

// Address space
`define RESET_VECTOR 64'h0000000000001000

// Peripheral Addresses
// Peripheral memory space extends from BASE to BASE+RANGE
// Range should be a thermometer code with 0's in the upper bits and 1s in the lower bits
`define BOOTROM_SUPPORTED 1'b1
`define BOOTROM_BASE   56'h00001000 
`define BOOTROM_RANGE  56'h00000FFF
`define RAM_SUPPORTED 1'b1
`define RAM_BASE       56'h80000000
`define RAM_RANGE      56'h07FFFFFF
`define EXT_MEM_SUPPORTED 1'b0
`define EXT_MEM_BASE       56'h80000000
`define EXT_MEM_RANGE      56'h07FFFFFF
`define CLINT_SUPPORTED 1'b1
`define CLINT_BASE  56'h02000000
`define CLINT_RANGE 56'h0000FFFF
`define GPIO_SUPPORTED 1'b1
`define GPIO_BASE   56'h10012000
`define GPIO_RANGE  56'h000000FF
`define UART_SUPPORTED 1'b1
`define UART_BASE   56'h10000000
`define UART_RANGE  56'h00000007
`define PLIC_SUPPORTED 1'b1
`define PLIC_BASE   56'h0C000000
`define PLIC_RANGE  56'h03FFFFFF
`define SDC_SUPPORTED 1'b0
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
`define PLIC_UART_ID 4

`define TWO_BIT_PRELOAD "../config/buildroot/twoBitPredictor.txt"
`define BTB_PRELOAD "../config/buildroot/BTBPredictor.txt"
`define BPRED_ENABLED 1
`define BPTYPE "BPGSHARE" // BPLOCALPAg or BPGLOBAL or BPTWOBIT or BPGSHARE
`define TESTSBP 0

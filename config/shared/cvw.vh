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


/*
// constants defining different privilege modes
// defined in Table 1.1 of the privileged spec
localparam M_MODE=(2'b11);
localparam S_MODE=(2'b01);
localparam U_MODE=(2'b00);

// Virtual Memory Constants
localparam VPN_SEGMENT_BITS = (P.XLEN == 32 ? 10 : 9)
  logic         VPN_BITS (`XLEN==32 ? (2*`VPN_SEGMENT_BITS) : (4*`VPN_SEGMENT_BITS))
  logic         PPN_BITS (`XLEN==32 ? 22 : 44)
  logic         PA_BITS (`XLEN==32 ? 34 : 56)
  logic         SVMODE_BITS (`XLEN==32 ? 1 : 4)
  logic         ASID_BASE (`XLEN==32 ? 22 : 44)
  logic         ASID_BITS (`XLEN==32 ? 9 : 16)

// constants to check SATP_MODE against
// defined in Table 4.3 of the privileged spec
  logic         NO_TRANSLATE 0
  logic         SV32 1
  logic         SV39 8
  logic         SV48 9

// macros to define supported modes
  logic         A_SUPPORTED ((`MISA >> 0) % 2 == 1)
  logic         B_SUPPORTED ((`ZBA_SUPPORTED | `ZBB_SUPPORTED | `ZBC_SUPPORTED | `ZBS_SUPPORTED)) // not based on MISA
  logic         C_SUPPORTED ((`MISA >> 2) % 2 == 1)
  logic         D_SUPPORTED ((`MISA >> 3) % 2 == 1)
  logic         E_SUPPORTED ((`MISA >> 4) % 2 == 1)
  logic         F_SUPPORTED ((`MISA >> 5) % 2 == 1)
  logic         I_SUPPORTED ((`MISA >> 8) % 2 == 1)
  logic         M_SUPPORTED ((`MISA >> 12) % 2 == 1)
  logic         Q_SUPPORTED ((`MISA >> 16) % 2 == 1)
  logic         S_SUPPORTED ((`MISA >> 18) % 2 == 1)
  logic         U_SUPPORTED ((`MISA >> 20) % 2 == 1)
// N-mode user-level interrupts are depricated per Andrew Waterman 1/13/21

// logarithm of XLEN, used for number of index bits to select
  logic         LOG_XLEN (`XLEN == 32 ? 5 : 6)

// Number of 64 bit PMP Configuration Register entries (or pairs of 32 bit entries)
  logic         PMPCFG_ENTRIES (`PMP_ENTRIES/8)

// Floating point constants for Quad, Double, Single, and Half precisions
  logic         Q_LEN 32'd128
  logic         Q_NE 32'd15
  logic         Q_NF 32'd112
  logic         Q_BIAS 32'd16383
  logic         Q_FMT 2'd3
  logic         D_LEN 32'd64
  logic         D_NE 32'd11
  logic         D_NF 32'd52
  logic         D_BIAS 32'd1023
  logic         D_FMT 2'd1
  logic         S_LEN 32'd32
  logic         S_NE 32'd8
  logic         S_NF 32'd23
  logic         S_BIAS 32'd127
  logic         S_FMT 2'd0
  logic         H_LEN 32'd16
  logic         H_NE 32'd5
  logic         H_NF 32'd10
  logic         H_BIAS 32'd15
  logic         H_FMT 2'd2

// Floating point length FLEN and number of exponent (NE) and fraction (NF) bits
  logic         FLEN (`Q_SUPPORTED ? `Q_LEN  : `D_SUPPORTED ? `D_LEN  : `S_LEN)
  logic         NE   (`Q_SUPPORTED ? `Q_NE   : `D_SUPPORTED ? `D_NE   : `S_NE)
  logic         NF   (`Q_SUPPORTED ? `Q_NF   : `D_SUPPORTED ? `D_NF   : `S_NF)
  logic         FMT  (`Q_SUPPORTED ? 2'd3    : `D_SUPPORTED ? 2'd1    : 2'd0)
  logic         BIAS (`Q_SUPPORTED ? `Q_BIAS : `D_SUPPORTED ? `D_BIAS : `S_BIAS)


// Floating point constants needed for FPU paramerterization
  logic         FPSIZES ((32)'(`Q_SUPPORTED)+(32)'(`D_SUPPORTED)+(32)'(`F_SUPPORTED)+(32)'(`ZFH_SUPPORTED))
  logic         FMTBITS ((32)'(`FPSIZES>=3)+1)
  logic         LEN1  ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_LEN  : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_LEN  : `H_LEN)
  logic         NE1   ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NE   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NE   : `H_NE)
  logic         NF1   ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NF   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NF   : `H_NF)
  logic         FMT1  ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? 2'd1    : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? 2'd0    : 2'd2)
  logic         BIAS1 ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_BIAS : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_BIAS : `H_BIAS)
  logic         LEN2  ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_LEN  : `H_LEN)
  logic         NE2   ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NE   : `H_NE)
  logic         NF2   ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NF   : `H_NF)
  logic         FMT2  ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? 2'd0    : 2'd2)
  logic         BIAS2 ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_BIAS : `H_BIAS)

// largest length in IEU/FPU
  logic         CVTLEN ((`NF<`XLEN) ? (`XLEN) : (`NF))
  logic         LLEN (($unsigned(`FLEN)<$unsigned(`XLEN)) ? ($unsigned(`XLEN)) : ($unsigned(`FLEN)))
  logic         LOGCVTLEN $unsigned($clog2(`CVTLEN+1))
  logic         NORMSHIFTSZ (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVb + 1 +`NF+1) > (3*`NF+6) ? (`DIVb + 1 +`NF+1) : (3*`NF+6)))
  logic         LOGNORMSHIFTSZ ($clog2(`NORMSHIFTSZ))
  logic         CORRSHIFTSZ (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVN+1+`NF) > (3*`NF+4) ? (`DIVN+1+`NF) : (3*`NF+4)))

// division constants

  logic         DIVN        (((`NF<`XLEN) & `IDIV_ON_FPU) ? `XLEN : `NF+2) // standard length of input
  logic         LOGR        ($clog2(`RADIX))            // r = log(R)
  logic         RK          (`LOGR*`DIVCOPIES)          // r*k used for intdiv preproc
  logic         LOGRK       ($clog2(`RK))               // log2(r*k)
  logic         FPDUR       ((`DIVN+1+(`LOGR*`DIVCOPIES))/(`LOGR*`DIVCOPIES)+(`RADIX/4))
  logic         DURLEN      ($clog2(`FPDUR+1))
  logic         DIVb        (`FPDUR*`LOGR*`DIVCOPIES-1) // canonical fdiv size (b)
  logic         DIVBLEN     ($clog2(`DIVb+1)-1)
  logic         DIVa        (`DIVb+1-`XLEN)             // used for idiv on fpu
 */

// Disable spurious Verilator warnings

/* verilator lint_off STMTDLY */
/* verilator lint_off ASSIGNDLY */
/* verilator lint_off PINCONNECTEMPTY */


endpackage

/*
// Place configuration in a package
package cvw;
  parameter XLEN = `XLEN;
  parameter FPGA = `FPGA;
  parameter QEMU = `QEMU;
  parameter IEEE754 = `IEEE754;
  parameter MISA = `MISA;
  parameter ZICSR_SUPPORTED = `ZICSR_SUPPORTED;
  parameter ZIFENCEI_SUPPORTED = `ZIFENCEI_SUPPORTED;
  parameter COUNTERS = `COUNTERS;
  parameter ZICOUNTERS_SUPPORTED = `ZICOUNTERS_SUPPORTED;
  parameter ZFH_SUPPORTED = `ZFH_SUPPORTED;
  parameter BUS_SUPPORTED = `BUS_SUPPORTED;
  parameter DCACHE_SUPPORTED = `DCACHE_SUPPORTED;
  parameter ICACHE_SUPPORTED = `ICACHE_SUPPORTED;
  parameter VIRTMEM_SUPPORTED = `VIRTMEM_SUPPORTED;
  parameter VECTORED_INTERRUPTS_SUPPORTED = `VECTORED_INTERRUPTS_SUPPORTED;
  parameter BIGENDIAN_SUPPORTED = `BIGENDIAN_SUPPORTED;
  parameter ITLB_ENTRIES = `ITLB_ENTRIES;
  parameter DTLB_ENTRIES = `DTLB_ENTRIES;
  parameter DCACHE_NUMWAYS = `DCACHE_NUMWAYS;
  parameter DCACHE_WAYSIZEINBYTES = `DCACHE_WAYSIZEINBYTES;
  parameter DCACHE_LINELENINBITS = `DCACHE_LINELENINBITS;
  parameter ICACHE_NUMWAYS = `ICACHE_NUMWAYS;
  parameter ICACHE_WAYSIZEINBYTES = `ICACHE_WAYSIZEINBYTES;
  parameter ICACHE_LINELENINBITS = `ICACHE_LINELENINBITS;
  parameter IDIV_BITSPERCYCLE = `IDIV_BITSPERCYCLE;
  parameter IDIV_ON_FPU = `IDIV_ON_FPU;
  parameter PMP_ENTRIES = `PMP_ENTRIES;
  parameter RESET_VECTOR = `RESET_VECTOR;
  parameter WFI_TIMEOUT_BIT = `WFI_TIMEOUT_BIT;
  parameter DTIM_SUPPORTED = `DTIM_SUPPORTED;
  parameter DTIM_BASE = `DTIM_BASE;
  parameter DTIM_RANGE = `DTIM_RANGE;
  parameter IROM_SUPPORTED = `IROM_SUPPORTED;
  parameter IROM_BASE = `IROM_BASE;
  parameter IROM_RANGE = `IROM_RANGE;
  parameter BOOTROM_SUPPORTED = `BOOTROM_SUPPORTED;
  parameter BOOTROM_BASE = `BOOTROM_BASE;
  parameter BOOTROM_RANGE = `BOOTROM_RANGE;
  parameter UNCORE_RAM_SUPPORTED = `UNCORE_RAM_SUPPORTED;
  parameter UNCORE_RAM_BASE = `UNCORE_RAM_BASE;
  parameter UNCORE_RAM_RANGE = `UNCORE_RAM_RANGE;
  parameter EXT_MEM_SUPPORTED = `EXT_MEM_SUPPORTED;
  parameter EXT_MEM_BASE = `EXT_MEM_BASE;
  parameter EXT_MEM_RANGE = `EXT_MEM_RANGE;
  parameter CLINT_SUPPORTED = `CLINT_SUPPORTED;
  parameter CLINT_BASE = `CLINT_BASE;
  parameter CLINT_RANGE = `CLINT_RANGE;
  parameter GPIO_SUPPORTED = `GPIO_SUPPORTED;
  parameter GPIO_BASE = `GPIO_BASE;
  parameter GPIO_RANGE = `GPIO_RANGE;
  parameter UART_SUPPORTED = `UART_SUPPORTED;
  parameter UART_BASE = `UART_BASE;
  parameter UART_RANGE = `UART_RANGE;
  parameter PLIC_SUPPORTED = `PLIC_SUPPORTED;
  parameter PLIC_BASE = `PLIC_BASE;
  parameter PLIC_RANGE = `PLIC_RANGE;
  parameter SDC_SUPPORTED = `SDC_SUPPORTED;
  parameter SDC_BASE = `SDC_BASE;
  parameter SDC_RANGE = `SDC_RANGE;
  parameter AHBW = `AHBW;
  parameter GPIO_LOOPBACK_TEST = `GPIO_LOOPBACK_TEST;
  parameter UART_PRESCALE = `UART_PRESCALE;
  parameter PLIC_NUM_SRC = `PLIC_NUM_SRC;
  parameter PLIC_GPIO_ID = `PLIC_GPIO_ID;
  parameter PLIC_UART_ID = `PLIC_UART_ID;
  parameter BPRED_SUPPORTED = `BPRED_SUPPORTED;
  parameter BPRED_TYPE = `BPRED_TYPE;
  parameter BPRED_SIZE = `BPRED_SIZE;
  parameter SVADU_SUPPORTED = `SVADU_SUPPORTED;
//  parameter  = `;


  // Shared parameters

  // constants defining different privilege modes
  // defined in Table 1.1 of the privileged spec
  parameter M_MODE = (2'b11);
  parameter S_MODE = (2'b01);
  parameter U_MODE = (2'b00);

  // Virtual Memory Constants
  parameter VPN_SEGMENT_BITS = (`XLEN == 32 ? 10 : 9);
  parameter VPN_BITS = (`XLEN==32 ? (2*`VPN_SEGMENT_BITS) : (4*`VPN_SEGMENT_BITS));
  parameter PPN_BITS = (`XLEN==32 ? 22 : 44);
  parameter PA_BITS = (`XLEN==32 ? 34 : 56);
  parameter SVMODE_BITS = (`XLEN==32 ? 1 : 4);
  parameter ASID_BASE = (`XLEN==32 ? 22 : 44);
  parameter ASID_BITS = (`XLEN==32 ? 9 : 16);

  // constants to check SATP_MODE against
  // defined in Table 4.3 of the privileged spec
  parameter NO_TRANSLATE = 0;
  parameter SV32 = 1;
  parameter SV39 = 8;
  parameter SV48 = 9;

  // macros to define supported modes
  parameter A_SUPPORTED = ((`MISA >> 0) % 2 == 1);
  parameter B_SUPPORTED = ((`ZBA_SUPPORTED | `ZBB_SUPPORTED | `ZBC_SUPPORTED | `ZBS_SUPPORTED)); // not based on MISA
  parameter C_SUPPORTED = ((`MISA >> 2) % 2 == 1);
  parameter D_SUPPORTED = ((`MISA >> 3) % 2 == 1);
  parameter E_SUPPORTED = ((`MISA >> 4) % 2 == 1);
  parameter F_SUPPORTED = ((`MISA >> 5) % 2 == 1);
  parameter I_SUPPORTED = ((`MISA >> 8) % 2 == 1);
  parameter M_SUPPORTED = ((`MISA >> 12) % 2 == 1);
  parameter Q_SUPPORTED = ((`MISA >> 16) % 2 == 1);
  parameter S_SUPPORTED = ((`MISA >> 18) % 2 == 1);
  parameter U_SUPPORTED = ((`MISA >> 20) % 2 == 1);
  // N-mode user-level interrupts are depricated per Andrew Waterman 1/13/21

  // logarithm of XLEN, used for number of index bits to select
  parameter LOG_XLEN = (`XLEN == 32 ? 5 : 6);

  // Number of 64 bit PMP Configuration Register entries (or pairs of 32 bit entries)
  parameter PMPCFG_ENTRIES = (`PMP_ENTRIES/8);

  // Floating point constants for Quad, Double, Single, and Half precisions
  parameter Q_LEN = 32'd128;
  parameter Q_NE = 32'd15;
  parameter Q_NF = 32'd112;
  parameter Q_BIAS = 32'd16383;
  parameter Q_FMT = 2'd3;
  parameter D_LEN = 32'd64;
  parameter D_NE = 32'd11;
  parameter D_NF = 32'd52;
  parameter D_BIAS = 32'd1023;
  parameter D_FMT = 2'd1;
  parameter S_LEN = 32'd32;
  parameter S_NE = 32'd8;
  parameter S_NF = 32'd23;
  parameter S_BIAS = 32'd127;
  parameter S_FMT = 2'd0;
  parameter H_LEN = 32'd16;
  parameter H_NE = 32'd5;
  parameter H_NF = 32'd10;
  parameter H_BIAS = 32'd15;
  parameter H_FMT = 2'd2;

  // Floating point length FLEN and number of exponent (NE) and fraction (NF) bits
  parameter FLEN = (`Q_SUPPORTED ? `Q_LEN  : `D_SUPPORTED ? `D_LEN  : `S_LEN);
  parameter NE   = (`Q_SUPPORTED ? `Q_NE   : `D_SUPPORTED ? `D_NE   : `S_NE);
  parameter NF   = (`Q_SUPPORTED ? `Q_NF   : `D_SUPPORTED ? `D_NF   : `S_NF);
  parameter FMT  = (`Q_SUPPORTED ? 2'd3    : `D_SUPPORTED ? 2'd1    : 2'd0);
  parameter BIAS = (`Q_SUPPORTED ? `Q_BIAS : `D_SUPPORTED ? `D_BIAS : `S_BIAS);
  
  // Floating point constants needed for FPU paramerterization
  parameter FPSIZES = ((32)'(`Q_SUPPORTED)+(32)'(`D_SUPPORTED)+(32)'(`F_SUPPORTED)+(32)'(`ZFH_SUPPORTED));
  parameter FMTBITS = ((32)'(`FPSIZES>=3)+1);
  parameter LEN1  = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_LEN  : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_LEN  : `H_LEN);
  parameter NE1   = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NE   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NE   : `H_NE);
  parameter NF1   = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NF   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NF   : `H_NF);
  parameter FMT1  = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? 2'd1    : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? 2'd0    : 2'd2);
  parameter BIAS1 = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_BIAS : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_BIAS : `H_BIAS);
  parameter LEN2  = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_LEN  : `H_LEN);
  parameter NE2   = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NE   : `H_NE);
  parameter NF2   = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NF   : `H_NF);
  parameter FMT2  = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? 2'd0    : 2'd2);
  parameter BIAS2 = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_BIAS : `H_BIAS);

  // largest length in IEU/FPU
  parameter CVTLEN = ((`NF<`XLEN) ? (`XLEN) : (`NF));
  parameter LLEN = ((`FLEN<`XLEN) ? (`XLEN) : (`FLEN));
  parameter LOGCVTLEN = $unsigned($clog2(`CVTLEN+1));
  parameter NORMSHIFTSZ = (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVb + 1 +`NF+1) > (3*`NF+6) ? (`DIVb + 1 +`NF+1) : (3*`NF+6)));
  parameter LOGNORMSHIFTSZ = ($clog2(`NORMSHIFTSZ));
  parameter CORRSHIFTSZ = (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVN+1+`NF) > (3*`NF+4) ? (`DIVN+1+`NF) : (3*`NF+4)));

  // division constants

  parameter DIVN        = (((`NF<`XLEN) & `IDIV_ON_FPU) ? `XLEN : `NF+2); // standard length of input
  parameter LOGR        = ($clog2(`RADIX));            // r = log(R)
  parameter RK          = (`LOGR*`DIVCOPIES);          // r*k used for intdiv preproc
  parameter LOGRK       = ($clog2(`RK));               // log2(r*k)
  parameter FPDUR       = ((`DIVN+1+(`LOGR*`DIVCOPIES))/(`LOGR*`DIVCOPIES)+(`RADIX/4));
  parameter DURLEN      = ($clog2(`FPDUR+1));
  parameter DIVb        = (`FPDUR*`LOGR*`DIVCOPIES-1); // canonical fdiv size (b)
  parameter DIVBLEN     = ($clog2(`DIVb+1)-1);
  parameter DIVa        = (`DIVb+1-`XLEN);             // used for idiv on fpu

endpackage
*/
 /*
typedef struct packed {
  byte          XLEN;   // Machine width (32 or 64)
  byte          FPGA;   // Modifications to tare
  byte          QEMU;   // Hacks to agree with QEMU during Linux boot
  byte          AHBW;   // AHB bus width (usually = XLEN)
  byte          PA_BITS;  // size of physical address
  logic [31:0] MISA;
  logic BUS_SUPPORTED;
  logic ZICSR_SUPPORTED;
  logic M_SUPPORTED;
  logic ZMMUL_SUPPORTED;
  logic F_SUPPORTED;
  logic [7:0] PMP_ENTRIES;
  logic [63:0] LLEN;
  logic [63:0] FLEN;
  logic [7:0] VPN_SEGMENT_BITS;
} cvw_t;

`define FPGA 0
`define QEMU 0

// RV32 or RV64: XLEN = 32 or 64
`define XLEN 32

// IEEE 754 compliance
`define IEEE754 0

// E
`define MISA (32'h00000010) 
`define ZICSR_SUPPORTED 0
`define ZIFENCEI_SUPPORTED 0
`define COUNTERS 0
`define ZICOUNTERS_SUPPORTED 0
`define ZFH_SUPPORTED 0
`define SSTC_SUPPORTED 0

// LSU microarchitectural Features
`define BUS_SUPPORTED 1
`define DCACHE_SUPPORTED 0
`define ICACHE_SUPPORTED 0
`define VIRTMEM_SUPPORTED 0
`define VECTORED_INTERRUPTS_SUPPORTED 0 
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
`define IDIV_BITSPERCYCLE 1
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
`define DTIM_SUPPORTED 1'b0
`define DTIM_BASE       34'h80000000
`define DTIM_RANGE      34'h007FFFFF
`define IROM_SUPPORTED 1'b0
`define IROM_BASE       34'h80000000
`define IROM_RANGE      34'h007FFFFF
`define BOOTROM_SUPPORTED 1'b1
`define BOOTROM_BASE   34'h00001000 
`define BOOTROM_RANGE  34'h00000FFF
`define UNCORE_RAM_SUPPORTED 1'b1
`define UNCORE_RAM_BASE       34'h80000000
`define UNCORE_RAM_RANGE      34'h07FFFFFF
`define EXT_MEM_SUPPORTED 1'b0
`define EXT_MEM_BASE       34'h80000000
`define EXT_MEM_RANGE      34'h07FFFFFF
`define CLINT_SUPPORTED 1'b0
`define CLINT_BASE  34'h02000000
`define CLINT_RANGE 34'h0000FFFF
`define GPIO_SUPPORTED 1'b0
`define GPIO_BASE   34'h10060000
`define GPIO_RANGE  34'h000000FF
`define UART_SUPPORTED 1'b0
`define UART_BASE   34'h10000000
`define UART_RANGE  34'h00000007
`define PLIC_SUPPORTED 1'b0
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

`define SVADU_SUPPORTED 0
`define ZMMUL_SUPPORTED 0

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

/*
// constants defining different privilege modes
// defined in Table 1.1 of the privileged spec
localparam M_MODE=(2'b11);
localparam S_MODE=(2'b01);
localparam U_MODE=(2'b00);

// Virtual Memory Constants
localparam VPN_SEGMENT_BITS = (P.XLEN == 32 ? 10 : 9)
`define VPN_BITS (`XLEN==32 ? (2*`VPN_SEGMENT_BITS) : (4*`VPN_SEGMENT_BITS))
`define PPN_BITS (`XLEN==32 ? 22 : 44)
`define PA_BITS (`XLEN==32 ? 34 : 56)
`define SVMODE_BITS (`XLEN==32 ? 1 : 4)
`define ASID_BASE (`XLEN==32 ? 22 : 44)
`define ASID_BITS (`XLEN==32 ? 9 : 16)

// constants to check SATP_MODE against
// defined in Table 4.3 of the privileged spec
`define NO_TRANSLATE 0
`define SV32 1
`define SV39 8
`define SV48 9

// macros to define supported modes
`define A_SUPPORTED ((`MISA >> 0) % 2 == 1)
`define B_SUPPORTED ((`ZBA_SUPPORTED | `ZBB_SUPPORTED | `ZBC_SUPPORTED | `ZBS_SUPPORTED)) // not based on MISA
`define C_SUPPORTED ((`MISA >> 2) % 2 == 1)
`define D_SUPPORTED ((`MISA >> 3) % 2 == 1)
`define E_SUPPORTED ((`MISA >> 4) % 2 == 1)
`define F_SUPPORTED ((`MISA >> 5) % 2 == 1)
`define I_SUPPORTED ((`MISA >> 8) % 2 == 1)
`define M_SUPPORTED ((`MISA >> 12) % 2 == 1)
`define Q_SUPPORTED ((`MISA >> 16) % 2 == 1)
`define S_SUPPORTED ((`MISA >> 18) % 2 == 1)
`define U_SUPPORTED ((`MISA >> 20) % 2 == 1)
// N-mode user-level interrupts are depricated per Andrew Waterman 1/13/21

// logarithm of XLEN, used for number of index bits to select
`define LOG_XLEN (`XLEN == 32 ? 5 : 6)

// Number of 64 bit PMP Configuration Register entries (or pairs of 32 bit entries)
`define PMPCFG_ENTRIES (`PMP_ENTRIES/8)

// Floating point constants for Quad, Double, Single, and Half precisions
`define Q_LEN 32'd128
`define Q_NE 32'd15
`define Q_NF 32'd112
`define Q_BIAS 32'd16383
`define Q_FMT 2'd3
`define D_LEN 32'd64
`define D_NE 32'd11
`define D_NF 32'd52
`define D_BIAS 32'd1023
`define D_FMT 2'd1
`define S_LEN 32'd32
`define S_NE 32'd8
`define S_NF 32'd23
`define S_BIAS 32'd127
`define S_FMT 2'd0
`define H_LEN 32'd16
`define H_NE 32'd5
`define H_NF 32'd10
`define H_BIAS 32'd15
`define H_FMT 2'd2

// Floating point length FLEN and number of exponent (NE) and fraction (NF) bits
`define FLEN (`Q_SUPPORTED ? `Q_LEN  : `D_SUPPORTED ? `D_LEN  : `S_LEN)
`define NE   (`Q_SUPPORTED ? `Q_NE   : `D_SUPPORTED ? `D_NE   : `S_NE)
`define NF   (`Q_SUPPORTED ? `Q_NF   : `D_SUPPORTED ? `D_NF   : `S_NF)
`define FMT  (`Q_SUPPORTED ? 2'd3    : `D_SUPPORTED ? 2'd1    : 2'd0)
`define BIAS (`Q_SUPPORTED ? `Q_BIAS : `D_SUPPORTED ? `D_BIAS : `S_BIAS)


// Floating point constants needed for FPU paramerterization
`define FPSIZES ((32)'(`Q_SUPPORTED)+(32)'(`D_SUPPORTED)+(32)'(`F_SUPPORTED)+(32)'(`ZFH_SUPPORTED))
`define FMTBITS ((32)'(`FPSIZES>=3)+1)
`define LEN1  ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_LEN  : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_LEN  : `H_LEN)
`define NE1   ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NE   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NE   : `H_NE)
`define NF1   ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NF   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NF   : `H_NF)
`define FMT1  ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? 2'd1    : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? 2'd0    : 2'd2)
`define BIAS1 ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_BIAS : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_BIAS : `H_BIAS)
`define LEN2  ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_LEN  : `H_LEN)
`define NE2   ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NE   : `H_NE)
`define NF2   ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NF   : `H_NF)
`define FMT2  ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? 2'd0    : 2'd2)
`define BIAS2 ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_BIAS : `H_BIAS)

// largest length in IEU/FPU
`define CVTLEN ((`NF<`XLEN) ? (`XLEN) : (`NF))
`define LLEN (($unsigned(`FLEN)<$unsigned(`XLEN)) ? ($unsigned(`XLEN)) : ($unsigned(`FLEN)))
`define LOGCVTLEN $unsigned($clog2(`CVTLEN+1))
`define NORMSHIFTSZ (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVb + 1 +`NF+1) > (3*`NF+6) ? (`DIVb + 1 +`NF+1) : (3*`NF+6)))
`define LOGNORMSHIFTSZ ($clog2(`NORMSHIFTSZ))
`define CORRSHIFTSZ (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVN+1+`NF) > (3*`NF+4) ? (`DIVN+1+`NF) : (3*`NF+4)))

// division constants

`define DIVN        (((`NF<`XLEN) & `IDIV_ON_FPU) ? `XLEN : `NF+2) // standard length of input
`define LOGR        ($clog2(`RADIX))            // r = log(R)
`define RK          (`LOGR*`DIVCOPIES)          // r*k used for intdiv preproc
`define LOGRK       ($clog2(`RK))               // log2(r*k)
`define FPDUR       ((`DIVN+1+(`LOGR*`DIVCOPIES))/(`LOGR*`DIVCOPIES)+(`RADIX/4))
`define DURLEN      ($clog2(`FPDUR+1))
`define DIVb        (`FPDUR*`LOGR*`DIVCOPIES-1) // canonical fdiv size (b)
`define DIVBLEN     ($clog2(`DIVb+1)-1)
`define DIVa        (`DIVb+1-`XLEN)             // used for idiv on fpu
 */

// Disable spurious Verilator warnings

/* verilator lint_off STMTDLY */
/* verilator lint_off ASSIGNDLY */
/* verilator lint_off PINCONNECTEMPTY */


/*
// Place configuration in a package
package cvw;
  parameter XLEN = `XLEN;
  parameter FPGA = `FPGA;
  parameter QEMU = `QEMU;
  parameter IEEE754 = `IEEE754;
  parameter MISA = `MISA;
  parameter ZICSR_SUPPORTED = `ZICSR_SUPPORTED;
  parameter ZIFENCEI_SUPPORTED = `ZIFENCEI_SUPPORTED;
  parameter COUNTERS = `COUNTERS;
  parameter ZICOUNTERS_SUPPORTED = `ZICOUNTERS_SUPPORTED;
  parameter ZFH_SUPPORTED = `ZFH_SUPPORTED;
  parameter BUS_SUPPORTED = `BUS_SUPPORTED;
  parameter DCACHE_SUPPORTED = `DCACHE_SUPPORTED;
  parameter ICACHE_SUPPORTED = `ICACHE_SUPPORTED;
  parameter VIRTMEM_SUPPORTED = `VIRTMEM_SUPPORTED;
  parameter VECTORED_INTERRUPTS_SUPPORTED = `VECTORED_INTERRUPTS_SUPPORTED;
  parameter BIGENDIAN_SUPPORTED = `BIGENDIAN_SUPPORTED;
  parameter ITLB_ENTRIES = `ITLB_ENTRIES;
  parameter DTLB_ENTRIES = `DTLB_ENTRIES;
  parameter DCACHE_NUMWAYS = `DCACHE_NUMWAYS;
  parameter DCACHE_WAYSIZEINBYTES = `DCACHE_WAYSIZEINBYTES;
  parameter DCACHE_LINELENINBITS = `DCACHE_LINELENINBITS;
  parameter ICACHE_NUMWAYS = `ICACHE_NUMWAYS;
  parameter ICACHE_WAYSIZEINBYTES = `ICACHE_WAYSIZEINBYTES;
  parameter ICACHE_LINELENINBITS = `ICACHE_LINELENINBITS;
  parameter IDIV_BITSPERCYCLE = `IDIV_BITSPERCYCLE;
  parameter IDIV_ON_FPU = `IDIV_ON_FPU;
  parameter PMP_ENTRIES = `PMP_ENTRIES;
  parameter RESET_VECTOR = `RESET_VECTOR;
  parameter WFI_TIMEOUT_BIT = `WFI_TIMEOUT_BIT;
  parameter DTIM_SUPPORTED = `DTIM_SUPPORTED;
  parameter DTIM_BASE = `DTIM_BASE;
  parameter DTIM_RANGE = `DTIM_RANGE;
  parameter IROM_SUPPORTED = `IROM_SUPPORTED;
  parameter IROM_BASE = `IROM_BASE;
  parameter IROM_RANGE = `IROM_RANGE;
  parameter BOOTROM_SUPPORTED = `BOOTROM_SUPPORTED;
  parameter BOOTROM_BASE = `BOOTROM_BASE;
  parameter BOOTROM_RANGE = `BOOTROM_RANGE;
  parameter UNCORE_RAM_SUPPORTED = `UNCORE_RAM_SUPPORTED;
  parameter UNCORE_RAM_BASE = `UNCORE_RAM_BASE;
  parameter UNCORE_RAM_RANGE = `UNCORE_RAM_RANGE;
  parameter EXT_MEM_SUPPORTED = `EXT_MEM_SUPPORTED;
  parameter EXT_MEM_BASE = `EXT_MEM_BASE;
  parameter EXT_MEM_RANGE = `EXT_MEM_RANGE;
  parameter CLINT_SUPPORTED = `CLINT_SUPPORTED;
  parameter CLINT_BASE = `CLINT_BASE;
  parameter CLINT_RANGE = `CLINT_RANGE;
  parameter GPIO_SUPPORTED = `GPIO_SUPPORTED;
  parameter GPIO_BASE = `GPIO_BASE;
  parameter GPIO_RANGE = `GPIO_RANGE;
  parameter UART_SUPPORTED = `UART_SUPPORTED;
  parameter UART_BASE = `UART_BASE;
  parameter UART_RANGE = `UART_RANGE;
  parameter PLIC_SUPPORTED = `PLIC_SUPPORTED;
  parameter PLIC_BASE = `PLIC_BASE;
  parameter PLIC_RANGE = `PLIC_RANGE;
  parameter SDC_SUPPORTED = `SDC_SUPPORTED;
  parameter SDC_BASE = `SDC_BASE;
  parameter SDC_RANGE = `SDC_RANGE;
  parameter AHBW = `AHBW;
  parameter GPIO_LOOPBACK_TEST = `GPIO_LOOPBACK_TEST;
  parameter UART_PRESCALE = `UART_PRESCALE;
  parameter PLIC_NUM_SRC = `PLIC_NUM_SRC;
  parameter PLIC_GPIO_ID = `PLIC_GPIO_ID;
  parameter PLIC_UART_ID = `PLIC_UART_ID;
  parameter BPRED_SUPPORTED = `BPRED_SUPPORTED;
  parameter BPRED_TYPE = `BPRED_TYPE;
  parameter BPRED_SIZE = `BPRED_SIZE;
  parameter SVADU_SUPPORTED = `SVADU_SUPPORTED;
//  parameter  = `;


  // Shared parameters

  // constants defining different privilege modes
  // defined in Table 1.1 of the privileged spec
  parameter M_MODE = (2'b11);
  parameter S_MODE = (2'b01);
  parameter U_MODE = (2'b00);

  // Virtual Memory Constants
  parameter VPN_SEGMENT_BITS = (`XLEN == 32 ? 10 : 9);
  parameter VPN_BITS = (`XLEN==32 ? (2*`VPN_SEGMENT_BITS) : (4*`VPN_SEGMENT_BITS));
  parameter PPN_BITS = (`XLEN==32 ? 22 : 44);
  parameter PA_BITS = (`XLEN==32 ? 34 : 56);
  parameter SVMODE_BITS = (`XLEN==32 ? 1 : 4);
  parameter ASID_BASE = (`XLEN==32 ? 22 : 44);
  parameter ASID_BITS = (`XLEN==32 ? 9 : 16);

  // constants to check SATP_MODE against
  // defined in Table 4.3 of the privileged spec
  parameter NO_TRANSLATE = 0;
  parameter SV32 = 1;
  parameter SV39 = 8;
  parameter SV48 = 9;

  // macros to define supported modes
  parameter A_SUPPORTED = ((`MISA >> 0) % 2 == 1);
  parameter B_SUPPORTED = ((`ZBA_SUPPORTED | `ZBB_SUPPORTED | `ZBC_SUPPORTED | `ZBS_SUPPORTED)); // not based on MISA
  parameter C_SUPPORTED = ((`MISA >> 2) % 2 == 1);
  parameter D_SUPPORTED = ((`MISA >> 3) % 2 == 1);
  parameter E_SUPPORTED = ((`MISA >> 4) % 2 == 1);
  parameter F_SUPPORTED = ((`MISA >> 5) % 2 == 1);
  parameter I_SUPPORTED = ((`MISA >> 8) % 2 == 1);
  parameter M_SUPPORTED = ((`MISA >> 12) % 2 == 1);
  parameter Q_SUPPORTED = ((`MISA >> 16) % 2 == 1);
  parameter S_SUPPORTED = ((`MISA >> 18) % 2 == 1);
  parameter U_SUPPORTED = ((`MISA >> 20) % 2 == 1);
  // N-mode user-level interrupts are depricated per Andrew Waterman 1/13/21

  // logarithm of XLEN, used for number of index bits to select
  parameter LOG_XLEN = (`XLEN == 32 ? 5 : 6);

  // Number of 64 bit PMP Configuration Register entries (or pairs of 32 bit entries)
  parameter PMPCFG_ENTRIES = (`PMP_ENTRIES/8);

  // Floating point constants for Quad, Double, Single, and Half precisions
  parameter Q_LEN = 32'd128;
  parameter Q_NE = 32'd15;
  parameter Q_NF = 32'd112;
  parameter Q_BIAS = 32'd16383;
  parameter Q_FMT = 2'd3;
  parameter D_LEN = 32'd64;
  parameter D_NE = 32'd11;
  parameter D_NF = 32'd52;
  parameter D_BIAS = 32'd1023;
  parameter D_FMT = 2'd1;
  parameter S_LEN = 32'd32;
  parameter S_NE = 32'd8;
  parameter S_NF = 32'd23;
  parameter S_BIAS = 32'd127;
  parameter S_FMT = 2'd0;
  parameter H_LEN = 32'd16;
  parameter H_NE = 32'd5;
  parameter H_NF = 32'd10;
  parameter H_BIAS = 32'd15;
  parameter H_FMT = 2'd2;

  // Floating point length FLEN and number of exponent (NE) and fraction (NF) bits
  parameter FLEN = (`Q_SUPPORTED ? `Q_LEN  : `D_SUPPORTED ? `D_LEN  : `S_LEN);
  parameter NE   = (`Q_SUPPORTED ? `Q_NE   : `D_SUPPORTED ? `D_NE   : `S_NE);
  parameter NF   = (`Q_SUPPORTED ? `Q_NF   : `D_SUPPORTED ? `D_NF   : `S_NF);
  parameter FMT  = (`Q_SUPPORTED ? 2'd3    : `D_SUPPORTED ? 2'd1    : 2'd0);
  parameter BIAS = (`Q_SUPPORTED ? `Q_BIAS : `D_SUPPORTED ? `D_BIAS : `S_BIAS);
  
  // Floating point constants needed for FPU paramerterization
  parameter FPSIZES = ((32)'(`Q_SUPPORTED)+(32)'(`D_SUPPORTED)+(32)'(`F_SUPPORTED)+(32)'(`ZFH_SUPPORTED));
  parameter FMTBITS = ((32)'(`FPSIZES>=3)+1);
  parameter LEN1  = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_LEN  : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_LEN  : `H_LEN);
  parameter NE1   = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NE   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NE   : `H_NE);
  parameter NF1   = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_NF   : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_NF   : `H_NF);
  parameter FMT1  = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? 2'd1    : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? 2'd0    : 2'd2);
  parameter BIAS1 = ((`D_SUPPORTED & (`FLEN != `D_LEN)) ? `D_BIAS : (`F_SUPPORTED & (`FLEN != `S_LEN)) ? `S_BIAS : `H_BIAS);
  parameter LEN2  = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_LEN  : `H_LEN);
  parameter NE2   = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NE   : `H_NE);
  parameter NF2   = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_NF   : `H_NF);
  parameter FMT2  = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? 2'd0    : 2'd2);
  parameter BIAS2 = ((`F_SUPPORTED & (`LEN1 != `S_LEN)) ? `S_BIAS : `H_BIAS);

  // largest length in IEU/FPU
  parameter CVTLEN = ((`NF<`XLEN) ? (`XLEN) : (`NF));
  parameter LLEN = ((`FLEN<`XLEN) ? (`XLEN) : (`FLEN));
  parameter LOGCVTLEN = $unsigned($clog2(`CVTLEN+1));
  parameter NORMSHIFTSZ = (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVb + 1 +`NF+1) > (3*`NF+6) ? (`DIVb + 1 +`NF+1) : (3*`NF+6)));
  parameter LOGNORMSHIFTSZ = ($clog2(`NORMSHIFTSZ));
  parameter CORRSHIFTSZ = (((`CVTLEN+`NF+1)>(`DIVb + 1 +`NF+1) & (`CVTLEN+`NF+1)>(3*`NF+6)) ? (`CVTLEN+`NF+1) : ((`DIVN+1+`NF) > (3*`NF+4) ? (`DIVN+1+`NF) : (3*`NF+4)));

  // division constants

  parameter DIVN        = (((`NF<`XLEN) & `IDIV_ON_FPU) ? `XLEN : `NF+2); // standard length of input
  parameter LOGR        = ($clog2(`RADIX));            // r = log(R)
  parameter RK          = (`LOGR*`DIVCOPIES);          // r*k used for intdiv preproc
  parameter LOGRK       = ($clog2(`RK));               // log2(r*k)
  parameter FPDUR       = ((`DIVN+1+(`LOGR*`DIVCOPIES))/(`LOGR*`DIVCOPIES)+(`RADIX/4));
  parameter DURLEN      = ($clog2(`FPDUR+1));
  parameter DIVb        = (`FPDUR*`LOGR*`DIVCOPIES-1); // canonical fdiv size (b)
  parameter DIVBLEN     = ($clog2(`DIVb+1)-1);
  parameter DIVa        = (`DIVb+1-`XLEN);             // used for idiv on fpu

endpackage
*/
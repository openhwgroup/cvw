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

// Load configuration-specific information
`include "wally-config.vh"

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
  parameter HPTW_WRITES_SUPPORTED = `HPTW_WRITES_SUPPORTED;
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

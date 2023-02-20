//////////////////////////////////////////
// wally-shared.vh
//
// Written: david_harris@hmc.edu 7 June 2021
//
// Purpose: Shared and default configuration values common to all designs
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

// constants defining different privilege modes
// defined in Table 1.1 of the privileged spec
`define M_MODE (2'b11)
`define S_MODE (2'b01)
`define U_MODE (2'b00)

// Virtual Memory Constants
`define VPN_SEGMENT_BITS (`XLEN == 32 ? 10 : 9)
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
/* Delete once tested dh 10/10/22

`define FLEN (`Q_SUPPORTED ? `Q_LEN  : `D_SUPPORTED ? `D_LEN  : `F_SUPPORTED ? `S_LEN  : `H_LEN)
`define NE   (`Q_SUPPORTED ? `Q_NE   : `D_SUPPORTED ? `D_NE   : `F_SUPPORTED ? `S_NE   : `H_NE)
`define NF   (`Q_SUPPORTED ? `Q_NF   : `D_SUPPORTED ? `D_NF   : `F_SUPPORTED ? `S_NF   : `H_NF) 
`define FMT  (`Q_SUPPORTED ? 2'd3       : `D_SUPPORTED ? 2'd1       : `F_SUPPORTED ? 2'd0       : 2'd2)
`define BIAS (`Q_SUPPORTED ? `Q_BIAS : `D_SUPPORTED ? `D_BIAS : `F_SUPPORTED ? `S_BIAS : `H_BIAS)*/

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

// Disable spurious Verilator warnings

/* verilator lint_off STMTDLY */
/* verilator lint_off ASSIGNDLY */
/* verilator lint_off PINCONNECTEMPTY */

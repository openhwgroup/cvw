///////////////////////////////////////////
// debug.vh
//
// Written: matthew.n.otto@okstate.edu
// Created: 15 March 2024
//
// Purpose: debug port definitions
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
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

// DMI op field constants
`define OP_NOP     2'b00
`define OP_READ    2'b01
`define OP_WRITE   2'b10
`define OP_SUCCESS 2'b00
`define OP_FAILED  2'b10
`define OP_BUSY    2'b11

// Debug Bus Address Width
`define ADDR_WIDTH 7

// Debug Module Debug Bus Register Addresses
// DM Internal registers
`define DATA0        `ADDR_WIDTH'h04
`define DATA1        `ADDR_WIDTH'h05
`define DATA2        `ADDR_WIDTH'h06
`define DATA3        `ADDR_WIDTH'h07
`define DATA4        `ADDR_WIDTH'h08
`define DATA5        `ADDR_WIDTH'h09
`define DATA6        `ADDR_WIDTH'h0A
`define DATA7        `ADDR_WIDTH'h0B
`define DATA8        `ADDR_WIDTH'h0C
`define DATA9        `ADDR_WIDTH'h0D
`define DATA10       `ADDR_WIDTH'h0E
`define DATA11       `ADDR_WIDTH'h0F
`define DMCONTROL    `ADDR_WIDTH'h10
`define DMSTATUS     `ADDR_WIDTH'h11
`define HARTINFO     `ADDR_WIDTH'h12
`define ABSTRACTCS   `ADDR_WIDTH'h16
`define COMMAND      `ADDR_WIDTH'h17
`define ABSTRACTAUTO `ADDR_WIDTH'h18
`define NEXTDM       `ADDR_WIDTH'h1d
//`define dmcs2        `ADDR_WIDTH'h32
`define SBCS         `ADDR_WIDTH'h38


//// Register field ranges
// DMCONTROL 0x10
`define HALTREQ         31
`define RESUMEREQ       30
`define HARTRESET       29
`define ACKHAVERESET    28
`define ACKUNAVAIL      27
`define HASEL           26
`define HARTSELLO       25:16
`define HARTSELHI       15:6
`define SETKEEPALIVE    5
`define CLRKEEPALIVE    4
`define SETRESETHALTREQ 3
`define CLRRESETHALTREQ 2
`define NDMRESET        1
`define DMACTIVE        0

// DMSTATUS 0x11
`define NDMRESETPENDING 24
`define STICKYUNAVAIL   23
`define IMPEBREAK       22
`define ALLHAVERESET    19
`define ANYHAVERESET    18
`define ALLRESUMEACK    17
`define ANYRESUMEACK    16
`define ALLNONEXISTENT  15
`define ANYNONEXISTENT  14
`define ALLUNAVAIL      13
`define ANYUNAVAIL      12
`define ALLRUNNING      11
`define ANYRUNNING      10
`define ALLHALTED       9
`define ANYHALTED       8
`define AUTHENTICATED   7
`define AUTHBUSY        6
`define HASRESETHALTREQ 5
`define CONFSTRPTRVALID 4
`define VERSION         3:0

// ABSTRACTCS 0x16
`define PROGBUFSIZE 28:24
`define BUSY        12
`define RELAXEDPRIV 11
`define CMDERR      10:8
`define DATACOUNT   3:0

// COMMAND 0x17
`define CMDTYPE 31:24
`define CONTROL 23:0

//// Abstract Commands
// cmderr
`define CMDERR_NONE          3'h0
`define CMDERR_BUSY          3'h1
`define CMDERR_NOT_SUPPORTED 3'h2
`define CMDERR_EXCEPTION     3'h3
`define CMDERR_HALTRESUME    3'h4
`define CMDERR_BUS           3'h5
`define CMDERR_OTHER         3'h7

// Abstract CmdType Constants (3.7.1)
`define ACCESS_REGISTER 0
`define QUICK_ACCESS    1
`define ACCESS_MEMORY   2

// ACCESS_REGISTER Control ranges
`define AARSIZE          22:20
`define AARPOSTINCREMENT 19
`define POSTEXEC         18
`define TRANSFER         17
`define AARWRITE         16
`define REGNO            15:0

// aarsize
`define AAR32  2
`define AAR64  3
`define AAR128 4

// Register Numbers (regno) 
// (Table 3.3)
// 0x0000 – 0x0fff | CSRs. The “PC” can be accessed here through dpc.
// 0x1000 – 0x101f | GPRs
// 0x1020 – 0x103f | Floating point registers
// 0xc000 – 0xffff | Reserved for non-standard extensions and internal use.

// privileged/csr/csrm
`define MISA_REGNO        16'h0301 // XLEN P.ZICSR_SUPPORTED (Read Only)
// wallypipelinedcore
`define TRAPM_REGNO       16'hC000 // 1'b  P.ZICSR_SUPPORTED (Read Only)
// src/ifu
`define DPC_REGNO         16'h07B1 // BOZO: Alias to PCM until DPC CSR is added
`define PCM_REGNO         16'hC001 // XLEN P.ZICSR_SUPPORTED | P.BPRED_SUPPORTED
`define INSTRM_REGNO      16'hC002 // 32'b P.ZICSR_SUPPORTED | P.A_SUPPORTED
// ieu/controller
`define MEMRWM_REGNO      16'hC003 // 2'b
`define INSTRVALIDM_REGNO 16'hC004 // 1'b  
// ieu/datapath
`define WRITEDATAM_REGNO  16'hC005 // XLEN
// lsu
`define IEUADRM_REGNO     16'hC006 // XLEN
`define READDATAM_REGNO   16'hC007 // LLEN (Read Only)

// src/ieu/datapath
`define X0_REGNO          16'h1000
`define X1_REGNO          16'h1001
`define X2_REGNO          16'h1002
`define X3_REGNO          16'h1003
`define X4_REGNO          16'h1004
`define X5_REGNO          16'h1005
`define X6_REGNO          16'h1006
`define X7_REGNO          16'h1007
`define X8_REGNO          16'h1008
`define X9_REGNO          16'h1009
`define X10_REGNO         16'h100A
`define X11_REGNO         16'h100B
`define X12_REGNO         16'h100C
`define X13_REGNO         16'h100D
`define X14_REGNO         16'h100E
`define X15_REGNO         16'h100F
`define X16_REGNO         16'h1010 // E_SUPPORTED
`define X17_REGNO         16'h1011 // E_SUPPORTED
`define X18_REGNO         16'h1012 // E_SUPPORTED
`define X19_REGNO         16'h1013 // E_SUPPORTED
`define X20_REGNO         16'h1014 // E_SUPPORTED
`define X21_REGNO         16'h1015 // E_SUPPORTED
`define X22_REGNO         16'h1016 // E_SUPPORTED
`define X23_REGNO         16'h1017 // E_SUPPORTED
`define X24_REGNO         16'h1018 // E_SUPPORTED
`define X25_REGNO         16'h1019 // E_SUPPORTED
`define X26_REGNO         16'h101A // E_SUPPORTED
`define X27_REGNO         16'h101B // E_SUPPORTED
`define X28_REGNO         16'h101C // E_SUPPORTED
`define X29_REGNO         16'h101D // E_SUPPORTED
`define X30_REGNO         16'h101E // E_SUPPORTED
`define X31_REGNO         16'h101F // E_SUPPORTED

// src/fpu/fpu
`define FP0_REGNO         16'h1020 // F/D_SUPPORTED
`define FP1_REGNO         16'h1021 // F/D_SUPPORTED
`define FP2_REGNO         16'h1022 // F/D_SUPPORTED
`define FP3_REGNO         16'h1023 // F/D_SUPPORTED
`define FP4_REGNO         16'h1024 // F/D_SUPPORTED
`define FP5_REGNO         16'h1025 // F/D_SUPPORTED
`define FP6_REGNO         16'h1026 // F/D_SUPPORTED
`define FP7_REGNO         16'h1027 // F/D_SUPPORTED
`define FP8_REGNO         16'h1028 // F/D_SUPPORTED
`define FP9_REGNO         16'h1029 // F/D_SUPPORTED
`define FP10_REGNO        16'h102A // F/D_SUPPORTED
`define FP11_REGNO        16'h102B // F/D_SUPPORTED
`define FP12_REGNO        16'h102C // F/D_SUPPORTED
`define FP13_REGNO        16'h102D // F/D_SUPPORTED
`define FP14_REGNO        16'h102E // F/D_SUPPORTED
`define FP15_REGNO        16'h102F // F/D_SUPPORTED
`define FP16_REGNO        16'h1030 // F/D_SUPPORTED
`define FP17_REGNO        16'h1031 // F/D_SUPPORTED
`define FP18_REGNO        16'h1032 // F/D_SUPPORTED
`define FP19_REGNO        16'h1033 // F/D_SUPPORTED
`define FP20_REGNO        16'h1034 // F/D_SUPPORTED
`define FP21_REGNO        16'h1035 // F/D_SUPPORTED
`define FP22_REGNO        16'h1036 // F/D_SUPPORTED
`define FP23_REGNO        16'h1037 // F/D_SUPPORTED
`define FP24_REGNO        16'h1038 // F/D_SUPPORTED
`define FP25_REGNO        16'h1039 // F/D_SUPPORTED
`define FP26_REGNO        16'h103A // F/D_SUPPORTED
`define FP27_REGNO        16'h103B // F/D_SUPPORTED
`define FP28_REGNO        16'h103C // F/D_SUPPORTED
`define FP29_REGNO        16'h103D // F/D_SUPPORTED
`define FP30_REGNO        16'h103E // F/D_SUPPORTED
`define FP31_REGNO        16'h103F // F/D_SUPPORTED

// ACCESS_MEMORY Control ranges (Not implemented)
//`define AAMVIRTUAL       23
//`define AAMSIZE          22:20
//`define AAMPOSTINCREMENT 19
//`define AAMWRITE         16
//`define TARGET_SPECIFIC  15:14

// aamsize
//`define AAM8   0
//`define AAM16  1
//`define AAM32  2
//`define AAM64  3
//`define AAM128 4

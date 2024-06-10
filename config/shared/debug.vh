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
`define CSR_USTATUS               16'h0000 
`define CSR_UIE 		  16'h0004 
`define CSR_UTVEC		  16'h0005 
`define CSR_USCRATCH 	          16'h0040 
`define CSR_UEPC 		  16'h0041 
`define CSR_UCAUSE 		  16'h0042 
`define CSR_UTVAL 		  16'h0043 
`define CSR_UIP		          16'h0044 
`define CSR_FFLAGS 		  16'h0001 
`define CSR_FRM 		  16'h0002 
`define CSR_FCSR		  16'h0003 
`define CSR_CYCLE 		  16'h0C00 
`define CSR_TIME 		  16'h0C01 
`define CSR_INSTRET 	          16'h0C02 
`define CSR_HPMCOUNTER3 	  16'h0C03 
`define CSR_HPMCOUNTER4 	  16'h0C04 
`define CSR_HPMCOUNTER5 	  16'h0C05 
`define CSR_HPMCOUNTER6 	  16'h0C06 
`define CSR_HPMCOUNTER7 	  16'h0C07 
`define CSR_HPMCOUNTER8 	  16'h0C08 
`define CSR_HPMCOUNTER9 	  16'h0C09 
`define CSR_HPMCOUNTER10 	  16'h0C0A 
`define CSR_HPMCOUNTER11 	  16'h0C0B 
`define CSR_HPMCOUNTER12 	  16'h0C0C 
`define CSR_HPMCOUNTER13 	  16'h0C0D 
`define CSR_HPMCOUNTER14 	  16'h0C0E 
`define CSR_HPMCOUNTER15 	  16'h0C0F 
`define CSR_HPMCOUNTER16 	  16'h0C10 
`define CSR_HPMCOUNTER17 	  16'h0C11 
`define CSR_HPMCOUNTER18 	  16'h0C12 
`define CSR_HPMCOUNTER19 	  16'h0C13 
`define CSR_HPMCOUNTER20 	  16'h0C14 
`define CSR_HPMCOUNTER21 	  16'h0C15 
`define CSR_HPMCOUNTER22 	  16'h0C16 
`define CSR_HPMCOUNTER23 	  16'h0C17 
`define CSR_HPMCOUNTER24 	  16'h0C18 
`define CSR_HPMCOUNTER25 	  16'h0C19 
`define CSR_HPMCOUNTER26 	  16'h0C1A 
`define CSR_HPMCOUNTER27 	  16'h0C1B 
`define CSR_HPMCOUNTER28 	  16'h0C1C 
`define CSR_HPMCOUNTER29 	  16'h0C1D 
`define CSR_HPMCOUNTER30 	  16'h0C1E 
`define CSR_HPMCOUNTER31 	  16'h0C1F 
`define CSR_CYCLEH 		  16'h0C80 
`define CSR_TIMEH 		  16'h0C81 
`define CSR_INSTRETH 	          16'h0C82 
`define CSR_HPMCOUNTER3H 	  16'h0C83 
`define CSR_HPMCOUNTER4H 	  16'h0C84 
`define CSR_HPMCOUNTER5H 	  16'h0C85 
`define CSR_HPMCOUNTER6H 	  16'h0C86 
`define CSR_HPMCOUNTER7H 	  16'h0C87 
`define CSR_HPMCOUNTER8H 	  16'h0C88 
`define CSR_HPMCOUNTER9H 	  16'h0C89 
`define CSR_HPMCOUNTER10H 	  16'h0C8A 
`define CSR_HPMCOUNTER11H 	  16'h0C8B 
`define CSR_HPMCOUNTER12H 	  16'h0C8C 
`define CSR_HPMCOUNTER13H 	  16'h0C8D 
`define CSR_HPMCOUNTER14H 	  16'h0C8E 
`define CSR_HPMCOUNTER15H 	  16'h0C8F 
`define CSR_HPMCOUNTER16H 	  16'h0C90 
`define CSR_HPMCOUNTER17H 	  16'h0C91 
`define CSR_HPMCOUNTER18H 	  16'h0C92 
`define CSR_HPMCOUNTER19H 	  16'h0C93 
`define CSR_HPMCOUNTER20H 	  16'h0C94 
`define CSR_HPMCOUNTER21H 	  16'h0C95 
`define CSR_HPMCOUNTER22H 	  16'h0C96 
`define CSR_HPMCOUNTER23H 	  16'h0C97 
`define CSR_HPMCOUNTER24H 	  16'h0C98 
`define CSR_HPMCOUNTER25H 	  16'h0C99 
`define CSR_HPMCOUNTER26H 	  16'h0C9A 
`define CSR_HPMCOUNTER27H 	  16'h0C9B 
`define CSR_HPMCOUNTER28H 	  16'h0C9C 
`define CSR_HPMCOUNTER29H 	  16'h0C9D 
`define CSR_HPMCOUNTER30H 	  16'h0C9E 
`define CSR_HPMCOUNTER31H	  16'h0C9F 
`define CSR_SSTATUS 	          16'h0100 
`define CSR_SEDELEG 	          16'h0102 
`define CSR_SIDELEG 	          16'h0103 
`define CSR_SIE 		  16'h0104 
`define CSR_STVEC 		  16'h0105 
`define CSR_SCOUNTEREN	          16'h0106 
`define CSR_SSCRATCH 	          16'h0140 
`define CSR_SEPC 		  16'h0141 
`define CSR_SCAUSE 		  16'h0142 
`define CSR_STVAL 		  16'h0143 
`define CSR_SIP		          16'h0144 
`define CSR_SATP		  16'h0180 
`define CSR_MVENDORID 	          16'h0F11 
`define CSR_MARCHID 	          16'h0F12 
`define CSR_MIMPID 		  16'h0F13 
`define CSR_MHARTID		  16'h0F14 
`define CSR_MSTATUS 	          16'h0300 
`define CSR_MISA 		  16'h0301 
`define CSR_MEDELEG 	          16'h0302 
`define CSR_MIDELEG 	          16'h0303 
`define CSR_MIE 		  16'h0304 
`define CSR_MTVEC 		  16'h0305 
`define CSR_MCOUNTEREN	          16'h0306 
`define CSR_MSCRATCH 	          16'h0340 
`define CSR_MEPC 		  16'h0341 
`define CSR_MCAUSE 		  16'h0342 
`define CSR_MTVAL 		  16'h0343 
`define CSR_MIP		          16'h0344 
`define CSR_PMPCFG0 	          16'h03A0 
`define CSR_PMPCFG1 	          16'h03A1 
`define CSR_PMPCFG2 	          16'h03A2 
`define CSR_PMPCFG3 	          16'h03A3 
`define CSR_PMPADDR0 	          16'h03B0 
`define CSR_PMPADDR1 	          16'h03B1 
`define CSR_PMPADDR2 	          16'h03B2 
`define CSR_PMPADDR3 	          16'h03B3 
`define CSR_PMPADDR4 	          16'h03B4 
`define CSR_PMPADDR5 	          16'h03B5 
`define CSR_PMPADDR6 	          16'h03B6 
`define CSR_PMPADDR7 	          16'h03B7 
`define CSR_PMPADDR8 	          16'h03B8 
`define CSR_PMPADDR9 	          16'h03B9 
`define CSR_PMPADDR10 	          16'h03BA 
`define CSR_PMPADDR11 	          16'h03BB 
`define CSR_PMPADDR12 	          16'h03BC 
`define CSR_PMPADDR13 	          16'h03BD 
`define CSR_PMPADDR14 	          16'h03BE 
`define CSR_PMPADDR15	          16'h03BF 
`define CSR_MCYCLE 		  16'h0B00 
`define CSR_MINSTRET 	          16'h0B02 
`define CSR_MHPMCOUNTER3 	  16'h0B03 
`define CSR_MHPMCOUNTER4 	  16'h0B04 
`define CSR_MHPMCOUNTER5 	  16'h0B05 
`define CSR_MHPMCOUNTER6 	  16'h0B06 
`define CSR_MHPMCOUNTER7 	  16'h0B07 
`define CSR_MHPMCOUNTER8 	  16'h0B08 
`define CSR_MHPMCOUNTER9 	  16'h0B09 
`define CSR_MHPMCOUNTER10 	  16'h0B0A 
`define CSR_MHPMCOUNTER11 	  16'h0B0B 
`define CSR_MHPMCOUNTER12 	  16'h0B0C 
`define CSR_MHPMCOUNTER13 	  16'h0B0D 
`define CSR_MHPMCOUNTER14 	  16'h0B0E 
`define CSR_MHPMCOUNTER15 	  16'h0B0F 
`define CSR_MHPMCOUNTER16 	  16'h0B10 
`define CSR_MHPMCOUNTER17 	  16'h0B11 
`define CSR_MHPMCOUNTER18 	  16'h0B12 
`define CSR_MHPMCOUNTER19 	  16'h0B13 
`define CSR_MHPMCOUNTER20 	  16'h0B14 
`define CSR_MHPMCOUNTER21 	  16'h0B15 
`define CSR_MHPMCOUNTER22 	  16'h0B16 
`define CSR_MHPMCOUNTER23 	  16'h0B17 
`define CSR_MHPMCOUNTER24 	  16'h0B18 
`define CSR_MHPMCOUNTER25 	  16'h0B19 
`define CSR_MHPMCOUNTER26 	  16'h0B1A 
`define CSR_MHPMCOUNTER27 	  16'h0B1B 
`define CSR_MHPMCOUNTER28 	  16'h0B1C 
`define CSR_MHPMCOUNTER29 	  16'h0B1D 
`define CSR_MHPMCOUNTER30 	  16'h0B1E 
`define CSR_MHPMCOUNTER31 	  16'h0B1F 
`define CSR_MCYCLEH 	          16'h0B80 
`define CSR_MINSTRETH 	          16'h0B82 
`define CSR_MHPMCOUNTER3H 	  16'h0B83 
`define CSR_MHPMCOUNTER4H 	  16'h0B84 
`define CSR_MHPMCOUNTER5H 	  16'h0B85 
`define CSR_MHPMCOUNTER6H 	  16'h0B86 
`define CSR_MHPMCOUNTER7H 	  16'h0B87 
`define CSR_MHPMCOUNTER8H 	  16'h0B88 
`define CSR_MHPMCOUNTER9H 	  16'h0B89 
`define CSR_MHPMCOUNTER10H 	  16'h0B8A 
`define CSR_MHPMCOUNTER11H 	  16'h0B8B 
`define CSR_MHPMCOUNTER12H 	  16'h0B8C 
`define CSR_MHPMCOUNTER13H 	  16'h0B8D 
`define CSR_MHPMCOUNTER14H 	  16'h0B8E 
`define CSR_MHPMCOUNTER15H 	  16'h0B8F 
`define CSR_MHPMCOUNTER16H 	  16'h0B90 
`define CSR_MHPMCOUNTER17H 	  16'h0B91 
`define CSR_MHPMCOUNTER18H 	  16'h0B92 
`define CSR_MHPMCOUNTER19H 	  16'h0B93 
`define CSR_MHPMCOUNTER20H 	  16'h0B94 
`define CSR_MHPMCOUNTER21H 	  16'h0B95 
`define CSR_MHPMCOUNTER22H 	  16'h0B96 
`define CSR_MHPMCOUNTER23H 	  16'h0B97 
`define CSR_MHPMCOUNTER24H 	  16'h0B98 
`define CSR_MHPMCOUNTER25H 	  16'h0B99 
`define CSR_MHPMCOUNTER26H 	  16'h0B9A 
`define CSR_MHPMCOUNTER27H 	  16'h0B9B 
`define CSR_MHPMCOUNTER28H 	  16'h0B9C 
`define CSR_MHPMCOUNTER29H 	  16'h0B9D 
`define CSR_MHPMCOUNTER30H 	  16'h0B9E 
`define CSR_MHPMCOUNTER31H	  16'h0B9F 
`define CSR_MHPMEVENT3 	          16'h0323 
`define CSR_MHPMEVENT4 	          16'h0324 
`define CSR_MHPMEVENT5 	          16'h0325 
`define CSR_MHPMEVENT6 	          16'h0326 
`define CSR_MHPMEVENT7 	          16'h0327 
`define CSR_MHPMEVENT8 	          16'h0328 
`define CSR_MHPMEVENT9 	          16'h0329 
`define CSR_MHPMEVENT10 	  16'h032A 
`define CSR_MHPMEVENT11 	  16'h032B 
`define CSR_MHPMEVENT12 	  16'h032C 
`define CSR_MHPMEVENT13 	  16'h032D 
`define CSR_MHPMEVENT14 	  16'h032E 
`define CSR_MHPMEVENT15 	  16'h032F 
`define CSR_MHPMEVENT16 	  16'h0330 
`define CSR_MHPMEVENT17 	  16'h0331 
`define CSR_MHPMEVENT18 	  16'h0332 
`define CSR_MHPMEVENT19 	  16'h0333 
`define CSR_MHPMEVENT20 	  16'h0334 
`define CSR_MHPMEVENT21 	  16'h0335 
`define CSR_MHPMEVENT22 	  16'h0336 
`define CSR_MHPMEVENT23 	  16'h0337 
`define CSR_MHPMEVENT24 	  16'h0338 
`define CSR_MHPMEVENT25 	  16'h0339 
`define CSR_MHPMEVENT26 	  16'h033A 
`define CSR_MHPMEVENT27 	  16'h033B 
`define CSR_MHPMEVENT28 	  16'h033C 
`define CSR_MHPMEVENT29 	  16'h033D 
`define CSR_MHPMEVENT30 	  16'h033E 
`define CSR_MHPMEVENT31	          16'h033F 
`define CSR_TSELECT 	          16'h07A0 
`define CSR_TDATA1 		  16'h07A1 
`define CSR_TDATA2 		  16'h07A2 
`define CSR_TDATA3		  16'h07A3 
`define CSR_DCSR 		  16'h07B0 
`define CSR_DPC 		  16'h07B1 
`define CSR_DSCRATCH	          16'h07B2 

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

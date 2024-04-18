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
//`define CONFSTRPTR0  `ADDR_WIDTH'h19
//`define CONFSTRPTR1  `ADDR_WIDTH'h1a
//`define CONFSTRPTR2  `ADDR_WIDTH'h1b
//`define CONFSTRPTR3  `ADDR_WIDTH'h1c
`define NEXTDM       `ADDR_WIDTH'h1d
//`define dmcs2        `ADDR_WIDTH'h32


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


//TODO
//Debug Modules must implement this command and must support read and write access to all GPRs
//when the selected hart is halted. Debug Modules may optionally support accessing other registers,
//or accessing registers when the hart is running. It is recommended that if one register in a group
//is accessible, then all registers in that group are accessible, but each individual register (aside from
//GPRs) may be supported differently across read, write, and halt status.

// Register Numbers (Table 3.3)
// TODO: Determine the correct category for each register
// Implementation dependent, 
// these addresses will likely need to be added to an OpenOCD config for Wally
`define PCM         16'h1
`define TRAPM       16'h2
`define INSTRM      16'h3
`define INSTRVALIDM 16'h4
`define MEMRWM      16'h5
`define IEUADRM     16'h6
`define READDATAM   16'h7
`define WRITEDATAM  16'h8
`define RS1         16'h9
`define RS2         16'hA
`define RD2         16'hB
`define RD1         16'hC
`define WD          16'hD
`define WE          16'hE

// ACCESS_MEMORY Control ranges
`define AAMVIRTUAL       23
`define AAMSIZE          22:20
`define AAMPOSTINCREMENT 19
`define AAMWRITE         16
`define TARGET_SPECIFIC  15:14

// aamsize
`define AAM8   0
`define AAM16  1
`define AAM32  2
`define AAM64  3
`define AAM128 4
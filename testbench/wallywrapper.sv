///////////////////////////////////////////
// testbench.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Testbench and helper modules
//          Applies test programs from the riscv-arch-test and Imperas suites
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

`include "wally-config.vh"
`include "config.vh"
`include "tests.vh"

`define PrintHPMCounters 0
`define BPRED_LOGGER 0
`define I_CACHE_ADDR_LOGGER 0
`define D_CACHE_ADDR_LOGGER 0

import cvw::*;

module wallywrapper;
  parameter DEBUG=0;
  parameter TEST="none";
 
`include "parameter-defs.vh"

  logic        clk;
  logic        reset_ext, reset;

  parameter SIGNATURESIZE = 5000000;

  int test, i, errors, totalerrors;
  logic [31:0] sig32[0:SIGNATURESIZE];
  logic [P.XLEN-1:0] signature[0:SIGNATURESIZE];
  logic [P.XLEN-1:0] testadr, testadrNoBase;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;

  string tests[];
  logic [3:0] dummy;

  logic [P.AHBW-1:0]    HRDATAEXT;
  logic                HREADYEXT, HRESPEXT;
  logic [P.PA_BITS-1:0] HADDR;
  logic [P.AHBW-1:0]    HWDATA;
  logic [P.XLEN/8-1:0]  HWSTRB;
  logic                HWRITE;
  logic [2:0]          HSIZE;
  logic [2:0]          HBURST;
  logic [3:0]          HPROT;
  logic [1:0]          HTRANS;
  logic                HMASTLOCK;
  logic                HCLK, HRESETn;

  logic [31:0] GPIOIN, GPIOOUT, GPIOEN;
  logic        UARTSin, UARTSout;

  logic        SDCCLK;
  logic        SDCCmdIn;
  logic        SDCCmdOut;
  logic        SDCCmdOE;
  logic [3:0]  SDCDatIn;
  tri1  [3:0]  SDCDat;
  tri1         SDCCmd;

  logic        HREADY;
  logic        HSELEXT;
  
  // instantiate device to be tested
  assign GPIOIN = 0;
  assign UARTSin = 1;

    assign HREADYEXT = 1;
    assign HRESPEXT = 0;
    assign HRDATAEXT = 0;

    assign SDCCmd = '0;
    assign SDCDat = '0;

  wallypipelinedsoc  #(P) dut(.clk, .reset_ext, .reset, .HRDATAEXT,.HREADYEXT, .HRESPEXT,.HSELEXT,
                        .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
                        .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), .GPIOIN, .GPIOOUT, .GPIOEN,
                        .UARTSin, .UARTSout, .SDCCmdIn, .SDCCmdOut, .SDCCmdOE, .SDCDatIn, .SDCCLK); 

endmodule

///////////////////////////////////////////
// wallywrapper.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wrapper module to define parameters for Wally Verilator linting
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

`include "config.vh"



module wallywrapper import cvw::*;(
  input logic clk,
  input logic reset_ext,
  input logic SPIIn,
  input logic SDCIntr
);
 
`include "parameter-defs.vh"

  logic        reset;

  logic [P.AHBW-1:0]    HRDATAEXT;
  logic                 HREADYEXT, HRESPEXT;
  logic [P.PA_BITS-1:0] HADDR;
  logic [P.AHBW-1:0]    HWDATA;
  logic [P.XLEN/8-1:0]  HWSTRB;
  logic                 HWRITE;
  logic [2:0]           HSIZE;
  logic [2:0]           HBURST;
  logic [3:0]           HPROT;
  logic [1:0]           HTRANS;
  logic                 HMASTLOCK;
  logic                 HCLK, HRESETn;

  logic [31:0] GPIOIN, GPIOOUT, GPIOEN;
  logic        UARTSin, UARTSout;
  logic        SPIOut;
  logic [3:0]  SPICS;
  logic        ui_clk;
  logic [15:0] dmc_trefi;
  logic [3:0]  dmc_tmrd;
  logic [3:0]  dmc_trfc;
  logic [3:0]  dmc_trc;
  logic [3:0]  dmc_trp;
  logic [3:0]  dmc_tras;
  logic [3:0]  dmc_trrd;
  logic [3:0]  dmc_trcd;
  logic [3:0]  dmc_twr;
  logic [3:0]  dmc_twtr;
  logic [3:0]  dmc_trtp;
  logic [3:0]  dmc_tcas;
  logic [3:0]  dmc_col_width;
  logic [3:0]  dmc_row_width;
  logic [1:0]  dmc_bank_width;
  logic [5:0]  dmc_bank_pos;
  logic [2:0]  dmc_dqs_sel_cal;
  logic [15:0] dmc_init_cycles;
  logic        dmc_config_changed;
  logic        PLLrefclk;
  logic        PLLrfen, PLLfben;
  logic [5:0]  PLLclkr;
  logic [12:0] PLLclkf;
  logic [3:0]  PLLclkod;
  logic [11:0] PLLbwadj;
  logic        PLLtest;
  logic        PLLfasten;
  logic        PLLlock;
  logic        PLLconfigdone;

  logic        HREADY;
  logic        HSELEXT;
  logic        HSELEXTSDC;


  // instantiate device to be tested
  assign GPIOIN = 0;
  assign UARTSin = 1;

  assign HREADYEXT = 1;
  assign HRESPEXT = 0;
  assign HRDATAEXT = 0;

  assign ui_clk = 0;
  assign PLLrefclk = 0;
  assign PLLrfen = 0;
  assign PLLfben = 0;
  assign PLLlock = 1;

  wallypipelinedsoc #(P) dut(
    .clk, .reset_ext, .reset, .HRDATAEXT,.HREADYEXT, .HRESPEXT,.HSELEXT, .HSELEXTSDC,
    .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
    .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), .GPIOIN, .GPIOOUT, .GPIOEN,
    .UARTSin, .UARTSout, .SPIIn, .SPIOut, .SPICS, .SDCIntr,
    .ui_clk, .dmc_trefi, .dmc_tmrd, .dmc_trfc, .dmc_trc, .dmc_trp, .dmc_tras, .dmc_trrd,
    .dmc_trcd, .dmc_twr, .dmc_twtr, .dmc_trtp, .dmc_tcas, .dmc_col_width, .dmc_row_width,
    .dmc_bank_width, .dmc_bank_pos, .dmc_dqs_sel_cal, .dmc_init_cycles, .dmc_config_changed,
    .PLLrefclk, .PLLrfen, .PLLfben, .PLLclkr, .PLLclkf, .PLLclkod, .PLLbwadj,
    .PLLtest, .PLLfasten, .PLLlock, .PLLconfigdone
  );

endmodule

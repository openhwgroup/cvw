///////////////////////////////////////////
// bsg_dmc_config_apb.sv
//
// Written: infinitymdm@gmail.com 3 June 2024
//
// Purpose: Synchronized configuration registers for BSG memory controller
// 
// Documentation: 
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

module pll_config_apb #(
  parameter APB_DATA_SIZE = 64
) (
  input  logic                     PCLK, PRESETn,
  input  logic                     PSEL,
  input  logic [7:0]               PADDR,
  input  logic [APB_DATA_SIZE-1:0] PWDATA,
  input  logic                     PWRITE,
  input  logic                     PENABLE,
  output logic                     PRDATA,
  output logic                     PREADY,
  input  logic                     ref_clk,
  // input  logic                     wally_clk, // Assume this is the same as PCLK
  input  logic                     pll_rfen,
  input  logic                     pll_fben,
  output logic [5:0]               pll_clkr,
  output logic [12:0]              pll_clkf,
  output logic [3:0]               pll_clkod,
  output logic [11:0]              pll_bwadj,
  output logic                     pll_bypass,
  output logic                     pll_test,
  input  logic                     pll_lock,
);

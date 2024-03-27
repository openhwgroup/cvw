///////////////////////////////////////////
// ahbxuiconverter.sv
//
// Written: infinitymdm@gmail.com 29 February 2024
//
// Purpose: AHB to Xilinx UI converter
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

module ahbxuiconverter #(parameter ADDR_SIZE = 31,
                         parameter DATA_SIZE = 64) (
  // AHB signals
  input  logic                   HCLK,
  input  logic                   HRESETn,
  input  logic                   HSEL,
  input  logic [ADDR_SIZE-1:0]   HADDR,
  input  logic [DATA_SIZE-1:0]   HWDATA,
  input  logic [DATA_SIZE/8-1:0] HWSTRB,
  input  logic                   HWRITE,
  input  logic [1:0]             HTRANS,
  input  logic                   HREADY,
  output logic [DATA_SIZE-1:0]   HRDATA,
  output logic                   HRESP,
  output logic                   HREADYOUT,

  // UI signals
  output logic                   sys_reset,
  input  logic                   ui_clk, // from PLL
  input  logic                   ui_clk_sync_rst,
  output logic [ADDR_SIZE-1:0]   app_addr, // Double check this width
  output logic [2:0]             app_cmd,
  output logic                   app_en,
  input  logic                   app_rdy,
  output logic                   app_wdf_wren,
  output logic [DATA_SIZE-1:0]   app_wdf_data,
  output logic [DATA_SIZE/8-1:0] app_wdf_mask,
  output logic                   app_wdf_end,
  input  logic                   app_wdf_rdy,
  input  logic [DATA_SIZE-1:0]   app_rd_data,
  input  logic                   app_rd_data_end,
  input  logic                   app_rd_data_valid,
  input  logic                   init_calib_complete
);

  assign sys_reset = ~HRESETn;

  // Enable this peripheral when:
  // a) selected, AND
  // b) a transfer is started, AND
  // c) the bus is ready
  logic initTrans;
  assign initTrans = HSEL & HTRANS[1] & HREADY;

  // FIXME: Double check burst transactions. I think we don't handle HREADYOUT for those correctly

  // UI is ready for a command when initialized and ready to read and write
  logic uiReady;
  assign uiReady = app_rdy & app_wdf_rdy & init_calib_complete;

  // Buffer the input down to ui_clk speed
  logic [ADDR_SIZE-1:0]   addr;
  logic [DATA_SIZE-1:0]   data;
  logic [DATA_SIZE/8-1:0] mask;
  logic                   cmdInit, cmdWrite;
  logic                   cmdwfull, cmdrvalid;
  logic enqueueCmd, dequeueCmd;
  assign enqueueCmd = initTrans & ~cmdwfull;
  assign dequeueCmd = uiReady & cmdrvalid;
  // FIFO needs addr + (data + mask) + (enable + write)
  bsg_async_fifo #(
    .width_p(ADDR_SIZE + 9*DATA_SIZE/8 + 2),
    .lg_size_p(16),
    .and_data_with_valid_p(1)
  ) cmdfifo (
    .w_data_i({HADDR, HWDATA, HWSTRB, initTrans, HWRITE}),
    .w_enq_i(enqueueCmd), .w_clk_i(HCLK), .w_reset_i(~HRESETn),
    .r_deq_i(dequeueCmd), .r_clk_i(ui_clk), .r_reset_i(ui_clk_sync_rst),
    .r_data_o({addr, data, mask, cmdInit, cmdWrite}),
    .w_full_o(cmdwfull), .r_valid_o(cmdrvalid)
  );

  // Delay transactions 1 clk so we can set wren on the cycle after write commands (when data arrives)
  flopen  #(ADDR_SIZE)   addrreg  (ui_clk, uiReady, addr, app_addr);
  flopenr #(3)           cmdreg   (ui_clk, ui_clk_sync_rst, uiReady, {2'b0, ~cmdWrite}, app_cmd);
  flopenr #(1)           cmdenreg (ui_clk, ui_clk_sync_rst, uiReady, cmdInit, app_en);
  flopenr #(1)           wrenreg  (ui_clk, ui_clk_sync_rst, uiReady, ~app_cmd[0], app_wdf_wren);
  flopenr #(DATA_SIZE)   datareg  (ui_clk, ui_clk_sync_rst, uiReady, data, app_wdf_data);
  flopenr #(DATA_SIZE/8) maskreg  (ui_clk, ui_clk_sync_rst, uiReady, mask, app_wdf_mask);
  assign app_wdf_end = app_wdf_wren; // Since AHB will always put data on the bus after a write cmd, this is always valid
  
  // Return read data at HCLK speed
  logic respwfull, resprvalid;
  logic enqueueResp, dequeueResp;
  assign enqueueResp = app_rd_data_valid & ~respwfull;
  assign dequeueResp = HSEL & resprvalid;
  bsg_async_fifo #(
    .width_p(DATA_SIZE),
    .lg_size_p(8),
    .and_data_with_valid_p(1)
  ) respfifo (
    .w_data_i(app_rd_data),
    .w_enq_i(enqueueResp), .w_clk_i(ui_clk), .w_reset_i(ui_clk_sync_rst),
    .r_deq_i(dequeueResp), .r_clk_i(HCLK), .r_reset_i(~HRESETn),
    .r_data_o(HRDATA),
    .w_full_o(respwfull), .r_valid_o(resprvalid)
  );
  
  assign HRESP = 0; // do not indicate errors
  assign HREADYOUT = uiReady & ~cmdwfull;

endmodule

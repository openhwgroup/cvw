///////////////////////////////////////////
// bsg_dmc_ahb.sv
//
// Written: infinitymdm@gmail.com 29 February 2024
//
// Purpose: BSG memory controller presenting an AHB interface
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

`include "bsg_dmc.svh"

module bsg_dmc_ahb 
  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
#(
  parameter AHB_ADDR_SIZE = 28,
  parameter AHB_DATA_SIZE = 64,
  parameter DQ_DATA_SIZE  = 32,
  parameter BURST_LEN     = 8, // bsg_dmc supports 4- or 8-beat bursts
  parameter FIFO_DEPTH    = 8
) (
  input  bsg_dmc_s                   dmc_config,
  input  logic                       dmc_config_changed,
  input  logic                       HCLK, HRESETn,
  input  logic                       HSEL,
  input  logic [AHB_ADDR_SIZE-1:0]   HADDR,
  input  logic [AHB_DATA_SIZE-1:0]   HWDATA,
  input  logic [AHB_DATA_SIZE/8-1:0] HWSTRB,
  input  logic [2:0]                 HBURST,
  input  logic                       HWRITE,
  input  logic [1:0]                 HTRANS,
  input  logic                       HREADY,
  output logic [AHB_DATA_SIZE-1:0]   HRDATA,
  output logic                       HRESP, HREADYOUT,
  input  logic                       ui_clk,
  output                             ddr_ck_p_o, ddr_ck_n_o, ddr_cke_o,
  output       [2:0]                 ddr_ba_o,
  output       [15:0]                ddr_addr_o,
  output                             ddr_cs_n_o, ddr_ras_n_o, ddr_cas_n_o,
  output                             ddr_we_n_o, ddr_reset_n_o, ddr_odt_o,
  output       [DQ_DATA_SIZE/8-1:0]  ddr_dm_oen_o, ddr_dm_o,
  output       [DQ_DATA_SIZE/8-1:0]  ddr_dqs_p_oen_o, ddr_dqs_p_ien_o, ddr_dqs_p_o,
  input        [DQ_DATA_SIZE/8-1:0]  ddr_dqs_p_i,
  output       [DQ_DATA_SIZE/8-1:0]  ddr_dqs_n_oen_o, ddr_dqs_n_ien_o, ddr_dqs_n_o,
  input        [DQ_DATA_SIZE/8-1:0]  ddr_dqs_n_i,
  output       [DQ_DATA_SIZE-1:0]    ddr_dq_oen_o, ddr_dq_o,
  input        [DQ_DATA_SIZE-1:0]    ddr_dq_i,
  input  logic                       dfi_clk_2x_i,
  output logic                       dfi_clk_1x_o
);

  // Global async reset
  logic sys_reset;

  // Memory controller config
  bsg_tag_s                      dmc_rst_tag, dmc_ds_tag;
  bsg_tag_s [DQ_DATA_SIZE/8-1:0] dmc_dly_tag, dmc_dly_trigger_tag;

  // UI signals
  logic                       ui_clk_sync_rst;
  logic [AHB_ADDR_SIZE-1:0]   app_addr;
  logic [2:0]                 app_cmd;
  logic                       app_en, app_rdy, app_wdf_wren;
  logic [AHB_DATA_SIZE-1:0]   app_wdf_data;
  logic [AHB_DATA_SIZE/8-1:0] app_wdf_mask;
  logic                       app_wdf_end, app_wdf_rdy;
  logic [AHB_DATA_SIZE-1:0]   app_rd_data;
  logic                       app_rd_data_end, app_rd_data_valid;
  logic                       app_ref_ack_o, app_zq_ack_o, app_sr_active_o; // Sink unused UI signals
  logic                       init_calib_complete;
  logic [11:0]                device_temp; // Reserved

  ahbxuiconverter #(
    AHB_ADDR_SIZE,
    AHB_DATA_SIZE,
    BURST_LEN
  ) bsg_dmc_ahb_ui_converter (
    .HCLK, .HRESETn(HRESETn & ~dmc_config_changed), // Allow changes to dmc_config to reset the converter FSM and reinit bsg_dmc
    .HSEL, .HADDR, .HWDATA, .HWSTRB, .HBURST, .HWRITE, .HTRANS, .HREADY, .HRDATA, .HRESP, .HREADYOUT,
    .sys_reset, .ui_clk, .ui_clk_sync_rst,
    .app_addr, .app_cmd, .app_en, .app_rdy,
    .app_wdf_wren, .app_wdf_data, .app_wdf_mask, .app_wdf_end, .app_wdf_rdy,
    .app_rd_data, .app_rd_data_end, .app_rd_data_valid,
    .init_calib_complete
  );

  bsg_dmc #(
    .num_adgs_p(1),
    .ui_addr_width_p(AHB_ADDR_SIZE),
    .ui_data_width_p(AHB_DATA_SIZE),
    .burst_data_width_p(AHB_DATA_SIZE * BURST_LEN),
    .dq_data_width_p(DQ_DATA_SIZE),
    .cmd_afifo_depth_p(FIFO_DEPTH),
    .cmd_sfifo_depth_p(FIFO_DEPTH)
  ) dmc (
    .async_reset_tag_i(dmc_rst_tag),
    .bsg_dly_tag_i(dmc_dly_tag), .bsg_dly_trigger_tag_i(dmc_dly_trigger_tag), .bsg_ds_tag_i(dmc_ds_tag),
    .dmc_p_i(dmc_config),
    .sys_reset_i(sys_reset),
    .app_addr_i(app_addr), .app_cmd_i(app_cmd), .app_en_i(app_en), .app_rdy_o(app_rdy),
    .app_wdf_wren_i(app_wdf_wren), .app_wdf_data_i(app_wdf_data), .app_wdf_mask_i(app_wdf_mask), .app_wdf_end_i(app_wdf_end), .app_wdf_rdy_o(app_wdf_rdy),
    .app_rd_data_valid_o(app_rd_data_valid), .app_rd_data_o(app_rd_data), .app_rd_data_end_o(app_rd_data_end),
    .app_ref_req_i(1'b0), .app_ref_ack_o,
    .app_zq_req_i(1'b0), .app_zq_ack_o,
    .app_sr_req_i(1'b0), .app_sr_active_o,
    .init_calib_complete_o(init_calib_complete),
    .ddr_ck_p_o, .ddr_ck_n_o, .ddr_cke_o,
    .ddr_ba_o, .ddr_addr_o, .ddr_cs_n_o, .ddr_ras_n_o, .ddr_cas_n_o,
    .ddr_we_n_o, .ddr_reset_n_o, .ddr_odt_o,
    .ddr_dm_oen_o, .ddr_dm_o,
    .ddr_dqs_p_oen_o, .ddr_dqs_p_ien_o, .ddr_dqs_p_o, .ddr_dqs_p_i,
    .ddr_dqs_n_oen_o, .ddr_dqs_n_ien_o, .ddr_dqs_n_o, .ddr_dqs_n_i,
    .ddr_dq_oen_o, .ddr_dq_o, .ddr_dq_i,
    .ui_clk_i(ui_clk),
    .dfi_clk_2x_i, .dfi_clk_1x_o,
    .ui_clk_sync_rst_o(ui_clk_sync_rst),
    .device_temp_o(device_temp)
  );
endmodule

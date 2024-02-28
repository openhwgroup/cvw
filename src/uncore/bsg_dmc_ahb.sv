///////////////////////////////////////////
// bsg_dmc_ahb.sv
//
// Written: infinitymdm@gmail.com
//
// Purpose: BSG controller and LPDDRDRAM presenting an AHB interface
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
  parameter ADDR_SIZE    = 28,
  parameter DATA_SIZE    = 64,
  parameter BURST_LENGTH = 8,
  parameter FIFO_DEPTH   = 4,
) (
  input  logic                    HCLK, HRESETn,
  input  logic                    HSEL,
  input  logic [ADDR_SIZE-1:0]    HADDR,
  input  logic [DATA_SIZE-1:0]    HWDATA,
  input  logic [DATA_SIZE/8-1:0]  HWSTRB,
  input  logic                    HWRITE,
  input  logic [1:0]              HTRANS,
  input  logic                    HREADY,
  output logic [DATA_SIZE-1:0]    HRDATA,
  output logic                    HRESP, HREADYOUT,
  //input  logic                    ui_clk // Add this once PLL is integrated
  output logic                    ddr_ck_p, ddr_ck_n, ddr_cke,
  output logic [2:0]              ddr_ba,
  output logic [15:0]             ddr_addr,
  output logic                    ddr_cs, ddr_ras, ddr_cas,
  output logic                    ddr_we, ddr_reset, ddr_odt,
  output logic [DATA_SIZE/16-1:0] ddr_dm_oen, ddr_dm,
  output logic [DATA_SIZE/16-1:0] ddr_dqs_p_oen, ddr_dqs_p_ien, ddr_dqs_p_out,
  input  logic [DATA_SIZE/16-1:0] ddr_dqs_p_in,
  output logic [DATA_SIZE/16-1:0] ddr_dqs_n_oen, ddr_dqs_n_ien, ddr_dqs_n_out,
  input  logic [DATA_SIZE/16-1:0] ddr_dqs_n_in,
  output logic [DATA_SIZE/2-1:0]  ddr_dq_oen, ddr_dq_out,
  input  logic [DATA_SIZE/2-1:0]  ddr_dq_in,
  input  logic                    dfi_clk_2x,
  output logic                    dfi_clk_1x
);

  localparam BURST_DATA_SIZE = DATA_SIZE * BURST_LENGTH;
  // localparam DQ_DATA_SIZE = DATA_SIZE >> 1;

  // Global async reset
  logic sys_reset;

  // Memory controller config
  bsg_tag_s       dmc_rst_tag, dmc_ds_tag;
  bsg_tag_s [3:0] dmc_dly_tag, dmc_dly_trigger_tag;
  bsg_dmc_s       dmc_config;

  // UI signals
  logic                   ui_clk_sync_rst;
  logic [ADDR_SIZE-1:0]   app_addr;
  logic [2:0]             app_cmd;
  logic                   app_en, app_rdy, app_wdf_wren;
  logic [DATA_SIZE-1:0]   app_wdf_data;
  logic [DATA_SIZE/8-1:0] app_wdf_mask;
  logic                   app_wdf_end, app_wdf_rdy;
  logic [DATA_SIZE-1:0]   app_rd_data;
  logic                   app_rd_data_end, app_rd_data_valid;
  logic                   app_ref_ack, app_zq_ack, app_sr_active; // Sink unused UI signals
  logic                   init_calib_complete;
  logic [11:0]            device_temp; // Reserved

  // Use a /6 clock divider until PLL is integrated. TODO: Replace
  logic ui_clk;
  integer clk_counter = 0;
  always @(posedge HCLK) begin
    counter <= counter + 1;
    if (counter >= 6) counter <= 0;
    ui_clk <= (counter >= 3);
  end

  // TODO: Figure out how to initialize dmc_config correctly
  always_comb begin: bsg_dmc_config
    dmc_p.trefi = 1023;
    dmc_p.tmrd = 1;
    dmc_p.trfc = 15;
    dmc_p.trc = 10;
    dmc_p.trp = 2;
    dmc_p.tras = 7;
    dmc_p.trrd = 1;
    dmc_p.trcd = 2;
    dmc_p.twr = 10;
    dmc_p.twtr = 7;
    dmc_p.trtp = 10;
    dmc_p.tcas = 3;
    dmc_p.col_width = 11;
    dmc_p.row_width = 14;
    dmc_p.bank_width = 2;
    dmc_p.dqs_sel_cal = 3;
    dmc_p.init_cycles = 40010;
    dmc_p.bank_pos = 25;
  end

  ahbxuiconverter #(ADDR_SIZE, DATA_SIZE) bsg_dmc_ahb_ui_converter (
    .HCLK, .HRESETn, .HSEL, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HTRANS, .HREADY, .HRDATA, .HRESP, .HREADYOUT,
    .sys_reset, .ui_clk, .ui_clk_sync_rst,
    .app_addr, .app_cmd, .app_en, .app_rdy,
    .app_wdf_wren, .app_wdf_data, .app_wdf_mask, .app_wdf_end, .app_wdf_rdy,
    .app_rd_data, .app_rd_data_end, .app_rd_data_valid,
    .init_calib_complete
  );

  bsg_dmc #(
    .num_adgs_p(1),
    .ui_addr_width_p(ADDR_SIZE),
    .ui_data_width_p(DATA_SIZE),
    .burst_data_width_p(BURST_DATA_SIZE),
    .dq_data_width_p(DQ_DATA_SIZE),
    .cmd_afifo_depth(FIFO_DEPTH),
    .cmd_sfifo_depth(FIFO_DEPTH)
  ) dmc (
    .async_reset_tag_i(dmc_rst_tag),
    .bsg_dly_tag_i(dmc_dly_tag), .bsg_dly_trigger_tag_i(dmc_dly_trigger_tag), .bsg_ds_tag_i(dmc_ds_tag),
    .dmc_p_i(dmc_config),
    .sys_reset_i(sys_reset),
    .app_addr_i(app_addr), .app_cmd_i(app_cmd), .app_en_i(app_en), .app_rdy_o(app_rdy),
    .app_wdf_wren_i(app_wdf_wren), .app_wdf_data_i(app_wdf_data), .app_wdf_mask_i(app_wdf_mask), .app_wdf_end_i(app_wdf_end), .app_wdf_rdy_o(app_wdf_rdy),
    .app_rd_data_valid_o(app_rd_data_valid), .app_rd_data_o(app_rd_data), .app_rd_data_end_o(app_rd_data_end),
    .app_ref_req_i(1'b0), .app_ref_ack_o(app_ref_ack),
    .app_zq_req_i(1'b0), .app_zq_ack_o(app_zq_ack),
    .app_sr_req_i(1'b0), .app_sr_active_o(app_sr_active),
    .init_calib_complete_o(init_calib_complete),
    .ddr_ck_p_o(ddr_ck_p), .ddr_ck_n_o(ddr_ck_n), .ddr_cke_o(ddr_cke),
    .ddr_ba_o(ddr_ba), .ddr_addr_o(ddr_addr), .ddr_cs_n_o(ddr_cs), .ddr_ras_n_o(ddr_ras), .ddr_cas_n_o(ddr_cas),
    .ddr_we_n_o(ddr_we), .ddr_reset_n_o(ddr_reset), .ddr_odt_o(ddr_odt),
    .ddr_dm_oen_o(ddr_dm_oen), .ddr_dm_o(ddr_dm),
    .ddr_dqs_p_oen_o(ddr_dqs_p_oen), .ddr_dqs_p_ien_o(ddr_dqs_p_ien), .ddr_dqs_p_o(ddr_dqs_p_out), .ddr_dqs_p_i(ddr_dqs_p_in),
    .ddr_dqs_n_oen_o(ddr_dqs_n_oen), .ddr_dqs_n_ien_o(ddr_dqs_n_ien), .ddr_dqs_n_o(ddr_dqs_n_out), .ddr_dqs_n_i(ddr_dqs_n_in),
    .ddr_dq_oen_o(ddr_dq_oen), .ddr_dq_o(ddr_dq_out), .ddr_dq_i(ddr_dq_in),
    .ui_clk_i(ui_clk),
    .dfi_clk_2x_i(dfi_clk_2x), .dfi_clk_1x_o(dfi_clk_1x),
    .ui_clk_sync_rst_o(ui_clk_sync_rst),
    .device_temp_o(device_temp)
  );
endmodule

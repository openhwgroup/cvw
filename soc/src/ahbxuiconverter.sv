///////////////////////////////////////////
// ahbxuiconverter.sv
//
// Written: infinitymdm@gmail.com 29 February 2024
// Modified: infinitymdm@gmail.com 02 April 2024
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

module ahbxuiconverter 
#(
  parameter ADDR_SIZE = 31,
  parameter DATA_SIZE = 64,
  parameter BURST_LEN = 8
) (
  // AHB signals
  input  logic                   HCLK,
  input  logic                   HRESETn,
  input  logic                   HSEL,
  input  logic [ADDR_SIZE-1:0]   HADDR,
  input  logic [DATA_SIZE-1:0]   HWDATA,
  input  logic [DATA_SIZE/8-1:0] HWSTRB,
  input  logic                   HWRITE,
  input  logic [1:0]             HTRANS,
  input  logic [2:0]             HBURST,
  input  logic                   HREADY,
  output logic [DATA_SIZE-1:0]   HRDATA,
  output logic                   HRESP,
  output logic                   HREADYOUT,

  // UI signals
  output logic                   sys_reset,
  input  logic                   ui_clk, // from PLL
  input  logic                   ui_clk_sync_rst,
  output logic [ADDR_SIZE-1:0]   app_addr,
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

  localparam BURST_CNTR_SIZE = $clog2(BURST_LEN);
  localparam MASK_SIZE = DATA_SIZE >> 3;
  localparam OP_SIZE = 1 + ADDR_SIZE-4 + DATA_SIZE + MASK_SIZE; // wren + addr (minus last nibble) + data + mask

  logic [ADDR_SIZE-1:0]       addr;
  logic                       ahb_wren;
  logic [ADDR_SIZE-1:4]       ahb_addr;
  logic [1:0]                 ahb_burst;
  
  logic                       op_ready;
  logic                       new_addr;
  logic                       new_burst;
  logic                       record_op;
  logic                       select_recorded_op;
  logic                       mask_write;
  
  logic [OP_SIZE-1:0]         op;
  logic [OP_SIZE-1:0]         recorded_op;
  logic                       capture_op;
  logic [OP_SIZE-1:MASK_SIZE] selected_op;
  logic [MASK_SIZE-1:0]       mask;
  logic [MASK_SIZE-1:0]       selected_mask;

  logic                       cmd_w_full;
  logic                       cmd_r_valid;
  logic                       cmd_enq;
  logic                       cmd_deq;

  logic                       ui_initialized;
  logic                       write;

  logic                       resp_w_full;
  logic                       resp_r_valid;
  logic                       resp_enq;
  logic                       resp_deq;

  assign sys_reset = ~HRESETn;

  // Wally uses byte addressing, but DDR gives us 32 bits per address
  // Compensate for this with a bit of address translation - just divide by 4
  assign addr = HADDR >> 2;

  // We use an FSM to line up AHB commands into bursts for the UI
  assign op_ready = HSEL & HTRANS[1] & HREADY;
  assign new_addr = ~(ahb_addr == addr[ADDR_SIZE-1:4]);
  assign new_burst = ~(ahb_burst == HBURST);
  ahbburstctrl #(BURST_LEN) ahbctrl (
    .clk(HCLK), .reset(~HRESETn),
    .op_ready, .cmd_full(cmd_w_full),
    .new_addr, .word_addr(addr[3:0]),
    .write(HWRITE), .new_burst,
    .resp_valid(resp_r_valid),
    .capture_op, .record_op,
    .select_recorded_op, .mask_write,
    .issue_op(cmd_enq),
    .readyout(HREADYOUT)
  );

  // Delay AHB address phase signals. Only capture if indicated by control logic
  flopenr #(1)           ahbwrenreg (HCLK, ~HRESETn, capture_op, HWRITE,              ahb_wren);
  flopenr #(ADDR_SIZE-4) ahbaddrreg (HCLK, ~HRESETn, capture_op, addr[ADDR_SIZE-1:4], ahb_addr);
  flopenr #(2)           ahbbrstreg (HCLK, ~HRESETn, capture_op, HBURST[2:1],         ahb_burst);
  assign op = {ahb_wren, ahb_addr, HWDATA, ~HWSTRB};

  // Store a previously captured op for later if requested by control logic
  flopenr #(OP_SIZE) recordedopreg (HCLK, ~HRESETn, record_op, op, recorded_op);

  // Select signals according to control logic
  mux2 #(OP_SIZE)   opselect   (op,   recorded_op,       select_recorded_op, {selected_op, mask});
  mux2 #(MASK_SIZE) maskselect (mask, {MASK_SIZE{1'b1}}, mask_write,         selected_mask);

  // Buffer input down to ui_clk speed
  bsg_async_fifo #(
    .width_p(OP_SIZE),
    .lg_size_p(16),
    .and_data_with_valid_p(1)
  ) cmdfifo (
    .w_data_i({selected_op, selected_mask}),
    .w_enq_i(cmd_enq), .w_clk_i(HCLK), .w_reset_i(~HRESETn),
    .r_deq_i(cmd_deq), .r_clk_i(ui_clk), .r_reset_i(ui_clk_sync_rst),
    .r_data_o({write, app_addr[ADDR_SIZE-1:4], app_wdf_data, app_wdf_mask}),
    .w_full_o(cmd_w_full), .r_valid_o(cmd_r_valid)
  );
  assign app_addr[3:0] = 4'b0;

  // Synchronize ui init flag
  flopr #(1) initreg (ui_clk, sys_reset, init_calib_complete, ui_initialized);

  // Use an FSM to issue UI bursts
  uiburstctrl #(BURST_LEN) uictrl (
    .clk(ui_clk), .reset(ui_clk_sync_rst),
    .ui_initialized, .app_rdy, .app_wdf_rdy,
    .write, .op_ready(cmd_r_valid),
    .app_en, .app_cmd0(app_cmd[0]), .app_wdf_wren, .app_wdf_end,
    .dequeue_op(cmd_deq)
  );
  assign app_cmd[2:1] = {2'b0};

  // Return read data at HCLK speed
  // There is no mechanism to stall the UI in the event that the FIFO is full during a read burst,
  // so we need to ensure that never occurs. In theory, since the FSM in ahbburstctrl ensures we
  // never issue a command while a read is in progress, we should never have the read FIFO fill up.
  assign resp_enq = app_rd_data_valid & ~resp_w_full;
  assign resp_deq = HSEL & resp_r_valid;
  bsg_async_fifo #(
    .width_p(DATA_SIZE),
    .lg_size_p(8),
    .and_data_with_valid_p(1)
  ) respfifo (
    .w_data_i(app_rd_data),
    .w_enq_i(resp_enq), .w_clk_i(ui_clk), .w_reset_i(ui_clk_sync_rst),
    .r_deq_i(resp_deq), .r_clk_i(HCLK), .r_reset_i(~HRESETn),
    .r_data_o(HRDATA),
    .w_full_o(resp_w_full), .r_valid_o(resp_r_valid)
  );

  // do not indicate errors
  assign HRESP = 0;

endmodule

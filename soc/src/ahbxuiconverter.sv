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

  assign sys_reset = ~HRESETn;

  // Enable this peripheral when:
  // a) selected, AND
  // b) a transfer is started, AND
  // c) the bus is ready
  logic initTrans;
  assign initTrans = HSEL & HREADY & HTRANS[1];

  // UI is ready for a command when initialized and ready to read and write
  logic uiReady;
  assign uiReady = app_rdy & app_wdf_rdy & init_calib_complete;

  logic cmdwfull, cmdrvalid;
  logic enqueueCmd, dequeueCmd;
  logic inc_cmd_count, reset_cmd_count;
  logic [2:0] cmd_count;
  counter #(3) cmd_beat_counter (HCLK, reset_cmd_count | ~HRESETn, inc_cmd_count, cmd_count);
  always_comb begin: cmd_burst_logic
    // Enqueue all single commands and 1st mod 8 commands in a burst read
    inc_cmd_count = initTrans & (|HBURST); // Increment each cycle during burst transactions
    reset_cmd_count = ~HSEL | ~(|HBURST); // Reset at end of transaction, or if transaction is not a burst
    enqueueCmd = initTrans & ~cmdwfull & (HWRITE | (cmd_count == 3'b000)); // enqueue all writes and 1st mod 8 reads in a burst
    dequeueCmd = uiReady & cmdrvalid;
  end

  // Buffer the input down to ui_clk speed
  logic [ADDR_SIZE-1:0]   addr;
  logic [DATA_SIZE-1:0]   data;
  logic [DATA_SIZE/8-1:0] mask;
  logic                   wren;
  logic [1:0]             respwidth; // respfifo should only enqueue 2^(respwidth) beats of the response
  // FIFO needs addr + (data + mask) + write + respwidth)
  bsg_async_fifo #(
    .width_p(ADDR_SIZE + 9*DATA_SIZE/8 + 1 + 2),
    .lg_size_p(16), // TODO: Parameterize based on wally config
    .and_data_with_valid_p(1)
  ) cmdfifo (
    .w_data_i({HADDR, HWDATA, ~HWSTRB, HWRITE, HBURST[2:1]}),
    .w_enq_i(enqueueCmd), .w_clk_i(HCLK), .w_reset_i(~HRESETn),
    .r_deq_i(dequeueCmd), .r_clk_i(ui_clk), .r_reset_i(ui_clk_sync_rst),
    .r_data_o({addr, data, mask, wren, respwidth}),
    .w_full_o(cmdwfull), .r_valid_o(cmdrvalid)
  );


  // Delay transactions 1 clk so we can set app_wdf_end when the address changes (or when we are no longer writing)
  assign app_cmd = {2'b0, ~app_wdf_wren};
  assign app_wdf_end = app_wdf_wren & ~({addr, wren} == {app_addr, app_wdf_wren});
  flopen  #(ADDR_SIZE)   addrreg  (ui_clk, uiReady, addr, app_addr);
  flopenr #(1)           cmdenreg (ui_clk, ui_clk_sync_rst, uiReady, dequeueCmd, app_en);
  flopenr #(DATA_SIZE)   datareg  (ui_clk, ui_clk_sync_rst, uiReady, data, app_wdf_data);
  flopenr #(DATA_SIZE/8) maskreg  (ui_clk, ui_clk_sync_rst, uiReady, mask, app_wdf_mask);
  flopenr #(1)           wrenreg  (ui_clk, ui_clk_sync_rst, uiReady, wren, app_wdf_wren);

  logic respwfull, resprvalid;
  logic enqueueResp, dequeueResp;
  logic inc_resp_count, reset_resp_count;
  logic [4:0] resp_count;
  counter #(5) resp_beat_counter (ui_clk, reset_resp_count | ui_clk_sync_rst, inc_resp_count, resp_count);
  always_comb begin: resp_burst_logic
    // Enqueue only the correct number of beats for each response
    inc_resp_count = app_rd_data_valid; // Increment every time we get a beat of valid response data
    reset_resp_count = app_en; // Reset when the UI gets a new transaction
    enqueueResp = app_rd_data_valid & ~respwfull & (|respwidth ? (resp_count < (5'b10 << respwidth)) : resp_count < 1); // Only enqueue 2^(respwidth) beats of a burst read
    dequeueResp = HSEL & resprvalid;
  end
  
  // Return read data at HCLK speed
  bsg_async_fifo #(
    .width_p(DATA_SIZE),
    .lg_size_p(16), // TODO: Parameterize based on wally config
    .and_data_with_valid_p(1)
  ) respfifo (
    .w_data_i(app_rd_data),
    .w_enq_i(enqueueResp), .w_clk_i(ui_clk), .w_reset_i(ui_clk_sync_rst),
    .r_deq_i(dequeueResp), .r_clk_i(HCLK), .r_reset_i(~HRESETn),
    .r_data_o(HRDATA),
    .w_full_o(respwfull), .r_valid_o(resprvalid)
  );
  
  assign HRESP = 0; // do not indicate errors
  assign HREADYOUT = HWRITE ? ~cmdwfull : resprvalid;

endmodule

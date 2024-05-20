///////////////////////////////////////////
// ahbxuiconverter.sv
//
// Written: infinitymdm@gmail.com 29 February 2024
<<<<<<< HEAD
// Modified: infinitymdm@gmail.com 02 April 2024
=======
>>>>>>> 62804195f (soc: organize SoC sources)
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
  localparam OP_DATA_SIZE = ADDR_SIZE + DATA_SIZE + MASK_SIZE + 3; // addr + data + mask + wren + burst

  logic                       ahb_sel;
  logic                       ahb_ready;
  logic [ADDR_SIZE-1:0]       ahb_addr;
  logic                       ahb_wren;
  logic [1:0]                 ahb_burst; // 2^ahb_burst encodes the number of responses we want for a burst
  logic                       ahb_burst_done;
  logic [OP_DATA_SIZE-1:0]    ahb_op;

  logic                       prev_ahb_wren;
  logic [1:0]                 prev_ahb_burst;
  logic [OP_DATA_SIZE-1:0]    prev_ahb_op;
  logic                       new_op_started;
  logic                       repeat_prev_ahb_op;

  logic                       cmd_w_full;
  logic                       cmd_r_valid;
  logic                       cmd_ready;
  logic                       cmd_enq;
  logic                       cmd_deq;
  logic [BURST_CNTR_SIZE-1:0] cmd_count;

  logic                       ui_ready;
  logic [ADDR_SIZE-1:0]       ui_addr;
  logic [DATA_SIZE-1:0]       ui_data;
  logic [MASK_SIZE-1:0]       ui_mask;
  logic                       ui_wren;
  logic [1:0]                 ui_burst;

  logic                       app_cmd_ready;
  logic [1:0]                 app_burst;

  logic                       resp_w_full;
  logic                       resp_r_valid;
  logic                       resp_enq;
  logic                       resp_deq;
  logic                       resp_count_inc;
  logic                       resp_count_rst;
  logic [BURST_CNTR_SIZE:0]   resp_count;
  logic [BURST_CNTR_SIZE:0]   expected_count;
  logic [1:0]                 resp_burst;

  assign sys_reset = ~HRESETn;

  // Delay AHB address phase signals to align with data phase so we can capture the whole transaction
  flopenr #(1)         ahbselreg  (HCLK, ~HRESETn, HREADY, HSEL & HTRANS[1], ahb_sel);
  flopen  #(ADDR_SIZE) ahbaddrreg (HCLK, HREADY, HADDR, ahb_addr);
  flopenr #(1)         ahbwrenreg (HCLK, ~HRESETn, HREADY, HWRITE, ahb_wren);
  flopenr #(2)         ahbbrstreg (HCLK, ~HRESETn, HREADY, HBURST[2:1], ahb_burst);
  flopr   #(1)         ahbrdyreg  (HCLK, ~HRESETn, HREADY, ahb_ready);
  assign ahb_op = {ahb_addr, HWDATA, ~HWSTRB, ahb_wren, ahb_burst};

  // UI only does burst transactions. So if we get N single writes with N < BURST_LEN, we need to 
  // pad those out to BURST_LEN. We do this by repeating the Nth write command BURST_LEN - N times.
  flopenr #(OP_DATA_SIZE) ahbopreg (HCLK, ~HRESETn, cmd_ready & ~repeat_prev_ahb_op, ahb_op, prev_ahb_op);
  always_comb begin: cmd_repeat_logic
    prev_ahb_wren = prev_ahb_op[2];
    prev_ahb_burst = prev_ahb_op[1:0];
    ahb_burst_done = (cmd_count == 'b0); // We have a full burst when cmd_count cycles back around to 0

    // If we have a new command and the previous burst is not done, check whether we've changed op
    // or started a new burst. If we have, we need to repeat the previous operation until the burst
    // is complete
    new_op_started = ~(prev_ahb_wren == ahb_wren) | ~(prev_ahb_burst == ahb_burst);
    repeat_prev_ahb_op = cmd_ready & ~ahb_burst_done & new_op_started;
      
    //repeat_prev_ahb_op = (~(prev_ahb_wren == ahb_wren) | ~(prev_ahb_burst == ahb_burst)) & ~ahb_burst_done & cmd_enq;
  end

  // Buffer input down to ui_clk speed
  always_comb begin: cmd_burst_capture_logic
    // UI treats all reads as burst reads, so 1 read gets us BURST_LEN responses
    cmd_ready = ahb_ready & ahb_sel; // A valid AHB command has been received and aligned with data
    cmd_enq = (ahb_wren | ahb_burst_done) & ~cmd_w_full;
    cmd_deq = ui_ready & cmd_r_valid;
  end
  counter #(BURST_CNTR_SIZE) cmd_beat_counter (HCLK, ~HRESETn, ahb_trans_start, cmd_count);
  bsg_async_fifo #(
    .width_p(OP_DATA_SIZE),
    .lg_size_p(16), // TODO: Parameterize based on wally config
    .and_data_with_valid_p(1)
  ) cmdfifo (
    .w_data_i(repeat_prev_ahb_op ? prev_ahb_op : ahb_op),
    .w_enq_i(cmd_enq), .w_clk_i(HCLK), .w_reset_i(~HRESETn),
    .r_deq_i(cmd_deq), .r_clk_i(ui_clk), .r_reset_i(ui_clk_sync_rst),
    .r_data_o({ui_addr, ui_data, ui_mask, ui_wren, ui_burst}),
    .w_full_o(cmd_w_full), .r_valid_o(cmd_r_valid)
  );

  // UI is ready for a command when initialized and ready to read and write
  assign ui_ready = app_rdy & app_wdf_rdy & init_calib_complete;

  // Delay transactions 1 ui_clk so we can detect the end of a write and set app_wdf_end
  assign app_en = app_cmd_ready & app_wdf_rdy; // Deassert app_en if not ready for write data so we don't accidentally repeat commands
  assign app_cmd = {2'b00, ~app_wdf_wren};
  assign app_wdf_end = app_wdf_wren & ~({ui_addr, ui_wren} == {app_addr, app_wdf_wren});
  flopen  #(ADDR_SIZE) appaddrreg (ui_clk, ui_ready, ui_addr, app_addr);
  flopenr #(1)         appenreg   (ui_clk, ui_clk_sync_rst, ui_ready, cmd_deq, app_cmd_ready);
  flopenr #(DATA_SIZE) appdatareg (ui_clk, ui_clk_sync_rst, ui_ready, ui_data, app_wdf_data);
  flopenr #(MASK_SIZE) appmaskreg (ui_clk, ui_clk_sync_rst, ui_ready, ui_mask, app_wdf_mask);
  flopenr #(1)         appwrenreg (ui_clk, ui_clk_sync_rst, ui_ready, ui_wren, app_wdf_wren);
  flopenr #(2)         appbrstreg (ui_clk, ui_clk_sync_rst, ui_ready, ui_burst, app_burst);

  // Hold on to the number of response beats we want until the ui registers the next command (i.e the response is done)
  flopenr #(2) respbrstreg (ui_clk, ui_clk_sync_rst, app_en, app_burst, resp_burst);

  // Return read data at HCLK speed
  always_comb begin: resp_burst_capture_logic
    // Enqueue only the correct number of beats for each response
    resp_count_inc = app_rd_data_valid; // Increment every time we get a beat of valid response data
    resp_count_rst = app_en | ui_clk_sync_rst; // Reset when the UI gets the next transaction (i.e. the response is done)
    expected_count = {{BURST_CNTR_SIZE-1{1'b0}}, 2'b10} << resp_burst; // 2^(resp_burst)
    resp_enq = app_rd_data_valid & ~resp_w_full & (resp_count < (|resp_burst ? expected_count : {{BURST_CNTR_SIZE{1'b0}}, 1'b1})); // Only enqueue the expected number of beats
    resp_deq = ahb_sel & resp_r_valid;
  end
  counter #(BURST_CNTR_SIZE+1) resp_beat_counter (ui_clk, resp_count_rst, resp_count_inc, resp_count);
  bsg_async_fifo #(
    .width_p(DATA_SIZE),
    .lg_size_p(16), // TODO: Parameterize based on wally config
    .and_data_with_valid_p(1)
  ) respfifo (
    .w_data_i(app_rd_data),
    .w_enq_i(resp_enq), .w_clk_i(ui_clk), .w_reset_i(ui_clk_sync_rst),
    .r_deq_i(resp_deq), .r_clk_i(HCLK), .r_reset_i(~HRESETn),
    .r_data_o(HRDATA),
    .w_full_o(resp_w_full), .r_valid_o(resp_r_valid)
  );

  // Normally accept commands until FIFO is full
  // If we're working on a read, stall until valid response data is available
  // If we're repeating commands to complete a burst, stall until done repeating
  always_comb begin: ready_logic
    if (~ahb_sel | ahb_wren)
      HREADYOUT = ~cmd_w_full & ~repeat_prev_ahb_op; // FIXME
    else
      HREADYOUT = resp_r_valid;
  end

  // do not indicate errors
  assign HRESP = 0;

endmodule

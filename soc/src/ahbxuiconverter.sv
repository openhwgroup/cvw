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

  // AHB wants to enable this peripheral when:
  // a) selected, AND
  // b) a transfer is started, AND
  // c) the bus is ready
  logic ahb_enable;
  assign ahb_enable = HSEL & HREADY & HTRANS[1];

  // UI is ready for a command when initialized and ready to read and write
  logic ui_ready;
  assign ui_ready = app_rdy & app_wdf_rdy & init_calib_complete;

  // Delay AHB address phase signals to align with data phase so we can capture the whole transaction
  logic [ADDR_SIZE-1:0]   ahb_addr;
  logic [DATA_SIZE-1:0]   ahb_data;
  logic [DATA_SIZE/8-1:0] ahb_strb;
  logic                   ahb_wren;
  logic [1:0]             ahb_burst; // 2^ahb_burst encodes the number of responses we want for a burst read
  flopen  #(ADDR_SIZE)   ahbaddrreg (HCLK, HREADY, HADDR, ahb_addr);
  flopenr #(DATA_SIZE)   ahbdatareg (HCLK, ~HRESETn, HREADY, HWDATA, ahb_data);
  flopenr #(DATA_SIZE/8) ahbstrbreg (HCLK, ~HRESETn, HREADY, HWSTRB, ahb_strb);
  flopenr #(1)           ahbwrenreg (HCLK, ~HRESETn, HREADY, HWRITE, ahb_wren);
  flopenr #(2)           ahbbrstreg (HCLK, ~HRESETn, HREADY, HBURST[2:1], ahb_burst);

  // Capture transactions during data phase, once we have the address and data aligned
  logic capture_trans;
  flopr #(1) transreg (HCLK, ~HRESETn, ahb_enable, capture_trans);

  // Buffer input down to ui_clk speed
  logic cmd_w_full, cmd_r_valid;
  logic enqueue_cmd, dequeue_cmd;
  logic inc_cmd_count, reset_cmd_count;
  logic [2:0] cmd_count;
  counter #(3) cmd_beat_counter (HCLK, reset_cmd_count | ~HRESETn, inc_cmd_count, cmd_count);
  always_comb begin: cmd_burst_capture_logic
    // UI treats all reads as burst reads with length 8, so 1 read gets us 8 responses
    // Enqueue all single commands and 1st mod 8 commands in a burst read
    inc_cmd_count = capture_trans & (|ahb_burst); // Increment each cycle during burst transactions
    reset_cmd_count = ~|ahb_burst; // Reset counter if transaction is not a burst
    enqueue_cmd = capture_trans & ~cmd_w_full & (ahb_wren | (cmd_count == 3'b000)); // enqueue all writes and 1st mod 8 reads in a burst
    dequeue_cmd = ui_ready & cmd_r_valid;
  end
  logic [ADDR_SIZE-1:0]   ui_addr;
  logic [DATA_SIZE-1:0]   ui_data;
  logic [DATA_SIZE/8-1:0] ui_mask;
  logic                   ui_wren;
  logic [1:0]             ui_burst; // respfifo should only enqueue 2^(ui_burst) beats of the response
  bsg_async_fifo #(
    .width_p(ADDR_SIZE + 9*DATA_SIZE/8 + 1 + 2), // FIFO needs addr + (data + mask) + write + burst)
    .lg_size_p(16), // TODO: Parameterize based on wally config
    .and_data_with_valid_p(1)
  ) cmdfifo (
    .w_data_i({ahb_addr, ahb_data, ~ahb_strb, ahb_wren, ahb_burst}),
    .w_enq_i(enqueue_cmd), .w_clk_i(HCLK), .w_reset_i(~HRESETn),
    .r_deq_i(dequeue_cmd), .r_clk_i(ui_clk), .r_reset_i(ui_clk_sync_rst),
    .r_data_o({ui_addr, ui_data, ui_mask, ui_wren, ui_burst}),
    .w_full_o(cmd_w_full), .r_valid_o(cmd_r_valid)
  );

  // Delay transactions 1 ui_clk so we can detect the end of a write and set app_wdf_end
  logic [1:0] app_burst;
  assign app_cmd = {2'b0, ~app_wdf_wren};
  assign app_wdf_end = app_wdf_wren & ~({ui_addr, ui_wren} == {app_addr, app_wdf_wren});
  flopen  #(ADDR_SIZE)   appaddrreg (ui_clk, ui_ready, ui_addr, app_addr);
  flopenr #(1)           appenreg   (ui_clk, ui_clk_sync_rst, ui_ready, dequeue_cmd, app_en);
  flopenr #(DATA_SIZE)   appdatareg (ui_clk, ui_clk_sync_rst, ui_ready, ui_data, app_wdf_data);
  flopenr #(DATA_SIZE/8) appmaskreg (ui_clk, ui_clk_sync_rst, ui_ready, ui_mask, app_wdf_mask);
  flopenr #(1)           appwrenreg (ui_clk, ui_clk_sync_rst, ui_ready, ui_wren, app_wdf_wren);
  flopenr #(2)           appbrstreg (ui_clk, ui_clk_sync_rst, ui_ready, ui_burst, app_burst);

  // Hold on to the number of response beats we want until the ui registers the next command (i.e the response is done)
  logic [1:0] resp_burst;
  flopenr #(2) respbrstreg (ui_clk, ui_clk_sync_rst, app_en, app_burst, resp_burst);
  
  // Return read data at HCLK speed
  logic resp_w_full, resp_r_valid;
  logic enqueue_resp, dequeue_resp;
  logic inc_resp_count, reset_resp_count;
  logic [4:0] resp_count;
  counter #(5) resp_beat_counter (ui_clk, reset_resp_count | ui_clk_sync_rst, inc_resp_count, resp_count);
  always_comb begin: resp_burst_capture_logic
    // Enqueue only the correct number of beats for each response
    inc_resp_count = app_rd_data_valid; // Increment every time we get a beat of valid response data
    reset_resp_count = app_en & app_wdf_wren; // Reset when the UI gets a write transaction
    enqueue_resp = app_rd_data_valid & ~resp_w_full & (|resp_burst ? resp_count < (5'b10 << resp_burst) : resp_count < 1); // Only enqueue 2^(resp_burst) beats of a burst read
    dequeue_resp = HSEL & resp_r_valid;
  end
  bsg_async_fifo #(
    .width_p(DATA_SIZE),
    .lg_size_p(16), // TODO: Parameterize based on wally config
    .and_data_with_valid_p(1)
  ) respfifo (
    .w_data_i(app_rd_data),
    .w_enq_i(enqueue_resp), .w_clk_i(ui_clk), .w_reset_i(ui_clk_sync_rst),
    .r_deq_i(dequeue_resp), .r_clk_i(HCLK), .r_reset_i(~HRESETn),
    .r_data_o(HRDATA),
    .w_full_o(resp_w_full), .r_valid_o(resp_r_valid)
  );
  
  // If there are only writes in the pipeline, accept commands until the buffer is full
  // If there is a read in the pipeline, stall until we have a valid response
  assign HREADYOUT = ~ahb_wren ? resp_r_valid : ~cmd_w_full;
  assign HRESP = 0; // do not indicate errors

endmodule

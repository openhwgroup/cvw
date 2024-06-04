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

module bsg_dmc_config_apb 
  import bsg_dmc_pkg::*;
#(
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
  input  logic                     ui_clk,
  output bsg_dmc_s                 dmc_config
);

  logic [7:0]   entry, wentry;
  logic         wren;
  logic [15:0]  wdata;
  logic [15:0]  rdata;
  logic         fifo_full, fifo_deq;

  assign entry  = {PADDR[7:3], 3'b000};
  assign wren   = PWRITE & PENABLE & PSEL;
  assign PREADY = ~fifo_full;

  // async reset
  always_ff @(negedge PRESETn) begin
    if (~PRESETn) begin
      // TODO: Should these be reset to Micron defaults instead?
      dmc_config.trefi        <= 0;
      dmc_config.tmrd         <= 0;
      dmc_config.trfc         <= 0;
      dmc_config.trc          <= 0;
      dmc_config.trp          <= 0;
      dmc_config.tras         <= 0;
      dmc_config.trrd         <= 0;
      dmc_config.trcd         <= 0;
      dmc_config.twr          <= 0;
      dmc_config.twtr         <= 0;
      dmc_config.trtp         <= 0;
      dmc_config.tcas         <= 0;
      dmc_config.col_width    <= 0;
      dmc_config.row_width    <= 0;
      dmc_config.bank_width   <= 0;
      dmc_config.bank_pos     <= 0;
      dmc_config.dqs_sel_cal  <= 0;
      dmc_config.init_cycles  <= 0;
    end
  end

  // Read on PCLK
  assign PRDATA = {APB_DATA_SIZE-17{1'b0}, rdata};
  always_ff @(posedge PCLK) begin
    case (entry)
      8'h00: rdata <=         dmc_config.trefi;
      8'h08: rdata <= {12'b0, dmc_config.tmrd};
      8'h10: rdata <= {12'b0, dmc_config.trfc};
      8'h18: rdata <= {12'b0, dmc_config.trc};
      8'h20: rdata <= {12'b0, dmc_config.trp};
      8'h28: rdata <= {12'b0, dmc_config.tras};
      8'h30: rdata <= {12'b0, dmc_config.trrd};
      8'h38: rdata <= {12'b0, dmc_config.trcd};
      8'h40: rdata <= {12'b0, dmc_config.twr};
      8'h48: rdata <= {12'b0, dmc_config.twtr};
      8'h50: rdata <= {12'b0, dmc_config.trtp};
      8'h58: rdata <= {12'b0, dmc_config.tcas};
      8'h60: rdata <= {12'b0, dmc_config.col_width};
      8'h68: rdata <= {12'b0, dmc_config.row_width};
      8'h70: rdata <= {14'b0, dmc_config.bank_width};
      8'h78: rdata <= {10'b0, dmc_config.bank_pos};
      8'h80: rdata <= {13'b0, dmc_config.dqs_sel_cal};
      8'h88: rdata <=         dmc_config.init_cycles;
    endcase
  end

  // Send writes to ui_clk domain
  bsg_async_fifo #(
    .lg_size_p(3),
    .width_p(8 + 16), // entry + data
  ) dmc_config_fifo (
    .w_clk_i(PCLK),
    .w_reset_i(~PRESETn),
    .w_enq_i(PWRITE),
    .w_data_i({entry, PWDATA[15:0]})
    .w_full_o(fifo_full),
    .r_clk_i(ui_clk),
    .r_reset_i(~PRESETn),
    .r_deq_i(fifo_deq),
    .r_data_o({wentry, wdata}),
    .r_valid_o(wren)
  );
  flop #(1) wdeqreg (ui_clk, wren, fifo_deq); // Dequeue after write
  
  // Write on ui_clk
  always_ff @(posedge ui_clk, negedge PRESETn) begin
    if (PRESETn & wren) begin // Only write if not resetting
      case (wentry)
        8'h00: dmc_config.trefi       <= wdata;
        8'h08: dmc_config.tmrd        <= wdata[3:0];
        8'h10: dmc_config.trfc        <= wdata[3:0];
        8'h18: dmc_config.trcd        <= wdata[3:0];
        8'h20: dmc_config.trp         <= wdata[3:0];
        8'h28: dmc_config.tras        <= wdata[3:0];
        8'h30: dmc_config.trrd        <= wdata[3:0];
        8'h38: dmc_config.trcd        <= wdata[3:0];
        8'h40: dmc_config.twr         <= wdata[3:0];
        8'h48: dmc_config.twtr        <= wdata[3:0];
        8'h50: dmc_config.trtp        <= wdata[3:0];
        8'h58: dmc_config.tcas        <= wdata[3:0];
        8'h60: dmc_config.col_width   <= wdata[3:0];
        8'h68: dmc_config.row_width   <= wdata[3:0];
        8'h70: dmc_config.bank_width  <= wdata[1:0];
        8'h78: dmc_config.bank_pos    <= wdata[5:0];
        8'h80: dmc_config.dqs_sel_cal <= wdata[2:0];
        8'h88: dmc_config.init_cycles <= wdata;
      endcase
    end
  end

endmodule

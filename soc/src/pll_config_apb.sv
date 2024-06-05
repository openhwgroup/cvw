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
  input  logic                     PLLrefclk,
  input  logic                     PLLrfen,
  input  logic                     PLLfben,
  output logic [5:0]               PLLclkr,
  output logic [12:0]              PLLclkf,
  output logic [3:0]               PLLclkod,
  output logic [11:0]              PLLbwadj,
  output logic                     PLLbypass,
  output logic                     PLLtest,
  input  logic                     PLLlock
);

  logic [7:0]  entry;
  logic        wren;
  logic [12:0] wdata;
  logic [12:0] rdata;
  logic [5:0]  wcode;

  assign entry  = {PADDR[7:3], 3'b0};
  assign wren   = PWRITE & PENABLE & PSEL;
  assign PREADY = 1;

  // Note that we don't reset these values when PRESETn is deasserted.
  // Since these values define our clock frequency, we probably don't want them reset
  // TODO: check if this ^ is correct

  // Read on PCLK
  assign PRDATA = {APB_DATA_SIZE-14{1'b0}, rdata}
  always_ff @(posedge PCLK) begin
    case (entry)
      8'h00:   rdata <= { 7'b0, PLLclkr};
      8'h08:   rdata <=         PLLclkf;
      8'h10:   rdata <= { 9'b0, PLLclkod};
      8'h18:   rdata <= { 1'b0, PLLbwadj};
      8'h20:   rdata <= {12'b0, PLLbypass};
      8'h28:   rdata <= {12'b0, PLLtest};
      8'h30:   rdata <= {12'b0, PLLlock};
      default: rdata <= 0;
    endcase
  end

  // Decode write address into one-hot enable
  always_comb begin
    if (wren) begin
      case (entry)
        8'h00:   wcode = 6'b100000;
        8'h08:   wcode = 6'b010000;
        8'h10:   wcode = 6'b001000;
        8'h18:   wcode = 6'b000100;
        8'h20:   wcode = 6'b000010;
        8'h28:   wcode = 6'b000001;
        default: wcode = 6'b000000;
      endcase
    end else begin
      wcode = 6'b000000;
    end
  end
  assign {clkr_en, clkf_en, clkod_en, bwadj_en, bypass_en, test_en} = wcode;

  // Writes are synced to different clocks depending on the signal
  flopen #(13) wdatareg (PCLK, wren, PWDATA[12:0], wdata);
  pll_sync #(6)  clkrsync   (.clk(PCLK), .trigger(PLLrfen),   .reset(~PRESETn), .data(wdata[5:0]),  .enable(clkr_enable),   .sync_data(PLLclkr));
  pll_sync #(13) clkfsync   (.clk(PCLK), .trigger(PLLfben),   .reset(~PRESETn), .data(wdata),       .enable(clkf_enable),   .sync_data(PLLclkf));
  pll_sync #(4)  clkodsync  (.clk(PCLK), .trigger(PLLrefclk), .reset(~PRESETn), .data(wdata[3:0]),  .enable(clkod_enable),  .sync_data(PLLclkod));
  pll_sync #(12) bwadjsync  (.clk(PCLK), .trigger(PLLrefclk), .reset(~PRESETn), .data(wdata[11:0]), .enable(bwadj_enable),  .sync_data(PLLbwadj));
  pll_sync #(1)  bypasssync (.clk(PCLK), .trigger(PLLrefclk), .reset(~PRESETn), .data(wdata[0]),    .enable(bypass_enable), .sync_data(PLLbypass));
  pll_sync #(1)  testsync   (.clk(PCLK), .trigger(PLLrefclk), .reset(~PRESETn), .data(wdata[0]),    .enable(test_enable),   .sync_data(PLLtest));

endmodule

module pll_sync #(parameter SIZE = 8) (
  input  logic            clk,
  input  logic            trigger,
  input  logic            reset,
  input  logic [SIZE-1:0] data,
  input  logic            enable,
  output logic [SIZE-1:0] sync_data
);

  // TCI sync logic from PLL guide

  logic selected_clk;
  logic [SIZE-1:0] data1d;
  logic            enable1d, enable2d;
  logic            sync_enable, sync_enable1d, sync_enable2d;

  // Use clk during reset. Otherwise sync to rising edge of trigger signal
  clockmux2 clkmux (trigger, ref_clk, reset, selected_clk);

  // Feedback loop for data enable
  always @(posedge clk or negedge sync_enable2d) begin: enablesync1
    // We use an SR FF to ensure enable is latched until data sync is complete
    if (reset) enable1d = 0;
    else begin
      if (enable)  enable1d <= 1;
      else         enable1d <= enable1d;
    end
  end
  flop  #(1) enablesync2 (selected_clk,                enable1d,      enable2d);
  flop  #(1) enablesync3 (selected_clk,                enable2d,      sync_enable);
  flop  #(1) enablesync4 (clk,                         sync_enable,   sync_enable1d);
  flop  #(1) enablesync5 (clk,                         sync_enable1d, sync_enable2d);

  // Pass data when we have a synchronized enable signal
  flopen #(SIZE) datasync1 (clk,          enable1d,    data, data1d);
  flopen #(SIZE) datasync2 (selected_clk, sync_enable, data1d, sync_data);

endmodule]

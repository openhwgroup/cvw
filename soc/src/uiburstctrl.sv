///////////////////////////////////////////
// uiburstctrl.sv
//
// Written: infinitymdm@gmail.com 24 March 2024
//
// Purpose: UI burst management for AHB to UI converter
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

module uiburstctrl #(parameter BURST_LEN = 8) (
  input  logic clk,
  input  logic reset,
  input  logic ui_initialized,
  input  logic app_rdy,
  input  logic app_wdf_rdy,
  input  logic write,
  input  logic op_ready,
  output logic app_en,
  output logic app_cmd0,
  output logic app_wdf_wren,
  output logic app_wdf_end,
  output logic dequeue_op
);
  // State Definitions
  // IDLE: Ready for next command (default)
  // WBIP: Write Burst In Progress: write addr issued, waiting for write data
  typedef enum logic {IDLE=0, WBIP} state;

  logic [$clog2(BURST_LEN)-1:0] op_count;
  logic inc_op_count;
  logic last_op;
  state current_state, next_state;
  logic [4:0] inputs;
  logic [5:0] outputs;

  // Op counter - used to track # reads or writes issued
  counter #($clog2(BURST_LEN)) op_counter (clk, reset, inc_op_count, op_count);
  assign last_op = &op_count;

  // State transition logic
  flopr #(1) statereg (clk, reset, next_state, current_state);
  always_comb begin
    inputs = {ui_initialized, app_rdy, app_wdf_rdy, write, op_ready};
    case (current_state)
      IDLE: casez (inputs)
              5'b0????: {next_state, outputs} = {IDLE, 6'b000000}; // Wait for init
              5'b1???0: {next_state, outputs} = {IDLE, 6'b001000}; // Wait for commands, assuming read
              5'b10?01: {next_state, outputs} = {IDLE, 6'b011000}; // Issue read w/o dequeuing
              5'b11?01: {next_state, outputs} = {IDLE, 6'b111000}; // Issue read and dequeue
              5'b10?11: {next_state, outputs} = {IDLE, 6'b010000}; // Prepare to write
              5'b11011: {next_state, outputs} = {WBIP, 6'b010000}; // Issue write addr w/o data
              5'b11111: {next_state, outputs} = {WBIP, 6'b110101}; // Issue write addr and data
            endcase
      WBIP: casez (inputs)
              5'b0????:              {next_state, outputs} = {IDLE, 6'b000000}; // This should never happen unless reset
              5'b1???0:              {next_state, outputs} = {WBIP, 6'b000000}; // Wait for more write data
              5'b1??01:              {next_state, outputs} = {WBIP, 6'b000000}; // This should never happen as long as ahbburstctrl works correctly
              5'b1?011:              {next_state, outputs} = {WBIP, 6'b000000}; // Wait until UI is ready for write data
              5'b1?111: if (last_op) {next_state, outputs} = {IDLE, 6'b100111}; // Issue write data and end the burst
                        else         {next_state, outputs} = {WBIP, 6'b100101}; // Issue write data
            endcase
    endcase
  end
  assign {dequeue_op, app_en, app_cmd0, app_wdf_wren, app_wdf_end, inc_op_count} = outputs;

endmodule

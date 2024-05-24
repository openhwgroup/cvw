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
  input  logic app_rdy,
  input  logic app_wdf_rdy,
  input  logic write,
  input  logic op_ready,
  input  logic app_rd_data_valid,
  output logic app_en,
  output logic app_cmd0,
  output logic app_wdf_wren,
  output logic app_wdf_end,
  output logic dequeue_op
);
  typedef enum logic [1:0] {IDLE=0, RBIP, WBIP} state;

  logic [$clog2(BURST_LEN)-1:0] op_count;
  logic inc_op_count;
  logic last_op;
  state current_state, next_state;
  logic [4:0] inputs;
  logic [5:0] outputs;

  // Op counter - used to track # writes issued and # read responses received
  counter #($clog2(BURST_LEN)) op_counter (clk, reset, inc_op_count, op_count);
  assign last_op = &op_count;

  // State transition logic
  flopr #(2) statereg (clk, reset, next_state, current_state);
  always_comb begin
    inputs = {app_rdy, app_wdf_rdy, write, op_ready, app_rd_data_valid};
    case (current_state)
      IDLE: casez (inputs)
              5'b0????: {next_state, outputs} = {IDLE, 6'b000000};
              5'b1??0?: {next_state, outputs} = {IDLE, 6'b000000};
              5'b1?01?: {next_state, outputs} = {RBIP, 6'b011000};
              5'b1011?: {next_state, outputs} = {IDLE, 6'b000000};
              5'b1111?: {next_state, outputs} = {WBIP, 6'b110101};
            endcase
      RBIP: casez (inputs)
              5'b????0: {next_state, outputs} = {RBIP, 6'b011000};
              5'b????1: if (last_op) {next_state, outputs} = {IDLE, 6'b111001};
                        else         {next_state, outputs} = {RBIP, 6'b011001};
            endcase
      WBIP: casez (inputs)
              5'b0????: {next_state, outputs} = {WBIP, 6'b000000};
              5'b1??0?: {next_state, outputs} = {WBIP, 6'b000000};
              5'b10?1?: {next_state, outputs} = {WBIP, 6'b000000};
              5'b11?1?: if (last_op) {next_state, outputs} = {IDLE, 6'b110111};
                        else         {next_state, outputs} = {WBIP, 6'b110101};
            endcase
    endcase
  end
  assign {dequeue_op, app_en, app_cmd0, app_wdf_wren, app_wdf_end, inc_op_count} = outputs;

endmodule

///////////////////////////////////////////
// ahbburstctrl.sv
//
// Written: infinitymdm@gmail.com 20 May 2024
//
// Purpose: Burst management FSM for AHB to UI converter
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

module ahbburstctrl #(parameter BURST_LEN = 8) (
  input  logic clk,
  input  logic reset,
  input  logic op_ready,            // Manager has valid address phase signals on the AHB bus
  input  logic write,               // Manager has issued a write operation
  input  logic burst,               // Manager has started a new burst
  input  logic cmd_full,            // Subordinate cannot accept a command right now
  input  logic resp_valid,          // Subordinate has response data ready
  output logic capture_op,          // Capture the current AHB op so we can issue it to the subordinate
  output logic record_op,           // Store the current AHB op so we have the option of issuing it to the subordinate later
  output logic select_recorded_op,  // Mux the recorded op to the subordinate
  output logic issue_op,            // Commit the selected op to the subordinate
  output logic ready                // Manager can send more commands
);
  // State Definitions
  // IDLE: Ready to start the next burst (default)
  // RBWT: Ready to send read burst, waiting on subordinate
  // RBIP: Read Burst In Progress
  // DROP: Read Burst response received, drop excess burst commands
  // WBWT: Ready to send next beat of write burst, waiting on subordinate
  // WBIP: Write Burst In Progress
  // RPTW: Repeat last write op to complete a burst, then start new write burst
  // RPTR: Repeat last write op to complete a burst, then start new read burst
  typedef enum logic [2:0] {IDLE=0, RBWT, RBIP, DROP, WBWT, WBIP, RPTW, RPTR} state;

  // Op counter
  logic [$clog2(BURST_LEN)-1:0] op_count;
  logic inc_op_count;
  counter #($clog2(BURST_LEN)) op_counter (clk, reset, inc_op_count, op_count);

  // Aliases for readability (mostly)
  logic read;
  assign read = ~write;
  logic first_op, last_op;
  assign first_op = ~|op_count; // true when op_count is all 0s
  assign last_op = &op_count; // true when op_count is all 1s

  // State transition logic
  state current_state, next_state;
  flopr #(3) statereg (clk, reset, next_state, current_state);
  logic [4:0] inputs;
  logic [5:0] outputs;
  logic record_op_next, issue_op_next, ready_next, ready_delayed;
  always_comb begin: state_transition_logic
    inputs = {op_ready, cmd_full, write, burst, resp_valid};
    case (current_state)
      IDLE: casez (inputs)
              5'b0????: {next_state, outputs} = {IDLE, 6'b000010};
              5'b100??: {next_state, outputs} = {RBIP, 6'b100101};
              5'b101??: {next_state, outputs} = {WBIP, 6'b110111};
              5'b110??: {next_state, outputs} = {RBWT, 6'b110000};
              5'b111??: {next_state, outputs} = {WBWT, 6'b110000};
            endcase
      RBWT: casez (inputs)
              5'b?0???: {next_state, outputs} = {RBIP, 6'b001101};
              5'b?1???: {next_state, outputs} = {RBWT, 6'b000000};
            endcase
      RBIP: casez (inputs)
              5'b????0: {next_state, outputs} = {RBIP, 6'b000000};
              5'b0???1: {next_state, outputs} = {DROP, 6'b000010};
              5'b1???1: {next_state, outputs} = {DROP, 6'b000011};
            endcase
      DROP: casez (inputs)
              5'b0????: {next_state, outputs} = {DROP, 6'b000010};
              5'b1????: {next_state, outputs} = {last_op? IDLE : DROP, 6'b000011};
            endcase
      WBWT: casez (inputs)
              5'b?0???: {next_state, outputs} = {WBIP, 6'b001111};
              5'b?1???: {next_state, outputs} = {WBWT, 6'b000000};
            endcase
      WBIP: casez (inputs)
              5'b0????: {next_state, outputs} = {WBIP, 6'b000010};
              5'b100??: {next_state, outputs} = {RPTR, 6'b101101};
              5'b1010?: if (last_op) {next_state, outputs} = {IDLE, 6'b100111};
                        else         {next_state, outputs} = {WBIP, 6'b110111};
              5'b1011?: {next_state, outputs} = {RPTW, 6'b101101};
              5'b110??: {next_state, outputs} = {RPTR, 6'b100000};
              5'b111??: {next_state, outputs} = {WBWT, 6'b110000};
            endcase
      RPTW: casez (inputs)
              5'b?0???: if (first_op) {next_state, outputs} = {WBIP, 6'b001111};
                        else          {next_state, outputs} = {RPTW, 6'b001101};
              5'b?1???: {next_state, outputs} = {RPTW, 6'b000000};
            endcase
      RPTR: casez (inputs)
              5'b?0???: if (first_op) {next_state, outputs} = {RBIP, 6'b001101};
                        else          {next_state, outputs} = {RPTR, 6'b001101};
              5'b?1???: {next_state, outputs} = {RPTR, 6'b000000};
            endcase
    endcase
  end

  assign {capture_op, record_op_next, select_recorded_op, issue_op_next, ready_next, inc_op_count} = outputs;

  // Delay signals to align with ops
  flopr #(1) recordreg (clk, reset, record_op_next, record_op);
  flopr #(1) issuereg (clk, reset, issue_op_next, issue_op);

  // Deassert ready immediately, but assert synchronously
  flopr #(1) readyreg (clk, reset, ready_next, ready_delayed);
  assign ready = ready_next & ready_delayed;

endmodule

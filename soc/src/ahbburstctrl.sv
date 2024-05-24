///////////////////////////////////////////
// ahbburstctrl.sv
//
// Written: infinitymdm@gmail.com 20 May 2024
//
// Purpose: AHB burst management FSM for AHB to UI converter
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
  input  logic cmd_full,            // Subordinate cannot accept a command right now
  input  logic new_addr,            // Manager is addressing a new location in memory
  input  logic [3:0] word_addr,     // Lower bits of the write address
  input  logic write,               // Manager has issued a write operation
  input  logic new_burst,           // Manager has initiated a new burst
  input  logic resp_valid,          // Subordinate has response data ready
  output logic capture_op,          // Capture the current AHB op so we can issue it to the subordinate
  output logic record_op,           // Store the current AHB op so we have the option of issuing it to the subordinate later
  output logic select_recorded_op,  // Mux the recorded op to the subordinate
  output logic mask_write,          // Mask off all bytes in this write op
  output logic issue_op,            // Commit the selected op to the subordinate
  output logic readyout             // Manager can send more commands
);
  // State Definitions (TODO: Update)
  // IDLE: Ready to start the next burst (default)
  // DLYR: Delay Read burst until subordinate is ready
  // RBIP: Read Burst In Progress
  // DROP: Read Burst response received, drop excess burst commands
  // RPTW: Repeat last write op to complete a burst, then start new write burst
  // RPTR: Repeat last write op to complete a burst, then start new read burst
  // RPTP: Repeat last write op to complete a burst, then pad the new write burst
  // WBIP: Write Burst In Progress
  // DLYW: Delay Write burst until subordinate is ready
  // DLYP: Delay write burst until subordinate is ready, then pad until word aligned
  // PADW: Pad Write burst until word aligned
  typedef enum logic [3:0] {IDLE=0, DLYR, RBIP, DROP, RPTR, RPTW, RPTP, WBIP, DLYW, DLYP, PADW} state;

  logic [$clog2(BURST_LEN)-1:0] op_count;
  logic inc_op_count;
  logic first_op, last_op;
  logic word_aligned, word_zero;
  state current_state, next_state;
  logic [5:0] inputs;
  logic [6:0] outputs;
  logic record_op_next, mask_write_next, issue_op_next, ready_next, ready;

  // Op counter
  counter #($clog2(BURST_LEN)) op_counter (clk, reset, inc_op_count, op_count);

  // Aliases/shorthands for readability
  assign first_op = ~|op_count; // true when op_count is all 0s
  assign last_op = &op_count; // true when op_count is all 1s
  assign word_aligned = (word_addr == {op_count, 1'b0}); // word_addr == 2*op_count
  assign word_zero = ~|word_addr; // word_addr == 4'b0000

  // We make a few big assumptions on the read side of things, that so far have proved valid:
  // 1) AHB will never issue a read burst that is not aligned to the start of a word
  // 2) AHB read bursts will always address all 8 bytes of the same word

  // State transition logic
  flopr #(4) statereg (clk, reset, next_state, current_state);
  always_comb begin
    inputs = {op_ready, cmd_full, new_addr, write, new_burst, resp_valid};
    case (current_state)
      IDLE: casez (inputs)
              6'b0?????: {next_state, outputs} = {IDLE, 7'b0000001};
              6'b10?0??: {next_state, outputs} = {RBIP, 7'b1000110};
              6'b10?1??: if (word_aligned) {next_state, outputs} = {WBIP, 7'b1100111};
                         else              {next_state, outputs} = {PADW, 7'b1101110};
              6'b11?0??: {next_state, outputs} = {DLYR, 7'b1100000};
              6'b11?1??: {next_state, outputs} = {DLYW, 7'b1100000};
            endcase
      DLYR: case (cmd_full)
              1'b0: {next_state, outputs} = {RBIP, 7'b0010110};
              1'b1: {next_state, outputs} = {DLYR, 7'b0000000};
            endcase
      RBIP: casez (inputs)
              6'b?????0: {next_state, outputs} = {RBIP, 7'b0000000};
              6'b0????1: {next_state, outputs} = {DROP, 7'b0000001};
              6'b1????1: {next_state, outputs} = {DROP, 7'b0000011};
            endcase
      DROP: casez (inputs)
              6'b0?????: {next_state, outputs} = {DROP, 7'b0000001};
              6'b1?????: if (last_op) {next_state, outputs} = {IDLE, 7'b0000011};
                         else         {next_state, outputs} = {DROP, 7'b0000011};
            endcase
      RPTR: case (cmd_full)
              1'b0: if (first_op) {next_state, outputs} = {RBIP, 7'b0010110};
                    else          {next_state, outputs} = {RPTR, 7'b0011110};
              1'b1: {next_state, outputs} = {RPTR, 7'b0000000};
            endcase
      RPTW: case (cmd_full)
              1'b0: if (first_op) {next_state, outputs} = {WBIP, 7'b0010111};
                    else          {next_state, outputs} = {RPTW, 7'b0011110};
              1'b1: {next_state, outputs} = {RPTW, 7'b0000000};
            endcase
      RPTP: case (cmd_full)
              1'b0: if (first_op) {next_state, outputs} = {PADW, 7'b0011110};
                    else          {next_state, outputs} = {RPTP, 7'b0011110};
              1'b1: {next_state, outputs} = {RPTP, 7'b0000000};
            endcase
      WBIP: casez (inputs)
              6'b0?????: {next_state, outputs} = {WBIP, 7'b0000001};
              6'b10?0??: {next_state, outputs} = {RPTR, 7'b1011110};
              6'b10010?: if (word_aligned)
                           if (last_op) {next_state, outputs} = {IDLE, 7'b1000111};
                           else         {next_state, outputs} = {WBIP, 7'b1100111};
                         else {next_state, outputs} = {PADW, 7'b1101110};
              6'b10011?: if (word_zero) {next_state, outputs} = {RPTW, 7'b1011110}; // new burst starts at word zero
                         else           {next_state, outputs} = {RPTP, 7'b1011110}; // new burst needs padding out
              6'b1011??: if (word_zero) {next_state, outputs} = {RPTW, 7'b1011110}; // burst to new addr starts at word zero
                         else           {next_state, outputs} = {RPTP, 7'b1011110}; // burst to new addr needs padding out
              6'b11?0??: {next_state, outputs} = {RPTR, 7'b1000000};
              6'b11010?: if (word_aligned) {next_state, outputs} = {DLYW, 7'b1100000};
                         else              {next_state, outputs} = {DLYP, 7'b1100000};
              6'b11011?: {next_state, outputs} = {RPTW, 7'b1000000};
              6'b1111??: {next_state, outputs} = {RPTW, 7'b1000000};
            endcase
      DLYW: case (cmd_full)
              1'b0: if (last_op) {next_state, outputs} = {IDLE, 7'b0010111};
                    else         {next_state, outputs} = {WBIP, 7'b0010111};
              1'b1: {next_state, outputs} = {DLYW, 7'b0000000};
            endcase
      DLYP: case (cmd_full)
              1'b0: {next_state, outputs} = {PADW, 7'b0011111};
              1'b1: {next_state, outputs} = {DLYP, 7'b0000000};
            endcase
      PADW: case (cmd_full)
              1'b0: if (word_aligned) {next_state, outputs} = {WBIP, 7'b0010111};
                    else              {next_state, outputs} = {PADW, 7'b0011110};
              1'b1: {next_state, outputs} = {PADW, 7'b0000000};
            endcase
    endcase
  end
  assign {capture_op, record_op_next, select_recorded_op, mask_write_next, issue_op_next, inc_op_count, ready_next} = outputs;

  // Delay signals to align with ops
  flopr #(1) recordreg (clk, reset, record_op_next,  record_op);
  flopr #(1) maskreg   (clk, reset, mask_write_next, mask_write);
  flopr #(1) issuereg  (clk, reset, issue_op_next,   issue_op);
  flopr #(1) readyreg  (clk, reset, ready_next,      ready);
  assign readyout = ready_next & ready;  // Deassert readyout immediately, but assert synchronously

endmodule

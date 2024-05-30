///////////////////////////////////////////
// ahbburstctrl.sv
//
// Written: infinitymdm@gmail.com 20 May 2024
// Modified: infinitymdm@gmail.com 25 May 2024
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
  output logic drop_resp,           // Discard response data from the subordinate
  output logic readyout             // Manager can send more commands
);
  // State Definitions
  typedef enum logic [4:0] {
    IDLE=0, // Ready to start the next burst (default)
    DLYR,   // Delay Read burst until subordinate is ready
    DLYPR,  // Delay Read burst until subordinate is ready, then pad until word aligned
    RBIP,   // Read Burst In Progress
    DROP,   // Read burst response received, check & drop aligned read commands
    DRPR,   // Drop unaligned read responses, then start new Read burst
    DRPPR,  // Drop remaining read responses, then start new Read burst by way of PADR
    DRPW,   // Drop remaining read responses, then start new Write burst
    DRPPW,  // Drop remaining read responses, then start new Write burst by way of PADW
    PADR,   // Read burst issued, but read command is not word aligned. Realign by dropping unaligned responses
    RPTR,   // Repeat last write op to complete a burst, then start new Read burst
    RPTPR,  // Repeat last write op to complete a burst, then start new Read burst by way of PADR
    RPTW,   // Repeat last write op to complete a burst, then start new Write burst
    RPTPW,  // Repeat last write op to complete a burst, then start new Write burst by way of PADW
    WBIP,   // Write Burst In Progress
    DLYW,   // Delay Write burst until subordinate is ready
    DLYPW,  // Delay write burst until subordinate is ready, then pad until word aligned
    PADW    // Pad Write burst by issuing masked writes until word aligned
  } state;

  logic [$clog2(BURST_LEN)-1:0] op_count;
  logic inc_op_count;
  logic first_op, last_op;
  logic word_aligned, word_zero;
  state current_state, next_state;
  logic [7:0] outputs;
  logic record_op_next, mask_write_next, issue_op_next, ready_next, ready;

  // Op counter
  counter #($clog2(BURST_LEN)) op_counter (clk, reset, inc_op_count, op_count);

  // Aliases/shorthands for readability
  assign first_op = ~|op_count; // true when op_count is all 0s
  assign last_op = &op_count; // true when op_count is all 1s
  assign word_aligned = (word_addr == {op_count, 1'b0}); // word_addr == 2*op_count // FIXME: If BURST_LEN != 8, op_count is the wrong size
  assign word_zero = ~|word_addr; // word_addr == 4'b0000

  // State transition logic
  flopr #(5) statereg (clk, reset, next_state, current_state);
  always_comb begin
    case (current_state)
      IDLE: casez ({op_ready, cmd_full, write, word_aligned})
              4'b0???: {next_state, outputs} = {IDLE,  8'b00000010}; // Wait for command
              4'b1000: {next_state, outputs} = {PADR,  8'b10001000}; // We have a misaligned read. Issue read burst and drop responses until realigned.
              4'b1001: {next_state, outputs} = {RBIP,  8'b10001100}; // We have an aligned read. Issue read burst and wait for response. Precount the first response beat.
              4'b1010: {next_state, outputs} = {PADW,  8'b11011100}; // We have a misaligned write. Pad write burst with masked writes until aligned with the incoming word.
              4'b1011: {next_state, outputs} = {WBIP,  8'b11001110}; // We have an aligned write. Issue write and wait for next write in burst.
              4'b1100: {next_state, outputs} = {DLYPR, 8'b11000000}; // We have a misaligned write, and the command queue is full Record op and wait for a spot in the queue, then pad read. 
              4'b1101: {next_state, outputs} = {DLYR,  8'b11000000}; // We have an aligned read, but the command queue is full. Record op and wait for a spot in the queue, then issue read.
              4'b1110: {next_state, outputs} = {DLYPW, 8'b11000000}; // We have a misaligned write, and the command queue is full. Record op and wait for a spot in the queue, then pad write.
              4'b1111: {next_state, outputs} = {DLYW,  8'b11000000}; // We have an aligned write, but the command queue is full. Record op and wait for a spot in the queue, then issue write.
            endcase
      DLYR: case (cmd_full)
              1'b0: {next_state, outputs} = {RBIP, 8'b00101100}; // Subordinate is ready for command. Issue read and wait for response.
              1'b1: {next_state, outputs} = {DLYR, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      DLYPR:case (cmd_full)
              1'b0: {next_state, outputs} = {PADR,  8'b00101100}; // Subordinate is ready for command. Issue read and drop responses until aligned.
              1'b1: {next_state, outputs} = {DLYPR, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      RBIP: casez ({resp_valid, op_ready, write, new_addr, word_aligned, word_zero})
              6'b0?????: {next_state, outputs} = {RBIP,  8'b00000000}; // Wait for response data from subordinate
              6'b10????: {next_state, outputs} = {DROP,  8'b00000010}; // Response rx'd. Wait for next read in burst.
              6'b11000?: {next_state, outputs} = {PADR,  8'b11000000}; // Response rx'd, but next read op is misaligned. Realign by dropping responses.
              6'b11001?: {next_state, outputs} = {DROP,  8'b00000110}; // Response rx'd. Drop the aligned read op on the bus.
              6'b1101?0: {next_state, outputs} = {DRPPR, 8'b11000000}; // Response rx'd, but we have a misaligned read targeting a new address. Drop remaining responses then pad out the new read.
              6'b1101?1: {next_state, outputs} = {DRPR,  8'b11000000}; // Response rx'd, but we have a read targeting a new address. Drop remaining responses then issue the new read.
              6'b111??0: {next_state, outputs} = {DRPPW, 8'b11000000}; // Response rx'd, but we have a misaligned write. Drop remaining responses then pad out the new write.
              6'b111??1: {next_state, outputs} = {DRPW,  8'b11000000}; // Response rx'd, but we have a write. Drop remaining responses then issue the new write.
            endcase
      DROP: casez ({op_ready, write, new_addr, word_aligned, last_op, word_zero})
              6'b0?????: {next_state, outputs} = {DROP,  8'b00000010}; // Wait for manager to send the next beat in the read burst
              6'b1000??: {next_state, outputs} = {PADR,  8'b11000000}; // We have a misaligned read op. Realign by dropping responses.
              6'b10010?: {next_state, outputs} = {DROP,  8'b00000110}; // We have an aligned read op. Ignore the op since we already have the response data, then wait for the next beat.
              6'b10011?: {next_state, outputs} = {IDLE,  8'b00000110}; // We have an aligned read op. Ignore the op since we already have the response data, then wait for a new op.
              6'b101??0: {next_state, outputs} = {DRPPR, 8'b11000000}; // We have a misaligned read targeting a new address. Drop remaining responses then pad out the new read.
              6'b101??1: {next_state, outputs} = {DRPR,  8'b11000000}; // We have an aligned read targeting a new address. Drop remaining responses then issue the new read.
              6'b11???0: {next_state, outputs} = {DRPPW, 8'b11000000}; // We have a misaligned write. Drop remaining responses then pad out the new write.
              6'b11???1: {next_state, outputs} = {DRPW,  8'b11000000}; // We have an aligned write. Drop remaining responses then issue the new write.
            endcase
      DRPR: casez ({resp_valid, cmd_full})
              2'b00: {next_state, outputs} = {RBIP, 8'b00101100}; // We've dropped all read responses and subordinate is ready for command. Issue read and wait for response.
              2'b01: {next_state, outputs} = {DLYPR, 8'b00000000}; // We've dropped all read responses. Wait until subordinate is ready for command.
              2'b1?: {next_state, outputs} = {DRPR, 8'b00000101}; // Drop this beat of the read response.
            endcase
      DRPPR:casez ({resp_valid, cmd_full})
              2'b00: {next_state, outputs} = {PADR,  8'b00101100}; // We've dropped all read responses and subordinate is ready for command. Pad read.
              2'b01: {next_state, outputs} = {DLYPR, 8'b00000000}; // We've dropped all read responses. Wait until subordinate is ready for command.
              2'b1?: {next_state, outputs} = {DRPR,  8'b00000101}; // Drop this beat of the read response.
            endcase
      DRPW: casez ({resp_valid, cmd_full})
              2'b00: {next_state, outputs} = {WBIP,  8'b00101110}; // We've dropped all read responses and subordinate is ready for command. Issue write and wait for next beat in burst.
              2'b01: {next_state, outputs} = {DLYPW, 8'b00000000}; // We've dropped all read responses. Wait until subordinate is ready for command.
              2'b1?: {next_state, outputs} = {DRPW,  8'b00000101}; // Drop this beat of the read response.
            endcase
      DRPPW:casez ({resp_valid, cmd_full})
              2'b00: {next_state, outputs} = {PADW,  8'b00111110}; // We've dropped all read responses and subordinate is ready for command. Pad write.
              2'b01: {next_state, outputs} = {DLYPW, 8'b00000000}; // We've dropped all read responses. Wait until subordinate is ready for command.
              2'b1?: {next_state, outputs} = {DRPPW, 8'b00000101}; // Drop this beat of the read response.
            endcase
      PADR: casez ({resp_valid, word_aligned, first_op, cmd_full})
              4'b0?0?: {next_state, outputs} = {PADR, 8'b00000000}; // Wait for response data
              4'b0?10: {next_state, outputs} = {PADR, 8'b00101100}; // We dropped all remaining beats of the burst without realigning. Issue a new read and wait for data. Precount the first beat. (NOTE: This should only happen if we have a misordered read burst, e.g. 0x08 followed by 0x00)
              4'b0?11: {next_state, outputs} = {PADR, 8'b00000000}; // We are out of response data, but queue is full. Wait for queue to open up.
              4'b10??: {next_state, outputs} = {PADR, 8'b00000101}; // Response is misaligned. Drop this beat of response data.
              4'b11??: {next_state, outputs} = {DROP, 8'b00000110}; // Response is now realigned with the read burst. Return to normal read burst handling.
            endcase
      RPTR: casez ({cmd_full, first_op})
              2'b00: {next_state, outputs} = {RPTR, 8'b00111100}; // Subordinate is ready for command, and write burst is incomplete. Mask and reissue the write op.
              2'b01: {next_state, outputs} = {RBIP, 8'b00101100}; // Subordinate is ready for command, and write burst is complete. Issue the captured read burst.
              2'b1?: {next_state, outputs} = {RPTR, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      RPTPR:casez ({cmd_full, first_op})
              2'b00: {next_state, outputs} = {RPTPR, 8'b00111100}; // Subordinate is ready for command, and write burst is incomplete. Mask and reissue the write op.
              2'b01: {next_state, outputs} = {PADR,  8'b01101100}; // Subordinate is ready for command, and write burst is complete. Issue the captured read burst and drop responses until aligned.
              2'b1?: {next_state, outputs} = {RPTPR, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      RPTW: casez ({cmd_full, first_op})
              2'b00: {next_state, outputs} = {RPTW, 8'b00111100}; // Subordinate is ready for command, and write burst is incomplete. Mask and reissue the write op.
              2'b01: {next_state, outputs} = {WBIP, 8'b00101110}; // Subordinate is ready for command, and write burst is complete. Issue the captured write burst.
              2'b1?: {next_state, outputs} = {RPTW, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      RPTPW:casez ({cmd_full, first_op})
              2'b00: {next_state, outputs} = {RPTPW, 8'b00111100}; // Subordinate is ready for command, and write burst is incomplete. Mask and reissue the write op.
              2'b01: {next_state, outputs} = {PADW,  8'b01111110}; // Subordinate is ready for command, and write burst is complete. Pad out the captured write burst.
              2'b1?: {next_state, outputs} = {RPTPW, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      WBIP: casez ({op_ready, cmd_full, write, new_burst, new_addr, word_aligned, word_zero, last_op})
              8'b0???????: {next_state, outputs} = {WBIP,  8'b00000010}; // Wait for command
              8'b100???0?: {next_state, outputs} = {RPTPR, 8'b10111100}; // We have a misaligned read. Repeat write op until burst is complete, then issue read and drop responses until aligned.
              8'b100???1?: {next_state, outputs} = {RPTR,  8'b10111100}; // We have an aligned read. Repeat write op until burst is complete, then issue read.
              8'b101000??: {next_state, outputs} = {PADW,  8'b11011100}; // We have a misaligned write. Pad until realigned.
              8'b101001?0: {next_state, outputs} = {WBIP,  8'b11001110}; // We have an aligned write, and the burst is not complete. Issue write, then wait for next write in burst.
              8'b101001?1: {next_state, outputs} = {IDLE,  8'b10001110}; // We have an aligned write that will complete the burst. Issue the write and wait for new op.
              8'b10101?0?: {next_state, outputs} = {RPTPW, 8'b10111100}; // We have a misaligned write targeting a new address. Repeat write op until burst is complete, then pad new write.
              8'b10101?1?: {next_state, outputs} = {RPTW,  8'b10111100}; // We have an aligned write targeting a new address. Repeat write op until burst is complete, then issue new write.
              8'b1011??0?: {next_state, outputs} = {RPTPW, 8'b10111100}; // We have a misaligned write starting a new burst. Repeat write op until burst is complete, then pad new write.
              8'b1011??1?: {next_state, outputs} = {RPTW,  8'b10111100}; // We have an aligned write starting a new burst. Repeat write op until burst is complete, then issue new write.
              8'b110???0?: {next_state, outputs} = {RPTPR, 8'b10000000}; // We have a misaligned read, but queue is full. Wait on the queue, then repeat write until burst complete, then issue read and drop responses until aligned.
              8'b110???1?: {next_state, outputs} = {RPTR,  8'b10000000}; // We have an aligned read, but queue is full. Wait on the queue, then repeat write until burst complete, then issue read.
              8'b111000??: {next_state, outputs} = {DLYPW, 8'b10000000}; // We have a misaligned write, but the queue is full. Wait on the queue, then pad the write.
              8'b111001??: {next_state, outputs} = {DLYW,  8'b10000000}; // We have an aligned write, but the queue is full. Wait on the queue, then issue the write.
              8'b11101?0?: {next_state, outputs} = {RPTPW, 8'b10000000}; // We have a misaligned write targeting a new address. Wait on the queue, then repeat write until burst complete, then pad new write.
              8'b11101?1?: {next_state, outputs} = {RPTW,  8'b10000000}; // We have an aligned write targeting a new address. Wait on the queue, then repeat write until burst complete, then issue new write.
              8'b1111??0?: {next_state, outputs} = {RPTPW, 8'b10000000}; // We have a misaligned write starting a new burst. Wait on the queue, then repeat write until burst complete, then pad new write.
              8'b1111??1?: {next_state, outputs} = {RPTW,  8'b10000000}; // We have an aligned write starting a new burst. Wait on the queue, then repeat write until burst complete, then issue new write.
            endcase
      DLYW: casez ({cmd_full, last_op})
              2'b00: {next_state, outputs} = {WBIP, 8'b00101110}; // Subordinate is ready for command, and write burst is incomplete. Issue write and wait for next write in burst.
              2'b01: {next_state, outputs} = {IDLE, 8'b00101110}; // Subordinate is ready for command, and this write completes the burst. Issue write and wait for new op.
              2'b1?: {next_state, outputs} = {DLYW, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      DLYPW:case (cmd_full)
              1'b0: {next_state, outputs} = {PADW,  8'b00111110}; // Subordinate is ready for command. Pad write until realigned.
              1'b1: {next_state, outputs} = {DLYPW, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
      PADW: casez ({cmd_full, word_aligned, last_op})
              3'b00?: {next_state, outputs} = {PADW, 8'b00111100}; // Subordinate is ready for command. Issue masked write to realign burst.
              3'b010: {next_state, outputs} = {WBIP, 8'b00101110}; // Subordinate is ready for command and burst is aligned. Issue and wait for next write in burst.
              3'b011: {next_state, outputs} = {IDLE, 8'b00101110}; // Subordinate is ready for command, burst is aligned, and this write completes the burst. Issue and wait for next op.
              3'b1??: {next_state, outputs} = {PADW, 8'b00000000}; // Wait until subordinate is ready for command
            endcase
    endcase
  end
  assign {capture_op, record_op_next, select_recorded_op, mask_write_next, issue_op_next, inc_op_count, ready_next, drop_resp} = outputs;

  // Delay signals to align with ops
  flopr #(1) recordreg (clk, reset, record_op_next,  record_op);
  flopr #(1) maskreg   (clk, reset, mask_write_next, mask_write);
  flopr #(1) issuereg  (clk, reset, issue_op_next,   issue_op);
  flopr #(1) readyreg  (clk, reset, ready_next,      ready);
  assign readyout = ready_next & ready;  // Deassert readyout immediately, but assert synchronously

endmodule

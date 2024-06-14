///////////////////////////////////////////
// dmc.sv
//
// Written: matthew.n.otto@okstate.edu 10 May 2024
// Modified: 
//
// Purpose: Controls pipeline during Debug Mode
// 
// Documentation: RISC-V System on Chip Design 
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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

// Note: This module controls all of the per-hart debug state.
// In a multihart system, this module should be instantiated under wallypipelinedcore

module dmc(
  input  logic clk, reset,
  input  logic Step,
  input  logic HaltReq,      // Initiates core halt
  input  logic ResumeReq,    // Initiates core resume
  input  logic HaltOnReset,  // Halts core immediately on hart reset
  input  logic AckHaveReset, // Clears HaveReset status

  output logic DebugMode,
  output logic ResumeAck,    // Signals Hart has been resumed
  output logic HaveReset,    // Signals Hart has been reset
  output logic DebugStall    // Stall signal goes to hazard unit
);
  enum logic {RUNNING, HALTED} State;

  always_ff @(posedge clk) begin
    if (reset)
      HaveReset <= 1;
    else if (AckHaveReset)
      HaveReset <= 0;
  end

  assign DebugMode = (State != RUNNING); // TODO: update this
  assign DebugStall = (State == HALTED);

  always_ff @(posedge clk) begin
    if (reset)
      State <= HaltOnReset ? HALTED : RUNNING;
    else begin
      case (State)
        RUNNING : begin
          State <= Step | HaltReq ? HALTED : RUNNING;
        end

        HALTED : begin
          State <= ResumeReq ? RUNNING : HALTED;
          ResumeAck <= ResumeReq ? 1 : ResumeAck;
        end
      endcase
    end
  end
endmodule

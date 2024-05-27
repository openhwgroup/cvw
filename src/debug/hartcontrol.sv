///////////////////////////////////////////
// hartcontrol.sv
//
// Written: matthew.n.otto@okstate.edu 10 May 2024
// Modified: 
//
// Purpose: Controls the state of connected hart
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

module hartcontrol(
  input  logic clk, rst,
  input  logic NdmReset,    // Triggers HaltOnReset behavior

  input  logic HaltReq,     // Initiate core halt
  input  logic ResumeReq,   // Initiates core resume
  input  logic HaltOnReset, // Halts core immediately on hart reset
  input  logic Step,        // Halts one cycle after a resume if asserted

  output logic DebugStall,  // Stall signal goes to hazard unit

  // DMStatus bits
  output logic Halted,
  output logic AllRunning,
  output logic AnyRunning,
  output logic AllHalted,
  output logic AnyHalted,
  output logic AllResumeAck,
  output logic AnyResumeAck
);

  assign Halted = DebugStall;
  assign AllRunning = ~DebugStall;
  assign AnyRunning = ~DebugStall;
  assign AllHalted = DebugStall;
  assign AnyHalted = DebugStall;
  assign AllResumeAck = ~DebugStall;
  assign AnyResumeAck = ~DebugStall;

  (* mark_debug = "true" *)enum bit [1:0] {
    RUNNING,
    HALTED,
    STEP
  } State;

  assign DebugStall = (State == HALTED);

  always_ff @(posedge clk) begin
    if (rst)
      State <= RUNNING;
    else if (NdmReset)
      State <= HaltOnReset ? HALTED : RUNNING;
    else begin
      case (State)
        RUNNING : State <= HaltReq ? HALTED : RUNNING;

        HALTED : begin
          case ({ResumeReq, Step})
            2'b10 : State <= RUNNING;
            2'b11 : State <= STEP;
            default : State <= HALTED;
          endcase
        end

        STEP : begin
          State <= HALTED;
        end
      endcase
    end
  end

endmodule

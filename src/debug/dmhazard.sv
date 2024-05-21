///////////////////////////////////////////
// dmhazard.sv
//
// Written: matthew.n.otto@okstate.edu 10 May 2024
// Modified: 
//
// Purpose: Determine stalls during DM initiated Halt, Step and Resume
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

// TODO: Depending on how complicated the stall logic ends up, this module may be removed completely

module dmhazard(
  input  logic clk, rst,

  input  logic HaltReq,       // Initiate core halt
  input  logic ResumeReq,     // Initiates core resume
  input  logic HaltOnReset,   // Halts core immediately on reset
  output logic Halted,        // Signals completion of halt
  output logic ResumeConfirm,

  output logic DebugStall
);

  (* mark_debug = "true" *)enum bit [3:0] {
    RUNNING,
    HALTED,
    STEP
  } State;

  assign DebugStall = (State == HALTED);
  assign Halted = DebugStall;

  always_ff @(posedge clk) begin
    if (rst) begin
      State <= HaltOnReset ? HALTED : RUNNING;
    end else begin
      case (State)
        RUNNING : begin
          ResumeConfirm <= 0;
          State <= HaltReq ? HALTED : RUNNING;
        end

        HALTED : begin
          case ({HaltReq, ResumeReq})
            2'b10 : State <= HALTED;
            2'b01 : begin
              State <= RUNNING;
              ResumeConfirm <= 1;
            end
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

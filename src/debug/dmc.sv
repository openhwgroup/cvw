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

module dmc (
  input  logic       clk, reset,
  input  logic       Step,
  input  logic       HaltReq,      // Initiates core halt
  input  logic       ResumeReq,    // Initiates core resume
  input  logic       HaltOnReset,  // Halts core immediately on hart reset
  input  logic       AckHaveReset, // Clears HaveReset status

  output logic       DebugMode,
  output logic [2:0] DebugCause,     // Reason Hart entered debug mode
  output logic       ResumeAck,      // Signals Hart has been resumed
  output logic       HaveReset,      // Signals Hart has been reset
  output logic       DebugStall,     // Stall signal goes to hazard unit

  output logic       EnterDebugMode, // Store PCNextF in DPC when entering Debug Mode
  output logic       ExitDebugMode,  // Updates PCNextF with the current value of DPC
  output logic       ForceNOP        // Fills the pipeline with NOP
);
  `include "debug.vh"

enum logic [1:0] {RUNNING, FLUSH, HALTED, RESUME} State;

  localparam NOP_CYCLE_DURATION = 0;
  logic [$clog2(NOP_CYCLE_DURATION+1)-1:0] Counter;

  always_ff @(posedge clk) begin
    if (reset)
      HaveReset <= 1;
    else if (AckHaveReset)
      HaveReset <= 0;
  end

  assign DebugMode = (State != RUNNING);
  assign DebugStall = (State == HALTED);

  assign EnterDebugMode = (State == FLUSH) & (Counter == 0);
  assign ExitDebugMode = (State == HALTED) & ResumeReq;
  assign ForceNOP = (State == FLUSH);

  always_ff @(posedge clk) begin
    if (reset) begin
      State <= HaltOnReset ? HALTED : RUNNING;
      DebugCause <= HaltOnReset ? `CAUSE_RESETHALTREQ : 0;
    end else begin
      case (State)
        RUNNING : begin
          if (HaltReq) begin
            Counter <= 0;
            State <= FLUSH;
            DebugCause <= `CAUSE_HALTREQ;
          end 
          //else if (eBreak) TODO: halt on ebreak if DCSR bit is set
          // DebugCause <= `CAUSE_EBREAK;
        end

        // fill the pipe with NOP before halting
        FLUSH : begin
          if (Counter == NOP_CYCLE_DURATION)
            State <= HALTED;
          else
            Counter <= Counter + 1;
        end

        HALTED : begin
          if (ResumeReq)
            State <= RESUME;
        end

        RESUME : begin
          if (Step) begin
            Counter <= 0;
            State <= FLUSH;
            DebugCause <= `CAUSE_STEP;
          end else begin
            State <= RUNNING;
            ResumeAck <= 1;
          end
        end
      endcase
    end
  end
endmodule

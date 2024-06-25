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


// TODO:
// Calculate correct cycle timing for step
// Test progbuf

module dmc (
  input  logic       clk, reset,
  input  logic       Step,
  input  logic       ebreakM,      // ebreak instruction
  input  logic       ebreakEn,     // DCSR: enter debug mode on ebreak
  input  logic       HaltReq,      // Initiates core halt
  input  logic       ResumeReq,    // Initiates core resume
  input  logic       HaltOnReset,  // Halts core immediately on hart reset
  input  logic       AckHaveReset, // Clears HaveReset status
  input  logic       ExecProgBuf,  // Updates PC to progbuf and resumes core

  output logic       DebugMode,      // Sets state in DM and controls masking of interrupts
  output logic [2:0] DebugCause,     // Reason Hart entered debug mode
  output logic       ResumeAck,      // Signals Hart has been resumed
  output logic       HaveReset,      // Signals Hart has been reset
  output logic       DebugStall,     // Stall signal goes to hazard unit

  output logic       DCall,          // Store PCNextF in DPC when entering Debug Mode
  output logic       DRet,           // Updates PCNextF with the current value of DPC
  output logic       ForceBreakPoint // Causes artificial ebreak that puts core in debug mode
);
  `include "debug.vh"

  enum logic [1:0] {RUNNING, EXECPROGBUF, HALTED, STEP} State;

  localparam E2M_CYCLE_COUNT = 4;
  logic [$clog2(E2M_CYCLE_COUNT+1)-1:0] Counter;

  always_ff @(posedge clk) begin
    if (reset)
      HaveReset <= 1;
    else if (AckHaveReset)
      HaveReset <= 0;
  end

  assign ForceBreakPoint = (State == RUNNING) & HaltReq | (State == STEP) & ~|Counter;

  assign DebugMode = (State != RUNNING);
  assign DebugStall = (State == HALTED);

  assign DCall = ((State == RUNNING) | (State == EXECPROGBUF)) & ((ebreakM & ebreakEn) | ForceBreakPoint);
  assign DRet = (State == HALTED) & (ResumeReq | ExecProgBuf);

  always_ff @(posedge clk) begin
    if (reset) begin
      State <= HaltOnReset ? HALTED : RUNNING;
      DebugCause <= HaltOnReset ? `CAUSE_RESETHALTREQ : 0;
    end else begin
      case (State)
        RUNNING : begin
          if (HaltReq) begin
            State <= HALTED;
            DebugCause <= `CAUSE_HALTREQ;
          end else if (ebreakM & ebreakEn) begin
            State <= HALTED;
            DebugCause <= `CAUSE_EBREAK;
          end
        end

        // Similar to RUNNING, but DebugMode isn't deasserted
        EXECPROGBUF : begin
          if (ebreakM & ebreakEn) begin
            State <= HALTED;
            DebugCause <= `CAUSE_EBREAK;
          end
        end

        HALTED : begin
          if (ResumeReq) begin
            if (Step) begin
              Counter <= E2M_CYCLE_COUNT;
              State <= STEP;
            end else begin
              State <= RUNNING;
              ResumeAck <= 1;
            end
          end else if (ExecProgBuf) begin
            State <= EXECPROGBUF;
            ResumeAck <= 1;
          end
        end


        STEP : begin
          if (~|Counter) begin
            DebugCause <= `CAUSE_STEP;
            State <= HALTED;
          end else
            Counter <= Counter - 1;
        end
      endcase
    end
  end
endmodule

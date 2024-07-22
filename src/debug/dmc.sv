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


module dmc (
  input  logic       clk, reset,
  input  logic       StallF, StallD, StallE, StallM, StallW,
  input  logic       FlushD, FlushE, FlushM, FlushW,
  input  logic       Step,
  input  logic       ebreakM,      // ebreak instruction
  input  logic       ebreakEn,     // DCSR: enter debug mode on ebreak
  input  logic       HaltReq,      // Initiates core halt
  input  logic       ResumeReq,    // Initiates core resume
  input  logic       HaltOnReset,  // Halts core immediately on hart reset
  input  logic       AckHaveReset, // Clears HaveReset status
  input  logic       ExecProgBuf,  // Updates PC to progbuf and resumes core

  input  logic       ProgBufTrap,    // Trap while executing progbuf
  output logic       DebugMode,      // Sets state in DM and controls masking of interrupts
  output logic [2:0] DebugCause,     // Reason Hart entered debug mode
  output logic       ResumeAck,      // Signals Hart has been resumed
  output logic       HaveReset,      // Signals Hart has been reset
  output logic       DebugStall,     // Stall signal goes to hazard unit

  output logic       DCall,          // Store PCNextF in DPC when entering Debug Mode
  output logic       DRet,           // Updates PCNextF with the current value of DPC, Flushes pipe
  output logic       ForceBreakPoint // Causes artificial ebreak that puts core in debug mode
);
  `include "debug.vh"

  logic StepF, StepD, StepE, StepM, StepW;

  enum logic [1:0] {RUNNING, EXECPROGBUF, HALTED, STEP} State;

  always_ff @(posedge clk) begin
    if (reset)
      HaveReset <= 1;
    else if (AckHaveReset)
      HaveReset <= 0;
  end

  assign ForceBreakPoint = (State == RUNNING) & HaltReq;

  assign DebugMode = (State != RUNNING);
  assign DebugStall = (State == HALTED);

  assign DCall = ((State == RUNNING) | (State == EXECPROGBUF)) & ((ebreakM & ebreakEn) | ForceBreakPoint) | StepW;
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

        EXECPROGBUF : begin
          if (ProgBufTrap) begin
            State <= HALTED;
          end
        end

        HALTED : begin
          if (ResumeReq) begin
            if (Step) begin
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
          if (StepW)
            State <= HALTED;
        end
        default: ; // empty defualt case to make the linter happy
      endcase
    end
  end

  flopenr #(1)  StepFReg (.clk, .reset, .en(~StallF), .d((State == HALTED) & ResumeReq & Step), .q(StepF));
  flopenrc #(1) StepDReg (.clk, .reset, .clear(FlushD), .en(~StallD), .d(StepF), .q(StepD));
  flopenrc #(1) StepEReg (.clk, .reset, .clear(FlushE), .en(~StallE), .d(StepD), .q(StepE));
  flopenrc #(1) StepMReg (.clk, .reset, .clear(FlushM), .en(~StallM), .d(StepE), .q(StepM));
  flopenrc #(1) StepWReg (.clk, .reset, .clear(FlushW), .en(~StallM), .d(StepM), .q(StepW));

endmodule

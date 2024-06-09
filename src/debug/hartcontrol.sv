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
  input  logic AckHaveReset, // Clears *HaveReset status

  input  logic HaltReq,     // Initiate core halt
  input  logic ResumeReq,   // Initiates core resume
  input  logic HaltOnReset, // Halts core immediately on hart reset

  output logic DebugStall,  // Stall signal goes to hazard unit

  // DMStatus bits
  output logic Halted,
  output logic AllRunning,
  output logic AnyRunning,
  output logic AllHalted,
  output logic AnyHalted,
  output logic AllResumeAck,
  output logic AnyResumeAck,
  output logic AllHaveReset,
  output logic AnyHaveReset
);
  enum logic {RUNNING, HALTED} State;
  
  assign AnyHaveReset = AllHaveReset;

  always_ff @(posedge clk) begin
    if (NdmReset)
      AllHaveReset <= 1;
    else if (AckHaveReset)
      AllHaveReset <= 0;
  end
  

  assign Halted = DebugStall;
  assign AllRunning = ~DebugStall;
  assign AnyRunning = ~DebugStall;
  assign AllHalted = DebugStall;
  assign AnyHalted = DebugStall;
  // BOZO: when sdext is implemented (proper step support is added)
  //       change ResumeReq to be ignored when HaltReq
  //       but ResumeReq should still always clear *ResumeAck
  assign AnyResumeAck = AllResumeAck;

  assign DebugStall = (State == HALTED);

  always_ff @(posedge clk) begin
    if (rst)
      State <= RUNNING;
    else if (NdmReset)
      State <= HaltOnReset ? HALTED : RUNNING;
    else begin
      case (State)
        RUNNING : begin
          if (HaltReq) begin
            State <= HALTED;
          end else if (ResumeReq) begin
            AllResumeAck <= 0;
          end
        end

        HALTED : begin
          if (ResumeReq) begin
            State <= RUNNING;
            AllResumeAck <= 1;
          end
        end
      endcase
    end
  end
endmodule

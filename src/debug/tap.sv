///////////////////////////////////////////
// tap.sv
//
// Written: matthew.n.otto@okstate.edu, james.stine@okstate.edu
// Created: 15 March 2024
//
// Purpose: JTAG tap controller
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

module tap (
  input  logic tck,
  input  logic tms,
  output logic resetn,
  output logic tdo_en,
  output logic captureIR,
  output logic clockIR,
  output logic updateIR,
  output logic shiftDR,
  output logic captureDR,
  output logic clockDR,
  output logic updateDR,
  output logic select
);

  enum logic [3:0] {
    Exit2DR     = 4'h0,
    Exit1DR     = 4'h1,
    ShiftDR     = 4'h2,
    PauseDR     = 4'h3,
    SelectIR    = 4'h4,
    UpdateDR    = 4'h5,
    CaptureDR   = 4'h6,
    SelectDR    = 4'h7,
    Exit2IR     = 4'h8,
    Exit1IR     = 4'h9,
    ShiftIR     = 4'hA,
    PauseIR     = 4'hB,
    RunTestIdle = 4'hC,
    UpdateIR    = 4'hD,
    CaptureIR   = 4'hE,
    TLReset     = 4'hF
  } State;

  always @(posedge tck) begin
    case (State)
      TLReset     : State <= tms ? TLReset : RunTestIdle;
      RunTestIdle : State <= tms ? SelectDR : RunTestIdle;
      SelectDR    : State <= tms ? SelectIR : CaptureDR;
      CaptureDR   : State <= tms ? Exit1DR : ShiftDR;
      ShiftDR     : State <= tms ? Exit1DR : ShiftDR;
      Exit1DR     : State <= tms ? UpdateDR : PauseDR;
      PauseDR     : State <= tms ? Exit2DR : PauseDR;
      Exit2DR     : State <= tms ? UpdateDR : ShiftDR;
      UpdateDR    : State <= tms ? SelectDR : RunTestIdle;
      SelectIR    : State <= tms ? TLReset : CaptureIR;
      CaptureIR   : State <= tms ? Exit1IR : ShiftIR;
      ShiftIR     : State <= tms ? Exit1IR : ShiftIR;
      Exit1IR     : State <= tms ? UpdateIR : PauseIR;
      PauseIR     : State <= tms ? Exit2IR : PauseIR;
      Exit2IR     : State <= tms ? UpdateIR : ShiftIR;
      UpdateIR    : State <= tms ? SelectDR : RunTestIdle;
    endcase
  end

  always @(negedge tck) begin
    resetn <= ~(State == TLReset);
    tdo_en <= State == ShiftIR || State == ShiftDR;
    captureIR <= State == CaptureIR;
    updateIR <= State == UpdateIR;
    shiftDR <= State == ShiftDR;
    captureDR <= State == CaptureDR;
    updateDR <= State == UpdateDR;
  end

  assign clockIR = tck | State[0] | ~State[1] | ~State[3];
  assign clockDR = tck | State[0] | ~State[1] | State[3];
  assign select = State[3];

endmodule

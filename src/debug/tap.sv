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
  input  logic trstn, 
  input  logic tms,
  output logic resetn,
  output logic tdo_en,
  output logic shiftIR,
  output logic captureIR,
  output logic clockIR,
  output logic updateIR,
  output logic shiftDR,
  output logic captureDR,
  output logic clockDR,
  output logic updateDR,
  output logic select
);

  logic [3:0]  State;

  always @(posedge tck, negedge trstn) begin
    if (~trstn) begin
      State <= 4'b1111;
    end else begin
      State[0] <= ~tms && ~State[2] && State[0] || tms && ~State[1] || tms && ~State[0] || tms && State[3] && State[2];
      State[1] <= ~tms && State[1] && ~State[0] || ~tms && ~State[2] || ~tms && ~State[3] && State[1] || ~tms && ~State[3] && ~State[0] || tms && State[2] && ~State[1] || tms && State[3] && State[2] && State[0];
      State[2] <= State[2] && ~State[1] || State[2] && State[0] || tms && ~State[1];
      State[3] <= State[3] && ~State[2] || State[3] && State[1] || ~tms && State[2] && ~State[1] || ~State[3] && State[2] && ~State[1] && ~State[0];
    end
  end

  always @(negedge tck, negedge trstn) begin
    if (~trstn) begin
      resetn <= 1'b0;
      tdo_en <= 1'b0;
      shiftIR <= 1'b0;
      captureIR <= 1'b0;
      shiftDR <= 1'b0;
      captureDR <= 1'b0;
    end else begin
      resetn <= ~&State;
      tdo_en <= ~State[0] && State[1] && ~State[2] && State[3] || ~State[0] && State[1] && ~State[2] && ~State[3]; // shiftIR || shiftDR;
      shiftIR <= ~State[0] && State[1] && ~State[2] && State[3];
      captureIR <= ~State[0] && State[1] && State[2] && State[3];
      updateIR <= State[0] && ~State[1] && State[2] && State[3];
      shiftDR <= ~State[0] && State[1] && ~State[2] && ~State[3];
      captureDR <= ~State[0] && State[1] && State[2] && ~State[3];
      updateDR <= State[0] && ~State[1] && State[2] && ~State[3];
    end
  end

  assign clockIR = tck || State[0] || ~State[1] || ~State[3];
  assign clockDR = tck || State[0] || ~State[1] || State[3];
  assign select = State[3];

endmodule

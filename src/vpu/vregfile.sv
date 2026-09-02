///////////////////////////////////////////
// vregfile.sv
//
// Written: Rose Thompson Rose.Thompson@skyworksinc.com
// based on regfile.sv by David_Harris@hmc.edu, Sarah.Harris@unlv.edu
// Created: 2 September
// Modified:
//
// Purpose: 4-port register file
//
// Documentation: RISC-V System on Chip Design Vol 2
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-26 Harvey Mudd College & Oklahoma State University & Skyworks Solutions Inc.
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

module vregfile #(parameter VLEN) (
  input  logic             clk, reset,
  input  logic             we4,                      // Write enable
  input  logic [4:0]       a1, a2, a3, a4,           // Source registers to read (a1, a2, a3), destination register to write (a4)
  input  logic [VLEN-1:0]  wd4,                      // Write data for port 4
  output logic [VLEN-1:0]  rd1, rd2, rd3, v0);       // Read data for ports 1, 2, 3, v0 always available for masks

  logic [VLEN-1:0] rf[31:0];
  integer i;

  // four ported register file
  // Read three ports combinationally (a1/rd1, a2/rd2, a3/rd3)
  // Write four port on falling edge of clock (a3/wd3/we3)
  // Write occurs on falling edge of clock

  // reset is intended for simulation only, not synthesis
  // can logic be adjusted to not need resettable registers?

  always_ff @(negedge clk)
    if (reset) for(i=0; i<32; i++) rf[i] <= '0;
    else       if (we4)            rf[a4] <= wd4;

  assign rd1 = rf[a1];
  assign rd2 = rf[a2];
  assign rd3 = rf[a3];
  assign v0  = rf[0];

endmodule

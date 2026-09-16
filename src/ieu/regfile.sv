///////////////////////////////////////////
// regfile.sv
//
// Written: David_Harris@hmc.edu, Sarah.Harris@unlv.edu
// Created: 9 January 2021
// Modified:
//
// Purpose: 3-port register file
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

module regfile #(parameter XLEN, E_SUPPORTED, ZACAS_SUPPORTED) (
  input  logic             clk, reset,
  input  logic             we3, we3p,           // Write enable for normal and pair
  input  logic [4:0]       a1, a2, a3, a4,      // Read a1, a2, and a4 (Zacas compare operand); write a3
  input  logic [XLEN-1:0]  wd3,                 // Write data for port 3
  input  logic [XLEN-1:0]  wd3h,                // Upper half write data for port 3 pair
  output logic [XLEN-1:0]  rd1, rd2,            // Read data for ports 1, 2
  output logic [XLEN*2-1:0] rd2p, rd4p          // Pair read data for the rs2 and compare-operand ports
);
  localparam NUMREGS = E_SUPPORTED ? 16 : 32;   // only 16 registers in E mode

  if (ZACAS_SUPPORTED) begin : pairedrf
    // Zacas reads three registers at once (rs1, rs2, and rd as the compare operand) and reads
    // register pairs, so hold the registers as pairs and add a third read port.
    logic [XLEN*2-1:0] rf[NUMREGS/2-1:0]; // organize as pairs, with half as many entries
    logic [XLEN*2-1:0] rd1p;              // pair holding rs1
    logic [3:0]        a1p, a2p, a3p, a4p; // pair addresses
    integer i;

    // Read three ports combinationally (a1/rd1, a2/rd2, a4/rd4p), write one port (a3) on the
    // falling edge of the clock.  Register 0 is hardwired to 0.
    // reset is intended for simulation only, not synthesis

    // A pair address drops the low bit of the register number; the low bit picks the half
    assign a1p = a1[4:1];
    assign a2p = a2[4:1];
    assign a3p = a3[4:1];
    assign a4p = a4[4:1];

    assign rd1p = rf[a1p];
    assign rd2p = (a2 == 0) ? '0 : rf[a2p]; // a source pair starting at x0 reads as all zeros
    assign rd4p = (a4 == 0) ? '0 : rf[a4p]; // a compare pair starting at x0 reads as all zeros

    // Write the whole pair for a pair write, otherwise only the addressed half
    always_ff @(negedge clk)
      if (reset)                   for (i=0; i<NUMREGS/2; i++) rf[i] <= '0;
      else if (we3p & (a3 != 0))   rf[a3p] <= {wd3h, wd3};
      else if (we3  & (a3 != 0))
        if (a3[0])                 rf[a3p][XLEN*2-1:XLEN] <= wd3;
        else                       rf[a3p][XLEN-1:0]      <= wd3;

    // Select the half the register number names, forcing x0 to read as zero
    assign rd1 = (a1 == 0) ? '0 : (a1[0] ? rd1p[XLEN*2-1:XLEN] : rd1p[XLEN-1:0]);
    assign rd2 = (a2 == 0) ? '0 : (a2[0] ? rf[a2p][XLEN*2-1:XLEN] : rf[a2p][XLEN-1:0]);
  end else begin : simplerf
    logic [XLEN-1:0] rf[NUMREGS-1:1];
    integer i;

    // Three ported register file
    // Read two ports combinationally (a1/rd1, a2/rd2)
    // Write third port on rising edge of clock (a3/wd3/we3)
    // Write occurs on falling edge of clock
    // Register 0 hardwired to 0

    // reset is intended for simulation only, not synthesis
    // can logic be adjusted to not need resettable registers?

    always_ff @(negedge clk)
      if (reset) for(i=1; i<NUMREGS; i++) rf[i] <= '0;
      else       if (we3)                 rf[a3] <= wd3;

    assign rd1 = (a1 != 0) ? rf[a1] : 0;
    assign rd2 = (a2 != 0) ? rf[a2] : 0;
    assign rd2p = '0; assign rd4p = '0; // not used without Zacas
  end
endmodule

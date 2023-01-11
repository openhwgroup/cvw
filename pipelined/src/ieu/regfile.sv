///////////////////////////////////////////
// regfile.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: 3-port register file
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
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

`include "wally-config.vh"

module regfile (
  input  logic             clk, reset,
  input  logic             we3, 
  input  logic [ 4:0]      a1, a2, a3, 
  input  logic [`XLEN-1:0] wd3, 
  output logic [`XLEN-1:0] rd1, rd2);

  localparam NUMREGS = `E_SUPPORTED ? 16 : 32;  // only 16 registers in E mode

(* mark_debug = "true" *)  logic [`XLEN-1:0] rf[NUMREGS-1:1];
  integer i;

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // write occurs on falling edge of clock
  // register 0 hardwired to 0
  
  // reset is intended for simulation only, not synthesis
  // can logic be adjusted to not need resettable registers?
    
  always_ff @(negedge clk) // or posedge reset) // *** make this a preload in testbench rather than reset
    if (reset) for(i=1; i<NUMREGS; i++) rf[i] <= 0;
    else       if (we3)            rf[a3] <= wd3;	

  assign #2 rd1 = (a1 != 0) ? rf[a1] : 0;
  assign #2 rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule

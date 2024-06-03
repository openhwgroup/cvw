///////////////////////////////////////////
// scanreg.sv
//
// Written: matthew.n.otto@okstate.edu 15 April 2024
// Modified: 
//
// Purpose: Scannable register that captures input on first scan cycle
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License Version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module scanreg #(parameter WIDTH = 8) (
  input  logic clk, reset,
  input  logic [WIDTH-1:0] d,
  input  logic scan, // scan enable
  input  logic scanin,
  output logic scanout
);
  logic buffer;
  logic [WIDTH:0] scanreg;
  logic firstcycle;

  assign scanreg[WIDTH] = buffer;
  assign scanout = scanreg[0];

  always_ff @(posedge clk)
    if (reset)
      buffer <= 0;
    else
      buffer <= scanin;

  genvar i;
  for (i=0; i<WIDTH; i=i+1) begin
    always_ff @(posedge clk)
      if (reset)
        scanreg[i] <= 0;
      else if (scan)
        scanreg[i] <= firstcycle ? d[i] : scanreg[i+1];
  end

  always_ff @(posedge clk)
    if (reset)
      firstcycle <= 1;
    else if (scan && firstcycle)
      firstcycle <= 0;
    else if (~scan && ~firstcycle)
      firstcycle <= 1;

endmodule
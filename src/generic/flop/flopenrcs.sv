///////////////////////////////////////////
// flopenrcs.sv
//
// Written: matthew.n.otto@okstate.edu 15 April 2024
// Modified: 
//
// Purpose: Scannable D flip-flop with enable, synchronous reset, enabled clear
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

module flopenrs #(parameter WIDTH = 8) (
  input  logic clk, reset, clear, en,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q,
  input  logic scan, // scan enable
  input  logic scanin,
  output logic scanout
);
  logic [WIDTH-1:0] dmux;

  assign dmux[WIDTH-1] = scan ? scanin : d[WIDTH-1];
  assign scanout = q[0];

  genvar i;
  for (i=0; i<WIDTH-1; i=i+1) begin
    assign dmux[i] = scan ? q[i+1] : d[i];
  end

  always_ff @(posedge clk)
    if (reset)
      q <= '0;
    else if (en || scan)
      if (clear)
        q <= '0;
      else
        q <= dmux;

endmodule
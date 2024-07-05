///////////////////////////////////////////
// clk_divider.sv
//
// Written: matthew.n.otto@okstate.edu
// Created: 28 June 2024
//
// Purpose: Divides the simulation clock to virtual JTAG adapter
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

module clk_divider #(parameter DIV) (
  input  logic clk_in, reset,
  output logic clk_out
);
  integer count;

  always_ff @(posedge clk_in) begin
    if (reset) begin
      count <= 0;
      clk_out <= 0;
    end else if (count == DIV) begin
      clk_out <= ~clk_out;
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end

endmodule
///////////////////////////////////////////
// clmul.sv
//
// Written: Kevin Kim <kekim@hmc.edu> and Kip Macsai-Goren <kmacsaigoren@hmc.edu>
// Created: 1 February 2023
// Modified: 
//
// Purpose: RISC-V single bit manipulation unit (ZBS instructions)
//
// Documentation: RISC-V System on Chip Design Chapter ***
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

module clmul #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,       // Operands
  output logic [WIDTH-1:0] Result);     // ZBS result
  //output logic [WIDTH-1:0] Sum);       // Sum of operands

  logic [WIDTH-1] pp [WIDTH-1]; //partial AND products
  logic [WIDTH-1] sop; //sum of partial products
  genvar i;
  for (i=0; i<WIDTH;i+=WIDTH) begin:forloop //loop fills partial product array
    for
    //fill partials products here
  end

  genvar i;
  for (i=1;x<WIDTH;i++) begin:outer 
    assign result[x] = ^pp[i][i:0]
  end


endmodule



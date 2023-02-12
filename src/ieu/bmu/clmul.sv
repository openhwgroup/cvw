///////////////////////////////////////////
// clmul.sv
//
// Written: Kevin Kim <kekim@hmc.edu> and Kip Macsai-Goren <kmacsaigoren@hmc.edu>
// Created: 1 February 2023
// Modified: 
//
// Purpose: Carry-Less multiplication top-level unit
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
  output logic [WIDTH-1:0] ClmulResult);     // ZBS result

  logic [WIDTH-1:0] pp [WIDTH-1:0]; //partial AND products
  // Note: only generates the bottom WIDTH bits of the carryless multiply.
  //    To get the high bits or the reversed bits, the inputs can be shifted and reversed
  //    as they are in zbc where this is instantiated
  /*
  genvar i;
  for (i=0; i<WIDTH; i++) begin
    assign pp[i] = ((A & {(WIDTH){B[i]}}) << i); // Fill partial product array
    // ClmulResult ^= pp[i];
  end
  assign ClmulResult = pp.xor();
  */
  genvar i,j;
  for (i=1; i<WIDTH;i++) begin:outer //loop fills partial product array
    for (j=0;j<=i;j++) begin: inner
      assign pp[i][j] = A[i]&B[j];
    end
  end

  for (i=1;i<WIDTH;i++) begin:xortree
    assign ClmulResult[i] = ^pp[i:0][i];
  end

  assign ClmulResult[0] = A[0]&B[0];

endmodule



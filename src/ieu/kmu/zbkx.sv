///////////////////////////////////////////
// zbkx.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 1 February 2024
//
// Purpose: RISC-V ZBKX top level unit
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

module zbkx #(parameter WIDTH=32) 
   (input  logic [WIDTH-1:0] A, B,
    input logic [2:0] 	     ZBKXSelect,
    output logic [WIDTH-1:0] ZBKXResult);
   
   logic [WIDTH-1:0] 	     xperm_lookup;
   logic [WIDTH-1:0] 	     XPERM8_Result;
   logic [WIDTH-1:0] 	     XPERM4_Result;
   integer i;
   
   always_comb begin
      if (ZBKXSelect[0] == 1'b0) begin
         for(i=0; i<WIDTH; i=i+8) begin: xperm8
            xperm_lookup = A >> {B[i+:8], 3'b0};
            ZBKXResult[i+:8] = xperm_lookup[7:0];
         end
      end
      else begin
         for(i=0; i<WIDTH; i=i+4) begin: xperm4
            xperm_lookup = A >> {B[i+:4], 2'b0};
            ZBKXResult[i+:4] = xperm_lookup[3:0];
         end
      end
   end
   
endmodule

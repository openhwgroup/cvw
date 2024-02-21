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
   
   logic [WIDTH-1:0] 	     xperm_lookup[0:WIDTH];
   logic [WIDTH-1:0] 	     XPERM8_Result;
   logic [WIDTH-1:0] 	     XPERM4_Result;
   genvar 		     i;
   
   for(i=0; i<WIDTH; i=i+8) begin: xperm8
      assign xperm_lookup[i] = A >> {B[i+7:i], 3'b0};
      assign XPERM8_Result[i+7:i] = xperm_lookup[i][7:0];
   end
   
   for(i=0; i<WIDTH; i=i+4) begin: xperm4
      assign xperm_lookup[i+1] = A >> {B[i+3:i], 2'b0};
      assign XPERM4_Result[i+3:i] = xperm_lookup[i+1][3:0];
   end
   
   mux2 #(WIDTH) ZbkxMux (XPERM8_Result, XPERM4_Result, ZBKXSelect[0], ZBKXResult);
   
endmodule

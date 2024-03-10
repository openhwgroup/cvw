///////////////////////////////////////////
// sha256sig0.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: sha256sig0 instruction
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

module sha256sig0 #(parameter WIDTH=32) 
   (input  logic [WIDTH-1:0] rs1,
    output logic [WIDTH-1:0] result);

   logic [31:0] 	   ror7;
   logic [31:0] 	   ror18;
   logic [31:0] 	   sh3;
   logic [31:0] 	   exts;
   
   assign ror7  = {rs1[6:0], rs1[31:7]};
   assign ror18 = {rs1[17:0], rs1[31:18]};
   assign sh3   = {3'b0, rs1[31:3]};
   
   // Assign output to xor of 3 rotates
   assign exts = ror7 ^ ror18 ^ sh3;   
   if (WIDTH==32) 
     assign result = exts;
   else 
     assign result = {{32{exts[31]}}, exts};
   
endmodule

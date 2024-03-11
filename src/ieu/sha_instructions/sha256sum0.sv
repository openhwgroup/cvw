///////////////////////////////////////////
// sha256sum0.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: sha256sum0 instruction
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

module sha256sum0 #(parameter WIDTH=32) (
   input  logic [WIDTH-1:0] rs1,
   output logic [WIDTH-1:0] result
);
   
   logic [31:0] 	     ror2;
   logic [31:0] 	     ror13;
   logic [31:0] 	     ror22;
   logic [31:0] 	     exts;
   
   assign ror2 = {rs1[1:0], rs1[31:2]};
   assign ror13 = {rs1[12:0], rs1[31:13]};
   assign ror22 = {rs1[21:0], rs1[31:22]};
   
   // Assign output to xor of 3 rotates
   assign exts = ror2 ^ ror13 ^ ror22;

   // Sign-extend for RV64
   if (WIDTH==32) assign result = exts;
   else           assign result = {{32{exts[31]}}, exts};
endmodule

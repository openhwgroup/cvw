///////////////////////////////////////////
// sha512sig0h.sv
//
// Written: ryan.swann@okstate.edu, kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: sha512sig0h instruction
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

module sha512sig0h(
   input  logic [31:0] rs1, 
   input  logic [31:0] rs2,
   output logic [31:0] DataOut
);
   
   // RS1 Shifts
   logic [31:0] 		       shift1;
   logic [31:0] 		       shift7;
   logic [31:0] 		       shift8;
   
   // RS2 Shifts
   logic [31:0] 		       shift31;
   logic [31:0] 		       shift24;
   
   // Shift rs1
   assign shift1 = rs1 >> 1;
   assign shift7 = rs1 >> 7;
   assign shift8 = rs1 >> 8;
   
   // Shift rs2
   assign shift31 = rs2 << 31;
   assign shift24 = rs2 << 24;
   
   // XOR to get result
   assign DataOut = shift1 ^ shift7 ^ shift8 ^ shift31 ^ shift24;
endmodule

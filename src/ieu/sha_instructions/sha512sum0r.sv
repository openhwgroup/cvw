///////////////////////////////////////////
// sha512sum0r.sv
//
// Written: ryan.swann@okstate.edu, kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 6 February 2024
//
// Purpose: sha512sum0r instruction
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

module sha512sum0r(
   input  logic [31:0] rs1, 
   input  logic [31:0]  rs2,
   output logic [31:0] DataOut
);
   
   // RS1 shifts
   logic [31:0] 		       shift25;
   logic [31:0] 		       shift30;
   logic [31:0] 		       shift28;
   
   // RS2 shifts
   logic [31:0] 		       shift7;
   logic [31:0] 		       shift2;
   logic [31:0] 		       shift4;
   
   // Shift rs1
   assign shift25 = rs1 << 25;
   assign shift30 = rs1 << 30;
   assign shift28 = rs1 >> 28;
   
   // Shift rs2
   assign shift7 = rs2 >> 7;
   assign shift2 = rs2 >> 2;
   assign shift4 = rs2 << 4;
   
   // Set output to XOR of shifted values
   assign DataOut = shift25 ^ shift30 ^ shift28 ^ shift7 ^ shift2 ^ shift4;
endmodule

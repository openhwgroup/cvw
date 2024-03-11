///////////////////////////////////////////
// sha512sig0l.sv
//
// Written: ryan.swann@okstate.edu, kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: sha512sig0l instruction: : RV32 SHA2-512 Sigma0 low instruction
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

module sha512sig0l(
   input  logic [31:0] rs1, 
   input  logic [31:0] rs2,
   output logic [31:0] DataOut
);
   
  logic [31:0] 		       shift1,  shift7,  shift8;  // rs1 shifts
   logic [31:0] 		       shift31, shift25, shift24; // rs2 shifts
   
   // rs1 shifts
   assign shift1 = rs1 >> 1;
   assign shift7 = rs1 >> 7;
   assign shift8 = rs1 >> 8;
   
   // rs2 shifts
   assign shift31 = rs2 << 31;
   assign shift25 = rs2 << 25;
   assign shift24 = rs2 << 24;
   
   assign DataOut = shift1 ^ shift7 ^ shift8 ^ shift31 ^ shift25 ^ shift24;
endmodule

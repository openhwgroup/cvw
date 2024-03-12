///////////////////////////////////////////
// sha512sum1r.sv
//
// Written: ryan.swann@okstate.edu, kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 6 February 2024
//
// Purpose: sha512sum1r instruction: RV32 SHA2-512 Sum01instruction
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

module sha512sum1r(
   input  logic [31:0] rs1, 
   input  logic [31:0] rs2,
   output logic [31:0] DataOut
);   
   
   logic [31:0] 		       shift1by23, shift1by14, shift1by18; // rs1 shifts
   logic [31:0] 		       shift2by9,  shift2by18, shift2by14; // rs2 shifts
   
   // Shift RS1
   assign shift1by23 = rs1 << 23;
   assign shift1by14 = rs1 >> 14;
   assign shift1by18 = rs1 >> 18;
   
   // Shift RS2
   assign shift2by9  = rs2 >> 9;
   assign shift2by18 = rs2 << 18;
   assign shift2by14 = rs2 << 14;
   
   // Assign output to xor of shifts
   assign DataOut = shift1by23 ^ shift1by14 ^ shift1by18 ^ shift2by9 ^ shift2by18 ^ shift2by14;
endmodule

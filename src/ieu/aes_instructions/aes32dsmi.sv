///////////////////////////////////////////
// aes32dsmi.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes32dsmi instruction: RV32 middle round AES decryption
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

module aes32dsmi(
   input  logic [1:0]  bs,
   input  logic [31:0] rs1,
   input  logic [31:0] rs2,
   output logic [31:0] DataOut
);

   logic [4:0] 			  shamt;
   logic [31:0] 		     SboxIn32;
   logic [7:0] 			  SboxIn;
   logic [7:0] 			  SboxOut;
   logic [31:0] 		     so;
   logic [31:0] 		     mixed;
   logic [31:0] 		     mixedrotate;   
   
   // shamt = bs * 8
   assign shamt = {bs, 3'b0};
   
   // Shift rs2 right by shamt and take the lower byte
   assign SboxIn32 = (rs2 >> shamt);
   assign SboxIn = SboxIn32[7:0];
   
   // Apply inverse sbox to si
   aesinvsbox inv_sbox(SboxIn, SboxOut);
   
   // Pad output of inverse substitution box
   assign so = {24'h0, SboxOut};
   
   // Run so through the mixword AES function
   aesinvmixcolumns mix(so, mixed);
   
   // Rotate the substitution box output left by shamt (bs * 8)
   assign mixedrotate = (mixed << shamt) | (mixed >> (32 - shamt)); 
   
   // Set result to "X(rs1)[31..0] ^ rol32(so, unsigned(shamt));"
   assign DataOut = rs1 ^ mixedrotate;
endmodule

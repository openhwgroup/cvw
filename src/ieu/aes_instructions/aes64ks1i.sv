///////////////////////////////////////////
// aes64ks1i.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes64ks1i instruction
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

module aes64ks1i(input logic [3:0] roundnum,
                 input logic [63:0]  rs1,
                 output logic [63:0] rd);                 
                 
   // Instantiate intermediary logic signals             
   logic [7:0] 			     rcon_preshift;
   logic [31:0] 		     rcon;
   logic 			     lastRoundFlag;
   logic [31:0] 		     rs1_rotate;
   logic [31:0] 		     tmp2;
   logic [31:0] 		     Sbox_Out;
   
   // Get rcon value from table
   rcon_lut_128 rc(.RD(roundnum), .rcon_out(rcon_preshift)); 

   // Shift RCON value
   assign rcon = {24'b0, rcon_preshift};    

   // Flag will be set if roundnum = 0xA = 0b1010
   assign lastRoundFlag = roundnum[3] & ~roundnum[2] & roundnum[1] & ~roundnum[0];    

   // Get rotated value fo ruse in tmp2
   assign rs1_rotate = {rs1[39:32], rs1[63:40]};

   // Assign tmp2 to a mux based on lastRoundFlag
   assign tmp2 = lastRoundFlag ? rs1[63:32] : rs1_rotate;    

   // Substitute bytes of value obtained for tmp2 using Rijndael sbox
   aes_sbox_word sbox(.in(tmp2),.out(Sbox_Out));    
   assign rd[31:0] = Sbox_Out ^ rcon;
   assign rd[63:32] = Sbox_Out ^ rcon;
   
	
endmodule


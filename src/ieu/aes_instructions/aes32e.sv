///////////////////////////////////////////
// aes32e.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes32esmi and aes32esi instruction: RV32 middle and final round AES encryption
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

module aes32e(
   input  logic [1:0]  bs,
   input  logic [31:0] rs1,
   input  logic [31:0] rs2,
   input  logic        finalround,
   output logic [31:0] result
);                
                
   logic [4:0] 			  shamt;
   logic [7:0] 			  SboxIn, SboxOut;
   logic [31:0] 		     so, mixed, rotin, rotout;
   
   assign shamt = {bs, 3'b0};                     // shamt = bs * 8 (convert bytes to bits)
   assign SboxIn = rs2[shamt +: 8];               // select byte bs of rs2
   aessbox sbox(SboxIn, SboxOut);                 // Substitute
   assign so = {24'h0, SboxOut};                  // Pad sbox output
   aesmixcolumns mwd(so, mixed);                  // Mix Word using aesmixword component
   mux2 #(32) rmux(mixed, so, finalround, rotin); // on final round, rotate so rather than mixed
   rotate #(32) mrot(rotin, shamt, rotout);       // Rotate the mixcolumns output left by shamt (bs * 8)
   assign result = rs1 ^ rotout;                 // xor with running value
endmodule

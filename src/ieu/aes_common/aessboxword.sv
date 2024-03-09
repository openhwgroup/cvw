///////////////////////////////////////////
// aessboxword.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: 4 sets of Rijndael S-BOX so whole word can be looked up simultaneously.
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

module aessboxword(input logic [31:0] in, output logic [31:0] out);   
   
   // Declare the SBOX for (least significant) byte 0 of the input
   aessbox sbox_b0(.in(in[7:0]), .out(out[7:0]));
   // Declare the SBOX for byte 1 of the input
   aessbox sbox_b1(.in(in[15:8]), .out(out[15:8]));
   // Declare the SBOX for byte 2 of the input
   aessbox sbox_b2(.in(in[23:16]), .out(out[23:16]));	
   // Declare the SBOX for byte 3 of the input	
   aessbox sbox_b3(.in(in[31:24]), .out(out[31:24]));
   
endmodule

///////////////////////////////////////////
// aes_Inv_sbox_128.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: 128-bit Inverse Substitution box comprised of 4x32-bit inverse s-boxes
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

module aes_Inv_sbox_128(input logic [127:0] in,
			output logic [127:0] out);

   // Declare the SBOX for (least significant) word 0 of the input
   aes_Inv_sbox_word sbox_w0(.in(in[31:0]), .out(out[31:0]));
   // Declare the SBOX for word 1 of the input
   aes_Inv_sbox_word sbox_w1(.in(in[63:32]), .out(out[63:32]));
   // Declare the SBOX for word 2 of the input
   aes_Inv_sbox_word sbox_w2(.in(in[95:64]), .out(out[95:64]));	
   // Declare the SBOX for word 3 of the input	
   aes_Inv_sbox_word sbox_w3(.in(in[127:96]), .out(out[127:96]));
				 
endmodule

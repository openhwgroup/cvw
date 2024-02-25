///////////////////////////////////////////
// mixword.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: Galois field operation to an individual 32-bit word
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

module mixword (word, mixed_word);
   
   // Declare Inputs/Outputs
   input logic [31:0] word;
   output logic [31:0] mixed_word;
   
   // Declare Internal Signals
   logic [7:0] 	       b0, b1, b2, b3;
   logic [7:0] 	       mb0, mb1, mb2, mb3;   
   logic [7:0] 	       gm2_0_Out;
   logic [7:0] 	       gm3_0_Out;   
   logic [7:0] 	       gm2_1_Out;
   logic [7:0] 	       gm3_1_Out;   
   logic [7:0] 	       gm2_2_Out;
   logic [7:0] 	       gm3_2_Out;   
   logic [7:0] 	       gm2_3_Out;
   logic [7:0] 	       gm3_3_Out;   
   
   // Break word into bytes
   assign b0 = word[31:24];
   assign b1 = word[23:16];
   assign b2 = word[15:8];
   assign b3 = word[7:0];

   // mb0 Galois components
   gm2 gm2_0(.gm2_In(b0), .gm2_Out(gm2_0_Out));
   gm3 gm3_0(.gm3_In(b3), .gm3_Out(gm3_0_Out));
   // mb1 Galois components
   gm2 gm2_1(.gm2_In(b1), .gm2_Out(gm2_1_Out));
   gm3 gm3_1(.gm3_In(b0), .gm3_Out(gm3_1_Out));
   // mb2 Galois components
   gm2 gm2_2(.gm2_In(b2), .gm2_Out(gm2_2_Out));
   gm3 gm3_2(.gm3_In(b1), .gm3_Out(gm3_2_Out));
   // mb3 Galois components
   gm2 gm2_3(.gm2_In(b3), .gm2_Out(gm2_3_Out));
   gm3 gm3_3(.gm3_In(b2), .gm3_Out(gm3_3_Out));

   // Combine Componenets into mixed word
   assign mb0 = gm2_0_Out ^ gm3_0_Out ^ b1 ^ b2;
   assign mb1 = gm2_1_Out ^ gm3_1_Out ^ b2 ^ b3;
   assign mb2 = gm2_2_Out ^ gm3_2_Out ^ b0 ^ b3;
   assign mb3 = gm2_3_Out ^ gm3_3_Out ^ b0 ^ b1;
   assign mixed_word = {mb0, mb1, mb2, mb3};
   
endmodule

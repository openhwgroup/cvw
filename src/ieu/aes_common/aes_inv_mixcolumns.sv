///////////////////////////////////////////
// aes_inv_mixcolumns.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: AES Inverted Mix Column Function for use with AES
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

module inv_mixword (input logic [31:0] word, output logic [31:0] mixed_word);

   // Instantiate Internal Logic
   logic [7:0] 	       b0, b1, b2, b3;
   logic [7:0] 	       mb0, mb1, mb2, mb3;
   
   logic [7:0] 	       gm9_mb0, gm11_mb0, gm13_mb0, gm14_mb0;
   logic [7:0] 	       gm9_mb1, gm11_mb1, gm13_mb1, gm14_mb1;
   logic [7:0] 	       gm9_mb2, gm11_mb2, gm13_mb2, gm14_mb2;
   logic [7:0] 	       gm9_mb3, gm11_mb3, gm13_mb3, gm14_mb3;

   // Break up word into 1 byte slices
   assign b0 = word[31:24];
   assign b1 = word[23:16];
   assign b2 = word[15:8];
   assign b3 = word[7:0];
   
   // mb0 Galois components
   gm9 gm9_0(.gm9_in(b1), .gm9_out(gm9_mb0));
   gm11 gm11_0(.gm11_in(b3), .gm11_out(gm11_mb0));
   gm13 gm13_0(.gm13_in(b2), .gm13_out(gm13_mb0));
   gm14 gm14_0(.gm14_in(b0), .gm14_out(gm14_mb0));

   // mb1 Galois components                	
   gm9 gm9_1(.gm9_in(b2), .gm9_out(gm9_mb1));  
   gm11 gm11_1(.gm11_in(b0), .gm11_out(gm11_mb1));
   gm13 gm13_1(.gm13_in(b3), .gm13_out(gm13_mb1));
   gm14 gm14_1(.gm14_in(b1), .gm14_out(gm14_mb1));
   
   // mb2 Galois components
   gm9 gm9_2(.gm9_in(b3), .gm9_out(gm9_mb2));
   gm11 gm11_2(.gm11_in(b1), .gm11_out(gm11_mb2));
   gm13 gm13_2(.gm13_in(b0), .gm13_out(gm13_mb2));
   gm14 gm14_2(.gm14_in(b2), .gm14_out(gm14_mb2));   
                                           
   // mb3 Galois components
   gm9 gm9_3(.gm9_in(b0), .gm9_out(gm9_mb3));
   gm11 gm11_3(.gm11_in(b2), .gm11_out(gm11_mb3));
   gm13 gm13_3(.gm13_in(b1), .gm13_out(gm13_mb3));
   gm14 gm14_3(.gm14_in(b3), .gm14_out(gm14_mb3));

   // XOR Galois components and assign output
   assign mb0 = gm9_mb0 ^ gm11_mb0 ^ gm13_mb0 ^ gm14_mb0;
   assign mb1 = gm9_mb1 ^ gm11_mb1 ^ gm13_mb1 ^ gm14_mb1;
   assign mb2 = gm9_mb2 ^ gm11_mb2 ^ gm13_mb2 ^ gm14_mb2;
   assign mb3 = gm9_mb3 ^ gm11_mb3 ^ gm13_mb3 ^ gm14_mb3;
   assign mixed_word = {mb0, mb1, mb2, mb3};  

endmodule // inv_mixword

module aes_inv_mixcols (input  logic [127:0] data, output logic [127:0] mixed_col);

   // Declare Internal logic
   logic [31:0] 	w0, w1, w2, w3;
   logic [31:0] 	ws0, ws1, ws2, ws3;
   
   // Break up input data into word components
   assign w0 = data[127:96];
   assign w1 = data[95:64];
   assign w2 = data[63:32];
   assign w3 = data[31:0];

   // Declare mixword components
   inv_mixword mw_0(.word(w0), .mixed_word(ws0));
   inv_mixword mw_1(.word(w1), .mixed_word(ws1));
   inv_mixword mw_2(.word(w2), .mixed_word(ws2));
   inv_mixword mw_3(.word(w3), .mixed_word(ws3));

   // Assign output to mixed word
   assign mixed_col = {ws0, ws1, ws2, ws3};

endmodule // inv_mixcols



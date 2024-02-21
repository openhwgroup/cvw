///////////////////////////////////////////
// aes_mixcolumns.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: RISC-V "Mix Columns"
//
// Documentation: RISC-V System on Chip Design Chapter 4 (Figure 4.4)
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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

/*
 * Purpose : The "mix columns" operation is essentially composed of a
 *	    nice little Galois field multiplication (of 1, 2 or 3) in the field
 *	    x^8 + x^4 + x^3 + x + 1.
 *	    The actual matrix you multiply by is
 *	    [2 3 1 1][a_0,j]
 *	    [1 2 3 1][a_1,j]
 *	    [1 1 2 3][a_2,j]
 *          [3 1 1 2][a_3,j]
 * 
 * Reference: secworks repo
 */

module aes_mixcolumns(data, mixedcols);

   // Declare Inputs/Outputs
   input  logic [127:0] data;
   output logic [127:0] mixedcols;
   
   // Declare internal Logic
   logic [31:0] 	w0, w1, w2, w3;
   logic [31:0] 	ws0, ws1, ws2, ws3;
   
   // Break up data into individual words
   assign w0 = data[127:96];
   assign w1 = data[95:64];
   assign w2 = data[63:32];
   assign w3 = data[31:0];
   
   // Instantiate The mix words components for the words
   mixword mw0(.word(w0), .mixed_word(ws0));
   mixword mw1(.word(w1), .mixed_word(ws1));
   mixword mw2(.word(w2), .mixed_word(ws2));
   mixword mw3(.word(w3), .mixed_word(ws3));   
   
   // Assign Output
   assign mixedcols = {ws0, ws1, ws2, ws3};
   
endmodule // mixcolumns

//This applies the Galois field operations to an individual 32 bit word.
module mixword (word, mixed_word);
   
   // Declare Inputs/Outputs
   input logic [31:0] word;
   output logic [31:0] mixed_word;
   
   // Declare Internal Signals
   logic [7:0] 	       b0, b1, b2, b3;
   logic [7:0] 	       mb0, mb1, mb2, mb3;
   
   logic [7:0] 	       gm2_0_out;
   logic [7:0] 	       gm3_0_out;
   
   logic [7:0] 	       gm2_1_out;
   logic [7:0] 	       gm3_1_out;
   
   logic [7:0] 	       gm2_2_out;
   logic [7:0] 	       gm3_2_out;
   
   logic [7:0] 	       gm2_3_out;
   logic [7:0] 	       gm3_3_out;   
   
   // Break word into bytes
   assign b0 = word[31:24];
   assign b1 = word[23:16];
   assign b2 = word[15:8];
   assign b3 = word[7:0];

   // mb0 Galois components
   gm2 gm2_0(.gm2_in(b0),
	     .gm2_out(gm2_0_out));
   gm3 gm3_0(.gm3_in(b3),
	     .gm3_out(gm3_0_out));

   // mb1 Galois components
   gm2 gm2_1(.gm2_in(b1),
	     .gm2_out(gm2_1_out));
   gm3 gm3_1(.gm3_in(b0),
	     .gm3_out(gm3_1_out));

   // mb2 Galois components
   gm2 gm2_2(.gm2_in(b2),
	     .gm2_out(gm2_2_out));
   gm3 gm3_2(.gm3_in(b1),
	     .gm3_out(gm3_2_out));

   // mb3 Galois components
   gm2 gm2_3(.gm2_in(b3),
	     .gm2_out(gm2_3_out));
   gm3 gm3_3(.gm3_in(b2),
	     .gm3_out(gm3_3_out));

   // Combine Componenets into mixed word
   assign mb0 = gm2_0_out ^ gm3_0_out ^ b1 ^ b2;
   assign mb1 = gm2_1_out ^ gm3_1_out ^ b2 ^ b3;
   assign mb2 = gm2_2_out ^ gm3_2_out ^ b0 ^ b3;
   assign mb3 = gm2_3_out ^ gm3_3_out ^ b0 ^ b1;
   assign mixed_word = {mb0, mb1, mb2, mb3};
   
endmodule

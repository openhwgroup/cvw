///////////////////////////////////////////
// aes_mixcolumns.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: AES "Mix Columns" Operation
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

module aes_mixcolumns(Data, mixedcols);

   // Declare Inputs/Outputs
   input  logic [127:0] Data;
   output logic [127:0] mixedcols;
   
   // Declare internal Logic
   logic [31:0] 	w0, w1, w2, w3;
   logic [31:0] 	ws0, ws1, ws2, ws3;
   
   // Break up Data into individual words
   assign w0 = Data[127:96];
   assign w1 = Data[95:64];
   assign w2 = Data[63:32];
   assign w3 = Data[31:0];
   
   // Instantiate The mix words components for the words
   mixword mw0(.word(w0), .mixed_word(ws0));
   mixword mw1(.word(w1), .mixed_word(ws1));
   mixword mw2(.word(w2), .mixed_word(ws2));
   mixword mw3(.word(w3), .mixed_word(ws3));   
   
   // Assign Output
   assign mixedcols = {ws0, ws1, ws2, ws3};
   
endmodule // mixcolumns

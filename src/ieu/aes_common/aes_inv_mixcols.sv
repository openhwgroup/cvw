///////////////////////////////////////////
// aes_inv_mixcols.sv
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



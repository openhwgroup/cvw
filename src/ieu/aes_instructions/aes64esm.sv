///////////////////////////////////////////
// aes64esm.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes64esm instruction
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

module aes64esm(input logic [63:0]  rs1,
                input logic [63:0]  rs2,
                output logic [63:0] data_out);
   
    // Intermediary Signals
    logic [127:0] shiftRow_out;
    logic [63:0] sbox_out;
                
    // AES shiftrow unit
    aes_shiftrow srow(.dataIn({rs2,rs1}), .dataOut(shiftRow_out));
   
    // Apply substitution box to 2 lower words
    aes_sbox_word sbox_0(.in(shiftRow_out[31:0]), .out(sbox_out[31:0]));
    aes_sbox_word sbox_1(.in(shiftRow_out[63:32]), .out(sbox_out[63:32]));
   
    // Apply mix columns operations
    mixword mw0(.word(sbox_out[31:0]), .mixed_word(data_out[31:0]));
    mixword mw1(.word(sbox_out[63:32]), .mixed_word(data_out[63:32]));    
endmodule

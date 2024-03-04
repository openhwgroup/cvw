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
                output logic [63:0] Data_Out);
   
    // Intermediary Signals
    logic [127:0] ShiftRow_Out;
    logic [63:0] Sbox_Out;
                
    // AES shiftrow unit
    aes_Shiftrow srow(.DataIn({rs2,rs1}), .DataOut(ShiftRow_Out));
   
    // Apply substitution box to 2 lower words
    aes_Sbox_Word sbox_0(.in(ShiftRow_Out[31:0]), .out(Sbox_Out[31:0]));
    aes_Sbox_Word sbox_1(.in(ShiftRow_Out[63:32]), .out(Sbox_Out[63:32]));
   
    // Apply mix columns operations
    aes_Mixcolumns mw0(.in(Sbox_Out[31:0]), .out(Data_Out[31:0]));
    aes_Mixcolumns mw1(.in(Sbox_Out[63:32]), .out(Data_Out[63:32]));    
endmodule

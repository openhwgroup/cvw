///////////////////////////////////////////
// zknd_32.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 27 November 2023
// Modified: 31 January 2024
//
// Purpose: RISC-V ZKND top level unit for 32-bit instructions
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

module zknd_32 #(parameter WIDTH=32) 
   (input  logic [WIDTH-1:0] A, B,
    input logic [6:0] 	     Funct7,
    input logic [2:0] 	     ZKNDSelect,
    output logic [WIDTH-1:0] ZKNDResult);
   
   logic [31:0] 	     aes32dsiRes;
   logic [31:0] 	     aes32dsmiRes;
   
   // RV32
   aes32dsi aes32dsi (.bs(Funct7[6:5]), .rs1(A), .rs2(B), .data_out(aes32dsiRes));
   aes32dsmi aes32dsmi (.bs(Funct7[6:5]), .rs1(A), .rs2(B), .data_out(aes32dsmiRes));
   
   mux2 #(WIDTH) zkndmux (aes32dsiRes, aes32dsmiRes, ZKNDSelect[0], ZKNDResult);

endmodule
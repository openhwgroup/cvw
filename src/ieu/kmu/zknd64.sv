///////////////////////////////////////////
// zknd64.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 27 November 2023
// Modified: 31 January 2024
//
// Purpose: RISC-V ZKND top level unit for 64-bit instructions: RV64 NIST AES Decryption
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

module zknd64 #(parameter WIDTH=32) (
   input  logic [WIDTH-1:0] A, B,
   input  logic [6:0] 	    Funct7,
   input  logic [3:0] 	    round,
   input  logic [3:0] 	    ZKNDSelect,
   output logic [WIDTH-1:0] ZKNDResult
);
   
   logic [63:0] 	     aes64dRes, aes64imRes, aes64ks1iRes, aes64ks2Res;
   
   // RV64
   aes64d    aes64d(.rs1(A), .rs2(B), .finalround(ZKNDSelect[2]), .aes64im(ZKNDSelect[3]), .result(aes64dRes)); // decode AES
   aes64ks1i aes64ks1i(.round, .rs1(A), .result(aes64ks1iRes));
   aes64ks2  aes64ks2(.rs2(B), .rs1(A), .result(aes64ks2Res));
   
   mux3 #(WIDTH) zkndmux(aes64dRes, aes64ks1iRes, aes64ks2Res, ZKNDSelect[1:0], ZKNDResult);
endmodule

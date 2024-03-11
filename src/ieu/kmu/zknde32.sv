///////////////////////////////////////////
// zknde32.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 27 November 2023
// Modified: 31 January 2024
//
// Purpose: NIST AES64 decryption and encryption 
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

module zknde32 import cvw::*; #(parameter cvw_t P) (
   input  logic [31:0] A, B,
   input  logic [6:0]  Funct7,
   input  logic [3:0]  round,
   input  logic [3:0]  ZKNSelect,
   output logic [31:0] ZKNDEResult
);

     logic [31:0]        ZKNEResult, ZKNDResult;             

    if (P.ZKND_SUPPORTED) aes32d aes32d(.bs(Funct7[6:5]), .rs1(A), .rs2(B), .finalround(ZKNSelect[2]), .result(ZKNDResult));
    if (P.ZKNE_SUPPORTED) aes32e aes32e(.bs(Funct7[6:5]), .rs1(A), .rs2(B), .finalround(ZKNSelect[2]), .result(ZKNEResult));

    // Mux result if both decrypt and encrypt are supported; otherwise, choose the only result
    if (P.ZKND_SUPPORTED & P.ZKNE_SUPPORTED) 
        mux2 #(32) zknmux(ZKNDResult, ZKNEResult, ZKNSelect[0], ZKNDEResult); 
    else if (P.ZKND_SUPPORTED)
        assign ZKNDEResult = ZKNDResult;
    else 
        assign ZKNDEResult = ZKNEResult;
endmodule

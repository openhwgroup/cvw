///////////////////////////////////////////
// extend.sv
//
// Written: David_Harris@hmc.edu, Sarah.Harris@unlv.edu
// Created: 9 January 2021
// Modified: 
//
// Purpose: Produce sign-extended immediates from various formats
// 
// Documentation: RISC-V System on Chip Design Chapter 4 (Figure 4.3)
//
// A component of the CORE-V-WALLY configurable RISC-V project.
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

`include "wally-config.vh"

module extend (
  input  logic [31:7]       InstrD,      // All instruction bits except opcode (lower 7 bits)
  input  logic [2:0]        ImmSrcD,     // Select what kind of extension to perform
  output logic [`XLEN-1:0 ] ImmExtD);    // Extended immediate

  localparam [`XLEN-1:0] undefined = {(`XLEN){1'bx}}; // could change to 0 after debug
 
  always_comb
    case(ImmSrcD) 
      // I-type 
      3'b000:   ImmExtD = {{(`XLEN-12){InstrD[31]}}, InstrD[31:20]};  
      // S-type (stores)
      3'b001:   ImmExtD = {{(`XLEN-12){InstrD[31]}}, InstrD[31:25], InstrD[11:7]}; 
      // B-type (branches)
      3'b010:   ImmExtD = {{(`XLEN-12){InstrD[31]}}, InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0}; 
      // J-type (jal)
      3'b011:   ImmExtD = {{(`XLEN-20){InstrD[31]}}, InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0}; 
      // U-type (lui, auipc)
      3'b100:  ImmExtD = {{(`XLEN-31){InstrD[31]}}, InstrD[30:12], 12'b0}; 
      // Store Conditional: zero offset
      3'b101:  if (`A_SUPPORTED) ImmExtD = 0;
               else              ImmExtD = undefined;
      default: ImmExtD = undefined; // undefined
    endcase  
endmodule

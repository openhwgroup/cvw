///////////////////////////////////////////
// shifter.sv
//
// Written: David_Harris@hmc.edu, Sarah.Harris@unlv.edu, Kevin Kim <kekim@hmc.edu>
// Created: 9 January 2021
// Modified: 6 February 2023
//
// Purpose: RISC-V 32/64 bit shifter
// 
// Documentation: RISC-V System on Chip Design Chapter 4 (Figure 4.5, Table 4.3)
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

module shifter (
  input  logic [`XLEN-1:0]     shA,                           // shift Source
  input  logic [`XLEN-1:0]   rotA,                          // rotate source
  input  logic [`LOG_XLEN-1:0] Amt,                         // Shift amount
  input  logic                 Right, Rotate, W64, Sign,    // Shift right, rotate signals
  output logic [`XLEN-1:0]     Y);                          // Shifted result

  logic [2*`XLEN-2:0]      z, zshift;                       // Input to funnel shifter, shifted amount before truncated to 32 or 64 bits
  logic [`LOG_XLEN-1:0]    amttrunc, offset;                // Shift amount adjusted for RV64, right-shift amount

  if (`ZBB_SUPPORTED) begin: rotfunnel
    if (`XLEN==32) begin // rv32 with rotates
      always_comb  // funnel mux
        case({Right, Rotate})
          2'b00: z = {shA[31:0], 31'b0};
          2'b01: z = {rotA,rotA[31:1]};
          2'b10: z = {{31{Sign}}, shA[31:0]};
          2'b11: z = {rotA[30:0],rotA};
        endcase
      assign amttrunc = Amt; // shift amount
    end else begin // rv64 with rotates
      always_comb  // funnel mux
        case ({Right, Rotate})
          2'b00: z = {shA[63:0],{63'b0}};
          2'b01: z = {rotA, rotA[63:1]};
          2'b10: z = {{63{Sign}},shA[63:0]};
          2'b11: z = {rotA[62:0],rotA[63:0]};
        endcase
      assign amttrunc = W64 ? {1'b0, Amt[4:0]} : Amt; // 32- or 64-bit shift
    end
  end else begin: norotfunnel
    if (`XLEN==32) begin:shifter // RV32
      always_comb  // funnel mux
        if (Right)  z = {{31{Sign}}, shA[31:0]};
        else        z = {shA[31:0], 31'b0};
      assign amttrunc = Amt; // shift amount
    end else begin:shifter  // RV64
      always_comb  // funnel mux
        if (Right)  z = {{63{Sign}},shA[63:0]};
        else        z = {shA[63:0],{63'b0}};
      assign amttrunc = W64 ? {1'b0, Amt[4:0]} : Amt; // 32- or 64-bit shift
    end
  end
  
  // Opposite offset for right shifts
  assign offset = Right ? amttrunc : ~amttrunc;
  
  // Funnel operation
  assign zshift = z >> offset;
  assign Y = zshift[`XLEN-1:0];    
endmodule



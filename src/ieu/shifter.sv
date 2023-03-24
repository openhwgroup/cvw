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
  input  logic [`XLEN-1:0]     A,                             // shift Source
  input  logic [`LOG_XLEN-1:0] Amt,                           // Shift amount
  input  logic                 Right, Rotate, W64, SubArith, // Shift right, rotate, W64-type operation, arithmetic shift
  output logic [`XLEN-1:0]     Y);                            // Shifted result

  logic [2*`XLEN-2:0]      Z, ZShift;                         // Input to funnel shifter, shifted amount before truncated to 32 or 64 bits
  logic [`LOG_XLEN-1:0]    TruncAmt, Offset;                  // Shift amount adjusted for RV64, right-shift amount
  logic                    Sign;                              // Sign bit for sign extension

  assign Sign = A[`XLEN-1] & SubArith;  // sign bit for sign extension
  if (`XLEN==32) begin // rv32
    if (`ZBB_SUPPORTED) begin: rotfunnel32 //rv32 shifter with rotates
      always_comb  // funnel mux
        case({Right, Rotate})
<<<<<<< HEAD
          2'b00: Z = {A[31:0], 31'b0};
          2'b01: Z = {A[31:0], A[31:1]};
          2'b10: Z = {{31{Sign}}, A[31:0]};
          2'b11: Z = {A[30:0], A};
        endcase
      assign TruncAmt = Amt; // shift amount
    end else begin // rv64 with rotates
=======
          2'b00: z = {A[31:0], 31'b0};
          2'b01: z = {A[31:0], A[31:1]};
          2'b10: z = {{31{Sign}}, A[31:0]};
          2'b11: z = {A[30:0], A[31:0]};
        endcase
    end else begin: norotfunnel32 //rv32 shifter without rotates
      always_comb  // funnel mux
        if (Right)  z = {{31{Sign}}, A[31:0]};
        else        z = {A[31:0], 31'b0};
    end
    assign amttrunc = Amt; // shift amount
  end else begin // rv64
    logic [`XLEN-1:0]         A64;                            
    mux3 #(64) extendmux({{32{1'b0}}, A[31:0]}, {{32{A[31]}}, A[31:0]}, A, {~W64, SubArith}, A64); // bottom 32 bits are always A[31:0], so effectively a 32-bit upper mux
    if (`ZBB_SUPPORTED) begin: rotfunnel64 // rv64 shifter with rotates
>>>>>>> 46e08410112c38dc213a034105f96f6979e1680a
      // shifter rotate source select mux
      logic [`XLEN-1:0]   RotA;                          // rotate source
      mux2 #(`XLEN) rotmux(A, {A[31:0], A[31:0]}, W64, RotA); // W64 rotatons
      always_comb  // funnel mux
        case ({Right, Rotate})
<<<<<<< HEAD
          2'b00: Z = {A[63:0],{63'b0}};
          2'b01: Z = {RotA, RotA[63:1]};
          2'b10: Z = {{63{Sign}}, A[63:0]};
          2'b11: Z = {RotA[62:0], RotA};
        endcase
      assign TruncAmt = W64 ? {1'b0, Amt[4:0]} : Amt; // 32- or 64-bit shift
    end
  end else begin: norotfunnel
    if (`XLEN==32) begin:shifter // RV32
      always_comb  // funnel mux
        if (Right)  Z = {{31{Sign}}, A[31:0]};
        else        Z = {A[31:0], 31'b0};
      assign TruncAmt = Amt; // shift amount
    end else begin:shifter  // RV64
      always_comb  // funnel mux
        if (Right)  Z = {{63{Sign}}, A[63:0]};
        else        Z = {A[63:0], {63'b0}};
      assign TruncAmt = W64 ? {1'b0, Amt[4:0]} : Amt; // 32- or 64-bit shift
=======
          2'b00: z = {A64[63:0],{63'b0}};
          2'b01: z = {RotA[63:0], RotA[63:1]};
          2'b10: z = {{63{Sign}}, A64[63:0]};
          2'b11: z = {RotA[62:0], RotA[63:0]};
        endcase
    end else begin: norotfunnel64 // rv64 shifter without rotates
      always_comb  // funnel mux
        if (Right)  z = {{63{Sign}}, A64[63:0]};
        else        z = {A64[63:0], {63'b0}};
>>>>>>> 46e08410112c38dc213a034105f96f6979e1680a
    end
    assign amttrunc = W64 ? {1'b0, Amt[4:0]} : Amt; // 32- or 64-bit shift
  end
  
  // Opposite offset for right shifts
  assign Offset = Right ? TruncAmt : ~TruncAmt;
  
  // Funnel operation
  assign ZShift = Z >> Offset;
  assign Y = ZShift[`XLEN-1:0];    
endmodule



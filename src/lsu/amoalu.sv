///////////////////////////////////////////
// amoalu.sv
//
// Written: David_Harris@hmc.edu
// Created: 10 March 2021
// Modified: 18 January 2023 
//
// Purpose: Performs AMO operations
// 
// Documentation: RISC-V System on Chip Design Chapter 14 (Figure ***)
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

module amoalu import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.XLEN-1:0] ReadDataM,    // LSU's ReadData
  input  logic [P.XLEN-1:0] IHWriteDataM, // LSU's WriteData
  input  logic [6:0]        LSUFunct7M,   // ALU Operation
  input  logic [2:0]        LSUFunct3M,   // Memoy access width
  output logic [P.XLEN-1:0] AMOResultM    // ALU output
);

  logic [P.XLEN-1:0] a, b, y;

  // *** see how synthesis generates this and optimize more structurally if necessary to share hardware
  // a single carry chain should be shared for + and the four min/max
  // and the same mux can be used to select b for swap.
  always_comb 
    case (LSUFunct7M[6:2])
      5'b00001: y = b;                                      // amoswap
      5'b00000: y = a + b;                                  // amoadd
      5'b00100: y = a ^ b;                                  // amoxor
      5'b01100: y = a & b;                                  // amoand
      5'b01000: y = a | b;                                  // amoor
      5'b10000: y = ($signed(a) < $signed(b)) ? a : b;      // amomin
      5'b10100: y = ($signed(a) >= $signed(b)) ? a : b;     // amomax
      5'b11000: y = ($unsigned(a) < $unsigned(b)) ? a : b;  // amominu
      5'b11100: y = ($unsigned(a) >= $unsigned(b)) ? a : b; // amomaxu
      default:  y = 'x;                                     // undefined; *** could change to b for efficiency
    endcase

  // sign extend if necessary
  if (P.XLEN == 32) begin:sext
    assign a = ReadDataM;
    assign b = IHWriteDataM;
    assign AMOResultM = y;
  end else begin:sext // P.XLEN = 64
    always_comb 
      if (LSUFunct3M[1:0] == 2'b10) begin // sign-extend word-length operations
        a = {{32{ReadDataM[31]}}, ReadDataM[31:0]};
        b = {{32{IHWriteDataM[31]}}, IHWriteDataM[31:0]};
        AMOResultM = {{32{y[31]}}, y[31:0]};
      end else begin
        a = ReadDataM;
        b = IHWriteDataM;
        AMOResultM = y;
      end
  end
endmodule

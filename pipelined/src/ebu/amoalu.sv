///////////////////////////////////////////
// amoalu.sv
//
// Written: David_Harris@hmc.edu 10 March 2021
// Modified: 
//
// Purpose: Performs AMO operations
// 
// A component of the Wally configurable RISC-V project.
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

// *** this should probably be moved into the LSU because it is instantiated in the D$

module amoalu (
  input  logic [`XLEN-1:0] srca, srcb,
  input  logic [6:0]       funct,
  input  logic [1:0]       width,
  output logic [`XLEN-1:0] result);

  logic [`XLEN-1:0] a, b, y;

  // *** can this be muxed into the regular ALU to avoid needing a second one?  Only a good
  // idea if the regular ALU is not the critical path

  // *** see how synthesis generates this and optimize more structurally if necessary to share hardware
  // a single carry chain should be shared for + and the four min/max
  // and the same mux can be used to select b for swap.
  always_comb 
    case (funct[6:2])
      5'b00001: y = b;                                // amoswap
      5'b00000: y = a + b;                            // amoadd
      5'b00100: y = a ^ b;                            // amoxor
      5'b01100: y = a & b;                            // amoand
      5'b01000: y = a | b;                            // amoor
      5'b10000: y = ($signed(a) < $signed(b)) ? a : b;                  // amomin
      5'b10100: y = ($signed(a) >= $signed(b)) ? a : b;                 // amomax
      5'b11000: y = ($unsigned(a) < $unsigned(b)) ? a : b;  // amominu
      5'b11100: y = ($unsigned(a) >= $unsigned(b)) ? a : b; // amomaxu
      default:  y = `XLEN'bx;                              // undefined; *** could change to b for efficiency
    endcase

  // sign extend if necessary
  if (`XLEN == 32) begin:sext
    assign a = srca;
    assign b = srcb;
    assign result = y;
  end else begin:sext // `XLEN = 64
    always_comb 
      if (width == 2'b10) begin // sign-extend word-length operations
        // *** it would be more efficient to look at carry out of bit 31 to determine comparisons than do this big mux on and b
        a = {{32{srca[31]}}, srca[31:0]};
        b = {{32{srcb[31]}}, srcb[31:0]};
        result = {{32{y[31]}}, y[31:0]};
      end else begin
        a = srca;
        b = srcb;
        result = y;
      end
  end
endmodule


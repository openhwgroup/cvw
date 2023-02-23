
///////////////////////////////////////////
// cnt.sv
//
// Written: Kevin Kim <kekim@hmc.edu>
// Created: 4 February 2023
// Modified: 
//
// Purpose: Count Instruction Submodule
//
// Documentation: RISC-V System on Chip Design Chapter ***
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

module cnt #(parameter WIDTH = 32) (
  input  logic [WIDTH-1:0] A, B,       // Operands
  input  logic W64,                    // Indicates word operation
  output logic [WIDTH-1:0] CntResult   // count result
);

  //count instructions
  logic [WIDTH-1:0] czResult;        // count zeros result
  logic [WIDTH-1:0] cpopResult;      // population count result
  logic [WIDTH-1:0] lzcA, popcntA;
  logic [WIDTH-1:0] revA;

  //in both rv64, rv32
  bitreverse #(WIDTH) brtz(.a(A), .b(revA));
  
  //only in rv64
  if (WIDTH==64) begin
    //NOTE: signal widths can be decreased
    always_comb begin
      //clz input select mux
      case({B[4:0],W64})
        6'b00000_0: lzcA = A;                       //clz
        6'b00000_1: lzcA = {A[31:0],{32{1'b1}}};    //clzw
        6'b00001_0: lzcA = revA;                    //ctz
        6'b00001_1: lzcA = {revA[63:32],{32{1'b1}}}; //ctzw
        default: lzcA = A;
      endcase 

      //cpop select mux
      case ({B[4:0],W64})
        6'b00010_0: popcntA = A;
        6'b00010_1: popcntA = {{32{1'b0}}, A[31:0]};
        default: popcntA = A;
      endcase
    end
  end
  else begin
    //rv32
    assign popcntA = A;
    always_comb begin
      //clz input slect mux
      case(B[4:0])
        5'b00000: lzcA = A;
        5'b00001: lzcA = revA;
        default: lzcA = A;
      endcase
    end
  end

  
  lzc #(WIDTH) lzc(.num(lzcA), .ZeroCnt(czResult[$clog2(WIDTH):0]));
  popcnt #(WIDTH) popcntw(.num(popcntA), .PopCnt(cpopResult[$clog2(WIDTH):0]));
  // zero extend these results to fit into width *** There may be a more elegant way to do this
  assign czResult[WIDTH-1:$clog2(WIDTH)+1] = {(WIDTH-$clog2(WIDTH)-1){1'b0}}; 
  assign cpopResult[WIDTH-1:$clog2(WIDTH)+1] = {(WIDTH-$clog2(WIDTH)-1){1'b0}};

  assign CntResult = (B[1]) ? cpopResult : czResult;

endmodule

///////////////////////////////////////////
// zbb.sv
//
// Written: Kevin Kim <kekim@hmc.edu> and Kip Macsai-Goren <kmacsaigoren@hmc.edu>
// Created: 2 February 2023
// Modified: 
//
// Purpose: RISC-V miscellaneous bit manipulation unit (subset of ZBB instructions)
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

module zbb #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,       // Operands
  input  logic [2:0]       Funct3,     // Indicates operation to perform
  input  logic [6:0]       Funct7,     // Indicates operation to perform
  input  logic [6:0]       W64,        // Indicates word operation
  output logic [WIDTH-1:0] ZBBResult); // ZBC result


  //count instructions
  logic [WIDTH-1:0] czResult;
  logic [WIDTH-1:0] clzResult;         //leading zeros result
  logic [WIDTH-1:0] ctzResult;         //trailing zeros result
  logic [WIDTH-1:0] cpopResult;        //population count result
  logic [WIDTH-1:0] clzA, clzB;
  logic [WIDTH-1:0] clzwA, clzwB;
  logic [WIDTH-1:0] ctzA, ctzB;
  logic [WIDTH-1:0] ctzwA, ctzwB;
  logic [WIDTH-1:0] cpopwA, cpopA;
  logic [WIDTH-1:0] cpopwB, cpopB;

  //in both rv64, rv32
  assign clzA = A;
  bitreverse #(WIDTH) brtz(.a(A), .b(ctzA));
  
  //only in rv64
  if (WIDTH==64) begin
    assign clzwA = {A[31:0],{32{1'b1}}};
    bitreverse #(WIDTH) brtzw(.a({{32{1'b1}},A[31:0]}), .b(ctzwA));
    assign cpopwA = {{32{1'b0}},A};

  end
  else begin
    assign clzwA = 32'b0;
    assign ctzwA = 32'b0;
    assign cpopwA = 32'b0;
  end

  //NOTE: Can be simplified to a single lzc with a 4-select mux. We are currently producing all cz results and selecting from those later.
  //NOTE: Signal width mistmatch from log2(WIDTH) to WIDTH but deal with that later.
  lzc #(WIDTH) lzc(.num(clzA), .ZeroCnt(clzB));
  lzc #(WIDTH) lzwc(.num(clzwA), .ZeroCnt(clzwB));
  lzc #(WIDTH) tzc(.num(ctzA), .ZeroCnt(ctzB));
  lzc #(WIDTH) tzwc(.num(ctzwA), .ZeroCnt(ctzwB));

  popcnt #(WIDTH) popcntw(.num(cpopwA), .PopCnt(cpopwB));
  popcnt #(WIDTH) popcnt(.num(cpopA), .PopCnt(cpopB));

  if (WIDTH==64) begin
    assign clzResult = W64 ? clzwB : clzB;
    assign ctzResult = W64 ? ctzwB : ctzB;
    assign cpopResult = W64 ? cpopwB : cpopB;
  end
  else begin
    assign clzResult = clzB;
    assign ctzResult = ctzB;
    assign cpopResult = cpopB;
  end

  



  



  


  //byte instructions
  logic [WIDTH-1:0] OrcBResult;
  logic [WIDTH-1:0] Rev8Result;

  genvar i;

  for (i=0;i<WIDTH;i+=8) begin:loop
    assign OrcBResult[i+7:i] = {8{|A[i+7:i]}};
    assign Rev8Result[WIDTH-i:WIDTH-i-7] = A[i+7:i];
  end

  //can replace with structural mux by looking at bit 4 in rs2 field
  always_comb begin 
      case ({Funct7, Funct3, B})
      15'b0010100_101_00111: ZBBResult = OrcBResult;
      15'b0110100_101_11000: ZBBResult = Rev8Result;
      15'b0110101_101_11000: ZBBResult = Rev8Result;
      15'b0110000_001_00000: ZBBResult = clzResult;
      15'b0110000_001_00010: ZBBResult = cpopResult;
      15'b0110000_001_00001: ZBBResult = ctzResult;
      15'b0110101_101_11000: ZBBResult = Rev8Result;
      15'b0110101_101_11000: ZBBResult = Rev8Result;
      endcase
  end


endmodule
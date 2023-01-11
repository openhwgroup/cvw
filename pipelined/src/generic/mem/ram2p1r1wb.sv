///////////////////////////////////////////
// ram2p1r1wb
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 14, 2021
// Modified: 
//
// Purpose: Behavioral model of two port SRAM.  While this is synthesizable it will produce a flip flop based memory which
//          behaves with the timing of an SRAM typical of GF 14nm, 32nm, and 45nm.
//          
// 
// to preload this memory we can use the following command
// in modelsim's do file.
// mem load -infile <relative path to the text file > -format <bin|hex> <hierarchy to the memory.>
// example
// mem load -infile twoBitPredictor.txt -format bin testbench/dut/core/ifu/bpred/DirPredictor/memory/memory
//
// A component of the CORE-V Wally configurable RISC-V project.
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

module ram2p1r1wb
  #(parameter int DEPTH = 10,
    parameter int WIDTH = 2
    )

  (input logic              clk,
   input logic              reset,
  
   // port 1 is read only
   input logic [DEPTH-1:0]  ra1,
   output logic [WIDTH-1:0] rd1,
   input logic              ren1,
  
   // port 2 is write only
   input logic [DEPTH-1:0]  wa2,
   input logic [WIDTH-1:0]  wd2,
   input logic              wen2,
   input logic [WIDTH-1:0]  bwe2
);
  

  logic [DEPTH-1:0]         ra1q, wa2q;
  logic                     wen2q;
  logic [WIDTH-1:0]         wd2q;

  logic [WIDTH-1:0]         mem[2**DEPTH-1:0];
  logic [WIDTH-1:0]         bwe;

  
  // SRAMs address busses are always registered first
  // *** likely issued DH and RT 12/20/22
  //   wrong enable for write port registers
  //  prefer to code read like ram1p1rw
  //  prefer not to have two-cycle write latency
  //  will require branch predictor changes
  
  flopenr #(DEPTH) ra1Reg(clk, reset, ren1, ra1, ra1q);
  flopenr #(DEPTH) wa2Reg(clk, reset, ren1, wa2, wa2q);
  flopr   #(1)     wen2Reg(clk, reset, wen2, wen2q);
  flopenr #(WIDTH) wd2Reg(clk, reset, ren1, wd2, wd2q);

  // read port
  assign rd1 = mem[ra1q];
  
  // write port
  assign bwe = {WIDTH{wen2q}} & bwe2;
  always_ff @(posedge clk)
    mem[wa2q] <= wd2q & bwe | mem[wa2q] & ~bwe;
 
endmodule  



///////////////////////////////////////////
// 2 port sram.
//
// Written: ross1728@gmail.com May 3, 2021
//          Two port SRAM 1 read port and 1 write port.
//          When clk rises Addr and LineWriteData are sampled.
//          Following the clk edge read data is output from the sampled Addr.
//          Write 
//
// Purpose: Storage and read/write access to data cache data, tag valid, dirty, and replacement.
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

// WIDTH is number of bits in one "word" of the memory, DEPTH is number of such words

`include "wally-config.vh"

module ram2p1r1wbe #(parameter DEPTH=128, WIDTH=256) (
  input  logic                     clk,
  input  logic                     ce1, ce2,
  input  logic [$clog2(DEPTH)-1:0] ra1,
  input  logic [WIDTH-1:0]         wd2,
  input  logic [$clog2(DEPTH)-1:0] wa2,
  input  logic                     we2,
  input  logic [(WIDTH-1)/8:0]     bwe2,
  output logic [WIDTH-1:0]         rd1
);

  logic [WIDTH-1:0]               mem[DEPTH-1:0];

  // ***************************************************************************
  // TRUE Smem macro
  // ***************************************************************************

  // ***************************************************************************
  // READ first SRAM model
  // ***************************************************************************
    integer i;

  // Read
  always_ff @(posedge clk) 
    if(ce1) rd1 <= #1 mem[ra1];
  
  // Write divided into part for bytes and part for extra msbs
  if(WIDTH >= 8) 
    always @(posedge clk) 
      if (ce2 & we2) 
        for(i = 0; i < WIDTH/8; i++) 
          if(bwe2[i]) mem[wa2][i*8 +: 8] <= #1 wd2[i*8 +: 8];
  
  if (WIDTH%8 != 0) // handle msbs if width not a multiple of 8
    always @(posedge clk) 
      if (ce2 & we2 & bwe2[WIDTH/8])
        mem[wa2][WIDTH-1:WIDTH-WIDTH%8] <= #1 wd2[WIDTH-1:WIDTH-WIDTH%8];

endmodule

///////////////////////////////////////////
// 1 port sram.
//
// Written: ross1728@gmail.com May 3, 2021
//          Basic sram with 1 read write port.
//          When clk rises Addr and LineWriteData are sampled.
//          Following the clk edge read data is output from the sampled Addr.
//          Write 
//
// Purpose: Storage and read/write access to data cache data, tag valid, dirty, and replacement.
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

// WIDTH is number of bits in one "word" of the memory, DEPTH is number of such words

`include "wally-config.vh"

module ram2p1r1wbefix #(parameter DEPTH=128, WIDTH=256) (
  input logic                     clk,
  input logic                     ce1, ce2,
  input logic [$clog2(DEPTH)-1:0] ra1,
  input logic [WIDTH-1:0]         wd2,
  input logic [$clog2(DEPTH)-1:0] wa2,
  input logic                     we2,
  input logic [(WIDTH-1)/8:0]     bwe2,
  output logic [WIDTH-1:0]        rd1);

    logic [WIDTH-1:0]               mem[DEPTH-1:0];

  // ***************************************************************************
  // TRUE Smem macro
  // ***************************************************************************

  // ***************************************************************************
  // READ first SRAM model
  // ***************************************************************************
    integer i;

  // Read
  always @(posedge clk) 
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

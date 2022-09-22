///////////////////////////////////////////
// 1 port sram.
//
// Written: ross1728@gmail.com May 3, 2021
//          Basic sram with 1 read write port.
//          When clk rises Addr and CacheWriteData are sampled.
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

module sram1p1rw #(parameter DEPTH=128, WIDTH=256) (
  input logic                     clk,
  input logic                     ce,
  input logic [$clog2(DEPTH)-1:0] addr,
  input logic [WIDTH-1:0]         din,
  input logic                     we,
  input logic [(WIDTH-1)/8:0]     bwe,
  output logic [WIDTH-1:0]        dout);

  logic [WIDTH-1:0]               RAM[DEPTH-1:0];


  // ***************************************************************************
  // TRUE SRAM macro
  // ***************************************************************************
  if (`USE_SRAM == 1) begin
    genvar index;
    // 64 x 128-bit SRAM
    // check if the size is ok, complain if not***
    logic [WIDTH-1:0] BitWriteMask;
    for (index=0; index < WIDTH; index++) 
      assign BitWriteMask[index] = bwe[index/8];
    TS1N28HPCPSVTB64X128M4SW sram(
      .CLK(clk), .CEB(~ce), .WEB(~we),
      .A(addr), .D(din), 
      .BWEB(~BitWriteMask), .Q(dout));
    
  // ***************************************************************************
  // READ first SRAM model
  // ***************************************************************************
  end else begin
    integer index2;
    if (WIDTH%8 != 0) // handle msbs if not a multiple of 8
      always_ff @(posedge clk) 
        if (ce & we & bwe[WIDTH/8])
          RAM[addr][WIDTH-1:WIDTH-WIDTH%8] <= #1 din[WIDTH-1:WIDTH-WIDTH%8];
    
    always_ff @(posedge clk) begin
      if(ce) begin
        if(we) begin
          for(index2 = 0; index2 < WIDTH/8; index2++) 
            if(ce & we & bwe[index2])
		      RAM[addr][index2*8 +: 8] <= #1 din[index2*8 +: 8];
        end
        dout <= #1 RAM[addr];
      end
    end
  end    

endmodule

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

module sram1p1rw #(parameter DEPTH=128, WIDTH=256) (
  input logic                     clk,
  input logic [$clog2(DEPTH)-1:0] Adr,
  input logic [WIDTH-1:0]         CacheWriteData,
  input logic                     WriteEnable,
  input logic [(WIDTH-1)/8:0]     ByteMask,
  output logic [WIDTH-1:0]        ReadData);

  logic [WIDTH-1:0]               StoredData[DEPTH-1:0];
  logic [$clog2(DEPTH)-1:0]       AdrD;
  logic                           WriteEnableD;

  always_ff @(posedge clk)       AdrD <= Adr;

  integer                          index;
/* -----\/----- EXCLUDED -----\/-----
  for(index = 0; index < WIDTH/8; index++) begin
    always_ff @(posedge clk) begin
      if (WriteEnable & ByteMask[index]) begin
        StoredData[Adr][8*(index+1)-1:8*index] <= #1 CacheWriteData[8*(index+1)-1:8*index];
      end
    end
  end
 -----/\----- EXCLUDED -----/\----- */

  always_ff @(posedge clk) begin
    if (WriteEnable) begin
      for(index = 0; index < WIDTH/8; index++) begin
        if(ByteMask[index]) begin
        StoredData[Adr][index*8 +: 8] <= #1 CacheWriteData[index*8 +: 8];
        end
      end
    end
  end
  
  // if not a multiple of 8, MSByte is not 8 bits long.
  if(WIDTH%8 != 0) begin
    always_ff @(posedge clk) begin
      if (WriteEnable & ByteMask[WIDTH/8]) begin
        StoredData[Adr][WIDTH-1:WIDTH-WIDTH%8] <= #1 CacheWriteData[WIDTH-1:WIDTH-WIDTH%8];
      end
    end
  end

  assign ReadData = StoredData[AdrD];
endmodule



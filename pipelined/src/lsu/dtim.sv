///////////////////////////////////////////
// dtim.sv
//
// Written: Ross Thompson ross1728@gmail.com January 30, 2022
// Modified: 
//
// Purpose: simple memory with bus or cache.
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

`include "wally-config.vh"

module dtim(
  input logic               clk, reset, ce,
  input logic [1:0]         MemRWM,
  input logic [`PA_BITS-1:0]   Adr,
  input logic               TrapM, 
  input logic [`LLEN-1:0]   WriteDataM,
  input logic [`LLEN/8-1:0] ByteMaskM,
  output logic [`LLEN-1:0]  ReadDataWordM
);

  logic we;
 
  localparam ADDR_WDITH = $clog2(`DTIM_RANGE/8);
  localparam OFFSET = $clog2(`LLEN/8);

  assign we = MemRWM[0]  & ~TrapM;  // have to ignore write if Trap.

  sram1p1rw #(.DEPTH(`DTIM_RANGE/8), .WIDTH(`LLEN)) 
    ram(.clk, .ce, .we, .bwe(ByteMaskM), .addr(Adr[ADDR_WDITH+OFFSET-1:OFFSET]), .dout(ReadDataWordM), .din(WriteDataM));
endmodule  
  

///////////////////////////////////////////
// imem.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: 
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module imem (
  input  logic [`XLEN-1:1] AdrF,
  output logic [31:0]      InstrF,
  output logic [15:0]      rd2, // bogus, delete when real multicycle fetch works
  output logic             InstrAccessFaultF);

 /* verilator lint_off UNDRIVEN */
  logic [`XLEN-1:0] RAM[`TIMBASE>>(1+`XLEN/32):(`TIMRANGE+`TIMBASE)>>(1+`XLEN/32)];
  logic [`XLEN-1:0] bootram[`BOOTTIMBASE>>(1+`XLEN/32):(`BOOTTIMRANGE+`BOOTTIMBASE)>>(1+`XLEN/32)];
 /* verilator lint_on UNDRIVEN */
  logic [28:0] adrbits;
  logic [`XLEN-1:0] rd;
//  logic [15:0] rd2;
      
  generate
    if (`XLEN==32) assign adrbits = AdrF[30:2];
    else          assign adrbits = AdrF[31:3];
  endgenerate

  //assign #2 rd = RAM[adrbits]; // word aligned
  assign #2 rd = (AdrF < (`TIMBASE >> 1)) ? bootram[adrbits] : RAM[adrbits]; // busybear: 2 memory options

  // hack right now for unaligned 32-bit instructions
  // eventually this will need to cause a stall like a cache miss
  // when the instruction wraps around a cache line
  // could be optimized to only stall when the instruction wrapping is 32 bits
  //assign #2 rd2 = RAM[adrbits+1][15:0];
  assign #2 rd2 = (AdrF < (`TIMBASE >> 1)) ? bootram[adrbits+1][15:0] : RAM[adrbits+1][15:0]; //busybear: 2 memory options
  generate 
    if (`XLEN==32) begin
      assign InstrF = AdrF[1] ? {rd2[15:0], rd[31:16]} : rd;
      if(`TIMBASE==0) begin
        assign InstrAccessFaultF = 0;
      end else begin
        assign InstrAccessFaultF = ~AdrF[31] | (|AdrF[30:16]); // memory mapped to 0x80000000-0x8000FFFF
      end
    end else begin
      assign InstrF = AdrF[2] ? (AdrF[1] ? {rd2[15:0], rd[63:48]} : rd[63:32])
                          : (AdrF[1] ? rd[47:16] : rd[31:0]);
      /*if(`TIMBASE==0) begin
        assign InstrAccessFaultF = 0;
      end else begin
        assign InstrAccessFaultF = (|AdrF[`XLEN-1:32]) | ~AdrF[31] | (|AdrF[30:16]); // memory mapped to 0x80000000-0x8000FFFF]
      end*/
      assign InstrAccessFaultF = 0; //busybear: for now, i know we're not doing this
    end
  endgenerate
endmodule


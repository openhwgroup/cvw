///////////////////////////////////////////
// RASPredictor.sv
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 15, 2021
// Modified: 
//
// Purpose: 2 bit saturating counter predictor with parameterized table depth.
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

module RASPredictor
  #(parameter int StackSize = 16
    )
  (input logic              clk,
   input logic              reset,
   input logic              pop,
   output logic [`XLEN-1:0] popPC,
   input logic              push,
   input logic              incr,
   input logic [`XLEN-1:0]  pushPC
   );

  logic                     CounterEn;
  localparam Depth = $clog2(StackSize);

  logic [Depth-1:0]         PtrD, PtrQ, PtrP1, PtrM1;
  logic [StackSize-1:0]     [`XLEN-1:0] memory;
  integer        index;
  
  assign CounterEn = pop | push | incr;

  assign PtrD = pop ? PtrM1 : PtrP1;

  assign PtrM1 = PtrQ - 1'b1;
  assign PtrP1 = PtrQ + 1'b1;
  // may have to handle a push and an incr at the same time.
  // *** what happens if jal is executing and there is a return being flushed in Decode?

  flopenr #(Depth) PTR(.clk(clk),
      .reset(reset),
      .en(CounterEn),
      .d(PtrD),
      .q(PtrQ));

  // RAS must be reset. 
  always_ff @ (posedge clk) begin
    if(reset) begin
      for(index=0; index<StackSize; index++)
 memory[index] <= {`XLEN{1'b0}};
    end else if(push) begin
      memory[PtrP1] <= #1 pushPC;
    end
  end

  assign popPC = memory[PtrQ];
  
  
endmodule




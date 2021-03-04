///////////////////////////////////////////
// SRAM2P1R1W
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 15, 2021
// Modified: 
//
// Purpose: BTB model.  Outputs type of instruction (currently 1 hot encoded. Probably want 
// to encode to reduce storage), valid, target PC.
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

module BTBPredictor
  #(parameter int Depth = 10
    )
  (input  logic clk,
   input logic 		    reset,
   input logic [`XLEN-1:0]  LookUpPC,
   output logic [`XLEN-1:0] TargetPC,
   output logic [3:0] 	    InstrClass,
   output logic 	    Valid,
   // update
   input logic 		    UpdateEN,
   input logic [`XLEN-1:0]  UpdatePC,
   input logic [`XLEN-1:0]  UpdateTarget,
   input logic [3:0] 	    UpdateInstrClass
   );

  localparam TotalDepth = 2 ** Depth;
  logic [TotalDepth-1:0]    ValidBits;
  logic [Depth-1:0] 	    LookUpPCIndex, UpdatePCIndex, LookUpPCIndexQ, UpdatePCIndexQ;

  // hashing function for indexing the PC
  // We have Depth bits to index, but XLEN bits as the input.
  // bit 0 is always 0, bit 1 is 0 if using 4 byte instructions, but is not always 0 if
  // using compressed instructions.  XOR bit 1 with the MSB of index.
  assign UpdatePCIndex = {UpdatePC[Depth+1] ^ UpdatePC[1], UpdatePC[Depth:2]};
  assign LookUpPCIndex = {LookUpPC[Depth+1] ^ LookUpPC[1], LookUpPC[Depth:2]};  
  

  flopenr #(Depth) UpdatePCIndexReg(.clk(clk),
				    .reset(reset),
				    .en(1'b1),
				    .d(UpdatePCIndex),
				    .q(UpdatePCIndexQ));
  
  // The valid bit must be resetable.
  always_ff @ (posedge clk) begin
    if (reset) begin
      ValidBits <= #1 {TotalDepth{1'b0}};
    end else if (UpdateEN) begin
      ValidBits[UpdatePCIndexQ] <= #1 1'b1;
    end
  end

  flopenr #(Depth) LookupPCIndexReg(.clk(clk),
				    .reset(reset),
				    .en(1'b1),
				    .d(LookUpPCIndex),
				    .q(LookUpPCIndexQ));

  assign Valid = ValidBits[LookUpPCIndexQ];

  // the BTB contains the target address.
  // *** future version may contain the instruction class, a tag or partial tag,
  // and other indirection branch data.
  // Another optimization may be using a PC relative address.

  SRAM2P1R1W #(Depth, `XLEN+4) memory(.clk(clk),
				      .reset(reset),
				      .RA1(LookUpPCIndex),
				      .RD1({{InstrClass, TargetPC}}),
				      .REN1(1'b1),
				      .WA1(UpdatePCIndex),
				      .WD1({UpdateInstrClass, UpdateTarget}),
				      .WEN1(UpdateEN),
				      .BitWEN1({`XLEN{1'b1}}));


endmodule

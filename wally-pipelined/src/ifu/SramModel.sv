///////////////////////////////////////////
// SRAM2P1R1W
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 14, 2021
// Modified: 
//
// Purpose: Hacky two port SRAM model.
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

module SRAM2P1R1W
  #(parameter int Depth = 10,
    parameter int Width = 2
    ) 
  (input clk,
    
   // port 1 is read only
   input logic [Depth-1:0]  RA1,
   output logic [Width-1:0] RD1,
   input logic 		    REN1,
  
   // port 2 is write only
   input logic [Depth-1:0]  WA1,
   input logic [Width-1:0]  WD1,
   input logic 		    WEN1,
   input logic [Width-1:0]  BitWEN1
   );
  
  



  logic [Depth-1:0] 	    RA1Q, WA1Q;
  logic 		    WEN1Q;
  logic [Width-1:0] 	    WD1Q;

  logic [2**Depth-1:0] [Width-1:0] memory;
  
  
  // SRAMs address busses are always registered first.

  flopenr #(Depth) RA1Reg(.clk(clk),
			  .reset(1'b0),
			  .en(REN1),
			  .d(RA1),
			  .q(RA1Q));
  

  flopenr #(Depth) WA1Reg(.clk(clk),
			  .reset(1'b0),
			  .en(REN1),
			  .d(WA1),
			  .q(WA1Q));

  flopenr #(1) WEN1Reg(.clk(clk),
		       .reset(1'b0),
		       .en(1'b1),
		       .d(WEN1),
		       .q(WEN1Q));
  
  flopenr #(Width) WD1Reg(.clk(clk),
			  .reset(1'b0),
			  .en(REN1),
			  .d(WD1),
			  .q(WD1Q));
  // read port
  assign RD1 = memory[RA1Q];

  genvar 			   index;
  
  // write port
  generate
    for (index = 0; index < Width; index = index + 1) begin    
      always_ff @ (posedge clk) begin
	if (WEN1Q & BitWEN1[index]) begin
	  memory[WA1Q][index] = WD1Q[index];
	end
      end
    end
  endgenerate

endmodule  



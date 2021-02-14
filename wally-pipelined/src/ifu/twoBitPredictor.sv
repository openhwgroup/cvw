///////////////////////////////////////////
// twoBitPredictor.sv
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 14, 2021
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

module twoBitPredictor
  #(parameter int Depth = 10
    )
  (input clk,
   input [`XLEN-1:0] LookUpPC,
   output [1:0]      Prediction,
   // update
   input [`XLEN-1:0] UpdatePC,
   input 	     UpdateEN,
   input [1:0] 	     UpdatePrediction
   );

  SRAM2P1R1W #(Depth, 2) memory(.clk(clk),
				.RA1(LookUpPC),
				.RD1(PredictionMemory),
				.REN1(1'b1),
				.WA1(UpdatePC),
				.WD1(UpdatePrediction),
				.WEN1(UpdateEN));

  // need to forward when updating to the same address as reading.
  assign Prediction = (UpdatePC == LookUpPC) ? UpdatePrediction : PredictionMemory;
  
endmodule

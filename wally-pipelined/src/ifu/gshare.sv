///////////////////////////////////////////
// gshare.sv
//
// Written: Shreya Sanghai
// Email: ssanghai@hmc.edu
// Created: March 16, 2021
// Modified: 
//
// Purpose: Gshare predictor with parameterized global history register
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

module gsharePredictor
  #(parameter int k = 10
    )
  (input logic clk,
   input logic 		   reset,
   input logic 		    StallF, StallD, StallE, FlushF, FlushD, FlushE,
   input logic [`XLEN-1:0] LookUpPC,
   output logic [1:0] 	   Prediction,
   // update
   input logic [`XLEN-1:0] UpdatePC,
   input logic 		   UpdateEN, PCSrcE,
   input logic [1:0] 	   UpdatePrediction
   
   );
   localparam int Depth = 2^k;
   logic [k-1:0] GHRF, GHRD, GHRE;

    flopenr #(k) GlobalHistoryRegister(.clk(clk),
            .reset(reset),
            .en(UpdateEN),
            .d({PCSrcE, GHRF[k-1:1] }),
            .q(GHRF));


  logic [k-1:0] 	   LookUpPCIndex, UpdatePCIndex;
  logic [1:0] 		   PredictionMemory;
  logic 		   DoForwarding, DoForwardingF;
  logic [1:0] 		   UpdatePredictionF;
  
  // for gshare xor the PC with the GHR 
  assign UpdatePCIndex = GHRE ^ UpdatePC[k-1:0];
  assign LookUpPCIndex = LookUpPC ^ GHRF[k-1:0];  
  // Make Prediction by reading the correct address in the PHT and also update the new address in the PHT 
  // GHR referes to the address that the past k branches points to in the prediction stage 
  // GHRE refers to the address that the past k branches points to in the exectution stage
    SRAM2P1R1W #(Depth, 2) PHT(.clk(clk),
				.reset(reset),
				.RA1(LookUpPCIndex),
				.RD1(PredictionMemory),
				.REN1(1'b1),
				.WA1(UpdatePCIndex),
				.WD1(UpdatePrediction),
				.WEN1(UpdateEN),
				.BitWEN1(2'b11));


  // need to forward when updating to the same address as reading.
  // first we compare to see if the update and lookup addreses are the same
  assign DoForwarding = LookUpPCIndex == UpdatePCIndex;

  // register the update value and the forwarding signal into the Fetch stage
  // TODO: add stall logic ***
  flopr #(1) DoForwardingReg(.clk(clk),
			     .reset(reset),
			     .d(DoForwarding),
			     .q(DoForwardingF));
  
  flopr #(2) UpdatePredictionReg(.clk(clk),
				 .reset(reset),
				 .d(UpdatePrediction),
				 .q(UpdatePredictionF));

  assign Prediction = DoForwardingF ? UpdatePredictionF : PredictionMemory;
  
  //pipeline for GHR
  flopenrc #(k) LookUpDReg(.clk(clk),
      .reset(reset),
      .en(~StallD),
      .clear(FlushD),
      .d(LookUpPCIndex),
      .q(LookUpPCIndexD));

  flopenrc #(k) LookUpEReg(.clk(clk),
        .reset(reset),
        .en(~StallE),
        .clear(FlushE),
        .d(LookUpPCIndexD),
        .q(LookUpPCIndexE));

endmodule

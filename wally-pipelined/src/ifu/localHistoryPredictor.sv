///////////////////////////////////////////
// locallHistoryPredictor.sv
//
// Written: Shreya Sanghai
// Email: ssanghai@hmc.edu
// Created: March 16, 2021
// Modified: 
//
// Purpose: Global History Branch predictor with parameterized global history register
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

module localHistoryPredictor
  #(  parameter int m = 6, // 2^m = number of local history branches
      parameter int k = 10 // number of past branches stored
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

   logic [2**m-1:0][k-1:0] LHRNextF;
   logic [k-1:0]       LHRD, LHRE, LHRENext, ForwardLHRNext;
   logic [m-1:0] 	   LookUpPCIndex, UpdatePCIndex;
   logic [1:0] 		   PredictionMemory;
   logic 		   DoForwarding, DoForwardingF, DoForwardingPHT, DoForwardingPHTF;
   logic [1:0] 		   UpdatePredictionF;

   assign LHRENext = {PCSrcE, LHRE[k-1:1]}; 
   assign UpdatePCIndex = {UpdatePC[m+1] ^ UpdatePC[1], UpdatePC[m:2]};
   assign LookUpPCIndex = {LookUpPC[m+1] ^ LookUpPC[1], LookUpPC[m:2]};  

// INCASE we do ahead pipelining
//    SRAM2P1R1W #(m,k) LHR(.clk(clk)),
//                 .reset(reset),
//                 .RA1(LookUpPCIndex), // need hashing function to get correct PC address 
//                 .RD1(LHRF),
//                 .REN1(~StallF),
//                 .WA1(UpdatePCIndex),
//                 .WD1(LHRENExt),
//                 .WEN1(UpdateEN),
//                 .BitWEN1(2'b11));  

genvar index;
generate
    for (index = 0; index < 2**m; index = index +1) begin:index
      
        flopenr #(k) LocalHistoryRegister(.clk(clk),
                .reset(reset),
                .en(UpdateEN && (index == UpdatePCIndex)),
                .d(LHRENext),
                .q(LHRNextF[index]));
    end 
endgenerate

// need to forward when updating to the same address as reading.
// first we compare to see if the update and lookup addreses are the same
assign DoForwarding = LookUpPCIndex == UpdatePCIndex;
assign ForwardLHRNext = DoForwarding ? LHRENext :LHRNextF[LookUpPCIndex]; 

  // Make Prediction by reading the correct address in the PHT and also update the new address in the PHT 
  // LHR referes to the address that the past k branches points to in the prediction stage 
  // LHRE refers to the address that the past k branches points to in the exectution stage
    SRAM2P1R1W #(k, 2) PHT(.clk(clk), 
				.reset(reset),
				.RA1(ForwardLHRNext),
				.RD1(PredictionMemory),
				.REN1(~StallF),
				.WA1(LHRENext),
				.WD1(UpdatePrediction),
				.WEN1(UpdateEN),
				.BitWEN1(2'b11));


  
assign DoForwardingPHT = LHRENext == ForwardLHRNext; 

  // register the update value and the forwarding signal into the Fetch stage
  // TODO: add stall logic ***
  flopr #(1) DoForwardingReg(.clk(clk),
			     .reset(reset),
			     .d(DoForwardingPHT),
			     .q(DoForwardingPHTF));
  
  flopr #(2) UpdatePredictionReg(.clk(clk),
				 .reset(reset),
				 .d(UpdatePrediction),
				 .q(UpdatePredictionF));

  assign Prediction = DoForwardingPHTF ? UpdatePredictionF : PredictionMemory;
  
  //pipeline for LHR
  flopenrc #(k) LHRFReg(.clk(clk),
      .reset(reset),
      .en(~StallF),
      .clear(FlushF),
      .d(ForwardLHRNext),
      .q(LHRF));

  flopenrc #(k) LHRDReg(.clk(clk),
        .reset(reset),
        .en(~StallD),
        .clear(FlushD),
        .d(LHRF),
        .q(LHRD));
    
   flopenrc #(k) LHREReg(.clk(clk),
        .reset(reset),
        .en(~StallE),
        .clear(FlushE),
        .d(LHRD),
        .q(LHRE));

endmodule

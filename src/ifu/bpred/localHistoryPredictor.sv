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
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module localHistoryPredictor #(parameter m = 6,    // 2^m = number of local history branches
                                         k = 10) ( // number of past branches stored
  input  logic             clk,
  input  logic             reset,
  input  logic             StallF,  StallE,
  input  logic [`XLEN-1:0] LookUpPC,
  output logic [1:0]       Prediction,
  // update
  input logic [`XLEN-1:0]  UpdatePC,
  input logic              UpdateEN, PCSrcE, 
  input logic [1:0]        UpdatePrediction
);

  logic [2**m-1:0][k-1:0]  LHRNextF;
  logic [k-1:0]            LHRF, ForwardLHRNext, LHRFNext;
  logic [m-1:0]            LookUpPCIndex, UpdatePCIndex;
  logic [1:0]              PredictionMemory;
  logic                    DoForwarding, DoForwardingF, DoForwardingPHT, DoForwardingPHTF;
  logic [1:0]              UpdatePredictionF;

  assign LHRFNext = {PCSrcE, LHRF[k-1:1]}; 
  assign UpdatePCIndex = {UpdatePC[m+1] ^ UpdatePC[1], UpdatePC[m:2]};
  assign LookUpPCIndex = {LookUpPC[m+1] ^ LookUpPC[1], LookUpPC[m:2]};  

  // INCASE we do ahead pipelining
  //    ram2p1r1wb #(m,k) LHR(.clk(clk)),
  //                 .reset(reset),
  //                 .RA1(LookUpPCIndex), // need hashing function to get correct PC address 
  //                 .RD1(LHRF),
  //                 .REN1(~StallF),
  //                 .WA1(UpdatePCIndex),
  //                 .WD1(LHRENExt),
  //                 .WEN1(UpdateEN),
  //                 .BitWEN1(2'b11));  

  genvar      index;
  for (index = 0; index < 2**m; index = index +1) begin:localhist
    flopenr #(k) LocalHistoryRegister(.clk, .reset, .en(UpdateEN & (index == UpdatePCIndex)),
                                      .d(LHRFNext), .q(LHRNextF[index]));
  end 

  // need to forward when updating to the same address as reading.
  // first we compare to see if the update and lookup addreses are the same
  assign DoForwarding = LookUpPCIndex == UpdatePCIndex;
  assign ForwardLHRNext = DoForwarding ? LHRFNext :LHRNextF[LookUpPCIndex]; 

  // Make Prediction by reading the correct address in the PHT and also update the new address in the PHT 
  // LHR referes to the address that the past k branches points to in the prediction stage 
  // LHRE refers to the address that the past k branches points to in the exectution stage
  ram2p1r1wb #(k, 2) PHT(.clk(clk), 
    .reset(reset),
    .ra1(ForwardLHRNext),
    .rd1(PredictionMemory),
    .ren1(~StallF),
    .wa2(LHRFNext),
    .wd2(UpdatePrediction),
    .wen2(UpdateEN),
    .bwe2(2'b11));


  
  assign DoForwardingPHT = LHRFNext == ForwardLHRNext; 

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
   .clear(1'b0),
   .d(ForwardLHRNext),
   .q(LHRF));
  /*
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
   */
endmodule

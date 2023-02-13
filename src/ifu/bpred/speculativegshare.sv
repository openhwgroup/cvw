///////////////////////////////////////////
// gsharePredictor.sv
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

module speculativegshare #(parameter int k = 10 ) (
  input logic 			  clk,
  input logic 			  reset,
  input logic 			  StallF, StallD, StallE, StallM, StallW, 
  input logic 			  FlushD, FlushE, FlushM, FlushW,
  output logic [1:0] 	  DirPredictionF, 
  output logic 			  DirPredictionWrongE,
  // update
  input logic [`XLEN-1:0] PCNextF, PCF, PCD, PCE,
  input logic [3:0] 	  PredInstrClassF,
  input logic [3:0]       InstrClassD, InstrClassE, InstrClassM,
  input logic [3:0] 	  WrongPredInstrClassD, 
  input logic 			  PCSrcE
);

  logic                    MatchF, MatchD, MatchE;
  logic                    MatchNextX, MatchXF;

  logic [1:0]              TableDirPredictionF, DirPredictionD, DirPredictionE;
  logic [1:0]              NewDirPredictionE;

  logic [k-1:0] 		   GHRF, GHRD, GHRE, GHRM;
  logic 				   GHRLastF;
  logic [k-1:0] 		   GHRNextF, GHRNextD, GHRNextE, GHRNextM;
  logic [k-1:0]            IndexNextF, IndexF, IndexD, IndexE;
  logic [1:0]              ForwardNewDirPrediction, ForwardDirPredictionF;

  logic 				   FlushDOrDirWrong;
  
  assign IndexNextF = GHRNextF ^ {PCNextF[k+1] ^ PCNextF[1], PCNextF[k:2]};
  assign IndexF = GHRF        ^ {PCF[k+1] ^ PCF[1], PCF[k:2]};
  assign IndexD = GHRD[k-1:0] ^ {PCD[k+1] ^ PCD[1], PCD[k:2]};
  assign IndexE = GHRE[k-1:0] ^ {PCE[k+1] ^ PCE[1], PCE[k:2]};
      
  ram2p1r1wbe #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF | reset), .ce2(~StallM & ~FlushM),
    .ra1(IndexNextF),
    .rd1(TableDirPredictionF),
    .wa2(IndexE),
    .wd2(NewDirPredictionE),
    .we2(InstrClassE[0]),
    .bwe2(1'b1));

  // if there are non-flushed branches in the pipeline we need to forward the prediction from that stage to the NextF demi stage
  // and then register for use in the Fetch stage.
  assign MatchF = PredInstrClassF[0] & ~FlushD & (IndexNextF == IndexF);
  assign MatchD = InstrClassD[0] & ~FlushE & (IndexNextF == IndexD);
  assign MatchE = InstrClassE[0] & ~FlushM & (IndexNextF == IndexE);
  assign MatchNextX = MatchF | MatchD | MatchE;

  flopenr #(1) MatchReg(clk, reset, ~StallF, MatchNextX, MatchXF);

  assign ForwardNewDirPrediction = MatchF ? {2{DirPredictionF[1]}} :
                                   MatchD ? {2{DirPredictionD[1]}} :
                                   NewDirPredictionE ;
  
  flopenr #(2) ForwardDirPredicitonReg(clk, reset, ~StallF, ForwardNewDirPrediction, ForwardDirPredictionF);

  assign DirPredictionF = MatchXF ? ForwardDirPredictionF : TableDirPredictionF;

  // DirPrediction pipeline
  flopenr #(2) PredictionRegD(clk, reset, ~StallD, DirPredictionF, DirPredictionD);
  flopenr #(2) PredictionRegE(clk, reset, ~StallE, DirPredictionD, DirPredictionE);

  
  satCounter2 BPDirUpdateE(.BrDir(PCSrcE), .OldState(DirPredictionE), .NewState(NewDirPredictionE));

  // GHR pipeline

  // If Fetch has a branch, speculatively insert prediction into the GHR
  // If the front end is flushed or the direction prediction is wrong, reset to
  // most recent valid GHR.  For a BP wrong this is GHRD with the correct prediction shifted in.
  // For FlushE this is GHRE.  GHRNextE is both.
  assign FlushDOrDirWrong = FlushD | DirPredictionWrongE;
  mux3 #(k) GHRFMux(GHRF, {DirPredictionF[1], GHRF[k-1:1]}, GHRNextE[k-1:0], 
					{FlushDOrDirWrong, PredInstrClassF[0]}, GHRNextF);

  // Need 1 extra bit to store the shifted out GHRF if repair needs to back shift.
  flopenr  #(k) GHRFReg(clk, reset, ~StallF | FlushDOrDirWrong, GHRNextF, GHRF);	
  flopenr  #(1) GHRFLastReg(clk, reset, ~StallF | FlushDOrDirWrong, GHRF[0], GHRLastF);

  // With instruction class prediction, the class could be wrong and is checked in Decode.
  // If it is wrong and branch does exist then shift right and insert the prediction.
  // If the branch does not exist then shift left and use GHRLastF to restore the LSB.
  logic [k-1:0] 		   GHRClassWrong;
  mux2 #(k) GHRClassWrongMux({DirPredictionD[1], GHRF[k-1:1]}, {GHRF[k-2:0], GHRLastF}, ~InstrClassD[0], GHRClassWrong);
  // As with GHRF FlushD and wrong direction prediction flushes the pipeline and restores to GHRNextE.
  mux3 #(k) GHRDMux(GHRF, GHRClassWrong, GHRNextE, {FlushDOrDirWrong, WrongPredInstrClassD[0]}, GHRNextD);

  flopenr  #(k) GHRDReg(clk, reset, ~StallD | FlushDOrDirWrong, GHRNextD, GHRD);

  mux3 #(k) GHREMux(GHRD, GHRNextM, {PCSrcE, GHRD[k-2:0]}, {InstrClassE[0] & ~FlushM, FlushE}, GHRNextE);

  flopenr  #(k) GHREReg(clk, reset, (~StallE) | FlushE, GHRNextE, GHRE);

  assign GHRNextM = FlushM ? GHRM : GHRE;
  flopenr  #(k) GHRMReg(clk, reset, (InstrClassM[0] & ~StallM) | FlushM, GHRNextM, GHRM);
  
  assign DirPredictionWrongE = PCSrcE != DirPredictionE[1] & InstrClassE[0];

endmodule

///////////////////////////////////////////
// globalHistoryPredictor.sv
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

module speculativeglobalhistory #(parameter k = 10) (
  input logic             clk,
  input logic             reset,
  input logic             StallF, StallD, StallE, StallM, StallW, 
  input logic             FlushD, FlushE, FlushM, FlushW,
  output logic [1:0]      DirPredictionF, 
  output logic            DirPredictionWrongE,
  // update
  input logic [`XLEN-1:0] PCNextF, PCF, PCD, PCE, PCM,
  input logic             BranchInstrF, BranchInstrD, BranchInstrE, BranchInstrM, BranchInstrW,
  input logic [3:0]       WrongPredInstrClassD, 
  input logic             PCSrcE
);

  logic                    MatchF, MatchD, MatchE;
  logic                    MatchNextX, MatchXF;

  logic [1:0]              TableDirPredictionF, DirPredictionD, DirPredictionE;
  logic [1:0]              NewDirPredictionF, NewDirPredictionD, NewDirPredictionE;

  logic [k-1:0]            GHRF;
  logic [k:0]              GHRD, OldGHRE, GHRE, GHRM, GHRW;
  logic [k-1:0]            GHRNextF;
  logic [k:-1] 			   GHRNextD, OldGHRD;
  logic [k:0]              GHRNextE, GHRNextM, GHRNextW;
  logic [k-1:0]            IndexNextF, IndexF;
  logic [k-1:0]            IndexD, IndexE;
  
  logic [`XLEN-1:0]        PCW;

  logic [1:0]              ForwardNewDirPrediction, ForwardDirPredictionF;
  
  assign IndexNextF = GHRNextF;
  assign IndexF = GHRF;
  assign IndexD = GHRD[k-1:0];
  assign IndexE = GHRE[k-1:0];
      
  ram2p1r1wbe #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF | reset), .ce2(~StallM & ~FlushM),
    .ra1(IndexNextF),
    .rd1(TableDirPredictionF),
    .wa2(IndexE),
    .wd2(NewDirPredictionE),
    .we2(BranchInstrE & ~StallM & ~FlushM),
    .bwe2(1'b1));

  // if there are non-flushed branches in the pipeline we need to forward the prediction from that stage to the NextF demi stage
  // and then register for use in the Fetch stage.
  assign MatchF = BranchInstrF & ~FlushD & (IndexNextF == IndexF);
  assign MatchD = BranchInstrD & ~FlushE & (IndexNextF == IndexD);
  assign MatchE = BranchInstrE & ~FlushM & (IndexNextF == IndexE);
  assign MatchNextX = MatchF | MatchD | MatchE;

  flopenr #(1) MatchReg(clk, reset, ~StallF, MatchNextX, MatchXF);

  assign ForwardNewDirPrediction = MatchF ? NewDirPredictionF :
                                   MatchD ? NewDirPredictionD :
                                   NewDirPredictionE ;
  
  flopenr #(2) ForwardDirPredicitonReg(clk, reset, ~StallF, ForwardNewDirPrediction, ForwardDirPredictionF);

  assign DirPredictionF = MatchXF ? ForwardDirPredictionF : TableDirPredictionF;

  // DirPrediction pipeline
  flopenr #(2) PredictionRegD(clk, reset, ~StallD, DirPredictionF, DirPredictionD);
  flopenr #(2) PredictionRegE(clk, reset, ~StallE, DirPredictionD, DirPredictionE);

  // New prediction pipeline
  assign NewDirPredictionF = {DirPredictionF[1], DirPredictionF[1]};
  
  flopenr #(2) NewPredDReg(clk, reset, ~StallD, NewDirPredictionF, NewDirPredictionD);
  satCounter2 BPDirUpdateE(.BrDir(PCSrcE), .OldState(DirPredictionE), .NewState(NewDirPredictionE));

  // GHR pipeline
  assign GHRNextF = FlushD ?  GHRNextD[k:1] :
                    BranchInstrF ? {DirPredictionF[1], GHRF[k-1:1]} :
                    GHRF;

  flopenr  #(k) GHRFReg(clk, reset, (~StallF) | FlushD, GHRNextF, GHRF);
  
  assign GHRNextD = FlushD ? {GHRNextE, GHRNextE[0]} : {DirPredictionF[1], GHRF, GHRF[0]};
  flopenr  #(k+2) GHRDReg(clk, reset, (~StallD) | FlushD, GHRNextD, OldGHRD);
  assign GHRD = WrongPredInstrClassD[0] & BranchInstrD  ? {DirPredictionD[1], OldGHRD[k:1]} : // shift right
				WrongPredInstrClassD[0] & ~BranchInstrD ? OldGHRD[k-1:-1] : // shift left
				OldGHRD[k:0];

  assign GHRNextE = FlushE ? GHRNextM : GHRD;
  flopenr  #(k+1) GHREReg(clk, reset, (~StallE) | FlushE, GHRNextE, OldGHRE);
  assign GHRE = BranchInstrE ? {PCSrcE, OldGHRE[k-1:0]} : OldGHRE;

  assign GHRNextM = FlushM ? GHRNextW : GHRE;
  flopenr  #(k+1) GHRMReg(clk, reset, (~StallM) | FlushM, GHRNextM, GHRM);

  assign GHRNextW = FlushW ? GHRW : GHRM;
  flopenr  #(k+1) GHRWReg(clk, reset, (BranchInstrM & ~StallW) | FlushW, GHRNextW, GHRW);
  
  assign DirPredictionWrongE = PCSrcE != DirPredictionE[1] & BranchInstrE;

  flopenr #(`XLEN) PCWReg(clk, reset, ~StallW, PCM, PCW);

endmodule

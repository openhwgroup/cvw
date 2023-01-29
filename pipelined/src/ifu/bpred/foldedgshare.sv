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

module foldedgshare #(parameter k = 16, depth = 10) (
  input logic             clk,
  input logic             reset,
  input logic             StallF, StallD, StallE, StallM, StallW, 
  input logic             FlushD, FlushE, FlushM, FlushW,
//   input logic [`XLEN-1:0] LookUpPC,
  output logic [1:0]      DirPredictionF, 
  output logic            DirPredictionWrongE,
  // update
  input logic [`XLEN-1:0] PCNextF, PCF, PCD, PCE, PCM,
  input logic             BranchInstrF, BranchInstrD, BranchInstrE, BranchInstrM, BranchInstrW, 
  input logic             PCSrcE
);

  logic                    MatchF, MatchD, MatchE, MatchM, MatchW;
  logic                    MatchNextX, MatchXF;

  logic [1:0]              TableDirPredictionF, DirPredictionD, DirPredictionE;
  logic [1:0]              NewDirPredictionF, NewDirPredictionD, NewDirPredictionE, NewDirPredictionM, NewDirPredictionW;

  logic [k-1:0]            GHRF;
  logic [k:0]              GHRD, OldGHRE, GHRE, GHRM, GHRW;
  logic [k-1:0]            GHRNextF;
  logic [k:0]              GHRNextD, GHRNextE, GHRNextM, GHRNextW;
  logic [k-1:0]            IndexNextF, IndexF;
  logic [k-1:0]            IndexD, IndexE, IndexM, IndexW;
  logic [depth-1:0] 	     FinalIndexNextF, FinalIndexW;
  
  logic                    PCSrcM, PCSrcW;
  logic [`XLEN-1:0]        PCW;

  logic [1:0]              ForwardNewDirPrediction, ForwardDirPredictionF;
  localparam        		   delta = 2 * depth - k;
  
  assign IndexNextF = GHRNextF ^ {PCNextF[k+1] ^ PCNextF[1], PCNextF[k:2]};
  assign IndexF = GHRF        ^ {PCF[k+1] ^ PCF[1], PCF[k:2]};
  assign IndexD = GHRD[k-1:0] ^ {PCD[k+1] ^ PCD[1], PCD[k:2]};
  assign IndexE = GHRE[k-1:0] ^ {PCE[k+1] ^ PCE[1], PCE[k:2]};
  assign IndexM = GHRM[k-1:0] ^ {PCM[k+1] ^ PCM[1], PCM[k:2]};
  assign IndexW = GHRW[k-1:0] ^ {PCW[k+1] ^ PCW[1], PCW[k:2]};

  // just be dumb for now.
  //localparam int kToDepthRatio = (k+depth) / depth;
  assign FinalIndexNextF = IndexNextF[depth-1:0] ^ {{delta{1'b0}} , IndexNextF[k-1:depth]};
  assign FinalIndexW = IndexW[depth-1:0] ^ {{delta{1'b0}} , IndexW[k-1:depth]};
        
  ram2p1r1wbe #(2**depth, 2) PHT(.clk(clk),
    .ce1(~StallF | reset), .ce2(~StallW & ~FlushW),
    .ra1(FinalIndexNextF),
    .rd1(TableDirPredictionF),
    .wa2(FinalIndexW),
    .wd2(NewDirPredictionW),
    .we2(BranchInstrW & ~StallW & ~FlushW),
    .bwe2(1'b1));

  // if there are non-flushed branches in the pipeline we need to forward the prediction from that stage to the NextF demi stage
  //  and then register for use in the Fetch stage.
  assign MatchF = BranchInstrF & ~FlushD & (IndexNextF == IndexF);
  assign MatchD = BranchInstrD & ~FlushE & (IndexNextF == IndexD);
  assign MatchE = BranchInstrE & ~FlushM & (IndexNextF == IndexE);
  assign MatchM = BranchInstrM & ~FlushW & (IndexNextF == IndexM);
  assign MatchW = BranchInstrW & (IndexNextF == IndexW);
  assign MatchNextX = MatchF | MatchD | MatchE | MatchM | MatchW;

  flopenr #(1) MatchReg(clk, reset, ~StallF, MatchNextX, MatchXF);

  assign ForwardNewDirPrediction = MatchF ? NewDirPredictionF :
                                   MatchD ? NewDirPredictionD :
                                   MatchE ? NewDirPredictionE :
                                   MatchM ? NewDirPredictionM :
                                   NewDirPredictionW;

  flopenr #(2) ForwardDirPredicitonReg(clk, reset, ~StallF, ForwardNewDirPrediction, ForwardDirPredictionF);

  assign DirPredictionF = MatchXF ? ForwardDirPredictionF : TableDirPredictionF;

  // DirPrediction pipeline
  flopenr #(2) PredictionRegD(clk, reset, ~StallD, DirPredictionF, DirPredictionD);
  flopenr #(2) PredictionRegE(clk, reset, ~StallE, DirPredictionD, DirPredictionE);

  // New prediction pipeline
  satCounter2 BPDirUpdateF(.BrDir(DirPredictionF[1]), .OldState(DirPredictionF), .NewState(NewDirPredictionF));
  flopenr #(2) NewPredDReg(clk, reset, ~StallD, NewDirPredictionF, NewDirPredictionD);
  satCounter2 BPDirUpdateE(.BrDir(PCSrcE), .OldState(DirPredictionE), .NewState(NewDirPredictionE));
  flopenr #(2) NewPredMReg(clk, reset, ~StallM, NewDirPredictionE, NewDirPredictionM);
  flopenr #(2) NewPredWReg(clk, reset, ~StallW, NewDirPredictionM, NewDirPredictionW);

  // PCSrc pipeline
  flopenrc #(1) PCSrcMReg(clk, reset, FlushM, ~StallM, PCSrcE, PCSrcM);
  flopenrc #(1) PCSrcWReg(clk, reset, FlushW, ~StallW, PCSrcM, PCSrcW);
  
  // GHR pipeline
  assign GHRNextF = FlushD ?  GHRNextD[k:1] :
                    BranchInstrF ? {DirPredictionF[1], GHRF[k-1:1]} :
                    GHRF;

  flopenr  #(k) GHRFReg(clk, reset, (~StallF) | FlushD, GHRNextF, GHRF);
  
  assign GHRNextD = FlushD ? GHRNextE : {DirPredictionF[1], GHRF};
  flopenr  #(k+1) GHRDReg(clk, reset, (~StallD) | FlushD, GHRNextD, GHRD);

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

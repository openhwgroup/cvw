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
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
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

module optgshare #(parameter k = 10) (
  input  logic             clk,
  input  logic             reset,
  input  logic             StallF, StallD, StallE, StallM, StallW, 
  input  logic             FlushD, FlushE, FlushM, FlushW,
//   input logic [`XLEN-1:0] LookUpPC,
  output logic [1:0]       DirPredictionF, 
  output logic             DirPredictionWrongE,
  // update
  input  logic [`XLEN-1:0] PCNextF, PCF, PCD, PCE, PCM,
  input  logic             BranchInstrF, BranchInstrD, BranchInstrE, BranchInstrM, BranchInstrW, 
  input  logic             PCSrcE
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
  
  logic                    PCSrcM, PCSrcW;
  logic [`XLEN-1:0]        PCW;

  logic [1:0]              ForwardNewDirPrediction, ForwardDirPredictionF;

  logic [k+4:0]            GHRNext, GHR;
  logic                    GHRUpdateEn;
  
  assign GHRUpdateEn = BranchInstrF | (DirPredictionWrongE & BranchInstrE) |
                       FlushD | FlushE | FlushM | FlushW;

  // it doesn't work this way.  Instead we need to see how many branch instructions are flushed.
  // then shift over by that amount.
  logic                    RemoveBrW, RemoveBrM, RemoveBrE, RemoveBrD, RemoveBrF, RemoveBrNextF;
  
  assign RemoveBrW = '0;
  assign RemoveBrM = BranchInstrM & FlushW;
  assign RemoveBrE = BranchInstrE & FlushM;
  assign RemoveBrD = BranchInstrD & FlushE;
  assign RemoveBrF = BranchInstrF & FlushD;
  assign RemoveBrNextF = BranchInstrF & FlushD;
  
  always_comb begin
    casez ({BranchInstrF, DirPredictionWrongE, RemoveBrF, RemoveBrD, RemoveBrE, RemoveBrM}) 
      6'b00_0000: GHRNext = GHR;  // no change
      6'b00_0001: GHRNext = {GHR[k+4:k+1], GHR[k-1:0], 1'b0}; // RemoveBrM
      6'b0?_0010: GHRNext = {GHR[k+4:k+2], GHR[k:0], 1'b0};   // RemoveBrE
      6'b0?_0011: GHRNext = {GHR[k+4:k+2], GHR[k-1:0], 2'b0};   // RemoveBrE, RemoveBrM

      6'b00_0100: GHRNext = {GHR[k+4:k+2], GHR[k-1:0], 2'b0}; // RemoveBrD
      6'b00_0101: GHRNext = {GHR[k+4:k+3], GHR[k+1:0], 1'b0}; // RemoveBrD, RemoveBrM
      6'b0?_0110: GHRNext = {GHR[k+4:k+3], GHR[k+1], GHR[k-1:0], 2'b0}; // RemoveBrD, RemoveBrE
      6'b0?_0111: GHRNext = {GHR[k+4:k+3], GHR[k-1:0], 3'b0}; // RemoveBrD, RemoveBrE, RemoveBrM

      6'b?0_1000: GHRNext = {GHR[k+2:0],   2'b0}; // RemoveBrF, 
      6'b?0_1001: GHRNext = {GHR[k+2:k+1], GHR[k-1:0],  3'b0}; // RemoveBrF, RemoveBrM
      6'b??_1010: GHRNext = {GHR[k+2], GHR[k:0],  3'b0}; // RemoveBrF, RemoveBrE
      6'b??_1011: GHRNext = {GHR[k+2], GHR[k-1:0],  4'b0}; // RemoveBrF, RemoveBrE, RemoveBrM

      6'b?0_1100: GHRNext = {GHR[k+1:0],  3'b0}; // RemoveBrF, RemoveBrD
      6'b?0_1101: GHRNext = {GHR[k+1], GHR[k-1:0], 4'b0}; // RemoveBrF, RemoveBrD, RemoveBrM
      6'b??_1110: GHRNext = {GHR[k:0], 4'b0}; // RemoveBrF, RemoveBrD, RemoveBrE
      6'b??_1111: GHRNext = {GHR[k-1:0], 5'b0}; // RemoveBrF, RemoveBrD, RemoveBrE, RemoveBrM

      6'b?1_0000: GHRNext = {PCSrcE, GHR[k+3:0]}; // Miss prediction, no branches to flushes
      6'b?1_0001: GHRNext = {PCSrcE, GHR[k+3:k], GHR[k-1:1], 1'b0}; // Miss prediction, branch in Memory stage dropped

      6'b?1_1100: GHRNext = {PCSrcE, GHR[k+1:0], 2'b00}; // Miss prediction, cannot have RemoveBrE
      6'b?1_1101: GHRNext = {PCSrcE, GHR[k+1], GHR[k-1:0], 3'b0}; // Miss prediction, cannot have RemoveBrE
      6'b10_0000: GHRNext = {DirPredictionF[1], GHR[k+4:1]};
      6'b10_0001: GHRNext = {DirPredictionF[1], GHR[k+4:k+1], GHR[k-1:1], 1'b0};
      6'b10_0010: GHRNext = {DirPredictionF[1], GHR[k+4:k+2], GHR[k:1], 1'b0};
      6'b10_0011: GHRNext = {DirPredictionF[1], GHR[k+4:k+2], GHR[k-1:1], 2'b0};
      6'b10_0100: GHRNext = {DirPredictionF[1], GHR[k+4:k+3], GHR[k+1:1], 1'b0};
      6'b10_0101: GHRNext = {DirPredictionF[1], GHR[k+4:k+3], GHR[k+1], GHR[k-1:1], 2'b0};
      6'b10_0110: GHRNext = {DirPredictionF[1], GHR[k+4:k+3], GHR[k], GHR[k-1:1], 2'b0};
      6'b10_0111: GHRNext = {DirPredictionF[1], GHR[k+4:k+3], GHR[k-1:1], 3'b0};
      
      default: GHRNext = GHR;
    endcase
  end

  flopenr  #(k+5) GHRReg(clk, reset, GHRUpdateEn,  GHRNext, GHR);
  logic [k-1:0] GHRNextF_temp, GHRF_temp;
  logic [k:0]   GHRD_temp, GHRE_temp, GHRM_temp, GHRW_temp;
  logic         GHRFExtra_temp;

  // these are also in the ieu controller.  should create inputs.
  logic         InstrValidF, InstrValidD, InstrValidE, InstrValidM, InstrValidW;
  flopenrc #(1)  InstrValidFReg(clk, reset, FlushD, ~StallF, 1'b1, InstrValidF);
  flopenrc #(1)  InstrValidDReg(clk, reset, FlushD, ~StallD, InstrValidF, InstrValidD);
  flopenrc #(1)  InstrValidEReg(clk, reset, FlushE, ~StallE, InstrValidD, InstrValidE);
  flopenrc #(1)  InstrValidMReg(clk, reset, FlushM, ~StallM, InstrValidE, InstrValidM);
  flopenrc #(1)  InstrValidWReg(clk, reset, FlushW, ~StallW, InstrValidM, InstrValidW);

  
  assign GHRNextF_temp = GHRNext[k+4:5];
  assign GHRF_temp = InstrValidF ? GHR[k+3:4] : GHRNextF_temp;
  assign GHRFExtra_temp = InstrValidF ? 1'b0 : GHR[k+4];
  assign GHRD_temp = InstrValidD ? GHR[k+3:3] : {GHRFExtra_temp, GHRF_temp};
  assign GHRE_temp = InstrValidE ?  GHR[k+2:2] : GHRD_temp;
  assign GHRM_temp = InstrValidM ? GHR[k+1:1] : GHRE_temp;
  assign GHRW_temp = InstrValidW ? GHR[k:0] : GHRM_temp;
  
  
  assign IndexNextF = GHRNextF ^ {PCNextF[k+1] ^ PCNextF[1], PCNextF[k:2]};
  assign IndexF = GHRF        ^ {PCF[k+1] ^ PCF[1], PCF[k:2]};
  assign IndexD = GHRD[k-1:0] ^ {PCD[k+1] ^ PCD[1], PCD[k:2]};
  assign IndexE = GHRE[k-1:0] ^ {PCE[k+1] ^ PCE[1], PCE[k:2]};
  assign IndexM = GHRM[k-1:0] ^ {PCM[k+1] ^ PCM[1], PCM[k:2]};
  assign IndexW = GHRW[k-1:0] ^ {PCW[k+1] ^ PCW[1], PCW[k:2]};
      
  ram2p1r1wbe #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF | reset), .ce2(~StallW & ~FlushW),
    .ra1(IndexNextF),
    .rd1(TableDirPredictionF),
    .wa2(IndexW),
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

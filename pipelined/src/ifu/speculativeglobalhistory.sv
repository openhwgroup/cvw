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
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module speculativeglobalhistory
  #(parameter int k = 10
    )
  (input logic             clk,
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
  logic                    PCSrcM, PCSrcW;
  logic [`XLEN-1:0]        PCW;

  logic [1:0]              ForwardNewDirPrediction, ForwardDirPredictionF;
  
      
  ram2p1r1wbefix #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF | reset), .ce2(~StallW & ~FlushW),
    .ra1(GHRNextF),
    .rd1(TableDirPredictionF),
    .wa2(GHRW[k-1:0]),
    .wd2(NewDirPredictionW),
    .we2(BranchInstrW & ~StallW & ~FlushW),
    .bwe2(1'b1));

  // if there are non-flushed branches in the pipeline we need to forward the prediction from that stage to the NextF demi stage
  //  and then register for use in the Fetch stage.
  assign MatchF = BranchInstrF & ~FlushD & (GHRNextF == GHRF);
  assign MatchD = BranchInstrD & ~FlushE & (GHRNextF == GHRD[k-1:0]);
  assign MatchE = BranchInstrE & ~FlushM & (GHRNextF == GHRE[k-1:0]);
  assign MatchM = BranchInstrM & ~FlushW & (GHRNextF == GHRM[k-1:0]);
  assign MatchW = BranchInstrW & (GHRNextF == GHRM[k-1:0]);
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

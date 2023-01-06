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

  logic                    MatchD, MatchE, MatchM, MatchW, MatchX, MatchXF;
//  logic [k-1:0]            IndexNextF, IndexF, IndexD, IndexE, IndexM, IndexW;
  logic [1:0]              TableDirPredictionF, DirPredictionD, DirPredictionE;
  logic [1:0]              NewDirPredictionF, NewDirPredictionD, NewDirPredictionE, NewDirPredictionM, NewDirPredictionW, NewDirPredictionX, NewDirPredictionXF;

  logic [k-1:0]            GHRF, GHRD, GHRE, GHRM, GHRW, GHRNextF, GHRCurrentF, GHRCurrentE;
  logic [k-1:0]            NewGHRF, NewGHRD, NewGHRE, NewGHRM, NewGHRW;
  logic                    PCSrcM, PCSrcW;
  logic [`XLEN-1:0]        PCW;
      
  ram2p1r1wbefix #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF | reset), .ce2(~StallM & ~FlushM),
    .ra1(NewGHRF),
    .rd1(TableDirPredictionF),
    .wa2(GHRM),
    .wd2(NewDirPredictionM),
    .we2(BranchInstrM & ~StallM & ~FlushM),
    .bwe2(1'b1));

  // if there are non-flushed branches in the pipeline we need to forward the prediction from that stage to the demi stage NextF and then
  // register for use in the Fetch stage.
  assign MatchD = BranchInstrD & (GHRD == GHRF);
  assign MatchE = BranchInstrE & (GHRE == GHRF);
  assign MatchM = BranchInstrM & (GHRM == GHRF);
  assign MatchW = BranchInstrW & (GHRW == GHRF);
  assign MatchX = MatchD | MatchE | MatchM | MatchW;
  
  assign NewDirPredictionX = MatchD ? NewDirPredictionD :
                          MatchE ? NewDirPredictionE :
                          MatchM ? NewDirPredictionM :
                          MatchW ? NewDirPredictionW : '0;
  flopenr #(2) NewPredXReg(clk, reset, ~StallF, NewDirPredictionX, NewDirPredictionXF);
  flopenrc #(1) DoForwardReg(clk, reset, FlushD, ~StallF, MatchX, MatchXF);
  
  assign DirPredictionF = MatchXF ? NewDirPredictionXF : TableDirPredictionF;

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
  assign GHRNextF = FlushD & BranchInstrD & ~FlushE & ~FlushM & ~FlushW ? NewGHRD :
                    FlushE & BranchInstrE & ~FlushM & ~FlushW ? NewGHRE :
                    FlushM & BranchInstrM & ~FlushW ? NewGHRM :
                    FlushW & BranchInstrW ? NewGHRW :
                    NewGHRF;
  
  flopenr  #(k) GHRFReg(clk, reset, ~StallF, GHRNextF, GHRF);
  //assign GHRF = BranchInstrF ? {NewDirPredictionF[1], GHRCurrentF[k-1:1]} : GHRCurrentF;
  assign NewGHRF = BranchInstrF ? {NewDirPredictionF[1], GHRF[k-1:1]} : GHRF;
  flopenr  #(k) GHRDReg(clk, reset, ~StallD, GHRF, GHRD);
  assign NewGHRD = BranchInstrD ? {NewDirPredictionD[1], GHRD[k-1:1]} : GHRD;
  flopenr  #(k) GHREReg(clk, reset, ~StallE, GHRD, GHRE);
  assign NewGHRE = BranchInstrE ? {PCSrcE, GHRE[k-1:1]} : GHRE;
  flopenr  #(k) GHRMReg(clk, reset, ~StallM, GHRE, GHRM);
  assign NewGHRM = BranchInstrM ? {PCSrcM, GHRM[k-1:1]} : GHRM;
  flopenr  #(k) GHRWReg(clk, reset, ~StallW, GHRM, GHRW);
  assign NewGHRW = BranchInstrW ? {PCSrcW, GHRW[k-1:1]} : GHRW;

  
  assign DirPredictionWrongE = PCSrcE != DirPredictionE[1] & BranchInstrE;

  flopenr #(`XLEN) PCWReg(clk, reset, ~StallW, PCM, PCW);

endmodule

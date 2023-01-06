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

module gshare
  #(parameter int k = 10
    )
  (input logic             clk,
   input logic             reset,
   input logic             StallF, StallD, StallE, StallM, 
   input logic             FlushD, FlushE, FlushM,
//   input logic [`XLEN-1:0] LookUpPC,
   output logic [1:0]      DirPredictionF, 
   output logic            DirPredictionWrongE,
   // update
   input logic [`XLEN-1:0] PCNextF, PCM,
   input logic             BranchInstrE, BranchInstrM, PCSrcE
   );

  logic [k-1:0]            IndexNextF, IndexM;
  logic [1:0]              DirPredictionD, DirPredictionE;
  logic [1:0]              NewDirPredictionE, NewDirPredictionM;

  logic [k-1:0]            GHRF, GHRD, GHRE, GHRM, GHR;
  logic [k-1:0]            GHRNext;
  logic                    PCSrcM;

  assign IndexNextF = GHR & {PCNextF[k+1] ^ PCNextF[1], PCNextF[k:2]};
  assign IndexM = GHRM & {PCM[k+1] ^ PCM[1], PCM[k:2]};
  
  ram2p1r1wbefix #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF), .ce2(~StallM & ~FlushM),
    .ra1(IndexNextF),
    .rd1(DirPredictionF),
    .wa2(IndexM),
    .wd2(NewDirPredictionM),
    .we2(BranchInstrM & ~StallM & ~FlushM),
    .bwe2(1'b1));

  flopenrc #(2) PredictionRegD(clk, reset,  FlushD, ~StallD, DirPredictionF, DirPredictionD);
  flopenrc #(2) PredictionRegE(clk, reset,  FlushE, ~StallE, DirPredictionD, DirPredictionE);

  satCounter2 BPDirUpdateE(.BrDir(PCSrcE), .OldState(DirPredictionE), .NewState(NewDirPredictionE));
  flopenrc #(2) NewPredictionRegM(clk, reset,  FlushM, ~StallM, NewDirPredictionE, NewDirPredictionM);

  assign DirPredictionWrongE = PCSrcE != DirPredictionE[1] & BranchInstrE;

  assign GHRNext = BranchInstrM ? {PCSrcM, GHR[k-1:1]} : GHR;
  flopenr #(k) GHRReg(clk, reset, ~StallM & ~FlushM & BranchInstrM, GHRNext, GHR);
  flopenrc #(1) PCSrcMReg(clk, reset, FlushM, ~StallM, PCSrcE, PCSrcM);
    
  flopenrc #(k) GHRFReg(clk, reset, FlushD, ~StallF, GHR, GHRF);
  flopenrc #(k) GHRDReg(clk, reset, FlushD, ~StallD, GHRF, GHRD);
  flopenrc #(k) GHREReg(clk, reset, FlushE, ~StallE, GHRD, GHRE);
  flopenrc #(k) GHRMReg(clk, reset, FlushM, ~StallM, GHRE, GHRM);


endmodule

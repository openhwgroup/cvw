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

module gshare #(parameter k = 10) (
  input logic             clk,
  input logic             reset,
  input logic             StallF, StallD, StallE, StallM, 
  input logic             FlushD, FlushE, FlushM,
  output logic [1:0]      DirPredictionF, 
  output logic            DirPredictionWrongE,
  // update
  input logic [`XLEN-1:0] PCNextF, PCE,
  input logic             BranchInstrE, BranchInstrM, PCSrcE
);

  logic [k-1:0]            IndexNextF, IndexE;
  logic [1:0]              DirPredictionD, DirPredictionE;
  logic [1:0]              NewDirPredictionE, NewDirPredictionM;

  logic [k-1:0]            GHRF, GHRD, GHRE, GHR;
  logic [k-1:0]            GHRNext;
  logic                    PCSrcM;

  assign IndexNextF = GHR & {PCNextF[k+1] ^ PCNextF[1], PCNextF[k:2]};
  assign IndexE = GHRE & {PCE[k+1] ^ PCE[1], PCE[k:2]};
  
  ram2p1r1wbe #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF), .ce2(~StallM & ~FlushM),
    .ra1(IndexNextF),
    .rd1(DirPredictionF),
    .wa2(IndexE),
    .wd2(NewDirPredictionE),
    .we2(BranchInstrE & ~StallM & ~FlushM),
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


endmodule

///////////////////////////////////////////
// localbpbasic
//
// Written: Ross Thompson
// Email: ross1728@gmail.com
// Created: 16 March 2021
//
// Purpose: Local history branch predictor. Basic implementation without any repair and flop memories.

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

module localbpbasic import cvw::*; #(parameter cvw_t P,
                                     parameter XLEN,
                      parameter m = 6, // 2^m = number of local history branches 
                      parameter k = 10) ( // number of past branches stored
  input logic             clk,
  input logic             reset,
  input logic             StallF, StallD, StallE, StallM, StallW,
  input logic             FlushD, FlushE, FlushM, FlushW,
  output logic [1:0]      BPDirPredF, 
  output logic            BPDirPredWrongE,
  // update
  input logic [XLEN-1:0] PCNextF, PCM,
  input logic             BranchE, BranchM, PCSrcE
);

  logic [k-1:0]           IndexNextF, IndexM;
  logic [1:0]             BPDirPredD, BPDirPredE;
  logic [1:0]             NewBPDirPredE, NewBPDirPredM;

  logic [k-1:0]           LHRF, LHRD, LHRE, LHRM, LHR;
  logic [k-1:0]           LHRNextW;
  logic                   PCSrcM;
  logic [2**m-1:0][k-1:0]  LHRArray;
  logic [m-1:0]            IndexLHRNextF, IndexLHRM;
  
  logic                    UpdateM;

  assign IndexNextF = LHR;
  assign IndexM = LHRM;
  
  ram2p1r1wbe #(P, 2**k, 2) PHT(.clk(clk),
    .ce1(~StallF), .ce2(~StallW & ~FlushW),
    .ra1(IndexNextF),
    .rd1(BPDirPredF),
    .wa2(IndexM),
    .wd2(NewBPDirPredM),
    .we2(BranchM),
    .bwe2(1'b1));

  flopenrc #(2) PredictionRegD(clk, reset,  FlushD, ~StallD, BPDirPredF, BPDirPredD);
  flopenrc #(2) PredictionRegE(clk, reset,  FlushE, ~StallE, BPDirPredD, BPDirPredE);

  satCounter2 BPDirUpdateE(.BrDir(PCSrcE), .OldState(BPDirPredE), .NewState(NewBPDirPredE));
  flopenrc #(2) NewPredictionRegM(clk, reset,  FlushM, ~StallM, NewBPDirPredE, NewBPDirPredM);

  assign BPDirPredWrongE = PCSrcE != BPDirPredE[1] & BranchE;

  // This is the main difference between global and local history basic implementations. In global, 
  // the ghr wraps back into itself directly without
  // being pipelined.  I.E. GHR is not read in F and then pipelined to M where it is updated.  Instead
  // GHR is both read and update in M.  GHR is still pipelined so that the PHT is updated with the correct
  // GHR.  Local history in contrast must pipeline the specific history register read during F and then update
  // that same one in M.  This implementation does not forward if a branch matches in the D, E, or M stages.
  assign LHRNextW = BranchM ? {PCSrcM, LHRM[k-1:1]} : LHRM;

  // this is local history
  genvar      index;
  assign UpdateM = BranchM & ~StallW & ~FlushW;
  assign IndexLHRM = {PCM[m+1] ^ PCM[1], PCM[m:2]};
  for (index = 0; index < 2**m; index = index +1) begin:localhist
    flopenr #(k) LocalHistoryRegister(.clk, .reset, .en(UpdateM & (index == IndexLHRM)),
                                      .d(LHRNextW), .q(LHRArray[index]));
  end
  assign IndexLHRNextF = {PCNextF[m+1] ^ PCNextF[1], PCNextF[m:2]};
  assign LHR = LHRArray[IndexLHRNextF];

  // this is global history
  //flopenr #(k) LHRReg(clk, reset, ~StallM & ~FlushM & BranchM, LHRNextW, LHR);

  flopenrc #(1) PCSrcMReg(clk, reset, FlushM, ~StallM, PCSrcE, PCSrcM);
    
  flopenrc #(k) LHRFReg(clk, reset, FlushD, ~StallF, LHR, LHRF);
  flopenrc #(k) LHRDReg(clk, reset, FlushD, ~StallD, LHRF, LHRD);
  flopenrc #(k) LHREReg(clk, reset, FlushE, ~StallE, LHRD, LHRE);
  flopenrc #(k) LHRMReg(clk, reset, FlushM, ~StallM, LHRE, LHRM);


endmodule

///////////////////////////////////////////
// twoBitPredictor.sv
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 14, 2021
// Modified: 
//
// Purpose: 2 bit saturating counter predictor with parameterized table depth.
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

module twoBitPredictor #(parameter k = 10) (
  input  logic             clk,
  input  logic             reset,
  input  logic             StallF, StallD, StallE, StallM,
  input  logic             FlushD, FlushE, FlushM,
  input  logic [`XLEN-1:0] PCNextF, PCM,
  output logic [1:0]       DirPredictionF,
  output logic             DirPredictionWrongE,
  input  logic             BranchInstrE, BranchInstrM,
  input  logic             PCSrcE
);

  logic [k-1:0]            IndexNextF, IndexM;
  logic [1:0]              PredictionMemory;
  logic                    DoForwarding, DoForwardingF;
  logic [1:0]              DirPredictionD, DirPredictionE;
  logic [1:0]              NewDirPredictionE, NewDirPredictionM;

  // hashing function for indexing the PC
  // We have k bits to index, but XLEN bits as the input.
  // bit 0 is always 0, bit 1 is 0 if using 4 byte instructions, but is not always 0 if
  // using compressed instructions.  XOR bit 1 with the MSB of index.
  assign IndexNextF = {PCNextF[k+1] ^ PCNextF[1], PCNextF[k:2]};
  assign IndexM = {PCM[k+1] ^ PCM[1], PCM[k:2]};  


  ram2p1r1wbe #(2**k, 2) PHT(.clk(clk),
    .ce1(~StallF), .ce2(~StallM & ~FlushM),
    .ra1(IndexNextF),
    .rd1(DirPredictionF),
    .wa2(IndexM),
    .wd2(NewDirPredictionM),
    .we2(BranchInstrM & ~StallM & ~FlushM),
    .bwe2(1'b1));
  
  flopenrc #(2) PredictionRegD(clk, reset,  FlushD, ~StallD, DirPredictionF, DirPredictionD);
  flopenrc #(2) PredictionRegE(clk, reset,  FlushE, ~StallE, DirPredictionD, DirPredictionE);

  assign DirPredictionWrongE = PCSrcE != DirPredictionE[1] & BranchInstrE;

  satCounter2 BPDirUpdateE(.BrDir(PCSrcE), .OldState(DirPredictionE), .NewState(NewDirPredictionE));
  flopenrc #(2) NewPredictionRegM(clk, reset,  FlushM, ~StallM, NewDirPredictionE, NewDirPredictionM);
  

endmodule

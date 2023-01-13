///////////////////////////////////////////
// bpred.sv
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 12, 2021
// Modified: 
//
// Purpose: Branch prediction unit
//          Produces a branch prediction based on branch history.
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

module bpred (
   input logic              clk, reset,
   input logic              StallF, StallD, StallE, StallM, StallW,
   input logic              FlushD, FlushE, FlushM, FlushW,
   // Fetch stage
   // the prediction
   input logic [31:0]       InstrD,        // Decompressed decode stage instruction 
   input logic [`XLEN-1:0]  PCNextF,       // Next Fetch Address
   input logic [`XLEN-1:0]  PCPlus2or4F,   // PCF+2/4
   output logic [`XLEN-1:0] PCNext1F,      // Branch Predictor predicted or corrected fetch address on miss prediction
   output logic [`XLEN-1:0] NextValidPCE,  // Address of next valid instruction after the instruction in the Memory stage.

   // Update Predictor
   input logic [`XLEN-1:0]  PCF,           // Fetch stage instruction address.
   input logic [`XLEN-1:0]  PCD,           // Decode stage instruction address. Also the address the branch predictor took.
   input logic [`XLEN-1:0]  PCE,           // Execution stage instruction address.
   input logic [`XLEN-1:0]  PCM,           // Memory stage instruction address.

   // *** after reviewing the compressed instruction set I am leaning towards having the btb predict the instruction class.
   // *** the specifics of how this is encode is subject to change.
   input logic              PCSrcE,        // Executation stage branch is taken
   input logic [`XLEN-1:0]  IEUAdrE,       // The branch/jump target address
   input logic [`XLEN-1:0]  PCLinkE,       // The address following the branch instruction. (AKA Fall through address)
   output logic [4:0]       InstrClassM,   // The valid instruction class. 1-hot encoded as jalr, ret, jr (not ret), j, br

   // Report branch prediction status
   output logic             BPPredWrongE,  // Prediction is wrong.
   output logic             DirPredictionWrongM, // Prediction direction is wrong.
   output logic             BTBPredPCWrongM, // Prediction target wrong.
   output logic             RASPredPCWrongM, // RAS prediction is wrong.
   output logic             PredictionInstrClassWrongM // Class prediction is wrong.
   );

  logic                     BTBValidF;
  logic [1:0]               DirPredictionF;

  logic [4:0]               PredInstrClassF, PredInstrClassD, PredInstrClassE;
  logic [`XLEN-1:0]         BTBPredPCF, RASPCF;
  logic                     TargetWrongE;
  logic                     FallThroughWrongE;
  logic                     PredictionPCWrongE;
  logic                     PredictionInstrClassWrongE;
  logic [4:0]               InstrClassD, InstrClassE, InstrClassW;
  logic                     DirPredictionWrongE, BTBPredPCWrongE, RASPredPCWrongE, BPPredClassNonCFIWrongE;
  
  logic                     SelBPPredF;
  logic [`XLEN-1:0]         BPPredPCF;
  logic                     BPPredWrongM;
  logic [`XLEN-1:0]         PCNext0F;
  logic [`XLEN-1:0] 		PCCorrectE;

  // Part 1 branch direction prediction
  // look into the 2 port Sram model. something is wrong. 
  if (`BPTYPE == "BPTWOBIT") begin:Predictor
    twoBitPredictor DirPredictor(.clk, .reset, .StallF, .StallD, .StallE, .StallM, .FlushD, .FlushE, .FlushM,
      .PCNextF, .PCM, .DirPredictionF, .DirPredictionWrongE,
      .BranchInstrE(InstrClassE[0]), .BranchInstrM(InstrClassM[0]), .PCSrcE);

  end else if (`BPTYPE == "BPGLOBAL") begin:Predictor
    globalhistory DirPredictor(.clk, .reset, .StallF, .StallD, .StallE, .StallM, .FlushD, .FlushE, .FlushM,
      .PCNextF, .PCM, .DirPredictionF, .DirPredictionWrongE,
      .BranchInstrE(InstrClassE[0]), .BranchInstrM(InstrClassM[0]), .PCSrcE);

  end else if (`BPTYPE == "BPSPECULATIVEGLOBAL") begin:Predictor
    speculativeglobalhistory #(10) DirPredictor(.clk, .reset, .StallF, .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
      .PCNextF, .PCF, .PCD, .PCE, .PCM, .DirPredictionF, .DirPredictionWrongE,
      .BranchInstrF(PredInstrClassF[0]), .BranchInstrD(InstrClassD[0]), .BranchInstrE(InstrClassE[0]), .BranchInstrM(InstrClassM[0]),
      .BranchInstrW(InstrClassW[0]), .PCSrcE);
    
  end else if (`BPTYPE == "BPGSHARE") begin:Predictor
    gshare DirPredictor(.clk, .reset, .StallF, .StallD, .StallE, .StallM, .FlushD, .FlushE, .FlushM,
      .PCNextF, .PCM, .DirPredictionF, .DirPredictionWrongE,
      .BranchInstrE(InstrClassE[0]), .BranchInstrM(InstrClassM[0]), .PCSrcE);

  end else if (`BPTYPE == "BPSPECULATIVEGSHARE") begin:Predictor
    speculativegshare DirPredictor(.clk, .reset, .StallF, .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
      .PCNextF, .PCF, .PCD, .PCE, .PCM, .DirPredictionF, .DirPredictionWrongE,
      .BranchInstrF(PredInstrClassF[0]), .BranchInstrD(InstrClassD[0]), .BranchInstrE(InstrClassE[0]), .BranchInstrM(InstrClassM[0]),
      .BranchInstrW(InstrClassW[0]), .PCSrcE);

  end else if (`BPTYPE == "BPLOCALPAg") begin:Predictor
    // *** Fix me
/* -----\/----- EXCLUDED -----\/-----
    localHistoryPredictor DirPredictor(.clk,
      .reset, .StallF, .StallE,
      .LookUpPC(PCNextF),
      .Prediction(DirPredictionF),
      // update
      .UpdatePC(PCE),
      .UpdateEN(InstrClassE[0] & ~StallE),
      .PCSrcE,
      .UpdatePrediction(InstrClassE[0]));
 -----/\----- EXCLUDED -----/\----- */
  end 


  // this predictor will have two pieces of data,
  // 1) A direction (1 = Taken, 0 = Not Taken)
  // 2) Any information which is necessary for the predictor to build its next state.
  // For a 2 bit table this is the prediction count.
  assign SelBPPredF = ((PredInstrClassF[0] & DirPredictionF[1] & BTBValidF) | 
         PredInstrClassF[3] |
         (PredInstrClassF[2] & BTBValidF) | 
         PredInstrClassF[1] & BTBValidF) ;

  // Part 2 Branch target address prediction
  // *** For now the BTB will house the direct and indirect targets

  // *** getting to many false positivies from the BTB, we need a partial TAG to reduce this.
  BTBPredictor TargetPredictor(.clk(clk),
          .reset(reset),
          .*, // Stalls and flushes
          .LookUpPC(PCNextF),
          .TargetPC(BTBPredPCF),
          .InstrClass(PredInstrClassF),
          .Valid(BTBValidF),
          // update
          .UpdateEN((|InstrClassE | (PredictionInstrClassWrongE)) & ~StallE),
          .UpdatePC(PCE),
          .UpdateTarget(IEUAdrE),
          .UpdateInvalid(PredictionInstrClassWrongE),
          .UpdateInstrClass(InstrClassE));

  // Part 3 RAS
  // *** need to add the logic to restore RAS on flushes.  We will use incr for this.
  RASPredictor RASPredictor(.clk(clk),
       .reset(reset),
       .pop(PredInstrClassF[3] & ~StallF),
       .popPC(RASPCF),
       .push(InstrClassE[4] & ~StallE),
       .incr(1'b0),
       .pushPC(PCLinkE));

  assign BPPredPCF = PredInstrClassF[3] ? RASPCF : BTBPredPCF;

  // the branch predictor needs a compact decoding of the instruction class.
  // *** consider adding in the alternate return address x5 for returns.
  assign InstrClassD[4] = (InstrD[6:0] & 7'h77) == 7'h67 & (InstrD[11:07] & 5'h1B) == 5'h01; // jal(r) must link to ra or r5
  assign InstrClassD[3] = InstrD[6:0] == 7'h67 & (InstrD[19:15] & 5'h1B) == 5'h01; // return must return to ra or r5
  assign InstrClassD[2] = InstrD[6:0] == 7'h67 & (InstrD[19:15] & 5'h1B) != 5'h01 & (InstrD[11:7] & 5'h1B) != 5'h01; // jump register, but not return
  assign InstrClassD[1] = InstrD[6:0] == 7'h6F & (InstrD[11:7] & 5'h1B) != 5'h01; // jump, RD != x1 or x5
  assign InstrClassD[0] = InstrD[6:0] == 7'h63; // branch
  flopenrc #(5) InstrClassRegE(clk, reset,  FlushE, ~StallE, InstrClassD, InstrClassE);
  flopenrc #(5) InstrClassRegM(clk, reset,  FlushM, ~StallM, InstrClassE, InstrClassM);
  flopenrc #(5) InstrClassRegW(clk, reset,  FlushW, ~StallW, InstrClassM, InstrClassW);
  flopenrc #(1) BPPredWrongMReg(clk, reset, FlushM, ~StallM, BPPredWrongE, BPPredWrongM);

  // branch predictor
  flopenrc #(4) BPPredWrongRegM(clk, reset, FlushM, ~StallM, 
    {DirPredictionWrongE, BTBPredPCWrongE, RASPredPCWrongE, PredictionInstrClassWrongE},
    {DirPredictionWrongM, BTBPredPCWrongM, RASPredPCWrongM, PredictionInstrClassWrongM});

  // pipeline the class
  flopenrc #(5) PredInstrClassRegD(clk, reset, FlushD, ~StallD, PredInstrClassF, PredInstrClassD);
  flopenrc #(5) PredInstrClassRegE(clk, reset, FlushE, ~StallE, PredInstrClassD, PredInstrClassE);

  // Check the prediction
  // first check if the target or fallthrough address matches what was predicted.
  assign TargetWrongE = IEUAdrE != PCD;
  assign FallThroughWrongE = PCLinkE != PCD;
  // If the target is taken check the target rather than fallthrough.  The instruction needs to be a branch if PCSrcE is selected
  // Remember the bpred can incorrectly predict a non cfi instruction as a branch taken.  If the real instruction is non cfi
  // it must have selected the fall through.
  assign PredictionPCWrongE = (PCSrcE  & (|InstrClassE) ? TargetWrongE : FallThroughWrongE);

  // The branch direction also need to checked.
  // However if the direction is wrong then the pc will be wrong.  This is only relavent to checking the
  // accuracy of the direciton prediction.
  //assign DirPredictionWrongE = (BPPredE[1] ^ PCSrcE) & InstrClassE[0];
  
  // Finally we need to check if the class is wrong.  When the class is wrong the BTB needs to be updated.
  // Also we want to track this in a performance counter.
  assign PredictionInstrClassWrongE = InstrClassE != PredInstrClassE;

  // We want to output to the instruction fetch if the PC fetched was wrong.  If by chance the predictor was wrong about
  // the direction or class, but correct about the target we don't have the flush the pipeline.  However we still
  // need this information to verify the accuracy of the predictors.
  assign BPPredWrongE = (PredictionPCWrongE & |InstrClassE) | BPPredClassNonCFIWrongE;

  // If we have a jump, jump register or jal or jalr and the PC is wrong we need to increment the performance counter.
  assign BTBPredPCWrongE = (InstrClassE[4] | InstrClassE[2] | InstrClassE[1]) & PredictionPCWrongE;
  // similar with RAS
  assign RASPredPCWrongE = InstrClassE[3] & PredictionPCWrongE;
  // Finally if the real instruction class is non CFI but the predictor said it was we need to count.
  assign BPPredClassNonCFIWrongE = PredictionInstrClassWrongE & ~|InstrClassE;
  
  
  // Selects the BP or PC+2/4.
  mux2 #(`XLEN) pcmux0(PCPlus2or4F, BPPredPCF, SelBPPredF, PCNext0F);
  // If the prediction is wrong select the correct address.
  mux2 #(`XLEN) pcmux1(PCNext0F, PCCorrectE, BPPredWrongE, PCNext1F);  
  // Correct branch/jump target.
  mux2 #(`XLEN) pccorrectemux(PCLinkE, IEUAdrE, PCSrcE, PCCorrectE);
  
  // If the fence/csrw was predicted as a taken branch then we select PCF, rather PCE.
  // Effectively this is PCM+4 or the non-existant PCLinkM
  //  if(`BPCLASS) begin
  mux2 #(`XLEN) pcmuxBPWrongInvalidateFlush(PCE, PCF, BPPredWrongM, NextValidPCE);
  //  end else begin
  //	assign NextValidPCE = PCE;
  //  end
  
endmodule

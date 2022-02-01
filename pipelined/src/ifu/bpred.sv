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

module bpred 
  (input logic              clk, reset,
   input logic              StallF, StallD, StallE, StallM,
   input logic              FlushF, FlushD, FlushE, FlushM,
   // Fetch stage
   // the prediction
   input logic [31:0]       InstrD, 
   input logic [`XLEN-1:0]  PCNextF, // *** forgot to include this one on the I/O list
   output logic [`XLEN-1:0] BPPredPCF,
   output logic             SelBPPredF,
   // Update Predictor
   input logic [`XLEN-1:0]  PCE, // The address of the currently executing instruction
   // 1 hot encoding
   // return, jump register, jump, branch
   // *** after reviewing the compressed instruction set I am leaning towards having the btb predict the instruction class.
   // *** the specifics of how this is encode is subject to change.
   input logic              PCSrcE, // AKA Branch Taken
   // Signals required to check the branch prediction accuracy.
   input logic [`XLEN-1:0]  IEUAdrE, // The branch destination if the branch is taken.
   input logic [`XLEN-1:0]  PCD, // The address the branch predictor took.
   input logic [`XLEN-1:0]  PCLinkE, // The address following the branch instruction. (AKA Fall through address)
   output logic [4:0]       InstrClassM,
   // Report branch prediction status
   output logic             BPPredWrongE,
   output logic             BPPredWrongM,   
   output logic             BPPredDirWrongM,
   output logic             BTBPredPCWrongM,
   output logic             RASPredPCWrongM,
   output logic             BPPredClassNonCFIWrongM
   );

  logic                     BTBValidF;
  logic [1:0]               BPPredF, BPPredD, BPPredE, UpdateBPPredE;

  logic [4:0]               BPInstrClassF, BPInstrClassD, BPInstrClassE;
  logic [`XLEN-1:0]         BTBPredPCF, RASPCF;
  logic                     TargetWrongE;
  logic                     FallThroughWrongE;
  logic                     PredictionPCWrongE;
  logic                     PredictionInstrClassWrongE;
  logic [4:0]               InstrClassD, InstrClassE;
  logic                     BPPredDirWrongE, BTBPredPCWrongE, RASPredPCWrongE, BPPredClassNonCFIWrongE;
  

  // Part 1 branch direction prediction

  if (`BPTYPE == "BPTWOBIT") begin:Predictor
    twoBitPredictor DirPredictor(.clk, .reset, .StallF,
      .LookUpPC(PCNextF),
      .Prediction(BPPredF),
      // update
      .UpdatePC(PCE),
      .UpdateEN(InstrClassE[0] & ~StallE),
      .UpdatePrediction(UpdateBPPredE));

  end else if (`BPTYPE == "BPGLOBAL") begin:Predictor
    globalHistoryPredictor DirPredictor(.clk, .reset, .StallF, .StallE,
      .PCNextF, .BPPredF, 
      .InstrClassE, .BPInstrClassF, .BPInstrClassD, .BPInstrClassE, .BPPredDirWrongE,
      .PCE, .PCSrcE, .UpdateBPPredE);

  end else if (`BPTYPE == "BPGSHARE") begin:Predictor
    gsharePredictor DirPredictor(.clk, .reset, .StallF, .StallE,
      .PCNextF, .BPPredF,
      .InstrClassE, .BPInstrClassF, .BPInstrClassD, .BPInstrClassE, .BPPredDirWrongE,
      .PCE, .PCSrcE, .UpdateBPPredE);
  end 
  else if (`BPTYPE == "BPLOCALPAg") begin:Predictor

    localHistoryPredictor DirPredictor(.clk,
      .reset, .StallF, .StallE, .FlushF,
      .LookUpPC(PCNextF),
      .Prediction(BPPredF),
      // update
      .UpdatePC(PCE),
      .UpdateEN(InstrClassE[0] & ~StallE),
      .PCSrcE,
      .UpdatePrediction(UpdateBPPredE));
  end 


  // this predictor will have two pieces of data,
  // 1) A direction (1 = Taken, 0 = Not Taken)
  // 2) Any information which is necessary for the predictor to built it's next state.
  // For a 2 bit table this is the prediction count.

  assign SelBPPredF = ((BPInstrClassF[0] & BPPredF[1] & BTBValidF) | 
         BPInstrClassF[3] |
         (BPInstrClassF[2] & BTBValidF) | 
         BPInstrClassF[1] & BTBValidF) ;


  // Part 2 Branch target address prediction
  // *** For now the BTB will house the direct and indirect targets

  // *** getting to many false positivies from the BTB, we need a partial TAG to reduce this.
  BTBPredictor TargetPredictor(.clk(clk),
          .reset(reset),
          .*, // Stalls and flushes
          .LookUpPC(PCNextF),
          .TargetPC(BTBPredPCF),
          .InstrClass(BPInstrClassF),
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
       .pop(BPInstrClassF[3] & ~StallF),
       .popPC(RASPCF),
       .push(InstrClassE[4] & ~StallE),
       .incr(1'b0),
       .pushPC(PCLinkE));

  assign BPPredPCF = BPInstrClassF[3] ? RASPCF : BTBPredPCF;
  
  

  // The prediction and its results need to be passed through the pipeline
  // *** for other predictors will will be different.
  
  flopenr #(2) BPPredRegD(.clk(clk),
      .reset(reset),
      .en(~StallD),
      .d(BPPredF),
      .q(BPPredD));

  flopenr #(2) BPPredRegE(.clk(clk),
      .reset(reset),
      .en(~StallE),
      .d(BPPredD),
      .q(BPPredE));


  // the branch predictor needs a compact decoding of the instruction class.
  // *** consider adding in the alternate return address x5 for returns.
  assign InstrClassD[4] = (InstrD[6:0] & 7'h77) == 7'h67 & (InstrD[11:07] & 5'h1B) == 5'h01; // jal(r) must link to ra or r5
  assign InstrClassD[3] = InstrD[6:0] == 7'h67 & (InstrD[19:15] & 5'h1B) == 5'h01; // return must return to ra or r5
  assign InstrClassD[2] = InstrD[6:0] == 7'h67 & (InstrD[19:15] & 5'h1B) != 5'h01 & (InstrD[11:7] & 5'h1B) != 5'h01; // jump register, but not return
  assign InstrClassD[1] = InstrD[6:0] == 7'h6F & (InstrD[11:7] & 5'h1B) != 5'h01; // jump, RD != x1 or x5
  assign InstrClassD[0] = InstrD[6:0] == 7'h63; // branch
  flopenrc #(5) InstrClassRegE(.clk, .reset, .en(~StallE), .clear(FlushE), .d(InstrClassD), .q(InstrClassE));
  flopenrc #(5) InstrClassRegM(.clk, .reset, .en(~StallM), .clear(FlushM), .d(InstrClassE), .q(InstrClassM));
  flopenrc #(1) BPPredWrongMReg(.clk, .reset, .en(~StallM), .clear(FlushM), .d(BPPredWrongE), .q(BPPredWrongM));


  // branch predictor
  flopenrc #(4) BPPredWrongRegM(.clk, .reset, .en(~StallM), .clear(FlushM),
                                .d({BPPredDirWrongE, BTBPredPCWrongE, RASPredPCWrongE, BPPredClassNonCFIWrongE}),
                                .q({BPPredDirWrongM, BTBPredPCWrongM, RASPredPCWrongM, BPPredClassNonCFIWrongM}));
  


  // pipeline the class
  flopenrc #(5) BPInstrClassRegD(.clk(clk),
          .reset(reset),
          .en(~StallD),
          .clear(FlushD),
          .d(BPInstrClassF),
          .q(BPInstrClassD));

  flopenrc #(5) BPInstrClassRegE(.clk(clk),
          .reset(reset),
          .en(~StallE),
          .clear(FlushE),
          .d(BPInstrClassD),
          .q(BPInstrClassE));

  

  // Check the prediction makes execution.

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
  assign BPPredDirWrongE = (BPPredE[1] ^ PCSrcE) & InstrClassE[0];
  
  // Finally we need to check if the class is wrong.  When the class is wrong the BTB needs to be updated.
  // Also we want to track this in a performance counter.
  assign PredictionInstrClassWrongE = InstrClassE != BPInstrClassE;

  // We want to output to the instruction fetch if the PC fetched was wrong.  If by chance the predictor was wrong about
  // the direction or class, but correct about the target we don't have the flush the pipeline.  However we still
  // need this information to verify the accuracy of the predictors.
  
  
  //assign BPPredWrongE = ((PredictionPCWrongE | BPPredDirWrongE) & (|InstrClassE)) | PredictionInstrClassWrongE;

  assign BPPredWrongE = (PredictionPCWrongE & |InstrClassE) | BPPredClassNonCFIWrongE;

  // If we have a jump, jump register or jal or jalr and the PC is wrong we need to increment the performance counter.
  assign BTBPredPCWrongE = (InstrClassE[4] | InstrClassE[2] | InstrClassE[1]) & PredictionPCWrongE;
  // similar with RAS
  assign RASPredPCWrongE = InstrClassE[3] & PredictionPCWrongE;
  // Finally if the real instruction class is non CFI but the predictor said it was we need to count.
  assign BPPredClassNonCFIWrongE = PredictionInstrClassWrongE & ~|InstrClassE;
  
  // Update predictors

  satCounter2 BPDirUpdate(.BrDir(PCSrcE),
     .OldState(BPPredE),
     .NewState(UpdateBPPredE));

endmodule

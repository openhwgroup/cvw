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
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module bpred 
  (input logic clk, reset,
   input logic 		    StallF, StallD, StallE, FlushF, FlushD, FlushE,
   // Fetch stage
   // the prediction
   input logic [`XLEN-1:0]  PCNextF, // *** forgot to include this one on the I/O list
   output logic [`XLEN-1:0] BPPredPCF,
   output logic 	    SelBPPredF,
   // Update Predictor
   input logic [`XLEN-1:0]  PCE, // The address of the currently executing instruction
   // 1 hot encoding
   // return, jump register, jump, branch
   // *** after reviewing the compressed instruction set I am leaning towards having the btb predict the instruction class.
   // *** the specifics of how this is encode is subject to change.
   input logic 		    PCSrcE, // AKA Branch Taken
   // Signals required to check the branch prediction accuracy.
   input logic [`XLEN-1:0]  PCTargetE, // The branch destination if the branch is taken.
   input logic [`XLEN-1:0]  PCD, // The address the branch predictor took.
   input logic [`XLEN-1:0]  PCLinkE, // The address following the branch instruction. (AKA Fall through address)
   input logic [3:0] 	    InstrClassE,
   // Report branch prediction status
   output logic 	    BPPredWrongE
   );

  logic 		    BTBValidF;
  logic [1:0] 		    BPPredF, BPPredD, BPPredE, UpdateBPPredE;

  logic [3:0] 		    BPInstrClassF, BPInstrClassD, BPInstrClassE;
  logic [`XLEN-1:0] 	    BTBPredPCF, RASPCF;
  logic 		    TargetWrongE;
  logic 		    FallThroughWrongE;
  logic 		    PredictionDirWrongE;
  logic 		    PredictionPCWrongE;
  logic 		    PredictionInstrClassWrongE;
  
  logic [`XLEN-1:0] 	    CorrectPCE;


  // Part 1 branch direction prediction

  generate
    if (`BPTYPE == "BPTWOBIT") begin:Predictor
      twoBitPredictor DirPredictor(.clk(clk),
				   .reset(reset),
				   .LookUpPC(PCNextF),
				   .Prediction(BPPredF),
				   // update
				   .UpdatePC(PCE),
				   .UpdateEN(InstrClassE[0] & ~StallE),
				   .UpdatePrediction(UpdateBPPredE));

    end else if (`BPTYPE == "BPGLOBAL") begin:Predictor

      globalHistoryPredictor DirPredictor(.clk(clk),
					  .reset(reset),
					  .*, // Stalls and flushes
					  .LookUpPC(PCNextF),
					  .Prediction(BPPredF),
					  // update
					  .UpdatePC(PCE),
					  .UpdateEN(InstrClassE[0] & ~StallE),
					  .PCSrcE(PCSrcE),
					  .UpdatePrediction(UpdateBPPredE));
    end else if (`BPTYPE == "BPGSHARE") begin:Predictor

      gsharePredictor DirPredictor(.clk(clk),
				   .reset(reset),
				   .*, // Stalls and flushes
				   .LookUpPC(PCNextF),
				   .Prediction(BPPredF),
				   // update
				   .UpdatePC(PCE),
				   .UpdateEN(InstrClassE[0] & ~StallE),
				   .PCSrcE(PCSrcE),
				   .UpdatePrediction(UpdateBPPredE));
    end 
  endgenerate


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
			       .UpdateTarget(PCTargetE),
			       .UpdateInvalid(PredictionInstrClassWrongE),
			       .UpdateInstrClass(InstrClassE));

  // need to forward when updating to the same address as reading.
  //assign CorrectPCE = PCSrcE ? PCTargetE : PCLinkE;
  //assign TargetPC = (PCE == PCNextF) ? CorrectPCE : BTBPredPCF;

  // Part 3 RAS
  // *** need to add the logic to restore RAS on flushes.  We will use incr for this.
  RASPredictor RASPredictor(.clk(clk),
			    .reset(reset),
			    .pop(BPInstrClassF[3] & ~StallF),
			    .popPC(RASPCF),
			    .push(InstrClassE[3] & ~StallE),
			    .incr(1'b0),
			    .pushPC(PCLinkE));

  assign BPPredPCF = BPInstrClassF[3] ? RASPCF : BTBPredPCF;
  
  

  // The prediction and its results need to be passed through the pipeline
  // *** for other predictors will will be different.
  
  flopenrc #(2) BPPredRegD(.clk(clk),
			   .reset(reset),
			   .en(~StallD),
			   .clear(FlushD),
			   .d(BPPredF),
			   .q(BPPredD));

  flopenrc #(2) BPPredRegE(.clk(clk),
			   .reset(reset),
			   .en(~StallE),
			   .clear(FlushE),
			   .d(BPPredD),
			   .q(BPPredE));

  // pipeline the class
  flopenrc #(4) InstrClassRegD(.clk(clk),
			       .reset(reset),
			       .en(~StallD),
			       .clear(FlushD),
			       .d(BPInstrClassF),
			       .q(BPInstrClassD));

  flopenrc #(4) InstrClassRegE(.clk(clk),
			       .reset(reset),
			       .en(~StallE),
			       .clear(FlushE),
			       .d(BPInstrClassD),
			       .q(BPInstrClassE));

  

  // Check the prediction makes execution.
  assign TargetWrongE = PCTargetE != PCD;
  assign FallThroughWrongE = PCLinkE != PCD;
  assign PredictionDirWrongE = (BPPredE[1] ^ PCSrcE) & InstrClassE[0];
  assign PredictionPCWrongE = PCSrcE ? TargetWrongE : FallThroughWrongE;
  assign PredictionInstrClassWrongE = InstrClassE != BPInstrClassE;  
  assign BPPredWrongE = ((PredictionPCWrongE | PredictionDirWrongE) & (|InstrClassE)) | PredictionInstrClassWrongE;

  // Update predictors

  satCounter2 BPDirUpdate(.BrDir(PCSrcE),
			  .OldState(BPPredE),
			  .NewState(UpdateBPPredE));

endmodule

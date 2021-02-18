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
   input logic [31:0] 	    InstrF, // we are going to use the opcode to indicate what type instruction this is.
   // if this is too slow we will have to predict the type of instruction.
   // Execute state
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
   // Report branch prediction status
   output logic 	    BPPredWrongE
   );

  logic 		    BTBValidF;
  logic [1:0] 		    BPPredF, BPPredD, BPPredE, UpdateBPPredE;

  logic [3:0] 		    InstrClassD, InstrClassF, InstrClassE;
  logic [`XLEN-1:0] 	    BTBPredPCF, RASPCF, BTBPredPCMemoryF;
  logic 		    TargetWrongE;
  logic 		    FallThroughWrongE;
  logic 		    PredictionDirWrongE;
  logic 		    PredictionPCWrongE;
  logic [`XLEN-1:0] 	    CorrectPCE;

  // Part 1 decode the instruction class.
  // *** for now I'm skiping the compressed instructions
  assign InstrClassF[3] = InstrF[5:0] == 7'h67 && InstrF[19:15] == 5'h01; // return
  // This is probably too much logic. 
  // *** This also encourages me to switch to predicting the class.

  assign InstrClassF[2] = InstrF[6:0] == 7'h67 && InstrF[19:15] == 5'h01; // jump register, but not return
  assign InstrClassF[1] = InstrF[6:0] == 7'h6F; // jump
  assign InstrClassF[0] = InstrF[6:0] == 7'h63; // branch
  
  // Part 2 branch direction prediction

  twoBitPredictor DirPredictor(.clk(clk),
			       .LookUpPC(PCNextF),
			       .Prediction(BPPredF),
			       // update
			       .UpdatePC(PCE),
			       .UpdateEN(InstrClassE[0]),
			       .UpdatePrediction(UpdateBPPredE));

  // this predictor will have two pieces of data,
  // 1) A direction (1 = Taken, 0 = Not Taken)
  // 2) Any information which is necessary for the predictor to built it's next state.
  // For a 2 bit table this is the prediction count.

  assign SelBPPredF = ((InstrClassF[0] & BPPredF[1] & BTBValidF) | 
		       InstrClassF[3] |
		       (InstrClassF[2] & BTBValidF) | 
		       InstrClassF[1] & BTBValidF) ;


  // Part 3 Branch target address prediction
  // *** For now the BTB will house the direct and indirect targets

  BTBPredictor TargetPredictor(.clk(clk),
			       .reset(reset),
			       .LookUpPC(PCNextF),
			       .TargetPC(BTBPredPCMemoryF),
			       .Valid(BTBValidF),
			       // update
			       .UpdateEN(InstrClassE[2] | InstrClassE[1] | InstrClassE[0]),
			       .UpdatePC(PCE),
			       .UpdateTarget(PCTargetE));

  // need to forward when updating to the same address as reading.
  assign CorrectPCE = PCSrcE ? PCTargetE : PCLinkE;
  assign TargetPC = (PCE == PCNextF) ? CorrectPCE : BTBPredPCMemoryF;

  // Part 4 RAS
  // *** need to add the logic to restore RAS on flushes.  We will use incr for this.
  RASPredictor RASPredictor(.clk(clk),
			    .reset(reset),
			    .pop(InstrClassF[3]),
			    .popPC(RASPCF),
			    .push(InstrClassE[3]),
			    .incr(1'b0),
			    .pushPC(PCLinkE));

  assign BPPredPCF = InstrClassF[3] ? RASPCF : BTBPredPCF;
  
  

  // The prediction and its results need to be passed through the pipeline
  // *** for other predictors will will be different.
  
  flopenrc #(2) BPPredRegD(.clk(clk),
			   .reset(reset),
			   .en(~StallF),
			   .clear(FlushF),
			   .d(BPPredF),
			   .q(BPPredD));

  flopenrc #(2) BPPredRegE(.clk(clk),
			   .reset(reset),
			   .en(~StallD),
			   .clear(FlushD),
			   .d(BPPredD),
			   .q(BPPredE));

  // pipeline the class
  flopenrc #(4) InstrClassRegD(.clk(clk),
			       .reset(reset),
			       .en(~StallF),
			       .clear(FlushF),
			       .d(InstrClassF),
			       .q(InstrClassD));

  flopenrc #(4) InstrClassRegE(.clk(clk),
			       .reset(reset),
			       .en(~StallD),
			       .clear(flushD),
			       .d(InstrClassD),
			       .q(InstrClassE));

  // Check the prediction makes execution.
  assign TargetWrongE = PCTargetE != PCD;
  assign FallThroughWrongE = PCLinkE != PCD;
  assign PredictionDirWrongE = BPPredE ^ PCSrcE;
  assign PredictionPCWrongE = PCSrcE ? TargetWrongE : FallThroughWrongE;
  assign BPPredWrongE = PredictionPCWrongE | PredictionDirWrongE;

  // Update predictors

  satCounter2 BPDirUpdate(.BrDir(~PredictionDirWrongE),
			  .OldState(BPPredE),
			  .NewState(UpdateBPPredE));

endmodule

///////////////////////////////////////////
// globalHistoryPredictor.sv
//
// Written: Shreya Sanghai
// Email: ssanghai@hmc.edu
// Created: March 16, 2021
// Modified: 
//
// Purpose: Gshare predictor with parameterized global history register
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

module gsharePredictor
  #(parameter int k = 10
    )
  (input logic             clk,
   input logic             reset,
   input logic             StallF, StallE,
   input logic [`XLEN-1:0] PCNextF,
   output logic [1:0]      BPPredF,
   // update
   input logic [4:0]       InstrClassE,
   input logic [4:0]       BPInstrClassE,
   input logic [4:0]       BPInstrClassD,
   input logic [4:0]       BPInstrClassF, 
   input logic             BPPredDirWrongE,

   input logic [`XLEN-1:0] PCE,
   input logic             PCSrcE,
   input logic [1:0]       UpdateBPPredE
  
   );
  logic [k+1:0]            GHR, GHRNext;
  logic [k-1:0]            PHTUpdateAdr, PHTUpdateAdr0, PHTUpdateAdr1;
  logic                    PHTUpdateEN;
  logic                    BPClassWrongNonCFI;
  logic                    BPClassWrongCFI;
  logic                    BPClassRightNonCFI;
  logic                    BPClassRightBPWrong;
  logic                    BPClassRightBPRight;

  logic [6:0]              GHRMuxSel;
  logic                    GHRUpdateEN;
  logic [k-1:0]            GHRLookup;

  assign BPClassRightNonCFI = ~BPInstrClassE[0] & ~InstrClassE[0];
  assign BPClassWrongCFI = ~BPInstrClassE[0] & InstrClassE[0];
  assign BPClassWrongNonCFI = BPInstrClassE[0] & ~InstrClassE[0];
  assign BPClassRightBPWrong = BPInstrClassE[0] & InstrClassE[0] & BPPredDirWrongE;
  assign BPClassRightBPRight = BPInstrClassE[0] & InstrClassE[0] & ~BPPredDirWrongE;
  
  
  // GHR update selection, 1 hot encoded.
  assign GHRMuxSel[0] = ~BPInstrClassF[0] & (BPClassRightNonCFI | BPClassRightBPRight);
  assign GHRMuxSel[1] = BPClassWrongCFI & ~BPInstrClassD[0];
  assign GHRMuxSel[2] = BPClassWrongNonCFI & ~BPInstrClassD[0];
  assign GHRMuxSel[3] = (BPClassRightBPWrong & ~BPInstrClassD[0]) | (BPClassWrongCFI & BPInstrClassD[0]);
  assign GHRMuxSel[4] = BPClassWrongNonCFI & BPInstrClassD[0];
  assign GHRMuxSel[5] = InstrClassE[0] & BPClassRightBPWrong & BPInstrClassD[0];
  assign GHRMuxSel[6] = BPInstrClassF[0] & (BPClassRightNonCFI | (InstrClassE[0] & BPClassRightBPRight));
  assign GHRUpdateEN = (| GHRMuxSel[5:1] & ~StallE) | GHRMuxSel[6] & ~StallF;

  // hoping this created a AND-OR mux.
  always_comb begin
    case (GHRMuxSel) 
      7'b000_0001: GHRNext = GHR[k-1+2:0];  // no change
      7'b000_0010: GHRNext = {GHR[k-2+2:0], PCSrcE}; // branch update
      7'b000_0100: GHRNext = {1'b0, GHR[k+1:1]}; // repair 1
      7'b000_1000: GHRNext = {GHR[k-1+2:1], PCSrcE}; // branch update with mis prediction correction
      7'b001_0000: GHRNext = {2'b00, GHR[k+1:2]}; // repair 2
      7'b010_0000: GHRNext = {1'b0, GHR[k+1:2], PCSrcE}; // branch update + repair 1
      7'b100_0000: GHRNext = {GHR[k-2+2:0], BPPredF[1]}; // speculative update
      default: GHRNext = GHR[k-1+2:0];
    endcase
  end

  flopenr #(k+2) GlobalHistoryRegister(.clk(clk),
           .reset(reset),
           .en((GHRUpdateEN)),
           .d(GHRNext),
           .q(GHR));

  // if actively updating the GHR at the time of prediction we want to us
  // GHRNext as the lookup rather than GHR.

  assign PHTUpdateAdr0 = InstrClassE[0] ? GHR[k:1] : GHR[k-1:0];
  assign PHTUpdateAdr1 = InstrClassE[0] ? GHR[k+1:2] : GHR[k:1];  
  assign PHTUpdateAdr = BPInstrClassD[0] ? PHTUpdateAdr1 : PHTUpdateAdr0;
  assign PHTUpdateEN = InstrClassE[0] & ~StallE;

  assign GHRLookup = |GHRMuxSel[6:1] ? GHRNext[k-1:0] : GHR[k-1:0];
  
  // Make Prediction by reading the correct address in the PHT and also update the new address in the PHT 
  SRAM2P1R1W #(k, 2) PHT(.clk(clk),
    .reset(reset),
    //.RA1(GHR[k-1:0]),
    .RA1(GHRLookup ^ PCNextF[k:1]),
    .RD1(BPPredF),
    .REN1(~StallF),
    .WA1(PHTUpdateAdr ^ PCE[k:1]),
    .WD1(UpdateBPPredE),
    .WEN1(PHTUpdateEN),
    .BitWEN1(2'b11));

endmodule // gsharePredictor

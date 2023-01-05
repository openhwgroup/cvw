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

module twoBitPredictor
  #(parameter int k = 10
    )
  (input logic             clk,
   input logic             reset,
   input logic             StallF, StallD, StallE, StallM,
   input logic             FlushD, FlushE, FlushM,
   input logic [`XLEN-1:0] PCNextF, PCM,
   output logic [1:0]      DirPredictionF,
   output logic            DirPredictionWrongE,
   input logic             BranchInstrE, BranchInstrM,
   input logic             PCSrcE
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

  assign DirPredictionWrongE = PCSrcE != DirPredictionE[1] & BranchInstrE;

  satCounter2 BPDirUpdateE(.BrDir(PCSrcE), .OldState(DirPredictionE), .NewState(NewDirPredictionE));
  flopenrc #(2) NewPredictionRegM(clk, reset,  FlushM, ~StallM, NewDirPredictionE, NewDirPredictionM);
  

endmodule

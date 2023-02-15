///////////////////////////////////////////
// btb.sv
//
// Written: Ross Thomposn ross1728@gmail.com
// Created: February 15, 2021
// Modified: 24 January 2023 
//
// Purpose: Branch Target Buffer (BTB). The BTB predicts the target address of all control flow instructions.
//          It also guesses the type of instrution; jalr(r), return, jump (jr), or branch.
//
// Documentation: RISC-V System on Chip Design Chapter 10 (Figure ***)
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

module btb #(parameter int Depth = 10 ) (
  input  logic             clk,
  input  logic             reset,
  input  logic             StallF, StallD, StallM, FlushD, FlushM,
  input  logic [`XLEN-1:0] PCNextF, PCF, PCD, PCE,                 // PC at various stages
  output logic [`XLEN-1:0] PredPCF,                                // BTB's guess at PC
  output logic [3:0]       BTBPredInstrClassF,                        // BTB's guess at instruction class
  output logic             PredValidF,                             // BTB's guess is valid
  // update
  input  logic             AnyWrongPredInstrClassE,             // BTB's instruction class guess was wrong
  input  logic [`XLEN-1:0] IEUAdrE,                                // Branch/jump target address to insert into btb
  input  logic [3:0]       InstrClassD,                            // Instruction class to insert into btb
  input  logic [3:0]       InstrClassE                             // Instruction class to insert into btb
);

  localparam TotalDepth = 2 ** Depth;
  logic [TotalDepth-1:0]    ValidBits;
  logic [Depth-1:0]         PCNextFIndex, PCFIndex, PCDIndex, PCEIndex;
  logic [`XLEN-1:0] 		ResetPC;
  logic 					MatchF, MatchD, MatchE, MatchNextX, MatchXF;
  logic [`XLEN+4:0] 		ForwardBTBPrediction, ForwardBTBPredictionF;
  logic [`XLEN+3:0] 		TableBTBPredictionF;
  logic [`XLEN-1:0] 		PredPCD;  
  logic 					UpdateEn;
  logic 					TablePredValidF, PredValidD;
    
  // hashing function for indexing the PC
  // We have Depth bits to index, but XLEN bits as the input.
  // bit 0 is always 0, bit 1 is 0 if using 4 byte instructions, but is not always 0 if
  // using compressed instructions.  XOR bit 1 with the MSB of index.
  assign PCFIndex = {PCF[Depth+1] ^ PCF[1], PCF[Depth:2]};
  assign PCDIndex = {PCD[Depth+1] ^ PCD[1], PCD[Depth:2]};
  assign PCEIndex = {PCE[Depth+1] ^ PCE[1], PCE[Depth:2]};

  // must output a valid PC and valid bit during reset.  Because only PCF, not PCNextF is reset, PCNextF is invalid
  // during reset.  The BTB must produce a non X PC1NextF to allow the simulation to run.
  // While thie mux could be included in IFU it is not necessary for the IROM/I$/bus.
  // For now it is optimal to leave it here.
  assign ResetPC = `RESET_VECTOR;
  assign PCNextFIndex = reset ? ResetPC[Depth+1:2] : {PCNextF[Depth+1] ^ PCNextF[1], PCNextF[Depth:2]}; 

  assign MatchF = PCNextFIndex == PCFIndex;
  assign MatchD = PCNextFIndex == PCDIndex;
  assign MatchE = PCNextFIndex == PCEIndex;
  assign MatchNextX = MatchF | MatchD | MatchE;
  
  flopenr #(1) MatchReg(clk, reset, ~StallF, MatchNextX, MatchXF);

  assign ForwardBTBPrediction = MatchF ? {PredValidF, BTBPredInstrClassF, PredPCF} :
                                MatchD ? {PredValidD, InstrClassD, PredPCD} :
                                {1'b1, InstrClassE, IEUAdrE} ;

  flopenr #(`XLEN+5) ForwardBTBPredicitonReg(clk, reset, ~StallF, ForwardBTBPrediction, ForwardBTBPredictionF);

  assign {PredValidF, BTBPredInstrClassF, PredPCF} = MatchXF ? ForwardBTBPredictionF : {TablePredValidF, TableBTBPredictionF};

  always_ff @ (posedge clk) begin
    if (reset) begin
      ValidBits <= #1 {TotalDepth{1'b0}};
    end else if ((UpdateEn) & ~StallM & ~FlushM) begin
      ValidBits[PCEIndex] <= #1 |InstrClassE;
    end
	if(~StallF | reset) TablePredValidF = ValidBits[PCNextFIndex];
  end

  assign UpdateEn = |InstrClassE | AnyWrongPredInstrClassE;

  // An optimization may be using a PC relative address.
  ram2p1r1wbe #(2**Depth, `XLEN+4) memory(
    .clk, .ce1(~StallF | reset), .ra1(PCNextFIndex), .rd1(TableBTBPredictionF),
     .ce2(~StallM & ~FlushM), .wa2(PCEIndex), .wd2({InstrClassE, IEUAdrE}), .we2(UpdateEn), .bwe2('1));

  flopenrc #(`XLEN+1) BTBD(clk, reset, FlushD, ~StallD, {PredValidF, PredPCF}, {PredValidD, PredPCD});

endmodule

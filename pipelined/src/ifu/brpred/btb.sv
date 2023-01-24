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

module btb
  #(parameter int Depth = 10
    )
  (input  logic             clk,
   input  logic             reset,
   input  logic             StallF, StallE,
   input  logic [`XLEN-1:0] PCNextF,
   output logic [`XLEN-1:0] BTBPredPCF,
   output logic [3:0]       InstrClass,
   output logic             Valid,
   // update
   input  logic             UpdateEN,
   input  logic [`XLEN-1:0] PCE,
   input  logic [`XLEN-1:0] IEUAdrE,
   input  logic [3:0]       InstrClassE,
   input  logic             UpdateInvalid
   );

  localparam TotalDepth = 2 ** Depth;
  logic [TotalDepth-1:0]    ValidBits;
  logic [Depth-1:0]         PCNextFIndex, PCEIndex, PCNextFIndexQ, PCEIndexQ;
  logic                     UpdateENQ;
  logic [`XLEN-1:0] 		ResetPC;


  // hashing function for indexing the PC
  // We have Depth bits to index, but XLEN bits as the input.
  // bit 0 is always 0, bit 1 is 0 if using 4 byte instructions, but is not always 0 if
  // using compressed instructions.  XOR bit 1 with the MSB of index.
  assign PCEIndex = {PCE[Depth+1] ^ PCE[1], PCE[Depth:2]};
  assign ResetPC = `RESET_VECTOR;
  assign PCNextFIndex = reset ? ResetPC[Depth+1:2] : {PCNextF[Depth+1] ^ PCNextF[1], PCNextF[Depth:2]};  
  //assign PCNextFIndex = {PCNextF[Depth+1] ^ PCNextF[1], PCNextF[Depth:2]};  

  flopenr #(Depth) PCEIndexReg(.clk(clk),
        .reset(reset),
        .en(~StallE),
        .d(PCEIndex),
        .q(PCEIndexQ));
  
  // The valid bit must be resetable.
  always_ff @ (posedge clk) begin
    if (reset) begin
      ValidBits <= #1 {TotalDepth{1'b0}};
    end else 
    if (UpdateENQ) begin
      ValidBits[PCEIndexQ] <= #1 ~ UpdateInvalid;
    end
  end
  assign Valid = ValidBits[PCNextFIndexQ];


  flopenr #(1) UpdateENReg(.clk(clk),
     .reset(reset),
     .en(~StallF),
     .d(UpdateEN),
     .q(UpdateENQ));


  flopenr #(Depth) LookupPCIndexReg(.clk(clk),
        .reset(reset),
        .en(~StallF),
        .d(PCNextFIndex),
        .q(PCNextFIndexQ));



  // the BTB contains the target address.
  // Another optimization may be using a PC relative address.
  // *** need to add forwarding.

  // *** optimize for byte write enables

  ram2p1r1wbe #(2**Depth, `XLEN+4) memory(
    .clk, .ce1(~StallF | reset), .ra1(PCNextFIndex), .rd1({InstrClass, BTBPredPCF}),
     .ce2(~StallE), .wa2(PCEIndex), .wd2({InstrClassE, IEUAdrE}), .we2(UpdateEN), .bwe2('1));

endmodule

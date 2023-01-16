///////////////////////////////////////////
// ram2p1r1wb
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 15, 2021
// Modified: 
//
// Purpose: BTB model.  Outputs type of instruction (currently 1 hot encoded. Probably want 
// to encode to reduce storage), valid, target PC.
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

module BTBPredictor
  #(parameter int Depth = 10
    )
  (input  logic             clk,
   input logic              reset,
   input logic              StallF, StallE,
   input logic [`XLEN-1:0]  LookUpPC,
   output logic [`XLEN-1:0] TargetPC,
   output logic [3:0]       InstrClass,
   output logic             Valid,
   // update
   input logic              UpdateEN,
   input logic [`XLEN-1:0]  UpdatePC,
   input logic [`XLEN-1:0]  UpdateTarget,
   input logic [3:0]        UpdateInstrClass,
   input logic              UpdateInvalid
   );

  localparam TotalDepth = 2 ** Depth;
  logic [TotalDepth-1:0]    ValidBits;
  logic [Depth-1:0]         LookUpPCIndex, UpdatePCIndex, LookUpPCIndexQ, UpdatePCIndexQ;
  logic                     UpdateENQ;
  

  // hashing function for indexing the PC
  // We have Depth bits to index, but XLEN bits as the input.
  // bit 0 is always 0, bit 1 is 0 if using 4 byte instructions, but is not always 0 if
  // using compressed instructions.  XOR bit 1 with the MSB of index.
  assign UpdatePCIndex = {UpdatePC[Depth+1] ^ UpdatePC[1], UpdatePC[Depth:2]};
  assign LookUpPCIndex = {LookUpPC[Depth+1] ^ LookUpPC[1], LookUpPC[Depth:2]};  
  

  flopenr #(Depth) UpdatePCIndexReg(.clk(clk),
        .reset(reset),
        .en(~StallE),
        .d(UpdatePCIndex),
        .q(UpdatePCIndexQ));
  
  // The valid bit must be resetable.
  always_ff @ (posedge clk) begin
    if (reset) begin
      ValidBits <= #1 {TotalDepth{1'b0}};
    end else 
    if (UpdateENQ) begin
      ValidBits[UpdatePCIndexQ] <= #1 ~ UpdateInvalid;
    end
  end
  assign Valid = ValidBits[LookUpPCIndexQ];


  flopenr #(1) UpdateENReg(.clk(clk),
     .reset(reset),
     .en(~StallF),
     .d(UpdateEN),
     .q(UpdateENQ));


  flopenr #(Depth) LookupPCIndexReg(.clk(clk),
        .reset(reset),
        .en(~StallF),
        .d(LookUpPCIndex),
        .q(LookUpPCIndexQ));



  // the BTB contains the target address.
  // Another optimization may be using a PC relative address.
  // *** need to add forwarding.

  // *** optimize for byte write enables
  ram2p1r1wb #(Depth, `XLEN+4) memory(.clk(clk),
          .reset(reset),
          .ra1(LookUpPCIndex),
          .rd1({{InstrClass, TargetPC}}),
          .ren1(~StallF),
          .wa2(UpdatePCIndex),
          .wd2({UpdateInstrClass, UpdateTarget}),
          .wen2(UpdateEN),
          .bwe2({4'hF, {`XLEN{1'b1}}})); // *** definitely not right.


endmodule

///////////////////////////////////////////
// fetchbuffer.sv
//
// Written: vkrishna@hmc.edu 3 April 2025
// Modified:
//
// Purpose: Cacheline buffer for instruction fetch
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
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

module instructionbuffer import cvw::*;  #(parameter cvw_t P) (
  input  logic                    clk, reset,
  input  logic                    DisableRead, DisableWrite,
  input  logic  [P.XLEN-1:0]      PCF,          // PC of the instruction
  input  logic  [P.XLEN-1:0]      PCCacheF,     // Address of the instruction
  input  logic  [P.ICACHE_LINELENINBITS-1:0]   FetchData,    // Data fetched from memory
  output logic                    InstrBufferEmpty, InstrBufferFull,
  output logic                    InstrBufferStallD,
  output logic  [31:0]            InstrD,       // Instruction to be decoded
  output logic  [P.XLEN-1:0]      PCD           // PC of the instruction to be decoded
);
  localparam ENTRY_INDEX_BITS = $clog2(P.ICACHE_LINELENINBITS/8);
  localparam TAG_BITS = P.XLEN - ENTRY_INDEX_BITS;
  localparam nop = 32'h00000013;

  logic ReadPtr, WritePtr;
  logic PrevReadPtr; // used to invalidate old cacheline
  // TODO: Check if we still need PrevReadPtr
  logic Spill;
  logic InstrMissing;

  logic [P.XLEN-1:ENTRY_INDEX_BITS] PCFTag;
  logic [ENTRY_INDEX_BITS-1:0] EntryIndex; // used to get the last 6 bits of PCF

  logic                 Valid [1:0];
  logic [TAG_BITS-1:0]  PCTag [1:0];
  logic [P.ICACHE_LINELENINBITS-1:0] Data [1:0];

  assign {PCFTag, EntryIndex} = PCF;

  assign WritePtr = ~ReadPtr;
  assign InstrBufferFull = Valid[0] & Valid[1];
  assign InstrBufferEmpty = ~Valid[0] & ~Valid[1];
  assign InstrMissing = ~((PCFTag == PCTag[0]) | (PCFTag == PCTag[1]));
  assign InstrBufferStallD = InstrBufferEmpty | (Spill & ~InstrBufferFull) | InstrMissing;


  // Don't care if it tag doesn't match either, as InstrMissing will be 1
  assign ReadPtr = (PCFTag == PCTag[1]) ? 1'b1 : 1'b0;

  flopr #(1) PrevReadPtrReg (clk, reset, ReadPtr, PrevReadPtr);


  // The priority for writing is:
  // 1. If the buffer is Empty, write the new Data
  // 2. If the buffer is not Empty, check if the new Data isn't already in the buffer
  // 3. If the new Data is not in the buffer, always write to WritePtr
  // 4. If the new Data is already in the buffer, check ReadPtr to invalidate the old Data
  always_ff @( posedge clk )
    if (reset) begin 
      Valid[0] <= 0;
      Valid[1] <= 0;
    end else if (~DisableWrite & (~InstrBufferFull | InstrMissing)) begin
      Valid[WritePtr] <= 1'b1;
      PCTag[WritePtr] <= PCCacheF[P.XLEN-1:ENTRY_INDEX_BITS];
      Data[WritePtr] <= FetchData;
    end else if (~DisableWrite & (PrevReadPtr != ReadPtr)) 
      Valid[PrevReadPtr] <= 1'b0;
    // TODO: Check if we need to keep the old data in the buffer
    // else begin
    //   Valid <= Valid;
    //   PCTag <= PCTag;
    //   Data <= Data;
    // end

  // Decode Logic:
  always_ff @( posedge clk )
    if (reset) begin
      InstrD <= nop;
      PCD <= PCF;
      Spill <= 1'b0;
    end else if (DisableRead | InstrBufferEmpty) begin
      InstrD <= InstrD;
      PCD <= PCD;
      Spill <= Spill;
    end else begin
      PCD <= PCF;
      // Spill logic
      if (EntryIndex[ENTRY_INDEX_BITS-1:1] == '1) begin 
        if (InstrBufferFull) begin 
          // next cacheline holds the Spill
          Spill <= 1'b0;
          InstrD <= {Data[~ReadPtr][15:0], Data[ReadPtr][P.ICACHE_LINELENINBITS-1:P.ICACHE_LINELENINBITS-16]};
        end else if (Data[ReadPtr][P.ICACHE_LINELENINBITS-15:P.ICACHE_LINELENINBITS-16] != 2'b11) begin 
          // next cacheline doesn't hold Spill but instruction is compressed so doesn't Spill over
          Spill <= 1'b0;
          InstrD <= {16'b0, Data[ReadPtr][P.ICACHE_LINELENINBITS-1:P.ICACHE_LINELENINBITS-16]};
        end else begin
          // next cacheline doesn't hold Spill, but it is needed as the instruction is not compressed
          Spill <= 1'b1;
          InstrD <= InstrD;
        end
      end else begin
        // fetch instruction from the cacheline as needed
        Spill <= 1'b0;
        InstrD <= Data[ReadPtr][EntryIndex*8 +: 32];
      end
    end
endmodule

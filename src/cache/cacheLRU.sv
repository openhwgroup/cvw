///////////////////////////////////////////
// cacheLRU.sv
//
// Written: Ross Thompson ross1728@gmail.com
// Created: 20 July 2021
// Modified: 20 January 2023
//
// Purpose: Implements Pseudo LRU. Tested for Powers of 2.
//
// Documentation: RISC-V System on Chip Design Chapter 7 (Figures 7.8 and 7.15 to 7.18)
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

module cacheLRU
  #(parameter NUMWAYS = 4, SETLEN = 9, OFFSETLEN = 5, NUMLINES = 128) (
  input  logic                clk, 
  input  logic                reset,
  input  logic                FlushStage,
  input  logic                CacheEn,         // Enable the cache memory arrays.  Disable hold read data constant
  input  logic [NUMWAYS-1:0]  HitWay,          // Which way is valid and matches PAdr's tag
  input  logic [NUMWAYS-1:0]  ValidWay,        // Which ways for a particular set are valid, ignores tag
  input  logic [SETLEN-1:0]   CacheSet,        // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   PAdr,            // Physical address 
  input  logic                LRUWriteEn,      // Update the LRU state
  input  logic                SetValid,        // Set the dirty bit in the selected way and set
  input  logic                ClearValid,      // Clear the dirty bit in the selected way and set
  input  logic                InvalidateCache, // Clear all valid bits
  input  logic                FlushCache,      // Flush all dirty lines back to memory
  output logic [NUMWAYS-1:0]  VictimWay        // LRU selects a victim to evict
);

  localparam                           LOGNUMWAYS = $clog2(NUMWAYS);

  logic [NUMWAYS-2:0]                  LRUMemory [NUMLINES-1:0];
  logic [NUMWAYS-2:0]                  CurrLRU;
  logic [NUMWAYS-2:0]                  NextLRU;
  logic [NUMWAYS-1:0]                  Way;
  logic [LOGNUMWAYS-1:0]               WayEncoded;
  logic [NUMWAYS-2:0]                  WayExpanded;
  logic                                AllValid;
  
  genvar                               row;

  /* verilator lint_off UNOPTFLAT */
  // Ross: For some reason verilator does not like this.  I checked and it is not a circular path.
  logic [NUMWAYS-2:0]                  LRUUpdate;
  logic [LOGNUMWAYS-1:0] Intermediate [NUMWAYS-2:0];
  /* verilator lint_on UNOPTFLAT */

  assign AllValid = &ValidWay;

  ///// Update replacement bits.

  // coverage off
  // Excluded from coverage b/c it is untestable without varying NUMWAYS.
  function integer log2 (integer value);
    int val;
    val = value;
    for (log2 = 0; val > 0; log2 = log2+1)
      val = val >> 1;
    return log2;
  endfunction // log2
  // coverage on

  // On a miss we need to ignore HitWay and derive the new replacement bits with the VictimWay.
  mux2 #(NUMWAYS) WayMux(HitWay, VictimWay, SetValid, Way);
  binencoder #(NUMWAYS) encoder(Way, WayEncoded);

  // bit duplication
  // expand HitWay as HitWay[3], {{2}{HitWay[2]}}, {{4}{HitWay[1]}, {{8{HitWay[0]}}, ...
  for(row = 0; row < LOGNUMWAYS; row++) begin
    localparam integer DuplicationFactor = 2**(LOGNUMWAYS-row-1);
    localparam StartIndex = NUMWAYS-2 - DuplicationFactor + 1;
    localparam EndIndex = NUMWAYS-2 - 2 * DuplicationFactor + 2;
    assign WayExpanded[StartIndex : EndIndex] = {{DuplicationFactor}{WayEncoded[row]}};
  end

  genvar               node;
  assign LRUUpdate[NUMWAYS-2] = '1;
  for(node = NUMWAYS-2; node >= NUMWAYS/2; node--) begin : enables
    localparam ctr = NUMWAYS - node - 1;
    localparam ctr_depth = log2(ctr);
    localparam lchild = node - ctr;
    localparam rchild = lchild - 1;
    localparam r = LOGNUMWAYS - ctr_depth;

    // the child node will be updated if its parent was updated and
    // the WayEncoded bit was the correct value.
    // The if statement is only there for coverage since LRUUpdate[root] is always 1.
    if (node == NUMWAYS-2) begin
      assign LRUUpdate[lchild] = ~WayEncoded[r];
      assign LRUUpdate[rchild] = WayEncoded[r];
    end else begin
      assign LRUUpdate[lchild] = LRUUpdate[node] & ~WayEncoded[r];
      assign LRUUpdate[rchild] = LRUUpdate[node] & WayEncoded[r];
    end
  end

  // The root node of the LRU tree will always be selected in LRUUpdate. No mux needed.
  assign NextLRU[NUMWAYS-2] = ~WayExpanded[NUMWAYS-2];
  if (NUMWAYS > 2) mux2 #(1) LRUMuxes[NUMWAYS-3:0](CurrLRU[NUMWAYS-3:0], ~WayExpanded[NUMWAYS-3:0], LRUUpdate[NUMWAYS-3:0], NextLRU[NUMWAYS-3:0]);

  // Compute next victim way.
  for(node = NUMWAYS-2; node >= NUMWAYS/2; node--) begin
    localparam t0 = 2*node - NUMWAYS;
    localparam t1 = t0 + 1;
    assign Intermediate[node] = CurrLRU[node] ? Intermediate[t0] : Intermediate[t1];
  end
  for(node = NUMWAYS/2-1; node >= 0; node--) begin
    localparam int0 = (NUMWAYS/2-1-node)*2;
    localparam int1 = int0 + 1;
    assign Intermediate[node] = CurrLRU[node] ? int1[LOGNUMWAYS-1:0] : int0[LOGNUMWAYS-1:0];
  end

  logic [NUMWAYS-1:0] FirstZero;
  logic [LOGNUMWAYS-1:0] FirstZeroWay;
  logic [LOGNUMWAYS-1:0] VictimWayEnc;
  
  priorityonehot #(NUMWAYS) FirstZeroEncoder(~ValidWay, FirstZero);
  binencoder #(NUMWAYS) FirstZeroWayEncoder(FirstZero, FirstZeroWay);
  mux2 #(LOGNUMWAYS) VictimMux(FirstZeroWay, Intermediate[NUMWAYS-2], AllValid, VictimWayEnc);
  //decoder #(LOGNUMWAYS) decoder (Intermediate[NUMWAYS-2], VictimWay);
  decoder #(LOGNUMWAYS) decoder (VictimWayEnc, VictimWay);

  // LRU storage must be reset for modelsim to run. However the reset value does not actually matter in practice.
  // This is a two port memory.
  // Every cycle must read from CacheSet and each load/store must write the new LRU.
  always_ff @(posedge clk) begin
    if (reset | (InvalidateCache & ~FlushStage)) for (int set = 0; set < NUMLINES; set++) LRUMemory[set] <= '0;
    if(CacheEn) begin
      if(ClearValid & ~FlushStage)
        LRUMemory[PAdr] <= '0;
      else if(LRUWriteEn)
        LRUMemory[PAdr] <= NextLRU;
      if(LRUWriteEn & (PAdr == CacheSet))
        CurrLRU <= #1 NextLRU;
      else 
        CurrLRU <= #1 LRUMemory[CacheSet];
    end
  end

endmodule



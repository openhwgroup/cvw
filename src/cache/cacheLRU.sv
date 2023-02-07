///////////////////////////////////////////
// dcache (data cache)
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

`include "wally-config.vh"

module cacheLRU
  #(parameter NUMWAYS = 4, SETLEN = 9, OFFSETLEN = 5, NUMLINES = 128) (
  input  logic                clk, 
  input  logic                reset, 
  input  logic                FlushStage,      // Pipeline flush of second stage (prevent writes and bus operations)
  input  logic                CacheEn,         // Enable the cache memory arrays.  Disable hold read data constant
  input  logic [NUMWAYS-1:0]  HitWay,          // Which way is valid and matches PAdr's tag
  input  logic [NUMWAYS-1:0]  ValidWay,        // Which ways for a particular set are valid, ignores tag
  input  logic [SETLEN-1:0]   CAdr,            // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   PAdr,            // Physical address 
  input  logic                LRUWriteEn,      // Update the LRU state
  input  logic                SetValid,        // Set the dirty bit in the selected way and set
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
  function integer log2 (integer value);
    for (log2=0; value>0; log2=log2+1)
      value = value>>1;
    return log2;
  endfunction // log2

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

  genvar               r, a, s;
  assign LRUUpdate[NUMWAYS-2] = '1;
  for(s = NUMWAYS-2; s >= NUMWAYS/2; s--) begin : enables
    localparam p = NUMWAYS - s - 1;
    localparam g = log2(p);
    localparam t0 = s - p;
    localparam t1 = t0 - 1;
    localparam r = LOGNUMWAYS - g;
    assign LRUUpdate[t0] = LRUUpdate[s] & ~WayEncoded[r];
    assign LRUUpdate[t1] = LRUUpdate[s] & WayEncoded[r];
  end

  mux2 #(1) LRUMuxes[NUMWAYS-2:0](CurrLRU, ~WayExpanded, LRUUpdate, NextLRU);

  // Compute next victim way.
  for(s = NUMWAYS-2; s >= NUMWAYS/2; s--) begin
    localparam t0 = 2*s - NUMWAYS;
    localparam t1 = t0 + 1;
    assign Intermediate[s] = CurrLRU[s] ? Intermediate[t0] : Intermediate[t1];
  end
  for(s = NUMWAYS/2-1; s >= 0; s--) begin
    localparam int0 = (NUMWAYS/2-1-s)*2;
    localparam int1 = int0 + 1;
    assign Intermediate[s] = CurrLRU[s] ? int1[LOGNUMWAYS-1:0] : int0[LOGNUMWAYS-1:0];
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
  // Every cycle must read from CAdr and each load/store must write the new LRU.
  // this is still wrong.***************************
  always_ff @(posedge clk) begin
    if (reset) for (int set = 0; set < NUMLINES; set++) LRUMemory[set] <= '0;
    if(CacheEn) begin
      if((InvalidateCache | FlushCache) & ~FlushStage) for (int set = 0; set < NUMLINES; set++) LRUMemory[set] <= '0;
      else if (LRUWriteEn & ~FlushStage) begin 
        LRUMemory[PAdr] <= NextLRU;
      end
      if(LRUWriteEn & ~FlushStage & (PAdr == CAdr))
        CurrLRU <= #1 NextLRU;
      else 
        CurrLRU <= #1 LRUMemory[CAdr];
    end
  end

endmodule



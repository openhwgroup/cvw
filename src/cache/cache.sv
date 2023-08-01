///////////////////////////////////////////
// cache.sv
//
// Written: Ross Thompson ross1728@gmail.com
// Created: 7 July 2021
// Modified: 20 January 2023
//
// Purpose: Implements the I$ and D$. Interfaces with requests from IEU and HPTW and ahbcacheinterface
//
// Documentation: RISC-V System on Chip Design Chapter 7 (Figures 7.9, 7.10, and 7.19)
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

module cache import cvw::*; #(parameter cvw_t P,
                              parameter PA_BITS, XLEN, LINELEN,  NUMLINES,  NUMWAYS, LOGBWPL, WORDLEN, MUXINTERVAL, READ_ONLY_CACHE) (
  input  logic                   clk,
  input  logic                   reset,
  input  logic                   Stall,             // Stall the cache, preventing new accesses. In-flight access finished but does not return to READY
  input  logic                   FlushStage,        // Pipeline flush of second stage (prevent writes and bus operations)
  input  logic                   IgnoreRequestTLB,  //
  // cpu side
  input  logic [1:0]             CacheRW,           // [1] Read, [0] Write 
  input  logic [1:0]             CacheAtomic,       // Atomic operation
  input  logic                   FlushCache,        // Flush all dirty lines back to memory
  input  logic                   InvalidateCache,   // Clear all valid bits
  input  logic [11:0]            NextSet,           // Virtual address, but we only use the lower 12 bits.
  input  logic [PA_BITS-1:0]     PAdr,              // Physical address
  input  logic [(WORDLEN-1)/8:0] ByteMask,          // Which bytes to write (D$ only)
  input  logic [WORDLEN-1:0]     CacheWriteData,    // Data to write to cache (D$ only)
  output logic                   CacheCommitted,    // Cache has started bus operation that shouldn't be interrupted
  output logic                   CacheStall,        // Cache stalls pipeline during multicycle operation
  output logic [WORDLEN-1:0]     ReadDataWord,      // Word read from cache (goes to CPU and bus)
  // to performance counters to cpu
  output logic                   CacheMiss,         // Cache miss
  output logic                   CacheAccess,       // Cache access
  // lsu control
  input  logic                   SelHPTW,           // Use PAdr from Hardware Page Table Walker rather than NextSet
  // Bus fsm interface
  input  logic                   CacheBusAck,       // Bus operation completed
  input  logic                   SelBusBeat,        // Word in cache line comes from BeatCount
  input  logic [LOGBWPL-1:0]     BeatCount,         // Beat in burst
  input  logic [LINELEN-1:0]     FetchBuffer,       // Buffer long enough to hold entire cache line arriving from bus
  output logic [1:0]             CacheBusRW,        // [1] Read (cache line fetch) or [0] write bus (cache line writeback)
  output logic [PA_BITS-1:0]     CacheBusAdr        // Address for bus access
);

  // Cache parameters
  localparam                     LINEBYTELEN = LINELEN/8;            // Line length in bytes
  localparam                     OFFSETLEN = $clog2(LINEBYTELEN);    // Number of bits in offset field
  localparam                     SETLEN = $clog2(NUMLINES);          // Number of set bits
  localparam                     SETTOP = SETLEN+OFFSETLEN;          // Number of set plus offset bits
  localparam                     TAGLEN = PA_BITS - SETTOP;          // Number of tag bits
  localparam                     CACHEWORDSPERLINE = LINELEN/WORDLEN;// Number of words in cache line
  localparam                     LOGCWPL = $clog2(CACHEWORDSPERLINE);// Log2 of ^
  localparam                     FLUSHADRTHRESHOLD = NUMLINES - 1;   // Used to determine when flush is complete
  localparam                     LOGLLENBYTES = $clog2(WORDLEN/8);   // Number of bits to address a word


  logic                          SelAdr;
  logic [1:0]                    AdrSelMuxSel;
  logic [SETLEN-1:0]             CacheSet;
  logic [LINELEN-1:0]            LineWriteData;
  logic                          ClearDirty, SetDirty, SetValid;
  logic [LINELEN-1:0]            ReadDataLineWay [NUMWAYS-1:0];
  logic [NUMWAYS-1:0]            HitWay, ValidWay;
  logic                          CacheHit;
  logic [NUMWAYS-1:0]            VictimWay, DirtyWay;
  logic                          LineDirty;
  logic [TAGLEN-1:0]             TagWay [NUMWAYS-1:0];
  logic [TAGLEN-1:0]             Tag;
  logic [SETLEN-1:0]             FlushAdr, NextFlushAdr, FlushAdrP1;
  logic                          FlushAdrCntEn, FlushCntRst;
  logic                          FlushAdrFlag, FlushWayFlag;
  logic [NUMWAYS-1:0]            FlushWay, NextFlushWay;
  logic                          FlushWayCntEn;
  logic                          SelWriteback;
  logic                          LRUWriteEn;
  logic                          SelFlush;
  logic                          ResetOrFlushCntRst;
  logic [LINELEN-1:0]            ReadDataLine, ReadDataLineCache;
  logic                          SelFetchBuffer;
  logic                          CacheEn;
  logic [LINELEN/8-1:0]          LineByteMask;
  logic [$clog2(LINELEN/8) - $clog2(MUXINTERVAL/8) - 1:0] WordOffsetAddr;

  genvar                         index;
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Read Path
  /////////////////////////////////////////////////////////////////////////////////////////////

  // Choose read address (CacheSet).  Normally use NextSet, but use PAdr during stalls
  // and FlushAdr when handling D$ flushes
  // The icache must update to the newest PCNextF on flush as it is probably a trap.  Trap
  // sets PCNextF to XTVEC and the icache must start reading the instruction.
  assign AdrSelMuxSel = {SelFlush, ((SelAdr | SelHPTW) & ~((READ_ONLY_CACHE == 1) & FlushStage))};
  mux3 #(SETLEN) AdrSelMux(NextSet[SETTOP-1:OFFSETLEN], PAdr[SETTOP-1:OFFSETLEN], FlushAdr,
    AdrSelMuxSel, CacheSet);

  // Array of cache ways, along with victim, hit, dirty, and read merging logic
  cacheway #(P, PA_BITS, XLEN, NUMLINES, LINELEN, TAGLEN, OFFSETLEN, SETLEN, READ_ONLY_CACHE) CacheWays[NUMWAYS-1:0](
    .clk, .reset, .CacheEn, .CacheSet, .PAdr, .LineWriteData, .LineByteMask,
    .SetValid, .SetDirty, .ClearDirty, .SelWriteback, .VictimWay,
    .FlushWay, .SelFlush, .ReadDataLineWay, .HitWay, .ValidWay, .DirtyWay, .TagWay, .FlushStage, .InvalidateCache);

  // Select victim way for associative caches
  if(NUMWAYS > 1) begin:vict
    cacheLRU #(NUMWAYS, SETLEN, OFFSETLEN, NUMLINES) cacheLRU(
      .clk, .reset, .CacheEn, .HitWay, .ValidWay, .VictimWay, .CacheSet, .LRUWriteEn,
      .SetValid, .PAdr(PAdr[SETTOP-1:OFFSETLEN]), .InvalidateCache, .FlushCache);
  end else 
    assign VictimWay = 1'b1; // one hot.

  assign CacheHit = |HitWay;
  assign LineDirty = |DirtyWay;

  // ReadDataLineWay is a 2d array of cache line len by number of ways.
  // Need to OR together each way in a bitwise manner.
  // Final part of the AO Mux.  First is the AND in the cacheway.
  or_rows #(NUMWAYS, LINELEN) ReadDataAOMux(.a(ReadDataLineWay), .y(ReadDataLineCache));
  or_rows #(NUMWAYS, TAGLEN) TagAOMux(.a(TagWay), .y(Tag));

  // Data cache needs to choose word offset from PAdr or BeatCount to writeback dirty lines
  if(!READ_ONLY_CACHE) 
    mux2 #(LOGBWPL) WordAdrrMux(.d0(PAdr[$clog2(LINELEN/8) - 1 : $clog2(MUXINTERVAL/8)]), 
      .d1(BeatCount), .s(SelBusBeat),
      .y(WordOffsetAddr)); 
  else 
    assign WordOffsetAddr = PAdr[$clog2(LINELEN/8) - 1 : $clog2(MUXINTERVAL/8)];
  
  // Bypass cache array to save a cycle when finishing a load miss
  mux2 #(LINELEN) EarlyReturnMux(ReadDataLineCache, FetchBuffer, SelFetchBuffer, ReadDataLine);

  // Select word from cache line
  subcachelineread #(LINELEN, WORDLEN, MUXINTERVAL) subcachelineread(
    .PAdr(WordOffsetAddr), .ReadDataLine, .ReadDataWord);
  
  // Bus address for fetch, writeback, or flush writeback
  mux3 #(PA_BITS) CacheBusAdrMux(.d0({PAdr[PA_BITS-1:OFFSETLEN], {OFFSETLEN{1'b0}}}),
    .d1({Tag, PAdr[SETTOP-1:OFFSETLEN], {OFFSETLEN{1'b0}}}),
    .d2({Tag, FlushAdr, {OFFSETLEN{1'b0}}}),
    .s({SelFlush, SelWriteback}), .y(CacheBusAdr));
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Write Path
  /////////////////////////////////////////////////////////////////////////////////////////////
  if(!READ_ONLY_CACHE) begin:WriteSelLogic
    logic [CACHEWORDSPERLINE-1:0]  MemPAdrDecoded;
    logic [LINELEN/8-1:0]          DemuxedByteMask, FetchBufferByteSel;

    // Adjust byte mask from word to cache line
    onehotdecoder #(LOGCWPL) adrdec(.bin(PAdr[LOGCWPL+LOGLLENBYTES-1:LOGLLENBYTES]), .decoded(MemPAdrDecoded));
    for(index = 0; index < 2**LOGCWPL; index++) begin
      assign DemuxedByteMask[(index+1)*(WORDLEN/8)-1:index*(WORDLEN/8)] = MemPAdrDecoded[index] ? ByteMask : '0;
    end
    assign FetchBufferByteSel = SetValid & ~SetDirty ? '1 : ~DemuxedByteMask;  // If load miss set all muxes to 1.

    // Merge write data into fetched cache line for store miss
    for(index = 0; index < LINELEN/8; index++) begin
      mux2 #(8) WriteDataMux(.d0(CacheWriteData[(8*index)%WORDLEN+7:(8*index)%WORDLEN]),
        .d1(FetchBuffer[8*index+7:8*index]), .s(FetchBufferByteSel[index]), .y(LineWriteData[8*index+7:8*index]));
    end
    assign LineByteMask = SetValid ? '1 : SetDirty ? DemuxedByteMask : '0;
  end
  else
    begin:WriteSelLogic
      // No need for this mux if the cache does not handle writes.
      assign LineWriteData = FetchBuffer;
      assign LineByteMask = '1;
    end
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Flush logic
  /////////////////////////////////////////////////////////////////////////////////////////////

  if (!READ_ONLY_CACHE) begin:flushlogic
    // Flush address (line number)
    assign ResetOrFlushCntRst = reset | FlushCntRst;
    flopenr #(SETLEN) FlushAdrReg(clk, ResetOrFlushCntRst, FlushAdrCntEn, FlushAdrP1, NextFlushAdr);
    mux2    #(SETLEN) FlushAdrMux(NextFlushAdr, FlushAdrP1, FlushAdrCntEn, FlushAdr);
    assign FlushAdrP1 = NextFlushAdr + 1'b1;
    assign FlushAdrFlag = (NextFlushAdr == FLUSHADRTHRESHOLD[SETLEN-1:0]);

    // Flush way
    flopenl #(NUMWAYS) FlushWayReg(clk, FlushWayCntEn, ResetOrFlushCntRst, {{NUMWAYS-1{1'b0}}, 1'b1}, NextFlushWay, FlushWay);
    if(NUMWAYS > 1) assign NextFlushWay = {FlushWay[NUMWAYS-2:0], FlushWay[NUMWAYS-1]};
    else            assign NextFlushWay = FlushWay[NUMWAYS-1];
    assign FlushWayFlag = FlushWay[NUMWAYS-1];
  end // block: flushlogic
  else begin:flushlogic
    assign FlushWayFlag = 0;
    assign FlushAdrFlag = 0;
  end
   
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Cache FSM
  /////////////////////////////////////////////////////////////////////////////////////////////
  
  cachefsm #(READ_ONLY_CACHE) cachefsm(.clk, .reset, .CacheBusRW, .CacheBusAck, 
    .FlushStage, .CacheRW, .CacheAtomic, .Stall,
    .CacheHit, .LineDirty, .CacheStall, .CacheCommitted, 
    .CacheMiss, .CacheAccess, .SelAdr, 
    .ClearDirty, .SetDirty, .SetValid, .SelWriteback, .SelFlush,
    .FlushAdrCntEn, .FlushWayCntEn, .FlushCntRst,
    .FlushAdrFlag, .FlushWayFlag, .FlushCache, .SelFetchBuffer,
    .InvalidateCache, .CacheEn, .LRUWriteEn);
endmodule 

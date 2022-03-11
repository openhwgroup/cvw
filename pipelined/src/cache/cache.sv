///////////////////////////////////////////
// cache (data cache)
//
// Written: ross1728@gmail.com July 07, 2021
//          Implements the L1 data cache
//
// Purpose: Storage for data and meta data.
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

module cache #(parameter LINELEN,  NUMLINES,  NUMWAYS, LOGWPL, WORDLEN, MUXINTERVAL, DCACHE) (
  input logic                 clk,
  input logic                 reset,
   // cpu side
  input logic                 CPUBusy,
  input logic [1:0]           RW,
  input logic [1:0]           Atomic,
  input logic                 FlushCache,
  input logic                 InvalidateCacheM,
  input logic [11:0]          NextAdr, // virtual address, but we only use the lower 12 bits.
  input logic [`PA_BITS-1:0]  PAdr, // physical address
  input logic [(`XLEN-1)/8:0] ByteMask,
  input logic [`XLEN-1:0]     FinalWriteData,
  output logic                CacheCommitted,
  output logic                CacheStall,
   // to performance counters to cpu
  output logic                CacheMiss,
  output logic                CacheAccess,
   // lsu control
  input logic                 IgnoreRequestTLB,
  input logic                 IgnoreRequestTrapM, 
  input logic                 Cacheable,
   // Bus fsm interface
  output logic                CacheFetchLine,
  output logic                CacheWriteLine,
  input logic                 CacheBusAck,
  input logic [LOGWPL-1:0]    WordCount,
  input logic                 LSUBusWriteCrit, 
  output logic [`PA_BITS-1:0] CacheBusAdr,
  input logic [LINELEN-1:0]   CacheBusWriteData,
  output logic [WORDLEN-1:0]  ReadDataWord);

  // Cache parameters
  localparam                  LINEBYTELEN = LINELEN/8;
  localparam                  OFFSETLEN = $clog2(LINEBYTELEN);
  localparam                  SETLEN = $clog2(NUMLINES);
  localparam                  SETTOP = SETLEN+OFFSETLEN;
  localparam                  TAGLEN = `PA_BITS - SETTOP;
  localparam                  WORDSPERLINE = LINELEN/`XLEN;
  localparam                  FlushAdrThreshold   = NUMLINES - 1;

  logic                       SelAdr;
  logic [SETLEN-1:0]          RAdr;
  logic [LINELEN-1:0]         CacheWriteData;
  logic                       ClearValid;
  logic                       ClearDirty;
  logic [LINELEN-1:0]         ReadDataLineWay [NUMWAYS-1:0];
  logic [NUMWAYS-1:0]         HitWay, HitWaySaved, HitWayFinal;
  logic                       CacheHit;
  logic                       SetDirty;
  logic                       SetValid;
  logic [NUMWAYS-1:0]         VictimWay;
  logic [NUMWAYS-1:0]         VictimDirtyWay;
  logic                       VictimDirty;
  logic [TAGLEN-1:0]          VictimTagWay [NUMWAYS-1:0];
  logic [TAGLEN-1:0]          VictimTag;
  logic [SETLEN-1:0]          FlushAdr;
  logic [SETLEN-1:0]          FlushAdrP1;
  logic                       FlushAdrCntEn;
  logic                       FlushAdrCntRst;
  logic                       FlushAdrFlag;
  logic                       FlushWayFlag;
  logic [NUMWAYS-1:0]         FlushWay;
  logic [NUMWAYS-1:0]         NextFlushWay;
  logic                       FlushWayCntEn;
  logic                       FlushWayCntRst;  
  logic                       SelEvict;
  logic                       LRUWriteEn;
  logic                       SelFlush;
  logic                       ResetOrFlushAdr, ResetOrFlushWay;
  logic [NUMWAYS-1:0]         SelectedWay;
  logic [NUMWAYS-1:0]         SetValidWay, ClearValidWay, SetDirtyWay, ClearDirtyWay;
  logic [1:0]                 CacheRW, CacheAtomic;
  logic [LINELEN-1:0]         ReadDataLine;
  logic [$clog2(LINELEN/8) - $clog2(MUXINTERVAL/8) - 1:0]          WordOffsetAddr;
  logic                       save, restore;
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Read Path
  /////////////////////////////////////////////////////////////////////////////////////////////

  // Choose read address (RAdr).  Normally use NextAdr, but use PAdr during stalls
  // and FlushAdr when handling D$ flushes  
  mux3 #(SETLEN) AdrSelMux(
    .d0(NextAdr[SETTOP-1:OFFSETLEN]), .d1(PAdr[SETTOP-1:OFFSETLEN]), .d2(FlushAdr),
    .s({SelFlush, SelAdr}), .y(RAdr));

  // Array of cache ways, along with victim, hit, dirty, and read merging logic
  cacheway #(NUMLINES, LINELEN, TAGLEN, OFFSETLEN, SETLEN) CacheWays[NUMWAYS-1:0](
    .clk, .reset, .RAdr, .PAdr, .CacheWriteData, .ByteMask,
    .SetValidWay, .ClearValidWay, .SetDirtyWay, .ClearDirtyWay, .SelEvict, .VictimWay,
    .FlushWay, .SelFlush, .ReadDataLineWay, .HitWay, .VictimDirtyWay, .VictimTagWay, 
    .Invalidate(InvalidateCacheM));
  if(NUMWAYS > 1) begin:vict
    cachereplacementpolicy #(NUMWAYS, SETLEN, OFFSETLEN, NUMLINES) cachereplacementpolicy(
      .clk, .reset, .HitWay(HitWayFinal), .VictimWay, .RAdr, .LRUWriteEn);
  end else assign VictimWay = 1'b1; // one hot.
  assign CacheHit = | HitWay;
  assign VictimDirty = | VictimDirtyWay;
  // ReadDataLineWay is a 2d array of cache line len by number of ways.
  // Need to OR together each way in a bitwise manner.
  // Final part of the AO Mux.  First is the AND in the cacheway.
  or_rows #(NUMWAYS, LINELEN) ReadDataAOMux(.a(ReadDataLineWay), .y(ReadDataLine));
  or_rows #(NUMWAYS, TAGLEN) VictimTagAOMux(.a(VictimTagWay), .y(VictimTag));

  // Because of the sram clocked read when the ieu is stalled the read data maybe lost.
  // There are two ways to resolve. 1. We can replay the read of the sram or we can save
  // the data.  Replay is eaiser but creates a longer critical path.
  // save/restore only wayhit and readdata.
  if(!`REPLAY) begin
    flopenr #(NUMWAYS) wayhitsavereg(clk, save, reset, HitWay, HitWaySaved);
    mux2 #(NUMWAYS) saverestoremux(HitWay, HitWaySaved, restore, HitWayFinal);
  end else assign HitWayFinal = HitWay;

  // like to fix this.
  if(DCACHE) 
    mux2 #(LOGWPL) WordAdrrMux(.d0(PAdr[$clog2(LINELEN/8) - 1 : $clog2(MUXINTERVAL/8)]), 
      .d1(WordCount), .s(LSUBusWriteCrit),
      .y(WordOffsetAddr)); 
  else assign WordOffsetAddr = PAdr[$clog2(LINELEN/8) - 1 : $clog2(MUXINTERVAL/8)];
  
  subcachelineread #(LINELEN, WORDLEN, MUXINTERVAL, LOGWPL) subcachelineread(
    .clk, .reset, .PAdr(WordOffsetAddr), .save, .restore,
    .ReadDataLine, .ReadDataWord);
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Write Path: Write data and address. Muxes between writes from bus and writes from CPU.
  /////////////////////////////////////////////////////////////////////////////////////////////
  mux2 #(LINELEN) WriteDataMux(.d0({WORDSPERLINE{FinalWriteData}}),
		.d1(CacheBusWriteData),	.s(SetValid), .y(CacheWriteData));
  mux3 #(`PA_BITS) CacheBusAdrMux(.d0({PAdr[`PA_BITS-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
		.d1({VictimTag, PAdr[SETTOP-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
		.d2({VictimTag, FlushAdr, {{OFFSETLEN}{1'b0}}}),
		.s({SelFlush, SelEvict}), .y(CacheBusAdr));

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Flush address and way generation during flush
  /////////////////////////////////////////////////////////////////////////////////////////////
  assign ResetOrFlushAdr = reset | FlushAdrCntRst;
  flopenr #(SETLEN) FlushAdrReg(.clk, .reset(ResetOrFlushAdr), .en(FlushAdrCntEn), 
    .d(FlushAdrP1), .q(FlushAdr));
  assign FlushAdrP1 = FlushAdr + 1'b1;
  assign FlushAdrFlag = (FlushAdr == FlushAdrThreshold[SETLEN-1:0]);
  assign ResetOrFlushWay = reset | FlushWayCntRst;
  flopenl #(NUMWAYS) FlushWayReg(.clk, .load(ResetOrFlushWay), .en(FlushWayCntEn), 
    .val({{NUMWAYS-1{1'b0}}, 1'b1}), .d(NextFlushWay), .q(FlushWay));
  assign FlushWayFlag = FlushWay[NUMWAYS-1];
  assign NextFlushWay = {FlushWay[NUMWAYS-2:0], FlushWay[NUMWAYS-1]};

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Write Path: Write Enables
  /////////////////////////////////////////////////////////////////////////////////////////////
  mux3 #(NUMWAYS) selectwaymux(HitWayFinal, VictimWay, FlushWay, 
    {SelFlush, SetValid}, SelectedWay);
  assign SetValidWay = SetValid ? SelectedWay : '0;
  assign ClearValidWay = ClearValid ? SelectedWay : '0;
  assign SetDirtyWay = SetDirty ? SelectedWay : '0;
  assign ClearDirtyWay = ClearDirty ? SelectedWay : '0;
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Cache FSM
  /////////////////////////////////////////////////////////////////////////////////////////////
  assign CacheRW = Cacheable ? RW : 2'b00;
  assign CacheAtomic = Cacheable ? Atomic : 2'b00;
  cachefsm cachefsm(.clk, .reset, .CacheFetchLine, .CacheWriteLine, .CacheBusAck, 
		.CacheRW, .CacheAtomic, .CPUBusy, .IgnoreRequestTLB, .IgnoreRequestTrapM,
 		.CacheHit, .VictimDirty, .CacheStall, .CacheCommitted, 
		.CacheMiss, .CacheAccess, .SelAdr, 
		.ClearValid, .ClearDirty, .SetDirty,
		.SetValid, .SelEvict, .SelFlush,
		.FlushAdrCntEn, .FlushWayCntEn, .FlushAdrCntRst,
		.FlushWayCntRst, .FlushAdrFlag, .FlushWayFlag, .FlushCache,
        .save, .restore,
        .LRUWriteEn);
endmodule 

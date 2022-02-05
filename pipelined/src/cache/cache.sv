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

module cache #(parameter LINELEN,  NUMLINES,  NUMWAYS, DCACHE = 1) (
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
  input logic [`XLEN-1:0]     FinalWriteData,
  output logic                CacheCommitted,
  output logic                CacheStall,
   // to performance counters to cpu
  output logic                CacheMiss,
  output logic                CacheAccess,
  output logic                save, restore,
   // lsu control
  input logic                 IgnoreRequest,
   // Bus fsm interface
  output logic                CacheFetchLine,
  output logic                CacheWriteLine,
  input logic                 CacheBusAck,
  output logic [`PA_BITS-1:0] CacheBusAdr,
  input logic [LINELEN-1:0]   CacheMemWriteData,
  output logic [LINELEN-1:0]  ReadDataLine,
  output logic [`XLEN-1:0]    ReadDataLineSets [(LINELEN/`XLEN)-1:0]);

  // Cache parameters
  localparam  						LINEBYTELEN = LINELEN/8;
  localparam  						OFFSETLEN = $clog2(LINEBYTELEN);
  localparam  						SETLEN = $clog2(NUMLINES);
  localparam              SETTOP = SETLEN+OFFSETLEN;
  localparam  						TAGLEN = `PA_BITS - SETTOP;
  localparam  						WORDSPERLINE = LINELEN/`XLEN;
  localparam  						LOGWPL = $clog2(WORDSPERLINE);
  localparam  						LOGXLENBYTES = $clog2(`XLEN/8);
  localparam  						FlushAdrThreshold   = NUMLINES - 1;

  logic [1:0] 								SelAdr;
  logic [SETLEN-1:0] 						RAdr;
  logic [LINELEN-1:0] 						SRAMWriteData;
  logic 									SetValid, ClearValid;
  logic 									SetDirty, ClearDirty;
  logic [LINELEN-1:0] 						ReadDataLineWay [NUMWAYS-1:0];
  logic [NUMWAYS-1:0] 						WayHit;
  logic 									CacheHit;
  logic [WORDSPERLINE-1:0] 					SRAMWordEnable;
  logic 									SRAMWordWriteEnable;
  logic 									SRAMLineWriteEnable;
  logic [NUMWAYS-1:0] 						SRAMLineWayWriteEnable;
  logic [NUMWAYS-1:0] 						SRAMWayWriteEnable;
  logic [NUMWAYS-1:0]             SRAMWordWayWriteEnable;
  logic [NUMWAYS-1:0] 						VictimWay;
  logic [NUMWAYS-1:0] 						VictimDirtyWay;
  logic 									VictimDirty;
  logic [2**LOGWPL-1:0] 					MemPAdrDecoded;
  logic [TAGLEN-1:0] 						VictimTagWay [NUMWAYS-1:0];
  logic [TAGLEN-1:0] 						VictimTag;
  logic [SETLEN-1:0] 						FlushAdr;
  logic [SETLEN-1:0] 						FlushAdrP1;
  logic 									FlushAdrCntEn;
  logic 									FlushAdrCntRst;
  logic 									FlushAdrFlag;
  logic 									FlushWayFlag;
  logic [NUMWAYS-1:0] 						FlushWay;
  logic [NUMWAYS-1:0] 						NextFlushWay;
  logic 									FlushWayCntEn;
  logic 									FlushWayCntRst;  
  logic 									VDWriteEnable;
  logic 									SelEvict;
  logic 									LRUWriteEn;
  logic [NUMWAYS-1:0] 						VDWriteEnableWay;
  logic 									SelFlush;
  logic                                     ResetOrFlushAdr, ResetOrFlushWay;
  logic [NUMWAYS-1:0]                       WayHitSaved, WayHitRaw;
  logic [LINELEN-1:0]                       ReadDataLineRaw, ReadDataLineSaved;
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Read Path
  /////////////////////////////////////////////////////////////////////////////////////////////

  // Choose read address (RAdr).  Normally use NextAdr, but use PAdr during stalls
  // and FlushAdr when handling D$ flushes  
  mux3 #(SETLEN) AdrSelMux(
    .d0(NextAdr[SETTOP-1:OFFSETLEN]), .d1(PAdr[SETTOP-1:OFFSETLEN]), .d2(FlushAdr),
		.s(SelAdr), .y(RAdr));

  // Array of cache ways, along with victim, hit, dirty, and read merging logic
  cacheway #(NUMLINES, LINELEN, TAGLEN, OFFSETLEN, SETLEN) CacheWays[NUMWAYS-1:0](
    .clk, .reset, .RAdr, .PAdr,
		.WriteEnable(SRAMWayWriteEnable),
		.VDWriteEnable(VDWriteEnableWay),
		.WriteWordEnable(SRAMWordEnable),
		.TagWriteEnable(SRAMLineWayWriteEnable), 
		.WriteData(SRAMWriteData),
		.SetValid, .ClearValid, .SetDirty, .ClearDirty, .SelEvict, .Victim(VictimWay), .Flush(FlushWay), 
        .SelFlush,
		.SelectedReadDataLine(ReadDataLineWay), .WayHit(WayHitRaw), .VictimDirty(VictimDirtyWay), .VictimTag(VictimTagWay),
		.InvalidateAll(InvalidateCacheM));
  if(NUMWAYS > 1) begin:vict
    cachereplacementpolicy #(NUMWAYS, SETLEN, OFFSETLEN, NUMLINES) cachereplacementpolicy(
      .clk, .reset, .WayHit, .VictimWay, .PAdr(PAdr[SETTOP-1:OFFSETLEN]), .RAdr, .LRUWriteEn);
  end else assign VictimWay = 1'b1; // one hot.
  assign CacheHit = | WayHit;
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
  flopenr #(NUMWAYS) wayhitsavereg(clk, save, reset, WayHitRaw, WayHitSaved);
  mux2 #(NUMWAYS) saverestoremux(WayHitRaw, WayHitSaved, restore, WayHit);
  

  // Convert the Read data bus ReadDataSelectWay into sets of XLEN so we can
  // easily build a variable input mux.
  // *** move this to LSU and IFU, also remove mux from busdp into LSU. 
  // *** give this a module name to match block diagram
  genvar index;
  if(DCACHE == 1) begin: readdata
    // *** only here temporary
    for (index = 0; index < WORDSPERLINE; index++) begin:readdatalinesetsmux
		  assign ReadDataLineSets[index] = ReadDataLine[((index+1)*`XLEN)-1: (index*`XLEN)];
    end
  end else begin: readdata
  end

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Write Path: Write Enables
  /////////////////////////////////////////////////////////////////////////////////////////////
 
  // *** Ross considering restructuring
  onehotdecoder #(LOGWPL) adrdec(
    .bin(PAdr[LOGWPL+LOGXLENBYTES-1:LOGXLENBYTES]), .decoded(MemPAdrDecoded));
  assign SRAMWordEnable = SRAMLineWriteEnable ? '1 : MemPAdrDecoded; // OR
  assign SRAMLineWayWriteEnable = SRAMLineWriteEnable ? VictimWay : '0; // AND
  assign SRAMWordWayWriteEnable = SRAMWordWriteEnable ? WayHit : '0; // AND
  mux2 #(NUMWAYS) WriteEnableMux(.d0(SRAMWordWayWriteEnable), .d1(VictimWay), 
    .s(SRAMLineWriteEnable), .y(SRAMWayWriteEnable));
  mux2 #(LINELEN) WriteDataMux(.d0({WORDSPERLINE{FinalWriteData}}),
		.d1(CacheMemWriteData),	.s(SRAMLineWriteEnable), .y(SRAMWriteData));
  mux3 #(`PA_BITS) CacheBusAdrMux(.d0({PAdr[`PA_BITS-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
		.d1({VictimTag, PAdr[SETTOP-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
		.d2({VictimTag, FlushAdr, {{OFFSETLEN}{1'b0}}}),
		.s({SelFlush, SelEvict}),
		.y(CacheBusAdr));

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Flush address and way generation during flush
  /////////////////////////////////////////////////////////////////////////////////////////////

  assign ResetOrFlushAdr = reset | FlushAdrCntRst;
  flopenr #(SETLEN) FlushAdrReg(.clk, .reset(ResetOrFlushAdr),
			  .en(FlushAdrCntEn), .d(FlushAdrP1), .q(FlushAdr));
  assign FlushAdrP1 = FlushAdr + 1'b1;
  assign FlushAdrFlag = (FlushAdr == FlushAdrThreshold[SETLEN-1:0]);

  assign ResetOrFlushWay = reset | FlushWayCntRst;
  flopenl #(NUMWAYS) FlushWayReg(.clk, .load(ResetOrFlushWay),
			  .en(FlushWayCntEn), .val({{NUMWAYS-1{1'b0}}, 1'b1}),
			  .d(NextFlushWay), .q(FlushWay));
  assign FlushWayFlag = FlushWay[NUMWAYS-1];
  assign VDWriteEnableWay = FlushWay & {NUMWAYS{VDWriteEnable}};
  assign NextFlushWay = {FlushWay[NUMWAYS-2:0], FlushWay[NUMWAYS-1]};

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Cache FSM
  /////////////////////////////////////////////////////////////////////////////////////////////

  cachefsm cachefsm(.clk, .reset, .CacheFetchLine, .CacheWriteLine, .CacheBusAck, 
		.RW, .Atomic, .CPUBusy, .IgnoreRequest,
 		.CacheHit, .VictimDirty, .CacheStall, .CacheCommitted, 
		.CacheMiss, .CacheAccess, .SelAdr, .SetValid, 
		.ClearValid, .SetDirty, .ClearDirty, .SRAMWordWriteEnable,
		.SRAMLineWriteEnable, .SelEvict, .SelFlush,
		.FlushAdrCntEn, .FlushWayCntEn, .FlushAdrCntRst,
		.FlushWayCntRst, .FlushAdrFlag, .FlushWayFlag, .FlushCache,
        .save, .restore,
		.VDWriteEnable, .LRUWriteEn);
endmodule 

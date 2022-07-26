///////////////////////////////////////////
// dcache (data cache) fsm
//
// Written: ross1728@gmail.com August 25, 2021
//          Implements the L1 data cache fsm
//
// Purpose: Controller for the dcache fsm
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

module cachefsm
  (input logic clk,
   input logic       reset,
   // inputs from IEU
   input logic [1:0] CacheRW,
   input logic [1:0] CacheAtomic,
   input logic       FlushCache,
   input logic       InvalidateCache,
   // hazard inputs
   input logic       CPUBusy,
   // interlock fsm
   input logic       IgnoreRequestTLB,
   input logic       IgnoreRequestTrapM,
   input logic       TrapM,
   // Bus inputs
   input logic       CacheBusAck,
   // dcache internals
   input logic       CacheHit,
   input logic       VictimDirty,
   input logic       FlushAdrFlag,
   input logic       FlushWayFlag, 
  
   // hazard outputs
   output logic      CacheStall,
   // counter outputs
   output logic      CacheMiss,
   output logic      CacheAccess,
   // Bus outputs
   output logic      CacheCommitted,
   output logic      CacheWriteLine,
   output logic      CacheFetchLine,

   // dcache internals
   output logic      SelAdr,
   output logic      ClearValid,
   output logic      ClearDirty,
   output logic      SetDirty,
   output logic      SetValid,
   output logic      SelEvict,
   output logic      LRUWriteEn,
   output logic      SelFlush,
   output logic      FlushAdrCntEn,
   output logic      FlushWayCntEn, 
   output logic      FlushAdrCntRst,
   output logic      FlushWayCntRst,
   output logic      SelBusBuffer, 
   output logic      SRAMEnable);
  
  logic               resetDelay;
  logic               AMO;
  logic               DoAMO, DoRead, DoWrite, DoFlush;
  logic               DoAnyUpdateHit, DoAnyHit;
  logic               DoAnyMiss;
  logic               FlushFlag, FlushWayAndNotAdrFlag;
    
  typedef enum logic [3:0]		  {STATE_READY, // hit states
                                   // miss states
					               STATE_MISS_FETCH_WDV,
					               STATE_MISS_EVICT_DIRTY_START,
					               STATE_MISS_EVICT_DIRTY,
					               STATE_MISS_WRITE_CACHE_LINE,
                                   // flush cache 
					               STATE_FLUSH,
					               STATE_FLUSH_CHECK,
					               STATE_FLUSH_INCR,
					               STATE_FLUSH_WRITE_BACK,
					               STATE_FLUSH_CLEAR_DIRTY} statetype;

  (* mark_debug = "true" *) statetype CurrState, NextState;
  logic               IgnoreRequest;
  assign IgnoreRequest = IgnoreRequestTLB | IgnoreRequestTrapM;

  // if the command is used in the READY state then the cache needs to be able to supress
  // using both IgnoreRequestTLB and IgnoreRequestTrapM.  Otherwise we can just use IgnoreRequestTLB.

  assign DoFlush = FlushCache & ~IgnoreRequestTrapM; // do NOT suppress flush on DTLBMissM. Does not depend on address translation.
  assign AMO = CacheAtomic[1] & (&CacheRW);
  assign DoAMO = AMO & ~IgnoreRequest; 
  assign DoRead = CacheRW[1] & ~IgnoreRequest; 
  assign DoWrite = CacheRW[0] & ~IgnoreRequest; 

  assign DoAnyMiss = (DoAMO | DoRead | DoWrite) & ~CacheHit & ~InvalidateCache;
  assign DoAnyUpdateHit = (DoAMO | DoWrite) & CacheHit;
  assign DoAnyHit = DoAnyUpdateHit | (DoRead & CacheHit);  
  assign FlushFlag = FlushAdrFlag & FlushWayFlag;

  // outputs for the performance counters.
  assign CacheAccess = (DoAMO | DoRead | DoWrite) & CurrState == STATE_READY;
  assign CacheMiss = CacheAccess & ~CacheHit;

  // special case on reset. When the fsm first exists reset the
  // PCNextF will no longer be pointing to the correct address.
  // But PCF will be the reset vector.
  flop #(1) resetDelayReg(.clk, .d(reset), .q(resetDelay));

  always_ff @(posedge clk)
    if (reset)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;  
  
  always_comb begin
    NextState = STATE_READY;
    case (CurrState)
      STATE_READY: if(IgnoreRequest | InvalidateCache) NextState = STATE_READY;
                   else if(DoFlush)                  NextState = STATE_FLUSH;
                   else if(DoAnyMiss)                NextState = STATE_MISS_FETCH_WDV; // fetch first, then eviction is necessary. see delay in lru read/write path.
                   else                              NextState = STATE_READY;
      STATE_MISS_FETCH_WDV: if(CacheBusAck & ~VictimDirty) NextState = STATE_MISS_WRITE_CACHE_LINE;
                            else if(CacheBusAck & VictimDirty) NextState = STATE_MISS_EVICT_DIRTY_START;
                            else                     NextState = STATE_MISS_FETCH_WDV;
      STATE_MISS_WRITE_CACHE_LINE:                   NextState = STATE_READY; // cpu_busy not needed. load misses have the property of reading from the bus buffer rather than sram.
      STATE_MISS_EVICT_DIRTY: if(CacheBusAck)        NextState = STATE_MISS_WRITE_CACHE_LINE;
                              else                   NextState = STATE_MISS_EVICT_DIRTY;
      STATE_MISS_EVICT_DIRTY_START:                  NextState = STATE_MISS_EVICT_DIRTY; // eviction needs a delay as the bus fsm does not correctly handle sending the write command at the same time as getting back the bus ack.
	  STATE_FLUSH:                                   NextState = STATE_FLUSH_CHECK;
      STATE_FLUSH_CHECK: if(VictimDirty)             NextState = STATE_FLUSH_WRITE_BACK;
                         else if(FlushFlag)          NextState = STATE_READY;
                         else if(FlushWayFlag)       NextState = STATE_FLUSH_INCR;
                         else                        NextState = STATE_FLUSH_CHECK;
	  STATE_FLUSH_INCR:                              NextState = STATE_FLUSH_CHECK;
      STATE_FLUSH_WRITE_BACK: if(CacheBusAck)        NextState = STATE_FLUSH_CLEAR_DIRTY;
                              else                   NextState = STATE_FLUSH_WRITE_BACK;
      STATE_FLUSH_CLEAR_DIRTY: if(FlushFlag)         NextState = STATE_READY;
                               else if(FlushWayFlag) NextState = STATE_FLUSH_INCR;
                               else                  NextState = STATE_FLUSH_CHECK;
      default:                                       NextState = STATE_READY;
    endcase
  end

  // com back to CPU
  assign CacheCommitted = CurrState != STATE_READY;
  assign CacheStall = (CurrState == STATE_READY & (DoFlush | DoAnyMiss)) | 
                      (CurrState == STATE_MISS_FETCH_WDV) |
                      (CurrState == STATE_MISS_EVICT_DIRTY_START) |
                      (CurrState == STATE_MISS_EVICT_DIRTY) |
                      (CurrState == STATE_MISS_WRITE_CACHE_LINE & ~(AMO | CacheRW[0])) |  // this cycle writes the sram, must keep stalling so the next cycle can read the next hit/miss unless its a write.
                      (CurrState == STATE_FLUSH) |
                      (CurrState == STATE_FLUSH_CHECK & ~(FlushFlag)) |
                      (CurrState == STATE_FLUSH_INCR) |
                      (CurrState == STATE_FLUSH_WRITE_BACK) |
                      (CurrState == STATE_FLUSH_CLEAR_DIRTY & ~(FlushFlag));
  // write enables internal to cache
  assign SetValid = CurrState == STATE_MISS_WRITE_CACHE_LINE;
  assign SetDirty = (CurrState == STATE_READY & DoAnyUpdateHit) |
                          (CurrState == STATE_MISS_WRITE_CACHE_LINE & (AMO | CacheRW[0]));
  assign ClearValid = '0;
  assign ClearDirty = (CurrState == STATE_MISS_WRITE_CACHE_LINE & ~(AMO | CacheRW[0])) |
                      (CurrState == STATE_FLUSH_CLEAR_DIRTY);
  assign LRUWriteEn = (CurrState == STATE_READY & DoAnyHit) |
                      (CurrState == STATE_MISS_WRITE_CACHE_LINE);
  // Flush and eviction controls
  assign SelEvict = (CurrState == STATE_MISS_EVICT_DIRTY_START) |
                    (CurrState == STATE_MISS_EVICT_DIRTY);
  assign SelFlush = (CurrState == STATE_FLUSH) | (CurrState == STATE_FLUSH_CHECK) |
                    (CurrState == STATE_FLUSH_INCR) | (CurrState == STATE_FLUSH_WRITE_BACK) |
                    (CurrState == STATE_FLUSH_CLEAR_DIRTY);
  assign FlushWayAndNotAdrFlag = FlushWayFlag & ~FlushAdrFlag;
  assign FlushAdrCntEn = (CurrState == STATE_FLUSH_CHECK & ~VictimDirty & FlushWayAndNotAdrFlag) |
                         (CurrState == STATE_FLUSH_CLEAR_DIRTY & FlushWayAndNotAdrFlag);
  assign FlushWayCntEn = (CurrState == STATE_FLUSH_CHECK & ~VictimDirty & ~(FlushFlag)) |
                         (CurrState == STATE_FLUSH_CLEAR_DIRTY & ~FlushFlag);
  assign FlushAdrCntRst = (CurrState == STATE_READY);
  assign FlushWayCntRst = (CurrState == STATE_READY) | (CurrState == STATE_FLUSH_INCR);
  // Bus interface controls
  assign CacheFetchLine = (CurrState == STATE_READY & DoAnyMiss);
    assign CacheWriteLine = (CurrState == STATE_MISS_EVICT_DIRTY_START) |
                          (CurrState == STATE_FLUSH_CHECK & VictimDirty);
  // **** can this be simplified?
  assign SelAdr = (CurrState == STATE_READY & (IgnoreRequestTLB & ~TrapM)) | // Ignore Request is needed on TLB miss.
                  // use the raw requests as we don't want IgnoreRequestTrapM in the critical path
                  (CurrState == STATE_READY & ((AMO | CacheRW[0]) & CacheHit)) | // changes if store delay hazard removed
                  (CurrState == STATE_READY & (CacheRW[1] & CacheHit) & (CPUBusy & `REPLAY)) |
                  (CurrState == STATE_READY & (DoAnyMiss)) |
                  (CurrState == STATE_MISS_FETCH_WDV) |
                  (CurrState == STATE_MISS_EVICT_DIRTY) |
                  (CurrState == STATE_MISS_EVICT_DIRTY_START) |
                  (CurrState == STATE_MISS_WRITE_CACHE_LINE) |
                  resetDelay;

  assign SelBusBuffer = CurrState == STATE_MISS_WRITE_CACHE_LINE;
  assign SRAMEnable = (CurrState == STATE_READY & ~CPUBusy | CacheStall) | (CurrState != STATE_READY) | reset;
  //assign SRAMEnable = 1;
                       
endmodule // cachefsm

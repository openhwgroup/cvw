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
   input logic        reset,
   // inputs from IEU
   input logic        FlushStage,
   input logic [1:0]  CacheRW,
   input logic [1:0]  CacheAtomic,
   input logic        FlushCache,
   input logic        InvalidateCache,
   // hazard inputs
   input logic        CPUBusy,
   // Bus inputs
   input logic        CacheBusAck,
   // dcache internals
   input logic        CacheHit,
   input logic        LineDirty,
   input logic        FlushAdrFlag,
   input logic        FlushWayFlag, 
  
   // hazard outputs
   output logic       CacheStall,
   // counter outputs
   output logic       CacheMiss,
   output logic       CacheAccess,
   // Bus outputs
   output logic       CacheCommitted,
   output logic [1:0] CacheBusRW,

   // dcache internals
   output logic       SelAdr,
   output logic       ClearValid,
   output logic       ClearDirty,
   output logic       SetDirty,
   output logic       SetValid,
   output logic       SelEvict,
   output logic       LRUWriteEn,
   output logic       SelFlush,
   output logic       FlushAdrCntEn,
   output logic       FlushWayCntEn, 
   output logic       FlushAdrCntRst,
   output logic       FlushWayCntRst,
   output logic       SelFetchBuffer, 
   output logic       ce);
  
  logic               resetDelay;
  logic               AMO, StoreAMO;
  logic               AnyUpdateHit, AnyHit;
  logic               AnyMiss;
  logic               FlushFlag, FlushWayAndNotAdrFlag;
    
  typedef enum logic [3:0]		  {STATE_READY, // hit states
                                   // miss states
					               STATE_MISS_FETCH_WDV,
					               STATE_MISS_EVICT_DIRTY,
					               STATE_MISS_WRITE_CACHE_LINE,
                                   STATE_MISS_READ_DELAY,  // required for back to back reads. structural hazard on writting SRAM
                                   // flush cache 
					               STATE_FLUSH,
					               STATE_FLUSH_CHECK,
					               STATE_FLUSH_INCR,
					               STATE_FLUSH_WRITE_BACK} statetype;

  (* mark_debug = "true" *) statetype CurrState, NextState;

  assign AMO = CacheAtomic[1] & (&CacheRW);
  assign StoreAMO = AMO | CacheRW[0];

  assign AnyMiss = (StoreAMO | CacheRW[1]) & ~CacheHit & ~InvalidateCache;
  assign AnyUpdateHit = (StoreAMO) & CacheHit;
  assign AnyHit = AnyUpdateHit | (CacheRW[1] & CacheHit);  
  assign FlushFlag = FlushAdrFlag & FlushWayFlag;

  // outputs for the performance counters.
  assign CacheAccess = (AMO | CacheRW[1] | CacheRW[0]) & CurrState == STATE_READY;
  assign CacheMiss = CacheAccess & ~CacheHit;

  // special case on reset. When the fsm first exists reset the
  // PCNextF will no longer be pointing to the correct address.
  // But PCF will be the reset vector.
  flop #(1) resetDelayReg(.clk, .d(reset), .q(resetDelay));

  always_ff @(posedge clk)
    if (reset | FlushStage)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;  
  
  always_comb begin
    NextState = STATE_READY;
    case (CurrState)
      STATE_READY: if(InvalidateCache)         NextState = STATE_READY;
                   else if(FlushCache)                            NextState = STATE_FLUSH;
      // Delayed LRU update.  Cannot check if victim line is dirty on this cycle.
      // To optimize do the fetch first, then eviction if necessary.
                   else if(AnyMiss & ~LineDirty)           NextState = STATE_MISS_FETCH_WDV;
                   else if(AnyMiss & LineDirty)            NextState = STATE_MISS_EVICT_DIRTY;
                   else                                        NextState = STATE_READY;
      STATE_MISS_FETCH_WDV: if(CacheBusAck)                    NextState = STATE_MISS_WRITE_CACHE_LINE;
                            else                               NextState = STATE_MISS_FETCH_WDV;
      //STATE_MISS_WRITE_CACHE_LINE:                             NextState = STATE_READY;
      STATE_MISS_WRITE_CACHE_LINE:                             NextState = STATE_MISS_READ_DELAY;
                                   //else                        NextState = STATE_READY;
      STATE_MISS_READ_DELAY: if(CPUBusy)                       NextState = STATE_MISS_READ_DELAY;
                             else                              NextState = STATE_READY;
      STATE_MISS_EVICT_DIRTY: if(CacheBusAck)                  NextState = STATE_MISS_FETCH_WDV;
                              else                             NextState = STATE_MISS_EVICT_DIRTY;
      // eviction needs a delay as the bus fsm does not correctly handle sending the write command at the same time as getting back the bus ack.
	  STATE_FLUSH:                                             NextState = STATE_FLUSH_CHECK;
      STATE_FLUSH_CHECK: if(LineDirty)                       NextState = STATE_FLUSH_WRITE_BACK;
                         else if(FlushFlag)                    NextState = STATE_READY;
                         else if(FlushWayFlag)                 NextState = STATE_FLUSH_INCR;
                         else                                  NextState = STATE_FLUSH_CHECK;
	  STATE_FLUSH_INCR:                                        NextState = STATE_FLUSH_CHECK;
      STATE_FLUSH_WRITE_BACK: if(CacheBusAck) begin
                                if(FlushFlag)                  NextState = STATE_READY;
                                else if(FlushWayFlag)          NextState = STATE_FLUSH_INCR;
                                else                           NextState = STATE_FLUSH_CHECK;
      end                       else                           NextState = STATE_FLUSH_WRITE_BACK;
      default:                                                 NextState = STATE_READY;
    endcase
  end

  // com back to CPU
  assign CacheCommitted = CurrState != STATE_READY;
  assign CacheStall = (CurrState == STATE_READY & (FlushCache | AnyMiss)) | 
                      (CurrState == STATE_MISS_FETCH_WDV) |
                      (CurrState == STATE_MISS_EVICT_DIRTY) |
                      (CurrState == STATE_MISS_WRITE_CACHE_LINE & ~(StoreAMO)) |  // this cycle writes the sram, must keep stalling so the next cycle can read the next hit/miss unless its a write.
                      (CurrState == STATE_FLUSH) |
                      (CurrState == STATE_FLUSH_CHECK & ~(FlushFlag)) |
                      (CurrState == STATE_FLUSH_INCR) |
                      (CurrState == STATE_FLUSH_WRITE_BACK & ~(FlushFlag) & CacheBusAck);
  // write enables internal to cache
  assign SetValid = CurrState == STATE_MISS_WRITE_CACHE_LINE;
  assign SetDirty = (CurrState == STATE_READY & AnyUpdateHit) |
                    (CurrState == STATE_MISS_WRITE_CACHE_LINE & (StoreAMO));
  assign ClearValid = '0;
  assign ClearDirty = (CurrState == STATE_MISS_WRITE_CACHE_LINE & ~(StoreAMO)) |
                      (CurrState == STATE_FLUSH_WRITE_BACK & CacheBusAck);
  assign LRUWriteEn = (CurrState == STATE_READY & AnyHit) |
                      (CurrState == STATE_MISS_WRITE_CACHE_LINE);
  // Flush and eviction controls
  assign SelEvict = (CurrState == STATE_MISS_EVICT_DIRTY & ~CacheBusAck) |
                    (CurrState == STATE_READY & AnyMiss & LineDirty);
  assign SelFlush = (CurrState == STATE_FLUSH) | (CurrState == STATE_FLUSH_CHECK) |
                    (CurrState == STATE_FLUSH_INCR) | (CurrState == STATE_FLUSH_WRITE_BACK);
  assign FlushWayAndNotAdrFlag = FlushWayFlag & ~FlushAdrFlag;
  assign FlushAdrCntEn = (CurrState == STATE_FLUSH_CHECK & ~LineDirty & FlushWayAndNotAdrFlag) |
                         (CurrState == STATE_FLUSH_WRITE_BACK & FlushWayAndNotAdrFlag & CacheBusAck);                         
  assign FlushWayCntEn = (CurrState == STATE_FLUSH_CHECK & ~LineDirty & ~(FlushFlag)) |
                         (CurrState == STATE_FLUSH_WRITE_BACK & ~FlushFlag & CacheBusAck);
  assign FlushAdrCntRst = (CurrState == STATE_READY);
  assign FlushWayCntRst = (CurrState == STATE_READY) | (CurrState == STATE_FLUSH_INCR);
  // Bus interface controls
  assign CacheBusRW[1] = (CurrState == STATE_READY & AnyMiss & ~LineDirty) | 
                         (CurrState == STATE_MISS_FETCH_WDV & ~CacheBusAck) | 
                         (CurrState == STATE_MISS_EVICT_DIRTY & CacheBusAck);
//  assign CacheBusRW[1] = CurrState == STATE_READY & AnyMiss;
  assign CacheBusRW[0] = (CurrState == STATE_READY & AnyMiss & LineDirty) |
                          (CurrState == STATE_MISS_EVICT_DIRTY & ~CacheBusAck) |
                          (CurrState == STATE_FLUSH_WRITE_BACK & ~CacheBusAck) |
                          (CurrState == STATE_FLUSH_CHECK & LineDirty);
//  assign CacheBusRW[0] = (CurrState == STATE_MISS_FETCH_WDV & CacheBusAck & LineDirty) |
//                          (CurrState == STATE_FLUSH_CHECK & VictimDirty);
  // **** can this be simplified?
  assign SelAdr = (CurrState == STATE_READY & ((StoreAMO) & CacheHit)) | // changes if store delay hazard removed
                  (CurrState == STATE_READY & (AnyMiss)) |
                  (CurrState == STATE_MISS_FETCH_WDV) |
                  (CurrState == STATE_MISS_EVICT_DIRTY) |
                  (CurrState == STATE_MISS_WRITE_CACHE_LINE) |
                  resetDelay;

  assign SelFetchBuffer = CurrState == STATE_MISS_WRITE_CACHE_LINE | CurrState == STATE_MISS_READ_DELAY;
  assign ce = (CurrState == STATE_READY & ~CPUBusy | CacheStall) | (CurrState != STATE_READY) | reset;
                       
endmodule // cachefsm

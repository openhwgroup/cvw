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
   input logic        Stall,
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
   output logic       SelWriteback,
   output logic       LRUWriteEn,
   output logic       SelFlush,
   output logic       FlushAdrCntEn,
   output logic       FlushWayCntEn, 
   output logic       FlushCntRst,
   output logic       SelFetchBuffer, 
   output logic       CacheEn);
  
  logic               resetDelay;
  logic               AMO, StoreAMO;
  logic               AnyUpdateHit, AnyHit;
  logic               AnyMiss;
  logic               FlushFlag;
    
  typedef enum logic [3:0]		  {STATE_READY, // hit states
                                   // miss states
					               STATE_FETCH,
					               STATE_WRITEBACK,
					               STATE_WRITE_LINE,
                                   STATE_READ_HOLD,  // required for back to back reads. structural hazard on writting SRAM
                                   // flush cache 
					               STATE_FLUSH,
					               STATE_FLUSH_WRITEBACK} statetype;

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
      STATE_READY: if(InvalidateCache)                     NextState = STATE_READY;
                   else if(FlushCache)                     NextState = STATE_FLUSH;
      // Delayed LRU update.  Cannot check if victim line is dirty on this cycle.
      // To optimize do the fetch first, then eviction if necessary.
                   else if(AnyMiss & ~LineDirty)           NextState = STATE_FETCH;
                   else if(AnyMiss & LineDirty)            NextState = STATE_WRITEBACK;
                   else                                    NextState = STATE_READY;
      STATE_FETCH: if(CacheBusAck)                NextState = STATE_WRITE_LINE;
                            else                           NextState = STATE_FETCH;
      STATE_WRITE_LINE:                         NextState = STATE_READ_HOLD;
      STATE_READ_HOLD: if(Stall)                     NextState = STATE_READ_HOLD;
                             else                          NextState = STATE_READY;
      STATE_WRITEBACK: if(CacheBusAck)              NextState = STATE_FETCH;
                              else                         NextState = STATE_WRITEBACK;
      // eviction needs a delay as the bus fsm does not correctly handle sending the write command at the same time as getting back the bus ack.
      STATE_FLUSH: if(LineDirty)                           NextState = STATE_FLUSH_WRITEBACK;
	               else if (FlushFlag)                     NextState = STATE_READ_HOLD;
	               else                                    NextState = STATE_FLUSH;
	  STATE_FLUSH_WRITEBACK: if(CacheBusAck & ~FlushFlag) NextState = STATE_FLUSH;
	                          else if(CacheBusAck)         NextState = STATE_READ_HOLD;
	                          else                         NextState = STATE_FLUSH_WRITEBACK;
      default:                                             NextState = STATE_READY;
    endcase
  end

  // com back to CPU
  assign CacheCommitted = CurrState != STATE_READY;
  assign CacheStall = (CurrState == STATE_READY & (FlushCache | AnyMiss)) | 
                      (CurrState == STATE_FETCH) |
                      (CurrState == STATE_WRITEBACK) |
                      (CurrState == STATE_WRITE_LINE & ~(StoreAMO)) |  // this cycle writes the sram, must keep stalling so the next cycle can read the next hit/miss unless its a write.
                      (CurrState == STATE_FLUSH) |
                      (CurrState == STATE_FLUSH_WRITEBACK);
  // write enables internal to cache
  assign SetValid = CurrState == STATE_WRITE_LINE;
  assign SetDirty = (CurrState == STATE_READY & AnyUpdateHit) |
                    (CurrState == STATE_WRITE_LINE & (StoreAMO));
  assign ClearValid = '0;
  assign ClearDirty = (CurrState == STATE_WRITE_LINE & ~(StoreAMO)) |
                      (CurrState == STATE_FLUSH & LineDirty); // This is wrong in a multicore snoop cache protocal.  Dirty must be cleared concurrently and atomically with writeback.  For single core cannot clear after writeback on bus ack and change flushadr.  Clears the wrong set.
  assign LRUWriteEn = (CurrState == STATE_READY & AnyHit) |
                      (CurrState == STATE_WRITE_LINE);
  // Flush and eviction controls
  assign SelWriteback = (CurrState == STATE_WRITEBACK & ~CacheBusAck) |
                    (CurrState == STATE_READY & AnyMiss & LineDirty);

  assign SelFlush = (CurrState == STATE_READY & FlushCache) |
					(CurrState == STATE_FLUSH) | 
					(CurrState == STATE_FLUSH_WRITEBACK);
  assign FlushAdrCntEn = (CurrState == STATE_FLUSH_WRITEBACK & FlushWayFlag & CacheBusAck) |
						 (CurrState == STATE_FLUSH & FlushWayFlag & ~LineDirty);
  assign FlushWayCntEn = (CurrState == STATE_FLUSH & ~LineDirty) |
						 (CurrState == STATE_FLUSH_WRITEBACK & CacheBusAck);
  assign FlushCntRst = (CurrState == STATE_FLUSH & FlushFlag & ~LineDirty) |
						  (CurrState == STATE_FLUSH_WRITEBACK & FlushFlag & CacheBusAck);
  // Bus interface controls
  assign CacheBusRW[1] = (CurrState == STATE_READY & AnyMiss & ~LineDirty) | 
                         (CurrState == STATE_FETCH & ~CacheBusAck) | 
                         (CurrState == STATE_WRITEBACK & CacheBusAck);
  assign CacheBusRW[0] = (CurrState == STATE_READY & AnyMiss & LineDirty) |
                          (CurrState == STATE_WRITEBACK & ~CacheBusAck) |
                     (CurrState == STATE_FLUSH_WRITEBACK & ~CacheBusAck);
  // **** can this be simplified?
  assign SelAdr = (CurrState == STATE_READY & (StoreAMO | AnyMiss)) | // changes if store delay hazard removed
                  (CurrState == STATE_FETCH) |
                  (CurrState == STATE_WRITEBACK) |
                  (CurrState == STATE_WRITE_LINE) |
                  resetDelay;

  assign SelFetchBuffer = CurrState == STATE_WRITE_LINE | CurrState == STATE_READ_HOLD;
  assign CacheEn = (CurrState == STATE_READY & ~Stall | CacheStall) | (CurrState != STATE_READY) | reset;
                       
endmodule // cachefsm

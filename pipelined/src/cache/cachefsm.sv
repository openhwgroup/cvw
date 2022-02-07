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
   input logic [1:0]  RW,
   input logic [1:0]  Atomic,
   input logic        FlushCache,
   // hazard inputs
   input logic        CPUBusy,
   // interlock fsm
   input logic        IgnoreRequest,
   // Bus inputs
   input logic        CacheBusAck,
   // dcache internals
   input logic        CacheHit,
   input logic        VictimDirty,
   input logic        FlushAdrFlag,
   input logic        FlushWayFlag, 
  
   // hazard outputs
   output logic       CacheStall,
   // counter outputs
   output logic       CacheMiss,
   output logic       CacheAccess,
   // Bus outputs
   output logic       CacheCommitted,
   output logic       CacheWriteLine,
   output logic       CacheFetchLine,

   // dcache internals
   output logic [1:0] SelAdr,
   output logic       SetValid,
   output logic       ClearValid,
   output logic       SetDirty,
   output logic       ClearDirty,
   output logic       SRAMWordWriteEnable,
   output logic       SRAMLineWriteEnable,
   output logic       SelEvict,
   output logic       LRUWriteEn,
   output logic       SelFlush,
   output logic       FlushAdrCntEn,
   output logic       FlushWayCntEn, 
   output logic       FlushAdrCntRst,
   output logic       FlushWayCntRst,
   output logic       save,
   output logic       restore,
   output logic       VDWriteEnable

   );
  
  logic [1:0]         PreSelAdr;
  logic               resetDelay;
  logic               DoAMO, DoRead, DoWrite, DoFlush;
  logic               DoAMOHit, DoReadHit, DoWriteHit;
  logic               DoAMOMiss, DoReadMiss, DoWriteMiss;
  logic               FlushFlag;
    
  typedef enum 		  {STATE_READY,

					   STATE_MISS_FETCH_WDV,
					   STATE_MISS_FETCH_DONE,
					   STATE_MISS_EVICT_DIRTY,
					   STATE_MISS_WRITE_CACHE_LINE,
					   STATE_MISS_READ_WORD,
					   STATE_MISS_READ_WORD_DELAY,
					   STATE_MISS_WRITE_WORD,

					   STATE_CPU_BUSY,
					   STATE_CPU_BUSY_FINISH_AMO,
  
					   STATE_FLUSH,
					   STATE_FLUSH_CHECK,
					   STATE_FLUSH_INCR,
					   STATE_FLUSH_WRITE_BACK,
					   STATE_FLUSH_CLEAR_DIRTY} statetype;

  (* mark_debug = "true" *) statetype CurrState, NextState;

  assign DoFlush = FlushCache & ~IgnoreRequest;
  assign DoAMO = Atomic[1] & (&RW) & ~IgnoreRequest;
  assign DoAMOHit = DoAMO & CacheHit;
  assign DoAMOMiss = DoAMOHit & ~CacheHit;  
  assign DoRead = RW[1] & ~IgnoreRequest;
  assign DoReadHit = DoRead & CacheHit;
  assign DoReadMiss = DoRead & ~CacheHit;
  assign DoWrite = RW[0] & ~IgnoreRequest;
  assign DoWriteHit = DoWrite & CacheHit;
  assign DoWriteMiss = DoWrite & ~CacheHit;

  assign FlushFlag = FlushAdrFlag & FlushWayFlag;

  // outputs for the performance counters.
  assign CacheAccess = (DoAMO | DoRead | DoWrite) & CurrState == STATE_READY;
  assign CacheMiss = CacheAccess & ~CacheHit;

  // special case on reset. When the fsm first exists reset the
  // PCNextF will no longer be pointing to the correct address.
  // But PCF will be the reset vector.
  flop #(1) resetDelayReg(.clk, .d(reset), .q(resetDelay));
  assign SelAdr = resetDelay ? 2'b01 : PreSelAdr;

  always_ff @(posedge clk)
    if (reset)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;  
  
  always_comb begin
    NextState = STATE_READY;
    case (CurrState)
      STATE_READY: if(DoFlush)                                      NextState = STATE_FLUSH;
                   else if(DoAMOHit & CPUBusy)                      NextState = STATE_CPU_BUSY_FINISH_AMO;
                   else if(DoReadHit & CPUBusy)                     NextState = STATE_CPU_BUSY;
                   else if (DoWriteHit & CPUBusy)                   NextState = STATE_CPU_BUSY;
                   else if(DoReadMiss | DoWriteMiss | DoAMOMiss)    NextState = STATE_MISS_FETCH_WDV;
                   else                                             NextState = STATE_READY;
      STATE_MISS_FETCH_WDV: if (CacheBusAck)                        NextState = STATE_MISS_FETCH_DONE;
                            else                                    NextState = STATE_MISS_FETCH_WDV;
      STATE_MISS_FETCH_DONE: if(VictimDirty)                        NextState = STATE_MISS_EVICT_DIRTY;
                             else                                   NextState = STATE_MISS_WRITE_CACHE_LINE;
      STATE_MISS_WRITE_CACHE_LINE:                                  NextState = STATE_MISS_READ_WORD;
      STATE_MISS_READ_WORD: if (DoWrite & ~DoAMO)                   NextState = STATE_MISS_WRITE_WORD;
                            else                                    NextState = STATE_MISS_READ_WORD_DELAY;
      STATE_MISS_READ_WORD_DELAY: if(DoAMO & CPUBusy)               NextState = STATE_CPU_BUSY_FINISH_AMO;
                                  else if(CPUBusy)                  NextState = STATE_CPU_BUSY;
                                  else                              NextState = STATE_READY;
      STATE_MISS_WRITE_WORD: if(CPUBusy)                            NextState = STATE_CPU_BUSY;
                             else                                   NextState = STATE_READY;
      STATE_MISS_EVICT_DIRTY: if(CacheBusAck)                       NextState = STATE_MISS_WRITE_CACHE_LINE;
                              else                                  NextState = STATE_MISS_EVICT_DIRTY;
      STATE_CPU_BUSY: if(CPUBusy)                                   NextState = STATE_CPU_BUSY;
                      else                                          NextState = STATE_READY;
      STATE_CPU_BUSY_FINISH_AMO: if(CPUBusy)                        NextState = STATE_CPU_BUSY_FINISH_AMO;
                                 else                               NextState = STATE_READY;
	  STATE_FLUSH:                                                  NextState = STATE_FLUSH_CHECK;
      STATE_FLUSH_CHECK: if(VictimDirty)                            NextState = STATE_FLUSH_WRITE_BACK;
                         else if (FlushFlag)                        NextState = STATE_READY;
                         else if(FlushWayFlag)                      NextState = STATE_FLUSH_INCR;
                         else                                       NextState = STATE_FLUSH_CHECK;
	  STATE_FLUSH_INCR:                                             NextState = STATE_FLUSH_CHECK;
      STATE_FLUSH_WRITE_BACK: if(CacheBusAck)                       NextState = STATE_FLUSH_CLEAR_DIRTY;
                              else                                  NextState = STATE_FLUSH_WRITE_BACK;
      STATE_FLUSH_CLEAR_DIRTY: if(FlushAdrFlag & FlushWayFlag)      NextState = STATE_READY;
                               else if (FlushWayFlag)               NextState = STATE_FLUSH_INCR;
                               else                                 NextState = STATE_FLUSH_CHECK;
      default:                                                      NextState = STATE_READY;
    endcase
  end

  assign CacheCommitted = CurrState != STATE_READY;
  assign CacheStall = (CurrState == STATE_READY & (DoFlush | DoAMOMiss | DoReadMiss | DoWriteMiss)) |
                      (CurrState == STATE_MISS_FETCH_WDV) |
                      (CurrState == STATE_MISS_FETCH_DONE) |
                      (CurrState == STATE_MISS_WRITE_CACHE_LINE) |
                      (CurrState == STATE_MISS_READ_WORD) |
                      (CurrState == STATE_MISS_EVICT_DIRTY) |
                      (CurrState == STATE_FLUSH) |
                      (CurrState == STATE_FLUSH_CHECK & ~(FlushFlag)) |
                      (CurrState == STATE_FLUSH_INCR) |
                      (CurrState == STATE_FLUSH_WRITE_BACK) |
                      (CurrState == STATE_FLUSH_CLEAR_DIRTY & ~(FlushFlag));
  assign SetValid = CurrState == STATE_MISS_WRITE_CACHE_LINE;
  assign ClearValid = '0;
  assign SetDirty = (CurrState == STATE_READY & DoAMO) |
                    (CurrState == STATE_READY & DoWrite) |
                    (CurrState == STATE_MISS_READ_WORD_DELAY & DoAMO) |
                    (CurrState == STATE_MISS_WRITE_WORD);
  assign ClearDirty = (CurrState == STATE_MISS_WRITE_CACHE_LINE) |
                      (CurrState == STATE_FLUSH_CLEAR_DIRTY);
  assign SRAMWordWriteEnable = (CurrState == STATE_READY & (DoAMOHit | DoWriteHit)) |
                               (CurrState == STATE_MISS_READ_WORD_DELAY & DoAMO) |
                               (CurrState == STATE_MISS_WRITE_WORD);
  assign SRAMLineWriteEnable = (CurrState == STATE_MISS_WRITE_CACHE_LINE);
  assign VDWriteEnable = (CurrState == STATE_FLUSH_CLEAR_DIRTY);
  assign SelEvict = (CurrState == STATE_MISS_EVICT_DIRTY);
  assign LRUWriteEn = (CurrState == STATE_READY & (DoAMOHit | DoReadHit | DoWriteHit)) |
                      (CurrState == STATE_MISS_READ_WORD_DELAY) |
                      (CurrState == STATE_MISS_WRITE_WORD);
  assign SelFlush = (CurrState == STATE_FLUSH) | (CurrState == STATE_FLUSH_CHECK) |
                    (CurrState == STATE_FLUSH_INCR) | (CurrState == STATE_FLUSH_WRITE_BACK) |
                    (CurrState == STATE_FLUSH_CLEAR_DIRTY);
  assign FlushAdrCntEn = (CurrState == STATE_FLUSH_CHECK & ~VictimDirty & FlushWayFlag & ~FlushAdrFlag) |
                         (CurrState == STATE_FLUSH_CLEAR_DIRTY & FlushWayFlag & ~FlushAdrFlag);
  assign FlushWayCntEn = (CurrState == STATE_FLUSH_CHECK & ~VictimDirty & ~(FlushFlag)) |
                         (CurrState == STATE_FLUSH_CLEAR_DIRTY & ~(FlushFlag));
  assign FlushAdrCntRst = (CurrState == STATE_READY & DoFlush);
  assign FlushWayCntRst = (CurrState == STATE_READY & DoFlush) | (CurrState == STATE_FLUSH_INCR);
  assign CacheFetchLine = (CurrState == STATE_READY & (DoAMOMiss | DoWriteMiss | DoReadMiss));
  assign CacheWriteLine = (CurrState == STATE_MISS_FETCH_DONE & VictimDirty) |
                          (CurrState == STATE_FLUSH_CHECK & VictimDirty);
  assign restore = ((CurrState == STATE_CPU_BUSY) | (CurrState == STATE_CPU_BUSY_FINISH_AMO)) & ~`REPLAY;
  assign save = ((CurrState == STATE_READY & (DoAMOHit | DoReadHit | DoWriteHit) & CPUBusy) |
                 (CurrState == STATE_MISS_READ_WORD_DELAY & (DoAMO | DoRead) & CPUBusy) |
                 (CurrState == STATE_MISS_WRITE_WORD & DoWrite & CPUBusy)) & ~`REPLAY;

  // **** can this be simplified?
  assign PreSelAdr = ((CurrState == STATE_READY & IgnoreRequest) | 
                      (CurrState == STATE_READY & DoAMOHit) |
                      (CurrState == STATE_READY & DoReadHit & (CPUBusy & `REPLAY)) |
                      (CurrState == STATE_READY & DoWriteHit) |
                      (CurrState == STATE_MISS_FETCH_WDV) |
                      (CurrState == STATE_MISS_FETCH_DONE) | 
                      (CurrState == STATE_MISS_WRITE_CACHE_LINE) | 
                      (CurrState == STATE_MISS_READ_WORD) |
                      (CurrState == STATE_MISS_READ_WORD_DELAY & (DoAMO | (CPUBusy & `REPLAY))) |
                      (CurrState == STATE_MISS_WRITE_WORD) |
                      (CurrState == STATE_MISS_EVICT_DIRTY) |
                      (CurrState == STATE_CPU_BUSY & (CPUBusy & `REPLAY)) |
                      (CurrState == STATE_CPU_BUSY_FINISH_AMO)) ? 2'b01 :
                     ((CurrState == STATE_FLUSH) | 
                      (CurrState == STATE_FLUSH_CHECK & ~(VictimDirty & FlushFlag)) |
                      (CurrState == STATE_FLUSH_INCR) |
                      (CurrState == STATE_FLUSH_WRITE_BACK) |
                      (CurrState == STATE_FLUSH_CLEAR_DIRTY & ~(FlushFlag))) ? 2'b10 : 
                     2'b00;
                                                                                
                       
endmodule // cachefsm

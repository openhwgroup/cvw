///////////////////////////////////////////
// busfsm.sv
//
// Written: Ross Thompson ross1728@gmail.com December 29, 2021
// Modified: 
//
// Purpose: Load/Store Unit's interface to BUS for cacheless system
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
`define BURST_EN 1

// HCLK and clk must be the same clock!
module buscachefsm #(parameter integer   BeatCountThreshold,
   parameter integer LOGWPL, parameter logic CACHE_ENABLED )
  (input logic               HCLK,
   input logic               HRESETn,

   // IEU interface
   input logic               Flush,
   input logic [1:0]         BusRW,
   input logic               Stall,
   output logic              BusCommitted,
   output logic              BusStall,
   output logic              CaptureEn,

   // cache interface
   input logic [1:0]         CacheBusRW,
   output logic              CacheBusAck,
   
   // lsu interface
   output logic [LOGWPL-1:0] BeatCount, BeatCountDelayed,
   output logic              SelBusBeat,

   // BUS interface
   input logic               HREADY,
   output logic [1:0]        HTRANS,
   output logic              HWRITE,
   output logic [2:0]        HBURST
);
  
  typedef enum logic [2:0] {ADR_PHASE,
				            DATA_PHASE,
				            MEM3,
                            CACHE_FETCH,
                            CACHE_WRITEBACK} busstatetype;

  typedef enum logic [1:0] {AHB_IDLE = 2'b00, AHB_BUSY = 2'b01, AHB_NONSEQ = 2'b10, AHB_SEQ = 2'b11} ahbtranstype;

  (* mark_debug = "true" *) busstatetype CurrState, NextState;

  logic [LOGWPL-1:0] NextBeatCount;
  logic              FinalBeatCount;
  logic [2:0]        LocalBurstType;
  logic              BeatCntEn;
  logic              BeatCntReset;
  logic              CacheAccess;
  
  always_ff @(posedge HCLK)
    if (~HRESETn | Flush)    CurrState <= #1 ADR_PHASE;
    else CurrState <= #1 NextState;  
  
  always_comb begin
	case(CurrState)
	  ADR_PHASE: if(HREADY & |BusRW)              NextState = DATA_PHASE;
                   else if (HREADY & CacheBusRW[0]) NextState = CACHE_WRITEBACK;
                   else if (HREADY & CacheBusRW[1]) NextState = CACHE_FETCH;
                   else                          NextState = ADR_PHASE;
      DATA_PHASE: if(HREADY)                  NextState = MEM3;
		           else                          NextState = DATA_PHASE;
      MEM3: if(Stall)                   NextState = MEM3;
		           else                          NextState = ADR_PHASE;
      CACHE_FETCH: if(HREADY & FinalBeatCount & CacheBusRW[0]) NextState = CACHE_WRITEBACK;
                   else if(HREADY & FinalBeatCount & CacheBusRW[1]) NextState = CACHE_FETCH;
                   else if(HREADY & FinalBeatCount & ~|CacheBusRW) NextState = ADR_PHASE;
                   else                       NextState = CACHE_FETCH;
      CACHE_WRITEBACK: if(HREADY & FinalBeatCount & CacheBusRW[0]) NextState = CACHE_WRITEBACK;
                   else if(HREADY & FinalBeatCount & CacheBusRW[1]) NextState = CACHE_FETCH;
                   else if(HREADY & FinalBeatCount & ~|CacheBusRW) NextState = ADR_PHASE;
                   else                       NextState = CACHE_WRITEBACK;
	  default:                                      NextState = ADR_PHASE;
	endcase
  end

  // IEU, LSU, and IFU controls
  flopenr #(LOGWPL) 
  BeatCountReg(.clk(HCLK),
		.reset(~HRESETn | BeatCntReset),
		.en(BeatCntEn),
		.d(NextBeatCount),
		.q(BeatCount));  
  
  // Used to store data from data phase of AHB.
  flopenr #(LOGWPL) 
  BeatCountDelayedReg(.clk(HCLK),
		.reset(~HRESETn | BeatCntReset),
		.en(BeatCntEn),
		.d(BeatCount),
		.q(BeatCountDelayed));
  assign NextBeatCount = BeatCount + 1'b1;

  assign FinalBeatCount = BeatCountDelayed == BeatCountThreshold[LOGWPL-1:0];
  assign BeatCntEn = ((NextState == CACHE_WRITEBACK | NextState == CACHE_FETCH) & HREADY & ~Flush) |
                     (NextState == ADR_PHASE & |CacheBusRW & HREADY);
  assign BeatCntReset = NextState == ADR_PHASE;

  assign CaptureEn = (CurrState == DATA_PHASE & BusRW[1]) | (CurrState == CACHE_FETCH & HREADY);
  assign CacheAccess = CurrState == CACHE_FETCH | CurrState == CACHE_WRITEBACK;

  assign BusStall = (CurrState == ADR_PHASE & (|BusRW | |CacheBusRW) & ~Flush) |
					//(CurrState == DATA_PHASE & ~BusRW[0]) |  // replace the next line with this.  Fails uart test but i think it's a test problem not a hardware problem.
					(CurrState == DATA_PHASE) | 
                    (CurrState == CACHE_FETCH & ~HREADY) |
                    (CurrState == CACHE_WRITEBACK & ~HREADY);
  assign BusCommitted = CurrState != ADR_PHASE;

  // AHB bus interface
  assign HTRANS = (CurrState == ADR_PHASE & HREADY & (|BusRW | |CacheBusRW) & ~Flush) |
                  (CacheAccess & FinalBeatCount & |CacheBusRW & HREADY) ? AHB_NONSEQ : // if we have a pipelined request
                  (CacheAccess & |BeatCount) ? (`BURST_EN ? AHB_SEQ : AHB_NONSEQ) : AHB_IDLE;

  assign HWRITE = BusRW[0] | CacheBusRW[0] | (CurrState == CACHE_WRITEBACK & |BeatCount);
  assign HBURST = `BURST_EN & (|CacheBusRW | (CacheAccess & |BeatCount)) ? LocalBurstType : 3'b0;  
  
  always_comb begin
    case(BeatCountThreshold)
      0:        LocalBurstType = 3'b000;
      3:        LocalBurstType = 3'b011; // INCR4
      7:        LocalBurstType = 3'b101; // INCR8
      15:       LocalBurstType = 3'b111; // INCR16
      default:  LocalBurstType = 3'b001; // INCR without end.
    endcase
  end

  // communication to cache
  assign CacheBusAck = (CacheAccess & HREADY & FinalBeatCount);
  assign SelBusBeat = (CurrState == ADR_PHASE & (BusRW[0] | CacheBusRW[0])) |
					  (CurrState == DATA_PHASE & BusRW[0]) |
                      (CurrState == CACHE_WRITEBACK) |
                      (CurrState == CACHE_FETCH);

endmodule

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

// HCLK and clk must be the same clock!
module buscachefsm #(parameter integer   WordCountThreshold,
   parameter integer LOGWPL, parameter logic CACHE_ENABLED )
  (input logic               HCLK,
   input logic               HRESETn,

   // IEU interface
   input logic [1:0]         RW,
   input logic               CPUBusy,
   output logic              BusCommitted,
   output logic              BusStall,
   output logic              CaptureEn,

   // cache interface
   input logic [1:0]         CacheRW,
   output logic              CacheBusAck,
   
   // lsu interface
   output logic              SelUncachedAdr,
   output logic [LOGWPL-1:0] WordCount, WordCountDelayed,
   output logic              SelBusWord,

   // BUS interface
   input logic               HREADY,
   output logic [1:0]        HTRANS,
   output logic              HWRITE,
   output logic [2:0]        HBURST
);
  
  typedef enum logic [2:0] {STATE_READY,
				            STATE_CAPTURE,
				            STATE_DELAY,
                            STATE_CACHE_FETCH,
                            STATE_CACHE_EVICT} busstatetype;

  typedef enum logic [1:0] {AHB_IDLE = 2'b00, AHB_BUSY = 2'b01, AHB_NONSEQ = 2'b10, AHB_SEQ = 2'b11} ahbtranstype;

  (* mark_debug = "true" *) busstatetype BusCurrState, BusNextState;

  logic [LOGWPL-1:0] NextWordCount;
  logic              FinalWordCount;
  logic [2:0]        LocalBurstType;
  logic              WordCntEn;
  logic              WordCntReset;
  logic              CacheAccess;
  
  always_ff @(posedge HCLK)
    if (~HRESETn)    BusCurrState <= #1 STATE_READY;
    else BusCurrState <= #1 BusNextState;  
  
  always_comb begin
	case(BusCurrState)
	  STATE_READY: if(HREADY & |RW)              BusNextState = STATE_CAPTURE;
                   else if (HREADY & CacheRW[0]) BusNextState = STATE_CACHE_EVICT;
                   else if (HREADY & CacheRW[1]) BusNextState = STATE_CACHE_FETCH;
                   else                          BusNextState = STATE_READY;
      STATE_CAPTURE: if(HREADY)                  BusNextState = STATE_DELAY;
		           else                          BusNextState = STATE_CAPTURE;
      STATE_DELAY: if(CPUBusy)                   BusNextState = STATE_DELAY;
		           else                          BusNextState = STATE_READY;
      STATE_CACHE_FETCH: if(HREADY & FinalWordCount) BusNextState = STATE_READY;
                         else                       BusNextState = STATE_CACHE_FETCH;
      STATE_CACHE_EVICT: if(HREADY & FinalWordCount) BusNextState = STATE_READY;
                         else                       BusNextState = STATE_CACHE_EVICT;
	  default:                                      BusNextState = STATE_READY;
	endcase
  end

  // IEU, LSU, and IFU controls
  flopenr #(LOGWPL) 
  WordCountReg(.clk(HCLK),
		.reset(~HRESETn | WordCntReset),
		.en(WordCntEn),
		.d(NextWordCount),
		.q(WordCount));  
  
  // Used to store data from data phase of AHB.
  flopenr #(LOGWPL) 
  WordCountDelayedReg(.clk(HCLK),
		.reset(~HRESETn | WordCntReset),
		.en(WordCntEn),
		.d(WordCount),
		.q(WordCountDelayed));
  assign NextWordCount = WordCount + 1'b1;

  assign FinalWordCount = WordCountDelayed == WordCountThreshold[LOGWPL-1:0];
  assign WordCntEn = ((BusNextState == STATE_CACHE_EVICT | BusNextState == STATE_CACHE_FETCH) & HREADY) |
                     (BusNextState == STATE_READY & |CacheRW & HREADY);
  assign WordCntReset = BusNextState == STATE_READY;

  assign CaptureEn = (BusCurrState == STATE_CAPTURE & RW[1]) | (BusCurrState == STATE_CACHE_FETCH & HREADY);
  assign CacheAccess = BusCurrState == STATE_CACHE_FETCH | BusCurrState == STATE_CACHE_EVICT;

  assign BusStall = (BusCurrState == STATE_READY & (|RW | |CacheRW)) |
					//(BusCurrState == STATE_CAPTURE & ~RW[0]) |  // replace the next line with this.  Fails uart test but i think it's a test problem not a hardware problem.
					(BusCurrState == STATE_CAPTURE) | 
                    (BusCurrState == STATE_CACHE_FETCH) |
                    (BusCurrState == STATE_CACHE_EVICT);
  assign BusCommitted = BusCurrState != STATE_READY;
  assign SelUncachedAdr = (BusCurrState == STATE_READY & |RW) |
                          (BusCurrState == STATE_CAPTURE) |
                          (BusCurrState == STATE_DELAY);

  // AHB bus interface
  assign HTRANS = (BusCurrState == STATE_READY & HREADY & (|RW | |CacheRW)) |
                  (BusCurrState == STATE_CAPTURE & ~HREADY) |
                  (CacheAccess & ~HREADY & ~|WordCount) ? AHB_NONSEQ :
                  (CacheAccess & |WordCount) ? AHB_SEQ : AHB_IDLE;

  assign HWRITE = RW[0] | CacheRW[0];
  assign HBURST = (|CacheRW) ? LocalBurstType : 3'b0;
  
  always_comb begin
    case(WordCountThreshold)
      0:        LocalBurstType = 3'b000;
      3:        LocalBurstType = 3'b011; // INCR4
      7:        LocalBurstType = 3'b101; // INCR8
      15:       LocalBurstType = 3'b111; // INCR16
      default:  LocalBurstType = 3'b001; // INCR without end.
    endcase
  end

  // communication to cache
  assign CacheBusAck = (CacheAccess & HREADY & FinalWordCount);
  assign SelBusWord = (BusCurrState == STATE_READY & (RW[0] | CacheRW[0])) |
						   (BusCurrState == STATE_CAPTURE & RW[0]) |
                           (BusCurrState == STATE_CACHE_EVICT);

endmodule

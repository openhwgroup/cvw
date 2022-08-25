///////////////////////////////////////////
// busfsm.sv
//
// Written: Ross Thompson ross1728@gmail.com December 29, 2021
// Modified: 
//
// Purpose: Load/Store Unit's interface to BUS
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


module busfsm #(parameter integer   WordCountThreshold,
				parameter integer LOGWPL, parameter logic CACHE_ENABLED )
  (input logic               clk,
   input logic               reset,

   input logic               IgnoreRequest,
   input logic [1:0]         RW,
   input logic               CacheFetchLine,
   input logic               CacheWriteLine,
   input logic               BusAck,
   input logic               BusInit, // This might be better as LSUBusLock, or to send this using BusAck.
   input logic               CPUBusy,
   input logic               Cacheable,

   output logic              BusStall,
   output logic              BusWrite,
   output logic              SelLSUBusWord,
   output logic              BusRead,
   output logic [2:0]        HBURST,
   output logic              BusTransComplete,
   output logic [1:0]        HTRANS,
   output logic              CacheBusAck,
   output logic              BusCommitted,
   output logic              SelUncachedAdr,
   output logic              BufferCaptureEn,
   output logic [LOGWPL-1:0] WordCount, WordCountDelayed);
  

  
  logic 			   UnCachedBusRead;
  logic 			   UnCachedBusWrite;
  logic 			   CntEn, PreCntEn;
  logic 			   CntReset;
  logic 			   WordCountFlag;
  logic [LOGWPL-1:0]   NextWordCount;
  logic 			   UnCachedAccess, UnCachedRW;
  logic [2:0]    LocalBurstType;
  

  typedef enum logic [2:0] {STATE_BUS_READY,
				STATE_BUS_FETCH,
				STATE_BUS_WRITE,
				STATE_BUS_UNCACHED_WRITE,
				STATE_BUS_UNCACHED_WRITE_DONE,
				STATE_BUS_UNCACHED_READ,
				STATE_BUS_UNCACHED_READ_DONE,
				STATE_BUS_CPU_BUSY} busstatetype;

  typedef enum logic [1:0] {AHB_IDLE = 2'b00, AHB_BUSY = 2'b01, AHB_NONSEQ = 2'b10, AHB_SEQ = 2'b11} ahbtranstype;

  (* mark_debug = "true" *) busstatetype BusCurrState, BusNextState;

  // Used to send address for address stage of AHB.
  flopenr #(LOGWPL) 
  WordCountReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(NextWordCount),
		.q(WordCount));  
  
  // Used to store data from data phase of AHB.
  flopenr #(LOGWPL) 
  WordCountDelayedReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(WordCount),
		.q(WordCountDelayed));

  assign NextWordCount = WordCount + 1'b1;

  assign PreCntEn = (BusCurrState == STATE_BUS_FETCH) | (BusCurrState == STATE_BUS_WRITE);
  assign WordCountFlag = (WordCountDelayed == WordCountThreshold[LOGWPL-1:0]); // Detect when we are waiting on the final access.
  assign CntEn = (PreCntEn & BusAck | (BusInit)) & ~WordCountFlag & ~UnCachedRW; // Want to count when doing cache accesses and we aren't wrapping up.

  assign UnCachedAccess = ~CACHE_ENABLED | ~Cacheable;

  always_ff @(posedge clk)
    if (reset)    BusCurrState <= #1 STATE_BUS_READY;
    else BusCurrState <= #1 BusNextState;  
  
  always_comb begin
	case(BusCurrState)
	  STATE_BUS_READY:           if(IgnoreRequest)                   BusNextState = STATE_BUS_READY;
	                             else if(RW[0] & UnCachedAccess) BusNextState = STATE_BUS_UNCACHED_WRITE;
		                         else if(RW[1] & UnCachedAccess) BusNextState = STATE_BUS_UNCACHED_READ;
		                         else if(CacheFetchLine)            BusNextState = STATE_BUS_FETCH;
		                         else if(CacheWriteLine)            BusNextState = STATE_BUS_WRITE;
                                 else                                BusNextState = STATE_BUS_READY;
      STATE_BUS_UNCACHED_WRITE:  if(BusAck)                       BusNextState = STATE_BUS_UNCACHED_WRITE_DONE;
		                         else                                BusNextState = STATE_BUS_UNCACHED_WRITE;
      STATE_BUS_UNCACHED_READ:   if(BusAck)                       BusNextState = STATE_BUS_UNCACHED_READ_DONE;
		                         else                                BusNextState = STATE_BUS_UNCACHED_READ;
      STATE_BUS_UNCACHED_WRITE_DONE: if(CPUBusy)                     BusNextState = STATE_BUS_CPU_BUSY;
                                     else                            BusNextState = STATE_BUS_READY;
      STATE_BUS_UNCACHED_READ_DONE:  if(CPUBusy)                     BusNextState = STATE_BUS_CPU_BUSY;
                                     else                            BusNextState = STATE_BUS_READY;
	  STATE_BUS_CPU_BUSY:            if(CPUBusy)                     BusNextState = STATE_BUS_CPU_BUSY;
                                     else                            BusNextState = STATE_BUS_READY;
      STATE_BUS_FETCH:           if (WordCountFlag & BusAck) begin
                                   if (CacheFetchLine)  BusNextState = STATE_BUS_FETCH;
                                   else if (CacheWriteLine)  BusNextState = STATE_BUS_WRITE;
                                   else BusNextState = STATE_BUS_READY;
	                             end else                            BusNextState = STATE_BUS_FETCH;
      STATE_BUS_WRITE:           if(WordCountFlag & BusAck) begin
                                   if (CacheFetchLine)  BusNextState = STATE_BUS_FETCH;
                                   else if (CacheWriteLine)  BusNextState = STATE_BUS_WRITE;
                                   else  BusNextState = STATE_BUS_READY;
                                 end else                                BusNextState = STATE_BUS_WRITE;
	  default:                                                       BusNextState = STATE_BUS_READY;
	endcase
  end

  always_comb begin
    case(WordCountThreshold)
      0:        LocalBurstType = 3'b000;
      3:        LocalBurstType = 3'b011; // INCR4
      7:        LocalBurstType = 3'b101; // INCR8
      15:       LocalBurstType = 3'b111; // INCR16
      default:  LocalBurstType = 3'b001; // INCR without end.
    endcase
  end

   assign HBURST = (UnCachedRW) ? 3'b0 : LocalBurstType; // Don't want to use burst when doing an Uncached Access.
  assign BusTransComplete = (UnCachedRW) ? BusAck : WordCountFlag & BusAck;
  // Use SEQ if not doing first word, NONSEQ if doing the first read/write, and IDLE if finishing up.
  assign HTRANS = (|WordCount) & ~UnCachedRW ? AHB_SEQ : (BusRead | BusWrite) & (~BusTransComplete) ? AHB_NONSEQ : AHB_IDLE; 
  // Reset if we aren't initiating a transaction or if we are finishing a transaction.
  assign CntReset = BusCurrState == STATE_BUS_READY & ~(CacheFetchLine | CacheWriteLine) | BusTransComplete; 
  
  assign BusStall = (BusCurrState == STATE_BUS_READY & ~IgnoreRequest & ((UnCachedAccess & (|RW)) | CacheFetchLine | CacheWriteLine)) |
					(BusCurrState == STATE_BUS_UNCACHED_WRITE) |
					(BusCurrState == STATE_BUS_UNCACHED_READ) |
					(BusCurrState == STATE_BUS_FETCH)  |
					(BusCurrState == STATE_BUS_WRITE);
  assign UnCachedBusWrite = (BusCurrState == STATE_BUS_READY & UnCachedAccess & RW[0] & ~IgnoreRequest) |
							   (BusCurrState == STATE_BUS_UNCACHED_WRITE);
  assign BusWrite = UnCachedBusWrite | (BusCurrState == STATE_BUS_WRITE & ~WordCountFlag);
  assign SelLSUBusWord = (BusCurrState == STATE_BUS_READY & UnCachedAccess & RW[0]) |
						   (BusCurrState == STATE_BUS_UNCACHED_WRITE) |
                           (BusCurrState == STATE_BUS_WRITE);

  assign UnCachedBusRead = (BusCurrState == STATE_BUS_READY & UnCachedAccess & RW[1] & ~IgnoreRequest) |
							  (BusCurrState == STATE_BUS_UNCACHED_READ);
  assign BusRead = UnCachedBusRead | (BusCurrState == STATE_BUS_FETCH & ~(WordCountFlag)) | (BusCurrState == STATE_BUS_READY & CacheFetchLine);
  assign BufferCaptureEn = UnCachedBusRead | BusCurrState == STATE_BUS_FETCH;

  // Makes bus only do uncached reads/writes when we actually do uncached reads/writes. Needed because Cacheable is 0 when flushing cache.
  assign UnCachedRW = UnCachedBusWrite | UnCachedBusRead; 

  assign CacheBusAck = (BusCurrState == STATE_BUS_FETCH & WordCountFlag & BusAck) |
						(BusCurrState == STATE_BUS_WRITE & WordCountFlag & BusAck);
  assign BusCommitted = BusCurrState != STATE_BUS_READY;
  assign SelUncachedAdr = (BusCurrState == STATE_BUS_READY & (|RW & UnCachedAccess)) |
						  (BusCurrState == STATE_BUS_UNCACHED_READ |
						   BusCurrState == STATE_BUS_UNCACHED_READ_DONE |
						   BusCurrState == STATE_BUS_UNCACHED_WRITE |
						   BusCurrState == STATE_BUS_UNCACHED_WRITE_DONE) |
						  ~CACHE_ENABLED; // if no Cache always select uncachedadr.
endmodule

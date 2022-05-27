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
   input logic [1:0]         LSURWM,
   input logic               DCacheFetchLine,
   input logic               DCacheWriteLine,
   input logic               LSUBusAck,
   input logic               CPUBusy,
   input logic               CacheableM,

   output logic              BusStall,
   output logic              LSUBusWrite,
   output logic              LSUBusWriteCrit,
   output logic              LSUBusRead,
   output logic [2:0]        LSUBurstType,
   output logic              LSUBurstDone,
   output logic              DCacheBusAck,
   output logic              BusCommittedM,
   output logic              SelUncachedAdr,
   output logic [LOGWPL-1:0] WordCount);
  

  
  logic 			   UnCachedLSUBusRead;
  logic 			   UnCachedLSUBusWrite;
  logic 			   CntEn, PreCntEn;
  logic 			   CntReset;
  logic 			   WordCountFlag;
  logic [LOGWPL-1:0]   NextWordCount;
  logic 			   UnCachedAccess;
  logic [2:0]    LocalBurstType;
  

  typedef enum logic [2:0] {STATE_BUS_READY,
				STATE_BUS_FETCH,
				STATE_BUS_WRITE,
				STATE_BUS_UNCACHED_WRITE,
				STATE_BUS_UNCACHED_WRITE_DONE,
				STATE_BUS_UNCACHED_READ,
				STATE_BUS_UNCACHED_READ_DONE,
				STATE_BUS_CPU_BUSY} busstatetype;

  (* mark_debug = "true" *) busstatetype BusCurrState, BusNextState;


  flopenr #(LOGWPL) 
  WordCountReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(NextWordCount),
		.q(WordCount));

  assign NextWordCount = WordCount + 1'b1;

  assign WordCountFlag = (WordCount == WordCountThreshold[LOGWPL-1:0]);
  assign CntEn = PreCntEn & LSUBusAck;

  assign UnCachedAccess = ~CACHE_ENABLED | ~CacheableM;

  always_ff @(posedge clk)
    if (reset)    BusCurrState <= #1 STATE_BUS_READY;
    else BusCurrState <= #1 BusNextState;  
  
  always_comb begin
	case(BusCurrState)
	  STATE_BUS_READY:           if(IgnoreRequest)                   BusNextState = STATE_BUS_READY;
	                             else if(LSURWM[0] & UnCachedAccess) BusNextState = STATE_BUS_UNCACHED_WRITE;
		                         else if(LSURWM[1] & UnCachedAccess) BusNextState = STATE_BUS_UNCACHED_READ;
		                         else if(DCacheFetchLine)            BusNextState = STATE_BUS_FETCH;
		                         else if(DCacheWriteLine)            BusNextState = STATE_BUS_WRITE;
                                 else                                BusNextState = STATE_BUS_READY;
      STATE_BUS_UNCACHED_WRITE:  if(LSUBusAck)                       BusNextState = STATE_BUS_UNCACHED_WRITE_DONE;
		                         else                                BusNextState = STATE_BUS_UNCACHED_WRITE;
      STATE_BUS_UNCACHED_READ:   if(LSUBusAck)                       BusNextState = STATE_BUS_UNCACHED_READ_DONE;
		                         else                                BusNextState = STATE_BUS_UNCACHED_READ;
      STATE_BUS_UNCACHED_WRITE_DONE: if(CPUBusy)                     BusNextState = STATE_BUS_CPU_BUSY;
                                     else                            BusNextState = STATE_BUS_READY;
      STATE_BUS_UNCACHED_READ_DONE:  if(CPUBusy)                     BusNextState = STATE_BUS_CPU_BUSY;
                                     else                            BusNextState = STATE_BUS_READY;
	  STATE_BUS_CPU_BUSY:            if(CPUBusy)                     BusNextState = STATE_BUS_CPU_BUSY;
                                     else                            BusNextState = STATE_BUS_READY;
      STATE_BUS_FETCH:           if (WordCountFlag & LSUBusAck)      BusNextState = STATE_BUS_READY;
	                             else                                BusNextState = STATE_BUS_FETCH;
      STATE_BUS_WRITE:           if(WordCountFlag & LSUBusAck)       BusNextState = STATE_BUS_READY;
	                             else                                BusNextState = STATE_BUS_WRITE;
	  default:                                                       BusNextState = STATE_BUS_READY;
	endcase
  end

  always_comb begin
    case(WordCountThreshold)
      4:        LSUBurstType = 3'b010; // WRAP4
      8:        LSUBurstType = 3'b100; // WRAP8
      16:       LSUBurstType = 3'b110; // WRAP16
      default:  LSUBurstType = 3'b000; // No Burst
    endcase // This block might be better in the FSM. WordCountThreshold is WordsPerLine
  end

  assign LSUBurstType = (UnCachedAccess) ? 3'b0 : LocalBurstType ; // Don't want to use burst when doing an Uncached Access
  assign LSUBurstDone = (UnCachedAccess) ? LSUBusAck : WordCountFlag & LSUBusAck;

  assign CntReset = BusCurrState == STATE_BUS_READY;
  assign BusStall = (BusCurrState == STATE_BUS_READY & ~IgnoreRequest & ((UnCachedAccess & (|LSURWM)) | DCacheFetchLine | DCacheWriteLine)) |
					(BusCurrState == STATE_BUS_UNCACHED_WRITE) |
					(BusCurrState == STATE_BUS_UNCACHED_READ) |
					(BusCurrState == STATE_BUS_FETCH)  |
					(BusCurrState == STATE_BUS_WRITE);
  assign PreCntEn = BusCurrState == STATE_BUS_FETCH | BusCurrState == STATE_BUS_WRITE;
  assign UnCachedLSUBusWrite = (BusCurrState == STATE_BUS_READY & UnCachedAccess & LSURWM[0] & ~IgnoreRequest) |
							   (BusCurrState == STATE_BUS_UNCACHED_WRITE);
  assign LSUBusWrite = UnCachedLSUBusWrite | (BusCurrState == STATE_BUS_WRITE);
  assign LSUBusWriteCrit = (BusCurrState == STATE_BUS_READY & UnCachedAccess & LSURWM[0]) |
						   (BusCurrState == STATE_BUS_UNCACHED_WRITE) |
                           (BusCurrState == STATE_BUS_WRITE);

  assign UnCachedLSUBusRead = (BusCurrState == STATE_BUS_READY & UnCachedAccess & LSURWM[1] & ~IgnoreRequest) |
							  (BusCurrState == STATE_BUS_UNCACHED_READ);
  assign LSUBusRead = UnCachedLSUBusRead | (BusCurrState == STATE_BUS_FETCH) | (BusCurrState == STATE_BUS_READY & DCacheFetchLine);

  assign DCacheBusAck = (BusCurrState == STATE_BUS_FETCH & WordCountFlag & LSUBusAck) |
						(BusCurrState == STATE_BUS_WRITE & WordCountFlag & LSUBusAck);
  assign BusCommittedM = BusCurrState != STATE_BUS_READY;
  assign SelUncachedAdr = (BusCurrState == STATE_BUS_READY & (|LSURWM & UnCachedAccess)) |
						  (BusCurrState == STATE_BUS_UNCACHED_READ |
						   BusCurrState == STATE_BUS_UNCACHED_READ_DONE |
						   BusCurrState == STATE_BUS_UNCACHED_WRITE |
						   BusCurrState == STATE_BUS_UNCACHED_WRITE_DONE) |
						  ~CACHE_ENABLED; // if no dcache always select uncachedadr.
endmodule

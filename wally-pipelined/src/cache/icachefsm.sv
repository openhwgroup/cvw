///////////////////////////////////////////
// icache.sv
//
// Written: ross1728@gmail.com June 04, 2021
// Modified: 
//
// Purpose: I Cache controller
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module icachefsm
  (// Inputs from pipeline
   input logic 		  clk, reset,

   input logic 		  CPUBusy,

   input logic 		  IgnoreRequest,
   input logic 		  CacheableF,

   // BUS interface
   input logic 		  ICacheBusAck,

   // icache internal inputs
   input logic 		  hit,

   // Load data into the cache
   output logic 	  ICacheMemWriteEnable,

   // Outputs to pipeline control stuff
   output logic 	  ICacheStallF,

   // Bus interface outputs
   output logic 	  ICacheFetchLine,

   // icache internal outputs
   output logic       SelAdr,
   output logic 	  LRUWriteEn
   );

  // FSM states
  typedef enum 		  {STATE_READY,

					   STATE_MISS_FETCH_WDV, // aligned miss, issue read to AHB and wait for data.
					   STATE_MISS_FETCH_DONE, // write data into SRAM/LUT
					   STATE_MISS_READ, // read block 1 from SRAM/LUT
					   STATE_MISS_READ_DELAY, // read block 1 from SRAM/LUT  		

					   STATE_CPU_BUSY
					   } statetype;
  
  (* mark_debug = "true" *)  statetype CurrState, NextState;
  logic 			  PreCntEn;

  // the FSM is always runing, do not stall.
  always_ff @(posedge clk)
    if (reset)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  // Next state logic
  always_comb begin
    //IfuBusFetch = 1'b0;
    ICacheMemWriteEnable = 1'b0;
    SelAdr = 1'b0;
    ICacheStallF = 1'b1;
    LRUWriteEn = 1'b0;
    case (CurrState)
      STATE_READY: begin
        SelAdr = 1'b0;
		if(IgnoreRequest) begin
		  SelAdr = 1'b1;
		  NextState = STATE_READY;
		end
		else if (CacheableF & hit) begin
          ICacheStallF = 1'b0;
		  LRUWriteEn = 1'b1;
		  if(CPUBusy) begin
			NextState = STATE_CPU_BUSY;
			SelAdr = 1'b1;
		  end else begin
            NextState = STATE_READY;
		  end
        end else if (CacheableF & ~hit) begin
		  SelAdr = 1'b1;                                         /// *********(
          NextState = STATE_MISS_FETCH_WDV;
        end else begin
		  if(CPUBusy) begin
			NextState = STATE_CPU_BUSY;
			SelAdr = 1'b1;
		  end else begin
            NextState = STATE_READY;
		  end
        end
      end
      // branch 3 miss no spill
      STATE_MISS_FETCH_WDV: begin
        SelAdr = 1'b1;
        //IfuBusFetch = 1'b1;
        if (ICacheBusAck) begin
          NextState = STATE_MISS_FETCH_DONE;	  
        end else begin
          NextState = STATE_MISS_FETCH_WDV;
        end
      end
      STATE_MISS_FETCH_DONE: begin
        SelAdr = 1'b1;
        ICacheMemWriteEnable = 1'b1;
        NextState = STATE_MISS_READ;
      end
      STATE_MISS_READ: begin
        SelAdr = 1'b1;
        NextState = STATE_MISS_READ_DELAY;
      end
      STATE_MISS_READ_DELAY: begin
		ICacheStallF = 1'b0;
		LRUWriteEn = 1'b1;
		if(CPUBusy) begin
		  SelAdr = 1'b1;
		  NextState = STATE_CPU_BUSY;
		  SelAdr = 1'b1;
		end else begin
          NextState = STATE_READY;
		end
      end
      STATE_CPU_BUSY: begin
		ICacheStallF = 1'b0;
        if(CPUBusy) begin
		  NextState = STATE_CPU_BUSY;
		  SelAdr = 1'b1;
		end
		else begin
		  NextState = STATE_READY;
		end
      end
      default: begin
        SelAdr = 1'b1;
        NextState = STATE_READY;
      end
    endcase
  end

  assign ICacheFetchLine = CurrState == STATE_MISS_FETCH_WDV;
  
  
endmodule

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

   // inputs from mmu
   input logic 		  ITLBMissF,
   input logic 		  ITLBWriteF,

   input logic 		  ExceptionM, PendingInterruptM,

   // BUS interface
   input logic 		  ICacheBusAck,

   // icache internal inputs
   input logic 		  hit,
   input logic 		  FetchCountFlag,
   input logic 		  spill,

   // icache internal outputs
   output logic 	  ICacheReadEn,
   // Load data into the cache
   output logic 	  ICacheMemWriteEnable,

   // Outputs to pipeline control stuff
   output logic 	  ICacheStallF,

   // Bus interface outputs
   output logic 	  IfuBusFetch,

   // icache internal outputs
   output logic 	  spillSave,
   output logic 	  CntEn,
   output logic 	  CntReset,
   output logic [1:0] SelAdr,
   output logic 	  LRUWriteEn
   );

  // FSM states
  typedef enum 		  {STATE_READY,
					   STATE_HIT_SPILL, // spill, block 0 hit
					   STATE_HIT_SPILL_MISS_FETCH_WDV, // block 1 miss, issue read to AHB and wait data.
					   STATE_HIT_SPILL_MISS_FETCH_DONE, // write data into SRAM/LUT
					   STATE_HIT_SPILL_MERGE,   // Read block 0 of CPU access, should be able to optimize into STATE_HIT_SPILL.

					   // a challenge is the spill signal gets us out of the ready state and moves us to
					   // 1 of the 2 spill branches.  However the original fsm design had us return to
					   // the ready state when the spill + hits/misses were fully resolved.  The problem
					   // is the spill signal is based on PCPF so when we return to READY to check if the
					   // cache has a hit it still expresses spill.  We can fix in 1 of two ways.
					   // 1. we can add 1 extra state at the end of each spill branch to returns the instruction
					   // to the CPU advancing the CPU and icache to the next instruction.
					   // 2. We can assert a signal which is delayed 1 cycle to suppress the spill when we get
					   // to the READY state.
					   // The first first option is more robust and increases the number of states by 2.  The
					   // second option is seams like it should work, but I worry there is a hidden interaction 
					   // between CPU stalling and that register.
					   // Picking option 1.

					   STATE_HIT_SPILL_FINAL, // this state replicates STATE_READY's replay of the
					   // spill access but does nto consider spill.  It also does not do another operation.
  
					   STATE_MISS_FETCH_WDV, // aligned miss, issue read to AHB and wait for data.
					   STATE_MISS_FETCH_DONE, // write data into SRAM/LUT
					   STATE_MISS_READ, // read block 1 from SRAM/LUT
					   STATE_MISS_READ_DELAY, // read block 1 from SRAM/LUT  		

					   STATE_MISS_SPILL_FETCH_WDV, // spill, miss on block 0, issue read to AHB and wait
					   STATE_MISS_SPILL_FETCH_DONE, // write data into SRAM/LUT
					   STATE_MISS_SPILL_READ1, // read block 0 from SRAM/LUT
					   STATE_MISS_SPILL_2, // return to ready if hit or do second block update.
					   STATE_MISS_SPILL_2_START, // return to ready if hit or do second block update.  
					   STATE_MISS_SPILL_MISS_FETCH_WDV, // miss on block 1, issue read to AHB and wait
					   STATE_MISS_SPILL_MISS_FETCH_DONE, // write data to SRAM/LUT
					   STATE_MISS_SPILL_MERGE, // read block 0 of CPU access,

					   STATE_MISS_SPILL_FINAL, // this state replicates STATE_READY's replay of the
					   // spill access but does nto consider spill.  It also does not do another operation.

					   STATE_CPU_BUSY,
					   STATE_CPU_BUSY_SPILL		
					   } statetype;
  
  (* mark_debug = "true" *)  statetype CurrState, NextState;
  logic 			  PreCntEn;

  // the FSM is always runing, do not stall.
  always_ff @(posedge clk)
    if (reset)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  // Next state logic
  always_comb begin
    CntReset = 1'b0;
    PreCntEn = 1'b0;
    //IfuBusFetch = 1'b0;
    ICacheMemWriteEnable = 1'b0;
    spillSave = 1'b0;
    SelAdr = 2'b00;
    ICacheReadEn = 1'b0;
    ICacheStallF = 1'b1;
    LRUWriteEn = 1'b0;
    case (CurrState)
      STATE_READY: begin
        SelAdr = 2'b00;
        ICacheReadEn = 1'b1;
/* -----\/----- EXCLUDED -----\/-----
        if (ITLBMissF & ~(ExceptionM | PendingInterruptM)) begin
          NextState = STATE_TLB_MISS;
        end else 
 -----/\----- EXCLUDED -----/\----- */
		if(ITLBMissF) begin
		  NextState = STATE_READY;
		  SelAdr = 2'b01;
		  ICacheStallF = 1'b0;
		end
		else if (hit & ~spill) begin
          ICacheStallF = 1'b0;
		  LRUWriteEn = 1'b1;
		  if(CPUBusy) begin
			NextState = STATE_CPU_BUSY;
			SelAdr = 2'b01;
		  end else begin
            NextState = STATE_READY;
		  end
        end else if (hit & spill) begin
          spillSave = 1'b1;
          SelAdr = 2'b10;
          LRUWriteEn = 1'b1;
		  NextState = STATE_HIT_SPILL;
        end else if (~hit & ~spill) begin
          CntReset = 1'b1;
		  SelAdr = 2'b01;                                         /// *********(
          NextState = STATE_MISS_FETCH_WDV;
        end else if (~hit & spill) begin
          CntReset = 1'b1;
          SelAdr = 2'b01;
          NextState = STATE_MISS_SPILL_FETCH_WDV;
        end else begin
		  if(CPUBusy) begin
			NextState = STATE_CPU_BUSY;
			SelAdr = 2'b01;
		  end else begin
            NextState = STATE_READY;
		  end
        end
      end
      // branch 1,  hit spill and 2, miss spill hit
      STATE_HIT_SPILL: begin
        SelAdr = 2'b10;
        ICacheReadEn = 1'b1;
        if (hit) begin
          NextState = STATE_HIT_SPILL_FINAL;
        end else begin
          CntReset = 1'b1;
          NextState = STATE_HIT_SPILL_MISS_FETCH_WDV;
        end
      end
      STATE_HIT_SPILL_MISS_FETCH_WDV: begin
        SelAdr = 2'b10;
        //IfuBusFetch = 1'b1;
        PreCntEn = 1'b1;
        if (FetchCountFlag & ICacheBusAck) begin
          NextState = STATE_HIT_SPILL_MISS_FETCH_DONE;
        end else begin
          NextState = STATE_HIT_SPILL_MISS_FETCH_WDV;
        end
      end
      STATE_HIT_SPILL_MISS_FETCH_DONE: begin
        SelAdr = 2'b10;
        ICacheMemWriteEnable = 1'b1;
        NextState = STATE_HIT_SPILL_MERGE;
      end
      STATE_HIT_SPILL_MERGE: begin
        SelAdr = 2'b10;
        ICacheReadEn = 1'b1;
        NextState = STATE_HIT_SPILL_FINAL;
      end
      STATE_HIT_SPILL_FINAL: begin
        ICacheReadEn = 1'b1;
        SelAdr = 2'b00;
        ICacheStallF = 1'b0;
		LRUWriteEn = 1'b1;
		
		if(CPUBusy) begin
		  NextState = STATE_CPU_BUSY_SPILL;
		  SelAdr = 2'b10;
		end else begin
          NextState = STATE_READY;
		end
		
      end
      // branch 3 miss no spill
      STATE_MISS_FETCH_WDV: begin
        SelAdr = 2'b01;
        //IfuBusFetch = 1'b1;
        PreCntEn = 1'b1;
        if (FetchCountFlag & ICacheBusAck) begin
          NextState = STATE_MISS_FETCH_DONE;	  
        end else begin
          NextState = STATE_MISS_FETCH_WDV;
        end
      end
      STATE_MISS_FETCH_DONE: begin
        SelAdr = 2'b01;
        ICacheMemWriteEnable = 1'b1;
        NextState = STATE_MISS_READ;
      end
      STATE_MISS_READ: begin
        SelAdr = 2'b01;
        ICacheReadEn = 1'b1;
        NextState = STATE_MISS_READ_DELAY;
      end
      STATE_MISS_READ_DELAY: begin
        //SelAdr = 2'b01;
        ICacheReadEn = 1'b1;
		ICacheStallF = 1'b0;
		LRUWriteEn = 1'b1;
		if(CPUBusy) begin
		  SelAdr = 2'b01;
		  NextState = STATE_CPU_BUSY;
		  SelAdr = 2'b01;
		end else begin
          NextState = STATE_READY;
		end
      end
      // branch 4 miss spill hit, and 5 miss spill miss
      STATE_MISS_SPILL_FETCH_WDV: begin
        SelAdr = 2'b01;
        PreCntEn = 1'b1;
        //IfuBusFetch = 1'b1;	
        if (FetchCountFlag & ICacheBusAck) begin 
          NextState = STATE_MISS_SPILL_FETCH_DONE;
        end else begin
          NextState = STATE_MISS_SPILL_FETCH_WDV;
        end
      end
      STATE_MISS_SPILL_FETCH_DONE: begin
        SelAdr = 2'b01;	
        ICacheMemWriteEnable = 1'b1;
        NextState = STATE_MISS_SPILL_READ1;
      end
      STATE_MISS_SPILL_READ1: begin // always be a hit as we just wrote that cache block.
        SelAdr = 2'b01;	 // there is a 1 cycle delay after setting the address before the date arrives.
        ICacheReadEn = 1'b1;
		LRUWriteEn = 1'b1;
        NextState = STATE_MISS_SPILL_2;
      end
      STATE_MISS_SPILL_2: begin
        SelAdr = 2'b10;
        spillSave = 1'b1; /// *** Could pipeline these to make it clearer in the fsm.
        ICacheReadEn = 1'b1;
        NextState = STATE_MISS_SPILL_2_START;
      end
      STATE_MISS_SPILL_2_START: begin
        if (~hit) begin
          CntReset = 1'b1;
          NextState = STATE_MISS_SPILL_MISS_FETCH_WDV;
        end else begin
          ICacheReadEn = 1'b1;
          SelAdr = 2'b00;
          ICacheStallF = 1'b0;
		  LRUWriteEn = 1'b1;
		  if(CPUBusy) begin
			NextState = STATE_CPU_BUSY_SPILL;
			SelAdr = 2'b10;
		  end else begin
            NextState = STATE_READY;
		  end
        end
      end
      STATE_MISS_SPILL_MISS_FETCH_WDV: begin
        SelAdr = 2'b10;
        PreCntEn = 1'b1;
        //IfuBusFetch = 1'b1;	
        if (FetchCountFlag & ICacheBusAck) begin
          NextState = STATE_MISS_SPILL_MISS_FETCH_DONE;	  
        end else begin
          NextState = STATE_MISS_SPILL_MISS_FETCH_WDV;
        end
      end
      STATE_MISS_SPILL_MISS_FETCH_DONE: begin
        SelAdr = 2'b10;
        ICacheMemWriteEnable = 1'b1;
        NextState = STATE_MISS_SPILL_MERGE;
      end
      STATE_MISS_SPILL_MERGE: begin
        SelAdr = 2'b10;
        ICacheReadEn = 1'b1;	
        NextState = STATE_MISS_SPILL_FINAL;
      end
      STATE_MISS_SPILL_FINAL: begin
        ICacheReadEn = 1'b1;
        SelAdr = 2'b00;
        ICacheStallF = 1'b0;	
		LRUWriteEn = 1'b1;
		if(CPUBusy) begin
		  NextState = STATE_CPU_BUSY_SPILL;
		  SelAdr = 2'b10;
		end else begin
          NextState = STATE_READY;
		end
      end
      STATE_CPU_BUSY: begin
		ICacheStallF = 1'b0;
        if(CPUBusy) begin
		  NextState = STATE_CPU_BUSY;
		  SelAdr = 2'b01;
		end
		else begin
		  NextState = STATE_READY;
		end
      end
      STATE_CPU_BUSY_SPILL: begin
		ICacheStallF = 1'b0;
		ICacheReadEn = 1'b1;
		if(CPUBusy) begin
		  NextState = STATE_CPU_BUSY_SPILL;
		  SelAdr = 2'b10;
		end
		else begin
		  NextState = STATE_READY;
		end
      end
      default: begin
        SelAdr = 2'b01;
        NextState = STATE_READY;
      end
      // *** add in error handling and invalidate/evict
    endcase
  end

  assign CntEn = PreCntEn & ICacheBusAck;
  assign IfuBusFetch = (CurrState == STATE_HIT_SPILL_MISS_FETCH_WDV) ||
					  (CurrState == STATE_MISS_FETCH_WDV) ||
					  (CurrState == STATE_MISS_SPILL_FETCH_WDV) ||
					  (CurrState == STATE_MISS_SPILL_MISS_FETCH_WDV);
  
endmodule

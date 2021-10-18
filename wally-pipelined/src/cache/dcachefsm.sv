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

module dcachefsm
  (input logic clk,
   input logic 	      reset,
   // inputs from IEU
   input logic [1:0]  MemRWM,
   input logic [1:0]  AtomicM,
   input logic 	      FlushDCacheM,
   // hazard inputs
   input logic 	      ExceptionM,
   input logic 	      PendingInterruptM,
   input logic 	      StallWtoDCache,
   // mmu inputs
   input logic 	      DTLBMissM,
   input logic 	      ITLBMissF,
   input logic 	      CacheableM,
   input logic 	      DTLBWriteM,
   input logic 	      ITLBWriteF,
   input logic 	      WalkerInstrPageFaultF,
   // hptw inputs
   input logic 	      SelPTW,
   input logic 	      WalkerPageFaultM,
   // Bus inputs
   input logic 	      AHBAck, // from ahb
   // dcache internals
   input logic 	      CacheHit,
   input logic 	      FetchCountFlag,
   input logic 	      VictimDirty,
   input logic 	      FlushAdrFlag,
   
   // hazard outputs
   output logic       DCacheStall,
   output logic       CommittedM,
   // counter outputs
   output logic       DCacheMiss,
   output logic       DCacheAccess,
   // hptw outputs
   output logic       MemAfterIWalkDone,
   // Bus outputs
   output logic       AHBRead,
   output logic       AHBWrite,

   // dcache internals
   output logic [1:0] SelAdrM,
   output logic       CntEn,
   output logic       SetValid,
   output logic       ClearValid,
   output logic       SetDirty,
   output logic       ClearDirty,
   output logic       SRAMWordWriteEnableM,
   output logic       SRAMBlockWriteEnableM,
   output logic       CntReset,
   output logic       SelUncached,
   output logic       SelEvict,
   output logic       LRUWriteEn,
   output logic       SelFlush,
   output logic       FlushAdrCntEn,
   output logic       FlushWayCntEn, 
   output logic       FlushAdrCntRst,
   output logic       FlushWayCntRst,
   output logic       VDWriteEnable

   );
  
  logic 	     PreCntEn;
  logic 	     AnyCPUReqM;
  
  typedef enum {STATE_READY,

		STATE_MISS_FETCH_WDV,
		STATE_MISS_FETCH_DONE,
		STATE_MISS_EVICT_DIRTY,
		STATE_MISS_WRITE_CACHE_BLOCK,
		STATE_MISS_READ_WORD,
		STATE_MISS_READ_WORD_DELAY,
		STATE_MISS_WRITE_WORD,

		STATE_PTW_READY,
		STATE_PTW_READ_MISS_FETCH_WDV,
		STATE_PTW_READ_MISS_FETCH_DONE,
		STATE_PTW_READ_MISS_WRITE_CACHE_BLOCK,
		STATE_PTW_READ_MISS_EVICT_DIRTY,		
		STATE_PTW_READ_MISS_READ_WORD,
		STATE_PTW_READ_MISS_READ_WORD_DELAY,
		STATE_PTW_ACCESS_AFTER_WALK,		

		STATE_UNCACHED_WRITE,
		STATE_UNCACHED_WRITE_DONE,
		STATE_UNCACHED_READ,
		STATE_UNCACHED_READ_DONE,

		STATE_PTW_FAULT_READY,
		STATE_PTW_FAULT_CPU_BUSY,
		STATE_PTW_FAULT_MISS_FETCH_WDV,
		STATE_PTW_FAULT_MISS_FETCH_DONE,
		STATE_PTW_FAULT_MISS_WRITE_CACHE_BLOCK,
		STATE_PTW_FAULT_MISS_READ_WORD,
		STATE_PTW_FAULT_MISS_READ_WORD_DELAY,
		STATE_PTW_FAULT_MISS_WRITE_WORD,
		STATE_PTW_FAULT_MISS_WRITE_WORD_DELAY,
		STATE_PTW_FAULT_MISS_EVICT_DIRTY,

		STATE_PTW_FAULT_UNCACHED_WRITE,
		STATE_PTW_FAULT_UNCACHED_WRITE_DONE,
		STATE_PTW_FAULT_UNCACHED_READ,
		STATE_PTW_FAULT_UNCACHED_READ_DONE,

		STATE_CPU_BUSY,
		STATE_CPU_BUSY_FINISH_AMO,
		
		STATE_FLUSH,
		STATE_FLUSH_WRITE_BACK,
		STATE_FLUSH_CLEAR_DIRTY} statetype;

  statetype CurrState, NextState;

  assign AnyCPUReqM = |MemRWM | (|AtomicM);
  assign CntEn = PreCntEn & AHBAck;


  always_ff @(posedge clk, posedge reset)
    if (reset)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;  
  
  // next state logic and some state ouputs.
  always_comb begin
    DCacheStall = 1'b0;
    SelAdrM = 2'b00;
    PreCntEn = 1'b0;
    SetValid = 1'b0;
    ClearValid = 1'b0;
    SetDirty = 1'b0;    
    ClearDirty = 1'b0;
    SRAMWordWriteEnableM = 1'b0;
    SRAMBlockWriteEnableM = 1'b0;
    CntReset = 1'b0;
    AHBRead = 1'b0;
    AHBWrite = 1'b0;
    CommittedM = 1'b0;        
    SelUncached = 1'b0;
    SelEvict = 1'b0;
    DCacheAccess = 1'b0;
    DCacheMiss = 1'b0;
    LRUWriteEn = 1'b0;
    MemAfterIWalkDone = 1'b0;
    SelFlush = 1'b0;
    FlushAdrCntEn = 1'b0;
    FlushWayCntEn = 1'b0;
    FlushAdrCntRst = 1'b0;
    FlushWayCntRst = 1'b0;	
    VDWriteEnable = 1'b0;
    NextState = STATE_READY;

    case (CurrState)
      STATE_READY: begin

	CntReset = 1'b0;
	DCacheStall = 1'b0;
	AHBRead = 1'b0;	  
	AHBWrite = 1'b0;
	DCacheAccess = 1'b0;
	DCacheMiss = 1'b0;
	SelAdrM = 2'b00;
	SRAMWordWriteEnableM = 1'b0;
	SetDirty = 1'b0;
	LRUWriteEn = 1'b0;
	CommittedM = 1'b0;

	if(FlushDCacheM) begin
	  NextState = STATE_FLUSH;
	  DCacheStall = 1'b1;
	  SelAdrM = 2'b11;
	  FlushAdrCntRst = 1'b1;
	  FlushWayCntRst = 1'b1;	
	end

	// TLB Miss	
	else if((AnyCPUReqM & DTLBMissM) | ITLBMissF) begin
	  // the LSU arbiter has not yet selected the PTW.
	  // The CPU needs to be stalled until that happens.
	  // If we set DCacheStall for 1 cycle before going to
	  // PTW ready the CPU will stall.
	  // The page table walker asserts it's control 1 cycle
	  // after the TLBs miss.
	  CommittedM = 1'b1;
	  DCacheStall = 1'b1;
	  NextState = STATE_PTW_READY;
	end
	// amo hit
	else if(AtomicM[1] & (&MemRWM) & CacheableM & ~(ExceptionM | PendingInterruptM) & CacheHit & ~DTLBMissM) begin
	  SelAdrM = 2'b10;
	  DCacheStall = 1'b0;
	  
	  if(StallWtoDCache) begin 
	    NextState = STATE_CPU_BUSY_FINISH_AMO;
	    SelAdrM = 2'b10;
	  end
	  else begin
	    SRAMWordWriteEnableM = 1'b1;
	    SetDirty = 1'b1;
	    LRUWriteEn = 1'b1;
	    NextState = STATE_READY;
	  end
	end
	// read hit valid cached
	else if(MemRWM[1] & CacheableM & ~(ExceptionM | PendingInterruptM) & CacheHit & ~DTLBMissM) begin
	  DCacheStall = 1'b0;
	  DCacheAccess = 1'b1;
	  LRUWriteEn = 1'b1;
	  
	  if(StallWtoDCache) begin
	    NextState = STATE_CPU_BUSY;
            SelAdrM = 2'b10;
	  end
	  else begin
	    NextState = STATE_READY;
	    end
	end
	// write hit valid cached
	else if (MemRWM[0] & CacheableM & ~(ExceptionM | PendingInterruptM) & CacheHit & ~DTLBMissM) begin
	  SelAdrM = 2'b10;
	  DCacheStall = 1'b0;
	  SRAMWordWriteEnableM = 1'b1;
	  SetDirty = 1'b1;
	  LRUWriteEn = 1'b1;
	  
	  if(StallWtoDCache) begin 
	    NextState = STATE_CPU_BUSY;
	    SelAdrM = 2'b10;
	  end
	  else begin
	    NextState = STATE_READY;
	  end
	end
	// read or write miss valid cached
	else if((|MemRWM) & CacheableM & ~(ExceptionM | PendingInterruptM) & ~CacheHit & ~DTLBMissM) begin
	  NextState = STATE_MISS_FETCH_WDV;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  DCacheAccess = 1'b1;
	  DCacheMiss = 1'b1;
	end
	// uncached write
	else if(MemRWM[0] & ~CacheableM & ~(ExceptionM | PendingInterruptM) & ~DTLBMissM) begin
	  NextState = STATE_UNCACHED_WRITE;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  AHBWrite = 1'b1;
	end
	// uncached read
	else if(MemRWM[1] & ~CacheableM & ~(ExceptionM | PendingInterruptM) & ~DTLBMissM) begin
	  NextState = STATE_UNCACHED_READ;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  AHBRead = 1'b1;	  
	end
	// fault
	else if(AnyCPUReqM & (ExceptionM | PendingInterruptM) & ~DTLBMissM) begin
	  NextState = STATE_READY;
	end
	else NextState = STATE_READY;
      end
      
      STATE_MISS_FETCH_WDV: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBRead = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	
        if (FetchCountFlag & AHBAck) begin
          NextState = STATE_MISS_FETCH_DONE;
        end else begin
          NextState = STATE_MISS_FETCH_WDV;
        end
      end

      STATE_MISS_FETCH_DONE: begin
	DCacheStall = 1'b1;
	SelAdrM = 2'b10;
        CntReset = 1'b1;
	CommittedM = 1'b1;
	if(VictimDirty) begin
	  NextState = STATE_MISS_EVICT_DIRTY;
	end else begin
	  NextState = STATE_MISS_WRITE_CACHE_BLOCK;
	end
      end

      STATE_MISS_WRITE_CACHE_BLOCK: begin
	SRAMBlockWriteEnableM = 1'b1;
	DCacheStall = 1'b1;
	NextState = STATE_MISS_READ_WORD;
	SelAdrM = 2'b10;
	SetValid = 1'b1;
	ClearDirty = 1'b1;
	CommittedM = 1'b1;
	//LRUWriteEn = 1'b1;  // DO not update LRU on SRAM fetch update.  Wait for subsequent read/write
      end

      STATE_MISS_READ_WORD: begin
	SelAdrM = 2'b10;
	DCacheStall = 1'b1;
	CommittedM = 1'b1;
	if (MemRWM[0] & ~AtomicM[1]) begin // handles stores and amo write.
	  NextState = STATE_MISS_WRITE_WORD;
	end else begin
	  NextState = STATE_MISS_READ_WORD_DELAY;
	  // delay state is required as the read signal MemRWM[1] is still high when we
	  // return to the ready state because the cache is stalling the cpu.
	end
      end

      STATE_MISS_READ_WORD_DELAY: begin
	//SelAdrM = 2'b10;
	CommittedM = 1'b1;
	SRAMWordWriteEnableM = 1'b0;
	SetDirty = 1'b0;
	LRUWriteEn = 1'b0;
	if(&MemRWM & AtomicM[1]) begin // amo write
	  SelAdrM = 2'b10;
	  if(StallWtoDCache) begin 
	    NextState = STATE_CPU_BUSY_FINISH_AMO;
	  end
	  else begin
	    SRAMWordWriteEnableM = 1'b1;
	    SetDirty = 1'b1;
	    LRUWriteEn = 1'b1;
	    NextState = STATE_READY;
	  end
	end else begin
	  LRUWriteEn = 1'b1;
	  if(StallWtoDCache) begin 
	    NextState = STATE_CPU_BUSY;
	    SelAdrM = 2'b10;
	  end
	  else begin
	    NextState = STATE_READY;
	  end
	end
      end

      STATE_MISS_WRITE_WORD: begin
	SRAMWordWriteEnableM = 1'b1;
	SetDirty = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	LRUWriteEn = 1'b1;
	if(StallWtoDCache) begin 
	  NextState = STATE_CPU_BUSY;
	  SelAdrM = 2'b10;
	end
	else begin
	  NextState = STATE_READY;
	end
      end

      STATE_MISS_EVICT_DIRTY: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBWrite = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	SelEvict = 1'b1;
	if(FetchCountFlag & AHBAck) begin
	  NextState = STATE_MISS_WRITE_CACHE_BLOCK;
	end else begin
	  NextState = STATE_MISS_EVICT_DIRTY;
	end	  
      end

      STATE_PTW_READY: begin
	// now all output connect to PTW instead of CPU.
	CommittedM = 1'b1;
	SelAdrM = 2'b00;
	DCacheStall = 1'b0;
	LRUWriteEn = 1'b0;
	CntReset = 1'b0;

	// In this branch we remove stall and go back to ready.  There is no request for memory from the
	// datapath or the walker had a fault.
	// types 3b, 4a, 4b, and 7c.
	if ((DTLBMissM & WalkerPageFaultM) | // 3b
	    (ITLBMissF & (WalkerInstrPageFaultF | ITLBWriteF) & ~AnyCPUReqM & ~DTLBMissM) | // 4a and 4b
	    (DTLBMissM & ITLBMissF & WalkerPageFaultM)) begin // 7c
	  NextState = STATE_READY;
	  DCacheStall = 1'b0;
	end
	// in this branch we go back to ready, but there is a memory operation from
	// the datapath so we MUST stall and replay the operation.
	// types 3a and 5a
	else if ((DTLBMissM & DTLBWriteM) |  // 3a
		 (ITLBMissF & ITLBWriteF & AnyCPUReqM)) begin // 5a
	  NextState = STATE_READY;
	  DCacheStall = 1'b1;
	  SelAdrM = 2'b01;
	end

	// like 5a we want to stall and go to the ready state, but we also have to save
	// the WalkerInstrPageFaultF so it is held until the end of the memory operation
	// from the datapath.
	// types 5b
	else if (ITLBMissF & WalkerInstrPageFaultF & AnyCPUReqM) begin // 5b
	  NextState = STATE_PTW_FAULT_READY;
	  DCacheStall = 1'b1;
	  SelAdrM = 2'b01;
	end

	// in this branch we stay in ptw_ready because we are doing an itlb walk
	// after a dtlb walk.
	// types 7a and 7b.
	else if (DTLBMissM & DTLBWriteM & ITLBMissF)begin
	  NextState = STATE_PTW_READY;
	  DCacheStall = 1'b0;
	  
	// read hit valid cached
	end else if(MemRWM[1] & CacheableM & ~ExceptionM & CacheHit) begin
	  NextState = STATE_PTW_READY;
	  DCacheStall = 1'b0;
	  LRUWriteEn = 1'b1;
	end

	// read miss valid cached
	else if(SelPTW & MemRWM[1] & CacheableM & ~ExceptionM & ~CacheHit) begin
	  NextState = STATE_PTW_READ_MISS_FETCH_WDV;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	end

	else begin
	  NextState = STATE_PTW_READY;
	  DCacheStall = 1'b0;
	end
      end

      STATE_PTW_READ_MISS_FETCH_WDV: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBRead = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	
        if(FetchCountFlag & AHBAck) begin
          NextState = STATE_PTW_READ_MISS_FETCH_DONE;
        end else begin
          NextState = STATE_PTW_READ_MISS_FETCH_WDV;
        end
      end

      STATE_PTW_READ_MISS_FETCH_DONE: begin
	DCacheStall = 1'b1;
	SelAdrM = 2'b10;
        CntReset = 1'b1;
	CommittedM = 1'b1;
        CntReset = 1'b1;
	if(VictimDirty) begin
	  NextState = STATE_PTW_READ_MISS_EVICT_DIRTY;
	end else begin
	  NextState = STATE_PTW_READ_MISS_WRITE_CACHE_BLOCK;
	end
      end

      STATE_PTW_READ_MISS_EVICT_DIRTY: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBWrite = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	SelEvict = 1'b1;
	if(FetchCountFlag & AHBAck) begin
	  NextState = STATE_PTW_READ_MISS_WRITE_CACHE_BLOCK;
	end else begin
	  NextState = STATE_PTW_READ_MISS_EVICT_DIRTY;
	end	  
      end
      

      STATE_PTW_READ_MISS_WRITE_CACHE_BLOCK: begin
	SRAMBlockWriteEnableM = 1'b1;
	DCacheStall = 1'b1;
	NextState = STATE_PTW_READ_MISS_READ_WORD;
	SelAdrM = 2'b10;
	SetValid = 1'b1;
	ClearDirty = 1'b1;
	CommittedM = 1'b1;
	//LRUWriteEn = 1'b1;
      end

      STATE_PTW_READ_MISS_READ_WORD: begin
	SelAdrM = 2'b10;
	DCacheStall = 1'b1;
	CommittedM = 1'b1;
	NextState = STATE_PTW_READ_MISS_READ_WORD_DELAY;
      end

      STATE_PTW_READ_MISS_READ_WORD_DELAY: begin
	SelAdrM = 2'b10;
	NextState = STATE_PTW_READY;
	CommittedM = 1'b1;
      end
      
      STATE_PTW_ACCESS_AFTER_WALK: begin
	DCacheStall = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	LRUWriteEn = 1'b1;
	NextState = STATE_READY;
      end
      
      STATE_CPU_BUSY: begin
	CommittedM = 1'b1;
	SelAdrM = 2'b00;
	if(StallWtoDCache) begin
	  NextState = STATE_CPU_BUSY;
	  SelAdrM = 2'b10;
	end
	else begin
	  NextState = STATE_READY;
	end
      end

      STATE_CPU_BUSY_FINISH_AMO: begin
	CommittedM = 1'b1;
	SelAdrM = 2'b10;
	SRAMWordWriteEnableM = 1'b0;
	SetDirty = 1'b0;
	LRUWriteEn = 1'b0;
	if(StallWtoDCache) begin
	  NextState = STATE_CPU_BUSY_FINISH_AMO;
	end
	else begin
	  SRAMWordWriteEnableM = 1'b1;
	  SetDirty = 1'b1;
	  LRUWriteEn = 1'b1;
	  NextState = STATE_READY;
	end
      end

      STATE_UNCACHED_WRITE : begin
	DCacheStall = 1'b1;	
	AHBWrite = 1'b1;
	CommittedM = 1'b1;
	if(AHBAck) begin
	  NextState = STATE_UNCACHED_WRITE_DONE;
	end else begin
	  NextState = STATE_UNCACHED_WRITE;
	end
      end

      STATE_UNCACHED_READ: begin
	DCacheStall = 1'b1;	
	AHBRead = 1'b1;
	CommittedM = 1'b1;
	if(AHBAck) begin
	  NextState = STATE_UNCACHED_READ_DONE;
	end else begin
	  NextState = STATE_UNCACHED_READ;
	end
      end
      
      STATE_UNCACHED_WRITE_DONE: begin
	CommittedM = 1'b1;
	SelAdrM = 2'b00;
	if(StallWtoDCache) begin
	  NextState = STATE_CPU_BUSY;
	  SelAdrM = 2'b10;
	end
	else begin
	  NextState = STATE_READY;
	end
      end

      STATE_UNCACHED_READ_DONE: begin
	CommittedM = 1'b1;
	SelUncached = 1'b1;
	SelAdrM = 2'b00;
	if(StallWtoDCache) begin 
	  NextState = STATE_CPU_BUSY;
	  SelAdrM = 2'b10;
	end
	else begin
	  NextState = STATE_READY;
	end 
      end


      // itlb => instruction page fault states with memory request.
      STATE_PTW_FAULT_READY: begin
	DCacheStall = 1'b0;
	DCacheAccess = 1'b0;
	DCacheMiss = 1'b0;
	LRUWriteEn = 1'b0;
	SelAdrM = 2'b00;
	MemAfterIWalkDone = 1'b0;
	SetDirty = 1'b0;
	LRUWriteEn = 1'b0;
	CntReset = 1'b0;
	AHBWrite = 1'b0;
	AHBRead = 1'b0;
	CommittedM = 1'b0;
	NextState = STATE_READY;
	
	
	// read hit valid cached
	if(MemRWM[1] & CacheableM & CacheHit & ~DTLBMissM) begin
	  DCacheStall = 1'b0;
	  DCacheAccess = 1'b1;
	  LRUWriteEn = 1'b1;
	  
	  if(StallWtoDCache) begin
	    NextState = STATE_PTW_FAULT_CPU_BUSY;
            SelAdrM = 2'b10;
	  end
	  else begin
	    MemAfterIWalkDone = 1'b1;
	    NextState = STATE_READY;
	  end
	end
	
	// write hit valid cached
	else if (MemRWM[0] & CacheableM & CacheHit & ~DTLBMissM) begin
	  SelAdrM = 2'b10;
	  DCacheStall = 1'b0;
	  SRAMWordWriteEnableM = 1'b1;
	  SetDirty = 1'b1;
	  LRUWriteEn = 1'b1;
	  
	  if(StallWtoDCache) begin 
	    NextState = STATE_PTW_FAULT_CPU_BUSY;
	    SelAdrM = 2'b10;
	  end
	  else begin
	    MemAfterIWalkDone = 1'b1;
	    NextState = STATE_READY;
	  end
	end
	// read or write miss valid cached
	else if((|MemRWM) & CacheableM & ~CacheHit & ~DTLBMissM) begin
	  NextState = STATE_PTW_FAULT_MISS_FETCH_WDV;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  DCacheAccess = 1'b1;
	  DCacheMiss = 1'b1;
	end
	// uncached write
	else if(MemRWM[0] & ~CacheableM & ~DTLBMissM) begin
	  NextState = STATE_PTW_FAULT_UNCACHED_WRITE;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  AHBWrite = 1'b1;
	end
	// uncached read
	else if(MemRWM[1] & ~CacheableM & ~DTLBMissM) begin
	  NextState = STATE_PTW_FAULT_UNCACHED_READ;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  AHBRead = 1'b1;	  
	  MemAfterIWalkDone = 1'b0;
	end
	// fault
	else  begin
	  MemAfterIWalkDone = 1'b1;
	  NextState = STATE_READY;
	end
      end
      
      STATE_PTW_FAULT_CPU_BUSY: begin
	CommittedM = 1'b1;
	if(StallWtoDCache) begin
	  NextState = STATE_PTW_FAULT_CPU_BUSY;
	  MemAfterIWalkDone = 1'b0;
	  SelAdrM = 2'b10;
	end
	else begin
	  MemAfterIWalkDone = 1'b1;
	  NextState = STATE_READY;
	  SelAdrM = 2'b00;
	end
      end

      STATE_PTW_FAULT_MISS_FETCH_WDV: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBRead = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	
        if(FetchCountFlag & AHBAck) begin
          NextState = STATE_PTW_FAULT_MISS_FETCH_DONE;
        end else begin
          NextState = STATE_PTW_FAULT_MISS_FETCH_WDV;
        end
      end

      STATE_PTW_FAULT_MISS_FETCH_DONE: begin
	DCacheStall = 1'b1;
	SelAdrM = 2'b10;
        CntReset = 1'b1;
	CommittedM = 1'b1;
	if(VictimDirty) begin
	  NextState = STATE_PTW_FAULT_MISS_EVICT_DIRTY;
	end else begin
	  NextState = STATE_PTW_FAULT_MISS_WRITE_CACHE_BLOCK;
	end
      end

      STATE_PTW_FAULT_MISS_WRITE_CACHE_BLOCK: begin
	SRAMBlockWriteEnableM = 1'b1;
	DCacheStall = 1'b1;
	NextState = STATE_PTW_FAULT_MISS_READ_WORD;
	SelAdrM = 2'b10;
	SetValid = 1'b1;
	ClearDirty = 1'b1;
	CommittedM = 1'b1;
	//LRUWriteEn = 1'b1;  // DO not update LRU on SRAM fetch update.  Wait for subsequent read/write
      end

      STATE_PTW_FAULT_MISS_READ_WORD: begin
	SelAdrM = 2'b10;
	DCacheStall = 1'b1;
	CommittedM = 1'b1;
	if(MemRWM[1]) begin
	  NextState = STATE_PTW_FAULT_MISS_READ_WORD_DELAY;
	  // delay state is required as the read signal MemRWM[1] is still high when we
	  // return to the ready state because the cache is stalling the cpu.
	end else begin
	  NextState = STATE_PTW_FAULT_MISS_WRITE_WORD;
	end
      end

      STATE_PTW_FAULT_MISS_READ_WORD_DELAY: begin
	CommittedM = 1'b1;
	LRUWriteEn = 1'b1;
	if(StallWtoDCache) begin 
	  NextState = STATE_PTW_FAULT_CPU_BUSY;
	  SelAdrM = 2'b10;
	  MemAfterIWalkDone = 1'b0;
	end
	else begin
	  MemAfterIWalkDone = 1'b1;
	  NextState = STATE_READY;
	  SelAdrM = 2'b00;
	end
      end

      STATE_PTW_FAULT_MISS_WRITE_WORD: begin
	SRAMWordWriteEnableM = 1'b1;
	SetDirty = 1'b1;
	SelAdrM = 2'b10;
	DCacheStall = 1'b1;
	CommittedM = 1'b1;
	LRUWriteEn = 1'b1;
	NextState = STATE_PTW_FAULT_MISS_WRITE_WORD_DELAY;
      end

      STATE_PTW_FAULT_MISS_WRITE_WORD_DELAY: begin
	CommittedM = 1'b1;
	if(StallWtoDCache) begin 
	  NextState = STATE_PTW_FAULT_CPU_BUSY;
	  MemAfterIWalkDone = 1'b0;
	  SelAdrM = 2'b10;
	end
	else begin
	  MemAfterIWalkDone = 1'b1;
	  NextState = STATE_READY;
	  SelAdrM = 2'b00;
	end
      end

      STATE_PTW_FAULT_MISS_EVICT_DIRTY: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBWrite = 1'b1;
	SelAdrM = 2'b10;
	CommittedM = 1'b1;
	SelEvict = 1'b1;
	if(FetchCountFlag & AHBAck) begin
	  NextState = STATE_PTW_FAULT_MISS_WRITE_CACHE_BLOCK;
	end else begin
	  NextState = STATE_PTW_FAULT_MISS_EVICT_DIRTY;
	end	  
      end


      STATE_PTW_FAULT_UNCACHED_WRITE : begin
	DCacheStall = 1'b1;	
	AHBWrite = 1'b1;
	CommittedM = 1'b1;
	if(AHBAck) begin
	  NextState = STATE_PTW_FAULT_UNCACHED_WRITE_DONE;
	end else begin
	  NextState = STATE_PTW_FAULT_UNCACHED_WRITE;
	end
      end

      STATE_PTW_FAULT_UNCACHED_READ : begin
	DCacheStall = 1'b1;	
	AHBRead = 1'b1;
	CommittedM = 1'b1;
	if(AHBAck) begin
	  NextState = STATE_PTW_FAULT_UNCACHED_READ_DONE;
	end else begin
	  NextState = STATE_PTW_FAULT_UNCACHED_READ;
	end
      end
      
      STATE_PTW_FAULT_UNCACHED_WRITE_DONE: begin
	CommittedM = 1'b1;
	if(StallWtoDCache) begin
	  NextState = STATE_PTW_FAULT_CPU_BUSY;
	  MemAfterIWalkDone = 1'b0;
	  SelAdrM = 2'b10;
	end
	else begin
	  MemAfterIWalkDone = 1'b1;
	  NextState = STATE_READY;
	  SelAdrM = 2'b00;
	end
      end

      STATE_PTW_FAULT_UNCACHED_READ_DONE: begin
	CommittedM = 1'b1;
	SelUncached = 1'b1;
	if(StallWtoDCache) begin 
	  NextState = STATE_PTW_FAULT_CPU_BUSY;
	  SelAdrM = 2'b10;
	end
	else begin
	  MemAfterIWalkDone = 1'b1;
	  NextState = STATE_READY;
	end 
      end

      STATE_FLUSH: begin
	DCacheStall = 1'b1;
	CommittedM = 1'b1;
	SelAdrM = 2'b11;
	SelFlush = 1'b1;
	FlushAdrCntEn = 1'b1;
	FlushWayCntEn = 1'b1;
	CntReset = 1'b1;
	if(VictimDirty) begin
	  NextState = STATE_FLUSH_WRITE_BACK;
	  FlushAdrCntEn = 1'b0;
	  FlushWayCntEn = 1'b0;
	end else if (FlushAdrFlag) begin
	  NextState = STATE_READY;
	  DCacheStall = 1'b0;
	  FlushAdrCntEn = 1'b0;
	  FlushWayCntEn = 1'b0;	
	end else begin
	  NextState = STATE_FLUSH;
	end
      end

      STATE_FLUSH_WRITE_BACK: begin
	DCacheStall = 1'b1;
	AHBWrite = 1'b1;
	SelAdrM = 2'b11;
	CommittedM = 1'b1;
	SelFlush = 1'b1;
        PreCntEn = 1'b1;
	if(FetchCountFlag & AHBAck) begin
	  NextState = STATE_FLUSH_CLEAR_DIRTY;
	end else begin
	  NextState = STATE_FLUSH_WRITE_BACK;
	end	  
      end

      STATE_FLUSH_CLEAR_DIRTY: begin
	DCacheStall = 1'b1;
	ClearDirty = 1'b1;
	VDWriteEnable = 1'b1;
	SelFlush = 1'b1;
	SelAdrM = 2'b11;
	FlushAdrCntEn = 1'b0;
	FlushWayCntEn = 1'b0;	
	if(FlushAdrFlag) begin
	  NextState = STATE_READY;
	  DCacheStall = 1'b0;
	  SelAdrM = 2'b00;
	end else begin
	  NextState = STATE_FLUSH;
	  FlushAdrCntEn = 1'b1;
	  FlushWayCntEn = 1'b1;	
	end
      end

      default: begin
	NextState = STATE_READY;
      end
    endcase
  end



endmodule // dcachefsm


///////////////////////////////////////////
// lsu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Load/Store Unit 
//          Top level of the memory-stage hart logic
//          Contains data cache, DTLB, subword read/write datapath, interface to external bus
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

// *** Ross Thompson amo misalignment check?
module lsu 
  (
   input logic 		       clk, reset,
   input logic 		       StallM, FlushM, StallW, FlushW,
   output logic 	       LSUStall,
   // Memory Stage

   // connected to cpu (controls)
   input logic [1:0] 	       MemRWM,
   input logic [2:0] 	       Funct3M,
   input logic [6:0] 	       Funct7M, 
   input logic [1:0] 	       AtomicM,
   input logic 		       ExceptionM,
   input logic 		       PendingInterruptM,
   input logic           FlushDCacheM,
   output logic 	       CommittedM, 
   output logic 	       SquashSCW,
   output logic 	       DCacheMiss,
   output logic 	       DCacheAccess,

   // address and write data
   input  logic [`XLEN-1:0]    IEUAdrE,
   output logic [`XLEN-1:0]    IEUAdrM,
   input  logic [`XLEN-1:0]    WriteDataM, 
   output logic [`XLEN-1:0]    ReadDataM,

   // cpu privilege
   input logic [1:0] 	       PrivilegeModeW,
   input logic 		       DTLBFlushM,
   // faults
   output logic 	       DTLBLoadPageFaultM, DTLBStorePageFaultM,
   output logic 	       LoadMisalignedFaultM, LoadAccessFaultM,
   // cpu hazard unit (trap)
   output logic 	       StoreMisalignedFaultM, StoreAccessFaultM,

   // connect to ahb
   output logic [`PA_BITS-1:0] DCtoAHBPAdrM,
   output logic 	       DCtoAHBReadM, 
   output logic 	       DCtoAHBWriteM,
   input logic 		       DCfromAHBAck,
   input logic [`XLEN-1:0]     DCfromAHBReadData,
   output logic [`XLEN-1:0]    DCtoAHBWriteData,
   output logic [2:0] 	       DCtoAHBSizeM, 

   // mmu management

   // page table walker
   input logic [`XLEN-1:0]     SATP_REGW, // from csr
   input logic 		       STATUS_MXR, STATUS_SUM, STATUS_MPRV,
   input logic [1:0] 	       STATUS_MPP,

   input logic [`XLEN-1:0]     PCF,
   input logic 		       ITLBMissF,
   output logic [`XLEN-1:0]    PTE,
   output logic [1:0] 	       PageType,
   output logic 	       ITLBWriteF,
   output logic 	       WalkerInstrPageFaultF,
   output logic 	       WalkerLoadPageFaultM,
   output logic 	       WalkerStorePageFaultM,

   input 		       var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
   input 		       var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0] // *** this one especially has a large note attached to it in pmpchecker.
   );

  logic 		       DTLBPageFaultM;
  logic 	         DataMisalignedM;

  
  logic [`PA_BITS-1:0] 	       MemPAdrM;  // from mmu to dcache
 
  logic 		       DTLBMissM;
  logic 		       DTLBWriteM;
  logic 		       HPTWStall;  
  logic [`PA_BITS-1:0] 	       TranslationPAdr;
  logic 		       HPTWRead;
  logic [1:0] 		       MemRWMtoDCache;
  logic [1:0] 		       MemRWMtoLRSC;
  logic [2:0] 		       Funct3MtoDCache;
  logic [1:0] 		       AtomicMtoDCache;
  logic [`PA_BITS-1:0] 	       MemPAdrMtoDCache;
  logic [11:0] 		       MemAdrEtoDCache;  
  logic 		       StallWtoDCache;
  logic 		       MemReadM;
  logic 		       DataMisalignedMfromDCache;
  logic 		       DisableTranslation;  // used to stop intermediate PTE physical addresses being saved to TLB.
  logic 		       DCacheStall;

  logic 		       CacheableM;
  logic 		       CacheableMtoDCache;
  logic 		       SelPTW;

  logic 		       CommittedMfromDCache;
  logic 		       PendingInterruptMtoDCache;
//  logic 		       FlushWtoDCache;
  logic 		       WalkerPageFaultM;

  logic 		       AnyCPUReqM;
  logic 		       MemAfterIWalkDone;

  assign AnyCPUReqM = (|MemRWM)  | (|AtomicM);


  typedef enum {STATE_T0_READY,
				STATE_T0_REPLAY,
				STATE_T0_FAULT_REPLAY,				
				STATE_T3_DTLB_MISS,
				STATE_T4_ITLB_MISS,
				STATE_T5_ITLB_MISS,
				STATE_T7_DITLB_MISS} statetype;

  statetype CurrState, NextState;
  logic 	   InterlockStall;
  logic SelReplayCPURequest;
  logic WalkerInstrPageFaultRaw;
  
  
  always_ff @(posedge clk)
    if (reset)    CurrState <= #1 STATE_T0_READY;
    else CurrState <= #1 NextState;

  always_comb begin
	case(CurrState)
	  STATE_T0_READY: begin
		if(~ITLBMissF & DTLBMissM & AnyCPUReqM) begin
		  NextState = STATE_T3_DTLB_MISS;
		end
		else if(ITLBMissF & ~DTLBMissM & ~AnyCPUReqM) begin
		  NextState = STATE_T4_ITLB_MISS;
		end
		else if(ITLBMissF & ~DTLBMissM & AnyCPUReqM) begin
		  NextState = STATE_T5_ITLB_MISS;
		end
		else if(ITLBMissF & DTLBMissM & AnyCPUReqM) begin
		  NextState = STATE_T7_DITLB_MISS;
		end else begin
		  NextState = STATE_T0_READY;
		end
	  end
	  STATE_T0_REPLAY: begin
		if(DCacheStall) begin
		  NextState = STATE_T0_REPLAY;
		end else begin
		  NextState = STATE_T0_READY;
		end
	  end
	  STATE_T3_DTLB_MISS: begin
		if(WalkerLoadPageFaultM | WalkerStorePageFaultM) begin
		  NextState = STATE_T0_READY;
		end else if(DTLBWriteM) begin
		  NextState = STATE_T0_REPLAY;
		end else begin
		  NextState = STATE_T3_DTLB_MISS;
		end
	  end
	  STATE_T4_ITLB_MISS: begin
		if(WalkerInstrPageFaultRaw | ITLBWriteF) begin
		  NextState = STATE_T0_READY;
		end else begin
		  NextState = STATE_T4_ITLB_MISS;
		end
	  end
	  STATE_T5_ITLB_MISS: begin
		if(ITLBWriteF) begin
		  NextState = STATE_T0_REPLAY;
		end else if(WalkerInstrPageFaultRaw) begin
		  NextState = STATE_T0_FAULT_REPLAY;
		end else begin
		  NextState = STATE_T5_ITLB_MISS;
		end
	  end
	  STATE_T0_FAULT_REPLAY: begin
		if(DCacheStall) begin
		  NextState = STATE_T0_FAULT_REPLAY;
		end else begin
		  NextState = STATE_T0_READY;
		end
	  end
	  STATE_T7_DITLB_MISS: begin
		if(WalkerStorePageFaultM | WalkerLoadPageFaultM) begin
		  NextState = STATE_T0_READY;
		end else if(DTLBWriteM) begin
		  NextState = STATE_T5_ITLB_MISS;
		end else begin
		  NextState = STATE_T7_DITLB_MISS;
		end
	  end
	  default: begin
		NextState = STATE_T0_READY;
	  end
	endcase
  end // always_comb

  // signal to CPU it needs to wait on HPTW.
  assign InterlockStall = (CurrState == STATE_T0_READY & (DTLBMissM | ITLBMissF)) | 
						  (CurrState == STATE_T3_DTLB_MISS) | (CurrState == STATE_T4_ITLB_MISS) |
						  (CurrState == STATE_T5_ITLB_MISS) | (CurrState == STATE_T7_DITLB_MISS);
  
  // When replaying CPU memory request after PTW select the IEUAdrM for correct address.
  assign SelReplayCPURequest = NextState == STATE_T0_READY;
  assign SelPTW = (CurrState == STATE_T3_DTLB_MISS) | (CurrState == STATE_T4_ITLB_MISS) |
				  (CurrState == STATE_T5_ITLB_MISS) | (CurrState == STATE_T7_DITLB_MISS);
  
  

  flopenrc #(`XLEN) AddressMReg(clk, reset, FlushM, ~StallM, IEUAdrE, IEUAdrM);

  // *** add generate to conditionally create hptw, lsuArb, and mmu
  // based on `MEM_VIRTMEM
  hptw hptw(.clk(clk),
	    .reset(reset),
	    .SATP_REGW(SATP_REGW),
	    .PCF(PCF),
	    .IEUAdrM(IEUAdrM),
	    .ITLBMissF(ITLBMissF & ~PendingInterruptM),
	    .DTLBMissM(DTLBMissM & ~PendingInterruptM),
	    .MemRWM(MemRWM),
	    .PTE(PTE),
	    .PageType,
	    .ITLBWriteF(ITLBWriteF),
	    .DTLBWriteM(DTLBWriteM),
	    .HPTWReadPTE(ReadDataM),
	    .DCacheStall(DCacheStall),
        .TranslationPAdr,			  
	    .HPTWRead(HPTWRead),
		.HPTWStall,
	    .AnyCPUReqM,
	    .MemAfterIWalkDone,
	    .WalkerInstrPageFaultF(WalkerInstrPageFaultF),
	    .WalkerLoadPageFaultM(WalkerLoadPageFaultM),  
	    .WalkerStorePageFaultM(WalkerStorePageFaultM));

  assign LSUStall = DCacheStall | InterlockStall;
  
  assign WalkerPageFaultM = WalkerStorePageFaultM | WalkerLoadPageFaultM;

  // arbiter between IEU and hptw
  lsuArb arbiter(.clk(clk),
		 // HPTW connection
		 .SelPTW,
		 .HPTWRead(HPTWRead),
		 .TranslationPAdrE(TranslationPAdr),
		 // CPU connection
		 .MemRWM(MemRWM),
		 .Funct3M(Funct3M),
		 .AtomicM(AtomicM),
		 .IEUAdrM(IEUAdrM),
		 .IEUAdrE(IEUAdrE[11:0]),		 
		 .CommittedM(CommittedM),
		 .PendingInterruptM(PendingInterruptM),		
		 .StallW(StallW),
		 .DataMisalignedM(DataMisalignedM),
		 // DCACHE
		 .DisableTranslation(DisableTranslation),
		 .MemRWMtoLRSC(MemRWMtoLRSC),
		 .Funct3MtoDCache(Funct3MtoDCache),
		 .AtomicMtoDCache(AtomicMtoDCache),
		 .MemPAdrMtoDCache(MemPAdrMtoDCache),
		 .MemAdrEtoDCache(MemAdrEtoDCache),
		 .StallWtoDCache(StallWtoDCache),
		 .DataMisalignedMfromDCache(DataMisalignedMfromDCache),
		 .CommittedMfromDCache(CommittedMfromDCache),
		 .PendingInterruptMtoDCache(PendingInterruptMtoDCache),
		 .DCacheStall(DCacheStall));
  
  mmu #(.TLB_ENTRIES(`DTLB_ENTRIES), .IMMU(0))
  dmmu(.clk, .reset, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
       .PrivilegeModeW, .DisableTranslation(DisableTranslation),
       .PAdr(MemPAdrMtoDCache),
       .VAdr(IEUAdrM),
       .Size(Funct3MtoDCache[1:0]),
       .PTE(PTE),
       .PageTypeWriteVal(PageType),
       .TLBWrite(DTLBWriteM),
       .TLBFlush(DTLBFlushM),
       .PhysicalAddress(MemPAdrM),
       .TLBMiss(DTLBMissM),
       .Cacheable(CacheableM),
       .Idempotent(),
       .AtomicAllowed(),
       .TLBPageFault(DTLBPageFaultM),
       .InstrAccessFaultF(), .LoadAccessFaultM, .StoreAccessFaultM,
       .AtomicAccessM(1'b0), .ExecuteAccessF(1'b0), 
       .WriteAccessM(MemRWMtoLRSC[0]), .ReadAccessM(MemRWMtoLRSC[1]),
       .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW
       //.AtomicAccessM(AtomicMaskedM[1]),
       ); // *** the pma/pmp instruction access faults don't really matter here. is it possible to parameterize which outputs exist?


  // Move generate from lrsc to outside this module.
  assign MemReadM = MemRWMtoLRSC[1] & ~(ExceptionM | PendingInterruptMtoDCache) & ~DTLBMissM; // & ~NonBusTrapM & ~DTLBMissM & CurrState != STATE_STALLED;
  lrsc lrsc(.clk, .reset, .FlushW, .StallWtoDCache, .MemReadM, .MemRWMtoLRSC, .AtomicMtoDCache, .MemPAdrM,
            .SquashSCW, .MemRWMtoDCache);

  // *** BUG, this is most likely wrong
  assign CacheableMtoDCache = SelPTW ? 1'b1 : CacheableM;
  

  // Specify which type of page fault is occurring
  // *** `MEM_VIRTMEM
  assign DTLBLoadPageFaultM = DTLBPageFaultM & MemRWMtoLRSC[1];
  assign DTLBStorePageFaultM = DTLBPageFaultM & MemRWMtoLRSC[0];

  // Determine if an Unaligned access is taking place
  always_comb
    case(Funct3MtoDCache[1:0]) 
      2'b00:  DataMisalignedMfromDCache = 0;                       // lb, sb, lbu
      2'b01:  DataMisalignedMfromDCache = MemPAdrMtoDCache[0];              // lh, sh, lhu
      2'b10:  DataMisalignedMfromDCache = MemPAdrMtoDCache[1] | MemPAdrMtoDCache[0]; // lw, sw, flw, fsw, lwu
      2'b11:  DataMisalignedMfromDCache = |MemPAdrMtoDCache[2:0];           // ld, sd, fld, fsd
    endcase 

  // Determine if address is valid
  assign LoadMisalignedFaultM = DataMisalignedMfromDCache & MemRWMtoLRSC[1];
  assign StoreMisalignedFaultM = DataMisalignedMfromDCache & MemRWMtoLRSC[0];

  // conditional
  // 1. ram // controlled by `MEM_DTIM
  // 2. cache `MEM_DCACHE
  // 3. wire pass-through
  dcache dcache(.clk(clk),
		.reset(reset),
		.StallWtoDCache(StallWtoDCache),
		.MemRWM(MemRWMtoDCache),
		.Funct3M(Funct3MtoDCache),
		.Funct7M(Funct7M),
		.FlushDCacheM,
		.AtomicM(AtomicMtoDCache),
		.IEUAdrE(MemAdrEtoDCache),
		.MemPAdrM(MemPAdrM),
		.VAdr(IEUAdrM[11:0]),		
		.WriteDataM(WriteDataM),
		.ReadDataM(ReadDataM),
		.DCacheStall(DCacheStall),
		.CommittedM(CommittedMfromDCache),
		.DCacheMiss,
		.DCacheAccess,		
		.ExceptionM(ExceptionM),
		.PendingInterruptM(PendingInterruptMtoDCache),
		.DTLBMissM(DTLBMissM),
		.CacheableM(CacheableMtoDCache), 
		.DTLBWriteM(DTLBWriteM),
		.ITLBWriteF(ITLBWriteF),
		.ITLBMissF,
		.MemAfterIWalkDone,
		.SelPTW,
		.WalkerPageFaultM(WalkerPageFaultM),
		.WalkerInstrPageFaultF(WalkerInstrPageFaultF),

		// AHB connection
		.AHBPAdr(DCtoAHBPAdrM),
		.AHBRead(DCtoAHBReadM),
		.AHBWrite(DCtoAHBWriteM),
		.AHBAck(DCfromAHBAck),
		.HWDATA(DCtoAHBWriteData),
		.HRDATA(DCfromAHBReadData),
		.DCtoAHBSizeM
		);

endmodule


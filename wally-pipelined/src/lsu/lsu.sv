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
   output logic 	       CommittedM, 
   output logic 	       SquashSCW,
   output logic 	       DataMisalignedM,

   // address and write data
   input logic [`XLEN-1:0]     MemAdrM,
   input logic [`XLEN-1:0]     MemAdrE,
   input logic [`XLEN-1:0]     WriteDataM, 
   output logic [`XLEN-1:0]    ReadDataW,

   // cpu privilege
   input logic [1:0] 	       PrivilegeModeW,
   input logic 		       DTLBFlushM,
   // faults
   input logic 		       NonBusTrapM, 
   output logic 	       DTLBLoadPageFaultM, DTLBStorePageFaultM,
   output logic 	       LoadMisalignedFaultM, LoadAccessFaultM,
   // cpu hazard unit (trap)
   output logic 	       StoreMisalignedFaultM, StoreAccessFaultM,

   // connect to ahb
   input logic 		       CommitM, // should this be generated in the abh interface?
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
   output logic [`XLEN-1:0]    PageTableEntryF,
   output logic [1:0] 	       PageType,
   output logic 	       ITLBWriteF,
   output logic 	       WalkerInstrPageFaultF,
   output logic 	       WalkerLoadPageFaultM,
   output logic 	       WalkerStorePageFaultM,

   output logic 	       DTLBHitM, // not connected 

   input 		       var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
   input 		       var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0] // *** this one especially has a large note attached to it in pmpchecker.

   //  output logic [5:0]       DHSELRegionsM

   );

  logic 		       SquashSCM;
  logic 		       DTLBPageFaultM;
  logic 		       MemAccessM;

/* -----\/----- EXCLUDED -----\/-----
  logic 		       preCommittedM;
 -----/\----- EXCLUDED -----/\----- */

  typedef enum 		       {STATE_READY,
				STATE_FETCH,
				STATE_FETCH_AMO_1,
				STATE_FETCH_AMO_2,
				STATE_STALLED,
				STATE_PTW_READY,
				STATE_PTW_FETCH,
				STATE_PTW_DONE} statetype;
  statetype CurrState, NextState;
  
  logic [`PA_BITS-1:0] 	       MemPAdrM;  // from mmu to dcache
 
  logic 		       DTLBMissM;
  logic [`XLEN-1:0] 	       PageTableEntryM;
  logic 		       DTLBWriteM;
  logic [`XLEN-1:0] 	       HPTWReadPTE;
  logic 		       HPTWStall;  
  logic [`XLEN-1:0] 	       HPTWPAdrE;
  logic [`XLEN-1:0] 	       HPTWPAdrM;  
  logic 		       HPTWRead;
  logic [1:0] 		       MemRWMtoDCache;
  logic [2:0] 		       Funct3MtoDCache;
  logic [1:0] 		       AtomicMtoDCache;
  logic [`XLEN-1:0] 	       MemAdrMtoDCache;
  logic [`XLEN-1:0] 	       MemAdrEtoDCache;  
  logic [`XLEN-1:0] 	       ReadDataWfromDCache;
  logic 		       StallWtoDCache;
  logic 		       SquashSCWfromDCache;
  logic 		       DataMisalignedMfromDCache;
  logic 		       HPTWReady;
  logic 		       DisableTranslation;  // used to stop intermediate PTE physical addresses being saved to TLB.
  logic 		       DCacheStall;

  logic 		       CacheableM;
  logic 		       CacheableMtoDCache;
  logic 		       SelPTW;

  logic 		       CommittedMfromDCache;
  logic 		       PendingInterruptMtoDCache;
  logic 		       FlushWtoDCache;
  logic 		       WalkerPageFaultM;
  
  
  pagetablewalker pagetablewalker(
				  .clk(clk),
				  .reset(reset),
				  .SATP_REGW(SATP_REGW),
				  .PCF(PCF),
				  .MemAdrM(MemAdrM),
				  .ITLBMissF(ITLBMissF),
				  .DTLBMissM(DTLBMissM),
				  .MemRWM(MemRWM),
				  .PageTableEntryF(PageTableEntryF),
				  .PageTableEntryM(PageTableEntryM),
				  .PageType,
				  .ITLBWriteF(ITLBWriteF),
				  .DTLBWriteM(DTLBWriteM),
				  .HPTWReadPTE(HPTWReadPTE),
				  .HPTWStall(HPTWStall),
				  .HPTWPAdrE(HPTWPAdrE),
				  .HPTWPAdrM(HPTWPAdrM),				  
				  .HPTWRead(HPTWRead),
				  .SelPTW(SelPTW),
				  .WalkerInstrPageFaultF(WalkerInstrPageFaultF),
				  .WalkerLoadPageFaultM(WalkerLoadPageFaultM),  
				  .WalkerStorePageFaultM(WalkerStorePageFaultM));
  
  assign WalkerPageFaultM = WalkerStorePageFaultM | WalkerLoadPageFaultM;

  // arbiter between IEU and pagetablewalker
  lsuArb arbiter(.clk(clk),
		 .reset(reset),
		 // HPTW connection
		 .SelPTW(SelPTW),
		 .HPTWRead(HPTWRead),
		 .HPTWPAdrE(HPTWPAdrE),
		 .HPTWPAdrM(HPTWPAdrM),		 
		 //.HPTWReadPTE(HPTWReadPTE),
		 .HPTWStall(HPTWStall),		 
		 // CPU connection
		 .MemRWM(MemRWM),
		 .Funct3M(Funct3M),
		 .AtomicM(AtomicM),
		 .MemAdrM(MemAdrM),
		 .MemAdrE(MemAdrE),		 
		 .CommittedM(CommittedM),
		 .PendingInterruptM(PendingInterruptM),		
		 .StallW(StallW),
		 .ReadDataW(ReadDataW),
		 .SquashSCW(SquashSCW),
		 .DataMisalignedM(DataMisalignedM),
		 .LSUStall(LSUStall),
		 // DCACHE
		 .DisableTranslation(DisableTranslation),
		 .MemRWMtoDCache(MemRWMtoDCache),
		 .Funct3MtoDCache(Funct3MtoDCache),
		 .AtomicMtoDCache(AtomicMtoDCache),
		 .MemAdrMtoDCache(MemAdrMtoDCache),
		 .MemAdrEtoDCache(MemAdrEtoDCache),
		 .StallWtoDCache(StallWtoDCache),
		 .SquashSCWfromDCache(SquashSCWfromDCache),      
		 .DataMisalignedMfromDCache(DataMisalignedMfromDCache),
		 .ReadDataWfromDCache(ReadDataWfromDCache),
		 .CommittedMfromDCache(CommittedMfromDCache),
		 .PendingInterruptMtoDCache(PendingInterruptMtoDCache),
		 .DCacheStall(DCacheStall));
  

    
  
  mmu #(.TLB_ENTRIES(`DTLB_ENTRIES), .IMMU(0))
  dmmu(.Address(MemAdrMtoDCache),
       .Size(Funct3MtoDCache[1:0]),
       .PTE(PageTableEntryM),
       .PageTypeWriteVal(PageType),
       .TLBWrite(DTLBWriteM),
       .TLBFlush(DTLBFlushM),
       .PhysicalAddress(MemPAdrM),
       .TLBMiss(DTLBMissM),
       .TLBHit(DTLBHitM),
       .TLBPageFault(DTLBPageFaultM),
       .ExecuteAccessF(1'b0),
       //.AtomicAccessM(AtomicMaskedM[1]),
       .AtomicAccessM(1'b0),
       .WriteAccessM(MemRWMtoDCache[0]),
       .ReadAccessM(MemRWMtoDCache[1]),
       .SquashBusAccess(),
       .DisableTranslation(DisableTranslation),
       .InstrAccessFaultF(),
       .Cacheable(CacheableM),
       .Idempotent(),
       .AtomicAllowed(),
       //       .SelRegions(DHSELRegionsM),
       .*); // *** the pma/pmp instruction acess faults don't really matter here. is it possible to parameterize which outputs exist?

  // *** BUG, this is most likely wrong
  assign CacheableMtoDCache = SelPTW ? 1'b1 : CacheableM;
  
  generate
    if (`XLEN == 32) assign DCtoAHBSizeM = CacheableMtoDCache ? 3'b010 : Funct3MtoDCache;
    else assign DCtoAHBSizeM = CacheableMtoDCache ? 3'b011 : Funct3MtoDCache;
  endgenerate;


  // Specify which type of page fault is occurring
  assign DTLBLoadPageFaultM = DTLBPageFaultM & MemRWMtoDCache[1];
  assign DTLBStorePageFaultM = DTLBPageFaultM & MemRWMtoDCache[0];

  // Determine if an Unaligned access is taking place
  always_comb
    case(Funct3MtoDCache[1:0]) 
      2'b00:  DataMisalignedMfromDCache = 0;                       // lb, sb, lbu
      2'b01:  DataMisalignedMfromDCache = MemAdrMtoDCache[0];              // lh, sh, lhu
      2'b10:  DataMisalignedMfromDCache = MemAdrMtoDCache[1] | MemAdrMtoDCache[0]; // lw, sw, flw, fsw, lwu
      2'b11:  DataMisalignedMfromDCache = |MemAdrMtoDCache[2:0];           // ld, sd, fld, fsd
    endcase 

  // Squash unaligned data accesses and failed store conditionals
  // *** this is also the place to squash if the cache is hit
  // Changed DataMisalignedMfromDCache to a larger combination of trap sources
  // NonBusTrapM is anything that the bus doesn't contribute to producing 
  // By contrast, using TrapM results in circular logic errors
/* -----\/----- EXCLUDED -----\/-----

 // *** BUG for now leave this out. come back later after the d cache is working. July 09, 2021

  assign MemReadM = MemRWMtoDCache[1] & ~NonBusTrapM & ~DTLBMissM & CurrState != STATE_STALLED;
  assign MemWriteM = MemRWMtoDCache[0] & ~NonBusTrapM & ~DTLBMissM & ~SquashSCM & CurrState != STATE_STALLED;
  assign AtomicMaskedM = CurrState != STATE_STALLED ? AtomicMtoDCache : 2'b00 ;
  assign MemAccessM = MemReadM | MemWriteM;

  // Determine if M stage committed
  // Reset whenever unstalled. Set when access successfully occurs
  flopr #(1) committedMreg(clk,reset,(CommittedMfromDCache | CommitM) & StallM,preCommittedM);
  assign CommittedMfromDCache = preCommittedM | CommitM;


  // Handle atomic load reserved / store conditional
  generate
    if (`A_SUPPORTED) begin // atomic instructions supported
      logic [`PA_BITS-1:2] ReservationPAdrW;
      logic 		   ReservationValidM, ReservationValidW; 
      logic 		   lrM, scM, WriteAdrMatchM;

      assign lrM = MemReadM && AtomicMtoDCache[0];
      assign scM = MemRWMtoDCache[0] && AtomicMtoDCache[0]; 
      assign WriteAdrMatchM = MemRWMtoDCache[0] && (MemPAdrM[`PA_BITS-1:2] == ReservationPAdrW) && ReservationValidW;
      assign SquashSCM = scM && ~WriteAdrMatchM;
      always_comb begin // ReservationValidM (next value of valid reservation)
        if (lrM) ReservationValidM = 1;  // set valid on load reserve
        else if (scM || WriteAdrMatchM) ReservationValidM = 0; // clear valid on store to same address or any sc
        else ReservationValidM = ReservationValidW; // otherwise don't change valid
      end
      flopenrc #(`PA_BITS-2) resadrreg(clk, reset, FlushW, lrM, MemPAdrM[`PA_BITS-1:2], ReservationPAdrW); // could drop clear on this one but not valid
      flopenrc #(1) resvldreg(clk, reset, FlushW, lrM, ReservationValidM, ReservationValidW);
      flopenrc #(1) squashreg(clk, reset, FlushW, ~StallWtoDCache, SquashSCM, SquashSCWfromDCache);
    end else begin // Atomic operations not supported
      assign SquashSCM = 0;
      assign SquashSCWfromDCache = 0; 
    end
  endgenerate
 -----/\----- EXCLUDED -----/\----- */

  // Determine if address is valid
  assign LoadMisalignedFaultM = DataMisalignedMfromDCache & MemRWMtoDCache[1];
  assign StoreMisalignedFaultM = DataMisalignedMfromDCache & MemRWMtoDCache[0];

  dcache dcache(.clk(clk),
		.reset(reset),
		.StallM(StallM),
		.StallW(StallWtoDCache),
		.FlushM(FlushM),
		.FlushW(FlushWtoDCache),
		.MemRWM(MemRWMtoDCache),
		.Funct3M(Funct3MtoDCache),
		.Funct7M(Funct7M),		
		.AtomicM(AtomicMtoDCache),
		.MemAdrE(MemAdrEtoDCache),
		.MemPAdrM(MemPAdrM),
		.WriteDataM(WriteDataM),
		.ReadDataW(ReadDataWfromDCache),
		.ReadDataM(HPTWReadPTE),
		.DCacheStall(DCacheStall),
		.CommittedM(CommittedMfromDCache),
		.ExceptionM(ExceptionM),
		.PendingInterruptM(PendingInterruptMtoDCache),		
		.DTLBMissM(DTLBMissM),
		.CacheableM(CacheableMtoDCache), 
		.DTLBWriteM(DTLBWriteM),
		.ITLBWriteF(ITLBWriteF),		
		.SelPTW(SelPTW),
		.WalkerPageFaultM(WalkerPageFaultM),

		// AHB connection
		.AHBPAdr(DCtoAHBPAdrM),
		.AHBRead(DCtoAHBReadM),
		.AHBWrite(DCtoAHBWriteM),
		.AHBAck(DCfromAHBAck),
		.HWDATA(DCtoAHBWriteData),
		.HRDATA(DCfromAHBReadData)		
		);
  
//  assign AtomicMaskedM = 2'b00;  // *** Remove from AHB
  

  // Data stall
  //assign LSUStall = (NextState == STATE_FETCH) || (NextState == STATE_FETCH_AMO_1) || (NextState == STATE_FETCH_AMO_2);
  // BUG *** July 09, 2021
  //assign HPTWReady = (CurrState == STATE_READY);
  

  // Ross Thompson April 22, 2021
  // for now we need to handle the issue where the data memory interface repeately
  // requests data from memory rather than issuing a single request.

/* -----\/----- EXCLUDED -----\/-----
 // *** BUG will need to modify this so we can handle the ptw. July 09, 2021

  flopenl #(.TYPE(statetype)) stateReg(.clk(clk),
				       .load(reset),
				       .en(1'b1),
				       .d(NextState),
				       .val(STATE_READY),
				       .q(CurrState));

  always_comb begin
    case (CurrState)
      STATE_READY:
	if (DTLBMissM) begin
	  NextState = STATE_PTW_READY;
	  LSUStall = 1'b1;
	end else if (AtomicMaskedM[1]) begin 
	  NextState = STATE_FETCH_AMO_1; // *** should be some misalign check
	  LSUStall = 1'b1;
	end else if((MemReadM & AtomicMtoDCache[0]) | (MemWriteM & AtomicMtoDCache[0])) begin
	  NextState = STATE_FETCH_AMO_2; 
	  LSUStall = 1'b1;
	end else if (MemAccessM & ~DataMisalignedMfromDCache) begin
	  NextState = STATE_FETCH;
	  LSUStall = 1'b1;
	end else begin
          NextState = STATE_READY;
	  LSUStall = 1'b0;
	end
      STATE_FETCH_AMO_1: begin
	LSUStall = 1'b1;
	if (DCfromAHBAck) begin
	  NextState = STATE_FETCH_AMO_2;
	end else begin 
	  NextState = STATE_FETCH_AMO_1;
	end
      end
      STATE_FETCH_AMO_2: begin
	LSUStall = 1'b1;	
	if (DCfromAHBAck & ~StallWtoDCache) begin
	  NextState = STATE_FETCH_AMO_2;
	end else if (DCfromAHBAck & StallWtoDCache) begin
          NextState = STATE_STALLED;
	end else begin
	  NextState = STATE_FETCH_AMO_2;
	end
      end
      STATE_FETCH: begin
	LSUStall = 1'b1;
	if (DCfromAHBAck & ~StallWtoDCache) begin
	  NextState = STATE_READY;
	end else if (DCfromAHBAck & StallWtoDCache) begin
	  NextState = STATE_STALLED;
	end else begin
	  NextState = STATE_FETCH;
	end
      end
      STATE_STALLED: begin
	LSUStall = 1'b0;
	if (~StallWtoDCache) begin
	  NextState = STATE_READY;
	end else begin
	  NextState = STATE_STALLED;
	end
      end
      STATE_PTW_READY: begin
	LSUStall = 1'b0;
	if (DTLBWriteM) begin
	  NextState = STATE_READY;
	  LSUStall = 1'b1;
	end else if (MemReadM & ~DataMisalignedMfromDCache) begin
	  NextState = STATE_PTW_FETCH;
	end else begin
	  NextState = STATE_PTW_READY;
	end
      end
      STATE_PTW_FETCH : begin
	LSUStall = 1'b1;
	if (DCfromAHBAck & ~DTLBWriteM) begin
	  NextState = STATE_PTW_READY;
	end else if (DCfromAHBAck & DTLBWriteM) begin
	  NextState = STATE_READY;
	end else begin
	  NextState = STATE_PTW_FETCH;
	end
      end
      STATE_PTW_DONE: begin
	NextState = STATE_READY;
      end
      default: begin
	LSUStall = 1'b0;
	NextState = STATE_READY;
      end
    endcase
  end // always_comb
 -----/\----- EXCLUDED -----/\----- */


endmodule


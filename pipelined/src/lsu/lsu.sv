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

module lsu 
  (
   input logic 				   clk, reset,
   input logic 				   StallM, FlushM, StallW, FlushW,
   output logic 			   LSUStall,
   // Memory Stage

   // connected to cpu (controls)
   input logic [1:0] 		   MemRWM,
   input logic [2:0] 		   Funct3M,
   input logic [6:0] 		   Funct7M, 
   input logic [1:0] 		   AtomicM,
   input logic 				   ExceptionM,
   input logic 				   PendingInterruptM,
   input logic 				   FlushDCacheM,
   output logic 			   CommittedM, 
   output logic 			   SquashSCW,
   output logic 			   DCacheMiss,
   output logic 			   DCacheAccess,

   // address and write data
   input logic [`XLEN-1:0] 	   IEUAdrE,
   (* mark_debug = "true" *)output logic [`XLEN-1:0]    IEUAdrM,
   input logic [`XLEN-1:0] 	   WriteDataM, 
   output logic [`XLEN-1:0]    ReadDataM,

   // cpu privilege
   input logic [1:0] 		   PrivilegeModeW,
   input logic 				   DTLBFlushM,
   // faults
   output logic 			   DTLBLoadPageFaultM, DTLBStorePageFaultM,
   output logic 			   LoadMisalignedFaultM, LoadAccessFaultM,
   // cpu hazard unit (trap)
   output logic 			   StoreMisalignedFaultM, StoreAccessFaultM,

   // connect to ahb
(* mark_debug = "true" *)   output logic [`PA_BITS-1:0] LsuBusAdr,
   output logic 			   LsuBusRead, 
   output logic 			   LsuBusWrite,
   input logic 				   LsuBusAck,
(* mark_debug = "true" *)   input logic [`XLEN-1:0] 	   LsuBusHRDATA,
   output logic [`XLEN-1:0]    LsuBusHWDATA,
   output logic [2:0] 		   LsuBusSize, 

   // mmu management

   // page table walker
   input logic [`XLEN-1:0] 	   SATP_REGW, // from csr
   input logic 				   STATUS_MXR, STATUS_SUM, STATUS_MPRV,
   input logic [1:0] 		   STATUS_MPP,

   input logic [`XLEN-1:0] 	   PCF,
   input logic 				   ITLBMissF,
   output logic [`XLEN-1:0]    PTE,
   output logic [1:0] 		   PageType,
   output logic 			   ITLBWriteF,

   input 					   var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
   input 					   var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0] // *** this one especially has a large note attached to it in pmpchecker.
   );

  logic 					   DTLBPageFaultM;
  
  logic [`PA_BITS-1:0] 		   LsuPAdrM;  // from mmu to dcache
  logic [`XLEN+1:0] 		   IEUAdrExtM;
  logic 					   DTLBMissM;
  logic 					   DTLBWriteM;

  logic [1:0] 				   LsuRWM;
  logic [1:0] 				   PreLsuRWM;
  logic [2:0] 				   LsuFunct3M;
  logic [1:0] 				   LsuAtomicM;
  logic [`PA_BITS-1:0] 		   PreLsuPAdrM, LocalLsuBusAdr;
  logic [11:0] 				   PreLsuAdrE, LsuAdrE;  
  logic 					   CPUBusy;
  logic 					   MemReadM;
  logic 					   DCacheStall;

  logic 					   CacheableM;
  logic 					   SelHPTW;


  logic 					   BusStall;
  

  logic 					   InterlockStall;
  logic 					   IgnoreRequest;
  logic 					   BusCommittedM, DCacheCommittedM;
  

  flopenrc #(`XLEN) AddressMReg(clk, reset, FlushM, ~StallM, IEUAdrE, IEUAdrM);
  assign IEUAdrExtM = {2'b00, IEUAdrM};

  if(`MEM_VIRTMEM) begin : MEM_VIRTMEM
    logic 					   AnyCPUReqM;
    logic [`PA_BITS-1:0] 		   HPTWAdr;
    logic 					   HPTWRead;
    logic [2:0] 				   HPTWSize;
    logic 					   SelReplayCPURequest;

    assign AnyCPUReqM = (|MemRWM) | (|AtomicM);

    interlockfsm interlockfsm (.clk, .reset, .AnyCPUReqM, .ITLBMissF, .ITLBWriteF,
    .DTLBMissM, .DTLBWriteM, .ExceptionM, .PendingInterruptM, .DCacheStall,
    .InterlockStall, .SelReplayCPURequest, .SelHPTW,
    .IgnoreRequest);
    
    hptw hptw(.clk, .reset, .SATP_REGW, .PCF, .IEUAdrM,
        .ITLBMissF(ITLBMissF & ~PendingInterruptM),
        .DTLBMissM(DTLBMissM & ~PendingInterruptM),
        .MemRWM, .PTE, .PageType, .ITLBWriteF, .DTLBWriteM,
        .HPTWReadPTE(ReadDataM),
        .DCacheStall, .HPTWAdr, .HPTWRead, .HPTWSize, .AnyCPUReqM);

    // arbiter between IEU and hptw
    
    // multiplex the outputs to LSU
    mux2 #(2) rwmux(MemRWM, {HPTWRead, 1'b0}, SelHPTW, PreLsuRWM);
    mux2 #(3) sizemux(Funct3M, HPTWSize, SelHPTW, LsuFunct3M);
    mux2 #(2) atomicmux(AtomicM, 2'b00, SelHPTW, LsuAtomicM);
    mux2 #(12) adremux(IEUAdrE[11:0], HPTWAdr[11:0], SelHPTW, PreLsuAdrE);
    mux2 #(`PA_BITS) lsupadrmux(IEUAdrExtM[`PA_BITS-1:0], HPTWAdr, SelHPTW, PreLsuPAdrM);

    // always block interrupts when using the hardware page table walker.
    assign CPUBusy = StallW & ~SelHPTW;
    
    // It is not possible to pipeline hptw as the following load will depend on the previous load's
    // data. Therefore we don't need a pipeline register
    //flop #(`PA_BITS) HPTWAdrMReg(clk, HPTWAdr, HPTWAdrM);   // delay HPTWAdrM by a cycle

    // Specify which type of page fault is occurring
    assign DTLBLoadPageFaultM = DTLBPageFaultM & PreLsuRWM[1];
    assign DTLBStorePageFaultM = DTLBPageFaultM & PreLsuRWM[0];

    // When replaying CPU memory request after PTW select the IEUAdrM for correct address.
    assign LsuAdrE = SelReplayCPURequest ? IEUAdrM[11:0] : PreLsuAdrE;

  end // if (`MEM_VIRTMEM)
  else begin
    assign InterlockStall = 1'b0;
    
    assign LsuAdrE = PreLsuAdrE;
    assign SelHPTW = 1'b0;
    assign IgnoreRequest = 1'b0;

    assign PTE = '0;
    assign PageType = '0;
    assign DTLBWriteM = 1'b0;
    assign ITLBWriteF = 1'b0;	  
    
    assign PreLsuRWM = MemRWM;
    assign LsuFunct3M = Funct3M;
    assign LsuAtomicM = AtomicM;
    assign PreLsuAdrE = IEUAdrE[11:0];
    assign PreLsuPAdrM = IEUAdrExtM;
    assign CPUBusy = StallW;
    
    assign DTLBLoadPageFaultM = 1'b0;
    assign DTLBStorePageFaultM = 1'b0;
  end

  // **** look into this confusing signal.
  // This signal is confusing.  CommittedM tells the CPU's trap unit the current instruction
  // in the memory stage is a memory operaton and that memory operation is either completed
  // or is partially executed.  This signal is only low for the first cycle of a memory
  // operation.
  // **** I think there is also a bug here.  Data cache misses and TLB misses both
  // set this bit in the first cycle.  It is not strickly wrong, but it may be better
  // to flush the memory operation at that time.
  assign CommittedM = SelHPTW | DCacheCommittedM | BusCommittedM;

  if(`ZICSR_SUPPORTED == 1) begin : dmmu
    logic 					   DataMisalignedM;

    mmu #(.TLB_ENTRIES(`DTLB_ENTRIES), .IMMU(0))
    dmmu(.clk, .reset, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
      .PrivilegeModeW, .DisableTranslation(SelHPTW),
      .PAdr(PreLsuPAdrM),
      .VAdr(IEUAdrM),
      .Size(LsuFunct3M[1:0]),
      .PTE,
      .PageTypeWriteVal(PageType),
      .TLBWrite(DTLBWriteM),
      .TLBFlush(DTLBFlushM),
      .PhysicalAddress(LsuPAdrM),
      .TLBMiss(DTLBMissM),
      .Cacheable(CacheableM),
      .Idempotent(), .AtomicAllowed(),
      .TLBPageFault(DTLBPageFaultM),
      .InstrAccessFaultF(), .LoadAccessFaultM, .StoreAccessFaultM,
      .AtomicAccessM(1'b0), .ExecuteAccessF(1'b0),  ///  atomicaccessm is probably a bug
      .WriteAccessM(PreLsuRWM[0]), .ReadAccessM(PreLsuRWM[1]),
      .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW
      ); // *** the pma/pmp instruction access faults don't really matter here. is it possible to parameterize which outputs exist?

    // Determine if an Unaligned access is taking place
    // hptw guarantees alignment, only check inputs from IEU.
    always_comb
    case(Funct3M[1:0]) 
      2'b00:  DataMisalignedM = 0;                       // lb, sb, lbu
      2'b01:  DataMisalignedM = IEUAdrM[0];              // lh, sh, lhu
      2'b10:  DataMisalignedM = IEUAdrM[1] | IEUAdrM[0]; // lw, sw, flw, fsw, lwu
      2'b11:  DataMisalignedM = |IEUAdrM[2:0];           // ld, sd, fld, fsd
    endcase 

    // If the CPU's (not HPTW's) request is a page fault.
    assign LoadMisalignedFaultM = DataMisalignedM & MemRWM[1];
    assign StoreMisalignedFaultM = DataMisalignedM & MemRWM[0];
    
  end else begin
    assign LsuPAdrM = PreLsuPAdrM;
    assign DTLBMissM = 0;
    assign CacheableM = 1;
    assign DTLBPageFaultM = 0;
    assign LoadAccessFaultM = 0;
    assign StoreAccessFaultM = 0;
    assign LoadMisalignedFaultM = 0;
    assign StoreMisalignedFaultM = 0;
  end
  assign LSUStall = DCacheStall | InterlockStall | BusStall;
  

  // use PreLsu as prefix for lrsc 
  if (`A_SUPPORTED) begin:lrsc
    assign MemReadM = PreLsuRWM[1] & ~(IgnoreRequest) & ~DTLBMissM;
    lrsc lrsc(.clk, .reset, .FlushW, .CPUBusy, .MemReadM, .PreLsuRWM, .LsuAtomicM, .LsuPAdrM,
        .SquashSCW, .LsuRWM);
  end else begin:lrsc
      assign SquashSCW = 0;
      assign LsuRWM = PreLsuRWM;
  end


  // conditional
  // 1. ram // controlled by `MEM_DTIM
  // 2. cache `MEM_DCACHE
  // 3. wire pass-through

  localparam integer   WORDSPERLINE = `MEM_DCACHE ? `DCACHE_LINELENINBITS/`XLEN : 1;
  localparam integer   LOGWPL = `MEM_DCACHE ? $clog2(WORDSPERLINE) : 1;
  localparam integer   LINELEN = `MEM_DCACHE ? `DCACHE_LINELENINBITS : `XLEN;
  localparam integer   WordCountThreshold = `MEM_DCACHE ? WORDSPERLINE - 1 : 0;

  localparam integer   LINEBYTELEN = LINELEN/8;
  localparam integer   OFFSETLEN = $clog2(LINEBYTELEN);

  // temp
  
  logic [`XLEN-1:0]    FinalAMOWriteDataM, FinalWriteDataM;
  (* mark_debug = "true" *) logic [`XLEN-1:0]    PreLsuBusHWDATA;
  logic [`XLEN-1:0]    ReadDataWordM;
  logic [LINELEN-1:0] DCacheMemWriteData;

  // keep
  logic [`XLEN-1:0]    ReadDataWordMuxM;



  logic [`PA_BITS-1:0] DCacheBusAdr;
  logic [`XLEN-1:0]    ReadDataLineSetsM [WORDSPERLINE-1:0];
  


  logic 			   DCacheWriteLine;
  logic 			   DCacheFetchLine;
  logic 			   DCacheBusAck;

  logic 			   SelUncachedAdr;

  if(`MEM_DCACHE) begin : dcache
    cache #(.LINELEN(`DCACHE_LINELENINBITS), .NUMLINES(`DCACHE_WAYSIZEINBYTES*8/LINELEN),
      .NUMWAYS(`DCACHE_NUMWAYS), .DCACHE(1)) 
  dcache(.clk, .reset, .CPUBusy,
          .RW(CacheableM ? LsuRWM : 2'b00), .FlushCache(FlushDCacheM), .Atomic(CacheableM ? LsuAtomicM : 2'b00), 
      .LsuAdrE, .LsuPAdrM, .PreLsuPAdrM(PreLsuPAdrM[11:0]), // still don't like this name PreLsuPAdrM, not always physical
          .FinalWriteData(FinalWriteDataM), .ReadDataWord(ReadDataWordM), .CacheStall(DCacheStall),
          .CacheMiss(DCacheMiss), .CacheAccess(DCacheAccess), 
          .IgnoreRequest, .CacheCommitted(DCacheCommittedM),
          .CacheBusAdr(DCacheBusAdr), .ReadDataLineSets(ReadDataLineSetsM), .CacheMemWriteData(DCacheMemWriteData),
          .CacheFetchLine(DCacheFetchLine), .CacheWriteLine(DCacheWriteLine), .CacheBusAck(DCacheBusAck), .InvalidateCacheM(1'b0));
  end else begin : passthrough
    assign ReadDataWordM = 0;
    assign DCacheStall = 0;
    assign DCacheMiss = 1;
    assign DCacheAccess = CacheableM;
    assign DCacheCommittedM = 0;
    assign DCacheWriteLine = 0;
    assign DCacheFetchLine = 0;
    assign DCacheBusAdr = 0;
    assign ReadDataLineSetsM[0] = 0;
  end


  // select between dcache and direct from the BUS. Always selected if no dcache.
  mux2 #(`XLEN) UnCachedDataMux(.d0(ReadDataWordM),
				.d1(DCacheMemWriteData[`XLEN-1:0]),
				.s(SelUncachedAdr),
				.y(ReadDataWordMuxM));
  
  // sub word selection for read and writes and optional amo alu.
  // finally swr
  subwordread subwordread(.ReadDataWordMuxM,
			  .LsuPAdrM(LsuPAdrM[2:0]),
			  .Funct3M(LsuFunct3M),
			  .ReadDataM);

  if (`A_SUPPORTED) begin : amo
    logic [`XLEN-1:0] AMOResult;
    amoalu amoalu(.srca(ReadDataM), .srcb(WriteDataM), .funct(Funct7M), .width(LsuFunct3M[1:0]), 
                  .result(AMOResult));
    mux2 #(`XLEN) wdmux(WriteDataM, AMOResult, LsuAtomicM[1], FinalAMOWriteDataM);
  end else
    assign FinalAMOWriteDataM = WriteDataM;

  // this might only get instantiated if there is a dcache or dtim.
  // There is a copy in the ebu.
  subwordwrite subwordwrite(.HRDATA(ReadDataWordM),
			    .HADDRD(LsuPAdrM[2:0]),
			    .HSIZED({LsuFunct3M[2], 1'b0, LsuFunct3M[1:0]}),
			    .HWDATAIN(FinalAMOWriteDataM),
			    .HWDATA(FinalWriteDataM));

  // Bus Side logic
  // register the fetch data from the next level of memory.
  // This register should be necessary for timing.  There is no register in the uncore or
  // ahblite controller between the memories and this cache.
  logic [LOGWPL-1:0]   WordCount;

  genvar index;
  for (index = 0; index < WORDSPERLINE; index++) begin:fetchbuffer
    flopen #(`XLEN) fb(.clk,
      .en(LsuBusAck & LsuBusRead & (index == WordCount)),
      .d(LsuBusHRDATA),
      .q(DCacheMemWriteData[(index+1)*`XLEN-1:index*`XLEN]));
  end

  assign LocalLsuBusAdr = SelUncachedAdr ? LsuPAdrM : DCacheBusAdr ;
  assign LsuBusAdr = ({{`PA_BITS-LOGWPL{1'b0}}, WordCount} << $clog2(`XLEN/8)) + LocalLsuBusAdr;
  assign PreLsuBusHWDATA = ReadDataLineSetsM[WordCount];
  assign LsuBusHWDATA = SelUncachedAdr ? WriteDataM : PreLsuBusHWDATA;  // *** why is this not FinalWriteDataM? which does not work.

  if (`XLEN == 32) assign LsuBusSize = SelUncachedAdr ? LsuFunct3M : 3'b010;
  else             assign LsuBusSize = SelUncachedAdr ? LsuFunct3M : 3'b011;

  busfsm #(WordCountThreshold, LOGWPL, `MEM_DCACHE)
  busfsm(.clk, .reset, .IgnoreRequest, .LsuRWM, .DCacheFetchLine, .DCacheWriteLine,
		 .LsuBusAck, .CPUBusy, .CacheableM, .BusStall, .LsuBusWrite, .LsuBusRead,
		 .DCacheBusAck, .BusCommittedM, .SelUncachedAdr, .WordCount);
    
endmodule


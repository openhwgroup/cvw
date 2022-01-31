///////////////////////////////////////////
// lsu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Load/Store Unit 
//          Top level of the memory-stage core logic
//          Contains data cache, DTLB, subword read/write datapath, interface to external bus
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

module lsu (
   input logic 				   clk, reset,
   input logic 				   StallM, FlushM, StallW, FlushW,
   output logic 			   LSUStallM,
   // connected to cpu (controls)
   input logic [1:0] 		   MemRWM,
   input logic [2:0] 		   Funct3M,
   input logic [6:0] 		   Funct7M, 
   input logic [1:0] 		   AtomicM,
   input logic                 TrapM,
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
   output logic 			   LoadPageFaultM, StoreAmoPageFaultM,
   output logic 			   LoadMisalignedFaultM, LoadAccessFaultM,
   // cpu hazard unit (trap)
   output logic 			   StoreAmoMisalignedFaultM, StoreAmoAccessFaultM,
   // connect to ahb
(* mark_debug = "true" *)   output logic [`PA_BITS-1:0] LSUBusAdr,
(* mark_debug = "true" *)   output logic 			   LSUBusRead, 
(* mark_debug = "true" *)   output logic 			   LSUBusWrite,
(* mark_debug = "true" *)   input logic 				   LSUBusAck,
(* mark_debug = "true" *)   input logic [`XLEN-1:0] 	   LSUBusHRDATA,
(* mark_debug = "true" *)   output logic [`XLEN-1:0]    LSUBusHWDATA,
(* mark_debug = "true" *)   output logic [2:0] 		   LSUBusSize, 
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

  logic [`PA_BITS-1:0] 		   LSUPAdrM;  // from mmu to dcache
  logic [`XLEN+1:0] 		   IEUAdrExtM;
  logic 					   DTLBMissM;
  logic 					   DTLBWriteM;
  logic [1:0] 				   LSURWM;
  logic [1:0] 				   PreLSURWM;
  logic [2:0] 				   LSUFunct3M;
  logic [6:0] 				   LSUFunct7M;
  logic [1:0] 				   LSUAtomicM;
(* mark_debug = "true" *)  logic [`PA_BITS-1:0] 		   PreLSUPAdrM, LocalLSUBusAdr;
  logic [11:0] 				   PreLSUAdrE, LSUAdrE;  
  logic 					   CPUBusy;
  logic 					   DCacheStallM;
  logic 					   CacheableM;
  logic 					   SelHPTW;
  logic 					   BusStall;
  logic 					   InterlockStall;
  logic 					   IgnoreRequest;
  logic 					   BusCommittedM, DCacheCommittedM;

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // HPTW and Interlock FSM (only needed if VM supported)
  // MMU include PMP and is needed if any privileged supported
  ////////////////////////////////////////////////////////////////////////////////////////////////

  flopenrc #(`XLEN) AddressMReg(clk, reset, FlushM, ~StallM, IEUAdrE, IEUAdrM);
  assign IEUAdrExtM = {2'b00, IEUAdrM}; 
 
  if(`MEM_VIRTMEM) begin : MEM_VIRTMEM
  // *** encapsulate as lsuvirtmem
    logic 					   AnyCPUReqM;
    logic [`PA_BITS-1:0] 		   HPTWAdr;
    logic 					   HPTWRead;
    logic [2:0] 				   HPTWSize;
    logic 					   SelReplayCPURequest;

    assign AnyCPUReqM = (|MemRWM) | (|AtomicM);

    interlockfsm interlockfsm (.clk, .reset, .AnyCPUReqM, .ITLBMissF, .ITLBWriteF,
    .DTLBMissM, .DTLBWriteM, .TrapM, .DCacheStallM,
    .InterlockStall, .SelReplayCPURequest, .SelHPTW,
    .IgnoreRequest);
    
    hptw hptw(.clk, .reset, .SATP_REGW, .PCF, .IEUAdrM,
        .ITLBMissF(ITLBMissF & ~TrapM),
        .DTLBMissM(DTLBMissM & ~TrapM),
        .PTE, .PageType, .ITLBWriteF, .DTLBWriteM,
        .HPTWReadPTE(ReadDataM),
        .DCacheStallM, .HPTWAdr, .HPTWRead, .HPTWSize);

    // arbiter between IEU and hptw
    
    // multiplex the outputs to LSU
    mux2 #(2) rwmux(MemRWM, {HPTWRead, 1'b0}, SelHPTW, PreLSURWM);
    mux2 #(3) sizemux(Funct3M, HPTWSize, SelHPTW, LSUFunct3M);
    mux2 #(7) funct7mux(Funct7M, 7'b0, SelHPTW, LSUFunct7M);    
    mux2 #(2) atomicmux(AtomicM, 2'b00, SelHPTW, LSUAtomicM);
    mux2 #(12) adremux(IEUAdrE[11:0], HPTWAdr[11:0], SelHPTW, PreLSUAdrE);
    mux2 #(12) replaymux(PreLSUAdrE, IEUAdrM[11:0], SelReplayCPURequest, LSUAdrE); // replay cpu request after hptw.
    mux2 #(`PA_BITS) lsupadrmux(IEUAdrExtM[`PA_BITS-1:0], HPTWAdr, SelHPTW, PreLSUPAdrM);

    // always block interrupts when using the hardware page table walker.
    assign CPUBusy = StallW & ~SelHPTW;
    
  end // if (`MEM_VIRTMEM)
  else begin
    assign {InterlockStall, SelHPTW, PTE, PageType, DTLBWriteM, ITLBWriteF} = '0;
    assign IgnoreRequest = TrapM;
    assign CPUBusy = StallW;
    assign LSUAdrE = PreLSUAdrE; assign LSUFunct3M = Funct3M;  assign LSUFunct7M = Funct7M; assign LSUAtomicM = AtomicM;
    assign PreLSURWM = MemRWM; assign PreLSUAdrE = IEUAdrE[11:0]; assign PreLSUPAdrM = IEUAdrExtM;
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

  // MMU and Misalignment fault logic required if privileged unit exists
  if(`ZICSR_SUPPORTED == 1) begin : dmmu

    mmu #(.TLB_ENTRIES(`DTLB_ENTRIES), .IMMU(0))
    dmmu(.clk, .reset, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
      .PrivilegeModeW, .DisableTranslation(SelHPTW),
      .PAdr(PreLSUPAdrM),
      .VAdr(IEUAdrM),
      .Size(LSUFunct3M[1:0]),
      .PTE,
      .PageTypeWriteVal(PageType),
      .TLBWrite(DTLBWriteM),
      .TLBFlush(DTLBFlushM),
      .PhysicalAddress(LSUPAdrM),
      .TLBMiss(DTLBMissM),
      .Cacheable(CacheableM), .Idempotent(), .AtomicAllowed(),
      .InstrAccessFaultF(), .LoadAccessFaultM, .StoreAmoAccessFaultM,
      .InstrPageFaultF(),.LoadPageFaultM, .StoreAmoPageFaultM,
      .LoadMisalignedFaultM, .StoreAmoMisalignedFaultM,         
      .AtomicAccessM(|LSUAtomicM), .ExecuteAccessF(1'b0), // **** change this to just use PreLSURWM
      .WriteAccessM(PreLSURWM[0]), .ReadAccessM(PreLSURWM[1]),
      .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW);

  end else begin
    assign {DTLBMissM, LoadAccessFaultM, StoreAmoAccessFaultM, LoadMisalignedFaultM, StoreAmoMisalignedFaultM} = '0;
    assign {LoadPageFaultM, StoreAmoPageFaultM} = '0;
    assign LSUPAdrM = PreLSUPAdrM;
    assign CacheableM = '1;
  end
  assign LSUStallM = DCacheStallM | InterlockStall | BusStall;
  
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Hart Memory System
  //  Either Data Cache or Data Tightly Integrated Memory or just bus interface
  ////////////////////////////////////////////////////////////////////////////////////////////////

  localparam integer   WORDSPERLINE = `MEM_DCACHE ? `DCACHE_LINELENINBITS/`XLEN : 1;
  localparam integer   LINELEN = `MEM_DCACHE ? `DCACHE_LINELENINBITS : `XLEN;

  logic [`XLEN-1:0]    FinalAMOWriteDataM, FinalWriteDataM;
  logic [`XLEN-1:0]    ReadDataWordM;
  logic [`XLEN-1:0]    ReadDataWordMuxM;
  logic [`PA_BITS-1:0] DCacheBusAdr;
  logic [`XLEN-1:0]    ReadDataLineSetsM [WORDSPERLINE-1:0];
  logic 			   DCacheWriteLine;
  logic 			   DCacheFetchLine;
  logic 			   DCacheBusAck;
  logic [LINELEN-1:0]  DCacheMemWriteData;
  

  if (`MEM_DTIM) begin : dtim
/*    Consider restructuring with higher level blocks.  Try drawing block diagrams with several pages of schematics,
  one for top level, one for each sublevel, alternate with either dtim or bus.  If this looks more satisfactory,
  restructure code accordingly.

  dtim dtim (.clk, .CPUBusy, .LSURWM, .IEUAdrM, .IEUAdrE, .TrapM, .FinalWriteDataM, .ReadDataWordM,
               .BusStallM, .LSUBusWrite, .LSUBusRead, .DCacheBusAck, .BusCommittedM,
               .ReadDataWordMuxM, .DCacheStallM, .DCacheCommittedM, .DCacheWriteLine, .DCacheFetchLine, .DCacheBusAdr,
               .ReadDataLineSetsM, .DCacheMiss, .DCacheAccess); */

    // *** adjust interface so write address doesn't need delaying; switch to standard RAM?
    simpleram #(.BASE(`RAM_BASE), .RANGE(`RAM_RANGE)) ram (
        .clk, 
        .a(CPUBusy | LSURWM[0] ? IEUAdrM[31:0] : IEUAdrE[31:0]),
        .we(LSURWM[0] & ~TrapM),  // have to ignore write if Trap.
        .wd(FinalWriteDataM), .rd(ReadDataWordM));

    // since we have a local memory the bus connections are all disabled.
    // There are no peripherals supported.
    assign {BusStall, LSUBusWrite, LSUBusRead, DCacheBusAck, BusCommittedM} = '0;   
    assign ReadDataWordMuxM = ReadDataWordM;
    assign {DCacheStallM, DCacheCommittedM, DCacheWriteLine, DCacheFetchLine, DCacheBusAdr} = '0;
    assign ReadDataLineSetsM[0] = 0;
    assign DCacheMiss = 1'b0; assign DCacheAccess = 1'b0;
  end else begin : bus  
    // Bus Side logic
    // register the fetch data from the next level of memory.
    // This register should be necessary for timing.  There is no register in the uncore or
    // ahblite controller between the memories and this cache.

    busdp #(WORDSPERLINE, LINELEN) 
    busdp(.clk, .reset,
          .LSUBusHRDATA, .LSUBusAck, .LSUBusWrite, .LSUBusRead, .LSUBusHWDATA, .LSUBusSize, 
          .LSUFunct3M, .LSUBusAdr, .DCacheBusAdr, .ReadDataLineSetsM, .DCacheFetchLine,
          .DCacheWriteLine, .DCacheBusAck, .DCacheMemWriteData, .LSUPAdrM, .FinalAMOWriteDataM,
          .ReadDataWordM, .ReadDataWordMuxM, .IgnoreRequest, .LSURWM, .CPUBusy, .CacheableM,
          .BusStall, .BusCommittedM);
    
    if(`MEM_DCACHE) begin : dcache
      cache #(.LINELEN(`DCACHE_LINELENINBITS), .NUMLINES(`DCACHE_WAYSIZEINBYTES*8/LINELEN),
        .NUMWAYS(`DCACHE_NUMWAYS), .DCACHE(1)) 
        dcache(.clk, .reset, .CPUBusy,
            .RW(CacheableM ? LSURWM : 2'b00), .FlushCache(FlushDCacheM), .Atomic(CacheableM ? LSUAtomicM : 2'b00), 
            .NextAdr(LSUAdrE), .PAdr(LSUPAdrM),
            .FinalWriteData(FinalWriteDataM), .ReadDataWord(ReadDataWordM), .CacheStall(DCacheStallM),
            .CacheMiss(DCacheMiss), .CacheAccess(DCacheAccess), 
            .IgnoreRequest, .CacheCommitted(DCacheCommittedM),
            .CacheBusAdr(DCacheBusAdr), .ReadDataLineSets(ReadDataLineSetsM), .CacheMemWriteData(DCacheMemWriteData),
            .CacheFetchLine(DCacheFetchLine), .CacheWriteLine(DCacheWriteLine), .CacheBusAck(DCacheBusAck), .InvalidateCacheM(1'b0));

    end else begin : passthrough
      assign {ReadDataWordM, DCacheStallM, DCacheCommittedM, DCacheWriteLine, DCacheFetchLine, DCacheBusAdr} = '0;
      assign ReadDataLineSetsM[0] = 0;
      assign DCacheMiss = CacheableM; assign DCacheAccess = CacheableM;
    end
  end

  // sub word selection for read and writes and optional amo alu.
  subwordread subwordread(.ReadDataWordMuxM,
			  .LSUPAdrM(LSUPAdrM[2:0]),
			  .Funct3M(LSUFunct3M),
			  .ReadDataM);

  // this might only get instantiated if there is a dcache or dtim.
  // There is a copy in the ebu. *** is it needed there, or can data come in from ebu, get muxed here and sent back out
  // Explore changing feedback path from output of AMOALU to subword write ***
  subwordwrite subwordwrite(.HRDATA(ReadDataWordM),
			    .HADDRD(LSUPAdrM[2:0]),
			    .HSIZED({LSUFunct3M[2], 1'b0, LSUFunct3M[1:0]}),
			    .HWDATAIN(FinalAMOWriteDataM),
			    .HWDATA(FinalWriteDataM));

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Atomic operations
  ////////////////////////////////////////////////////////////////////////////////////////////////

  if (`A_SUPPORTED) begin:lrsc
    /*atomic atomic(.clk, .reset, .FlushW, .CPUBusy, .MemRead, .PreLSURWM, .LSUAtomicM, .LSUPAdrM,
                    .SquashSCM, .LSURWM, ... ); *** */
    atomic atomic(.clk, .reset, .FlushW, .CPUBusy, .ReadDataM, .WriteDataM, .LSUPAdrM, .LSUFunct7M,
                  .LSUFunct3M, .LSUAtomicM, .PreLSURWM, .IgnoreRequest, .DTLBMissM, 
                  .FinalAMOWriteDataM, .SquashSCW, .LSURWM);

  end else begin:lrsc
    assign SquashSCW = 0; assign LSURWM = PreLSURWM; assign FinalAMOWriteDataM = WriteDataM;
  end
endmodule


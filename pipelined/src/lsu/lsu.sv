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

// committed means the memory operation in flight cannot be interrupted.
// cpubusy means the cpu is stalled and the lsu must ensure ReadDataM stalls constant until the stall is removed.
// chap 5 handling faults to memory by delaying writes to memory stage.
// chap 6 combing bus with dtim
// chap 9 complete lsu.

`include "wally-config.vh"

module lsu (
   input logic              clk, reset,
   input logic              StallM, FlushM, StallW, FlushW,
   output logic             LSUStallM,
   // connected to cpu (controls)
   input logic [1:0]        MemRWM,
   input logic [2:0]        Funct3M,
   input logic [6:0]        Funct7M, 
   input logic [1:0]        AtomicM,
   input logic              TrapM,
   input logic              FlushDCacheM,
   output logic             CommittedM, 
   output logic             SquashSCW,
   output logic             DCacheMiss,
   output logic             DCacheAccess,
   // address and write data
   input logic [`XLEN-1:0]  IEUAdrE,
   (* mark_debug = "true" *)output logic [`XLEN-1:0] IEUAdrM,
   (* mark_debug = "true" *)input logic [`XLEN-1:0] WriteDataM, 
   output logic [`LLEN-1:0] ReadDataW,
   // cpu privilege
   input logic [1:0]        PrivilegeModeW, 
   input logic              BigEndianM,
   input logic              sfencevmaM,
   // fpu
   input logic [`FLEN-1:0]  FWriteDataM,
   input logic              FpLoadStoreM,
   // faults
   output logic             LoadPageFaultM, StoreAmoPageFaultM,
   output logic             LoadMisalignedFaultM, LoadAccessFaultM,
   // cpu hazard unit (trap)
   output logic             StoreAmoMisalignedFaultM, StoreAmoAccessFaultM,
            // connect to ahb
   (* mark_debug = "true" *)   output logic [`PA_BITS-1:0] LSUHADDR,
   (* mark_debug = "true" *)   output logic LSUBusRead, 
   (* mark_debug = "true" *)   output logic LSUBusWrite,
   (* mark_debug = "true" *)   input logic LSUBusAck,
   (* mark_debug = "true" *)   input logic LSUBusInit,
   (* mark_debug = "true" *)   input logic [`XLEN-1:0] HRDATA,
   (* mark_debug = "true" *)   output logic [`XLEN-1:0] LSUHWDATA,
   (* mark_debug = "true" *)   input logic LSUHREADY,
   (* mark_debug = "true" *)   output logic LSUHWRITE,
   (* mark_debug = "true" *)   output logic [2:0] LSUHSIZE, 
   (* mark_debug = "true" *)   output logic [2:0] LSUHBURST,
   (* mark_debug = "true" *)   output logic [1:0] LSUHTRANS,
   (* mark_debug = "true" *)   output logic [`XLEN/8-1:0] LSUHWSTRB,
   (* mark_debug = "true" *)   output logic LSUTransComplete,
            // page table walker
   input logic [`XLEN-1:0]  SATP_REGW, // from csr
   input logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV,
   input logic [1:0]        STATUS_MPP,
   input logic [`XLEN-1:0]  PCF,
   input logic              ITLBMissF,
   input logic              InstrDAPageFaultF,
   output logic [`XLEN-1:0] PTE,
   output logic [1:0]       PageType,
   output logic             ITLBWriteF, SelHPTW,
   input var                logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
   input var                logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0] // *** this one especially has a large note attached to it in pmpchecker.
  );

  logic [`XLEN+1:0]         IEUAdrExtM;
  logic [`XLEN+1:0]         IEUAdrExtE;
  logic [`PA_BITS-1:0]      LSUPAdrM;
  logic                     DTLBMissM;
  logic                     DTLBWriteM;
  logic [1:0]               NonDTIMMemRWM, PreLSURWM, LSURWM;
  logic [2:0]               LSUFunct3M;
  logic [6:0]               LSUFunct7M;
  logic [1:0]               LSUAtomicM;
  (* mark_debug = "true" *)  logic [`XLEN+1:0] 		   PreLSUPAdrM;
  logic [11:0]              LSUAdrE;  
  logic                     SelDTIM;
  logic                     CPUBusy;
  logic                     DCacheStallM;
  logic                     CacheableM;
  logic                     BusStall;
  logic                     InterlockStall;
  logic                     IgnoreRequestTLB;
  logic                     BusCommittedM, DCacheCommittedM;
  logic                     DataDAPageFaultM;
  logic [`XLEN-1:0]         IMWriteDataM, IMAWriteDataM;
  logic [`LLEN-1:0]         IMAFWriteDataM;
  logic [`LLEN-1:0]         ReadDataM;
  logic [(`LLEN-1)/8:0]     ByteMaskM;
  
  flopenrc #(`XLEN) AddressMReg(clk, reset, FlushM, ~StallM, IEUAdrE, IEUAdrM);
  assign IEUAdrExtM = {2'b00, IEUAdrM}; 
  assign IEUAdrExtE = {2'b00, IEUAdrE}; 
  assign LSUStallM = DCacheStallM | InterlockStall | BusStall;

  /////////////////////////////////////////////////////////////////////////////////////////////
  // HPTW and Interlock FSM (only needed if VM supported)
  // MMU include PMP and is needed if any privileged supported
  /////////////////////////////////////////////////////////////////////////////////////////////

  if(`VIRTMEM_SUPPORTED) begin : VIRTMEM_SUPPORTED
    lsuvirtmem lsuvirtmem(.clk, .reset, .StallW, .MemRWM(NonDTIMMemRWM), .AtomicM, .ITLBMissF, .ITLBWriteF,
      .DTLBMissM, .DTLBWriteM, .InstrDAPageFaultF, .DataDAPageFaultM, 
      .TrapM, .DCacheStallM, .SATP_REGW, .PCF,
      .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP, .PrivilegeModeW,
      .ReadDataM(ReadDataM[`XLEN-1:0]), .WriteDataM, .Funct3M, .LSUFunct3M, .Funct7M, .LSUFunct7M,
      .IEUAdrExtM, .PTE, .IMWriteDataM, .PageType, .PreLSURWM, .LSUAtomicM, .IEUAdrE,
      .LSUAdrE, .PreLSUPAdrM, .CPUBusy, .InterlockStall, .SelHPTW,
      .IgnoreRequestTLB);
  end else begin
    assign {InterlockStall, SelHPTW, PTE, PageType, DTLBWriteM, ITLBWriteF, IgnoreRequestTLB} = '0;
    assign CPUBusy = StallW; assign PreLSURWM = NonDTIMMemRWM; 
    assign LSUAdrE = IEUAdrE[11:0]; 
    assign PreLSUPAdrM = IEUAdrExtM;
    assign LSUFunct3M = Funct3M;  assign LSUFunct7M = Funct7M; assign LSUAtomicM = AtomicM;
    assign IMWriteDataM = WriteDataM;
   end

  // CommittedM tells the CPU's privilege unit the current instruction
  // in the memory stage is a memory operaton and that memory operation is either completed
  // or is partially executed. Partially completed memory operations need to prevent an interrupts.
  // There is not a clean way to restore back to a partial executed instruction.  CommiteedM will
  // delay the interrupt until the LSU is in a clean state.
  assign CommittedM = SelHPTW | DCacheCommittedM | BusCommittedM;

  // MMU and Misalignment fault logic required if privileged unit exists
  // *** DH: This is too strong a requirement.  Separate MMU in `VIRTMEM_SUPPORTED from simpler faults in `ZICSR_SUPPORTED
  if(`ZICSR_SUPPORTED == 1) begin : dmmu
    logic DisableTranslation;
    assign DisableTranslation = SelHPTW | FlushDCacheM;
    mmu #(.TLB_ENTRIES(`DTLB_ENTRIES), .IMMU(0))
    dmmu(.clk, .reset, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
      .PrivilegeModeW, .DisableTranslation,
      .VAdr(PreLSUPAdrM),
      .Size(LSUFunct3M[1:0]),
      .PTE,
      .PageTypeWriteVal(PageType),
      .TLBWrite(DTLBWriteM),
      .TLBFlush(sfencevmaM),
      .PhysicalAddress(LSUPAdrM),
      .TLBMiss(DTLBMissM),
      .Cacheable(CacheableM), .Idempotent(), .AtomicAllowed(),
      .InstrAccessFaultF(), .LoadAccessFaultM, .StoreAmoAccessFaultM,
      .InstrPageFaultF(),.LoadPageFaultM, .StoreAmoPageFaultM,
      .LoadMisalignedFaultM, .StoreAmoMisalignedFaultM,   // *** these faults need to be supressed during hptw.
      .DAPageFault(DataDAPageFaultM),
         // *** should use LSURWM as this is includes the lr/sc squash. However this introduces a combo loop
         // from squash, depends on LSUPAdrM, depends on TLBHit, depends on these *AccessM inputs.
      .AtomicAccessM(|LSUAtomicM), .ExecuteAccessF(1'b0), 
      .WriteAccessM(PreLSURWM[0]), .ReadAccessM(PreLSURWM[1]),
      .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW);

  end else begin
    // Determine which region of physical memory (if any) is being accessed

    // conditionally move adredecs to here and ifu.
    // the lsu will output LSUHSel to EBU (need the same for ifu).
    // The ebu will have a mux to select between LSUHSel, IFUHSel
    // mux for HWSTRB
    // adrdecs out of uncore.
    
    assign {DTLBMissM, LoadAccessFaultM, StoreAmoAccessFaultM, LoadMisalignedFaultM, StoreAmoMisalignedFaultM} = '0;
    assign {LoadPageFaultM, StoreAmoPageFaultM} = '0;
    assign LSUPAdrM = PreLSUPAdrM;
    assign CacheableM = '1;
  end
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  //  Memory System
  //  Either Data Cache or Data Tightly Integrated Memory or just bus interface
  /////////////////////////////////////////////////////////////////////////////////////////////
  logic [`LLEN-1:0]    LSUWriteDataM, LittleEndianWriteDataM;
  logic [`LLEN-1:0]    ReadDataWordM, LittleEndianReadDataWordM;
  logic [`LLEN-1:0]    ReadDataWordMuxM;
  logic                IgnoreRequest;
  assign IgnoreRequest = IgnoreRequestTLB | TrapM;
  
  if (`DTIM_SUPPORTED) begin : dtim
    logic [`PA_BITS-1:0] DTIMAdr;
    logic             DTIMAccessRW;
    logic             MemStage;

    // The DTIM uses untranslated addresses, so it is not compatible with virtual memory.
    // Don't perform size checking on DTIM
    /* verilator lint_off WIDTH */
    assign MemStage = CPUBusy | MemRWM[0] | reset; // 1 = M stage; 0 = E stage
    assign DTIMAdr = MemStage ? IEUAdrExtM : IEUAdrExtE; // zero extend or contract to PA_BITS
    /* verilator lint_on WIDTH */
    assign DTIMAccessRW = |MemRWM; 
    adrdec dtimdec(IEUAdrExtM, `DTIM_BASE, `DTIM_RANGE, `DTIM_SUPPORTED, DTIMAccessRW, 2'b10, 4'b1111, SelDTIM); // maybe we pull this out of the mmu?
    //assign NonDTIMMemRWM = MemRWM & ~{2{SelDTIM}}; // disable access to bus-based memory map when DTIM is selected
    assign NonDTIMMemRWM = MemRWM; // *** fix

    dtim dtim(.clk, .reset, .MemRWM,
              .Adr(DTIMAdr),
              .TrapM, .WriteDataM(LSUWriteDataM), 
              .ReadDataWordM(ReadDataWordM[`XLEN-1:0]), .ByteMaskM(ByteMaskM[`XLEN/8-1:0]));
  end else begin
    assign SelDTIM = 0;  assign NonDTIMMemRWM = MemRWM;
  end
  if (`BUS) begin : bus              
    localparam integer   WORDSPERLINE = `DCACHE ? `DCACHE_LINELENINBITS/`XLEN : 1;
    localparam integer   LOGBWPL = `DCACHE ? $clog2(WORDSPERLINE) : 1;
    if(`DCACHE) begin : dcache
      localparam integer   LINELEN = `DCACHE ? `DCACHE_LINELENINBITS : `XLEN;
      logic [LINELEN-1:0]  FetchBuffer;
      logic [`PA_BITS-1:0] DCacheBusAdr;
      logic                DCacheWriteLine;
      logic                DCacheFetchLine;
      logic [LOGBWPL-1:0]  WordCount;
      logic                SelUncachedAdr, DCacheBusAck;
      logic                SelBusWord;
      logic [`XLEN-1:0]    LSUHWDATA_noDELAY; //*** change name
      logic [`XLEN/8-1:0]  ByteMaskMDelay;

      cache #(.LINELEN(`DCACHE_LINELENINBITS), .NUMLINES(`DCACHE_WAYSIZEINBYTES*8/LINELEN),
              .NUMWAYS(`DCACHE_NUMWAYS), .LOGBWPL(LOGBWPL), .WORDLEN(`LLEN), .MUXINTERVAL(`XLEN), .DCACHE(1)) dcache(
        .clk, .reset, .CPUBusy, .SelBusWord, .RW(LSURWM), .Atomic(LSUAtomicM),
        .FlushCache(FlushDCacheM), .NextAdr(LSUAdrE), .PAdr(LSUPAdrM), 
        .ByteMask(ByteMaskM), .WordCount,
        .FinalWriteData(LSUWriteDataM), .Cacheable(CacheableM),
        .CacheStall(DCacheStallM), .CacheMiss(DCacheMiss), .CacheAccess(DCacheAccess),
        .IgnoreRequestTLB, .TrapM, .CacheCommitted(DCacheCommittedM), 
        .CacheBusAdr(DCacheBusAdr), .ReadDataWord(ReadDataWordM), 
        .FetchBuffer, .CacheFetchLine(DCacheFetchLine), 
        .CacheWriteLine(DCacheWriteLine), .CacheBusAck(DCacheBusAck), .InvalidateCache(1'b0));
      AHBCachedp #(WORDSPERLINE, LINELEN, LOGBWPL, `DCACHE) cachedp(
        .HCLK(clk), .HRESETn(~reset),
        .HRDATA, 
        .HSIZE(LSUHSIZE), .HBURST(LSUHBURST), .HTRANS(LSUHTRANS), .HWRITE(LSUHWRITE), .HREADY(LSUHREADY),
        .WordCount, .SelBusWord,
        .Funct3(LSUFunct3M), .HADDR(LSUHADDR), .CacheBusAdr(DCacheBusAdr), .CacheRW({DCacheFetchLine, DCacheWriteLine} & ~{IgnoreRequest, IgnoreRequest}),
        .CacheBusAck(DCacheBusAck), .FetchBuffer, .PAdr(LSUPAdrM),
        .SelUncachedAdr, .RW(LSURWM & ~{IgnoreRequest, IgnoreRequest} & ~{CacheableM, CacheableM}), .CPUBusy, .Cacheable(CacheableM),
        .BusStall, .BusCommitted(BusCommittedM));

      mux2 #(`LLEN) UnCachedDataMux(.d0(LittleEndianReadDataWordM), .d1({{`LLEN-`XLEN{1'b0}}, FetchBuffer[`XLEN-1:0] }),
        .s(SelUncachedAdr), .y(ReadDataWordMuxM));
      mux2 #(`XLEN) LSUHWDATAMux(.d0(ReadDataWordM[`XLEN-1:0]), .d1(LSUWriteDataM[`XLEN-1:0]),
        .s(SelUncachedAdr), .y(LSUHWDATA_noDELAY));

      flop #(`XLEN) wdreg(clk, LSUHWDATA_noDELAY, LSUHWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN

      // *** bummer need a second byte mask for bus as it is XLEN rather than LLEN.
      logic [`XLEN/8-1:0]  BusByteMaskM;
      swbytemask #(`XLEN) busswbytemask(.Size(LSUFunct3M), .Adr(LSUPAdrM[$clog2(`XLEN/8)-1:0]), .ByteMask(BusByteMaskM));
      
      flop #(`XLEN/8) HWSTRBReg(clk, BusByteMaskM[`XLEN/8-1:0], LSUHWSTRB);
      

    end else begin : passthrough // just needs a register to hold the value from the bus
      logic CaptureEn;
      assign LSUHADDR = LSUPAdrM;
      assign LSUHSIZE = LSUFunct3M;
 
      flopen #(`XLEN) fb(.clk, .en(CaptureEn), .d(HRDATA), .q(ReadDataWordM));

      flop #(`XLEN) wdreg(clk, LSUWriteDataM, LSUHWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN
      flop #(`XLEN/8) HWSTRBReg(clk, ByteMaskM, LSUHWSTRB);

/* -----\/----- EXCLUDED -----\/-----
      busfsm #(LOGBWPL) busfsm(
        .clk, .reset, .RW(LSURWM & ~{IgnoreRequest, IgnoreRequest}), 
        .BusAck(LSUBusAck), .BusInit(LSUBusInit), .CPUBusy, 
        .BusStall, .BusWrite(LSUBusWrite), .BusRead(LSUBusRead), 
        .HTRANS(LSUHTRANS), .BusCommitted(BusCommittedM));
 -----/\----- EXCLUDED -----/\----- */

      AHBBusfsm busfsm(.HCLK(clk), .HRESETn(~reset), .RW(LSURWM & ~{IgnoreRequest, IgnoreRequest}),
                       .BusCommitted(BusCommittedM), .CPUBusy, .BusStall, .CaptureEn, .HREADY(LSUHREADY), .HTRANS(LSUHTRANS),
                       .HWRITE(LSUHWRITE));
          
      assign ReadDataWordMuxM = LittleEndianReadDataWordM;  // from byte swapping
      assign LSUHBURST = 3'b0;
      assign LSUTransComplete = LSUBusAck;
      assign {DCacheStallM, DCacheCommittedM, DCacheMiss, DCacheAccess} = '0;
 end
  end else begin: nobus // block: bus
    assign LSUHWDATA = '0; 
    assign ReadDataWordMuxM = LittleEndianReadDataWordM;
    assign {BusStall, BusCommittedM} = '0;   
    assign {DCacheMiss, DCacheAccess} = '0;
    assign {DCacheStallM, DCacheCommittedM} = '0;
  end

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Atomic operations
  /////////////////////////////////////////////////////////////////////////////////////////////
  if (`A_SUPPORTED) begin:atomic
    atomic atomic(.clk, .reset, .StallW, .ReadDataM(ReadDataM[`XLEN-1:0]), .IMWriteDataM, .LSUPAdrM, 
      .LSUFunct7M, .LSUFunct3M, .LSUAtomicM, .PreLSURWM, .IgnoreRequest, 
      .IMAWriteDataM, .SquashSCW, .LSURWM);
  end else begin:lrsc
    assign SquashSCW = 0; assign LSURWM = PreLSURWM; assign IMAWriteDataM = IMWriteDataM;
  end

  if (`F_SUPPORTED) 
    mux2 #(`LLEN) datamux({{{`LLEN-`XLEN}{1'b0}}, IMAWriteDataM}, FWriteDataM, FpLoadStoreM, IMAFWriteDataM);
  else assign IMAFWriteDataM = IMAWriteDataM;
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Subword Accesses
  /////////////////////////////////////////////////////////////////////////////////////////////
  subwordread subwordread(.ReadDataWordMuxM, .LSUPAdrM(LSUPAdrM[2:0]),
		.FpLoadStoreM, .Funct3M(LSUFunct3M), .ReadDataM);
  subwordwrite subwordwrite(.LSUPAdrM(LSUPAdrM[2:0]),
    .LSUFunct3M, .IMAFWriteDataM, .LittleEndianWriteDataM);

  // Compute byte masks
  swbytemask #(`LLEN) swbytemask(.Size(LSUFunct3M), .Adr(LSUPAdrM[$clog2(`LLEN/8)-1:0]), .ByteMask(ByteMaskM));

  /////////////////////////////////////////////////////////////////////////////////////////////
  // MW Pipeline Register
  /////////////////////////////////////////////////////////////////////////////////////////////

  flopen #(`LLEN) ReadDataMWReg(clk, ~StallW, ReadDataM, ReadDataW);

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Big Endian Byte Swapper
  //  hart works little-endian internally
  //  swap the bytes when read from big-endian memory
  /////////////////////////////////////////////////////////////////////////////////////////////
  if (`BIGENDIAN_SUPPORTED) begin:endian
    bigendianswap #(`LLEN) storeswap(.BigEndianM, .a(LittleEndianWriteDataM), .y(LSUWriteDataM));
    bigendianswap #(`LLEN) loadswap(.BigEndianM, .a(ReadDataWordM), .y(LittleEndianReadDataWordM));
  end else begin
    assign LSUWriteDataM = LittleEndianWriteDataM;
    assign LittleEndianReadDataWordM = ReadDataWordM;
  end

endmodule

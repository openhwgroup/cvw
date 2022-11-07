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
   (* mark_debug = "true" *)   input logic [`XLEN-1:0] HRDATA,
   (* mark_debug = "true" *)   output logic [`XLEN-1:0] LSUHWDATA,
   (* mark_debug = "true" *)   input logic LSUHREADY,
   (* mark_debug = "true" *)   output logic LSUHWRITE,
   (* mark_debug = "true" *)   output logic [2:0] LSUHSIZE, 
   (* mark_debug = "true" *)   output logic [2:0] LSUHBURST,
   (* mark_debug = "true" *)   output logic [1:0] LSUHTRANS,
   (* mark_debug = "true" *)   output logic [`XLEN/8-1:0] LSUHWSTRB,
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
  logic [`PA_BITS-1:0]      PAdrM;
  logic                     DTLBMissM;
  logic                     DTLBWriteM;
  logic [1:0]               PreLSURWM, LSURWM;
  logic [2:0]               LSUFunct3M;
  logic [6:0]               LSUFunct7M;
  logic [1:0]               LSUAtomicM;
  (* mark_debug = "true" *)  logic [`XLEN+1:0] 		   IHAdrM;
  logic                     CPUBusy;
  logic                     DCacheStallM;
  logic                     CacheableM;
  logic                     BusStall;
  logic                     HPTWStall;
  logic                     IgnoreRequestTLB;
  logic                     BusCommittedM, DCacheCommittedM;
  logic                     DataDAPageFaultM;
  logic [`XLEN-1:0]         IMWriteDataM, IMAWriteDataM;
  logic [`LLEN-1:0]         IMAFWriteDataM;
  logic [`LLEN-1:0]         ReadDataM;
  logic [(`LLEN-1)/8:0]     ByteMaskM;
  logic                     SelDTIM;
    
  flopenrc #(`XLEN) AddressMReg(clk, reset, FlushM, ~StallM, IEUAdrE, IEUAdrM);
  assign IEUAdrExtM = {2'b00, IEUAdrM}; 
  assign IEUAdrExtE = {2'b00, IEUAdrE};
  assign LSUStallM = DCacheStallM | HPTWStall | BusStall;

  /////////////////////////////////////////////////////////////////////////////////////////////
  // HPTW and Interlock FSM (only needed if VM supported)
  // MMU include PMP and is needed if any privileged supported
  /////////////////////////////////////////////////////////////////////////////////////////////

  if(`VIRTMEM_SUPPORTED) begin : VIRTMEM_SUPPORTED
    lsuvirtmem lsuvirtmem(.clk, .reset, .StallW, .MemRWM, .AtomicM, .ITLBMissF, .ITLBWriteF,
      .DTLBMissM, .DTLBWriteM, .InstrDAPageFaultF, .DataDAPageFaultM,
      .FlushW, .DCacheStallM, .SATP_REGW, .PCF,
      .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP, .PrivilegeModeW,
      .ReadDataM(ReadDataM[`XLEN-1:0]), .WriteDataM, .Funct3M, .LSUFunct3M, .Funct7M, .LSUFunct7M,
      .IEUAdrExtM, .PTE, .IMWriteDataM, .PageType, .PreLSURWM, .LSUAtomicM,
      .IHAdrM, .CPUBusy, .HPTWStall, .SelHPTW,
      .IgnoreRequestTLB);
  end else begin
    assign {HPTWStall, SelHPTW, PTE, PageType, DTLBWriteM, ITLBWriteF, IgnoreRequestTLB} = '0;
    assign CPUBusy = StallW; assign PreLSURWM = MemRWM; 
    assign IHAdrM = IEUAdrExtM;
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
  if(`ZICSR_SUPPORTED == 1) begin : dmmu
    logic DisableTranslation;
    assign DisableTranslation = SelHPTW | FlushDCacheM;
    mmu #(.TLB_ENTRIES(`DTLB_ENTRIES), .IMMU(0))
    dmmu(.clk, .reset, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
      .PrivilegeModeW, .DisableTranslation,
      .VAdr(IHAdrM),
      .Size(LSUFunct3M[1:0]),
      .PTE,
      .PageTypeWriteVal(PageType),
      .TLBWrite(DTLBWriteM),
      .TLBFlush(sfencevmaM),
      .PhysicalAddress(PAdrM),
      .TLBMiss(DTLBMissM),
      .Cacheable(CacheableM), .Idempotent(), .AtomicAllowed(), .SelTIM(SelDTIM),
      .InstrAccessFaultF(), .LoadAccessFaultM, .StoreAmoAccessFaultM,
      .InstrPageFaultF(),.LoadPageFaultM, .StoreAmoPageFaultM,
      .LoadMisalignedFaultM, .StoreAmoMisalignedFaultM,   // *** these faults need to be supressed during hptw.
      .DAPageFault(DataDAPageFaultM),
         // *** should use LSURWM as this is includes the lr/sc squash. However this introduces a combo loop
         // from squash, depends on PAdrM, depends on TLBHit, depends on these *AccessM inputs.
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
    assign PAdrM = IHAdrM[`PA_BITS-1:0];
    assign CacheableM = '1;
    assign SelDTIM = `DTIM_SUPPORTED & ~`BUS; // if no pma then select dtim if there is a DTIM.  If there is 
    // a bus then this is always 0. Cannot have both without PMA.
  end
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  //  Memory System
  //  Either Data Cache or Data Tightly Integrated Memory or just bus interface
  /////////////////////////////////////////////////////////////////////////////////////////////
  logic [`LLEN-1:0]    LSUWriteDataM, LittleEndianWriteDataM;
  logic [`LLEN-1:0]    ReadDataWordM, LittleEndianReadDataWordM;
  logic [`LLEN-1:0]    ReadDataWordMuxM, DTIMReadDataWordM, DCacheReadDataWordM;
  logic                IgnoreRequest;
  assign IgnoreRequest = IgnoreRequestTLB | FlushW;
  
  if (`DTIM_SUPPORTED) begin : dtim
    logic [`PA_BITS-1:0] DTIMAdr;
    logic [1:0]          DTIMMemRWM;
    
    // The DTIM uses untranslated addresses, so it is not compatible with virtual memory.
    assign DTIMAdr = MemRWM[0] ? IEUAdrExtM[`PA_BITS-1:0] : IEUAdrExtE[`PA_BITS-1:0]; // zero extend or contract to PA_BITS
    assign DTIMMemRWM = SelDTIM & ~IgnoreRequestTLB ? LSURWM : '0;
    // **** fix ReadDataWordM to be LLEN. ByteMask is wrong length.
    // **** create config to support DTIM with floating point.
    dtim dtim(.clk, .reset, .ce(~CPUBusy), .MemRWM(DTIMMemRWM),
              .Adr(DTIMAdr),
              .FlushW, .WriteDataM(LSUWriteDataM), 
              .ReadDataWordM(DTIMReadDataWordM[`XLEN-1:0]), .ByteMaskM(ByteMaskM[`XLEN/8-1:0]));
  end else begin
  end
  if (`BUS) begin : bus              
    localparam integer   LLENWORDSPERLINE = `DCACHE ? `DCACHE_LINELENINBITS/`LLEN : 1;
    localparam integer   LLENLOGBWPL = `DCACHE ? $clog2(LLENWORDSPERLINE) : 1;
    localparam integer   AHBWWORDSPERLINE = `DCACHE ? `DCACHE_LINELENINBITS/`AHBW : 1;
    localparam integer   AHBWLOGBWPL = `DCACHE ? $clog2(AHBWWORDSPERLINE) : 1;
    if(`DCACHE) begin : dcache
      localparam integer   LINELEN = `DCACHE ? `DCACHE_LINELENINBITS : `XLEN;
      logic [LINELEN-1:0]  FetchBuffer;
      logic [`PA_BITS-1:0] DCacheBusAdr;
      logic                DCacheWriteLine;
      logic                DCacheFetchLine;
      logic [AHBWLOGBWPL-1:0]  WordCount;
      logic                DCacheBusAck;
      logic                SelBusWord;
      logic [`XLEN-1:0]    PreHWDATA; //*** change name
      logic [`XLEN/8-1:0]  ByteMaskMDelay;
      logic [1:0]          CacheBusRW, BusRW;
      localparam integer   LLENPOVERAHBW = `LLEN / `AHBW;
      logic                CacheableOrFlushCacheM;
      logic [1:0]          CacheRWM, CacheAtomicM;
      logic                CacheFlushM;
      
      assign BusRW = ~CacheableM & ~IgnoreRequestTLB & ~SelDTIM ? LSURWM : '0;
      assign CacheableOrFlushCacheM = CacheableM | FlushDCacheM;
      assign CacheRWM = CacheableM & ~IgnoreRequestTLB & ~SelDTIM ? LSURWM : '0;
      assign CacheAtomicM = CacheableM & ~IgnoreRequestTLB & ~SelDTIM ? LSUAtomicM : '0;
      assign CacheFlushM  = FlushDCacheM;
      
      cache #(.LINELEN(`DCACHE_LINELENINBITS), .NUMLINES(`DCACHE_WAYSIZEINBYTES*8/LINELEN),
              .NUMWAYS(`DCACHE_NUMWAYS), .LOGBWPL(LLENLOGBWPL), .WORDLEN(`LLEN), .MUXINTERVAL(`LLEN), .DCACHE(1)) dcache(
        .clk, .reset, .CPUBusy, .SelBusWord, .Flush(FlushW), .CacheRW(CacheRWM), .CacheAtomic(CacheAtomicM),
        .FlushCache(CacheFlushM), .NextAdr(IEUAdrE[11:0]), .PAdr(PAdrM), 
        .ByteMask(ByteMaskM), .WordCount(WordCount[AHBWLOGBWPL-1:AHBWLOGBWPL-LLENLOGBWPL]),
        .FinalWriteData(LSUWriteDataM), .SelHPTW,
        .CacheStall(DCacheStallM), .CacheMiss(DCacheMiss), .CacheAccess(DCacheAccess),
        .CacheCommitted(DCacheCommittedM), 
        .CacheBusAdr(DCacheBusAdr), .ReadDataWord(DCacheReadDataWordM), 
        .FetchBuffer, .CacheBusRW, 
        .CacheBusAck(DCacheBusAck), .InvalidateCache(1'b0));
      ahbcacheinterface #(.WORDSPERLINE(AHBWWORDSPERLINE), .LINELEN(LINELEN), .LOGWPL(AHBWLOGBWPL), .CACHE_ENABLED(`DCACHE)) ahbcacheinterface(
        .HCLK(clk), .HRESETn(~reset), .Flush(FlushW),
        .HRDATA, 
        .HSIZE(LSUHSIZE), .HBURST(LSUHBURST), .HTRANS(LSUHTRANS), .HWRITE(LSUHWRITE), .HREADY(LSUHREADY),
        .WordCount, .SelBusWord,
        .Funct3(LSUFunct3M), .HADDR(LSUHADDR), .CacheBusAdr(DCacheBusAdr), .CacheBusRW,
        .CacheBusAck(DCacheBusAck), .FetchBuffer, .PAdr(PAdrM),
        .Cacheable(CacheableOrFlushCacheM), .BusRW, .CPUBusy,
        .BusStall, .BusCommitted(BusCommittedM));

      // FetchBuffer[`AHBW-1:0] needs to be duplicated LLENPOVERAHBW times.
      // DTIMReadDataWordM should be increased to LLEN.
      // *** DTIMReadDataWordM should be LLEN
      // pma should generate expection for LLEN read to periph.
      mux3 #(`LLEN) UnCachedDataMux(.d0(DCacheReadDataWordM), .d1({LLENPOVERAHBW{FetchBuffer[`XLEN-1:0]}}),
                                    .d2({{`LLEN-`XLEN{1'b0}}, DTIMReadDataWordM[`XLEN-1:0]}),
                                    .s({SelDTIM, ~(CacheableOrFlushCacheM)}), .y(ReadDataWordMuxM));

      // When AHBW is less than LLEN need extra muxes to select the subword from cache's read data.
      logic [`AHBW-1:0]    DCacheReadDataWordAHB;
      if(LLENPOVERAHBW > 1) begin
        logic [`AHBW-1:0]          AHBWordSets [(LLENPOVERAHBW)-1:0];
        genvar                     index;
        for (index = 0; index < LLENPOVERAHBW; index++) begin:readdatalinesetsmux
	      assign AHBWordSets[index] = DCacheReadDataWordM[(index*`AHBW)+`AHBW-1: (index*`AHBW)];
        end
        assign DCacheReadDataWordAHB = AHBWordSets[WordCount[$clog2(LLENPOVERAHBW)-1:0]];
      end else assign DCacheReadDataWordAHB = DCacheReadDataWordM[`AHBW-1:0];      
      mux2 #(`XLEN) LSUHWDATAMux(.d0(DCacheReadDataWordAHB), .d1(LSUWriteDataM[`AHBW-1:0]),
        .s(~(CacheableOrFlushCacheM)), .y(PreHWDATA));

      flopen #(`AHBW) wdreg(clk, LSUHREADY, PreHWDATA, LSUHWDATA); // delay HWDATA by 1 cycle per spec

      // *** bummer need a second byte mask for bus as it is AHBW rather than LLEN.
      // probably can merge by muxing PAdrM's LLEN/8-1 index bit based on HTRANS being != 0.
      logic [`AHBW/8-1:0]  BusByteMaskM;
      swbytemask #(`AHBW) busswbytemask(.Size(LSUHSIZE), .Adr(PAdrM[$clog2(`AHBW/8)-1:0]), .ByteMask(BusByteMaskM));
      
      flop #(`AHBW/8) HWSTRBReg(clk, BusByteMaskM[`AHBW/8-1:0], LSUHWSTRB);

    end else begin : passthrough // just needs a register to hold the value from the bus
      logic CaptureEn;
      logic [1:0] BusRW;
      logic [`XLEN-1:0] FetchBuffer;
      assign BusRW = ~IgnoreRequestTLB & ~SelDTIM ? LSURWM : '0;
//      assign BusRW = LSURWM & ~{IgnoreRequest, IgnoreRequest} & ~{SelDTIM, SelDTIM};
      
      assign LSUHADDR = PAdrM;
      assign LSUHSIZE = LSUFunct3M;

      ahbinterface #(1) ahbinterface(.HCLK(clk), .HRESETn(~reset), .Flush(FlushW), .HREADY(LSUHREADY), 
        .HRDATA(HRDATA), .HTRANS(LSUHTRANS), .HWRITE(LSUHWRITE), .HWDATA(LSUHWDATA),
        .HWSTRB(LSUHWSTRB), .BusRW, .ByteMask(ByteMaskM), .WriteData(LSUWriteDataM),
        .CPUBusy, .BusStall, .BusCommitted(BusCommittedM), .FetchBuffer(FetchBuffer));

      if(`DTIM_SUPPORTED) mux2 #(`XLEN) ReadDataMux2(FetchBuffer, DTIMReadDataWordM, SelDTIM, ReadDataWordMuxM);
      else assign ReadDataWordMuxM = FetchBuffer[`XLEN-1:0];
      assign LSUHBURST = 3'b0;
      assign {DCacheStallM, DCacheCommittedM, DCacheMiss, DCacheAccess} = '0;
 end
  end else begin: nobus // block: bus
    assign LSUHWDATA = '0; 
    assign ReadDataWordMuxM = DTIMReadDataWordM;
    assign {BusStall, BusCommittedM} = '0;   
    assign {DCacheMiss, DCacheAccess} = '0;
    assign {DCacheStallM, DCacheCommittedM} = '0;
  end

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Atomic operations
  /////////////////////////////////////////////////////////////////////////////////////////////
  if (`A_SUPPORTED) begin:atomic
    atomic atomic(.clk, .reset, .StallW, .ReadDataM(ReadDataM[`XLEN-1:0]), .IMWriteDataM, .PAdrM, 
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
  subwordread subwordread(.ReadDataWordMuxM(LittleEndianReadDataWordM), .PAdrM(PAdrM[2:0]), .BigEndianM,
		.FpLoadStoreM, .Funct3M(LSUFunct3M), .ReadDataM);
  subwordwrite subwordwrite(.LSUFunct3M, .IMAFWriteDataM, .LittleEndianWriteDataM);

  // Compute byte masks
  swbytemask #(`LLEN) swbytemask(.Size(LSUFunct3M), .Adr(PAdrM[$clog2(`LLEN/8)-1:0]), .ByteMask(ByteMaskM));

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
    endianswap #(`LLEN) storeswap(.BigEndianM, .a(LittleEndianWriteDataM), .y(LSUWriteDataM));
    endianswap #(`LLEN) loadswap(.BigEndianM, .a(ReadDataWordMuxM), .y(LittleEndianReadDataWordM));
  end else begin
    assign LSUWriteDataM = LittleEndianWriteDataM;
    assign LittleEndianReadDataWordM = ReadDataWordMuxM;
  end

endmodule

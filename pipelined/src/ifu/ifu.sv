///////////////////////////////////////////
// ifu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified:
//
// Purpose: Instrunction Fetch Unit
//           PC, branch prediction, instruction cache
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

module ifu (
	input logic 				clk, reset,
	input logic 				StallF, StallD, StallE, StallM, StallW,
	input logic 				FlushF, FlushD, FlushE, FlushM, FlushW,
	// Bus interface
(* mark_debug = "true" *)	input logic [`XLEN-1:0] 	IFUBusHRDATA,
(* mark_debug = "true" *)	input logic 				IFUBusAck,
(* mark_debug = "true" *)	output logic [`PA_BITS-1:0] IFUBusAdr,
(* mark_debug = "true" *)	output logic 				IFUBusRead,
(* mark_debug = "true" *)	output logic 				IFUStallF,
	(* mark_debug = "true" *) output logic [`XLEN-1:0] PCF, 
	// Execute
	output logic [`XLEN-1:0] 	PCLinkE,
	input logic 				PCSrcE, 
	input logic [`XLEN-1:0] 	IEUAdrE,
	output logic [`XLEN-1:0] 	PCE,
	output logic 				BPPredWrongE, 
	// Mem
	input logic 				RetM, TrapM, 
	input logic [`XLEN-1:0] 	PrivilegedNextPCM, 
	input logic 				InvalidateICacheM,
	output logic [31:0] 		InstrD, InstrM, 
	output logic [`XLEN-1:0] 	PCM, 
	// branch predictor
	output logic [4:0] 			InstrClassM,
	output logic 				BPPredDirWrongM,
	output logic 				BTBPredPCWrongM,
	output logic 				RASPredPCWrongM,
	output logic 				BPPredClassNonCFIWrongM,
	// Faults
	input logic 				IllegalBaseInstrFaultD,
	output logic 				InstrPageFaultF,
	output logic 				IllegalIEUInstrFaultD,
	output logic 				InstrMisalignedFaultM,
	output logic [`XLEN-1:0] 	InstrMisalignedAdrM,
	input logic 				ExceptionM, PendingInterruptM,
	// mmu management
	input logic [1:0] 			PrivilegeModeW,
	input logic [`XLEN-1:0] 	PTE,
	input logic [1:0] 			PageType,
	input logic [`XLEN-1:0] 	SATP_REGW,
	input logic 				STATUS_MXR, STATUS_SUM, STATUS_MPRV,
	input logic [1:0] 			STATUS_MPP,
	input logic 				ITLBWriteF, ITLBFlushF,
	output logic 				ITLBMissF, InstrDAPageFaultF,
	input 						var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
	input 						var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0], 
	output logic 				InstrAccessFaultF,
    output logic                ICacheAccess,
    output logic                ICacheMiss
);
  localparam                    CACHE_ENABLED = `IMEM == `MEM_CACHE;
  (* mark_debug = "true" *)  logic [`XLEN-1:0]            PCCorrectE, UnalignedPCNextF, PCNextF;
  logic                        BranchMisalignedFaultE;
  logic                        PrivilegedChangePCM;
  logic                        IllegalCompInstrD;
  logic [`XLEN-1:0]            PCPlus2or4F, PCLinkD;
  logic [`XLEN-3:0]            PCPlusUpperF;
  logic                        CompressedF;
  logic [31:0]                 InstrRawD, InstrRawF;
  logic [31:0]                 FinalInstrRawF;
  
  logic [31:0]                 InstrE;
  logic [`XLEN-1:0]            PCD;

  localparam [31:0]            nop = 32'h00000013; // instruction for NOP
  logic [31:0] NextInstrD, NextInstrE;

  logic [`XLEN-1:0] 		   PCBPWrongInvalidate;
  
(* mark_debug = "true" *)  logic [`PA_BITS-1:0]         PCPF; // used to either truncate or expand PCPF and PCNextF into `PA_BITS width.
  logic [`XLEN+1:0]            PCFExt;

  logic 					   CacheableF;
  logic [`XLEN-1:0]			   PCNextFSpill;
  logic [`XLEN-1:0] 		   PCFSpill;
  logic 					   SelNextSpillF;
  logic 					   ICacheFetchLine;
  logic 					   BusStall;
  logic 					   ICacheStallF, IFUCacheBusStallF;
  logic 					   CPUBusy;
(* mark_debug = "true" *)  logic [31:0] 				   PostSpillInstrRawF;
  // branch predictor signal
  logic [`XLEN-1:0]            PCNext1F, PCNext2F, PCNext0F;

  assign PCFExt = {2'b00, PCFSpill};

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Spill Support
  /////////////////////////////////////////////////////////////////////////////////////////////

  if(`C_SUPPORTED) begin : SpillSupport

    spillsupport #(CACHE_ENABLED) spillsupport(.clk, .reset, .StallF, .PCF, .PCPlusUpperF, .PCNextF, .InstrRawF,
      .InstrDAPageFaultF, .IFUCacheBusStallF, .ITLBMissF, .PCNextFSpill, .PCFSpill,
      .SelNextSpillF, .PostSpillInstrRawF, .CompressedF);
  end else begin : NoSpillSupport
    assign PCNextFSpill = PCNextF;
    assign PCFSpill = PCF;
    assign PostSpillInstrRawF = InstrRawF;
    assign {SelNextSpillF, CompressedF} = 0;
  end

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Memory management
  ////////////////////////////////////////////////////////////////////////////////////////////////

  if(`ZICSR_SUPPORTED == 1) begin : immu
    mmu #(.TLB_ENTRIES(`ITLB_ENTRIES), .IMMU(1))
    immu(.clk, .reset, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
         .PrivilegeModeW, .DisableTranslation(1'b0),
         .PAdr(PCFExt[`PA_BITS-1:0]),
         .VAdr(PCFSpill),
         .Size(2'b10),
         .PTE(PTE),
         .PageTypeWriteVal(PageType),
         .TLBWrite(ITLBWriteF),
         .TLBFlush(ITLBFlushF),
         .PhysicalAddress(PCPF),
         .TLBMiss(ITLBMissF),
         .Cacheable(CacheableF), .Idempotent(), .AtomicAllowed(),
         .InstrAccessFaultF, .LoadAccessFaultM(), .StoreAmoAccessFaultM(),
         .InstrPageFaultF, .LoadPageFaultM(), .StoreAmoPageFaultM(),
         .LoadMisalignedFaultM(), .StoreAmoMisalignedFaultM(),
         .DAPageFault(InstrDAPageFaultF),
         .AtomicAccessM(1'b0),.ExecuteAccessF(1'b1), .WriteAccessM(1'b0), .ReadAccessM(1'b0),
         .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW);

  end else begin
    assign {ITLBMissF, InstrAccessFaultF, InstrPageFaultF, InstrDAPageFaultF} = '0;
    assign PCPF = PCFExt[`PA_BITS-1:0];
    assign CacheableF = '1;
  end

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Memory 
  ////////////////////////////////////////////////////////////////////////////////////////////////

  logic [`XLEN-1:0] AllInstrRawF;
  assign InstrRawF = AllInstrRawF[31:0];

  
  if (`IMEM == `MEM_TIM) begin : irom // *** fix up dtim taking PA_BITS rather than XLEN, *** IEUAdr is a bad name.  Probably use a ROM rather than DTIM
    dtim irom(.clk, .reset, .CPUBusy, .LSURWM(2'b10), .IEUAdrM(PCPF[31:0]), .IEUAdrE(PCNextFSpill),
              .TrapM(1'b0), .FinalWriteDataM(), 
              .ReadDataWordM(AllInstrRawF), .BusStall, .LSUBusWrite(), .LSUBusRead(IFUBusRead),
              .BusCommittedM(), .ReadDataWordMuxM(), .DCacheStallM(ICacheStallF), 
              .DCacheCommittedM(), .DCacheMiss(ICacheMiss), .DCacheAccess(ICacheAccess));
    
  end else begin : bus
    localparam integer   WORDSPERLINE = (CACHE_ENABLED) ? `ICACHE_LINELENINBITS/`XLEN : 1;
    localparam integer   LINELEN = (CACHE_ENABLED) ? `ICACHE_LINELENINBITS : `XLEN;
    localparam integer   LOGWPL = (`DMEM == `MEM_CACHE) ? $clog2(WORDSPERLINE) : 1;
    logic [LINELEN-1:0]  ReadDataLine;
    logic [LINELEN-1:0]  ICacheBusWriteData;
    logic [`PA_BITS-1:0] ICacheBusAdr;
    logic                ICacheBusAck;
    logic                save,restore;
    logic [31:0]         temp;
    logic                SelUncachedAdr;
    
    busdp #(WORDSPERLINE, LINELEN, LOGWPL, CACHE_ENABLED) 
    busdp(.clk, .reset,
          .LSUBusHRDATA(IFUBusHRDATA), .LSUBusAck(IFUBusAck), .LSUBusWrite(), .LSUBusWriteCrit(),
          .LSUBusRead(IFUBusRead), .LSUBusSize(), 
          .LSUFunct3M(3'b010), .LSUBusAdr(IFUBusAdr), .DCacheBusAdr(ICacheBusAdr),
          .WordCount(), 
          .DCacheFetchLine(ICacheFetchLine),
          .DCacheWriteLine(1'b0), .DCacheBusAck(ICacheBusAck), 
          .DCacheBusWriteData(ICacheBusWriteData), .LSUPAdrM(PCPF),
          .FinalWriteDataM(), .SelUncachedAdr,
          .IgnoreRequest(ITLBMissF), .LSURWM(2'b10), .CPUBusy, .CacheableM(CacheableF),
          .BusStall, .BusCommittedM());

    mux2 #(32) UnCachedDataMux(.d0(FinalInstrRawF), .d1(ICacheBusWriteData[32-1:0]),
      .s(SelUncachedAdr), .y(AllInstrRawF[31:0]));
    

    if(CACHE_ENABLED) begin : icache
      cache #(.LINELEN(`ICACHE_LINELENINBITS),
              .NUMLINES(`ICACHE_WAYSIZEINBYTES*8/`ICACHE_LINELENINBITS),
              .NUMWAYS(`ICACHE_NUMWAYS), .DCACHE(0))
      icache(.clk, .reset, .CPUBusy, .IgnoreRequestTLB(ITLBMissF), .IgnoreRequestTrapM('0),
             .CacheBusWriteData(ICacheBusWriteData), .CacheBusAck(ICacheBusAck),
             .CacheBusAdr(ICacheBusAdr), .CacheStall(ICacheStallF), 
             .CacheFetchLine(ICacheFetchLine),
             .CacheWriteLine(), .ReadDataLine(ReadDataLine),
             .save, .restore, .Cacheable(CacheableF),
             .CacheMiss(ICacheMiss), .CacheAccess(ICacheAccess),
             .FinalWriteData('0),
             .RW(2'b10), 
             .Atomic('0), .FlushCache('0),
             .NextAdr(PCNextFSpill[11:0]),
             .PAdr(PCPF),
             .CacheCommitted(), .InvalidateCacheM(InvalidateICacheM));

      subcachelineread #(LINELEN, 32, 16) subcachelineread(
        .clk, .reset, .PAdr(PCPF), .save, .restore,
        .ReadDataLine, .ReadDataWord(FinalInstrRawF));

    end else begin : passthrough
      assign {ICacheFetchLine, ICacheBusAdr, ICacheStallF, FinalInstrRawF} = '0;
      assign ICacheAccess = CacheableF; assign ICacheMiss = CacheableF;
    end
  end  
  
  assign IFUCacheBusStallF = ICacheStallF | BusStall;
  assign IFUStallF = IFUCacheBusStallF | SelNextSpillF;
  assign CPUBusy = StallF & ~SelNextSpillF;
  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset, ~StallD, FlushD ? nop : PostSpillInstrRawF, nop, InstrRawD);

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // PCNextF logic
  ////////////////////////////////////////////////////////////////////////////////////////////////

  assign PrivilegedChangePCM = RetM | TrapM;

  mux2 #(`XLEN) pcmux1(.d0(PCNext0F), .d1(PCCorrectE), .s(BPPredWrongE), .y(PCNext1F));
  if(CACHE_ENABLED)
    mux2 #(`XLEN) pcmux2(.d0(PCNext1F), .d1(PCBPWrongInvalidate), .s(InvalidateICacheM), 
      .y(PCNext2F));
  else assign PCNext2F = PCNext1F;
  if(`ZICSR_SUPPORTED)
    mux2 #(`XLEN) pcmux3(.d0(PCNext2F), .d1(PrivilegedNextPCM), .s(PrivilegedChangePCM), 
      .y(UnalignedPCNextF));
  else assign UnalignedPCNextF = PCNext2F;

  assign  PCNextF = {UnalignedPCNextF[`XLEN-1:1], 1'b0}; // hart-SPEC p. 21 about 16-bit alignment
  flopenl #(`XLEN) pcreg(clk, reset, ~StallF, PCNextF, `RESET_VECTOR, PCF);

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Branch and Jump Predictor
  ////////////////////////////////////////////////////////////////////////////////////////////////
  if (`BPRED_ENABLED) begin : bpred
    logic                        BPPredWrongM;
    logic                        SelBPPredF;
    logic [`XLEN-1:0]            BPPredPCF;
    bpred bpred(.clk, .reset,
                .StallF, .StallD, .StallE, .StallM, 
                .FlushF, .FlushD, .FlushE, .FlushM,
                .InstrD, .PCNextF, .BPPredPCF, .SelBPPredF, .PCE, .PCSrcE, .IEUAdrE,
                .PCD, .PCLinkE, .InstrClassM, .BPPredWrongE, .BPPredWrongM, 
                .BPPredDirWrongM, .BTBPredPCWrongM, .RASPredPCWrongM, .BPPredClassNonCFIWrongM);

    mux2 #(`XLEN) pcmux0(.d0(PCPlus2or4F), .d1(BPPredPCF), .s(SelBPPredF), .y(PCNext0F));
    // Mux only required on instruction class miss prediction.
    mux2 #(`XLEN) pcmuxBPWrongInvalidateFlush(.d0(PCE), .d1(PCF), 
                                              .s(BPPredWrongM), .y(PCBPWrongInvalidate));
    mux2 #(`XLEN) pccorrectemux(.d0(PCLinkE), .d1(IEUAdrE), .s(PCSrcE), .y(PCCorrectE));
    
  end else begin : bpred
    assign BPPredWrongE = PCSrcE;
    assign {BPPredDirWrongM, BTBPredPCWrongM, RASPredPCWrongM, BPPredClassNonCFIWrongM} = '0;
    assign PCNext0F = PCPlus2or4F;
    assign PCCorrectE = IEUAdrE;
    assign PCBPWrongInvalidate = PCE;
  end      

  // pcadder
  // add 2 or 4 to the PC, based on whether the instruction is 16 bits or 32
  assign PCPlusUpperF = PCF[`XLEN-1:2] + 1; // add 4 to PC
  // choose PC+2 or PC+4 based on CompressedF, which arrives later. 
  // Speeds up critical path as compared to selecting adder input based on CompressedF
  always_comb
    if (CompressedF) // add 2
      if (PCF[1]) PCPlus2or4F = {PCPlusUpperF, 2'b00}; 
      else        PCPlus2or4F = {PCF[`XLEN-1:2], 2'b10};
    else          PCPlus2or4F = {PCPlusUpperF, PCF[1:0]}; // add 4

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Decode stage pipeline register and compressed instruction decoding.
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Decode stage pipeline register and logic
  flopenrc #(`XLEN) PCDReg(clk, reset, FlushD, ~StallD, PCF, PCD);
   
  // expand 16-bit compressed instructions to 32 bits
  decompress decomp(.InstrRawD, .InstrD, .IllegalCompInstrD);
  assign IllegalIEUInstrFaultD = IllegalBaseInstrFaultD | IllegalCompInstrD; // illegal if bad 32 or 16-bit instr

  // Misaligned PC logic
  // Instruction address misalignement only from br/jal(r) instructions.
  // instruction address misalignment is generated by the target of control flow instructions, not
  // the fetch itself.
  // xret and Traps both cannot produce instruction misaligned.
  // xret: mepc is an MXLEN-bit read/write register formatted as shown in Figure 3.21. 
  // The low bit of mepc (mepc[0]) is always zero. On implementations that support
  // only IALIGN=32, the two low bits (mepc[1:0]) are always zero.
  // Spec 3.1.14
  // Traps: Can’t happen.  The bottom two bits of MTVEC are ignored so the trap always is to a multiple of 4.  See 3.1.7 of the privileged spec.
  assign BranchMisalignedFaultE = (IEUAdrE[1] & ~`C_SUPPORTED) & PCSrcE;
  flopenr #(1) InstrMisalginedReg(clk, reset, ~StallM, BranchMisalignedFaultE, InstrMisalignedFaultM);
  flopenr #(`XLEN) InstrMisalignedAdrReg(clk, reset, ~StallM, PCNextF, InstrMisalignedAdrM);

  // Instruction and PC/PCLink pipeline registers
  mux2    #(32)    FlushInstrEMux(InstrD, nop, FlushE, NextInstrD);
  mux2    #(32)    FlushInstrMMux(InstrE, nop, FlushM, NextInstrE);
  flopenr #(32)    InstrEReg(clk, reset, ~StallE, NextInstrD, InstrE);
  flopenr #(32)    InstrMReg(clk, reset, ~StallM, NextInstrE, InstrM);
  flopenr #(`XLEN) PCEReg(clk, reset, ~StallE, PCD, PCE);
  flopenr #(`XLEN) PCMReg(clk, reset, ~StallM, PCE, PCM);
  flopenr #(`XLEN) PCPDReg(clk, reset, ~StallD, PCPlus2or4F, PCLinkD);
  flopenr #(`XLEN) PCPEReg(clk, reset, ~StallE, PCLinkD, PCLinkE);
endmodule

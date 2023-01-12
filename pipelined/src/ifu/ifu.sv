///////////////////////////////////////////
// ifu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified:
//
// Purpose: Instrunction Fetch Unit
//           PC, branch prediction, instruction cache
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module ifu (
	input logic 				clk, reset,
	input logic 				StallF, StallD, StallE, StallM, StallW,
	input logic 				FlushD, FlushE, FlushM, FlushW, 
	// Bus interface
(* mark_debug = "true" *)	input logic [`XLEN-1:0] 	HRDATA,
(* mark_debug = "true" *)	output logic [`PA_BITS-1:0] IFUHADDR,
(* mark_debug = "true" *)	output logic 				IFUStallF,
(* mark_debug = "true" *) output logic [2:0]  IFUHBURST,
(* mark_debug = "true" *) output logic [1:0]  IFUHTRANS,
(* mark_debug = "true" *) output logic [2:0]  IFUHSIZE,
(* mark_debug = "true" *) output logic  IFUHWRITE,
(* mark_debug = "true" *) input logic   IFUHREADY,
	(* mark_debug = "true" *) output logic [`XLEN-1:0] PCF, 
	// Execute
	output logic [`XLEN-1:0] 	PCLinkE,
	input logic 				PCSrcE, 
	input logic [`XLEN-1:0] 	IEUAdrE,
	output logic [`XLEN-1:0] 	PCE,
	output logic 				BPPredWrongE, 
	// Mem
    output logic                CommittedF, 
	input logic [`XLEN-1:0] 	UnalignedPCNextF,
    output logic [`XLEN-1:0]    PCNext2F,
	input logic         	    CSRWriteFenceM,
    input logic                 InvalidateICacheM,
	output logic [31:0] 		InstrD, InstrM, 
	output logic [`XLEN-1:0] 	PCM, 
	// branch predictor
	output logic [4:0] 			InstrClassM,
	output logic 				DirPredictionWrongM,
	output logic 				BTBPredPCWrongM,
	output logic 				RASPredPCWrongM,
	output logic 				PredictionInstrClassWrongM,
	// Faults
	input logic 				IllegalBaseInstrFaultD,
	output logic 				InstrPageFaultF,
	output logic 				IllegalIEUInstrFaultD,
	output logic 				InstrMisalignedFaultM,
	// mmu management
	input logic [1:0] 			PrivilegeModeW,
	input logic [`XLEN-1:0] 	PTE,
	input logic [1:0] 			PageType,
	input logic [`XLEN-1:0] 	SATP_REGW,
	input logic 				STATUS_MXR, STATUS_SUM, STATUS_MPRV,
	input logic [1:0] 			STATUS_MPP,
	input logic 				ITLBWriteF, sfencevmaM,
	output logic 				ITLBMissF, InstrDAPageFaultF,
	input 						var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
	input 						var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0], 
	output logic 				InstrAccessFaultF,
    output logic                ICacheAccess,
    output logic                ICacheMiss
);
  (* mark_debug = "true" *)  logic [`XLEN-1:0]            PCNextF;
  logic                        BranchMisalignedFaultE;
  logic [`XLEN-1:0]            PCPlus2or4F, PCLinkD;
  logic [`XLEN-1:2]            PCPlus4F;
  logic                        CompressedF;
  logic [31:0]                 InstrRawD, InstrRawF, IROMInstrF, ICacheInstrF;
  logic [31:0]                 FinalInstrRawF;
  logic [1:0]                  IFURWF;
  
  logic [31:0]                 InstrE;
  logic [`XLEN-1:0]            PCD;

  localparam [31:0]            nop = 32'h00000013; // instruction for NOP
  logic [31:0] NextInstrD, NextInstrE;

  logic [`XLEN-1:0] 		   NextValidPCE;
  
(* mark_debug = "true" *)  logic [`PA_BITS-1:0]         PCPF; // used to either truncate or expand PCPF and PCNextF into `PA_BITS width.
  logic [`XLEN+1:0]            PCFExt;

  logic 					   CacheableF;
  logic [`XLEN-1:0]			   PCNextFSpill;
  logic [`XLEN-1:0] 		   PCFSpill;
  logic 					   SelNextSpillF;
  logic 					   ICacheFetchLine;
  logic 					   BusStall;
  logic 					   ICacheStallF, IFUCacheBusStallD;
  logic 					   GatedStallD;
(* mark_debug = "true" *)  logic [31:0] 				   PostSpillInstrRawF;
  // branch predictor signal
  logic [`XLEN-1:0]            PCNext1F, PCNext0F;
  logic                        BusCommittedF, CacheCommittedF;
  logic                        SelIROM;
  
  assign PCFExt = {2'b00, PCFSpill};

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Spill Support
  /////////////////////////////////////////////////////////////////////////////////////////////

  if(`C_SUPPORTED) begin : SpillSupport
    spillsupport #(`ICACHE) spillsupport(.clk, .reset, .StallF, .Flush(FlushD), .PCF, .PCPlus4F, .PCNextF, .InstrRawF(InstrRawF),
      .InstrDAPageFaultF, .IFUCacheBusStallD, .ITLBMissF, .PCNextFSpill, .PCFSpill,
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
    ///////////////////////////////////////////
    // sfence.vma causes TLB flushes
    ///////////////////////////////////////////
    // sets ITLBFlush to pulse for one cycle of the sfence.vma instruction
    // In this instr we want to flush the tlb and then do a pagetable walk to update the itlb and continue the program.
    // But we're still in the stalled sfence instruction, so if itlbflushf == sfencevmaM, tlbflush would never drop and 
    // the tlbwrite would never take place after the pagetable walk. by adding in ~StallMQ, we are able to drop itlbflush 
    // after a cycle AND pulse it for another cycle on any further back-to-back sfences. 
    logic StallMQ, TLBFlush;
    flopr #(1) StallMReg(.clk, .reset, .d(StallM), .q(StallMQ));
    assign TLBFlush = sfencevmaM & ~StallMQ;

    mmu #(.TLB_ENTRIES(`ITLB_ENTRIES), .IMMU(1))
    immu(.clk, .reset, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
         .PrivilegeModeW, .DisableTranslation(1'b0),
         .VAdr(PCFExt),
         .Size(2'b10),
         .PTE(PTE),
         .PageTypeWriteVal(PageType),
         .TLBWrite(ITLBWriteF),
         .TLBFlush,
         .PhysicalAddress(PCPF),
         .TLBMiss(ITLBMissF),
         .Cacheable(CacheableF), .Idempotent(), .SelTIM(SelIROM),
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
    assign SelIROM = '0;
  end

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Memory 
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // CommittedM tells the CPU's privileged unit the current instruction
  // in the memory stage is a memory operaton and that memory operation is either completed
  // or is partially executed. Partially completed memory operations need to prevent an interrupts.
  // There is not a clean way to restore back to a partial executed instruction.  CommiteedM will
  // delay the interrupt until the LSU is in a clean state.
  assign CommittedF = CacheCommittedF | BusCommittedF;

  logic 			   IgnoreRequest;
  assign IgnoreRequest = ITLBMissF | FlushD;

  // The IROM uses untranslated addresses, so it is not compatible with virtual memory.
  if (`IROM_SUPPORTED) begin : irom 
    assign IFURWF = 2'b10;
    irom irom(.clk, .ce(~GatedStallD | reset), .Adr(PCNextFSpill[`XLEN-1:0]), .ReadData(IROMInstrF));
  end else begin
    assign IFURWF = 2'b10;
  end
  if (`BUS) begin : bus
    // **** must fix words per line vs beats per line as in lsu.
    localparam integer   WORDSPERLINE = `ICACHE ? `ICACHE_LINELENINBITS/`XLEN : 1;
    localparam integer   LOGBWPL = `ICACHE ? $clog2(WORDSPERLINE) : 1;
    if(`ICACHE) begin : icache
      localparam integer   LINELEN = `ICACHE ? `ICACHE_LINELENINBITS : `XLEN;
      logic [LINELEN-1:0]  FetchBuffer;
      logic [`PA_BITS-1:0] ICacheBusAdr;
      logic                ICacheBusAck;
      logic [1:0]          CacheBusRW, BusRW, CacheRWF;
      
      //assign BusRW = IFURWF & ~{IgnoreRequest, IgnoreRequest} & ~{CacheableF, CacheableF} & ~{SelIROM, SelIROM};
      assign BusRW = ~ITLBMissF & ~CacheableF & ~SelIROM ? IFURWF : '0;
      assign CacheRWF = ~ITLBMissF & CacheableF & ~SelIROM ? IFURWF : '0;
      cache #(.LINELEN(`ICACHE_LINELENINBITS),
              .NUMLINES(`ICACHE_WAYSIZEINBYTES*8/`ICACHE_LINELENINBITS),
              .NUMWAYS(`ICACHE_NUMWAYS), .LOGBWPL(LOGBWPL), .WORDLEN(32), .MUXINTERVAL(16), .DCACHE(0))
      icache(.clk, .reset, .FlushStage(FlushD), .Stall(GatedStallD),
             .FetchBuffer, .CacheBusAck(ICacheBusAck),
             .CacheBusAdr(ICacheBusAdr), .CacheStall(ICacheStallF), 
             .CacheBusRW,
             .ReadDataWord(ICacheInstrF),
             .SelHPTW('0),
             .CacheMiss(ICacheMiss), .CacheAccess(ICacheAccess),
             .ByteMask('0), .BeatCount('0), .SelBusBeat('0),
             .CacheWriteData('0),
             .CacheRW(CacheRWF), 
             .CacheAtomic('0), .FlushCache('0),
             .NextAdr(PCNextFSpill[11:0]),
             .PAdr(PCPF),
             .CacheCommitted(CacheCommittedF), .InvalidateCache(InvalidateICacheM));
      ahbcacheinterface #(WORDSPERLINE, LINELEN, LOGBWPL, `ICACHE) 
      ahbcacheinterface(.HCLK(clk), .HRESETn(~reset),
            .HRDATA,
            .Flush(FlushD), .CacheBusRW, .HSIZE(IFUHSIZE), .HBURST(IFUHBURST), .HTRANS(IFUHTRANS), .HWSTRB(),
            .Funct3(3'b010), .HADDR(IFUHADDR), .HREADY(IFUHREADY), .HWRITE(IFUHWRITE), .CacheBusAdr(ICacheBusAdr),
            .BeatCount(), .Cacheable(CacheableF), .SelBusBeat(), .WriteDataM('0),
             .CacheBusAck(ICacheBusAck), .HWDATA(), .CacheableOrFlushCacheM(1'b0), .CacheReadDataWordM('0),
            .FetchBuffer, .PAdr(PCPF),
            .BusRW, .Stall(GatedStallD),
            .BusStall, .BusCommitted(BusCommittedF));

      mux3 #(32) UnCachedDataMux(.d0(ICacheInstrF), .d1(FetchBuffer[32-1:0]), .d2(IROMInstrF),
                                 .s({SelIROM, ~CacheableF}), .y(InstrRawF[31:0]));
    end else begin : passthrough
      assign IFUHADDR = PCPF;
      logic [31:0]  FetchBuffer;
      logic [1:0] BusRW;
      assign BusRW = ~ITLBMissF & ~SelIROM ? IFURWF : '0;
      assign IFUHSIZE = 3'b010;

      ahbinterface #(0) ahbinterface(.HCLK(clk), .Flush(FlushD), .HRESETn(~reset), .HREADY(IFUHREADY), 
        .HRDATA(HRDATA), .HTRANS(IFUHTRANS), .HWRITE(IFUHWRITE), .HWDATA(),
        .HWSTRB(), .BusRW, .ByteMask(), .WriteData('0),
        .Stall(GatedStallD), .BusStall, .BusCommitted(BusCommittedF), .FetchBuffer(FetchBuffer));

      assign CacheCommittedF = '0;
      if(`IROM_SUPPORTED) mux2 #(32) UnCachedDataMux2(FetchBuffer, IROMInstrF, SelIROM, InstrRawF);
      else assign InstrRawF = FetchBuffer;
      assign IFUHBURST = 3'b0;
      assign {ICacheFetchLine, ICacheStallF, FinalInstrRawF} = '0;
      assign {ICacheMiss, ICacheAccess} = '0;
    end
  end else begin : nobus // block: bus
    assign {BusStall, CacheCommittedF} = '0;   
    assign {ICacheStallF, ICacheMiss, ICacheAccess} = '0;
    assign InstrRawF = IROMInstrF;
  end
  
  assign IFUCacheBusStallD = ICacheStallF | BusStall;
  assign IFUStallF = IFUCacheBusStallD | SelNextSpillF;
  assign GatedStallD = StallD & ~SelNextSpillF;
  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset | FlushD, ~StallD, PostSpillInstrRawF, nop, InstrRawD);

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // PCNextF logic
  ////////////////////////////////////////////////////////////////////////////////////////////////

  if(`ZICSR_SUPPORTED | `ZIFENCEI_SUPPORTED)
    mux2 #(`XLEN) pcmux2(.d0(PCNext1F), .d1(NextValidPCE), .s(CSRWriteFenceM),.y(PCNext2F));
  else assign PCNext2F = PCNext1F;

  assign  PCNextF = {UnalignedPCNextF[`XLEN-1:1], 1'b0}; // hart-SPEC p. 21 about 16-bit alignment
  flopenl #(`XLEN) pcreg(clk, reset, ~StallF, PCNextF, `RESET_VECTOR, PCF);

  // pcadder
  // add 2 or 4 to the PC, based on whether the instruction is 16 bits or 32
  assign PCPlus4F = PCF[`XLEN-1:2] + 1; // add 4 to PC
  // choose PC+2 or PC+4 based on CompressedF, which arrives later. 
  // Speeds up critical path as compared to selecting adder input based on CompressedF
  // *** consider gating PCPlus4F to provide the reset.
/* -----\/----- EXCLUDED -----\/-----
  assign PCPlus2or4F[0] = '0;
  assign PCPlus2or4F[1] = ~reset & (CompressedF ^ PCF[1]);
  assign PCPlus2or4F[`XLEN-1:2] = reset ? '0 : CompressedF & ~PCF[1] ? PCF[`XLEN-1:2] : PCPlus4F;
 -----/\----- EXCLUDED -----/\----- */
/* -----\/----- EXCLUDED -----\/-----
  assign PCPlus2or4F[1:0] = reset ? 2'b00 : CompressedF ? PCF[1] ? 2'b00 : 2'b10 : PCF[1:0];
 -----/\----- EXCLUDED -----/\----- */

  // *** There is actually a bug in the regression test.  We fetched an address which returns data with
  // an X.  This version of the code does not die because if CompressedF is an X it just defaults to the last
  // option.  The above code would work, but propagates the x.
  always_comb
    if(reset) PCPlus2or4F = '0;
    else if (CompressedF) // add 2
      if (PCF[1]) PCPlus2or4F = {PCPlus4F, 2'b00}; 
      else        PCPlus2or4F = {PCF[`XLEN-1:2], 2'b10};
    else          PCPlus2or4F = {PCPlus4F, PCF[1:0]}; // add 4


  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Branch and Jump Predictor
  ////////////////////////////////////////////////////////////////////////////////////////////////
  if (`BPRED_ENABLED) begin : bpred
    bpred bpred(.clk, .reset,
                .StallF, .StallD, .StallE, .StallM, .StallW,
                .FlushD, .FlushE, .FlushM, .FlushW,
                .InstrD, .PCNextF, .PCPlus2or4F, .PCNext1F, .PCE, .PCM, .PCSrcE, .IEUAdrE, .PCF, .NextValidPCE,
                .PCD, .PCLinkE, .InstrClassM, .BPPredWrongE,
                .DirPredictionWrongM, .BTBPredPCWrongM, .RASPredPCWrongM, .PredictionInstrClassWrongM);

  end else begin : bpred
    mux2 #(`XLEN) pcmux1(.d0(PCPlus2or4F), .d1(IEUAdrE), .s(PCSrcE), .y(PCNext1F));    
    assign BPPredWrongE = PCSrcE;
    assign {InstrClassM, DirPredictionWrongM, BTBPredPCWrongM, RASPredPCWrongM, PredictionInstrClassWrongM} = '0;
    assign PCNext0F = PCPlus2or4F;
    assign NextValidPCE = PCE;
  end      


  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Decode stage pipeline register and compressed instruction decoding.
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Decode stage pipeline register and logic
  flopenrc #(`XLEN) PCDReg(clk, reset, FlushD, ~StallD, PCF, PCD);
   
  // expand 16-bit compressed instructions to 32 bits
  if (`C_SUPPORTED) begin
    logic IllegalCompInstrD;
    decompress decomp(.InstrRawD, .InstrD, .IllegalCompInstrD); 
    assign IllegalIEUInstrFaultD = IllegalBaseInstrFaultD | IllegalCompInstrD; // illegal if bad 32 or 16-bit instr
  end else begin  
    assign InstrD = InstrRawD;
    assign IllegalIEUInstrFaultD = IllegalBaseInstrFaultD;
  end

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

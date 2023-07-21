///////////////////////////////////////////
// ifu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified:
//
// Purpose: Instruction Fetch Unit
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

module ifu import cvw::*;  #(parameter cvw_t P) (
  input  logic                 clk, reset,
  input  logic                 StallF, StallD, StallE, StallM, StallW,
  input  logic                 FlushD, FlushE, FlushM, FlushW, 
  output logic                 IFUStallF,                                // IFU stalsl pipeline during a multicycle operation
  // Command from CPU
  input  logic                 InvalidateICacheM,                        // Clears all instruction cache valid bits
  input  logic                 CSRWriteFenceM,                           // CSR write or fence instruction, PCNextF = the next valid PC (typically PCE)
  input  logic                 InstrValidD, InstrValidE, InstrValidM,
  input  logic                 BranchD, BranchE,
  input  logic                 JumpD, JumpE,
  // Bus interface
  output logic [P.PA_BITS-1:0] IFUHADDR,                                 // Bus address from IFU to EBU
  input  logic [P.XLEN-1:0]    HRDATA,                                   // Bus read data from IFU to EBU
  input  logic                 IFUHREADY,                                // Bus ready from IFU to EBU
  output logic                 IFUHWRITE,                                // Bus write operation from IFU to EBU
  output logic [2:0]           IFUHSIZE,                                 // Bus operation size from IFU to EBU
  output logic [2:0]           IFUHBURST,                                // Bus burst from IFU to EBU
  output logic [1:0]           IFUHTRANS,                                // Bus transaction type from IFU to EBU

  output logic [P.XLEN-1:0]    PCSpillF,                                 // PCF with possible + 2 to handle spill to HPTW
  // Execute
  output logic [P.XLEN-1:0]    PCLinkE,                                  // The address following the branch instruction. (AKA Fall through address)
  input  logic                 PCSrcE,                                   // Executation stage branch is taken
  input  logic [P.XLEN-1:0]    IEUAdrE,                                  // The branch/jump target address
  input  logic [P.XLEN-1:0]    IEUAdrM,                                  // The branch/jump target address
  output logic [P.XLEN-1:0]    PCE,                                      // Execution stage instruction address
  output logic                 BPWrongE,                                 // Prediction is wrong
  output logic                 BPWrongM,                                 // Prediction is wrong
  // Mem
  output logic                 CommittedF,                               // I$ or bus memory operation started, delay interrupts
  input  logic [P.XLEN-1:0]    UnalignedPCNextF,                         // The next PCF, but not aligned to 2 bytes. 
  output logic [P.XLEN-1:0]    PC2NextF,                                 // Selected PC between branch prediction and next valid PC if CSRWriteFence
  output logic [31:0]          InstrD,                                   // The decoded instruction in Decode stage
  output logic [31:0]          InstrM,                                   // The decoded instruction in Memory stage
  output logic [31:0]          InstrOrigM,                               // Original compressed or uncompressed instruction in Memory stage for Illegal Instruction MTVAL
  output logic [P.XLEN-1:0]    PCM,                                      // Memory stage instruction address
  // branch predictor
  output logic [3:0]           InstrClassM,                              // The valid instruction class. 1-hot encoded as jalr, ret, jr (not ret), j, br
  output logic                 BPDirPredWrongM,                          // Prediction direction is wrong
  output logic                 BTAWrongM,                                // Prediction target wrong
  output logic                 RASPredPCWrongM,                          // RAS prediction is wrong
  output logic                 IClassWrongM,                             // Class prediction is wrong
  output logic                 ICacheStallF,                             // I$ busy with multicycle operation
  // Faults
  input logic                  IllegalBaseInstrD,                        // Illegal non-compressed instruction
  input logic                  IllegalFPUInstrD,                         // Illegal FP instruction
  output logic                 InstrPageFaultF,                          // Instruction page fault 
  output logic                 IllegalIEUFPUInstrD,                      // Illegal instruction including compressed & FP
  output logic                 InstrMisalignedFaultM,                    // Branch target not aligned to 4 bytes if no compressed allowed (2 bytes if allowed)
  // mmu management
  input logic [1:0]            PrivilegeModeW,                           // Priviledge mode in Writeback stage
  input logic [P.XLEN-1:0]     PTE,                                      // Hardware page table walker (HPTW) writes Page table entry (PTE) to ITLB
  input logic [1:0]            PageType,                                 // Hardware page table walker (HPTW) writes PageType to ITLB
  input logic                  ITLBWriteF,                               // Writes PTE and PageType to ITLB
  input logic [P.XLEN-1:0]     SATP_REGW,                                // Location of the root page table and page table configuration
  input logic                  STATUS_MXR,                               // Status CSR: make executable page readable 
  input logic                  STATUS_SUM,                               // Status CSR: Supervisor access to user memory
  input logic                  STATUS_MPRV,                              // Status CSR: modify machine privilege
  input logic [1:0]            STATUS_MPP,                               // Status CSR: previous machine privilege level
  input logic                  sfencevmaM,                               // Virtual memory address fence, invalidate TLB entries
  output logic                 ITLBMissF,                                // ITLB miss causes HPTW (hardware pagetable walker) walk
  output logic                 InstrUpdateDAF,                           // ITLB hit needs to update dirty or access bits
  input  var logic [7:0]       PMPCFG_ARRAY_REGW[P.PMP_ENTRIES-1:0],     // PMP configuration from privileged unit
  input  var logic [P.PA_BITS-3:0] PMPADDR_ARRAY_REGW[P.PMP_ENTRIES-1:0],// PMP address from privileged unit
  output logic                 InstrAccessFaultF,                        // Instruction access fault 
  output logic                 ICacheAccess,                             // Report I$ read to performance counters
  output logic                 ICacheMiss                                // Report I$ miss to performance counters
);

  localparam [31:0]            nop = 32'h00000013;                       // instruction for NOP

  logic [P.XLEN-1:0]           PCNextF;                                  // Next PCF, selected from Branch predictor, Privilege, or PC+2/4
  logic                        BranchMisalignedFaultE;                   // Branch target not aligned to 4 bytes if no compressed allowed (2 bytes if allowed)
  logic [P.XLEN-1:0]           PCPlus2or4F;                              // PCF + 2 (CompressedF) or PCF + 4 (Non-compressed)
  logic [P.XLEN-1:0]           PCSpillNextF;                             // Next PCF after possible + 2 to handle spill
  logic [P.XLEN-1:0]           PCLinkD;                                  // PCF2or4F delayed 1 cycle.  This is next PC after a control flow instruction (br or j)
  logic [P.XLEN-1:2]           PCPlus4F;                                 // PCPlus4F is always PCF + 4.  Fancy way to compute PCPlus2or4F
  logic [P.XLEN-1:0]           PCD;                                      // Decode stage instruction address
  logic [P.XLEN-1:0]           NextValidPCE;                             // The PC of the next valid instruction in the pipeline after  csr write or fence
  logic [P.XLEN-1:0]           PCF;                                      // Fetch stage instruction address
  logic [P.PA_BITS-1:0]        PCPF;                                     // Physical address after address translation
  logic [P.XLEN+1:0]           PCFExt;                                

  logic [31:0]                 IROMInstrF;                               // Instruction from the IROM
  logic [31:0]                 ICacheInstrF;                             // Instruction from the I$
  logic [31:0]                 InstrRawF;                                // Instruction from the IROM, I$, or bus
  logic                        CompressedF;                              // The fetched instruction is compressed
  logic                        CompressedD;                              // The decoded instruction is compressed
  logic                        CompressedE;                              // The execution instruction is compressed
  logic                        CompressedM;                              // The execution instruction is compressed
  logic [31:0]                 PostSpillInstrRawF;                       // Fetch instruction after merge two halves of spill
  logic [31:0]                 InstrRawD;                                // Non-decompressed instruction in the Decode stage
  logic                        IllegalIEUInstrD;                         // IEU Instruction (regular or compressed) is not good
  
  logic [1:0]                  IFURWF;                                   // IFU alreays read IFURWF = 10
  logic [31:0]                 InstrE;                                   // Instruction in the Execution stage
  logic [31:0]                 NextInstrD, NextInstrE;                   // Instruction into the next stage after possible stage flush

  logic                        CacheableF;                               // PMA indicates instruction address is cacheable
  logic                        SelSpillNextF;                            // In a spill, stall pipeline and gate local stallF
  logic                        BusStall;                                 // Bus interface busy with multicycle operation
  logic                        IFUCacheBusStallF;                        // EIther I$ or bus busy with multicycle operation
  logic                        GatedStallD;                              // StallD gated by selected next spill
  // branch predictor signal
  logic [P.XLEN-1:0]           PC1NextF;                                 // Branch predictor next PCF
  logic                        BusCommittedF;                            // Bus memory operation in flight, delay interrupts
  logic                        CacheCommittedF;                          // I$ memory operation started, delay interrupts
  logic                        SelIROM;                                  // PMA indicates instruction address is in the IROM
  logic [15:0]                 InstrRawE, InstrRawM;
  
  assign PCFExt = {2'b00, PCSpillF};

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Spill Support
  /////////////////////////////////////////////////////////////////////////////////////////////

  if(P.C_SUPPORTED) begin : Spill
    spill #(P) spill(.clk, .reset, .StallD, .FlushD, .PCF, .PCPlus4F, .PCNextF, .InstrRawF,
      .InstrUpdateDAF, .IFUCacheBusStallF, .ITLBMissF, .PCSpillNextF, .PCSpillF, .SelSpillNextF, .PostSpillInstrRawF, .CompressedF);
  end else begin : NoSpill
    assign PCSpillNextF = PCNextF;
    assign PCSpillF = PCF;
    assign PostSpillInstrRawF = InstrRawF;
    assign {SelSpillNextF, CompressedF} = 0;
  end

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Memory management
  ////////////////////////////////////////////////////////////////////////////////////////////////

  if(P.ZICSR_SUPPORTED == 1) begin : immu
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

    mmu #(.P(P), .TLB_ENTRIES(P.ITLB_ENTRIES), .IMMU(1))
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
         .UpdateDA(InstrUpdateDAF),
         .AtomicAccessM(1'b0),.ExecuteAccessF(1'b1), .WriteAccessM(1'b0), .ReadAccessM(1'b0),
         .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW);

  end else begin
    assign {ITLBMissF, InstrAccessFaultF, InstrPageFaultF, InstrUpdateDAF} = '0;
    assign PCPF = PCFExt[P.PA_BITS-1:0];
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

  logic  IgnoreRequest;
  assign IgnoreRequest = ITLBMissF | FlushD;

  // The IROM uses untranslated addresses, so it is not compatible with virtual memory.
  if (P.IROM_SUPPORTED) begin : irom
  logic IROMce;
  assign IROMce = ~GatedStallD | reset;
    assign IFURWF = 2'b10;
    irom #(P) irom(.clk, .ce(IROMce), .Adr(PCSpillNextF[P.XLEN-1:0]), .IROMInstrF);
  end else begin
    assign IFURWF = 2'b10;
  end
  if (P.BUS_SUPPORTED) begin : bus
    // **** must fix words per line vs beats per line as in lsu.
    localparam   WORDSPERLINE = P.ICACHE_SUPPORTED ? P.ICACHE_LINELENINBITS/P.XLEN : 1;
    localparam   LOGBWPL = P.ICACHE_SUPPORTED ? $clog2(WORDSPERLINE) : 1;
    if(P.ICACHE_SUPPORTED) begin : icache
      localparam            LINELEN = P.ICACHE_SUPPORTED ? P.ICACHE_LINELENINBITS : P.XLEN;
      localparam            LLENPOVERAHBW = P.LLEN / P.AHBW; // Number of AHB beats in a LLEN word. AHBW cannot be larger than LLEN. (implementation limitation)
      logic [LINELEN-1:0]   FetchBuffer;
      logic [P.PA_BITS-1:0] ICacheBusAdr;
      logic                 ICacheBusAck;
      logic [1:0]           CacheBusRW, BusRW, CacheRWF;
      logic [1:0]           CacheBusRWTemp;
      
      assign BusRW = ~ITLBMissF & ~CacheableF & ~SelIROM ? IFURWF : '0;
      assign CacheRWF = ~ITLBMissF & CacheableF & ~SelIROM ? IFURWF : '0;
      cache #(.P(P), .PA_BITS(P.PA_BITS), .XLEN(P.XLEN), .LINELEN(P.ICACHE_LINELENINBITS),
              .NUMLINES(P.ICACHE_WAYSIZEINBYTES*8/P.ICACHE_LINELENINBITS),
              .NUMWAYS(P.ICACHE_NUMWAYS), .LOGBWPL(LOGBWPL), .WORDLEN(32), .MUXINTERVAL(16), .READ_ONLY_CACHE(1))
      icache(.clk, .reset, .FlushStage(FlushD), .IgnoreRequestTLB(1'b0), .Stall(GatedStallD),
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
             .NextSet(PCSpillNextF[11:0]),
             .PAdr(PCPF),
             .CacheCommitted(CacheCommittedF), .InvalidateCache(InvalidateICacheM));

      ahbcacheinterface #(P.AHBW, P.LLEN, P.PA_BITS, WORDSPERLINE, LOGBWPL, LINELEN, LLENPOVERAHBW, 1) 
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

      ahbinterface #(P.XLEN, 0) ahbinterface(.HCLK(clk), .Flush(FlushD), .HRESETn(~reset), .HREADY(IFUHREADY), 
        .HRDATA(HRDATA), .HTRANS(IFUHTRANS), .HWRITE(IFUHWRITE), .HWDATA(),
        .HWSTRB(), .BusRW, .ByteMask(), .WriteData('0),
        .Stall(GatedStallD), .BusStall, .BusCommitted(BusCommittedF), .FetchBuffer(FetchBuffer));

      assign CacheCommittedF = '0;
      if(P.IROM_SUPPORTED) mux2 #(32) UnCachedDataMux2(FetchBuffer, IROMInstrF, SelIROM, InstrRawF);
      else assign InstrRawF = FetchBuffer;
      assign IFUHBURST = 3'b0;
      assign {ICacheMiss, ICacheAccess, ICacheStallF} = '0;
    end
  end else begin : nobus // block: bus
    assign {BusStall, CacheCommittedF} = '0;   
    assign {ICacheStallF, ICacheMiss, ICacheAccess} = '0;
    assign InstrRawF = IROMInstrF;
  end
  
  assign IFUCacheBusStallF = ICacheStallF | BusStall;
  assign IFUStallF = IFUCacheBusStallF | SelSpillNextF;
  assign GatedStallD = StallD & ~SelSpillNextF;
  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset | FlushD, ~StallD, PostSpillInstrRawF, nop, InstrRawD);

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // PCNextF logic
  ////////////////////////////////////////////////////////////////////////////////////////////////

  if(P.ZICSR_SUPPORTED | P.ZIFENCEI_SUPPORTED)
    mux2 #(P.XLEN) pcmux2(.d0(PC1NextF), .d1(NextValidPCE), .s(CSRWriteFenceM),.y(PC2NextF));
  else assign PC2NextF = PC1NextF;

  assign  PCNextF = {UnalignedPCNextF[P.XLEN-1:1], 1'b0}; // hart-SPEC p. 21 about 16-bit alignment
  flopenl #(P.XLEN) pcreg(clk, reset, ~StallF, PCNextF, P.RESET_VECTOR[P.XLEN-1:0], PCF);

  // pcadder
  // add 2 or 4 to the PC, based on whether the instruction is 16 bits or 32
  // *** consider using PCPlus2or4F = PCF + CompressedF ? 2 : 4;
  assign PCPlus4F = PCF[P.XLEN-1:2] + 1; // add 4 to PC
  // choose PC+2 or PC+4 based on CompressedF, which arrives later. 
  // Speeds up critical path as compared to selecting adder input based on CompressedF
  // *** consider gating PCPlus4F to provide the reset.

  // *** There is actually a bug in the regression test.  We fetched an address which returns data with
  // an X.  This version of the code does not die because if CompressedF is an X it just defaults to the last
  // option.  The above code would work, but propagates the x.
  always_comb
    if(reset) PCPlus2or4F = '0;
    else if (CompressedF) // add 2
      if (PCF[1]) PCPlus2or4F = {PCPlus4F, 2'b00}; 
      else        PCPlus2or4F = {PCF[P.XLEN-1:2], 2'b10};
    else          PCPlus2or4F = {PCPlus4F, PCF[1:0]}; // add 4

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Branch and Jump Predictor
  ////////////////////////////////////////////////////////////////////////////////////////////////
  if (P.BPRED_SUPPORTED) begin : bpred
    bpred #(P) bpred(.clk, .reset,
                .StallF, .StallD, .StallE, .StallM, .StallW,
                .FlushD, .FlushE, .FlushM, .FlushW, .InstrValidD, .InstrValidE, 
                .BranchD, .BranchE, .JumpD, .JumpE,
                .InstrD, .PCNextF, .PCPlus2or4F, .PC1NextF, .PCE, .PCM, .PCSrcE, .IEUAdrE, .IEUAdrM, .PCF, .NextValidPCE,
                .PCD, .PCLinkE, .InstrClassM, .BPWrongE, .PostSpillInstrRawF, .BPWrongM,
                .BPDirPredWrongM, .BTAWrongM, .RASPredPCWrongM, .IClassWrongM);

  end else begin : bpred
    mux2 #(P.XLEN) pcmux1(.d0(PCPlus2or4F), .d1(IEUAdrE), .s(PCSrcE), .y(PC1NextF));    
    assign BPWrongE = PCSrcE;
    assign {InstrClassM, BPDirPredWrongM, BTAWrongM, RASPredPCWrongM, IClassWrongM} = '0;
    assign NextValidPCE = PCE;
  end      

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Decode stage pipeline register and compressed instruction decoding.
  ////////////////////////////////////////////////////////////////////////////////////////////////
  
  // Decode stage pipeline register and logic
  flopenrc #(P.XLEN) PCDReg(clk, reset, FlushD, ~StallD, PCF, PCD);
   
  // expand 16-bit compressed instructions to 32 bits
  if (P.C_SUPPORTED) begin
    logic IllegalCompInstrD;
    decompress #(P.XLEN) decomp(.InstrRawD, .InstrD, .IllegalCompInstrD); 
    assign IllegalIEUInstrD = IllegalBaseInstrD | IllegalCompInstrD; // illegal if bad 32 or 16-bit instr
  end else begin  
    assign InstrD = InstrRawD;
    assign IllegalIEUInstrD = IllegalBaseInstrD;
  end
  assign IllegalIEUFPUInstrD = IllegalIEUInstrD & IllegalFPUInstrD;

  // Misaligned PC logic
  // Instruction address misalignment only from br/jal(r) instructions.
  // instruction address misalignment is generated by the target of control flow instructions, not
  // the fetch itself.
  // xret and Traps both cannot produce instruction misaligned.
  // xret: mepc is an MXLEN-bit read/write register formatted as shown in Figure 3.21. 
  // The low bit of mepc (mepc[0]) is always zero. On implementations that support
  // only IALIGN=32, the two low bits (mepc[1:0]) are always zero.
  // Spec 3.1.14
  // Traps: Can’t happen.  The bottom two bits of MTVEC are ignored so the trap always is to a multiple of 4.  See 3.1.7 of the privileged spec.
  assign BranchMisalignedFaultE = (IEUAdrE[1] & ~P.C_SUPPORTED) & PCSrcE;
  flopenr #(1) InstrMisalignedReg(clk, reset, ~StallM, BranchMisalignedFaultE, InstrMisalignedFaultM);

  // Instruction and PC/PCLink pipeline registers
  // Cannot use flopenrc for Instr(E/M) as it resets to NOP not 0.
  mux2    #(32)     FlushInstrEMux(InstrD, nop, FlushE, NextInstrD);
  mux2    #(32)     FlushInstrMMux(InstrE, nop, FlushM, NextInstrE);
  flopenr #(32)     InstrEReg(clk, reset, ~StallE, NextInstrD, InstrE);
  flopenr #(32)     InstrMReg(clk, reset, ~StallM, NextInstrE, InstrM);
  flopenr #(P.XLEN) PCEReg(clk, reset, ~StallE, PCD, PCE);
  flopenr #(P.XLEN) PCMReg(clk, reset, ~StallM, PCE, PCM);
  //flopenr #(P.XLEN) PCPDReg(clk, reset, ~StallD, PCPlus2or4F, PCLinkD);
  //flopenr #(P.XLEN) PCPEReg(clk, reset, ~StallE, PCLinkD, PCLinkE);

  flopenrc #(1) CompressedDReg(clk, reset, FlushD, ~StallD, CompressedF, CompressedD);
  flopenrc #(1) CompressedEReg(clk, reset, FlushE, ~StallE, CompressedD, CompressedE);
  assign PCLinkE = PCE + (CompressedE ? 2 : 4);

  // pipeline original compressed instruction in case it is needed for MTVAL on an illegal instruction exception
  flopenrc #(16) InstrRawEReg(clk, reset, FlushE, ~StallE, InstrRawD[15:0], InstrRawE);
  flopenrc #(16) InstrRawMReg(clk, reset, FlushM, ~StallM, InstrRawE, InstrRawM);
  flopenrc #(1)  CompressedMReg(clk, reset, FlushM, ~StallM, CompressedE, CompressedM);
  mux2     #(32) InstrOrigMux(InstrM, {16'b0, InstrRawM}, CompressedM, InstrOrigM); 
endmodule

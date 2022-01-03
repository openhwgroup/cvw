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

module ifu (
  input logic 		      clk, reset,
  input logic 		      StallF, StallD, StallE, StallM, StallW,
  input logic 		      FlushF, FlushD, FlushE, FlushM, FlushW,
  // Fetch
  input logic [`XLEN-1:0]     IfuBusHRDATA,
  input logic 		      IfuBusAck,
  (* mark_debug = "true" *) output logic [`XLEN-1:0]    PCF, 
  output logic [`PA_BITS-1:0] IfuBusAdr,
  output logic 		      IfuBusRead,
  output logic 		      IfuStallF,
  // Execute
  output logic [`XLEN-1:0]    PCLinkE,
  input logic 		      PCSrcE, 
  input logic [`XLEN-1:0]     IEUAdrE,
  output logic [`XLEN-1:0]    PCE,
  output logic 		      BPPredWrongE, 
  // Mem
  input logic 		      RetM, TrapM, 
  input logic [`XLEN-1:0]     PrivilegedNextPCM, 
  input logic 		      InvalidateICacheM,
  output logic [31:0] 	      InstrD, InstrM, 
  output logic [`XLEN-1:0]    PCM, 
  output logic [4:0] 	      InstrClassM,
  output logic 		      BPPredDirWrongM,
  output logic 		      BTBPredPCWrongM,
  output logic 		      RASPredPCWrongM,
  output logic 		      BPPredClassNonCFIWrongM,
  // Writeback
  // output logic [`XLEN-1:0] PCLinkW,
  // Faults
  input logic 		      IllegalBaseInstrFaultD,
  output logic 		      ITLBInstrPageFaultF,
  output logic 		      IllegalIEUInstrFaultD,
  output logic 		      InstrMisalignedFaultM,
  output logic [`XLEN-1:0]    InstrMisalignedAdrM,
  input logic 		      ExceptionM, PendingInterruptM,
	    

  
  // mmu management
  input logic [1:0] 	      PrivilegeModeW,
  input logic [`XLEN-1:0]     PTE,
  input logic [1:0] 	      PageType,
  input logic [`XLEN-1:0]     SATP_REGW,
  input logic 		      STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic [1:0] 	      STATUS_MPP,
  input logic 		      ITLBWriteF, ITLBFlushF,

  output logic 		      ITLBMissF,

  // pmp/pma (inside mmu) signals.  *** temporarily from AHB bus but eventually replace with internal versions pre H
  input 		      var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  input 		      var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0], 

  output logic 		      InstrAccessFaultF
);

  logic [`XLEN-1:0]            PCCorrectE, UnalignedPCNextF, PCNextF;
  logic                        misaligned, BranchMisalignedFaultE, BranchMisalignedFaultM, TrapMisalignedFaultM;
  logic                        PrivilegedChangePCM;
  logic                        IllegalCompInstrD;
  logic [`XLEN-1:0]            PCPlus2or4F, PCLinkD;
  logic [`XLEN-3:0]            PCPlusUpperF;
  logic                        CompressedF;
  logic [31:0]                 InstrRawD, FinalInstrRawF, InstrRawF;
  logic [31:0]                 InstrE;
  logic [`XLEN-1:0]            PCD;

  localparam [31:0]      nop = 32'h00000013; // instruction for NOP
  logic                        reset_q; // *** look at this later.

  logic                        BPPredDirWrongE, BTBPredPCWrongE, RASPredPCWrongE, BPPredClassNonCFIWrongE;
  
(* mark_debug = "true" *)  logic [`PA_BITS-1:0]         PCPFmmu, PCNextFPhys; // used to either truncate or expand PCPF and PCNextF into `PA_BITS width.
  logic [`XLEN+1:0]            PCFExt;
  logic [`XLEN-1:0] 		   PCBPWrongInvalidate;
  logic 					   BPPredWrongM;
  logic 					   CacheableF;
  
  

  generate
    if (`XLEN==32) begin:pcnextfphys
      //assign PCPF = PCPFmmu[31:0];
      assign PCNextFPhys = {{(`PA_BITS-`XLEN){1'b0}}, PCNextF};
    end else begin:pcnextfphys
      //assign PCPF = {8'b0, PCPFmmu};
      assign PCNextFPhys = PCNextF[`PA_BITS-1:0];
    end
  endgenerate

  assign PCFExt = {2'b00, PCF};
  //
  mmu #(.TLB_ENTRIES(`ITLB_ENTRIES), .IMMU(1))
  immu(.PAdr(PCFExt[`PA_BITS-1:0]),
       .VAdr(PCF),
       .Size(2'b10),
       .PTE(PTE),
       .PageTypeWriteVal(PageType),
       .TLBWrite(ITLBWriteF),
       .TLBFlush(ITLBFlushF),
       .PhysicalAddress(PCPFmmu),
       .TLBMiss(ITLBMissF),
       .TLBPageFault(ITLBInstrPageFaultF),
       .ExecuteAccessF(1'b1), // ***dh -- this should eventually change to only true if an instruction fetch is occurring
       .AtomicAccessM(1'b0),
       .ReadAccessM(1'b0),
       .WriteAccessM(1'b0),
       .LoadAccessFaultM(),
       .StoreAccessFaultM(),
       .DisableTranslation(1'b0),
       .Cacheable(CacheableF), .Idempotent(), .AtomicAllowed(),

       .clk, .reset,
       .SATP_REGW,
       .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV,
       .STATUS_MPP,
       .PrivilegeModeW,
       .InstrAccessFaultF,
       .PMPCFG_ARRAY_REGW,
       .PMPADDR_ARRAY_REGW      
       );



  // branch predictor signal
  logic                        SelBPPredF;
  logic [`XLEN-1:0]            BPPredPCF, PCNext0F, PCNext1F, PCNext2F, PCNext3F;
  logic [4:0]                  InstrClassD, InstrClassE;

  logic 					   ICacheFetchLine;
  logic 					   BusStall;
  logic 					   ICacheStallF;
  logic 					   IgnoreRequest;
  
  

  // *** put memory interface on here, InstrF becomes output
  //assign ICacheBusAdr = PCF; // *** no MMU
  //assign IfuBusFetch = ~StallD; // *** & ICacheMissF; add later
  // assign IfuBusFetch = 1; // *** & ICacheMissF; add later

  // conditional
  // 1. ram // controlled by `MEM_IROM
  // 2. cache // `MEM_ICACHE
  // 3. wire pass-through

  localparam integer   WORDSPERLINE = `MEM_ICACHE ? `ICACHE_BLOCKLENINBITS/`XLEN : 1;
  localparam integer   LOGWPL = `MEM_ICACHE ? $clog2(WORDSPERLINE) : 1;
  localparam integer   BLOCKLEN = `MEM_ICACHE ? `ICACHE_BLOCKLENINBITS : `XLEN;
  localparam integer   WordCountThreshold = `MEM_ICACHE ? WORDSPERLINE - 1 : 0;

  localparam integer   BLOCKBYTELEN = BLOCKLEN/8;
  localparam integer   OFFSETLEN = $clog2(BLOCKBYTELEN);

  logic [LOGWPL-1:0]   WordCount;
  logic [BLOCKLEN-1:0] ICacheMemWriteData;
  logic 			   ICacheBusAck;
  logic [`PA_BITS-1:0] LocalIfuBusAdr;
  logic [`PA_BITS-1:0] ICacheBusAdr;
  logic 			   SelUncachedAdr;
  

  // *** bug: on spill the second memory request does not go through the mmu(skips tlb, pmp, and pma checkers)
  // also it is possible to have any above fault on the spilled accesses.
  // I think the solution is to move the spill logic into the ifu using the busfsm and ensuring
  // the mmu sees the spilled address.
  generate
	if(`MEM_ICACHE) begin : icache
	  icache icache(.clk, .reset, .CPUBusy(StallF), .IgnoreRequest, .ICacheMemWriteData , .ICacheBusAck,
					.ICacheBusAdr, .CompressedF, .ICacheStallF, .ITLBMissF, .ITLBWriteF, .FinalInstrRawF, 
					.ICacheFetchLine,
					.CacheableF,
					.PCNextF(PCNextFPhys),
					.PCPF(PCPFmmu),
					.PCF,
					.InvalidateICacheM);

	end else begin : passthrough
	  assign ICacheFetchLine = 0;
	  assign ICacheBusAdr = 0;
	  assign CompressedF = 0; //?
	  assign ICacheStallF = 0;
	  assign FinalInstrRawF = 0;
	end
  endgenerate
	
  // select between dcache and direct from the BUS. Always selected if no dcache.
  mux2 #(32) UnCachedInstrMux(.d0(FinalInstrRawF),
				.d1(ICacheMemWriteData[31:0]),
				.s(SelUncachedAdr),
				.y(InstrRawF));

  
  genvar 			   index;
  generate
    for (index = 0; index < WORDSPERLINE; index++) begin:fetchbuffer
      flopen #(`XLEN) fb(.clk(clk),
			 .en(IfuBusAck & IfuBusRead & (index == WordCount)),
			 .d(IfuBusHRDATA),
			 .q(ICacheMemWriteData[(index+1)*`XLEN-1:index*`XLEN]));
    end
  endgenerate

  assign LocalIfuBusAdr = SelUncachedAdr ? PCPFmmu : ICacheBusAdr;
  assign IfuBusAdr = ({{`PA_BITS-LOGWPL{1'b0}}, WordCount} << $clog2(`XLEN/8)) + LocalIfuBusAdr;

  busfsm #(WordCountThreshold, LOGWPL, `MEM_ICACHE)
  busfsm(.clk, .reset, .IgnoreRequest,
		.LsuRWM(2'b10), .DCacheFetchLine(ICacheFetchLine), .DCacheWriteLine(1'b0), 
		.LsuBusAck(IfuBusAck),
		.CPUBusy(StallF), .CacheableM(CacheableF),
		.BusStall, .LsuBusWrite(), .LsuBusRead(IfuBusRead), .DCacheBusAck(ICacheBusAck),
		.BusCommittedM(), .SelUncachedAdr(SelUncachedAdr), .WordCount);

  assign IfuStallF = ICacheStallF | BusStall;

  //assign IgnoreRequest = ITLBMissF | ExceptionM | PendingInterruptM;
  assign IgnoreRequest = ITLBMissF;




  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset | reset_q, ~StallD, FlushD ? nop : InstrRawF, nop, InstrRawD);


  assign PrivilegedChangePCM = RetM | TrapM;

  mux2 #(`XLEN) pcmux0(.d0(PCPlus2or4F),
         .d1(BPPredPCF),
         .s(SelBPPredF),
         .y(PCNext0F));

  mux2 #(`XLEN) pcmux1(.d0(PCNext0F),
         .d1(PCCorrectE),
         .s(BPPredWrongE),
         .y(PCNext1F));

  // December 20, 2021 Ross Thompson, If instructions in ID and IF are already invalid we don't pick PCE on icache invalidate.
  // this only happens because of branch class miss prediction.  The Fence instruction was incorrectly predicted as a branch
  // this means on the previous cycle the BPPredWrongE updated PCNextF to the correct fall through address.
  // to fix we need to select the correct address PCF as the next PCNextF. Unforunately we must still flush the instruction in IF
  // as we are deliberately invalidating the icache.  This address has to be refetched by the icache.
  mux2 #(`XLEN) pcmux2(.d0(PCNext1F),
         .d1(PCBPWrongInvalidate),
         .s(InvalidateICacheM),
         .y(PCNext2F));
  
  mux2 #(`XLEN) pcmux3(.d0(PCNext2F),
         .d1(PrivilegedNextPCM),
         .s(PrivilegedChangePCM),
         .y(PCNext3F));

  mux2 #(`XLEN) pcmux4(.d0(PCNext3F),
         .d1(`RESET_VECTOR),
         .s(reset_q),
         .y(UnalignedPCNextF)); 
 
  flop #(1) resetReg (.clk(clk),
        .d(reset),
        .q(reset_q));


  flopenrc #(1) BPPredWrongMReg(.clk, .reset, .en(~StallM), .clear(FlushM),
								.d(BPPredWrongE), .q(BPPredWrongM));

  mux2 #(`XLEN) pcmuxBPWrongInvalidateFlush(.d0(PCE), .d1(PCF), 
											.s(BPPredWrongM & InvalidateICacheM), 
											.y(PCBPWrongInvalidate));
  
  
  assign  PCNextF = {UnalignedPCNextF[`XLEN-1:1], 1'b0}; // hart-SPEC p. 21 about 16-bit alignment
  flopenl #(`XLEN) pcreg(clk, reset, ~StallF & ~ICacheStallF, PCNextF, `RESET_VECTOR, PCF);

  // branch and jump predictor
  generate
    if (`BPRED_ENABLED == 1) begin : bpred
      // I am making the port connection explicit for now as I want to see them and they will be changing.
    
      bpred bpred(.clk, .reset,
				  .StallF, .StallD, .StallE,
				  .FlushF, .FlushD, .FlushE,
				  .PCNextF, .BPPredPCF, .SelBPPredF, .PCE, .PCSrcE, .IEUAdrE,
				  .PCD, .PCLinkE, .InstrClassE, .BPPredWrongE, .BPPredDirWrongE,
				  .BTBPredPCWrongE, .RASPredPCWrongE, .BPPredClassNonCFIWrongE);
	  
    end else begin : bpred
      assign BPPredPCF = {`XLEN{1'b0}};
      assign SelBPPredF = 1'b0;
      assign BPPredWrongE = PCSrcE;
      assign BPPredDirWrongE = 1'b0;
      assign BTBPredPCWrongE = 1'b0;
      assign RASPredPCWrongE = 1'b0;
      assign BPPredClassNonCFIWrongE = 1'b0;
    end      
  endgenerate
  // The true correct target is IEUAdrE if PCSrcE is 1 else it is the fall through PCLinkE.
  assign PCCorrectE =  PCSrcE ? IEUAdrE : PCLinkE;

  // pcadder
  // add 2 or 4 to the PC, based on whether the instruction is 16 bits or 32
  assign PCPlusUpperF = PCF[`XLEN-1:2] + 1; // add 4 to PC
  // choose PC+2 or PC+4
  always_comb
    if (CompressedF) // add 2
      if (PCF[1]) PCPlus2or4F = {PCPlusUpperF, 2'b00}; 
      else        PCPlus2or4F = {PCF[`XLEN-1:2], 2'b10};
    else          PCPlus2or4F = {PCPlusUpperF, PCF[1:0]}; // add 4

  // Decode stage pipeline register and logic
  flopenrc #(`XLEN) PCDReg(clk, reset, FlushD, ~StallD, PCF, PCD);
   
  // expand 16-bit compressed instructions to 32 bits

  decompress decomp(.InstrRawD, .InstrD, .IllegalCompInstrD);
  assign IllegalIEUInstrFaultD = IllegalBaseInstrFaultD | IllegalCompInstrD; // illegal if bad 32 or 16-bit instr
  // *** combine these with others in better way, including M, F


  // the branch predictor needs a compact decoding of the instruction class.
  // *** consider adding in the alternate return address x5 for returns.
  assign InstrClassD[4] = (InstrD[6:0] & 7'h77) == 7'h67 & (InstrD[11:07] & 5'h1B) == 5'h01; // jal(r) must link to ra or r5
  assign InstrClassD[3] = InstrD[6:0] == 7'h67 & (InstrD[19:15] & 5'h1B) == 5'h01; // return must return to ra or r5
  assign InstrClassD[2] = InstrD[6:0] == 7'h67 & (InstrD[19:15] & 5'h1B) != 5'h01 & (InstrD[11:7] & 5'h1B) != 5'h01; // jump register, but not return
  assign InstrClassD[1] = InstrD[6:0] == 7'h6F & (InstrD[11:7] & 5'h1B) != 5'h01; // jump, RD != x1 or x5
  assign InstrClassD[0] = InstrD[6:0] == 7'h63; // branch

  // Misaligned PC logic
  // instruction address misalignment is generated by the target of control flow instructions, not
  // the fetch itself.
  assign misaligned = PCNextF[0] | (PCNextF[1] & ~`C_SUPPORTED);
  // do we really need to have check if the instruction is control flow? Yes
  // Branches are updated in the execution stage but traps are updated in the memory stage.

  // pipeline misaligned faults to M stage
  assign BranchMisalignedFaultE = misaligned & PCSrcE; // E-stage (Branch/Jump) misaligned
  flopenr #(1) InstrMisalginedReg(clk, reset, ~StallM, BranchMisalignedFaultE, BranchMisalignedFaultM);
  // *** Ross Thompson. Check InstrMisalignedAdrM as I believe it is the same as PCF.  Should be able to remove.
  flopenr #(`XLEN) InstrMisalignedAdrReg(clk, reset, ~StallM, PCNextF, InstrMisalignedAdrM);
  assign TrapMisalignedFaultM = misaligned & PrivilegedChangePCM;
  assign InstrMisalignedFaultM = BranchMisalignedFaultM; // | TrapMisalignedFaultM; *** put this back in without causing a cyclic path
  
  flopenr  #(32)   InstrEReg(clk, reset, ~StallE, FlushE ? nop : InstrD, InstrE);
  flopenr  #(32)   InstrMReg(clk, reset, ~StallM, FlushM ? nop : InstrE, InstrM);
  flopenr #(`XLEN) PCEReg(clk, reset, ~StallE, PCD, PCE);
  flopenr #(`XLEN) PCMReg(clk, reset, ~StallM, PCE, PCM);

  flopenrc #(5) InstrClassRegE(.clk(clk),
          .reset(reset),
          .en(~StallE),
          .clear(FlushE),
          .d(InstrClassD),
          .q(InstrClassE));

  flopenrc #(5) InstrClassRegM(.clk(clk),
          .reset(reset),
          .en(~StallM),
          .clear(FlushM),
          .d(InstrClassE),
          .q(InstrClassM));

  flopenrc #(4) BPPredWrongRegM(.clk(clk),
          .reset(reset),
          .en(~StallM),
          .clear(FlushM),
          .d({BPPredDirWrongE, BTBPredPCWrongE, RASPredPCWrongE, BPPredClassNonCFIWrongE}),
          .q({BPPredDirWrongM, BTBPredPCWrongM, RASPredPCWrongM, BPPredClassNonCFIWrongM}));

  // seems like there should be a lower-cost way of doing this PC+2 or PC+4 for JAL.  
  // either have ALU compute PC+2/4 and feed into ALUResult input of ResultMux or
  // have dedicated adder in Mem stage based on PCM + 2 or 4
  // *** redo this 
  flopenr #(`XLEN) PCPDReg(clk, reset, ~StallD, PCPlus2or4F, PCLinkD);
  flopenr #(`XLEN) PCPEReg(clk, reset, ~StallE, PCLinkD, PCLinkE);
endmodule


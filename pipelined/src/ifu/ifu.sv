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
	output logic 				ITLBInstrPageFaultF,
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
	output logic 				ITLBMissF,
  // pmp/pma (inside mmu) signals.  *** temporarily from AHB bus but eventually replace with internal versions pre H
	input 						var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
	input 						var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0], 
	output logic 				InstrAccessFaultF,
    output logic                ICacheAccess,
    output logic                ICacheMiss
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

  localparam [31:0]            nop = 32'h00000013; // instruction for NOP
  logic                        reset_q; // *** look at this later.

  logic                        BPPredDirWrongE, BTBPredPCWrongE, RASPredPCWrongE, BPPredClassNonCFIWrongE;
  logic [`XLEN-1:0] 		   PCBPWrongInvalidate;
  logic 					   BPPredWrongM;

  
(* mark_debug = "true" *)  logic [`PA_BITS-1:0]         PCPF; // used to either truncate or expand PCPF and PCNextF into `PA_BITS width.
  logic [`XLEN+1:0]            PCFExt;

  logic 					   CacheableF;
  logic [11:0] 				   PCNextFMux;
  logic [`XLEN-1:0] 		   PCFMux;
  logic 					   SelNextSpill;
  logic 					   ICacheFetchLine;
  logic 					   BusStall;
  logic 					   ICacheStallF;
  logic 					   IgnoreRequest;
  logic 					   CPUBusy;
  logic [31:0] 				   PostSpillInstrRawF;


	if(`C_SUPPORTED) begin : SpillSupport
	  logic [`XLEN-1:0] 		   PCFp2;
	  logic 					   Spill;
	  logic 					   SelSpill, SpillSave;
	  logic [15:0] 				   SpillDataLine0;

	  // this exists only if there are compressed instructions.
	  assign PCFp2 = PCF + `XLEN'b10;
  
	  assign PCNextFMux = SelNextSpill ? PCFp2[11:0] : PCNextF[11:0];
	  assign PCFMux = SelSpill ? PCFp2 : PCF;
  
	  assign Spill = &PCF[$clog2(SPILLTHRESHOLD)+1:1];

	  typedef enum 		   {STATE_SPILL_READY, STATE_SPILL_SPILL} statetype;
	  (* mark_debug = "true" *)  statetype CurrState, NextState;


	  always_ff @(posedge clk)
		if (reset)    CurrState <= #1 STATE_SPILL_READY;
		else CurrState <= #1 NextState;

	  always_comb begin
		case(CurrState)
		  STATE_SPILL_READY: if (Spill & ~(ICacheStallF | BusStall)) NextState = STATE_SPILL_SPILL;
          else                                    NextState = STATE_SPILL_READY;
		  STATE_SPILL_SPILL: if(ICacheStallF | BusStall | StallF)    NextState = STATE_SPILL_SPILL;
	      else                                    NextState = STATE_SPILL_READY;
		  default:                                                   NextState = STATE_SPILL_READY;
		endcase
	  end

	  assign SelSpill = CurrState == STATE_SPILL_SPILL;
	  assign SelNextSpill = (CurrState == STATE_SPILL_READY & (Spill & ~(ICacheStallF | BusStall))) |
							(CurrState == STATE_SPILL_SPILL & (ICacheStallF | BusStall));
	  assign SpillSave = CurrState == STATE_SPILL_READY & (Spill & ~(ICacheStallF | BusStall));
	  

	  flopenr #(16) SpillInstrReg(.clk(clk),
								  .en(SpillSave),
								  .reset(reset),
								  .d(`MEM_ICACHE ? InstrRawF[15:0] : InstrRawF[31:16]),
								  .q(SpillDataLine0));

	  assign PostSpillInstrRawF = Spill ? {InstrRawF[15:0], SpillDataLine0} : InstrRawF;
	  assign CompressedF = PostSpillInstrRawF[1:0] != 2'b11;

	  // end of spill support
	end else begin : NoSpillSupport // line: SpillSupport
	  assign PCNextFMux = PCNextF[11:0];
	  assign PCFMux = PCF;
	  assign SelNextSpill = 0;
	  assign PostSpillInstrRawF = InstrRawF;
	end
  

  assign PCFExt = {2'b00, PCFMux};
  //
  mmu #(.TLB_ENTRIES(`ITLB_ENTRIES), .IMMU(1))
  immu(.PAdr(PCFExt[`PA_BITS-1:0]),
       .VAdr(PCFMux),
       .Size(2'b10),
       .PTE(PTE),
       .PageTypeWriteVal(PageType),
       .TLBWrite(ITLBWriteF),
       .TLBFlush(ITLBFlushF),
       .PhysicalAddress(PCPF),
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

  

  // *** put memory interface on here, InstrF becomes output
  //assign ICacheBusAdr = PCF; // *** no MMU
  //assign IFUBusFetch = ~StallD; // *** & ICacheMissF; add later
  // assign IFUBusFetch = 1; // *** & ICacheMissF; add later

  // conditional
  // 1. ram // controlled by `MEM_IROM
  // 2. cache // `MEM_ICACHE
  // 3. wire pass-through

  localparam integer   WORDSPERLINE = `MEM_ICACHE ? `ICACHE_LINELENINBITS/`XLEN : 1;
  localparam integer   SPILLTHRESHOLD = `MEM_ICACHE ? `ICACHE_LINELENINBITS/32 : 1;
  localparam integer   LOGWPL = `MEM_ICACHE ? $clog2(WORDSPERLINE) : 1;
  localparam integer   LINELEN = `MEM_ICACHE ? `ICACHE_LINELENINBITS : `XLEN;
  localparam integer   WordCountThreshold = `MEM_ICACHE ? WORDSPERLINE - 1 : 0;

  localparam integer   LINEBYTELEN = LINELEN/8;
  localparam integer   OFFSETLEN = $clog2(LINEBYTELEN);

  logic [LOGWPL-1:0]   WordCount;
  logic [LINELEN-1:0] ICacheMemWriteData;
  logic 			   ICacheBusAck;
  logic [`PA_BITS-1:0] LocalIFUBusAdr;
  logic [`PA_BITS-1:0] ICacheBusAdr;
  logic 			   SelUncachedAdr;
  
	if(`MEM_ICACHE) begin : icache
	  logic [1:0] IFURWF;
	  assign IFURWF = CacheableF ? 2'b10 : 2'b00;
	  
	  logic [`XLEN-1:0] FinalInstrRawF_FIXME;
	  
	  cache #(.LINELEN(`ICACHE_LINELENINBITS),
			  .NUMLINES(`ICACHE_WAYSIZEINBYTES*8/`ICACHE_LINELENINBITS),
			  .NUMWAYS(`ICACHE_NUMWAYS), .DCACHE(0))
	  icache(.clk, .reset, .CPUBusy, .IgnoreRequest, .CacheMemWriteData(ICacheMemWriteData) , .CacheBusAck(ICacheBusAck),
			 .CacheBusAdr(ICacheBusAdr), .CacheStall(ICacheStallF), .ReadDataWord(FinalInstrRawF_FIXME),
			 .CacheFetchLine(ICacheFetchLine),
			 .CacheWriteLine(),
			 .ReadDataLineSets(),
			 .CacheMiss(ICacheMiss),
			 .CacheAccess(ICacheAccess),
			 .FinalWriteData('0),
			 .RW(IFURWF), 
			 .Atomic(2'b00),
			 .FlushCache(1'b0),
			 .NextAdr(PCNextFMux),
			 .PAdr(PCPF),
			 .CacheCommitted(),
			 .InvalidateCacheM(InvalidateICacheM));

	  assign FinalInstrRawF = FinalInstrRawF_FIXME[31:0];
	end else begin
	  assign ICacheFetchLine = 0;
	  assign ICacheBusAdr = 0;
	  assign ICacheStallF = 0;
	  assign FinalInstrRawF = 0;
      assign ICacheAccess = CacheableF;
      assign ICacheMiss = CacheableF;
	end
	
  // select between dcache and direct from the BUS. Always selected if no dcache.
  // handled in the busfsm.
  mux2 #(32) UnCachedInstrMux(.d0(FinalInstrRawF),
				.d1(ICacheMemWriteData[31:0]),
				.s(SelUncachedAdr),
				.y(InstrRawF));

  // always present
  genvar 			   index;
  for (index = 0; index < WORDSPERLINE; index++) begin:fetchbuffer
    flopen #(`XLEN) fb(.clk(clk),
      .en(IFUBusAck & IFUBusRead & (index == WordCount)),
      .d(IFUBusHRDATA),
      .q(ICacheMemWriteData[(index+1)*`XLEN-1:index*`XLEN]));
  end

  assign LocalIFUBusAdr = SelUncachedAdr ? PCPF : ICacheBusAdr;
  assign IFUBusAdr = ({{`PA_BITS-LOGWPL{1'b0}}, WordCount} << $clog2(`XLEN/8)) + LocalIFUBusAdr;

  busfsm #(WordCountThreshold, LOGWPL, `MEM_ICACHE)
  busfsm(.clk, .reset, .IgnoreRequest,
		.LSURWM(2'b10), .DCacheFetchLine(ICacheFetchLine), .DCacheWriteLine(1'b0), 
		.LSUBusAck(IFUBusAck),
		.CPUBusy, .CacheableM(CacheableF),
		.BusStall, .LSUBusWrite(), .LSUBusRead(IFUBusRead), .DCacheBusAck(ICacheBusAck),
		.BusCommittedM(), .SelUncachedAdr(SelUncachedAdr), .WordCount);

  assign IFUStallF = ICacheStallF | BusStall | SelNextSpill;
  assign CPUBusy = StallF & ~SelNextSpill;

  //assign IgnoreRequest = ITLBMissF | ExceptionM | PendingInterruptM;
  // this is a difference with the dcache.
  // uses interlock fsm.
  assign IgnoreRequest = ITLBMissF;

  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset | reset_q, ~StallD, FlushD ? nop : PostSpillInstrRawF, nop, InstrRawD);


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
  if (`BPRED_ENABLED == 1) begin : bpred
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


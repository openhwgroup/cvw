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
  input logic [`XLEN-1:0]     InstrInF,
  input logic 		      InstrAckF,
  output logic [`XLEN-1:0]    PCF, 
  output logic [`PA_BITS-1:0] InstrPAdrF,
  output logic 		      InstrReadF,
  output logic 		      ICacheStallF,
  // Decode
  output logic [`XLEN-1:0]    PCD, 
  // Execute
  output logic [`XLEN-1:0]    PCLinkE,
  input logic 		      PCSrcE, 
  input logic [`XLEN-1:0]     PCTargetE,
  output logic [`XLEN-1:0]    PCE,
  output logic 		      BPPredWrongE, 
  // Mem
  input logic 		      RetM, TrapM, 
  input logic [`XLEN-1:0]     PrivilegedNextPCM, 
  output logic [31:0] 	      InstrD, InstrE, InstrM, InstrW,
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

  
  // mmu management
  input logic [1:0] 	      PrivilegeModeW,
  input logic [`XLEN-1:0]     PTE,
  input logic [1:0] 	      PageType,
  input logic [`XLEN-1:0]     SATP_REGW,
  input logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic  [1:0]       STATUS_MPP,
  input logic 		      ITLBWriteF, ITLBFlushF,
  input logic 		      WalkerInstrPageFaultF,

  output logic 		      ITLBMissF, ITLBHitF,

  // pmp/pma (inside mmu) signals.  *** temporarily from AHB bus but eventually replace with internal versions pre H
  input  var logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  input  var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0], 

  output logic InstrAccessFaultF,

  output logic 		      ISquashBusAccessF
);

  logic [`XLEN-1:0] PCCorrectE, UnalignedPCNextF, PCNextF;
  logic             misaligned, BranchMisalignedFaultE, BranchMisalignedFaultM, TrapMisalignedFaultM;
  logic             PrivilegedChangePCM;
  logic             IllegalCompInstrD;
  logic [`XLEN-1:0] PCPlus2or4F, PCW, PCLinkD, PCLinkM, PCPF;
  logic [`XLEN-3:0] PCPlusUpperF;
  logic             CompressedF;
  logic [31:0]      InstrRawD, FinalInstrRawF;
  localparam [31:0]      nop = 32'h00000013; // instruction for NOP
  logic 	    reset_q; // *** look at this later.

  logic 	    BPPredDirWrongE, BTBPredPCWrongE, RASPredPCWrongE, BPPredClassNonCFIWrongE;
  
  logic [`PA_BITS-1:0] PCPFmmu, PCNextFPhys; // used to either truncate or expand PCPF and PCNextF into `PA_BITS width.
  logic [`XLEN+1:0]    PCFExt;

  generate
    if (`XLEN==32) begin
      assign PCPF = PCPFmmu[31:0];
      assign PCNextFPhys = {{(`PA_BITS-`XLEN){1'b0}}, PCNextF};
    end else begin
      assign PCPF = {8'b0, PCPFmmu};
      assign PCNextFPhys = PCNextF[`PA_BITS-1:0];
    end
  endgenerate

  assign PCFExt = {2'b00, PCF};
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
       .TLBHit(ITLBHitF),
       .TLBPageFault(ITLBInstrPageFaultF),
       .ExecuteAccessF(1'b1), // ***dh -- this should eventually change to only true if an instruction fetch is occurring
       .AtomicAccessM(1'b0),
       .ReadAccessM(1'b0),
       .WriteAccessM(1'b0),
       .SquashBusAccess(ISquashBusAccessF),
       .LoadAccessFaultM(),
       .StoreAccessFaultM(),
       .DisableTranslation(1'b0),
       .Cacheable(),
       .Idempotent(),
       .AtomicAllowed(),
       .*);


  // branch predictor signals
  logic 	          SelBPPredF;
  logic [`XLEN-1:0] BPPredPCF, PCNext0F, PCNext1F, PCNext2F, PCNext3F;
  logic [4:0] 	    InstrClassD, InstrClassE;
  

  // *** put memory interface on here, InstrF becomes output
  //assign InstrPAdrF = PCF; // *** no MMU
  //assign InstrReadF = ~StallD; // *** & ICacheMissF; add later
  // assign InstrReadF = 1; // *** & ICacheMissF; add later

  icache icache(.*,
		.PCNextF(PCNextFPhys),
		.PCPF(PCPFmmu),
		.WalkerInstrPageFaultF(WalkerInstrPageFaultF));
  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset | reset_q, ~StallD, FlushD ? nop : FinalInstrRawF, nop, InstrRawD);


  assign PrivilegedChangePCM = RetM | TrapM;

  mux2 #(`XLEN) pcmux0(.d0(PCPlus2or4F),
		       .d1(BPPredPCF),
		       .s(SelBPPredF),
		       .y(PCNext0F));

  mux2 #(`XLEN) pcmux1(.d0(PCNext0F),
		       .d1(PCCorrectE),
		       .s(BPPredWrongE),
		       .y(PCNext1F));

  mux2 #(`XLEN) pcmux2(.d0(PCNext1F),
		       .d1(PrivilegedNextPCM),
		       .s(PrivilegedChangePCM),
		       .y(PCNext2F));

  mux2 #(`XLEN) pcmux4(.d0(PCNext2F),
		       .d1(`RESET_VECTOR),
		       .s(reset_q),
		       .y(UnalignedPCNextF)); 
 
  flop #(1) resetReg (.clk(clk),
		      .d(reset),
		      .q(reset_q));
  
  
  assign  PCNextF = {UnalignedPCNextF[`XLEN-1:1], 1'b0}; // hart-SPEC p. 21 about 16-bit alignment
  flopenl #(`XLEN) pcreg(clk, reset, ~StallF & ~ICacheStallF, PCNextF, `RESET_VECTOR, PCF);

  // branch and jump predictor
  generate
    if (`BPRED_ENABLED == 1) begin : bpred
      // I am making the port connection explicit for now as I want to see them and they will be changing.
      bpred bpred(.*,
		  .PCNextF(PCNextF),
		  .BPPredPCF(BPPredPCF),
		  .SelBPPredF(SelBPPredF),
		  .PCE(PCE),
		  .PCSrcE(PCSrcE),
		  .PCTargetE(PCTargetE),
		  .PCD(PCD),
		  .PCLinkE(PCLinkE),
		  .InstrClassE(InstrClassE),
		  .BPPredWrongE(BPPredWrongE),
 		  .BPPredDirWrongE(BPPredDirWrongE),
 		  .BTBPredPCWrongE(BTBPredPCWrongE),
 		  .RASPredPCWrongE(RASPredPCWrongE),
 		  .BPPredClassNonCFIWrongE(BPPredClassNonCFIWrongE));
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
  // The true correct target is PCTargetE if PCSrcE is 1 else it is the fall through PCLinkE.
  assign PCCorrectE =  PCSrcE ? PCTargetE : PCLinkE;

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
  decompress decomp(.*);
  assign IllegalIEUInstrFaultD = IllegalBaseInstrFaultD | IllegalCompInstrD; // illegal if bad 32 or 16-bit instr
  // *** combine these with others in better way, including M, F


  // the branch predictor needs a compact decoding of the instruction class.
  // *** consider adding in the alternate return address x5 for returns.
  assign InstrClassD[4] = (InstrD[6:0] & 7'h77) == 7'h67 && (InstrD[11:07] & 5'h1B) == 5'h01; // jal(r) must link to ra or r5
  assign InstrClassD[3] = InstrD[6:0] == 7'h67 && (InstrD[19:15] & 5'h1B) == 5'h01; // return must return to ra or r5
  assign InstrClassD[2] = InstrD[6:0] == 7'h67 && (InstrD[19:15] & 5'h1B) != 5'h01 && (InstrD[11:7] & 5'h1B) != 5'h01; // jump register, but not return
  assign InstrClassD[1] = InstrD[6:0] == 7'h6F && (InstrD[11:7] & 5'h1B) != 5'h01; // jump, RD != x1 or x5
  assign InstrClassD[0] = InstrD[6:0] == 7'h63; // branch

  // Misaligned PC logic

  generate
    if (`C_SUPPORTED) // C supports compressed instructions on halfword boundaries
      assign misaligned = PCNextF[0];
    else // instructions must be on word boundaries
      assign misaligned = |PCNextF[1:0];
  endgenerate

  // pipeline misaligned faults to M stage
  assign BranchMisalignedFaultE = misaligned & PCSrcE; // E-stage (Branch/Jump) misaligned
  flopenr #(1) InstrMisalginedReg(clk, reset, ~StallM, BranchMisalignedFaultE, BranchMisalignedFaultM);
  // *** Ross Thompson. Check InstrMisalignedAdrM as I believe it is the same as PCF.  Should be able to remove.
  flopenr #(`XLEN) InstrMisalignedAdrReg(clk, reset, ~StallM, PCNextF, InstrMisalignedAdrM);
  assign TrapMisalignedFaultM = misaligned & PrivilegedChangePCM;
  assign InstrMisalignedFaultM = BranchMisalignedFaultM; // | TrapMisalignedFaultM; *** put this back in without causing a cyclic path
  
  flopenr  #(32)   InstrEReg(clk, reset, ~StallE, FlushE ? nop : InstrD, InstrE);
  flopenr  #(32)   InstrMReg(clk, reset, ~StallM, FlushM ? nop : InstrE, InstrM);
  // flopenr  #(32)   InstrWReg(clk, reset, ~StallW, FlushW ? nop : InstrM, InstrW); // just for testbench, delete later
  flopenr #(`XLEN) PCEReg(clk, reset, ~StallE, PCD, PCE);
  flopenr #(`XLEN) PCMReg(clk, reset, ~StallM, PCE, PCM);
  // flopenr #(`XLEN) PCWReg(clk, reset, ~StallW, PCM, PCW); // *** probably not needed; delete later

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
  // flopenr #(`XLEN) PCPMReg(clk, reset, ~StallM, PCLinkE, PCLinkM);
  // /flopenr #(`XLEN) PCPWReg(clk, reset, ~StallW, PCLinkM, PCLinkW);

endmodule


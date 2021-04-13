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
  input  logic             clk, reset,
  input  logic             StallF, StallD, StallE, StallM, StallW,
  input  logic             FlushF, FlushD, FlushE, FlushM, FlushW,
  // Fetch
  input  logic [`XLEN-1:0] InstrInF,
  input  logic             InstrAckF,
  output logic [`XLEN-1:0] PCF, 
  output logic [`XLEN-1:0] InstrPAdrF,
  output logic             InstrReadF,
  output logic             ICacheStallF,
  // Decode  
  // Execute
  output logic [`XLEN-1:0] PCLinkE,
  input logic 		   PCSrcE, 
  input logic [`XLEN-1:0]  PCTargetE,
  output logic [`XLEN-1:0] PCE,
  output logic 		   BPPredWrongE, 
  // Mem
  input logic 		   RetM, TrapM, 
  input logic [`XLEN-1:0]  PrivilegedNextPCM, 
  output logic [31:0] 	   InstrD, InstrM,
  output logic [`XLEN-1:0] PCM, 
  output logic [3:0] InstrClassM,
  output logic BPPredWrongM,
  // Writeback
  // output logic [`XLEN-1:0] PCLinkW,
  // Faults
  input  logic             IllegalBaseInstrFaultD,
  output logic             IllegalIEUInstrFaultD,
  output logic             InstrMisalignedFaultM,
  output logic [`XLEN-1:0] InstrMisalignedAdrM,
  // TLB management
  input logic  [1:0]       PrivilegeModeW,
  input logic  [`XLEN-1:0] PageTableEntryF,
  input logic  [1:0]       PageTypeF,
  input logic  [`XLEN-1:0] SATP_REGW,
  input logic              ITLBWriteF, ITLBFlushF,
  output logic             ITLBMissF, ITLBHitF
);

  logic [`XLEN-1:0] UnalignedPCNextF, PCNextF;
  logic             misaligned, BranchMisalignedFaultE, BranchMisalignedFaultM, TrapMisalignedFaultM;
  logic             PrivilegedChangePCM;
  logic             IllegalCompInstrD;
  logic [`XLEN-1:0] PCPlusUpperF, PCPlus2or4F, PCD, PCW, PCLinkD, PCLinkM, PCNextPF;
  logic             CompressedF;
  logic [31:0]      InstrRawD, InstrE, InstrW;
  logic [31:0]      nop = 32'h00000013; // instruction for NOP
  logic [`XLEN-1:0] ITLBInstrPAdrF, ICacheInstrPAdrF;
  // *** send this to the trap unit
  logic             ITLBPageFaultF;

  tlb #(3) itlb(.TLBAccess(1'b1), .VirtualAddress(PCF),
                .PageTableEntryWrite(PageTableEntryF), .PageTypeWrite(PageTypeF),
                .TLBWrite(ITLBWriteF), .TLBFlush(ITLBFlushF),
                .PhysicalAddress(ITLBInstrPAdrF), .TLBMiss(ITLBMissF),
                .TLBHit(ITLBHitF), .TLBPageFault(ITLBPageFaultF),
                .*);

  // branch predictor signals
  logic 	   SelBPPredF;
  logic [`XLEN-1:0] BPPredPCF, PCCorrectE, PCNext0F, PCNext1F;
  logic [3:0] 	    InstrClassD, InstrClassE;
  

  // *** put memory interface on here, InstrF becomes output
  //assign InstrPAdrF = PCF; // *** no MMU
  //assign InstrReadF = ~StallD; // *** & ICacheMissF; add later
  // assign InstrReadF = 1; // *** & ICacheMissF; add later

  // jarred 2021-03-14 Add instrution cache block to remove rd2
  assign PCNextPF = PCNextF; // Temporary workaround until iTLB is live
  icache ic(
    .*,
    .InstrPAdrF(ICacheInstrPAdrF),
    .UpperPCNextPF(PCNextPF[`XLEN-1:12]),
    .LowerPCNextF(PCNextF[11:0])
  );
  // Prioritize the iTLB for reads if it wants one
  mux2 #(`XLEN) instrPAdrMux(ICacheInstrPAdrF, ITLBInstrPAdrF, ITLBMissF, InstrPAdrF);

  assign PrivilegedChangePCM = RetM | TrapM;

  //mux3    #(`XLEN) pcmux(PCPlus2or4F, PCCorrectE, PrivilegedNextPCM, {PrivilegedChangePCM, BPPredWrongE}, UnalignedPCNextF);
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
		       .y(UnalignedPCNextF));
  
  assign  PCNextF = {UnalignedPCNextF[`XLEN-1:1], 1'b0}; // hart-SPEC p. 21 about 16-bit alignment
  flopenl #(`XLEN) pcreg(clk, reset, ~StallF & ~ICacheStallF, PCNextF, `RESET_VECTOR, PCF);

  // branch and jump predictor
  // I am making the port connection explicit for now as I want to see them and they will be changing.
  bpred bpred(.clk(clk),
	      .reset(reset),
	      .StallF(StallF),
	      .StallD(StallD),
	      .StallE(1'b0),   // *** may need this eventually
	      .FlushF(FlushF),
	      .FlushD(FlushD),
	      .FlushE(FlushE),
	      .PCNextF(PCNextF),
	      .BPPredPCF(BPPredPCF),
	      .SelBPPredF(SelBPPredF),
	      .PCE(PCE),
	      .PCSrcE(PCSrcE),
	      .PCTargetE(PCTargetE),
	      .PCD(PCD),
	      .PCLinkE(PCLinkE),
	      .InstrClassE(InstrClassE),
	      .BPPredWrongE(BPPredWrongE));
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
  assign InstrClassD[3] = InstrD[6:0] == 7'h67 && InstrD[19:15] == 5'h01; // return
  assign InstrClassD[2] = InstrD[6:0] == 7'h67 && InstrD[19:15] != 5'h01; // jump register, but not return
  assign InstrClassD[1] = InstrD[6:0] == 7'h6F; // jump
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
  flopenr #(`XLEN) InstrMisalignedAdrReg(clk, reset, ~StallM, PCNextF, InstrMisalignedAdrM);
  assign TrapMisalignedFaultM = misaligned & PrivilegedChangePCM;
  assign InstrMisalignedFaultM = BranchMisalignedFaultM; // | TrapMisalignedFaultM; *** put this back in without causing a cyclic path
  
  flopenr  #(32)   InstrEReg(clk, reset, ~StallE, FlushE ? nop : InstrD, InstrE);
  flopenr  #(32)   InstrMReg(clk, reset, ~StallM, FlushM ? nop : InstrE, InstrM);
  // flopenr  #(32)   InstrWReg(clk, reset, ~StallW, FlushW ? nop : InstrM, InstrW); // just for testbench, delete later
  flopenr #(`XLEN) PCEReg(clk, reset, ~StallE, PCD, PCE);
  flopenr #(`XLEN) PCMReg(clk, reset, ~StallM, PCE, PCM);
  // flopenr #(`XLEN) PCWReg(clk, reset, ~StallW, PCM, PCW); // *** probably not needed; delete later

  flopenrc #(4) InstrClassRegE(.clk(clk),
			       .reset(reset),
			       .en(~StallE),
			       .clear(FlushE),
			       .d(InstrClassD),
			       .q(InstrClassE));

  flopenrc #(4) InstrClassRegM(.clk(clk),
			       .reset(reset),
			       .en(~StallM),
			       .clear(FlushM),
			       .d(InstrClassE),
			       .q(InstrClassM));

  flopenrc #(1) BPPredWrongRegM(.clk(clk),
			       .reset(reset),
			       .en(~StallM),
			       .clear(FlushM),
			       .d(BPPredWrongE),
			       .q(BPPredWrongM));

  // seems like there should be a lower-cost way of doing this PC+2 or PC+4 for JAL.  
  // either have ALU compute PC+2/4 and feed into ALUResult input of ResultMux or
  // have dedicated adder in Mem stage based on PCM + 2 or 4
  // *** redo this 
  flopenr #(`XLEN) PCPDReg(clk, reset, ~StallD, PCPlus2or4F, PCLinkD);
  flopenr #(`XLEN) PCPEReg(clk, reset, ~StallE, PCLinkD, PCLinkE);
  // flopenr #(`XLEN) PCPMReg(clk, reset, ~StallM, PCLinkE, PCLinkM);
  // /flopenr #(`XLEN) PCPWReg(clk, reset, ~StallW, PCLinkM, PCLinkW);

endmodule


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
  input logic 		   clk, reset,
  input logic 		   StallF, StallD, FlushF, FlushD, FlushE, FlushM, FlushW,
  // Fetch
  input logic [31:0] 	   InstrF,
  output logic [`XLEN-1:0] PCF, 
  output logic [`XLEN-1:0] InstrPAdrF,
  // Decode  
  output logic 		   InstrStall,
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
  // Writeback
  output logic [`XLEN-1:0] PCLinkW,
  // Faults
  input logic 		   IllegalBaseInstrFaultD,
  output logic 		   IllegalIEUInstrFaultD,
  output logic 		   InstrMisalignedFaultM,
  output logic [`XLEN-1:0] InstrMisalignedAdrM
);

  logic [`XLEN-1:0] UnalignedPCNextF, PCNextF;
  logic misaligned, BranchMisalignedFaultE, BranchMisalignedFaultM, TrapMisalignedFaultM;
  logic StallExceptResolveBranchesF, PrivilegedChangePCM;
  logic IllegalCompInstrD;
  logic [`XLEN-1:0] PCPlusUpperF, PCPlus2or4F, PCD, PCW, PCLinkD, PCLinkM;
  logic        CompressedF;
  logic [31:0]     InstrRawD, InstrE;
  logic [31:0]     nop = 32'h00000013; // instruction for NOP

  // branch predictor signals
  logic 	   SelBPPredF;
  logic [`XLEN-1:0] BPPredPCF, PCCorrectE, PCNext0F, PCNext1F;
  

  // *** put memory interface on here, InstrF becomes output
  assign InstrStall = 0; // ***
  assign InstrPAdrF = PCF; // *** no MMU

  assign PrivilegedChangePCM = RetM | TrapM;

  assign StallExceptResolveBranchesF = StallF & ~(SelBPPredF | BPPredWrongE | PrivilegedChangePCM);

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
  flopenl #(`XLEN) pcreg(clk, reset, ~StallExceptResolveBranchesF, PCNextF, `RESET_VECTOR, PCF);

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
	      .InstrF(InstrF), // *** this is flushed internally. The logic is redundant with some out here.
	      // Also I believe this port will be removed.
	      .PCE(PCE),
	      .PCSrcE(PCSrcE),
	      .PCTargetE(PCTargetE),
	      .PCD(PCD),
	      .PCLinkE(PCLinkE),
	      .BPPredWrongE(BPPredWrongE));
  // The true correct target is PCTargetE if PCSrcE is 1 else it is the fall through PCLinkE.
  assign PCCorrectE =  PCSrcE ? PCTargetE : PCLinkE;

  // pcadder
  // add 2 or 4 to the PC, based on whether the instruction is 16 bits or 32
  assign CompressedF = (InstrF[1:0] != 2'b11); // is it a 16-bit compressed instruction?
  assign PCPlusUpperF = PCF[`XLEN-1:2] + 1; // add 4 to PC
  
  // choose PC+2 or PC+4
  always_comb
    if (CompressedF) // add 2
      if (PCF[1]) PCPlus2or4F = {PCPlusUpperF, 2'b00}; 
      else        PCPlus2or4F = {PCF[`XLEN-1:2], 2'b10};
    else          PCPlus2or4F = {PCPlusUpperF, PCF[1:0]}; // add 4


  // Decode stage pipeline register and logic
  flopenl #(32)    InstrDReg(clk, reset, ~StallD, (FlushD ? nop : InstrF), nop, InstrRawD);
  flopenrc #(`XLEN) PCDReg(clk, reset, FlushD, ~StallD, PCF, PCD);
   
  // expand 16-bit compressed instructions to 32 bits
  decompress decomp(.*);
  assign IllegalIEUInstrFaultD = IllegalBaseInstrFaultD | IllegalCompInstrD; // illegal if bad 32 or 16-bit instr
  // *** combine these with others in better way, including M, F

  // Misaligned PC logic

  generate
    if (`C_SUPPORTED) // C supports compressed instructions on halfword boundaries
      assign misaligned = PCNextF[0];
    else // instructions must be on word boundaries
      assign misaligned = |PCNextF[1:0];
  endgenerate

  // pipeline misaligned faults to M stage
  assign BranchMisalignedFaultE = misaligned & PCSrcE; // E-stage (Branch/Jump) misaligned
  flopr #(1) InstrMisalginedReg(clk, reset, BranchMisalignedFaultE, BranchMisalignedFaultM);
  flopr #(`XLEN) InstrMisalignedAdrReg(clk, reset, PCNextF, InstrMisalignedAdrM);
  assign TrapMisalignedFaultM = misaligned & PrivilegedChangePCM;
  assign InstrMisalignedFaultM = BranchMisalignedFaultM; // | TrapMisalignedFaultM; *** put this back in without causing a cyclic path
  
  flopr  #(32)   InstrEReg(clk, reset, FlushE ? nop : InstrD, InstrE);
  flopr  #(32)   InstrMReg(clk, reset, FlushM ? nop : InstrE, InstrM);
  flopr #(`XLEN) PCEReg(clk, reset, PCD, PCE);
  flopr #(`XLEN) PCMReg(clk, reset, PCE, PCM);
  flopr #(`XLEN) PCWReg(clk, reset, PCM, PCW); // *** probably not needed; delete later

  // seems like there should be a lower-cost way of doing this PC+2 or PC+4 for JAL.  
  // either have ALU compute PC+2/4 and feed into ALUResult input of ResultMux or
  // have dedicated adder in Mem stage based on PCM + 2 or 4
  // *** redo this 
  flopr #(`XLEN) PCPDReg(clk, reset, PCPlus2or4F, PCLinkD);
  flopr #(`XLEN) PCPEReg(clk, reset, PCLinkD, PCLinkE);
  flopr #(`XLEN) PCPMReg(clk, reset, PCLinkE, PCLinkM);
  flopr #(`XLEN) PCPWReg(clk, reset, PCLinkM, PCLinkW);

endmodule


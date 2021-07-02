///////////////////////////////////////////
//
// Written: Katherine Parry, Bret Mathis
// Modified: 6/23/2021
//
// Purpose: FPU
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

module fpu (
  input logic 		         clk,
  input logic 		         reset,
  input logic [2:0]        FRM_REGW,   // Rounding mode from CSR
  input logic [31:0]       InstrD,
  input logic [`XLEN-1:0]  ReadDataW,     // Read data from memory
  input logic [`XLEN-1:0]  SrcAE,      // Integer input being processed
  input logic [`XLEN-1:0]  SrcAM,      // Integer input being written into fpreg
  input logic 		         StallE, StallM, StallW,
  input logic 		         FlushE, FlushM, FlushW,
  output logic 		      FStallD,    // Stall the decode stage if Div/Sqrt instruction
  output logic 		      FWriteIntE, FWriteIntM, FWriteIntW, // Write integer register enable
  output logic [`XLEN-1:0] FWriteDataE,      // Data to be written to memory
  output logic [`XLEN-1:0] FIntResM,     
  output logic 		      FDivBusyE,        // Is the divison/sqrt unit busy
  output logic 		      IllegalFPUInstrD, // Is the instruction an illegal fpu instruction
  output logic [4:0] 	   SetFflagsM,       // FPU flags
  output logic [`XLEN-1:0] FPUResultW);      // FPU result

   // control logic signal instantiation
   logic 		   FWriteEnD, FWriteEnE, FWriteEnM, FWriteEnW;              // FP register write enable
   logic [2:0] 	FrmD, FrmE, FrmM, FrmW;                                  // FP rounding mode
   logic 		   FmtD, FmtE, FmtM, FmtW;                                  // FP precision 0-single 1-double
   logic 		   FDivStartD, FDivStartE;                                  // Start division
   logic 		   FWriteIntD;                                              // Write to integer register
   logic 		   FOutputInput2D, FOutputInput2E;                          // Put Input2 in Input1 if a store instruction
   logic [1:0] 	FMemRWD;                                        // Read and write enable for memory
   logic [1:0]    ForwardXD, ForwardXE;                        // Input1 forwarding mux control signal
   logic [1:0] 	ForwardYD, ForwardYE;                        // Input2 forwarding mux control signal
   logic [1:0]		   ForwardZD, ForwardZE;                        // Input3 forwarding mux control signal
   logic 		   SrcYUsedD;                                            // Is input 2 used
   logic 		   SrcZUsedD;                                            // Is input 3 used
   logic [2:0] 	FResultSelD, FResultSelE, FResultSelM, FResultSelW;      // Select FP result
   logic [3:0] 	FOpCtrlD, FOpCtrlE, FOpCtrlM, FOpCtrlW;                  // Select which opperation to do in each component
   logic [1:0]         FResSelD, FResSelE, FResSelM;  
   logic [1:0]         FIntResSelD, FIntResSelE, FIntResSelM;                                   
   logic [4:0] 	Adr1E, Adr2E, Adr3E;
   
   // regfile signals
   logic [4:0]    RdE, RdM, RdW;                                           // what adress to write to    // ***Can take from ieu insted of pipelining
   logic [63:0] 	FWDM;                                                    // Write data for FP register
   logic [63:0] 	FRD1D, FRD2D, FRD3D;                                     // Read Data from FP register - decode stage
   logic [63:0] 	FRD1E, FRD2E, FRD3E;                                     // Read Data from FP register - execute stage
   logic [63:0] 	SrcXE, SrcXM, SrcXW;                         // Input 1 to the various units (after forwarding)
   logic [`XLEN-1:0]   SrcXMAligned;
   logic [63:0] 	SrcYE, SrcYM, SrcYW;                                      // Input 2 to the various units (after forwarding)
   logic [63:0] 	SrcZE, SrcZM;                                      // Input 3 to the various units (after forwarding)
   logic [63:0] 	FLoadResultW, FLoadStoreResultM, FLoadStoreResultW;      // Result for load, store, and move to int-reg instructions
   
   // div/sqrt signals
   logic 		   DivDenormE, DivDenormM, DivDenormW;
   logic 		   DivOvEn, DivUnEn;
   logic [63:0] 	FDivResultE, FDivResultM, FDivResultW;
   logic [4:0] 	FDivFlagsE, FDivFlagsM, FDivFlagsW;
   logic          FDivSqrtDoneE, FDivSqrtDoneM;
   logic [63:0] 	DivInput1E, DivInput2E;
   logic          HoldInputs;                                              // keep forwarded inputs arround durring division
   
   // FMA signals
	logic [105:0]	ProdManE, ProdManM;
	logic [161:0]	AlignedAddendE, AlignedAddendM;                       
	logic [12:0]	ProdExpE, ProdExpM;
	logic 			AddendStickyE, AddendStickyM;
	logic 			KillProdE, KillProdM;
	logic				XZeroE, YZeroE, ZZeroE, XZeroM, YZeroM, ZZeroM;
	logic				XInfE, YInfE, ZInfE, XInfM, YInfM, ZInfM;
	logic				XNaNE, YNaNE, ZNaNE, XNaNM, YNaNM, ZNaNM;
   logic [63:0]   FmaResultM, FmaResultW;
   logic [4:0]    FmaFlagsM, FmaFlagsW;

   // add/cvt signals
   logic [63:0] 	AddSumE, AddSumTcE;
   logic [3:0] 	AddSelInvE;
   logic [10:0] 	AddExpPostSumE;
   logic 		   AddCorrSignE, AddOp1NormE, AddOp2NormE, AddOpANormE, AddOpBNormE, AddInvalidE;
   logic 		   AddDenormInE, AddSwapE, AddNormOvflowE, AddSignAE;
   logic 		   AddConvertE;
   logic [63:0] 	AddFloat1E, AddFloat2E;
   logic [11:0] 	AddExp1DenormE, AddExp2DenormE;
   logic [10:0] 	AddExponentE;
   logic [2:0] 	AddRmE;
   logic [3:0] 	AddOpTypeE;
   logic 		   AddPE, AddOvEnE, AddUnEnE;    
   logic 		   AddDenormM;
   logic [63:0] 	AddSumM, AddSumTcM;
   logic [3:0] 	AddSelInvM;
   logic [10:0] 	AddExpPostSumM;
   logic 		   AddCorrSignM, AddOp1NormM, AddOp2NormM, AddOpANormM, AddOpBNormM, AddInvalidM;
   logic 		   AddDenormInM, AddSwapM, AddNormOvflowM, AddSignAM;
   logic 		   AddConvertM, AddSignM;
   logic [63:0] 	AddFloat1M, AddFloat2M;
   logic [11:0] 	AddExp1DenormM, AddExp2DenormM;
   logic [10:0] 	AddExponentM;
   logic [63:0] 	AddOp1M, AddOp2M;
   logic [2:0] 	AddRmM;
   logic [3:0] 	AddOpTypeM;
   logic 		   AddPM, AddOvEnM, AddUnEnM;  
   logic [63:0] 	FAddResultM, FAddResultW;
   logic [4:0] 	FAddFlagsM, FAddFlagsW;
   
   // cmp signals 
   logic 		   CmpInvalidE, CmpInvalidM, CmpInvalidW;
   logic [63:0] 	FCmpResultE, FCmpResultM, FCmpResultW;
   
   // fsgn signals
   logic [63:0] 	SgnResultE, SgnResultM, SgnResultW;
   logic [4:0] 	SgnFlagsE, SgnFlagsM, SgnFlagsW;
   logic [63:0]   FResM, FResW;
   logic    FFlgM, FFlgW;
   
   // instantiation of W stage regfile signals
   logic [63:0] 	AlignedSrcAM, ForwardSrcAM, SrcAW;
   
   // classify signals
   logic [63:0] 	ClassResultE, ClassResultM, ClassResultW;
   
   // 64-bit FPU result   
   logic [63:0] 	FPUResult64W, FPUResult64E;                                           
   logic [4:0] 	FPUFlagsW;
   
   
   //DECODE STAGE
   
   
   // top-level controller for FPU
   fctrl ctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]), .*);
   
   // regfile instantiation
   FPregfile fpregfile (clk, reset, FWriteEnW,
			InstrD[19:15], InstrD[24:20], InstrD[31:27], RdW,
			FPUResult64W,
			FRD1D, FRD2D, FRD3D);	
   
   //*****************
   // fpregfile D/E pipe registers
   //*****************
   flopenrc #(64) DEReg1(clk, reset, FlushE, ~StallE, FRD1D, FRD1E);
   flopenrc #(64) DEReg2(clk, reset, FlushE, ~StallE, FRD2D, FRD2E);
   flopenrc #(64) DEReg3(clk, reset, FlushE, ~StallE, FRD3D, FRD3E);
   
   //*****************
   // other  D/E pipe registers
   //*****************
   flopenrc #(1) CtrlRegE1(clk, reset, FlushE, ~StallE, FDivStartD, FDivStartE);
   flopenrc #(15) CtrlRegE2(clk, reset, FlushE, ~StallE, {InstrD[19:15], InstrD[24:20], InstrD[31:27]}, 
                                                         {Adr1E,         Adr2E,         Adr3E});
   flopenrc #(22) DECtrlReg(clk, reset, FlushE, ~StallE, 
                        {FWriteEnD, FResultSelD, FResSelD, FIntResSelD, FrmD, FmtD, InstrD[11:7], FOpCtrlD, FWriteIntD},
                        {FWriteEnE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, RdE,          FOpCtrlE, FWriteIntE});

   //EXECUTION STAGE
   
   // Hazard unit for FPU
   fpuhazard hazard(.*);

   // forwarding muxs
   mux3  #(64)  fxemux(FRD1E, FPUResult64W, FResM, ForwardXE, SrcXE);
   mux3  #(64)  fyemux(FRD2E, FPUResult64W, FResM, ForwardYE, SrcYE);
   mux3  #(64)  fzemux(FRD3E, FPUResult64W, FResM, ForwardZE, SrcZE);

   
   // first of two-stage instance of floating-point fused multiply-add unit
   fma1 fma1 (.X(SrcXE), .Y(SrcYE), .Z(SrcZE), .FOpCtrlE(FOpCtrlE[2:0]),.*);
   
   // first and only instance of floating-point divider
   logic fpdivClk;
   
   clockgater fpdivclkg(.E(FDivStartE),
			.SE(1'b0),
			.CLK(clk),
			.ECLK(fpdivClk));
   
   // capture the inputs for div/sqrt	 
   flopenrc #(64) reg_input1 (.d(SrcXE), .q(DivInput1E),
               .en(~HoldInputs), .clear(FDivSqrtDoneE),
               .reset(reset),  .clk(clk));
   flopenrc #(64) reg_input2 (.d(SrcYE), .q(DivInput2E),
               .en(~HoldInputs), .clear(FDivSqrtDoneE),
               .reset(reset),  .clk(clk));

   fpdiv fpdivsqrt (.DivOpType(FOpCtrlE[0]), .clk(fpdivClk), .FmtE(~FmtE), .*);
   


   // first of two-stage instance of floating-point add/cvt unit
   fpuaddcvt1 fpadd1 (.*);
   
   // first of two-stage instance of floating-point comparator
   fpucmp1 fpcmp1 (SrcXE, SrcYE, FOpCtrlE[2:0], FmtE, CmpInvalidE, FCmpResultE);
   
   // first and only instance of floating-point sign converter
   fpusgn fpsgn (.SgnOpCodeE(FOpCtrlE[1:0]),.*);
   
   // first and only instance of floating-point classify unit
   fpuclassify fpuclass (.*);

   // output for store instructions
   assign FWriteDataE = FmtE ? SrcYE[63:64-`XLEN] : {{`XLEN-32{1'b0}}, SrcYE[63:32]};
   
   //*****************
   //fpregfile D/E pipe registers
   //*****************
   flopenrc #(64) EMFpReg1(clk, reset, FlushM, ~StallM, SrcXE, SrcXM);
   flopenrc #(64) EMFpReg2(clk, reset, FlushM, ~StallM, SrcYE, SrcYM);
   flopenrc #(64) EMFpReg3(clk, reset, FlushM, ~StallM, SrcZE, SrcZM);
   
   //*****************
   // fma E/M pipe registers
   //*****************  
  flopenrc #(106) EMRegFma3(clk, reset, FlushM, ~StallM, ProdManE, ProdManM); 
  flopenrc #(162) EMRegFma4(clk, reset, FlushM, ~StallM, AlignedAddendE, AlignedAddendM); 
  flopenrc #(13) EMRegFma6(clk, reset, FlushM, ~StallM, ProdExpE, ProdExpM);  
  flopenrc #(1) EMRegFma7(clk, reset, FlushM, ~StallM, AddendStickyE, AddendStickyM); 
  flopenrc #(1) EMRegFma8(clk, reset, FlushM, ~StallM, KillProdE, KillProdM); 
  flopenrc #(1) EMRegFma10(clk, reset, FlushM, ~StallM, XZeroE, XZeroM); 
  flopenrc #(1) EMRegFma11(clk, reset, FlushM, ~StallM, YZeroE, YZeroM); 
  flopenrc #(1) EMRegFma12(clk, reset, FlushM, ~StallM, ZZeroE, ZZeroM); 
  flopenrc #(1) EMRegFma16(clk, reset, FlushM, ~StallM, XInfE, XInfM); 
  flopenrc #(1) EMRegFma17(clk, reset, FlushM, ~StallM, YInfE, YInfM); 
  flopenrc #(1) EMRegFma18(clk, reset, FlushM, ~StallM, ZInfE, ZInfM); 
  flopenrc #(1) EMRegFma19(clk, reset, FlushM, ~StallM, XNaNE, XNaNM); 
  flopenrc #(1) EMRegFma20(clk, reset, FlushM, ~StallM, YNaNE, YNaNM); 
  flopenrc #(1) EMRegFma21(clk, reset, FlushM, ~StallM, ZNaNE, ZNaNM);  

   //*****************
   // fpadd E/M pipe registers
   //*****************
   flopenrc #(64) EMRegAdd1(clk, reset, FlushM, ~StallM, AddSumE, AddSumM); 
   flopenrc #(64) EMRegAdd2(clk, reset, FlushM, ~StallM, AddSumTcE, AddSumTcM); 
   flopenrc #(4)  EMRegAdd3(clk, reset, FlushM, ~StallM, AddSelInvE, AddSelInvM); 
   flopenrc #(11) EMRegAdd4(clk, reset, FlushM, ~StallM, AddExpPostSumE, AddExpPostSumM); 
   flopenrc #(1) EMRegAdd5(clk, reset, FlushM, ~StallM, AddCorrSignE, AddCorrSignM); 
   flopenrc #(1) EMRegAdd6(clk, reset, FlushM, ~StallM, AddOp1NormE, AddOp1NormM); 
   flopenrc #(1) EMRegAdd7(clk, reset, FlushM, ~StallM, AddOp2NormE, AddOp2NormM); 
   flopenrc #(1) EMRegAdd8(clk, reset, FlushM, ~StallM, AddOpANormE, AddOpANormM); 
   flopenrc #(1) EMRegAdd9(clk, reset, FlushM, ~StallM, AddOpBNormE, AddOpBNormM); 
   flopenrc #(1) EMRegAdd10(clk, reset, FlushM, ~StallM, AddInvalidE, AddInvalidM); 
   flopenrc #(1) EMRegAdd11(clk, reset, FlushM, ~StallM, AddDenormInE, AddDenormInM); 
   flopenrc #(1) EMRegAdd12(clk, reset, FlushM, ~StallM, AddConvertE, AddConvertM); 
   flopenrc #(1) EMRegAdd13(clk, reset, FlushM, ~StallM, AddSwapE, AddSwapM); 
   flopenrc #(1) EMRegAdd14(clk, reset, FlushM, ~StallM, AddNormOvflowE, AddNormOvflowM); 
   flopenrc #(1) EMRegAdd15(clk, reset, FlushM, ~StallM, AddSignAE, AddSignAM); 
   flopenrc #(64) EMRegAdd16(clk, reset, FlushM, ~StallM, AddFloat1E, AddFloat1M); 
   flopenrc #(64) EMRegAdd17(clk, reset, FlushM, ~StallM, AddFloat2E, AddFloat2M); 
   flopenrc #(12) EMRegAdd18(clk, reset, FlushM, ~StallM, AddExp1DenormE, AddExp1DenormM); 
   flopenrc #(12) EMRegAdd19(clk, reset, FlushM, ~StallM, AddExp2DenormE, AddExp2DenormM); 
   flopenrc #(11) EMRegAdd20(clk, reset, FlushM, ~StallM, AddExponentE, AddExponentM); 
   flopenrc #(3) EMRegAdd23(clk, reset, FlushM, ~StallM, AddRmE, AddRmM); 
   flopenrc #(4) EMRegAdd24(clk, reset, FlushM, ~StallM, AddOpTypeE, AddOpTypeM); 
   flopenrc #(1) EMRegAdd25(clk, reset, FlushM, ~StallM, AddPE, AddPM); 
   flopenrc #(1) EMRegAdd26(clk, reset, FlushM, ~StallM, AddOvEnE, AddOvEnM); 
   flopenrc #(1) EMRegAdd27(clk, reset, FlushM, ~StallM, AddUnEnE, AddUnEnM); 
   
   //*****************
   // fpcmp E/M pipe registers
   //*****************
   flopenrc #(1)  EMRegCmp1(clk, reset, FlushM, ~StallM, CmpInvalidE, CmpInvalidM); 
   flopenrc #(64) EMRegCmp3(clk, reset, FlushM, ~StallM, FCmpResultE, FCmpResultM); 
   
   //*****************
   // fpsgn E/M pipe registers
   //***************** 
   flopenrc #(64) EMRegSgn2(clk, reset, FlushM, ~StallM, SgnResultE, SgnResultM);
   flopenrc #(5) EMRegSgn3(clk, reset, FlushM, ~StallM, SgnFlagsE, SgnFlagsM);
   
   //*****************
   // other E/M pipe registers
   //*****************
   flopenrc #(22) EMCtrlReg(clk, reset, FlushM, ~StallM,
                        {FWriteEnE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, RdE, FOpCtrlE, FWriteIntE},
                        {FWriteEnM, FResultSelM, FResSelM, FIntResSelM, FrmM, FmtM, RdM, FOpCtrlM, FWriteIntM});
   
   //*****************
   // fpuclassify E/M pipe registers
   //***************** 
   flopenrc #(64) EMRegClass(clk, reset, FlushM, ~StallM, ClassResultE, ClassResultM);
   
   //BEGIN MEMORY STAGE
   
   mux3  #(64)  FResMux(AlignedSrcAM, SgnResultM, FCmpResultM, FResSelM, FResM);
   assign FFlgM = CmpInvalidM & FResSelM[1];

   assign SrcXMAligned = FmtM ? SrcXM[63:64-`XLEN] : {{`XLEN-32{1'b0}}, SrcXM[63:32]};
   mux3  #(`XLEN)  IntResMux(FCmpResultM[`XLEN-1:0], SrcXMAligned, ClassResultM[`XLEN-1:0], FIntResSelM, FIntResM);

   // second instance of two-stage FMA unit
   fma2 fma2(.X(SrcXM), .Y(SrcYM), .Z(SrcZM), .FOpCtrlM(FOpCtrlM[2:0]), .*);
   
   // second instance of two-stage floating-point add/cvt unit
   fpuaddcvt2 fpadd2 (.*);
   
   // Align SrcA to MSB when single precicion
   mux2  #(64)  SrcAMux({SrcAM[31:0], 32'b0}, {{64-`XLEN{1'b0}}, SrcAM}, FmtM, AlignedSrcAM);
      


      
   //*****************
   //fpregfile M/W pipe registers
   //*****************
   flopenrc #(64) MWFpReg1(clk, reset, FlushW, ~StallW, SrcXM, SrcXW);
   flopenrc #(64) MWFpReg2(clk, reset, FlushW, ~StallW, SrcYM, SrcYW);
   
   //*****************
   // fma M/W pipe registers
   //*****************
   flopenrc #(64) MWRegFma1(clk, reset, FlushW, ~StallW, FmaResultM, FmaResultW); 
   flopenrc #(5) MWRegFma2(clk, reset, FlushW, ~StallW, FmaFlagsM, FmaFlagsW); 
   
   //*****************
   // fpdiv M/W pipe registers
   //*****************
   flopenrc #(64) MWRegDiv1(clk, reset, FlushW, ~StallW, FDivResultM, FDivResultW); 
   flopenrc #(5) MWRegDiv2(clk, reset, FlushW, ~StallW, FDivFlagsM, FDivFlagsW);
   flopenrc #(1) MWRegDiv3(clk, reset, FlushW, ~StallW, DivDenormM, DivDenormW); 
   
   //*****************
   // fpadd M/W pipe registers
   //*****************
   flopenrc #(64) MWRegAdd1(clk, reset, FlushW, ~StallW, FAddResultM, FAddResultW); 
   flopenrc #(5) MWRegAdd2(clk, reset, FlushW, ~StallW, FAddFlagsM, FAddFlagsW); 
   
   //*****************
   // fpcmp M/W pipe registers
   //*****************
   flopenrc #(1) MWRegCmp1(clk, reset, FlushW, ~StallW, CmpInvalidM, CmpInvalidW); 
   // flopenrc #(2) MWRegCmp2(clk, reset, FlushW, ~StallW, CmpFCCM, CmpFCCW); 
   flopenrc #(64) MWRegCmp3(clk, reset, FlushW, ~StallW, FCmpResultM, FCmpResultW); 
   
   //*****************
   // fpsgn M/W pipe registers
   //***************** 
   flopenrc #(64) MWRegSgn1(clk, reset, FlushW, ~StallW, SgnResultM, SgnResultW);
   flopenrc #(5) MWRegSgn2(clk, reset, FlushW, ~StallW, SgnFlagsM, SgnFlagsW);
   
   //*****************
   // other M/W pipe registers
   //*****************
   flopenrc #(11) MWCtrlReg(clk, reset, FlushW, ~StallW,
                        {FWriteEnM, FResultSelM, RdM, FmtM, FWriteIntM},
                        {FWriteEnW, FResultSelW, RdW, FmtW, FWriteIntW});
   
   //*****************
   // fpuclassify M/W pipe registers
   //***************** 
   flopenrc #(64) MWRegClass(clk, reset, FlushW, ~StallW, ClassResultM, ClassResultW);
   flopenrc #(64) MWRegClass2(clk, reset, FlushW, ~StallW, FResM, FResW);
   flopenrc #(1) MWRegClass1(clk, reset, FlushW, ~StallW, FFlgM, FFlgW);
   




  //#########################################
  // BEGIN WRITEBACK STAGE
  //#########################################






   always_comb begin
      case (FResultSelW)
	3'b000 : FPUFlagsW = 5'b0;
	3'b001 : FPUFlagsW = FmaFlagsW;
	3'b010 : FPUFlagsW = FAddFlagsW;
	3'b011 : FPUFlagsW = FDivFlagsW;
	3'b100 : FPUFlagsW = {4'b0,FFlgW};
	default : FPUFlagsW = 5'bxxxxx;
      endcase
   end

   always_comb begin
      case (FResultSelW)
	3'b000 : FPUResult64W = FmtW ? {ReadDataW, {64-`XLEN{1'b0}}} : {ReadDataW[31:0], 32'b0};
	3'b001 : FPUResult64W = FmaResultW;
	3'b010 : FPUResult64W = FAddResultW;
	3'b011 : FPUResult64W = FDivResultW;
	3'b100 : FPUResult64W = FResW;
	default : FPUResult64W = 64'bxxxxx;
      endcase
   end
   
   
   // interface between XLEN size datapath and double-precision sized
   // floating-point results
   //
   // define offsets for LSB zero extension or truncation
   always_comb begin      
      // zero extension 
      FPUResultW = FmtW ? FPUResult64W[63:64-`XLEN] : {{`XLEN-32{1'b0}}, FPUResult64W[63:32]};
      SetFflagsM = FPUFlagsW;      
   end
  
endmodule // fpu


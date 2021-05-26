///////////////////////////////////////////
//
// Written: 
// Modified: 
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
  input  logic [2:0]       FRM_REGW,    // Rounding mode from CSR
  input  logic             reset,
  //input  logic             clear,     // *** not being used anywhere
  input  logic             clk,
  input  logic [31:0]      InstrD,
  input  logic [`XLEN-1:0] SrcAE,       // Integer input being processed
  input  logic [`XLEN-1:0] SrcAM,       // Integer input being written into fpreg
  input  logic 		         StallE, StallM, StallW,
  input  logic             FlushE, FlushM, FlushW,
  input  logic [`AHBW-1:0] HRDATA,
  input  logic             RegWriteD,
  output logic [4:0]       SetFflagsM,
  output logic [31:0]      FSROutW,
  output logic [1:0]       FMemRWM,
	output logic             FStallD,
  output logic             FWriteIntM, FWriteIntW,
  output logic [`XLEN-1:0] FWriteDataM,
  output logic             FDivSqrtDoneM,
  output logic             IllegalFPUInstrD,
  output logic [`XLEN-1:0] FPUResultW);





  //control logic signal instantiation
  logic             FWriteEnD, FWriteEnE, FWriteEnM, FWriteEnW;             // FP register write enable
  logic [2:0]       FrmD, FrmE, FrmM, FrmW;                                 // FP rounding mode
  logic             FmtD, FmtE, FmtM, FmtW;                                 // FP precision 0-single 1-double
  logic             FDivStartD, FDivStartE;                                 // Start division
  logic             FWriteIntD, FWriteIntE;                                 // Write to integer register
  logic             FOutputInput2D, FOutputInput2E;                         // Put Input2 in Input1 if a store instruction
  logic [1:0]       FMemRWD, FMemRWE;                                       // Read and write enable for memory
  logic [1:0]       FForwardInput1D, FForwardInput1E;                       // Input1 forwarding mux control signal
  logic [1:0]       FForwardInput2D, FForwardInput2E;                       // Input2 forwarding mux control signal
  logic             FForwardInput3D, FForwardInput3E;                       // Input3 forwarding mux control signal
  logic             FInput2UsedD;                                           // Is input 2 used
  logic             FInput3UsedD;                                           // Is input 3 used
  logic [2:0]       FResultSelD, FResultSelE, FResultSelM, FResultSelW;     // Select FP result
  logic [3:0]       FOpCtrlD, FOpCtrlE, FOpCtrlM;                           // Select which opperation to do in each component
  
  // regfile signals
  logic [4:0]       RdE, RdM, RdW; // ***Can take from ieu
  logic [`XLEN-1:0] FWDM;                                                   // Write data for FP register
  logic [`XLEN-1:0] FRD1D, FRD2D, FRD3D;                                    // Read Data from FP register
  logic [`XLEN-1:0] FRD1E, FRD2E, FRD3E;
  logic [`XLEN-1:0] FInput1E, FInput1M, FInput1tmpE;
  logic [`XLEN-1:0] FInput2E, FInput2M;
  logic [`XLEN-1:0] FInput3E, FInput3M;
  logic [`XLEN-1:0] FLoadStoreResultM, FLoadStoreResultW;                   // Result for load, store, and move to int-reg instructions

  // div/sqrt signals
  logic             DivDenormM, DivDenormW;
  logic             DivOvEn, DivUnEn;
  logic             DivBusyM;
  logic [63:0]      FDivResultM, FDivResultW;
  logic [4:0]       FDivFlagsM, FDivFlagsW;

  // FMA signals
  logic [12:0]		  aligncntE, aligncntM; 
  logic [105:0]		  rE, rM; 
  logic [105:0]		  sE, sM; 
  logic [163:0]		  tE, tM;	
  logic [8:0]		    normcntE, normcntM; 
  logic [12:0]		  aeE, aeM; 
  logic 		        bsE, bsM;
  logic 		        killprodE, killprodM; 
  logic 		        prodofE, prodofM; 
  logic			        xzeroE, xzeroM;
  logic			        yzeroE, yzeroM;
  logic			        zzeroE, zzeroM;
  logic			        xdenormE, xdenormM;
  logic			        ydenormE, ydenormM;
  logic			        zdenormE, zdenormM;
  logic			        xinfE, xinfM;
  logic			        yinfE, yinfM;
  logic			        zinfE, zinfM;
  logic			        xnanE, xnanM;
  logic			        ynanE, ynanM;
  logic			        znanE, znanM;
  logic			        nanE, nanM;
  logic	[8:0]		    sumshiftE, sumshiftM;
  logic			        sumshiftzeroE, sumshiftzeroM;
  logic             prodinfE, prodinfM;
  logic [63:0]      FmaResultM, FmaResultW;
  logic [4:0]       FmaFlagsM, FmaFlagsW;
  
  // add/cvt signals
  logic [63:0]      AddSumE, AddSumTcE;
  logic [3:0]       AddSelInvE;
  logic [10:0]      AddExpPostSumE;
  logic             AddCorrSignE, AddOp1NormE, AddOp2NormE, AddOpANormE, AddOpBNormE, AddInvalidE;
  logic             AddDenormInE, AddSwapE, AddNormOvflowE, AddSignAE;
  logic             AddConvertE;
  logic [63:0]      AddFloat1E, AddFloat2E;
  logic [11:0]      AddExp1DenormE, AddExp2DenormE;
  logic [10:0]      AddExponentE;
  logic [2:0]       AddRmE;
  logic [3:0]       AddOpTypeE;
  logic             AddPE, AddOvEnE, AddUnEnE;    
  logic             AddDenormM;
  logic [63:0]      AddSumM, AddSumTcM;
  logic [3:0]       AddSelInvM;
  logic [10:0]      AddExpPostSumM;
  logic             AddCorrSignM, AddOp1NormM, AddOp2NormM, AddOpANormM, AddOpBNormM, AddInvalidM;
  logic             AddDenormInM, AddSwapM, AddNormOvflowM, AddSignAM;
  logic             AddConvertM, AddSignM;
  logic [63:0]      AddFloat1M, AddFloat2M;
  logic [11:0]      AddExp1DenormM, AddExp2DenormM;
  logic [10:0]      AddExponentM;
  logic [63:0]      AddOp1M, AddOp2M;
  logic [2:0]       AddRmM;
  logic [3:0]       AddOpTypeM;
  logic             AddPM, AddOvEnM, AddUnEnM;  
  logic [63:0]      FAddResultM, FAddResultW;
  logic [4:0]       FAddFlagsM, FAddFlagsW;

  //cmp signals 
  logic [7:0]       WE, WM;
  logic [7:0]       XE, XM;
  logic             ANaNE, ANaNM;
  logic             BNaNE, BNaNM;
  logic             AzeroE, AzeroM;
  logic             BzeroE, BzeroM;
  logic             CmpInvalidM, CmpInvalidW;
  logic [1:0]       CmpFCCM, CmpFCCW; 
  logic [63:0]      FCmpResultW;

  // fsgn signals
  logic [63:0]      SgnResultE, SgnResultM, SgnResultW;
  logic [4:0]       SgnFlagsE, SgnFlagsM, SgnFlagsW;

  //instantiation of W stage regfile signals
  logic [`XLEN-1:0] SrcAW;

  // classify signals
  logic [63:0]      ClassResultE, ClassResultM, ClassResultW;
  logic [4:0]       ClassFlagsE, ClassFlagsM, ClassFlagsW;

  // other
  logic [63:0]      FPUResult64W, FPUResult64E;                                           // 64-bit FPU result
  logic [4:0]       FPUFlagsW;

  // pipeline control logic
  logic	                   PipeEnableDE;
  logic	                   PipeEnableEM;
  logic	                   PipeEnableMW;
  logic                    PipeClearDE;
  logic                    PipeClearEM;
  logic                    PipeClearMW;

  //temporarily assign pipe clear and enable signals
  //to never flush & always be running
  localparam PipeClear = 1'b0;
  localparam PipeEnable = 1'b1;
  always_comb begin

	  PipeEnableDE = ~StallE;
	  PipeEnableEM = ~StallM;
	  PipeEnableMW = ~StallW;
	  PipeClearDE = FlushE;
	  PipeClearEM = FlushM;
	  PipeClearMW = FlushW;

  end

 











  //DECODE STAGE

  //Hazard unit for FPU
  fpuhazard hazard(.Adr1(InstrD[19:15]), .Adr2(InstrD[24:20]), .Adr3(InstrD[31:27]), .*);

  //top-level controller for FPU
  fctrl ctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]), .*);


  //regfile instantiation
   FPregfile fpregfile (clk, reset, FWriteEnW,
			InstrD[19:15], InstrD[24:20], InstrD[31:27], RdW,
			FPUResult64W,
			FRD1D, FRD2D, FRD3D);	









  //*****************
  //fpregfile D/E pipe registers
  //*****************
  flopenrc #(64) DEReg1(clk, reset, PipeClearDE, PipeEnableDE, FRD1D, FRD1E);
  flopenrc #(64) DEReg2(clk, reset, PipeClearDE, PipeEnableDE, FRD2D, FRD2E);
  flopenrc #(64) DEReg3(clk, reset, PipeClearDE, PipeEnableDE, FRD3D, FRD3E);

  //*****************
  //other  D/E pipe registers
  //*****************
  flopenrc #(1) DEReg4(clk, reset, PipeClearDE, PipeEnableDE, FWriteEnD, FWriteEnE);
  flopenrc #(3) DEReg5(clk, reset, PipeClearDE, PipeEnableDE, FResultSelD, FResultSelE);
  flopenrc #(3) DEReg6(clk, reset, PipeClearDE, PipeEnableDE, FrmD, FrmE);
  flopenrc #(1) DEReg7(clk, reset, PipeClearDE, PipeEnableDE, FmtD, FmtE);
  flopenrc #(5) DEReg8(clk, reset, PipeClearDE, PipeEnableDE, InstrD[11:7], RdE);
  flopenrc #(4) DEReg9(clk, reset, PipeClearDE, PipeEnableDE, FOpCtrlD, FOpCtrlE);
  flopenrc #(1) DEReg10(clk, reset, PipeClearDE, PipeEnableDE, FDivStartD, FDivStartE);
  flopenrc #(2) DEReg11(clk, reset, PipeClearDE, PipeEnableDE, FForwardInput1D, FForwardInput1E);
  flopenrc #(2) DEReg12(clk, reset, PipeClearDE, PipeEnableDE, FForwardInput2D, FForwardInput2E);
  flopenrc #(1) DEReg13(clk, reset, PipeClearDE, PipeEnableDE, FForwardInput3D, FForwardInput3E);
  flopenrc #(64) DEReg14(clk, reset, PipeClearDE, PipeEnableDE, FPUResult64W, FPUResult64E);
  flopenrc #(1) DEReg15(clk, reset, PipeClearDE, PipeEnableDE, FWriteIntD, FWriteIntE);
  flopenrc #(1) DEReg16(clk, reset, PipeClearDE, PipeEnableDE, FOutputInput2D, FOutputInput2E);
  flopenrc #(2) DEReg17(clk, reset, PipeClearDE, PipeEnableDE, FMemRWD, FMemRWE);













  //EXECUTION STAGE



  // input muxs for forwarding
  mux4  #(64)  FInput1Emux(FRD1E, FPUResult64W, FPUResult64E, SrcAM, FForwardInput1E, FInput1tmpE);
  mux3  #(64)  FInput2Emux(FRD2E, FPUResult64W, FPUResult64E, FForwardInput2E, FInput2E);
  mux2  #(64)  FInput3Emux(FRD3E, FPUResult64E, FForwardInput3E, FInput3E);
  mux2  #(64)  FOutputInput2mux(FInput1tmpE, FInput2E, FOutputInput2E, FInput1E);

  fma1 fma1 (.*);

  //first and only instance of floating-point divider
  fpdiv fpdivsqrt (.DivOpType(FOpCtrlE[0]), .*);

  //first of two-stage instance of floating-point add/cvt unit
  fpuaddcvt1 fpadd1 (.*);

  //first of two-stage instance of floating-point comparator
  fpucmp1 fpcmp1 (WE, XE, ANaNE, BNaNE, AzeroE, BzeroE, FInput1E, FInput2E, FOpCtrlE[1:0]);

  //first and only instance of floating-point sign converter
  fpusgn fpsgn (.SgnOpCodeE(FOpCtrlE[1:0]),.*);














  //*****************
  //fpregfile D/E pipe registers
  //*****************
  flopenrc #(64) EMFpReg1(clk, reset, PipeClearEM, PipeEnableEM, FInput1E, FInput1M);
  flopenrc #(64) EMFpReg2(clk, reset, PipeClearEM, PipeEnableEM, FInput2E, FInput2M);
  flopenrc #(64) EMFpReg3(clk, reset, PipeClearEM, PipeEnableEM, FInput3E, FInput3M);

  //*****************
  //fma E/M pipe registers
  //*****************  
  flopenrc #(13) EMRegFma1(clk, reset, PipeClearEM, PipeEnableEM, aligncntE, aligncntM); 
  flopenrc #(106) EMRegFma2(clk, reset, PipeClearEM, PipeEnableEM, rE, rM); 
  flopenrc #(106) EMRegFma3(clk, reset, PipeClearEM, PipeEnableEM, sE, sM); 
  flopenrc #(164) EMRegFma4(clk, reset, PipeClearEM, PipeEnableEM, tE, tM); 
  flopenrc #(9) EMRegFma5(clk, reset, PipeClearEM, PipeEnableEM, normcntE, normcntM); 
  flopenrc #(13) EMRegFma6(clk, reset, PipeClearEM, PipeEnableEM, aeE, aeM);  
  flopenrc #(1) EMRegFma7(clk, reset, PipeClearEM, PipeEnableEM, bsE, bsM); 
  flopenrc #(1) EMRegFma8(clk, reset, PipeClearEM, PipeEnableEM, killprodE, killprodM); 
  flopenrc #(1) EMRegFma9(clk, reset, PipeClearEM, PipeEnableEM, prodofE, prodofM); 
  flopenrc #(1) EMRegFma10(clk, reset, PipeClearEM, PipeEnableEM, xzeroE, xzeroM); 
  flopenrc #(1) EMRegFma11(clk, reset, PipeClearEM, PipeEnableEM, yzeroE, yzeroM); 
  flopenrc #(1) EMRegFma12(clk, reset, PipeClearEM, PipeEnableEM, zzeroE, zzeroM); 
  flopenrc #(1) EMRegFma13(clk, reset, PipeClearEM, PipeEnableEM, xdenormE, xdenormM); 
  flopenrc #(1) EMRegFma14(clk, reset, PipeClearEM, PipeEnableEM, ydenormE, ydenormM); 
  flopenrc #(1) EMRegFma15(clk, reset, PipeClearEM, PipeEnableEM, zdenormE, zdenormM); 
  flopenrc #(1) EMRegFma16(clk, reset, PipeClearEM, PipeEnableEM, xinfE, xinfM); 
  flopenrc #(1) EMRegFma17(clk, reset, PipeClearEM, PipeEnableEM, yinfE, yinfM); 
  flopenrc #(1) EMRegFma18(clk, reset, PipeClearEM, PipeEnableEM, zinfE, zinfM); 
  flopenrc #(1) EMRegFma19(clk, reset, PipeClearEM, PipeEnableEM, xnanE, xnanM); 
  flopenrc #(1) EMRegFma20(clk, reset, PipeClearEM, PipeEnableEM, ynanE, ynanM); 
  flopenrc #(1) EMRegFma21(clk, reset, PipeClearEM, PipeEnableEM, znanE, znanM); 
  flopenrc #(1) EMRegFma22(clk, reset, PipeClearEM, PipeEnableEM, nanE, nanM); 
  flopenrc #(9) EMRegFma23(clk, reset, PipeClearEM, PipeEnableEM, sumshiftE, sumshiftM); 
  flopenrc #(1) EMRegFma24(clk, reset, PipeClearEM, PipeEnableEM, sumshiftzeroE, sumshiftzeroM); 
  flopenrc #(1) EMRegFma25(clk, reset, PipeClearEM, PipeEnableEM, prodinfE, prodinfM); 

  //*****************
  //fpadd E/M pipe registers
  //*****************
  flopenrc #(64) EMRegAdd1(clk, reset, PipeClearEM, PipeEnableEM, AddSumE, AddSumM); 
  flopenrc #(64) EMRegAdd2(clk, reset, PipeClearEM, PipeEnableEM, AddSumTcE, AddSumTcM); 
  flopenrc #(4)  EMRegAdd3(clk, reset, PipeClearEM, PipeEnableEM, AddSelInvE, AddSelInvM); 
  flopenrc #(11) EMRegAdd4(clk, reset, PipeClearEM, PipeEnableEM, AddExpPostSumE, AddExpPostSumM); 
  flopenrc #(1) EMRegAdd5(clk, reset, PipeClearEM, PipeEnableEM, AddCorrSignE, AddCorrSignM); 
  flopenrc #(1) EMRegAdd6(clk, reset, PipeClearEM, PipeEnableEM, AddOp1NormE, AddOp1NormM); 
  flopenrc #(1) EMRegAdd7(clk, reset, PipeClearEM, PipeEnableEM, AddOp2NormE, AddOp2NormM); 
  flopenrc #(1) EMRegAdd8(clk, reset, PipeClearEM, PipeEnableEM, AddOpANormE, AddOpANormM); 
  flopenrc #(1) EMRegAdd9(clk, reset, PipeClearEM, PipeEnableEM, AddOpBNormE, AddOpBNormM); 
  flopenrc #(1) EMRegAdd10(clk, reset, PipeClearEM, PipeEnableEM, AddInvalidE, AddInvalidM); 
  flopenrc #(1) EMRegAdd11(clk, reset, PipeClearEM, PipeEnableEM, AddDenormInE, AddDenormInM); 
  flopenrc #(1) EMRegAdd12(clk, reset, PipeClearEM, PipeEnableEM, AddConvertE, AddConvertM); 
  flopenrc #(1) EMRegAdd13(clk, reset, PipeClearEM, PipeEnableEM, AddSwapE, AddSwapM); 
  flopenrc #(1) EMRegAdd14(clk, reset, PipeClearEM, PipeEnableEM, AddNormOvflowE, AddNormOvflowM); 
  flopenrc #(1) EMRegAdd15(clk, reset, PipeClearEM, PipeEnableEM, AddSignAE, AddSignAM); 
  flopenrc #(64) EMRegAdd16(clk, reset, PipeClearEM, PipeEnableEM, AddFloat1E, AddFloat1M); 
  flopenrc #(64) EMRegAdd17(clk, reset, PipeClearEM, PipeEnableEM, AddFloat2E, AddFloat2M); 
  flopenrc #(12) EMRegAdd18(clk, reset, PipeClearEM, PipeEnableEM, AddExp1DenormE, AddExp1DenormM); 
  flopenrc #(12) EMRegAdd19(clk, reset, PipeClearEM, PipeEnableEM, AddExp2DenormE, AddExp2DenormM); 
  flopenrc #(11) EMRegAdd20(clk, reset, PipeClearEM, PipeEnableEM, AddExponentE, AddExponentM); 
  flopenrc #(3) EMRegAdd23(clk, reset, PipeClearEM, PipeEnableEM, AddRmE, AddRmM); 
  flopenrc #(4) EMRegAdd24(clk, reset, PipeClearEM, PipeEnableEM, AddOpTypeE, AddOpTypeM); 
  flopenrc #(1) EMRegAdd25(clk, reset, PipeClearEM, PipeEnableEM, AddPE, AddPM); 
  flopenrc #(1) EMRegAdd26(clk, reset, PipeClearEM, PipeEnableEM, AddOvEnE, AddOvEnM); 
  flopenrc #(1) EMRegAdd27(clk, reset, PipeClearEM, PipeEnableEM, AddUnEnE, AddUnEnM); 

  //*****************
  //fpcmp E/M pipe registers
  //*****************
  flopenrc #(8) EMRegCmp1(clk, reset, PipeClearEM, PipeEnableEM, WE, WM); 
  flopenrc #(8) EMRegCmp2(clk, reset, PipeClearEM, PipeEnableEM, XE, XM); 
  flopenrc #(1) EMRegcmp3(clk, reset, PipeClearEM, PipeEnableEM, ANaNE, ANaNM); 
  flopenrc #(1) EMRegCmp4(clk, reset, PipeClearEM, PipeEnableEM, BNaNE, BNaNM); 
  flopenrc #(1) EMRegCmp5(clk, reset, PipeClearEM, PipeEnableEM, AzeroE, AzeroM); 
  flopenrc #(1) EMRegCmp6(clk, reset, PipeClearEM, PipeEnableEM, BzeroE, BzeroM); 

  //put this in for the event we want to delay fsgn - will otherwise bypass
  //*****************
  //fpsgn E/M pipe registers
  //***************** 
  flopenrc #(64) EMRegSgn2(clk, reset, PipeClearEM, PipeEnableEM, SgnResultE, SgnResultM);
  flopenrc #(5) EMRegSgn3(clk, reset, PipeClearEM, PipeEnableEM, SgnFlagsE, SgnFlagsM);

  //*****************
  //other E/M pipe registers
  //*****************
  flopenrc #(1) EMReg1(clk, reset, PipeClearEM, PipeEnableEM, FWriteEnE, FWriteEnM);
  flopenrc #(3) EMReg2(clk, reset, PipeClearEM, PipeEnableEM, FResultSelE, FResultSelM);
  flopenrc #(3) EMReg3(clk, reset, PipeClearEM, PipeEnableEM, FrmE, FrmM);
  flopenrc #(1) EMReg4(clk, reset, PipeClearEM, PipeEnableEM, FmtE, FmtM);
  flopenrc #(5) EMReg5(clk, reset, PipeClearEM, PipeEnableEM, RdE, RdM);
  flopenrc #(4) EMReg6(clk, reset, PipeClearEM, PipeEnableEM, FOpCtrlE, FOpCtrlM);
  flopenrc #(1) EMReg7(clk, reset, PipeClearEM, PipeEnableEM, FWriteIntE, FWriteIntM);
  flopenrc #(2) EMReg8(clk, reset, PipeClearEM, PipeEnableEM, FMemRWE, FMemRWM);










  //BEGIN MEMORY STAGE

  assign FWriteDataM = FInput1M;

  mux2  #(64)  FLoadStoreResultMux(HRDATA, FInput1M, |FOpCtrlM[2:1], FLoadStoreResultM);

  fma2 fma2(.*);

  //second instance of two-stage floating-point add/cvt unit
  fpuaddcvt2 fpadd2 (.*);

  //second instance of two-stage floating-point comparator
  fpucmp2 fpcmp2 (CmpInvalidM, CmpFCCM, ANaNM, BNaNM, AzeroM, BzeroM, WM, XM, {1'b0, FmtM}, FInput1M, FInput2M);










  
  //*****************
  //fma M/W pipe registers
  //*****************
  flopenrc #(64) MWRegFma1(clk, reset, PipeClearMW, PipeEnableMW, FmaResultM, FmaResultW); 
  flopenrc #(5) MWRegFma2(clk, reset, PipeClearMW, PipeEnableMW, FmaFlagsM, FmaFlagsW); 

  //*****************
  //fpdiv M/W pipe registers
  //*****************
  flopenrc #(64) MWRegDiv1(clk, reset, PipeClearMW, PipeEnableMW, FDivResultM, FDivResultW); 
  flopenrc #(5) MWRegDiv2(clk, reset, PipeClearMW, PipeEnableMW, FDivFlagsM, FDivFlagsW);
  flopenrc #(1) MWRegDiv3(clk, reset, PipeClearMW, PipeEnableMW, DivDenormM, DivDenormW); 

  //*****************
  //fpadd M/W pipe registers
  //*****************
  flopenrc #(64) MWRegAdd1(clk, reset, PipeClearMW, PipeEnableMW, FAddResultM, FAddResultW); 
  flopenrc #(5) MWRegAdd2(clk, reset, PipeClearMW, PipeEnableMW, FAddFlagsM, FAddFlagsW); 

  //*****************
  //fpcmp M/W pipe registers
  //*****************
  flopenrc #(1) MWRegCmp1(clk, reset, PipeClearMW, PipeEnableMW, CmpInvalidM, CmpInvalidW); 
  flopenrc #(2) MWRegCmp2(clk, reset, PipeClearMW, PipeEnableMW, CmpFCCM, CmpFCCW); 

  //*****************
  //fpsgn M/W pipe registers
  //***************** 
  flopenrc #(64) MWRegSgn1(clk, reset, PipeClearMW, PipeEnableMW, SgnResultM, SgnResultW);
  flopenrc #(5) MWRegSgn2(clk, reset, PipeClearMW, PipeEnableMW, SgnFlagsM, SgnFlagsW);

  //*****************
  //other M/W pipe registers
  //*****************
  flopenrc #(1) MWReg1(clk, reset, PipeClearMW, PipeEnableMW, FWriteEnM, FWriteEnW);
  flopenrc #(3) MWReg2(clk, reset, PipeClearMW, PipeEnableMW, FResultSelM, FResultSelW);
  flopenrc #(1) MWReg3(clk, reset, PipeClearMW, PipeEnableMW, FmtM, FmtW);
  flopenrc #(5) MWReg4(clk, reset, PipeClearMW, PipeEnableMW, RdM, RdW);
  flopenrc #(`XLEN) MWReg5(clk, reset, PipeClearMW, PipeEnableMW, SrcAM, SrcAW);
  flopenrc #(64) MWReg6(clk, reset, PipeClearMW, PipeEnableMW, FLoadStoreResultM, FLoadStoreResultW);
  flopenrc #(1) MWReg7(clk, reset, PipeClearMW, PipeEnableMW, FWriteIntM, FWriteIntW);










  //#########################################
  //BEGIN WRITEBACK STAGE
  //#########################################

  always_comb begin
	case (FResultSelW)
		// div/sqrt
		3'b000 : FPUFlagsW = FDivFlagsW;
		// cmp		
		3'b001 : FPUFlagsW = {CmpInvalidW, 4'b0};
		//fma/mult
		3'b010 : FPUFlagsW = FmaFlagsW;
		// sgn inj
		3'b011 : FPUFlagsW = SgnFlagsW;
		// add/sub/cnvt
		3'b100 : FPUFlagsW = FAddFlagsW;
		// classify
		3'b101 : FPUFlagsW = ClassFlagsW;
		// output SrcAW
		3'b110 : FPUFlagsW = 5'b0;
		// output FRD1
		3'b111 : FPUFlagsW = 5'b0;
		default : FPUFlagsW = 5'bxxxxx;
	endcase
  end


  always_comb begin
	case (FResultSelW)
		// div/sqrt
		3'b000 : FPUResult64W = FDivResultW;
		// cmp		
		3'b001 : FPUResult64W = FCmpResultW;
		//fma/mult
		3'b010 : FPUResult64W = FmaResultW;
		// sgn inj
		3'b011 : FPUResult64W = SgnResultW;
		// add/sub/cnvt
		3'b100 : FPUResult64W = FAddResultW;
		// classify
		3'b101 : FPUResult64W = ClassResultW;
		// output SrcAW
		3'b110 : FPUResult64W = SrcAW;
		// Load/Store/Move to FP-register
		3'b111 : FPUResult64W = FLoadStoreResultW;
		default : FPUResult64W = {64{1'bx}};
	endcase
  end
  //interface between XLEN size datapath and double-precision sized
  //floating-point results
  //
  //define offsets for LSB zero extension or truncation
  always_comb begin
           
  //zero extension 
      FPUResultW = FPUResult64W[63:64-`XLEN];
      SetFflagsM = FPUFlagsW;

  end  
endmodule

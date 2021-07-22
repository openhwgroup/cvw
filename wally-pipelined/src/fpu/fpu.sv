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
  input logic 		   clk,
  input logic 		   reset,
  input logic [2:0] 	   FRM_REGW, // Rounding mode from CSR
  input logic [31:0] 	   InstrD,
  input logic [`XLEN-1:0]  ReadDataW, // Read data from memory
  input logic [`XLEN-1:0]  SrcAE, // Integer input being processed
  input logic [`XLEN-1:0]  SrcAM, // Integer input being written into fpreg
  input logic 		   StallE, StallM, StallW,
  input logic 		   FlushE, FlushM, FlushW,
  input logic [4:0] 	   RdE, RdM, RdW, 
  output logic 		   FRegWriteM,
  output logic 		   FStallD, // Stall the decode stage
  output logic 		   FWriteIntE, FWriteIntM, FWriteIntW, // Write integer register enable
  output logic [`XLEN-1:0] FWriteDataE, // Data to be written to memory
  output logic [`XLEN-1:0] FIntResM, 
  output logic 		   FDivBusyE, // Is the divison/sqrt unit busy
  output logic 		   IllegalFPUInstrD, // Is the instruction an illegal fpu instruction
  output logic [4:0] 	   SetFflagsM);      // FPU result
// *** change FMA to do 16 - 32 - 64 - 128 FEXPBITS 
// *** folder at same level of src for tests fpu tests
// qa.b
// u1.52 - u sunsigned, q signed
  generate
     if (`F_SUPPORTED | `D_SUPPORTED) begin 
      // control logic signal instantiation
	logic 		   FRegWriteD, FRegWriteE, FRegWriteW;                 // FP register write enable
	logic [2:0] 	   FrmD, FrmE, FrmM;                                   // FP rounding mode
	logic 		   FmtD, FmtE, FmtM, FmtW;                             // FP precision 0-single 1-double
	logic 		   FDivStartD, FDivStartE;                             // Start division
	logic 		   FWriteIntD;                                         // Write to integer register
	logic [1:0] 	   FForwardXE, FForwardYE, FForwardZE;                 // Input3 forwarding mux control signal
	logic [2:0] 	   FResultSelD, FResultSelE, FResultSelM, FResultSelW; // Select FP result
	logic [3:0] 	   FOpCtrlD, FOpCtrlE, FOpCtrlM;                       // Select which opperation to do in each component
	logic [1:0] 	   FResSelD, FResSelE, FResSelM;  
	logic [1:0] 	   FIntResSelD, FIntResSelE, FIntResSelM;                                   
	logic [4:0] 	   Adr1E, Adr2E, Adr3E;
	
	// regfile signals
	logic [63:0] 	   FRD1D, FRD2D, FRD3D;                                // Read Data from FP register - decode stage
	logic [63:0] 	   FRD1E, FRD2E, FRD3E;                                // Read Data from FP register - execute stage
	logic [`XLEN-1:0]  FSrcXMAligned;
	logic [63:0] 	   FSrcXE, FSrcXM;                                     // Input 1 to the various units (after forwarding)
	logic [63:0] 	   FSrcYE;                                             // Input 2 to the various units (after forwarding)
	logic [63:0] 	   FSrcZE;                                             // Input 3 to the various units (after forwarding)
	
	// unpacking signals
	logic 		   XSgnE, YSgnE, ZSgnE;
	logic [10:0] 	   XExpE, YExpE, ZExpE;
	logic [52:0] 	   XManE, YManE, ZManE;
	logic 		   XNaNE, YNaNE, ZNaNE;
	logic 		   XSNaNE, YSNaNE, ZSNaNE;
	logic 		   XDenormE, YDenormE, ZDenormE;
	logic 		   XZeroE, YZeroE, ZZeroE;
	logic [10:0] 	   BiasE;
	logic 		   XInfE, YInfE, ZInfE;
	logic 		   XExpMaxE;
	logic 		   XNormE;
	
	logic 		   XSgnM, YSgnM, ZSgnM;
	logic [10:0] 	   XExpM, YExpM, ZExpM;
	logic [52:0] 	   XManM, YManM, ZManM;
	logic 		   XNaNM, YNaNM, ZNaNM;
	logic 		   XSNaNM, YSNaNM, ZSNaNM;
	logic 		   XZeroM, YZeroM, ZZeroM;
	logic 		   XInfM, YInfM, ZInfM;
	
	// div/sqrt signals
	logic [63:0] 	   FDivResultM, FDivResultW;
	logic [4:0] 	   FDivSqrtFlgM, FDivSqrtFlgW;
	logic 		   FDivSqrtDoneE;
	logic [63:0] 	   DivInput1E, DivInput2E;
	logic 		   HoldInputs;                                              // keep forwarded inputs arround durring division
	
	//fpu signals
	logic [63:0] 	   FMAResM, FMAResW;
	logic [4:0] 	   FMAFlgM, FMAFlgW;
	
	logic [63:0] 	   ReadResW;
	
	// add/cvt signals
	logic [63:0] 	   FAddResM, FAddResW;
	logic [4:0] 	   FAddFlgM, FAddFlgW;  
	logic [63:0] 	   CvtResE, CvtResM;
	logic [4:0] 	   CvtFlgE, CvtFlgM;  
	
	// cmp signals 
	logic 		   CmpNVE, CmpNVM, CmpNVW;
	logic [63:0] 	   CmpResE, CmpResM, CmpResW;
	
	// fsgn signals
	logic [63:0] 	   SgnResE, SgnResM;
	logic 		   SgnNVE, SgnNVM, SgnNVW;
	logic [63:0] 	   FResM, FResW;
	logic [4:0] 	   FFlgM, FFlgW;
	
	// instantiation of W stage regfile signals
	logic [63:0] 	   AlignedSrcAM;
	
	// classify signals
	logic [63:0] 	   ClassResE, ClassResM;
	
	// 64-bit FPU result   
	logic [63:0] 	   FPUResultW;                                           
	logic [4:0] 	   FPUFlagsW;
	
	//DECODE STAGE
	
	// top-level controller for FPU
	fctrl fctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]), 
                     .FRM_REGW, .IllegalFPUInstrD, .FRegWriteD, .FDivStartD, .FResultSelD, .FOpCtrlD, .FResSelD, 
                     .FIntResSelD, .FmtD, .FrmD, .FWriteIntD);
	
	// regfile instantiation
	fregfile fregfile (clk, reset, FRegWriteW,
			   InstrD[19:15], InstrD[24:20], InstrD[31:27], RdW,
			   FPUResultW,
			   FRD1D, FRD2D, FRD3D);	
	
	//*****************
	// D/E pipe registers
	//*****************
	flopenrc #(64) DEReg1(clk, reset, FlushE, ~StallE, FRD1D, FRD1E);
	flopenrc #(64) DEReg2(clk, reset, FlushE, ~StallE, FRD2D, FRD2E);
	flopenrc #(64) DEReg3(clk, reset, FlushE, ~StallE, FRD3D, FRD3E);
	flopenrc #(1) DECtrlRegE1(clk, reset, FlushE, ~StallE, FDivStartD, FDivStartE);
	flopenrc #(15) DECtrlRegE2(clk, reset, FlushE, ~StallE, {InstrD[19:15], InstrD[24:20], InstrD[31:27]}, 
                                   {Adr1E,         Adr2E,         Adr3E});
	flopenrc #(17) DECtrlReg3(clk, reset, FlushE, ~StallE, 
				  {FRegWriteD, FResultSelD, FResSelD, FIntResSelD, FrmD, FmtD, FOpCtrlD, FWriteIntD},
				  {FRegWriteE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, FOpCtrlE, FWriteIntE});
	
	//EXECUTION STAGE
	
	// Hazard unit for FPU
	fhazard fhazard(.Adr1E, .Adr2E, .Adr3E, .FRegWriteM, .FRegWriteW, .RdM, .RdW, .FResultSelM, .FStallD, 
                        .FForwardXE, .FForwardYE, .FForwardZE);
	
	// forwarding muxs
	mux3  #(64)  fxemux(FRD1E, FPUResultW, FResM, FForwardXE, FSrcXE);
	mux3  #(64)  fyemux(FRD2E, FPUResultW, FResM, FForwardYE, FSrcYE);
	mux3  #(64)  fzemux(FRD3E, FPUResultW, FResM, FForwardZE, FSrcZE);
	
	unpacking unpacking(.X(FSrcXE), .Y(FSrcYE), .Z(FSrcZE), 
			    .FOpCtrlE(FOpCtrlE[2:0]), .FmtE, .XSgnE, .YSgnE, 
			    .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE, 
			    .XNaNE, .YNaNE, .ZNaNE, 
			    .XSNaNE, .YSNaNE, .ZSNaNE, .XDenormE, .YDenormE, .ZDenormE, 
			    .XZeroE, .YZeroE, .ZZeroE, .BiasE, .XInfE, .YInfE, .ZInfE, .XExpMaxE, .XNormE);
      // first of two-stage instance of floating-point fused multiply-add unit
	fma fma (.clk, .reset, .FlushM, .StallM, 
		 .XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .
		 ZManE, .XDenormE, .YDenormE, 
		 .ZDenormE, .XZeroE, .YZeroE, .ZZeroE, .BiasE, 
		 .XSgnM, .YSgnM, .ZSgnM, .XExpM, .YExpM, .ZExpM, .XManM, 
		 .YManM, .ZManM, .XNaNM, .YNaNM, .ZNaNM, .XZeroM, .YZeroM, .ZZeroM, .XInfM, .YInfM, .ZInfM, .XSNaNM, .YSNaNM, .ZSNaNM,
		 //  .FSrcXE, .FSrcYE, .FSrcZE, .FSrcXM, .FSrcYM, .FSrcZM, 
		 .FOpCtrlE(FOpCtrlE[2:0]), .FOpCtrlM(FOpCtrlM[2:0]), 
		 .FmtE, .FmtM, .FrmM, .FMAFlgM, .FMAResM);
	
	// first and only instance of floating-point divider
	logic 		   fpdivClk;
	
	clockgater fpdivclkg(.E(FDivStartE),
			     .SE(1'b0),
			     .CLK(clk),
			     .ECLK(fpdivClk));
	
	// capture the inputs for div/sqrt	 
	flopenrc #(64) reg_input1 (.d(FSrcXE), .q(DivInput1E),
				   .en(1'b1), .clear(FDivSqrtDoneE),
				   .reset(reset),  .clk(HoldInputs));
	flopenrc #(64) reg_input2 (.d(FSrcYE), .q(DivInput2E),
				   .en(1'b1), .clear(FDivSqrtDoneE),
				   .reset(reset),  .clk(HoldInputs));
	//*** add round to nearest ties to max magnitude
	fpdiv fdivsqrt (.op1(DivInput1E), .op2(DivInput2E), .done(FDivSqrtDoneE), .rm(FrmE[1:0]), .op_type(FOpCtrlE[0]), 
			.P(~FmtE), .FDivBusyE, .HoldInputs, 
			.OvEn(1'b1), .UnEn(1'b1),
			.start(FDivStartE), .reset, .clk(fpdivClk), .AS_Result(FDivResultM), .Flags(FDivSqrtFlgM));
	
        // .DivOpType(FOpCtrlE[0]), .clk(fpdivClk), .FmtE(~FmtE), .DivInput1E, .DivInput2E, 
        //                 .FrmE, .DivOvEn(1'b1), .DivUnEn(1'b1), .FDivStartE, .FDivResultM, .FDivSqrtFlgM, 
        //                 .FDivSqrtDoneE, .FDivBusyE, .HoldInputs, .reset);
	// assign FDivBusyE = 0;
	
	// first of two-stage instance of floating-point add/cvt unit
	faddcvt faddcvt (.clk, .reset, .FlushM, .StallM, .FrmM, .FOpCtrlM, .FmtE, .FmtM,
                         .FSrcXE, .FSrcYE, .FOpCtrlE, .FAddResM, .FAddFlgM);
	
	// first and only instance of floating-point comparator
	fcmp fcmp (.op1({XSgnE,XExpE,XManE[`NF-1:0]}), .op2({YSgnE,YExpE,YManE[`NF-1:0]}), .FSrcXE, 
		   .FSrcYE, .FOpCtrlE(FOpCtrlE[2:0]), .FmtE, 
		   .Invalid(CmpNVE), .CmpResE, .XNaNE, .YNaNE, .XZeroE, .YZeroE);
	
	// first and only instance of floating-point sign converter
	fsgn fsgn (.SgnOpCodeE(FOpCtrlE[1:0]), .XSgnE, .YSgnE, .FSrcXE, .FmtE, .SgnResE, .SgnNVE, .XExpMaxE);

	// first and only instance of floating-point classify unit
	fclassify fclassify (.XSgnE, .XDenormE, .XZeroE, .XNaNE, .XInfE, .XNormE, .XSNaNE, .ClassResE);
	
	fcvt fcvt (.XSgnE, .XExpE, .XManE, .XZeroE, .XNaNE, .XInfE, .XDenormE, .BiasE, .SrcAE, .FOpCtrlE, .FmtE, .FrmE, .CvtResE, .CvtFlgE);
	
	// output for store instructions
	assign FWriteDataE = FSrcYE[`XLEN-1:0];
	
	//*****************
	// E/M pipe registers
	//*****************
	flopenrc #(64) EMFpReg1(clk, reset, FlushM, ~StallM, FSrcXE, FSrcXM);
	// flopenrc #(64) EMFpReg2(clk, reset, FlushM, ~StallM, FSrcYE, FSrcYM);
	// flopenrc #(64) EMFpReg3(clk, reset, FlushM, ~StallM, FSrcZE, FSrcZM);
	flopenrc #(65) EMFpReg4(clk, reset, FlushM, ~StallM, {XSgnE,XExpE,XManE}, {XSgnM,XExpM,XManM});
	flopenrc #(65) EMFpReg5(clk, reset, FlushM, ~StallM, {YSgnE,YExpE,YManE}, {YSgnM,YExpM,YManM});
	flopenrc #(65) EMFpReg6(clk, reset, FlushM, ~StallM, {ZSgnE,ZExpE,ZManE}, {ZSgnM,ZExpM,ZManM});
	flopenrc #(12) EMFpReg7(clk, reset, FlushM, ~StallM, 
				{XZeroE, YZeroE, ZZeroE, XInfE, YInfE, ZInfE, XNaNE, YNaNE, ZNaNE, XSNaNE, YSNaNE, ZSNaNE},
				{XZeroM, YZeroM, ZZeroM, XInfM, YInfM, ZInfM, XNaNM, YNaNM, ZNaNM, XSNaNM, YSNaNM, ZSNaNM});
	
	flopenrc #(1)  EMRegCmp1(clk, reset, FlushM, ~StallM, CmpNVE, CmpNVM); 
	flopenrc #(64) EMRegCmp2(clk, reset, FlushM, ~StallM, CmpResE, CmpResM); 
	
	flopenrc #(64) EMRegSgn1(clk, reset, FlushM, ~StallM, SgnResE, SgnResM);
	flopenrc #(1) EMRegSgn2(clk, reset, FlushM, ~StallM, SgnNVE, SgnNVM);
	
	flopenrc #(64) EMRegCvt1(clk, reset, FlushM, ~StallM, CvtResE, CvtResM);
	flopenrc #(5) EMRegCvt2(clk, reset, FlushM, ~StallM, CvtFlgE, CvtFlgM);
	
	flopenrc #(17) EMCtrlReg(clk, reset, FlushM, ~StallM,
				 {FRegWriteE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, FOpCtrlE, FWriteIntE},
				 {FRegWriteM, FResultSelM, FResSelM, FIntResSelM, FrmM, FmtM, FOpCtrlM, FWriteIntM});
	
	flopenrc #(64) EMRegClass(clk, reset, FlushM, ~StallM, ClassResE, ClassResM);
	
	//BEGIN MEMORY STAGE
	mux4  #(64)  FResMux(AlignedSrcAM, SgnResM, CmpResM, CvtResM, FResSelM, FResM);
	mux4  #(5)  FFlgMux(5'b0, {4'b0, SgnNVM}, {4'b0, CmpNVM}, CvtFlgM, FResSelM, FFlgM);
	
	// mux2  #(`XLEN)  FSrcXAlignedMux({{`XLEN-32{1'b0}}, FSrcXM[63:32]}, FSrcXM[63:64-`XLEN], FmtM, FSrcXMAligned);
	mux4  #(`XLEN)  IntResMux(CmpResM[`XLEN-1:0], FSrcXM[`XLEN-1:0], ClassResM[`XLEN-1:0], CvtResM[`XLEN-1:0], FIntResSelM, FIntResM);
	
	// Align SrcA to MSB when single precicion
	mux2  #(64)  SrcAMux({{32{1'b1}}, SrcAM[31:0]}, {{64-`XLEN{1'b1}}, SrcAM}, FmtM, AlignedSrcAM);
	mux5  #(5)  FPUFlgMux(5'b0, FMAFlgM, FAddFlgM, FDivSqrtFlgM, FFlgM, FResultSelW, SetFflagsM);
	
	//*****************
	// M/W pipe registers
	//*****************
	flopenrc #(64) MWRegFma1(clk, reset, FlushW, ~StallW, FMAResM, FMAResW); 
	flopenrc #(64) MWRegDiv1(clk, reset, FlushW, ~StallW, FDivResultM, FDivResultW); 
	flopenrc #(64) MWRegAdd1(clk, reset, FlushW, ~StallW, FAddResM, FAddResW); 
	flopenrc #(64) MWRegCmp3(clk, reset, FlushW, ~StallW, CmpResM, CmpResW);
	flopenrc #(64) MWRegClass2(clk, reset, FlushW, ~StallW, FResM, FResW);
	flopenrc #(6) MWCtrlReg(clk, reset, FlushW, ~StallW,
				{FRegWriteM, FResultSelM, FmtM, FWriteIntM},
				{FRegWriteW, FResultSelW, FmtW, FWriteIntW});
	
	//#########################################
	// BEGIN WRITEBACK STAGE
	//#########################################
	mux2  #(64)  ReadResMux({{32{1'b1}}, ReadDataW[31:0]}, {{64-`XLEN{1'b1}}, ReadDataW}, FmtW, ReadResW);
	mux5  #(64)  FPUResultMux(ReadResW, FMAResW, FAddResW, FDivResultW, FResW, FResultSelW, FPUResultW);
	
	
     end else begin // no F_SUPPORTED; tie outputs low
	assign FStallD = 0;
	assign FWriteIntE = 0; 
	assign FWriteIntM = 0;
	assign FWriteIntW = 0;
	assign FWriteDataE = 0;
	assign FIntResM = 0;
	assign FDivBusyE = 0;
	assign IllegalFPUInstrD = 1;
	assign SetFflagsM = 0;
     end
  endgenerate 
   
endmodule // fpu

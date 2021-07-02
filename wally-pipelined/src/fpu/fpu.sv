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
  output logic 		      FStallD,    // Stall the decode stage
  output logic 		      FWriteIntE, FWriteIntM, FWriteIntW, // Write integer register enable
  output logic [`XLEN-1:0] FWriteDataE,      // Data to be written to memory
  output logic [`XLEN-1:0] FIntResM,     
  output logic 		      FDivBusyE,        // Is the divison/sqrt unit busy
  output logic 		      IllegalFPUInstrD, // Is the instruction an illegal fpu instruction
  output logic [4:0] 	   SetFflagsM,       // FPU flags
  output logic [`XLEN-1:0] FPUResultW);      // FPU result
// *** change FMA to do 16 - 32 - 64 - 128 FEXPBITS 
   // control logic signal instantiation
   logic 		   FWriteEnD, FWriteEnE, FWriteEnM, FWriteEnW;              // FP register write enable
   logic [2:0] 	FrmD, FrmE, FrmM;                                  // FP rounding mode
   logic 		   FmtD, FmtE, FmtM, FmtW;                                  // FP precision 0-single 1-double
   logic 		   FDivStartD, FDivStartE;                                  // Start division
   logic 		   FWriteIntD;                                              // Write to integer register
   logic [1:0]    ForwardXE, ForwardYE, ForwardZE;                        // Input3 forwarding mux control signal
   logic [2:0] 	FResultSelD, FResultSelE, FResultSelM, FResultSelW;      // Select FP result
   logic [3:0] 	FOpCtrlD, FOpCtrlE, FOpCtrlM;                  // Select which opperation to do in each component
   logic [1:0]    FResSelD, FResSelE, FResSelM;  
   logic [1:0]    FIntResSelD, FIntResSelE, FIntResSelM;                                   
   logic [4:0] 	Adr1E, Adr2E, Adr3E;
   
   // regfile signals
   logic [4:0]    RdE, RdM, RdW;                                           // what adress to write to    // ***Can take from ieu insted of pipelining
   logic [63:0] 	FRD1D, FRD2D, FRD3D;                                     // Read Data from FP register - decode stage
   logic [63:0] 	FRD1E, FRD2E, FRD3E;                                     // Read Data from FP register - execute stage
   logic [`XLEN-1:0]   SrcXMAligned;
   logic [63:0] 	SrcXE, SrcXM;                         // Input 1 to the various units (after forwarding)
   logic [63:0] 	SrcYE, SrcYM;                                      // Input 2 to the various units (after forwarding)
   logic [63:0] 	SrcZE, SrcZM;                                      // Input 3 to the various units (after forwarding)
   
   // div/sqrt signals
   logic [63:0] 	FDivResultM, FDivResultW;
   logic [4:0]    FDivSqrtFlgM, FDivSqrtFlgW;
   logic          FDivSqrtDoneE;
   logic [63:0] 	DivInput1E, DivInput2E;
   logic          HoldInputs;                                              // keep forwarded inputs arround durring division
   
   // FMA signals
	logic [105:0]	ProdManE, ProdManM; ///*** put pipline stages in units
	logic [161:0]	AlignedAddendE, AlignedAddendM;                       
	logic [12:0]	ProdExpE, ProdExpM;
	logic 			AddendStickyE, AddendStickyM;
	logic 			KillProdE, KillProdM;
	logic				XZeroE, YZeroE, ZZeroE, XZeroM, YZeroM, ZZeroM;
	logic				XInfE, YInfE, ZInfE, XInfM, YInfM, ZInfM;
	logic				XNaNE, YNaNE, ZNaNE, XNaNM, YNaNM, ZNaNM;
   logic [63:0]   FMAResM, FMAResW;
   logic [4:0]    FMAFlgM, FMAFlgW;

   // add/cvt signals
   logic [63:0] 	AddSumE, AddSumM;
   logic [63:0]   AddSumTcE, AddSumTcM;
   logic [3:0] 	AddSelInvE, AddSelInvM;
   logic [10:0] 	AddExpPostSumE,AddExpPostSumM;
   logic 		   AddCorrSignE, AddCorrSignM;
   logic          AddOp1NormE, AddOp1NormM;
   logic          AddOp2NormE, AddOp2NormM;
   logic          AddOpANormE,  AddOpANormM;
   logic          AddOpBNormE, AddOpBNormM;
   logic          AddInvalidE, AddInvalidM;
   logic 		   AddDenormInE, AddDenormInM;
   logic          AddSwapE, AddSwapM;
   logic          AddNormOvflowE, AddNormOvflowM; //***this isn't used in addcvt2
   logic          AddSignAE, AddSignAM;
   logic 		   AddConvertE, AddConvertM;
   logic [63:0] 	AddFloat1E, AddFloat2E, AddFloat1M, AddFloat2M;
   logic [11:0] 	AddExp1DenormE, AddExp2DenormE, AddExp1DenormM, AddExp2DenormM;
   logic [10:0] 	AddExponentE, AddExponentM;
   logic [63:0] 	FAddResM, FAddResW;
   logic [4:0] 	FAddFlgM, FAddFlgW;  
   
   // cmp signals 
   logic 		   CmpNVE, CmpNVM, CmpNVW;
   logic [63:0] 	CmpResE, CmpResM, CmpResW;
   
   // fsgn signals
   logic [63:0] 	SgnResE, SgnResM;
   logic        	SgnNVE, SgnNVM, SgnNVW;
   logic [63:0]   FResM, FResW;
   logic          FFlgM, FFlgW;
   
   // instantiation of W stage regfile signals
   logic [63:0] 	AlignedSrcAM;
   
   // classify signals
   logic [63:0] 	ClassResE, ClassResM;
   
   // 64-bit FPU result   
   logic [63:0] 	FPUResult64W;                                           
   logic [4:0] 	FPUFlagsW;
   
   







   //DECODE STAGE
   
   
   // top-level controller for FPU
   fctrl fctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]), 
               .FRM_REGW, .IllegalFPUInstrD, .FWriteEnD, .FDivStartD, .FResultSelD, .FOpCtrlD, .FResSelD, 
               .FIntResSelD, .FmtD, .FrmD, .FWriteIntD);
   
   // regfile instantiation
   fregfile fregfile (clk, reset, FWriteEnW,
			InstrD[19:15], InstrD[24:20], InstrD[31:27], RdW,
			FPUResult64W,
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
   flopenrc #(22) DECtrlReg3(clk, reset, FlushE, ~StallE, 
                        {FWriteEnD, FResultSelD, FResSelD, FIntResSelD, FrmD, FmtD, InstrD[11:7], FOpCtrlD, FWriteIntD},
                        {FWriteEnE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, RdE,          FOpCtrlE, FWriteIntE});














   //EXECUTION STAGE
   
   // Hazard unit for FPU
   fhazard fhazard(.Adr1E, .Adr2E, .Adr3E, .FWriteEnM, .FWriteEnW, .RdM, .RdW, .FResultSelM, .FStallD, 
                     .ForwardXE, .ForwardYE, .ForwardZE);

   // forwarding muxs
   mux3  #(64)  fxemux(FRD1E, FPUResult64W, FResM, ForwardXE, SrcXE);
   mux3  #(64)  fyemux(FRD2E, FPUResult64W, FResM, ForwardYE, SrcYE);
   mux3  #(64)  fzemux(FRD3E, FPUResult64W, FResM, ForwardZE, SrcZE);

   
   // first of two-stage instance of floating-point fused multiply-add unit
   fma1 fma1 (.X(SrcXE), .Y(SrcYE), .Z(SrcZE), .FOpCtrlE(FOpCtrlE[2:0]), .FmtE, .ProdManE, .AlignedAddendE,
               .ProdExpE, .AddendStickyE, .KillProdE, .XZeroE, .YZeroE, .ZZeroE, .XInfE, .YInfE, .ZInfE,
               .XNaNE, .YNaNE, .ZNaNE );
   
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

   fdivsqrt fdivsqrt (.DivOpType(FOpCtrlE[0]), .clk(fpdivClk), .FmtE(~FmtE), .DivInput1E, .DivInput2E, 
                     .FrmE, .DivOvEn(1'b1), .DivUnEn(1'b1), .FDivStartE, .FDivResultM, .FDivSqrtFlgM, 
                     .FDivSqrtDoneE, .FDivBusyE, .HoldInputs, .reset);
   


   // first of two-stage instance of floating-point add/cvt unit
   fpuaddcvt1 fpadd1 (.SrcXE, .SrcYE, .FOpCtrlE, .FmtE, .AddFloat1E, .AddFloat2E, .AddExponentE, 
                     .AddExpPostSumE, .AddExp1DenormE, .AddExp2DenormE, .AddSumE, .AddSumTcE, .AddSelInvE, 
                     .AddCorrSignE, .AddSignAE, .AddOp1NormE, .AddOp2NormE, .AddOpANormE, .AddOpBNormE, .AddInvalidE, 
                     .AddDenormInE, .AddConvertE, .AddSwapE, .AddNormOvflowE);
   
   // first and only instance of floating-point comparator
   fcmp fcmp (SrcXE, SrcYE, FOpCtrlE[2:0], FmtE, CmpNVE, CmpResE);
   
   // first and only instance of floating-point sign converter
   fsgn fsgn (.SgnOpCodeE(FOpCtrlE[1:0]), .SrcXE, .SrcYE, .SgnResE, .SgnNVE);
   
   // first and only instance of floating-point classify unit
   fclassify fclassify (.SrcXE, .FmtE, .ClassResE);

   // output for store instructions
   assign FWriteDataE = FmtE ? SrcYE[63:64-`XLEN] : {{`XLEN-32{1'b0}}, SrcYE[63:32]};
   //***swap to mux










   //*****************
   // E/M pipe registers
   //*****************
   flopenrc #(64) EMFpReg1(clk, reset, FlushM, ~StallM, SrcXE, SrcXM);
   flopenrc #(64) EMFpReg2(clk, reset, FlushM, ~StallM, SrcYE, SrcYM);
   flopenrc #(64) EMFpReg3(clk, reset, FlushM, ~StallM, SrcZE, SrcZM);
   
   flopenrc #(106) EMRegFma1(clk, reset, FlushM, ~StallM, ProdManE, ProdManM); 
   flopenrc #(162) EMRegFma2(clk, reset, FlushM, ~StallM, AlignedAddendE, AlignedAddendM); 
   flopenrc #(13) EMRegFma3(clk, reset, FlushM, ~StallM, ProdExpE, ProdExpM);  
   flopenrc #(11) EMRegFma4(clk, reset, FlushM, ~StallM, 
                              {AddendStickyE, KillProdE, XZeroE, YZeroE, ZZeroE, XInfE, YInfE, ZInfE, XNaNE, YNaNE, ZNaNE},
                              {AddendStickyM, KillProdM, XZeroM, YZeroM, ZZeroM, XInfM, YInfM, ZInfM, XNaNM, YNaNM, ZNaNM});

   flopenrc #(64) EMRegAdd1(clk, reset, FlushM, ~StallM, AddSumE, AddSumM); 
   flopenrc #(64) EMRegAdd2(clk, reset, FlushM, ~StallM, AddSumTcE, AddSumTcM); 
   flopenrc #(11) EMRegAdd3(clk, reset, FlushM, ~StallM, AddExpPostSumE, AddExpPostSumM); 
   flopenrc #(64) EMRegAdd4(clk, reset, FlushM, ~StallM, AddFloat1E, AddFloat1M); 
   flopenrc #(64) EMRegAdd5(clk, reset, FlushM, ~StallM, AddFloat2E, AddFloat2M); 
   flopenrc #(12) EMRegAdd6(clk, reset, FlushM, ~StallM, AddExp1DenormE, AddExp1DenormM); 
   flopenrc #(12) EMRegAdd7(clk, reset, FlushM, ~StallM, AddExp2DenormE, AddExp2DenormM); 
   flopenrc #(11) EMRegAdd8(clk, reset, FlushM, ~StallM, AddExponentE, AddExponentM);
   flopenrc #(15) EMRegAdd9(clk, reset, FlushM, ~StallM, 
                           {AddSelInvE, AddCorrSignE, AddOp1NormE, AddOp2NormE, AddOpANormE, AddOpBNormE, AddInvalidE, AddDenormInE, AddConvertE, AddSwapE, AddNormOvflowE, AddSignAE},
                           {AddSelInvM, AddCorrSignM, AddOp1NormM, AddOp2NormM, AddOpANormM, AddOpBNormM, AddInvalidM, AddDenormInM, AddConvertM, AddSwapM, AddNormOvflowM, AddSignAM}); 

   flopenrc #(1)  EMRegCmp1(clk, reset, FlushM, ~StallM, CmpNVE, CmpNVM); 
   flopenrc #(64) EMRegCmp2(clk, reset, FlushM, ~StallM, CmpResE, CmpResM); 
   
   flopenrc #(64) EMRegSgn1(clk, reset, FlushM, ~StallM, SgnResE, SgnResM);
   flopenrc #(1) EMRegSgn2(clk, reset, FlushM, ~StallM, SgnNVE, SgnNVM);
   
   flopenrc #(22) EMCtrlReg(clk, reset, FlushM, ~StallM,
                        {FWriteEnE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, RdE, FOpCtrlE, FWriteIntE},
                        {FWriteEnM, FResultSelM, FResSelM, FIntResSelM, FrmM, FmtM, RdM, FOpCtrlM, FWriteIntM});

   flopenrc #(64) EMRegClass(clk, reset, FlushM, ~StallM, ClassResE, ClassResM);
   







   //BEGIN MEMORY STAGE
   
   mux3  #(64)  FResMux(AlignedSrcAM, SgnResM, CmpResM, FResSelM, FResM);
   mux3  #(1)  FFlgMux(1'b0, SgnNVM, CmpNVM, FResSelM, FFlgM);

   //***change to mux
   assign SrcXMAligned = FmtM ? SrcXM[63:64-`XLEN] : {{`XLEN-32{1'b0}}, SrcXM[63:32]};
   mux3  #(`XLEN)  IntResMux(CmpResM[`XLEN-1:0], SrcXMAligned, ClassResM[`XLEN-1:0], FIntResSelM, FIntResM);

   // second instance of two-stage FMA unit
   fma2 fma2(.X(SrcXM), .Y(SrcYM), .Z(SrcZM), .FOpCtrlM(FOpCtrlM[2:0]), .FrmM, .FmtM, 
            .ProdManM, .AlignedAddendM, .ProdExpM, .AddendStickyM, .KillProdM, 
            .XZeroM, .YZeroM, .ZZeroM, .XInfM, .YInfM, .ZInfM, .XNaNM, .YNaNM, .ZNaNM, 
            .FMAResM, .FMAFlgM);
   
   // second instance of two-stage floating-point add/cvt unit
   fpuaddcvt2 fpadd2 (.FrmM, .FOpCtrlM, .FmtM, .AddSumM, .AddSumTcM, .AddFloat1M, .AddFloat2M, 
                     .AddExp1DenormM, .AddExp2DenormM, .AddExponentM, .AddExpPostSumM, .AddSelInvM, 
                     .AddOp1NormM, .AddOp2NormM, .AddOpANormM, .AddOpBNormM, .AddInvalidM, .AddDenormInM, 
                     .AddSignAM, .AddCorrSignM, .AddConvertM, .AddSwapM, .FAddResM, .FAddFlgM);
   
   // Align SrcA to MSB when single precicion
   mux2  #(64)  SrcAMux({SrcAM[31:0], 32'b0}, {{64-`XLEN{1'b0}}, SrcAM}, FmtM, AlignedSrcAM);
      








         
   //*****************
   // M/W pipe registers
   //*****************
   flopenrc #(64) MWRegFma1(clk, reset, FlushW, ~StallW, FMAResM, FMAResW); 
   flopenrc #(5) MWRegFma2(clk, reset, FlushW, ~StallW, FMAFlgM, FMAFlgW); 
   
   flopenrc #(64) MWRegDiv1(clk, reset, FlushW, ~StallW, FDivResultM, FDivResultW); 
   flopenrc #(5) MWRegDiv2(clk, reset, FlushW, ~StallW, FDivSqrtFlgM, FDivSqrtFlgW);
   
   flopenrc #(64) MWRegAdd1(clk, reset, FlushW, ~StallW, FAddResM, FAddResW); 
   flopenrc #(5) MWRegAdd2(clk, reset, FlushW, ~StallW, FAddFlgM, FAddFlgW); 
   
   flopenrc #(1) MWRegCmp1(clk, reset, FlushW, ~StallW, CmpNVM, CmpNVW); 
   flopenrc #(64) MWRegCmp3(clk, reset, FlushW, ~StallW, CmpResM, CmpResW);

   flopenrc #(64) MWRegClass2(clk, reset, FlushW, ~StallW, FResM, FResW);
   flopenrc #(1) MWRegClass1(clk, reset, FlushW, ~StallW, FFlgM, FFlgW);
   
   flopenrc #(11) MWCtrlReg(clk, reset, FlushW, ~StallW,
                        {FWriteEnM, FResultSelM, RdM, FmtM, FWriteIntM},
                        {FWriteEnW, FResultSelW, RdW, FmtW, FWriteIntW});
   
   




  //#########################################
  // BEGIN WRITEBACK STAGE
  //#########################################





//***turn into muxs
   always_comb begin
      case (FResultSelW)
	3'b000 : FPUFlagsW = 5'b0;
	3'b001 : FPUFlagsW = FMAFlgW;
	3'b010 : FPUFlagsW = FAddFlgW;
	3'b011 : FPUFlagsW = FDivSqrtFlgW;
	3'b100 : FPUFlagsW = {4'b0,FFlgW};
	default : FPUFlagsW = 5'bxxxxx;
      endcase
   end

   always_comb begin
      case (FResultSelW)
	3'b000 : FPUResult64W = FmtW ? {ReadDataW, {64-`XLEN{1'b0}}} : {ReadDataW[31:0], 32'b0};
	3'b001 : FPUResult64W = FMAResW;
	3'b010 : FPUResult64W = FAddResW;
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
//***turn into mux
      FPUResultW = FmtW ? FPUResult64W[63:64-`XLEN] : {{`XLEN-32{1'b0}}, FPUResult64W[63:32]};
      //*** put into mem stage
      SetFflagsM = FPUFlagsW;      
   end
  
endmodule // fpu


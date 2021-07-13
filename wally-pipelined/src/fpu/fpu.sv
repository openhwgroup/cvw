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
  output logic [4:0] 	   SetFflagsM);      // FPU result
// *** change FMA to do 16 - 32 - 64 - 128 FEXPBITS 

  generate
     if (`F_SUPPORTED | `D_SUPPORTED) begin 
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
      
      //fpu signals
      logic [63:0]   FMAResM, FMAResW;
      logic [4:0]    FMAFlgM, FMAFlgW;


      logic [63:0]   ReadResW;

      // add/cvt signals
      logic [63:0] 	FAddResM, FAddResW;
      logic [4:0] 	FAddFlgM, FAddFlgW;  
      logic [63:0] 	CvtResE, CvtResM;
      logic [4:0] 	CvtFlgE, CvtFlgM;  
      
      // cmp signals 
      logic 		   CmpNVE, CmpNVM, CmpNVW;
      logic [63:0] 	CmpResE, CmpResM, CmpResW;
      
      // fsgn signals
      logic [63:0] 	SgnResE, SgnResM;
      logic        	SgnNVE, SgnNVM, SgnNVW;
      logic [63:0]   FResM, FResW;
      logic [4:0]         FFlgM, FFlgW;
      
      // instantiation of W stage regfile signals
      logic [63:0] 	AlignedSrcAM;
      
      // classify signals
      logic [63:0] 	ClassResE, ClassResM;
      
      // 64-bit FPU result   
      logic [63:0] 	FPUResultW;                                           
      logic [4:0] 	FPUFlagsW;
      
      







      //DECODE STAGE
      
      
      // top-level controller for FPU
      fctrl fctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]), 
                  .FRM_REGW, .IllegalFPUInstrD, .FWriteEnD, .FDivStartD, .FResultSelD, .FOpCtrlD, .FResSelD, 
                  .FIntResSelD, .FmtD, .FrmD, .FWriteIntD);
      
      // regfile instantiation
      fregfile fregfile (clk, reset, FWriteEnW,
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
      flopenrc #(22) DECtrlReg3(clk, reset, FlushE, ~StallE, 
                           {FWriteEnD, FResultSelD, FResSelD, FIntResSelD, FrmD, FmtD, InstrD[11:7], FOpCtrlD, FWriteIntD},
                           {FWriteEnE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, RdE,          FOpCtrlE, FWriteIntE});














      //EXECUTION STAGE
      
      // Hazard unit for FPU
      fhazard fhazard(.Adr1E, .Adr2E, .Adr3E, .FWriteEnM, .FWriteEnW, .RdM, .RdW, .FResultSelM, .FStallD, 
                        .ForwardXE, .ForwardYE, .ForwardZE);

      // forwarding muxs
      mux3  #(64)  fxemux(FRD1E, FPUResultW, FResM, ForwardXE, SrcXE);
      mux3  #(64)  fyemux(FRD2E, FPUResultW, FResM, ForwardYE, SrcYE);
      mux3  #(64)  fzemux(FRD3E, FPUResultW, FResM, ForwardZE, SrcZE);

      
      // first of two-stage instance of floating-point fused multiply-add unit
      fma fma (.clk, .reset, .FlushM, .StallM, 
               .SrcXE, .SrcYE, .SrcZE, .SrcXM, .SrcYM, .SrcZM, 
               .FOpCtrlE(FOpCtrlE[2:0]), .FOpCtrlM(FOpCtrlM[2:0]), 
               .FmtE, .FmtM, .FrmM, .FMAFlgM, .FMAResM);
      
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
      faddcvt faddcvt (.clk, .reset, .FlushM, .StallM, .FrmM, .FOpCtrlM, .FmtE, .FmtM,
                        .SrcXE, .SrcYE, .FOpCtrlE, .FAddResM, .FAddFlgM);
      
      // first and only instance of floating-point comparator
      fcmp fcmp (SrcXE, SrcYE, FOpCtrlE[2:0], FmtE, CmpNVE, CmpResE);
      
      // first and only instance of floating-point sign converter
      fsgn fsgn (.SgnOpCodeE(FOpCtrlE[1:0]), .SrcXE, .SrcYE, .SgnResE, .SgnNVE);
      
      // first and only instance of floating-point classify unit
      fclassify fclassify (.SrcXE, .FmtE, .ClassResE);


      fcvt fcvt (.X(SrcXE), .SrcAE, .FOpCtrlE, .FmtE, .FrmE, .CvtResE, .CvtFlgE);

      // output for store instructions
      mux2  #(`XLEN)  FWriteDataMux({{`XLEN-32{1'b0}}, SrcYE[63:32]}, SrcYE[63:64-`XLEN], FmtE, FWriteDataE);










      //*****************
      // E/M pipe registers
      //*****************
      flopenrc #(64) EMFpReg1(clk, reset, FlushM, ~StallM, SrcXE, SrcXM);
      flopenrc #(64) EMFpReg2(clk, reset, FlushM, ~StallM, SrcYE, SrcYM);
      flopenrc #(64) EMFpReg3(clk, reset, FlushM, ~StallM, SrcZE, SrcZM);
      
     
      flopenrc #(1)  EMRegCmp1(clk, reset, FlushM, ~StallM, CmpNVE, CmpNVM); 
      flopenrc #(64) EMRegCmp2(clk, reset, FlushM, ~StallM, CmpResE, CmpResM); 
      
      flopenrc #(64) EMRegSgn1(clk, reset, FlushM, ~StallM, SgnResE, SgnResM);
      flopenrc #(1) EMRegSgn2(clk, reset, FlushM, ~StallM, SgnNVE, SgnNVM);
      
      flopenrc #(64) EMRegCvt1(clk, reset, FlushM, ~StallM, CvtResE, CvtResM);
      flopenrc #(5) EMRegCvt2(clk, reset, FlushM, ~StallM, CvtFlgE, CvtFlgM);
      
      flopenrc #(22) EMCtrlReg(clk, reset, FlushM, ~StallM,
                           {FWriteEnE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, RdE, FOpCtrlE, FWriteIntE},
                           {FWriteEnM, FResultSelM, FResSelM, FIntResSelM, FrmM, FmtM, RdM, FOpCtrlM, FWriteIntM});

      flopenrc #(64) EMRegClass(clk, reset, FlushM, ~StallM, ClassResE, ClassResM);
      







      //BEGIN MEMORY STAGE
      
      mux4  #(64)  FResMux(AlignedSrcAM, SgnResM, CmpResM, CvtResM, FResSelM, FResM);
      mux4  #(5)  FFlgMux(5'b0, {4'b0, SgnNVM}, {4'b0, CmpNVM}, CvtFlgM, FResSelM, FFlgM);

      mux2  #(`XLEN)  SrcXAlignedMux({{`XLEN-32{1'b0}}, SrcXM[63:32]}, SrcXM[63:64-`XLEN], FmtM, SrcXMAligned);
      mux4  #(`XLEN)  IntResMux(CmpResM[`XLEN-1:0], SrcXMAligned, ClassResM[`XLEN-1:0], CvtResM[`XLEN-1:0], FIntResSelM, FIntResM);

      
      // Align SrcA to MSB when single precicion
      mux2  #(64)  SrcAMux({SrcAM[31:0], 32'b0}, {{64-`XLEN{1'b0}}, SrcAM}, FmtM, AlignedSrcAM);
         
      always_comb begin
         case (FResultSelM)
      3'b000 : SetFflagsM = 5'b0;
      3'b001 : SetFflagsM = FMAFlgM;
      3'b010 : SetFflagsM = FAddFlgM;
      3'b011 : SetFflagsM = FDivSqrtFlgM;
      3'b100 : SetFflagsM = FFlgM;
      default : SetFflagsM = 5'bxxxxx;
         endcase
      end







            
      //*****************
      // M/W pipe registers
      //*****************
      flopenrc #(64) MWRegFma1(clk, reset, FlushW, ~StallW, FMAResM, FMAResW); 
      
      flopenrc #(64) MWRegDiv1(clk, reset, FlushW, ~StallW, FDivResultM, FDivResultW); 
      
      flopenrc #(64) MWRegAdd1(clk, reset, FlushW, ~StallW, FAddResM, FAddResW); 
      
      flopenrc #(64) MWRegCmp3(clk, reset, FlushW, ~StallW, CmpResM, CmpResW);

      flopenrc #(64) MWRegClass2(clk, reset, FlushW, ~StallW, FResM, FResW);
      
      flopenrc #(11) MWCtrlReg(clk, reset, FlushW, ~StallW,
                           {FWriteEnM, FResultSelM, RdM, FmtM, FWriteIntM},
                           {FWriteEnW, FResultSelW, RdW, FmtW, FWriteIntW});
      
      




   //#########################################
   // BEGIN WRITEBACK STAGE
   //#########################################


      mux2  #(64)  ReadResMux({ReadDataW[31:0], 32'b0}, {ReadDataW, {64-`XLEN{1'b0}}}, FmtW, ReadResW);
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


///////////////////////////////////////////
//
// Written: Katherine Parry, James Stine, Brett Mathis
// Modified: 6/23/2021
//
// Purpose: FPU
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

module fpu (
  input logic 		   clk,
  input logic 		   reset,
  input logic [2:0] 	   FRM_REGW, // Rounding mode from CSR
  input logic [31:0] 	   InstrD, // instruction from IFU
  input logic [`XLEN-1:0]  ReadDataW,// Read data from memory
  input logic [`XLEN-1:0]  ForwardedSrcAE, // Integer input being processed (from IEU)
  input logic 		   StallE, StallM, StallW, // stall signals from HZU
  input logic 		   FlushE, FlushM, FlushW, // flush signals from HZU
  input logic [4:0] 	   RdM, RdW, // which FP register to write to (from IEU)
  input logic [1:0]        STATUS_FS, // Is floating-point enabled?
  output logic 		   FRegWriteM, // FP register write enable
  output logic 		   FStallD, // Stall the decode stage
  output logic 		   FWriteIntE, // integer register write enables
  output logic [`XLEN-1:0] FWriteDataE, // Data to be written to memory
  output logic [`XLEN-1:0] FIntResM, // data to be written to integer register
  output logic 		   FDivBusyE, // Is the divide/sqrt unit busy (stall execute stage)
  output logic 		   IllegalFPUInstrD, // Is the instruction an illegal fpu instruction
  output logic [4:0] 	   SetFflagsM        // FPU flags (to privileged unit)
  );

   //*** make everything FLEN at some point
   //*** add the 128 bit support to the if statement when needed
   //*** make new tests for fp using testfloat that include flag checking and all rounding modes
   //*** what is the format for 16-bit - finding conflicting info online can't find anything specified in spec
   //*** only fma/mul and fp <-> int convert flags have been tested. test the others.

   // FPU specifics:
   //    - uses NaN-blocking format
   //        - if there are any unsused bits the most significant bits are filled with 1s
   //                single stored in a double: | 32 1s | single precision value |
   //    - sets the underflow after rounding
  
   // control signals
   logic 		  FRegWriteD, FRegWriteE, FRegWriteW; // FP register write enable
   logic [2:0] 	  FrmD, FrmE, FrmM;                   // FP rounding mode
   logic [`FMTBITS-1:0] FmtD, FmtE, FmtM, FmtW;             // FP precision 0-single 1-double
   logic 		  FDivStartD, FDivStartE;             // Start division or squareroot
   logic 		  FWriteIntD;                         // Write to integer register
   logic [1:0] 	  FForwardXE, FForwardYE, FForwardZE; // forwarding mux control signals
   logic [1:0] 	  FResultSelD, FResultSelE;           // Select the result written to FP register
   logic [1:0] 	  FResultSelM, FResultSelW;           // Select the result written to FP register
   logic [2:0] 	  FOpCtrlD, FOpCtrlE;       // Select which opperation to do in each component
   logic [1:0] 	  FResSelD, FResSelE;       // Select one of the results that finish in the memory stage
   logic [1:0] 	  FIntResSelD, FIntResSelE;           // Select the result written to the integer resister
   logic [4:0] 	  Adr1E, Adr2E, Adr3E;                // adresses of each input

   // regfile signals
   logic [`FLEN-1:0] 	  FRD1D, FRD2D, FRD3D;                // Read Data from FP register - decode stage
   logic [`FLEN-1:0] 	  FRD1E, FRD2E, FRD3E;                // Read Data from FP register - execute stage
   logic [`FLEN-1:0] 	  FSrcXE;                             // Input 1 to the various units (after forwarding)
   logic [`FLEN-1:0] 	  FPreSrcYE, FSrcYE;                  // Input 2 to the various units (after forwarding)
   logic [`FLEN-1:0] 	  FPreSrcZE, FSrcZE;                  // Input 3 to the various units (after forwarding)

   // unpacking signals
   logic 		  XSgnE, YSgnE, ZSgnE;                // input's sign - execute stage
   logic 		  XSgnM, YSgnM;                       // input's sign - memory stage
   logic [`NE-1:0] 	  XExpE, YExpE, ZExpE;                // input's exponent - execute stage
   logic [`NE-1:0] 	  ZExpM;                              // input's exponent - memory stage
   logic [`NF:0] 	  XManE, YManE, ZManE;                // input's fraction - execute stage
   logic [`NF:0] 	  XManM, YManM, ZManM;                // input's fraction - memory stage
   logic 		  XNaNE, YNaNE, ZNaNE;                // is the input a NaN - execute stage
   logic 		  XNaNM, YNaNM, ZNaNM;                // is the input a NaN - memory stage
   logic 		  XNaNQ, YNaNQ;                       // is the input a NaN - divide
   logic 		  XSNaNE, YSNaNE, ZSNaNE;             // is the input a signaling NaN - execute stage
   logic 		  XSNaNM, YSNaNM, ZSNaNM;             // is the input a signaling NaN - memory stage
   logic 		  XDenormE, ZDenormE;       // is the input denormalized
   logic 		  XZeroE, YZeroE, ZZeroE;             // is the input zero - execute stage
   logic 		  XZeroM, YZeroM, ZZeroM;             // is the input zero - memory stage
   logic 		  XZeroQ, YZeroQ;                     // is the input zero - divide
   logic 		  XInfE, YInfE, ZInfE;                // is the input infinity - execute stage
   logic 		  XInfM, YInfM, ZInfM;                // is the input infinity - memory stage
   logic 		  XInfQ, YInfQ;                       // is the input infinity - divide
   logic 		  XExpMaxE;                           // is the exponent all ones (max value)
   logic 		  FmtQ;
   logic 		  FOpCtrlQ;     

   // result and flag signals
   logic [63:0] 	  FDivResM, FDivResW;                 // divide/squareroot result
   logic [4:0] 	  FDivFlgM;                 // divide/squareroot flags  
   logic [`FLEN-1:0] 	  FMAResM, FMAResW;                   // FMA/multiply result
   logic [4:0] 	  FMAFlgM;                   // FMA/multiply result	
   logic [`FLEN-1:0] 	  ReadResW;                           // read result (load instruction)
   logic [`FLEN-1:0] 	  CvtResE;                   // FP <-> int convert result
   logic [`XLEN-1:0] CvtIntResE;                   // FP <-> int convert result
   logic [4:0] 	  CvtFlgE;                   // FP <-> int convert flags //*** trim this	
   logic [`XLEN-1:0] 	  ClassResE;               // classify result
   logic [`FLEN-1:0] 	  CmpResE;                   // compare result
   logic 		  CmpNVE;                     // compare invalid flag (Not Valid)     
   logic [`FLEN-1:0] 	  SgnResE;                   // sign injection result
   logic [`FLEN-1:0] 	  FResE, FResM, FResW;                // selected result that is ready in the memory stage
   logic [4:0] 	  FFlgE, FFlgM;                       // selected flag that is ready in the memory stage     
   logic [`XLEN-1:0] 	  FIntResE;     
   logic [`FLEN-1:0] 	  FPUResultW;                         // final FP result being written to the FP register     
   // other signals
   logic 		  FDivSqrtDoneE;                      // is divide done
   logic [63:0] 	  DivInput1E, DivInput2E;             // inputs to divide/squareroot unit
   logic 		  load_preload;                       // enable for FF on fpdivsqrt     
   logic [`FLEN-1:0] 	  AlignedSrcAE;                       // align SrcA to the floating point format
   logic [`FLEN-1:0]     BoxedZeroE;                         // Zero value for Z for multiplication, with NaN boxing if needed
   logic [`FLEN-1:0]     BoxedOneE;                         // Zero value for Z for multiplication, with NaN boxing if needed
   
   // DECODE STAGE

   // calculate FP control signals
   fctrl fctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]), .FRM_REGW, .STATUS_FS,
      .IllegalFPUInstrD, .FRegWriteD, .FDivStartD, .FResultSelD, .FOpCtrlD, .FResSelD, 
      .FIntResSelD, .FmtD, .FrmD, .FWriteIntD);

   // FP register file
   fregfile fregfile (.clk, .reset, .we4(FRegWriteW),
      .a1(InstrD[19:15]), .a2(InstrD[24:20]), .a3(InstrD[31:27]), 
      .a4(RdW), .wd4(FPUResultW),
      .rd1(FRD1D), .rd2(FRD2D), .rd3(FRD3D));	

   // D/E pipeline registers
   flopenrc #(`FLEN) DEReg1(clk, reset, FlushE, ~StallE, FRD1D, FRD1E);
   flopenrc #(`FLEN) DEReg2(clk, reset, FlushE, ~StallE, FRD2D, FRD2E);
   flopenrc #(`FLEN) DEReg3(clk, reset, FlushE, ~StallE, FRD3D, FRD3E);
   flopenrc #(15) DEAdrReg(clk, reset, FlushE, ~StallE, {InstrD[19:15], InstrD[24:20], InstrD[31:27]}, 
                           {Adr1E, Adr2E, Adr3E});
   flopenrc #(16+int'(`FMTBITS-1)) DECtrlReg3(clk, reset, FlushE, ~StallE, 
               {FRegWriteD, FResultSelD, FResSelD, FIntResSelD, FrmD, FmtD, FOpCtrlD, FWriteIntD, FDivStartD},
               {FRegWriteE, FResultSelE, FResSelE, FIntResSelE, FrmE, FmtE, FOpCtrlE, FWriteIntE, FDivStartE});

   // EXECUTION STAGE
   // Hazard unit for FPU  
   //    - determines if any forwarding or stalls are needed
   fhazard fhazard(.Adr1E, .Adr2E, .Adr3E, .FRegWriteM, .FRegWriteW, .RdM, .RdW, .FResultSelM, 
                  .FStallD, .FForwardXE, .FForwardYE, .FForwardZE);

   // forwarding muxs
   mux3  #(`FLEN)  fxemux (FRD1E, FPUResultW, FResM, FForwardXE, FSrcXE);
   mux3  #(`FLEN)  fyemux (FRD2E, FPUResultW, FResM, FForwardYE, FPreSrcYE);
   mux3  #(`FLEN)  fzemux (FRD3E, FPUResultW, FResM, FForwardZE, FPreSrcZE);


   generate
      if(`FPSIZES == 1) assign BoxedOneE = {2'b0, {`NE-1{1'b1}}, (`NF)'(0)};
      else if(`FPSIZES == 2) 
         mux2 #(`FLEN) fonemux ({{`FLEN-`LEN1{1'b1}}, 2'b0, {`NE1-1{1'b1}}, (`NF1)'(0)}, {2'b0, {`NE-1{1'b1}}, (`NF)'(0)}, FmtE, BoxedOneE); // NaN boxing zeroes
      else if(`FPSIZES == 3 | `FPSIZES == 4) 
         mux4 #(`FLEN) fonemux ({{`FLEN-`S_LEN{1'b1}}, 2'b0, {`S_NE-1{1'b1}}, (`S_NF)'(0)}, 
                              {{`FLEN-`D_LEN{1'b1}}, 2'b0, {`D_NE-1{1'b1}}, (`D_NF)'(0)}, 
                              {{`FLEN-`H_LEN{1'b1}}, 2'b0, {`H_NE-1{1'b1}}, (`H_NF)'(0)}, 
                              {2'b0, {`NE-1{1'b1}}, (`NF)'(0)}, FmtE, BoxedOneE); // NaN boxing zeroes
   endgenerate


   mux2  #(`FLEN)  fyaddmux (FPreSrcYE, BoxedOneE, FOpCtrlE[2]&FOpCtrlE[1]&(FResultSelE==2'b01), FSrcYE); // Force Z to be 0 for multiply instructions
   
   // Force Z to be 0 for multiply instructions 
   generate
   if(`FPSIZES == 1) assign BoxedZeroE = 0;
   else if(`FPSIZES == 2) 
      mux2 #(`FLEN) fmulzeromux ({{`FLEN-`LEN1{1'b1}}, {`LEN1{1'b0}}}, (`FLEN)'(0), FmtE, BoxedZeroE); // NaN boxing zeroes
   else if(`FPSIZES == 3 | `FPSIZES == 4)
      mux4 #(`FLEN) fmulzeromux ({{`FLEN-`S_LEN{1'b1}}, {`S_LEN{1'b0}}}, 
                                 {{`FLEN-`D_LEN{1'b1}}, {`D_LEN{1'b0}}}, 
                                 {{`FLEN-`H_LEN{1'b1}}, {`H_LEN{1'b0}}}, 
                                 (`FLEN)'(0), FmtE, BoxedZeroE); // NaN boxing zeroes
   endgenerate

   mux3  #(`FLEN)  fzmulmux (FPreSrcZE, BoxedZeroE, FPreSrcYE, {FOpCtrlE[2]&FOpCtrlE[1], FOpCtrlE[2]&~FOpCtrlE[1]}, FSrcZE);

   // unpack unit
   //    - splits FP inputs into their various parts
   //    - does some classifications (SNaN, NaN, Denorm, Norm, Zero, Infifnity)
   unpack unpack (.X(FSrcXE), .Y(FSrcYE), .Z(FSrcZE), .FmtE,
         .XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE, 
         .XNaNE, .YNaNE, .ZNaNE, .XSNaNE, .YSNaNE, .ZSNaNE, .XDenormE, .ZDenormE, 
         .XZeroE, .YZeroE, .ZZeroE, .XInfE, .YInfE, .ZInfE, .XExpMaxE);

   // FMA
   //   - two stage FMA
   //   - execute stage - multiplication and addend shifting
   //   - memory stage  - addition and rounding
   //   - handles FMA and multiply instructions
   fma fma (.clk, .reset, .FlushM, .StallM, 
      .XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE, 
      .ZDenormE, .XZeroE, .YZeroE, .ZZeroE,
      .XSgnM, .YSgnM, .ZExpM, .XManM, .YManM, .ZManM, 
      .XNaNM, .YNaNM, .ZNaNM, .XZeroM, .YZeroM, .ZZeroM, 
      .XInfM, .YInfM, .ZInfM, .XSNaNM, .YSNaNM, .ZSNaNM,
      .FOpCtrlE,
      .FmtE, .FmtM, .FrmM, 
      .FMAFlgM, .FMAResM);

   // fpdivsqrt using Goldschmidt's iteration
   if(`FLEN == 64) begin 
   flopenrc #(64) reg_input1 (.d({FSrcXE[63:0]}), .q(DivInput1E),
         .clear(FDivSqrtDoneE), .en(load_preload),
         .reset(reset),  .clk(clk));
   flopenrc #(64) reg_input2 (.d({FSrcYE[63:0]}), .q(DivInput2E),
            .clear(FDivSqrtDoneE), .en(load_preload),
            .reset(reset),  .clk(clk));
   end
   else if (`FLEN == 32) begin 
   flopenrc #(64) reg_input1 (.d({32'b0, FSrcXE[31:0]}), .q(DivInput1E),
         .clear(FDivSqrtDoneE), .en(load_preload),
         .reset(reset),  .clk(clk));
   flopenrc #(64) reg_input2 (.d({32'b0, FSrcYE[31:0]}), .q(DivInput2E),
            .clear(FDivSqrtDoneE), .en(load_preload),
            .reset(reset),  .clk(clk));
   end
   flopenrc #(8) reg_input3 (.d({XNaNE, YNaNE, XInfE, YInfE, XZeroE, YZeroE, FmtE[0], FOpCtrlE[0]}), 
            .q({XNaNQ, YNaNQ, XInfQ, YInfQ, XZeroQ, YZeroQ, FmtQ, FOpCtrlQ}),
            .clear(FDivSqrtDoneE), .en(load_preload),
            .reset(reset),  .clk(clk));
   fpdiv_pipe fdivsqrt (.op1(DivInput1E[63:0]), .op2(DivInput2E[63:0]), .rm(FrmE[1:0]), .op_type(FOpCtrlQ), 
         .reset, .clk(clk), .start(FDivStartE), .P(~FmtQ), .OvEn(1'b1), .UnEn(1'b1),
         .XNaNQ, .YNaNQ, .XInfQ, .YInfQ, .XZeroQ, .YZeroQ, .load_preload,
         .FDivBusyE, .done(FDivSqrtDoneE), .AS_Result(FDivResM), .Flags(FDivFlgM));

   // other FP execution units
   fcmp fcmp (.FmtE, .FOpCtrlE, .XSgnE, .YSgnE, .XExpE, .YExpE, .XManE, .YManE, 
            .XZeroE, .YZeroE, .XNaNE, .YNaNE, .XSNaNE, .YSNaNE, .FSrcXE, .FSrcYE, .CmpNVE, .CmpResE);
   fsgninj fsgninj(.SgnOpCodeE(FOpCtrlE[1:0]), .XSgnE, .YSgnE, .FSrcXE, .FmtE, .SgnResE);
   fclassify fclassify (.XSgnE, .XDenormE, .XZeroE, .XNaNE, .XInfE, .XSNaNE, .ClassResE);
   fcvt fcvt (.XSgnE, .XExpE, .XManE, .ForwardedSrcAE, .FOpCtrlE, .FWriteIntE, .XZeroE, .XDenormE,
              .XInfE, .XNaNE, .XSNaNE, .FrmE, .FmtE, .CvtResE, .CvtIntResE, .CvtFlgE);

   // data to be stored in memory - to IEU
   //    - FP uses NaN-blocking format
   //        - if there are any unsused bits the most significant bits are filled with 1s
   if (`FLEN>`XLEN) assign FWriteDataE = FSrcYE[`XLEN-1:0]; 
   else assign FWriteDataE = {{`XLEN-`FLEN{FSrcYE[`FLEN-1]}}, FSrcYE}; 

   // NaN Block SrcA
   generate
   if(`FPSIZES == 1) assign AlignedSrcAE = {{`FLEN-`XLEN{1'b1}}, ForwardedSrcAE};
   else if(`FPSIZES == 2) 
      mux2 #(`FLEN) SrcAMux ({{`FLEN-`LEN1{1'b1}}, ForwardedSrcAE[`LEN1-1:0]}, {{`FLEN-`XLEN{1'b1}}, ForwardedSrcAE}, FmtE, AlignedSrcAE);
   else if(`FPSIZES == 3 | `FPSIZES == 4)
      mux4 #(`FLEN) SrcAMux ({{`FLEN-`S_LEN{1'b1}}, ForwardedSrcAE[`S_LEN-1:0]}, 
                             {{`FLEN-`D_LEN{1'b1}}, ForwardedSrcAE[`D_LEN-1:0]}, 
                             {{`FLEN-`H_LEN{1'b1}}, ForwardedSrcAE[`H_LEN-1:0]}, 
                             {{`FLEN-`XLEN{1'b1}}, ForwardedSrcAE}, FmtE, AlignedSrcAE); // NaN boxing zeroes
   endgenerate
   // select a result that may be written to the FP register
   mux4  #(`FLEN) FResMux(AlignedSrcAE, SgnResE, CmpResE, CvtResE, FResSelE, FResE);
   mux4  #(5)  FFlgMux(5'b0, 5'b0, {CmpNVE, 4'b0}, CvtFlgE, FResSelE, FFlgE);

   // select the result that may be written to the integer register - to IEU
   if (`FLEN>`XLEN) 
      mux4  #(`XLEN)  IntResMux(CmpResE[`XLEN-1:0], FSrcXE[`XLEN-1:0], ClassResE, 
                  CvtIntResE, FIntResSelE, FIntResE);
   else 
      mux4  #(`XLEN)  IntResMux({{`XLEN-`FLEN{CmpResE[`FLEN-1:0]}}, CmpResE}, {{`XLEN-`FLEN{FSrcXE[`FLEN-1:0]}}, FSrcXE}, ClassResE, 
                  CvtIntResE, FIntResSelE, FIntResE);
   // *** DH 5/25/22: CvtRes will move to mem stage.  Premux in execute to save area, then make sure stalls are ok
   // *** make sure the fpu matches the chapter diagram

   // E/M pipe registers

   // flopenrc #(64) EMFpReg1(clk, reset, FlushM, ~StallM, FSrcXE, FSrcXM);
   flopenrc #(`NF+2) EMFpReg2 (clk, reset, FlushM, ~StallM, {XSgnE,XManE}, {XSgnM,XManM});
   flopenrc #(`NF+2) EMFpReg3 (clk, reset, FlushM, ~StallM, {YSgnE,YManE}, {YSgnM,YManM});
   flopenrc #(`FLEN) EMFpReg4 (clk, reset, FlushM, ~StallM, {ZExpE,ZManE}, {ZExpM,ZManM});
   flopenrc #(12) EMFpReg5 (clk, reset, FlushM, ~StallM, 
            {XZeroE, YZeroE, ZZeroE, XInfE, YInfE, ZInfE, XNaNE, YNaNE, ZNaNE, XSNaNE, YSNaNE, ZSNaNE},
            {XZeroM, YZeroM, ZZeroM, XInfM, YInfM, ZInfM, XNaNM, YNaNM, ZNaNM, XSNaNM, YSNaNM, ZSNaNM});     
   flopenrc #(`FLEN) EMRegCmpRes (clk, reset, FlushM, ~StallM, FResE, FResM); 
   flopenrc #(5)  EMRegCmpFlg (clk, reset, FlushM, ~StallM, FFlgE, FFlgM);      
   flopenrc #(`XLEN) EMRegSgnRes (clk, reset, FlushM, ~StallM, FIntResE, FIntResM);
   flopenrc #(7+int'(`FMTBITS-1)) EMCtrlReg (clk, reset, FlushM, ~StallM,
               {FRegWriteE, FResultSelE, FrmE, FmtE},
               {FRegWriteM, FResultSelM, FrmM, FmtM});

   // BEGIN MEMORY STAGE

   // FPU flag selection - to privileged
   mux4  #(5)  FPUFlgMux (5'b0, FMAFlgM, FDivFlgM, FFlgM, FResultSelM, SetFflagsM);

   // M/W pipe registers
   flopenrc #(`FLEN) MWRegFma(clk, reset, FlushW, ~StallW, FMAResM, FMAResW); 
   flopenrc #(64) MWRegDiv(clk, reset, FlushW, ~StallW, FDivResM, FDivResW); 
   flopenrc #(`FLEN) MWRegClass(clk, reset, FlushW, ~StallW, FResM, FResW);
   flopenrc #(4+int'(`FMTBITS-1))  MWCtrlReg(clk, reset, FlushW, ~StallW,
            {FRegWriteM, FResultSelM, FmtM},
            {FRegWriteW, FResultSelW, FmtW});

   // BEGIN WRITEBACK STAGE

   // put ReadData into NaN-blocking format
   //    - if there are any unsused bits the most significant bits are filled with 1s
   //    - for load instruction
   generate
      if(`FPSIZES == 1) assign ReadResW = {{`FLEN-`XLEN{1'b1}}, ReadDataW};
      else if(`FPSIZES == 2) 
         mux2 #(`FLEN) SrcAMux ({{`FLEN-`LEN1{1'b1}}, ReadDataW[`LEN1-1:0]}, {{`FLEN-`XLEN{1'b1}}, ReadDataW}, FmtW, ReadResW);
      else if(`FPSIZES == 3 | `FPSIZES == 4)
         mux4 #(`FLEN) SrcAMux ({{`FLEN-`S_LEN{1'b1}}, ReadDataW[`S_LEN-1:0]}, 
                              {{`FLEN-`D_LEN{1'b1}}, ReadDataW[`D_LEN-1:0]}, 
                              {{`FLEN-`H_LEN{1'b1}}, ReadDataW[`H_LEN-1:0]}, 
                              {{`FLEN-`XLEN{1'b1}}, ReadDataW}, FmtW, ReadResW); // NaN boxing zeroes
   endgenerate

   // select the result to be written to the FP register
   if(`FLEN>=64)
   mux4  #(`FLEN)  FPUResultMux (ReadResW, FMAResW, {{`FLEN-64{1'b0}},FDivResW}, FResW, FResultSelW, FPUResultW);
endmodule // fpu

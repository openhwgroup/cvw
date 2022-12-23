///////////////////////////////////////////
// fpu.sv
//
// Written: me@KatherineParry.com, James Stine, Brett Mathis
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
   input  logic 		        clk,
   input  logic 		        reset,
   input  logic  [2:0] 	     FRM_REGW,   // Rounding mode (from CSR)
   input  logic  [31:0] 	  InstrD,     // instruction (from IFU)
   input  logic  [`FLEN-1:0] ReadDataW,  // Read data (from LSU)
   input  logic  [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // Integer input (from IEU)
   input  logic 		        StallE, StallM, StallW, // stall signals (from HZU)
   //input  logic              TrapM,
   input  logic 		        FlushE, FlushM, FlushW, // flush signals (from HZU)
   input  logic  [4:0] 	     RdE, RdM, RdW,   // which FP register to write to (from IEU)
   input  logic  [1:0]       STATUS_FS,  // Is floating-point enabled? (From privileged unit)
   input  logic  [2:0] 	     Funct3E, Funct3M,
	input  logic 		        MDUE, W64E,
   output logic 		        FRegWriteM, // FP register write enable (to privileged unit)
   output logic 		        FpLoadStoreM,  // Fp load instruction? (to LSU)
   output logic 		        FPUStallD,       // Stall the decode stage (To HZU)
   output logic 		        FWriteIntE,    // integer register write enable (to IEU)
   output logic              FCvtIntE,      // Convert to int (to IEU)
   output logic [`FLEN-1:0]  FWriteDataM,   // Data to be written to memory (to LSU) 
   output logic [`XLEN-1:0]  FIntResM,      // data to be written to integer register (to IEU)
   output logic [`XLEN-1:0]  FCvtIntResW,   // convert result to to be written to integer register (to IEU)
   output logic              FCvtIntW,      // select FCvtIntRes (to IEU)
   output logic 		        FDivBusyE,     // Is the divide/sqrt unit busy (stall execute stage) (to HZU)
   output logic 		        IllegalFPUInstrM, // Is the instruction an illegal fpu instruction (to privileged unit)
   output logic [4:0] 	     SetFflagsM,        // FPU flags (to privileged unit)
   output logic [`XLEN-1:0]  FPIntDivResultW
  );

   // FPU specifics:
   //    - uses NaN-blocking format
   //        - if there are any unsused bits the most significant bits are filled with 1s
   //                single stored in a double: | 32 1s | single precision value |
   //    - sets the underflow after rounding

   // control signals
   logic 		         FRegWriteW; // FP register write enable
   logic [2:0] 	      FrmM;                   // FP rounding mode
   logic [`FMTBITS-1:0] FmtE, FmtM;             // FP precision 0-single 1-double
   logic 		         FDivStartE, IDivStartE;             // Start division or squareroot
   logic 		         FWriteIntM;                         // Write to integer register
   logic [1:0] 	      ForwardXE, ForwardYE, ForwardZE; // forwarding mux control signals
   logic [2:0] 	      OpCtrlE, OpCtrlM;       // Select which opperation to do in each component
   logic [1:0] 	      FResSelE, FResSelM, FResSelW;       // Select one of the results that finish in the memory stage
   logic [1:0] 	      PostProcSelE, PostProcSelM; // select result in the post processing unit
   logic [4:0] 	      Adr1D, Adr2D, Adr3D;                // adresses of each input
   logic [4:0] 	      Adr1E, Adr2E, Adr3E;                // adresses of each input
   logic                XEnD, YEnD, ZEnD;
   logic                XEnE, YEnE, ZEnE;
   logic                 FRegWriteE;

   // regfile signals
   logic [`FLEN-1:0] FRD1D, FRD2D, FRD3D;                // Read Data from FP register - decode stage
   logic [`FLEN-1:0] FRD1E, FRD2E, FRD3E;                // Read Data from FP register - execute stage
   logic [`FLEN-1:0] XE;                             // Input 1 to the various units (after forwarding)
   logic [`XLEN-1:0] IntSrcXE;                             // Input 1 to the various units (after forwarding)
   logic [`FLEN-1:0] PreYE, YE;                  // Input 2 to the various units (after forwarding)
   logic [`FLEN-1:0] PreZE, ZE;                  // Input 3 to the various units (after forwarding)

   // unpacking signals
   logic 		      XsE, YsE, ZsE;                // input's sign - execute stage
   logic 		      XsM, YsM;                       // input's sign - memory stage
   logic [`NE-1:0] 	XeE, YeE, ZeE;                // input's exponent - execute stage
   logic [`NE-1:0] 	ZeM;                              // input's exponent - memory stage
   logic [`NF:0] 	   XmE, YmE, ZmE;                // input's fraction - execute stage
   logic [`NF:0] 	   XmM, YmM, ZmM;                // input's fraction - memory stage
   logic 		      XNaNE, YNaNE, ZNaNE;                // is the input a NaN - execute stage
   logic 		      XNaNM, YNaNM, ZNaNM;                // is the input a NaN - memory stage
   logic 		      XNaNQ, YNaNQ;                       // is the input a NaN - divide
   logic 		      XSNaNE, YSNaNE, ZSNaNE;             // is the input a signaling NaN - execute stage
   logic 		      XSNaNM, YSNaNM, ZSNaNM;             // is the input a signaling NaN - memory stage
   logic 		      XDenormE, ZDenormE, ZDenormM;       // is the input denormalized
   logic 		      XZeroE, YZeroE, ZZeroE;             // is the input zero - execute stage
   logic 		      XZeroM, YZeroM, ZZeroM;             // is the input zero - memory stage
   logic 		      XInfE, YInfE, ZInfE;                // is the input infinity - execute stage
   logic 		      XInfM, YInfM, ZInfM;                // is the input infinity - memory stage
   logic 		      XExpMaxE;                           // is the exponent all ones (max value)

   // Fma Signals
   logic [3*`NF+5:0] SmE, SmM;                       
   logic 			   ZmStickyE, ZmStickyM;
   logic [`NE+1:0]   SeE,SeM;
   logic 			   InvAE, InvAM;
   logic 			   AsE, AsM;
   logic 			   PsE, PsM;
   logic 			   SsE, SsM;
   logic [$clog2(3*`NF+7)-1:0] SCntE, SCntM;

   // Cvt Signals
   logic [`NE:0]           CeE, CeM;    // the calculated expoent
   logic [`LOGCVTLEN-1:0]  CvtShiftAmtE, CvtShiftAmtM;  // how much to shift by
   logic                   CvtResDenormUfE, CvtResDenormUfM;// does the result underflow or is denormalized
   logic                   CsE, CsM;     // the result's sign
   logic                   IntZeroE, IntZeroM;      // is the integer zero?
   logic [`CVTLEN-1:0]     CvtLzcInE, CvtLzcInM;      // input to the Leading Zero Counter (priority encoder)
   
   //divide signals
   logic [`DIVb:0]      QmM;
   logic [`NE+1:0]      QeE, QeM; 
   logic                DivSE, DivSM;
//   logic                DivDoneM;
   logic                FDivDoneE, IFDivStartE;

   // result and flag signals
   logic [`XLEN-1:0] ClassResE;               // classify result
   logic [`XLEN-1:0] FIntResE;               // classify result
   logic [`FLEN-1:0] FpResM, FpResW;               // classify result
   logic [`FLEN-1:0] PostProcResM;               // classify result
   logic [4:0] 	   PostProcFlgM;               // classify result
   logic [`XLEN-1:0] FCvtIntResM; 
   logic [`FLEN-1:0] CmpFpResE;                   // compare result
   logic [`XLEN-1:0] CmpIntResE;                   // compare result
   logic 		      CmpNVE;                     // compare invalid flag (Not Valid)     
   logic [`FLEN-1:0] SgnResE;                   // sign injection result
   logic [`FLEN-1:0] PreFpResE, PreFpResM;                // selected result that is ready in the memory stage
   logic  	         PreNVE, PreNVM;                       // selected flag that is ready in the memory stage     
   logic [`FLEN-1:0] FPUResultW;                         // final FP result being written to the FP register     
   // other signals
   logic [`FLEN-1:0] 	 AlignedSrcAE;                       // align SrcA to the floating point format
   logic [`FLEN-1:0]     BoxedZeroE;                         // Zero value for Z for multiplication, with NaN boxing if needed
   logic [`FLEN-1:0]     BoxedOneE;                         // Zero value for Z for multiplication, with NaN boxing if needed
   logic             StallUnpackedM;
   logic [`XLEN-1:0] FPIntDivResultM;

   // DECODE STAGE

   //////////////////////////////////////////////////////////////////////////////////////////
   //          |||||||||||
   //          |||      |||
   //          |||       |||
   //          |||       |||
   //          |||       |||
   //          |||      |||
   //          |||||||||||
   //////////////////////////////////////////////////////////////////////////////////////////

   // calculate FP control signals
   fctrl fctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]), 
               .Funct3E, .MDUE, .InstrD,
               .StallE, .StallM, .StallW, .FlushE, .FlushM, .FlushW, .FRM_REGW, .STATUS_FS, .FDivBusyE,
               .reset, .clk, .FRegWriteE, .FRegWriteM, .FRegWriteW, .FrmM, .FmtE, .FmtM,
               .FDivStartE, .IDivStartE, .FWriteIntE, .FCvtIntE, .FWriteIntM, .OpCtrlE, .OpCtrlM, .IllegalFPUInstrM, .XEnD, .YEnD, .ZEnD, .XEnE, .YEnE, .ZEnE,
               .FResSelE, .FResSelM, .FResSelW, .PostProcSelE, .PostProcSelM, .FCvtIntW, .Adr1D, .Adr2D, .Adr3D, .Adr1E, .Adr2E, .Adr3E);

   // FP register file
   fregfile fregfile (.clk, .reset, .we4(FRegWriteW),
      .a1(InstrD[19:15]), .a2(InstrD[24:20]), .a3(InstrD[31:27]), 
      .a4(RdW), .wd4(FPUResultW),
      .rd1(FRD1D), .rd2(FRD2D), .rd3(FRD3D));	

   // D/E pipeline registers  
   flopenrc #(`FLEN) DEReg1(clk, reset, FlushE, ~StallE, FRD1D, FRD1E);
   flopenrc #(`FLEN) DEReg2(clk, reset, FlushE, ~StallE, FRD2D, FRD2E);
   flopenrc #(`FLEN) DEReg3(clk, reset, FlushE, ~StallE, FRD3D, FRD3E);

   // EXECUTION STAGE
   
   //////////////////////////////////////////////////////////////////////////////////////////
   //          ||||||||||||
   //          |||
   //          |||       
   //          |||||||||
   //          |||     
   //          |||      
   //          ||||||||||||
   //////////////////////////////////////////////////////////////////////////////////////////

   // Hazard unit for FPU  
   //    - determines if any forwarding or stalls are needed
   fhazard fhazard(.Adr1D, .Adr2D, .Adr3D, .Adr1E, .Adr2E, .Adr3E, .FRegWriteE, .FRegWriteM, .FRegWriteW, .RdE, .RdM, .RdW, .FResSelM, 
                   .XEnD, .YEnD, .ZEnD, .FPUStallD, .ForwardXE, .ForwardYE, .ForwardZE);

   // forwarding muxs
   mux3  #(`FLEN)  fxemux (FRD1E, FPUResultW, PreFpResM, ForwardXE, XE);
   mux3  #(`FLEN)  fyemux (FRD2E, FPUResultW, PreFpResM, ForwardYE, PreYE);
   mux3  #(`FLEN)  fzemux (FRD3E, FPUResultW, PreFpResM, ForwardZE, PreZE);


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


   mux2  #(`FLEN)  fyaddmux (PreYE, BoxedOneE, OpCtrlE[2]&OpCtrlE[1]&(FResSelE==2'b01)&(PostProcSelE==2'b10), YE); // Force Z to be 0 for multiply instructions
   
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

   mux3  #(`FLEN)  fzmulmux (PreZE, BoxedZeroE, PreYE, {OpCtrlE[2]&OpCtrlE[1], OpCtrlE[2]&~OpCtrlE[1]}, ZE);

   // unpack unit
   //    - splits FP inputs into their various parts
   //    - does some classifications (SNaN, NaN, Denorm, Norm, Zero, Infifnity)
   unpack unpack (.X(XE), .Y(YE), .Z(ZE), .Fmt(FmtE), .Xs(XsE), .Ys(YsE), .Zs(ZsE), 
                  .Xe(XeE), .Ye(YeE), .Ze(ZeE), .Xm(XmE), .Ym(YmE), .Zm(ZmE), .YEn(YEnE),
                  .XNaN(XNaNE), .YNaN(YNaNE), .ZNaN(ZNaNE), .XSNaN(XSNaNE), .XEn(XEnE), 
                  .YSNaN(YSNaNE), .ZSNaN(ZSNaNE), .XDenorm(XDenormE), .ZDenorm(ZDenormE), 
                  .XZero(XZeroE), .YZero(YZeroE), .ZZero(ZZeroE), .XInf(XInfE), .YInf(YInfE), 
                  .ZEn(ZEnE), .ZInf(ZInfE), .XExpMax(XExpMaxE));
   
   // fused multiply add
   //    - fadd/fsub
   //    - fmul
   //    - fmadd/fnmadd/fmsub/fnmsub
   fma fma (.Xs(XsE), .Ys(YsE), .Zs(ZsE), 
            .Xe(XeE), .Ye(YeE), .Ze(ZeE), 
            .Xm(XmE), .Ym(YmE), .Zm(ZmE), 
            .XZero(XZeroE), .YZero(YZeroE), .ZZero(ZZeroE), 
            .OpCtrl(OpCtrlE), 
            .As(AsE), .Ps(PsE), .Ss(SsE), .Se(SeE),
            .Sm(SmE), 
            .InvA(InvAE), .SCnt(SCntE), 
            .ZmSticky(ZmStickyE)); 

   // divide and squareroot
   //    - fdiv
   //    - fsqrt
   // *** add other opperations
   fdivsqrt fdivsqrt(.clk, .reset, .FmtE, .XmE, .YmE, .XeE, .YeE, .SqrtE(OpCtrlE[0]), .SqrtM(OpCtrlM[0]),
                  .XInfE, .YInfE, .XZeroE, .YZeroE, .XNaNE, .YNaNE, .FDivStartE, .IDivStartE, .XsE,
                  .ForwardedSrcAE, .ForwardedSrcBE, .Funct3E, .Funct3M, .MDUE, .W64E,
                  .StallM, .FlushE, .DivSM, .FDivBusyE, .IFDivStartE, .FDivDoneE, .QeM, 
                  .QmM, .FPIntDivResultM /*, .DivDone(DivDoneM) */);

                  //
   // compare
   //    - fmin/fmax
   //    - flt/fle/feq
   fcmp fcmp (.Fmt(FmtE), .OpCtrl(OpCtrlE), .Xs(XsE), .Ys(YsE), .Xe(XeE), .Ye(YeE), 
               .Xm(XmE), .Ym(YmE), .XZero(XZeroE), .YZero(YZeroE), .XNaN(XNaNE), .YNaN(YNaNE), 
               .XSNaN(XSNaNE), .YSNaN(YSNaNE), .X(XE), .Y(YE), .CmpNV(CmpNVE), 
               .CmpFpRes(CmpFpResE), .CmpIntRes(CmpIntResE));
   // sign injection
   //    - fsgnj/fsgnjx/fsgnjn
   fsgninj fsgninj(.OpCtrl(OpCtrlE[1:0]), .Xs(XsE), .Ys(YsE), .X(XE), .Fmt(FmtE), .SgnRes(SgnResE));

   // classify
   //    - fclass
   fclassify fclassify (.Xs(XsE), .XDenorm(XDenormE), .XZero(XZeroE), .XNaN(XNaNE), 
                        .XInf(XInfE), .XSNaN(XSNaNE), .ClassRes(ClassResE));

   // convert
   //    - fcvt.*.*
   fcvt fcvt (.Xs(XsE), .Xe(XeE), .Xm(XmE), .Int(ForwardedSrcAE), .OpCtrl(OpCtrlE), 
              .ToInt(FWriteIntE), .XZero(XZeroE), .XDenorm(XDenormE), .Fmt(FmtE), .Ce(CeE), 
              .ShiftAmt(CvtShiftAmtE), .ResDenormUf(CvtResDenormUfE), .Cs(CsE), .IntZero(IntZeroE), 
              .LzcIn(CvtLzcInE));

   // data to be stored in memory - to IEU
   //    - FP uses NaN-blocking format
   //        - if there are any unsused bits the most significant bits are filled with 1s
   
   flopenrc #(`FLEN) FWriteDataMReg (clk, reset, FlushM, ~StallM, YE, FWriteDataM);

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
   mux3  #(`FLEN) FResMux(SgnResE, AlignedSrcAE, CmpFpResE, {OpCtrlE[2], &OpCtrlE[1:0]}, PreFpResE);
   assign PreNVE = CmpNVE&(OpCtrlE[2]|FWriteIntE);

   // select the result that may be written to the integer register - to IEU
   
   logic [`FLEN-1:0] SgnExtXE;
   generate
   if(`FPSIZES == 1)
      assign SgnExtXE = XE;
   else if(`FPSIZES == 2) 
      mux2 #(`FLEN) sgnextmux ({{`FLEN-`LEN1{XsE}}, XE[`LEN1-1:0]}, XE, FmtE, SgnExtXE);
   else if(`FPSIZES == 3 | `FPSIZES == 4)
      mux4 #(`FLEN) fmulzeromux ({{`FLEN-`H_LEN{XsE}}, XE[`H_LEN-1:0]}, 
                                 {{`FLEN-`S_LEN{XsE}}, XE[`S_LEN-1:0]}, 
                                 {{`FLEN-`D_LEN{XsE}}, XE[`D_LEN-1:0]}, 
                                 XE, FmtE, SgnExtXE); // NaN boxing zeroes
   endgenerate
   if (`FLEN>`XLEN)
      assign IntSrcXE = SgnExtXE[`XLEN-1:0];
   else 
      assign IntSrcXE = {{`XLEN-`FLEN{XsE}}, SgnExtXE};

   mux3 #(`XLEN) IntResMux (ClassResE, IntSrcXE, CmpIntResE, {~FResSelE[1], FResSelE[0]}, FIntResE);
   // *** DH 5/25/22: CvtRes will move to mem stage.  Premux in execute to save area, then make sure stalls are ok
   // *** make sure the fpu matches the chapter diagram

   // E/M pipe registers

   assign StallUnpackedM = StallM | (FDivBusyE & ~IFDivStartE | FDivDoneE); // Need to stall during divsqrt iterations to avoid capturing bad flags from stale forwarded sources

   flopenrc #(`NF+1) EMFpReg2 (clk, reset, FlushM, ~StallM, XmE, XmM);
   flopenrc #(`NF+1) EMFpReg3 (clk, reset, FlushM, ~StallM, YmE, YmM);
   flopenrc #(`FLEN) EMFpReg4 (clk, reset, FlushM, ~StallM, {ZeE,ZmE}, {ZeM,ZmM});
   flopenrc #(`XLEN) EMFpReg6 (clk, reset, FlushM, ~StallM, FIntResE, FIntResM);
   flopenrc #(`FLEN) EMFpReg7 (clk, reset, FlushM, ~StallM, PreFpResE, PreFpResM);
   flopenr #(15) EMFpReg5 (clk, reset, ~StallUnpackedM, 
            {XsE, YsE, XZeroE, YZeroE, ZZeroE, XInfE, YInfE, ZInfE, XNaNE, YNaNE, ZNaNE, XSNaNE, YSNaNE, ZSNaNE, ZDenormE},
            {XsM, YsM, XZeroM, YZeroM, ZZeroM, XInfM, YInfM, ZInfM, XNaNM, YNaNM, ZNaNM, XSNaNM, YSNaNM, ZSNaNM, ZDenormM});     
   flopenrc #(1)  EMRegCmpFlg (clk, reset, FlushM, ~StallM, PreNVE, PreNVM);      
   flopenrc #(3*`NF+6) EMRegFma2(clk, reset, FlushM, ~StallM, SmE, SmM); 
  flopenrc #($clog2(3*`NF+7)+7+`NE) EMRegFma4(clk, reset, FlushM, ~StallM, 
                           {ZmStickyE, InvAE, SCntE, AsE, PsE, SsE, SeE},
                           {ZmStickyM, InvAM, SCntM, AsM, PsM, SsM, SeM});
   flopenrc #(`NE+`LOGCVTLEN+`CVTLEN+4) EMRegCvt(clk, reset, FlushM, ~StallM, 
                           {CeE, CvtShiftAmtE, CvtResDenormUfE, CsE, IntZeroE, CvtLzcInE},
                           {CeM, CvtShiftAmtM, CvtResDenormUfM, CsM, IntZeroM, CvtLzcInM});

   // BEGIN MEMORY STAGE

   //////////////////////////////////////////////////////////////////////////////////////////
   //          |||         |||
   //          ||||||   ||||||
   //          ||| ||| ||| |||
   //          |||  |||||  |||
   //          |||   |||   |||
   //          |||         |||
   //          |||         |||
   //////////////////////////////////////////////////////////////////////////////////////////

   assign FpLoadStoreM = FResSelM[1];

   postprocess postprocess(.Xs(XsM), .Ys(YsM), .Xm(XmM), .Ym(YmM), .Zm(ZmM), .Frm(FrmM), .Fmt(FmtM), 
                           .FmaZmS(ZmStickyM), .XZero(XZeroM), .YZero(YZeroM), .ZZero(ZZeroM), .XInf(XInfM), .YInf(YInfM), .DivQm(QmM), .FmaSs(SsM),
                           .ZInf(ZInfM), .XNaN(XNaNM), .YNaN(YNaNM), .ZNaN(ZNaNM), .XSNaN(XSNaNM), .YSNaN(YSNaNM), .ZSNaN(ZSNaNM), .FmaSm(SmM), .DivQe(QeM), /*.DivDone(DivDoneM), */
                           .ZDenorm(ZDenormM), .FmaAs(AsM), .FmaPs(PsM), .OpCtrl(OpCtrlM), .FmaSCnt(SCntM), .FmaSe(SeM),
                           .CvtCe(CeM), .CvtResDenormUf(CvtResDenormUfM),.CvtShiftAmt(CvtShiftAmtM), .CvtCs(CsM), .ToInt(FWriteIntM), .DivS(DivSM),
                           .CvtLzcIn(CvtLzcInM), .IntZero(IntZeroM), .PostProcSel(PostProcSelM), .PostProcRes(PostProcResM), .PostProcFlg(PostProcFlgM), .FCvtIntRes(FCvtIntResM));

   // FPU flag selection - to privileged
   mux2  #(5)  FPUFlgMux ({PreNVM&~FResSelM[1], 4'b0}, PostProcFlgM, ~FResSelM[1]&FResSelM[0], SetFflagsM);
   mux2  #(`FLEN)  FPUResMux (PreFpResM, PostProcResM, FResSelM[0], FpResM);

   // M/W pipe registers
   flopenrc #(`FLEN) MWRegFp(clk, reset, FlushW, ~StallW, FpResM, FpResW); 
   flopenrc #(`XLEN) MWRegIntCvtRes(clk, reset, FlushW, ~StallW, FCvtIntResM, FCvtIntResW); 
   flopenrc #(`XLEN) MWRegIntDivRes(clk, reset, FlushW, ~StallW, FPIntDivResultM, FPIntDivResultW); 

   // BEGIN WRITEBACK STAGE

   //////////////////////////////////////////////////////////////////////////////////////////
   //         |||           |||
   //         |||           |||
   //         |||    |||    |||
   //         |||   |||||   |||
   //         |||  ||| |||  |||
   //          ||||||   ||||||
   //          |||         |||
   //////////////////////////////////////////////////////////////////////////////////////////

   // select the result to be written to the FP register
   mux2  #(`FLEN)  FPUResultMux (FpResW, ReadDataW, FResSelW[1], FPUResultW);

endmodule // fpu

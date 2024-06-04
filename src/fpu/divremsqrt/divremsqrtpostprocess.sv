///////////////////////////////////////////
// postprocess.sv
//
// Written: kekim@hmc.edu
// Modified: 19 May 2023
//
// Purpose: Post-Processing: normalization, rounding, sign, flags, special cases
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////


module divremsqrtpostprocess import cvw::*;  #(parameter cvw_t P)  (
  // general signals
  input logic                             Xs, Ys,     // input signs
  input logic  [P.NF:0]                    Xm, Ym,     // input mantissas
  input logic  [2:0]                      Frm,        // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
  input logic  [P.FMTBITS-1:0]             Fmt,        // precision 1 = double 0 = single
  input logic  [3:0]                      OpCtrl,     // choose which opperation (look below for values)
  input logic                             XZero, YZero,        // inputs are zero
  input logic                             XInf, YInf,          // inputs are infinity
  input logic                             XNaN, YNaN,          // inputs are NaN
  input logic                             XSNaN, YSNaN,        // inputs are signaling NaNs
  input logic  [1:0]                      PostProcSel,         // select result to be written to fp register
  //fma signals
  //divide signals
  input logic                             DivSticky,  // divider sticky bit
  input logic  [P.NE+1:0]                  DivUe,      // divsqrt exponent
  input logic  [P.NF+2:0]                  DivUm,      // divsqrt significand
  input logic  [P.DIVBLEN-1:0]             IntNormShiftM, // integer normalization left-shift amount (after pre-shifting right)
  input logic  [P.XLEN+3:0]                PreResultM, // integer result to be shifted
  input logic                              IntDivM,
  // final results
  output logic [P.FLEN-1:0]                PostProcRes,// postprocessor final result
  output logic [4:0]                      PostProcFlg, // postprocesser flags
  output logic [P.DIVb+3:0]  PreIntResultM // normalized integer result
  );

  
  // general signals
  logic                       Rs;         // result sign
  logic [P.NF-1:0]             Rf;         // Result fraction
  logic [P.NE-1:0]             Re;         // Result exponent
  logic                       Ms;         // norMalized sign
  logic [P.NORMSHIFTSZDRSU-1:0]    Mf;         // norMalized fraction
  logic [P.NE+1:0]             Me;         // normalized exponent
  logic [P.NE+1:0]             FullRe;     // Re with bits to determine sign and overflow
  logic                       UfPlus1;    // do you add one (for determining underflow flag)
  logic [P.LOGNORMSHIFTSZDRSU-1:0] ShiftAmt;   // normalization shift amount
  logic [P.NORMSHIFTSZDRSU-1:0]    ShiftIn;    // input to normalization shift
  logic [P.NORMSHIFTSZDRSU-1:0]    Shifted;    // the ouput of the normalized shifter (before shift correction)
  logic                       Plus1;      // add one to the final result?
  logic                       Overflow;   // overflow flag used to select results
  logic                       Invalid;    // invalid flag used to select results
  logic                       Guard, Round, Sticky; // bits needed to determine rounding
  logic [P.FMTBITS-1:0]        OutFmt;     // output format
  // division singals
  logic [P.LOGNORMSHIFTSZDRSU-1:0] DivShiftAmt;        // divsqrt shif amount
  logic [P.NORMSHIFTSZDRSU-1:0]    DivShiftIn;         // divsqrt shift input
  logic [P.NE+1:0]             Ue;                 // divsqrt corrected exponent after corretion shift
  logic                       DivByZero;          // divide by zero flag
  logic                       DivResSubnorm;      // is the divsqrt result subnormal
  logic                       DivSubnormShiftPos; // is the divsqrt subnorm shift amout positive (not underflowed)
  // conversion signals
  logic [P.CVTLEN+P.NF:0]       CvtShiftIn;         // number to be shifted for converter
  logic [1:0]                 CvtNegResMsbs;      // most significant bits of possibly negated int result
  logic [P.XLEN+1:0]           CvtNegRes;          // possibly negated integer result
  logic                       CvtResUf;           // did the convert result underflow
  logic                       IntInvalid;         // invalid integer flag
  // readability signals
  logic                       Mult;       // multiply opperation
  logic                       Sqrt;       // is the divsqrt opperation sqrt
  logic                       Int64;      // is the integer 64 bits?
  logic                       Signed;     // is the opperation with a signed integer?
  logic                       IntToFp;    // is the opperation an int->fp conversion?
  logic                       CvtOp;      // convertion opperation
  logic                       DivOp;      // divider opperation
  logic                       InfIn;      // are any of the inputs infinity
  logic                       NaNIn;      // are any of the inputs NaN

  // signals to help readability
  //assign Signed =  OpCtrl[0];
  //assign Int64 =   OpCtrl[1];
  //assign IntToFp = OpCtrl[2];
  //assign Mult = OpCtrl[2]&~OpCtrl[1]&~OpCtrl[0];
  //assign CvtOp = (PostProcSel == 2'b00);
  //assign FmaOp = (PostProcSel == 2'b10);
  assign DivOp = (PostProcSel == 2'b01);
  assign Sqrt =  OpCtrl[0];

  // is there an input of infinity or NaN being used
  assign InfIn = XInf|YInf;
  assign NaNIn = XNaN|YNaN;

  // choose the ouptut format depending on the opperation
  //      - fp -> fp: OpCtrl contains the percision of the output
  //      - otherwise: Fmt contains the percision of the output
  if (P.FPSIZES == 2) 
      //assign OutFmt = IntToFp|~CvtOp ? Fmt : (OpCtrl[1:0] == P.FMT); 
      assign OutFmt = Fmt;
  else if (P.FPSIZES == 3 | P.FPSIZES == 4) 
      //assign OutFmt = IntToFp|~CvtOp ? Fmt : OpCtrl[1:0]; 
      assign OutFmt = Fmt;

  ///////////////////////////////////////////////////////////////////////////////
  // Normalization
  ///////////////////////////////////////////////////////////////////////////////

  // final claulations before shifting
  /*cvtshiftcalc cvtshiftcalc(.ToInt, .CvtCe, .CvtResSubnormUf, .Xm, .CvtLzcIn,  
      .XZero, .IntToFp, .OutFmt, .CvtResUf, .CvtShiftIn);*/

  divremsqrtdivshiftcalc #(P) divremsqrtdivshiftcalc(.DivUe, .DivUm, .DivResSubnorm, .DivSubnormShiftPos, .DivShiftAmt, .DivShiftIn);

  assign ShiftAmt = DivShiftAmt;
  assign ShiftIn = DivShiftIn;
  
  // main normalization shift
  if (~P.IDIV_ON_FPU) begin
    divremsqrtnormshift #(P) divremsqrtnormshift (.ShiftIn, .ShiftAmt, .Shifted);
  end else begin
    // use unified shifter
    logic [P.UNIFIEDSHIFTWIDTH-1:0] UnifiedShiftIn, ShiftInWide, PreResultMWide, UnifiedShifted;
    logic [P.LOGUNIFIEDSHIFTWIDTH-1:0] UnifiedShiftAmt, IntNormShiftMWide, ShiftAmtWide;

    // extend signals to fit unified width
    assign IntNormShiftMWide = {{(P.LOGUNIFIEDSHIFTWIDTH-P.DIVBLEN){1'b0}},IntNormShiftM};
    //assign PreResultMWide = {{(P.DIVb){PreResultM[P.DIVb+3]}},PreResultM,{(P.UNIFIEDSHIFTWIDTH-P.DIVb-4-P.DIVb){1'b0}}};
    assign PreResultMWide = {{(P.XLEN){PreResultM[P.XLEN+3]}},PreResultM,{(P.UNIFIEDSHIFTWIDTH-P.XLEN-4-P.XLEN){1'b0}}};

    
    assign ShiftInWide = {ShiftIn,{(P.UNIFIEDSHIFTWIDTH-P.NORMSHIFTSZDRSU){1'b0}}};
    assign ShiftAmtWide = {{(P.LOGUNIFIEDSHIFTWIDTH-P.LOGNORMSHIFTSZDRSU){1'b0}},ShiftAmt};


    // mux between fp or int normalization shift inputs
    mux2 #(P.UNIFIEDSHIFTWIDTH) unifiedshiftinmux(ShiftInWide, PreResultMWide, IntDivM, UnifiedShiftIn);
    mux2 #(P.LOGUNIFIEDSHIFTWIDTH) unifiedshiftamtmux(ShiftAmtWide, IntNormShiftMWide, IntDivM, UnifiedShiftAmt);

    divremsqrtunifiedshift #(P) unifiedshift(UnifiedShiftAmt, UnifiedShiftIn, UnifiedShifted);
    // extract fp result
    assign Shifted = UnifiedShifted[P.UNIFIEDSHIFTWIDTH-1:P.UNIFIEDSHIFTWIDTH-1-P.NORMSHIFTSZDRSU+1];

    // extract integer result
    assign PreIntResultM = {{(P.DIVb-P.XLEN){1'b0}},UnifiedShifted[P.UNIFIEDSHIFTWIDTH-1:P.UNIFIEDSHIFTWIDTH-1-P.XLEN-4+1]};
    //assign PreIntResultM = IntNormShiftM
  end

  // correct for LZA/divsqrt error
  divremsqrtshiftcorrection #(P) shiftcorrection(.DivResSubnorm, .DivSubnormShiftPos, .DivOp(1'b1), .DivUe, .Ue, .Shifted, .Mf);

  ///////////////////////////////////////////////////////////////////////////////
  // Rounding
  ///////////////////////////////////////////////////////////////////////////////

  // round to nearest even
  // round to zero
  // round to -infinity
  // round to infinity
  // round to nearest max magnitude

  // calulate result sign used in rounding unit
  divremsqrtroundsign #(P) roundsign( .DivOp(1'b1), .Sqrt, .Xs, .Ys, .Ms);

  divremsqrtround #(P) round(.OutFmt, .Frm, .Plus1, .Ue,
      .Ms, .Mf, .DivSticky, .DivOp(1'b1), .UfPlus1, .FullRe, .Rf, .Re, .Sticky, .Round, .Guard, .Me);

  ///////////////////////////////////////////////////////////////////////////////
  // Sign calculation
  ///////////////////////////////////////////////////////////////////////////////

  /*resultsign resultsign(.Frm, .FmaPs, .FmaAs, .Round, .Sticky, .Guard,
      .FmaOp, .ZInf, .InfIn, .FmaSZero, .Mult, .Ms, .Rs);*/
  assign Rs = Ms;

  ///////////////////////////////////////////////////////////////////////////////
  // Flags
  ///////////////////////////////////////////////////////////////////////////////

  divremsqrtflags #(P) flags(.XSNaN, .YSNaN, .XInf, .YInf, .InfIn, .XZero, .YZero, 
              .Xs, .OutFmt, .Sqrt,
              .NaNIn, .Round, .DivByZero,
              .Guard, .Sticky, .UfPlus1,.DivOp(1'b1), .FullRe, .Plus1,
              .Me, .Invalid, .Overflow, .PostProcFlg);

  ///////////////////////////////////////////////////////////////////////////////
  // Select the result
  ///////////////////////////////////////////////////////////////////////////////

  //negateintres negateintres(.Xs, .Shifted, .Signed, .Int64, .Plus1, .CvtNegResMsbs, .CvtNegRes);

  divremsqrtspecialcase #(P) specialcase(.Xs, .Xm, .Ym, .XZero, 
      .Frm, .OutFmt, .XNaN, .YNaN,  
      .NaNIn, .Plus1, .Invalid, .Overflow, .InfIn,
      .XInf, .YInf, .DivOp(1'b1), .DivByZero, .FullRe, .Rs, .Re, .Rf, .PostProcRes );

endmodule

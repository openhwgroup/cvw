///////////////////////////////////////////
// postprocess.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Post-Processing
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

module postprocess (
    // general signals
    input logic                             Xs, Ys,     // input signs
    input logic  [`NF:0]                    Xm, Ym, Zm, // input mantissas
    input logic  [2:0]                      Frm,        // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic  [`FMTBITS-1:0]             Fmt,        // precision 1 = double 0 = single
    input logic  [2:0]                      OpCtrl,     // choose which opperation (look below for values)
    input logic                             XZero, YZero, ZZero, // inputs are zero
    input logic                             XInf, YInf, ZInf,    // inputs are infinity
    input logic                             XNaN, YNaN, ZNaN,    // inputs are NaN
    input logic                             XSNaN, YSNaN, ZSNaN, // inputs are signaling NaNs
    input logic                             ZDenorm,        // is the original precision denormalized
    input logic  [1:0]                      PostProcSel,    // select result to be written to fp register
    //fma signals
    input logic                             FmaAs,  // the modified Z sign - depends on instruction
    input logic                             FmaPs,  // the product's sign
    input logic  [`NE+1:0]                  FmaSe,  // the sum's exponent
    input logic  [3*`NF+3:0]                FmaSm,  // the positive sum
    input logic                             FmaASticky, // sticky bit that is calculated during alignment
    input logic                             FmaSs,  //
    input logic  [$clog2(3*`NF+5)-1:0]      FmaSCnt,   // the normalization shift count
    //divide signals
    input logic                             DivS,
    input logic  [`NE+1:0]                  DivQe,
    input logic  [`DIVb:0]                  DivQm,
    // conversion signals
    input logic                             CvtCs,     // the result's sign
    input logic  [`NE:0]                    CvtCe,    // the calculated expoent
    input logic                             CvtResDenormUf,
	input logic  [`LOGCVTLEN-1:0]           CvtShiftAmt,  // how much to shift by
    input logic                             ToInt,     // is fp->int (since it's writting to the integer register)
    input logic  [`CVTLEN-1:0]              CvtLzcIn,      // input to the Leading Zero Counter (priority encoder)
    input logic                             IntZero,         // is the input zero
    // final results
    output logic [`FLEN-1:0]                PostProcRes,    // FMA final result
    output logic [4:0]                      PostProcFlg,
    output logic [`XLEN-1:0]                FCvtIntRes    // the int conversion result
    );
   
    // general signals
    logic Ws;
    logic [`NF-1:0] Rf; // Result fraction
    logic [`NE-1:0] Re;  // Result exponent
    logic Ms;
    logic [`NE+1:0] Me;
    logic [`CORRSHIFTSZ-1:0] Mf; // corectly shifted fraction
    logic [`NE+1:0] FullRe;  // Re with bits to determine sign and overflow
    logic UfPlus1;                    // do you add one (for determining underflow flag)
    logic [`LOGNORMSHIFTSZ-1:0] ShiftAmt;   // normalization shift count
    logic [`NORMSHIFTSZ-1:0] ShiftIn;        // is the sum zero
    logic [`NORMSHIFTSZ-1:0] Shifted;    // the shifted result
    logic Plus1;      // add one to the final result?
    logic IntInvalid, Overflow, Invalid; // flags
    logic G, R, S; // bits needed to determine rounding
    logic [`FMTBITS-1:0] OutFmt;
    // fma signals
    logic [`NE+1:0] FmaMe;     // exponent of the normalized sum
    logic FmaSZero;        // is the sum zero
    logic [3*`NF+5:0] FmaShiftIn;        // shift input
    logic [`NE+1:0] NormSumExp;          // exponent of the normalized sum not taking into account denormal or zero results
    logic FmaPreResultDenorm;    // is the result denormalized - calculated before LZA corection
    logic [$clog2(3*`NF+5)-1:0] FmaShiftAmt;   // normalization shift count
    // division singals
    logic [`LOGNORMSHIFTSZ-1:0] DivShiftAmt;
    logic [`NORMSHIFTSZ-1:0] DivShiftIn;
    logic [`NE+1:0] Qe;
    logic DivByZero;
    logic DivResDenorm;
    logic DivDenormShiftPos;
    // conversion signals
    logic [`CVTLEN+`NF:0] CvtShiftIn;    // number to be shifted
    logic [1:0] CvtNegResMsbs;
    logic [`XLEN+1:0]    CvtNegRes;
    logic CvtResUf;
    // readability signals
    logic Mult;       // multiply opperation
    logic Int64;      // is the integer 64 bits?
    logic Signed;     // is the opperation with a signed integer?
    logic IntToFp;       // is the opperation an int->fp conversion?
    logic CvtOp;
    logic FmaOp;
    logic DivOp;
    logic InfIn;
    logic NaNIn;
    logic Sqrt;

    // signals to help readability
    assign Signed =  OpCtrl[0];
    assign Int64 =   OpCtrl[1];
    assign IntToFp = OpCtrl[2];
    assign Mult = OpCtrl[2]&~OpCtrl[1]&~OpCtrl[0];
    assign CvtOp = (PostProcSel == 2'b00);
    assign FmaOp = (PostProcSel == 2'b10);
    assign DivOp = (PostProcSel == 2'b01); // & DivDone;
    assign Sqrt =  OpCtrl[0];

    // is there an input of infinity or NaN being used
    assign InfIn = XInf|YInf|ZInf;
    assign NaNIn = XNaN|YNaN|ZNaN;

    // choose the ouptut format depending on the opperation
    //      - fp -> fp: OpCtrl contains the percision of the output
    //      - otherwise: Fmt contains the percision of the output
    if (`FPSIZES == 2) 
        assign OutFmt = IntToFp|~CvtOp ? Fmt : (OpCtrl[1:0] == `FMT); 
    else if (`FPSIZES == 3 | `FPSIZES == 4) 
        assign OutFmt = IntToFp|~CvtOp ? Fmt : OpCtrl[1:0]; 

    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////

    cvtshiftcalc cvtshiftcalc(.ToInt, .CvtCe, .CvtResDenormUf, .Xm, .CvtLzcIn,  
                              .XZero, .IntToFp, .OutFmt, .CvtResUf, .CvtShiftIn);
    fmashiftcalc fmashiftcalc(.FmaSm, .FmaSCnt, .Fmt, .NormSumExp, .FmaSe,
                          .FmaSZero, .FmaPreResultDenorm, .FmaShiftAmt, .FmaShiftIn);
    divshiftcalc divshiftcalc(.Sqrt, .DivQe, .DivQm, .DivResDenorm, .DivDenormShiftPos, .DivShiftAmt, .DivShiftIn);

    always_comb
        case(PostProcSel)
            2'b10: begin // fma
                ShiftAmt = {{`LOGNORMSHIFTSZ-$clog2(3*`NF+5){1'b0}}, FmaShiftAmt};
                ShiftIn =  {FmaShiftIn, {`NORMSHIFTSZ-(3*`NF+6){1'b0}}};
            end
            2'b00: begin // cvt
                ShiftAmt = {{`LOGNORMSHIFTSZ-$clog2(`CVTLEN+1){1'b0}}, CvtShiftAmt};
                ShiftIn =  {CvtShiftIn, {`NORMSHIFTSZ-`CVTLEN-`NF-1{1'b0}}};
            end
            2'b01: begin //div
               /* if(DivDone) begin */
                    ShiftAmt = DivShiftAmt;
                    ShiftIn =  DivShiftIn;
              /*  end else begin
                    ShiftAmt = '0;
                    ShiftIn =  '0;
                end */
            end
            default: begin 
                ShiftAmt = {`LOGNORMSHIFTSZ{1'bx}}; 
                ShiftIn = {`NORMSHIFTSZ{1'bx}}; 
            end
        endcase
    
    normshift normshift (.ShiftIn, .ShiftAmt, .Shifted);

    shiftcorrection shiftcorrection(.FmaOp, .FmaPreResultDenorm, .NormSumExp,
                                .DivResDenorm, .DivDenormShiftPos, .DivOp, .DivQe,
                                .Qe, .FmaSZero, .Shifted, .FmaMe, .Mf);

    ///////////////////////////////////////////////////////////////////////////////
    // Rounding
    ///////////////////////////////////////////////////////////////////////////////

    // round to nearest even
    // round to zero
    // round to -infinity
    // round to infinity
    // round to nearest max magnitude

                          
    roundsign roundsign(.FmaOp, .DivOp, .CvtOp, .Sqrt, .FmaSs, .Xs, .Ys, .CvtCs, .Ms);

    round round(.OutFmt, .Frm, .FmaASticky, .Plus1, .PostProcSel, .CvtCe, .Qe,
                .Ms, .FmaMe, .FmaOp, .CvtOp, .CvtResDenormUf, .Mf, .ToInt,  .CvtResUf,
                .DivS, //.DivDone,
                .DivOp, .UfPlus1, .FullRe, .Rf, .Re, .S, .R, .G, .Me);

    ///////////////////////////////////////////////////////////////////////////////
    // Sign calculation
    ///////////////////////////////////////////////////////////////////////////////

    resultsign resultsign(.Frm, .FmaPs, .FmaAs, .R, .S, .G,
                          .FmaOp, .ZInf, .InfIn, .FmaSZero, .Mult, .Ms, .Ws);

    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////

    flags flags(.XSNaN, .YSNaN, .ZSNaN, .XInf, .YInf, .ZInf, .InfIn, .XZero, .YZero, 
                .Xs, .Sqrt, .ToInt, .IntToFp, .Int64, .Signed, .OutFmt, .CvtCe,
                .NaNIn, .FmaAs, .FmaPs, .R, .IntInvalid, .DivByZero,
                .G, .S, .UfPlus1, .CvtOp, .DivOp, .FmaOp, .FullRe, .Plus1,
                .Me, .CvtNegResMsbs, .Invalid, .Overflow, .PostProcFlg);

    ///////////////////////////////////////////////////////////////////////////////
    // Select the result
    ///////////////////////////////////////////////////////////////////////////////

    negateintres negateintres(.Xs, .Shifted, .Signed, .Int64, .Plus1, .CvtNegResMsbs, .CvtNegRes);
    specialcase specialcase(.Xs, .Xm, .Ym, .Zm, .XZero, .IntInvalid,
        .IntZero, .Frm, .OutFmt, .XNaN, .YNaN, .ZNaN, .CvtResUf, 
        .NaNIn, .IntToFp, .Int64, .Signed, .CvtOp, .FmaOp, .Plus1, .Invalid, .Overflow, .InfIn, .CvtNegRes,
        .XInf, .YInf, .DivOp,
        .DivByZero, .FullRe, .CvtCe, .Ws, .Re, .Rf, .PostProcRes, .FCvtIntRes);

endmodule

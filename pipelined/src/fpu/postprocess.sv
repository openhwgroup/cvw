///////////////////////////////////////////
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

module postprocess(
    // general signals
    input logic                             Xs, Ys,  // input signs
    input logic  [`NE-1:0]                  Ze, // input exponents
    input logic  [`NF:0]                    Xm, Ym, Zm, // input mantissas
    input logic  [2:0]                      Frm,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic  [`FMTBITS-1:0]             Fmt,       // precision 1 = double 0 = single
    input logic  [2:0]                      FOpCtrl,       // choose which opperation (look below for values)
    input logic                             XZero, YZero, ZZero, // inputs are zero
    input logic                             XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                             XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic                             XSNaNM, YSNaNM, ZSNaNM, // inputs are signaling NaNs
    input logic                             ZDenormM, // is the original precision denormalized
    input logic  [1:0]                      PostProcSelM, // select result to be written to fp register
    //fma signals
    input logic  [`NE+1:0]                  ProdExpM,       // X exponent + Y exponent - bias
    input logic                             AddendStickyM,  // sticky bit that is calculated during alignment
    input logic                             KillProdM,      // set the product to zero before addition if the product is too small to matter
    input logic  [3*`NF+5:0]                SumM,       // the positive sum
    input logic                             NegSumM,    // was the sum negitive
    input logic                             InvZM,      // do you invert Z
    input logic                             ZSgnEffM,   // the modified Z sign - depends on instruction
    input logic                             PSgnM,      // the product's sign
    input logic  [$clog2(3*`NF+7)-1:0]      FmaNormCntM,   // the normalization shift count
    //divide signals
    input logic  [$clog2(`DIVLEN/2+3)-1:0]  EarlyTermShiftDiv2M,
    input logic                             DivStickyM,
    input logic                             DivNegStickyM,
    input logic                             DivDone,
    input logic  [`NE+1:0]                  DivCalcExpM,
    input logic  [`DIVLEN+2:0]              Quot,
    // conversion signals
    input logic  [`NE:0]                    CvtCalcExpM,    // the calculated expoent
    input logic                             CvtResDenormUfM,
	input logic  [`LOGCVTLEN-1:0]           CvtShiftAmtM,  // how much to shift by
    input logic                             CvtResSgnM,     // the result's sign
    input logic                             FWriteIntM,     // is fp->int (since it's writting to the integer register)
    input logic  [`CVTLEN-1:0]              CvtLzcInM,      // input to the Leading Zero Counter (priority encoder)
    input logic                             IntZeroM,         // is the input zero
    // final results
    output logic [`FLEN-1:0]                PostProcResM,    // FMA final result
    output logic [4:0]                      PostProcFlgM,
    output logic [`XLEN-1:0]                FCvtIntResM    // the int conversion result
    );
   
    // general signals
    logic [`NF-1:0] ResFrac; // Result fraction
    logic [`NE-1:0] ResExp;  // Result exponent
    logic [`CORRSHIFTSZ-1:0] CorrShifted; // corectly shifted fraction
    logic [`NE+1:0] FullResExp;  // ResExp with bits to determine sign and overflow
    logic Sticky;           // Sticky bit
    logic UfPlus1;                    // do you add one (for determining underflow flag)
    logic Round;   // bits needed to determine rounding
    logic [`FLEN:0] RoundAdd;       // how much to add to the result
    logic [$clog2(`NORMSHIFTSZ)-1:0] ShiftAmt;   // normalization shift count
    logic [`NORMSHIFTSZ-1:0] ShiftIn;        // is the sum zero
    logic [`NORMSHIFTSZ-1:0] Shifted;    // the shifted result
    logic Plus1;      // add one to the final result?
    logic IntInvalid, Overflow, Invalid; // flags
    logic [`NE+1:0] RoundExp;
    logic ResSgn;
    logic RoundSgn;
    logic UfLSBRes;
    logic [`FMTBITS-1:0] OutFmt;
    // fma signals
    logic [`NE+1:0] SumExp;     // exponent of the normalized sum
    logic SumZero;        // is the sum zero
    logic [3*`NF+8:0] FmaShiftIn;        // is the sum zero
    logic [`NE+1:0] ConvNormSumExp;          // exponent of the normalized sum not taking into account denormal or zero results
    logic PreResultDenorm;    // is the result denormalized - calculated before LZA corection
    logic [$clog2(3*`NF+7)-1:0] FmaShiftAmt;   // normalization shift count
    // division singals
    logic [$clog2(`NORMSHIFTSZ)-1:0] DivShiftAmt;
    logic [`NORMSHIFTSZ-1:0] DivShiftIn;
    logic [`NE+1:0] CorrDivExp;
    logic DivByZero;
    logic DivResDenorm;
    logic [`NE+1:0] DivDenormShift;
    // conversion signals
    logic [`CVTLEN+`NF:0] CvtShiftIn;    // number to be shifted
    logic [1:0] NegResMSBS;
    logic [`XLEN+1:0]    NegRes;
    logic CvtResUf;
    // readability signals
    logic Mult;       // multiply opperation
    logic Int64;      // is the integer 64 bits?
    logic Signed;     // is the opperation with a signed integer?
    logic IntToFp;       // is the opperation an int->fp conversion?
    logic ToInt;      // is the opperation an fp->int conversion?
    logic CvtOp;
    logic FmaOp;
    logic DivOp;
    logic InfIn;
    logic NaNIn;
    logic Sqrt;

    // signals to help readability
    assign Signed =  FOpCtrl[0];
    assign Int64 =   FOpCtrl[1];
    assign IntToFp = FOpCtrl[2];
    assign ToInt =   FWriteIntM;
    assign Mult = FOpCtrl[2]&~FOpCtrl[1]&~FOpCtrl[0];
    assign CvtOp = (PostProcSelM == 2'b00);
    assign FmaOp = (PostProcSelM == 2'b10);
    assign DivOp = (PostProcSelM == 2'b01)&DivDone;
    assign Sqrt =  FOpCtrl[0];

    // is there an input of infinity or NaN being used
    assign InfIn = (XInfM&~(IntToFp&CvtOp))|(YInfM&~CvtOp)|(ZInfM&FmaOp);
    assign NaNIn = (XNaNM&~(IntToFp&CvtOp))|(YNaNM&~CvtOp)|(ZNaNM&FmaOp);

    // choose the ouptut format depending on the opperation
    //      - fp -> fp: OpCtrl contains the percision of the output
    //      - otherwise: Fmt contains the percision of the output
    if (`FPSIZES == 2) 
        assign OutFmt = IntToFp|~CvtOp ? Fmt : (FOpCtrl[1:0] == `FMT); 
    else if (`FPSIZES == 3 | `FPSIZES == 4) 
        assign OutFmt = IntToFp|~CvtOp ? Fmt : FOpCtrl[1:0]; 

    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////

    cvtshiftcalc cvtshiftcalc(.ToInt, .CvtCalcExpM, .CvtResDenormUfM, .Xm, .CvtLzcInM,  
                              .XZero, .IntToFp, .OutFmt, .CvtResUf, .CvtShiftIn);
    fmashiftcalc fmashiftcalc(.SumM, .Ze, .ProdExpM, .FmaNormCntM, .Fmt, .KillProdM, .ConvNormSumExp,
                          .ZDenormM, .SumZero, .PreResultDenorm, .FmaShiftAmt, .FmaShiftIn);
    divshiftcalc divshiftcalc(.Fmt, .DivCalcExpM, .Quot, .EarlyTermShiftDiv2M, .DivResDenorm, .DivDenormShift, .DivShiftAmt, .DivShiftIn);

    always_comb
        case(PostProcSelM)
            2'b10: begin // fma
                ShiftAmt = {{$clog2(`NORMSHIFTSZ)-$clog2(3*`NF+7){1'b0}}, FmaShiftAmt};
                ShiftIn =  {FmaShiftIn, {`NORMSHIFTSZ-(3*`NF+9){1'b0}}};
            end
            2'b00: begin // cvt
                ShiftAmt = {{$clog2(`NORMSHIFTSZ)-$clog2(`CVTLEN+1){1'b0}}, CvtShiftAmtM};
                ShiftIn =  {CvtShiftIn, {`NORMSHIFTSZ-`CVTLEN-`NF-1{1'b0}}};
            end
            2'b01: begin //div
                if(DivDone) begin
                    ShiftAmt = DivShiftAmt;
                    ShiftIn =  DivShiftIn;
                end else begin
                    ShiftAmt = '0;
                    ShiftIn =  '0;
                end
            end
            default: begin 
                ShiftAmt = {$clog2(`NORMSHIFTSZ){1'bx}}; 
                ShiftIn = {`NORMSHIFTSZ{1'bx}}; 
            end
        endcase
    
    normshift normshift (.ShiftIn, .ShiftAmt, .Shifted);

    lzacorrection lzacorrection(.FmaOp, .KillProdM, .PreResultDenorm, .ConvNormSumExp,
                                .DivResDenorm, .DivDenormShift, .DivOp, .DivCalcExpM,
                                .CorrDivExp, .SumZero, .Shifted, .SumExp, .CorrShifted);

    ///////////////////////////////////////////////////////////////////////////////
    // Rounding
    ///////////////////////////////////////////////////////////////////////////////

    // round to nearest even
    // round to zero
    // round to -infinity
    // round to infinity
    // round to nearest max magnitude

                          
    roundsign roundsign(.PSgnM, .ZSgnEffM, .InvZM, .FmaOp, .DivOp, .CvtOp, .NegSumM, 
                          .Xs, .Ys, .CvtResSgnM, .RoundSgn);

    round round(.OutFmt, .Frm, .Sticky, .AddendStickyM, .ZZero, .Plus1, .PostProcSelM, .CvtCalcExpM, .CorrDivExp,
                .InvZM, .RoundSgn, .SumExp, .FmaOp, .CvtOp, .CvtResDenormUfM, .CorrShifted, .ToInt,  .CvtResUf,
                .DivStickyM, .DivNegStickyM, .DivDone,
                .DivOp, .UfPlus1, .FullResExp, .ResFrac, .ResExp, .Round, .RoundAdd, .UfLSBRes, .RoundExp);

    ///////////////////////////////////////////////////////////////////////////////
    // Sign calculation
    ///////////////////////////////////////////////////////////////////////////////

    resultsign resultsign(.Frm, .PSgnM, .ZSgnEffM, .SumExp, .Round, .Sticky,
                          .FmaOp, .ZInfM, .InfIn, .SumZero, .Mult, .RoundSgn, .ResSgn);

    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////

    flags flags(.XSNaNM, .YSNaNM, .ZSNaNM, .XInfM, .YInfM, .ZInfM, .InfIn, .XZero, .YZero, 
                .Xs, .Sqrt, .ToInt, .IntToFp, .Int64, .Signed, .OutFmt, .CvtCalcExpM,
                .XNaNM, .YNaNM, .NaNIn, .ZSgnEffM, .PSgnM, .Round, .IntInvalid, .DivByZero,
                .UfLSBRes, .Sticky, .UfPlus1, .CvtOp, .DivOp, .FmaOp, .FullResExp, .Plus1,
                .RoundExp, .NegResMSBS, .Invalid, .Overflow, .PostProcFlgM);

    ///////////////////////////////////////////////////////////////////////////////
    // Select the result
    ///////////////////////////////////////////////////////////////////////////////

    negateintres negateintres(.Xs, .Shifted, .Signed, .Int64, .Plus1, .NegResMSBS, .NegRes);
    resultselect resultselect(.Xs, .Xm, .Ym, .Zm, .XZero, .IntInvalid,
        .IntZeroM, .Frm, .OutFmt, .XNaNM, .YNaNM, .ZNaNM, .CvtResUf, 
        .NaNIn, .IntToFp, .Int64, .Signed, .CvtOp, .FmaOp, .Plus1, .Invalid, .Overflow, .InfIn, .NegRes,
        .XInfM, .YInfM, .DivOp,
        .DivByZero, .FullResExp, .CvtCalcExpM, .ResSgn, .ResExp, .ResFrac, .PostProcResM, .FCvtIntResM);

endmodule

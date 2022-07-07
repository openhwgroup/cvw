
///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Floating point conversions of configurable size
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

module fcvt (
    input logic             XSgnE,          // input's sign
    input logic [`NE-1:0]   XExpE,          // input's exponent
    input logic [`NF:0]     XManE,          // input's fraction
    input logic [`XLEN-1:0] ForwardedSrcAE, // integer input - from IEU
    input logic [2:0]       FOpCtrlE,       // choose which opperation (look below for values)
    input logic             FWriteIntE,     // is fp->int (since it's writting to the integer register)
    input logic             XZeroE,         // is the input zero
    input logic             XDenormE,   // is the input denormalized
    input logic [`FMTBITS-1:0] FmtE,        // the input's precision (11=quad 01=double 00=single 10=half)
    output logic [`NE:0]           CvtCalcExpE,    // the calculated expoent
	output logic [`LOGCVTLEN-1:0] CvtShiftAmtE,  // how much to shift by
    output logic                   CvtResDenormUfE,// does the result underflow or is denormalized
    output logic                   CvtResSgnE,     // the result's sign
    output logic                   IntZeroE,      // is the integer zero?
    output logic [`CVTLEN-1:0]      CvtLzcInE      // input to the Leading Zero Counter (priority encoder)
    );

    // OpCtrls:
    //  fp->fp conversions: {0, output precision} - only one of the operations writes to the int register
    //      half   - 10
    //      single - 00
    //      double - 01
    //      quad   - 11
    //  int<->fp conversions: {is int->fp?, is the integer 64-bit?, is the integer signed?}
    //                            bit 2              bit 1                   bit 0
    //      for example: signed long -> single floating point has the OpCode 101

    // (FF) fp  -> fp coversion signals
    // (IF) int -> fp coversion signals
    // (FI) fp  -> int coversion signals


    logic [`FMTBITS-1:0]    OutFmt;     // format of the output
    logic [`XLEN-1:0]       PosInt;     // the positive integer input
    logic [`XLEN-1:0]       TrimInt;    // integer trimmed to the correct size
    logic [`NE-2:0]         NewBias;    // the bias of the final result
    logic [`NE-1:0]	        OldExp;     // the old exponent
    logic                   Signed;     // is the opperation with a signed integer?
    logic                   Int64;      // is the integer 64 bits?
    logic                   IntToFp;       // is the opperation an int->fp conversion?
    logic                   ToInt;      // is the opperation an fp->int conversion?
    logic [`LOGCVTLEN-1:0] ZeroCnt; // output from the LZC


    // seperate OpCtrl for code readability
    assign Signed = FOpCtrlE[0];
    assign Int64 =  FOpCtrlE[1];
    assign IntToFp =   FOpCtrlE[2];
    assign ToInt =  FWriteIntE;

    // choose the ouptut format depending on the opperation
    //      - fp -> fp: OpCtrl contains the percision of the output
    //      - int -> fp: FmtE contains the percision of the output
    if (`FPSIZES == 2) 
        assign OutFmt = IntToFp ? FmtE : (FOpCtrlE[1:0] == `FMT); 
    else if (`FPSIZES == 3 | `FPSIZES == 4) 
        assign OutFmt = IntToFp ? FmtE : FOpCtrlE[1:0]; 


    ///////////////////////////////////////////////////////////////////////////
    // negation
    ///////////////////////////////////////////////////////////////////////////
    // 1) negate the input if the input is a negitive singed integer
    // 2) trim the input to the proper size (kill the 32 most significant zeroes if needed)

    assign PosInt = CvtResSgnE ? -ForwardedSrcAE : ForwardedSrcAE;
    assign TrimInt = {{`XLEN-32{Int64}}, {32{1'b1}}} & PosInt;
    assign IntZeroE = ~|TrimInt;

    ///////////////////////////////////////////////////////////////////////////
    // lzc 
    ///////////////////////////////////////////////////////////////////////////
    
    // choose the input to the leading zero counter i.e. priority encoder
    //             int -> fp : | positive integer | 00000... (if needed) | 
    //             fp  -> fp : | fraction         | 00000... (if needed) | 
    assign CvtLzcInE = IntToFp ? {TrimInt, {`CVTLEN-`XLEN{1'b0}}} :
                             {XManE[`NF-1:0], {`CVTLEN-`NF{1'b0}}};
    
    lzc #(`CVTLEN) lzc (.num(CvtLzcInE), .ZeroCnt);

    ///////////////////////////////////////////////////////////////////////////
    // shifter
    ///////////////////////////////////////////////////////////////////////////

    // kill the shift if it's negitive
    // select the amount to shift by
    //      fp -> int: 
    //          - shift left by CalcExp - essentially shifting until the unbiased exponent = 0
    //              - don't shift if supposed to shift right (underflowed or denorm input)
    //      denormalized/undeflowed result fp -> fp:
    //          - shift left by NF-1+CalcExp - to shift till the biased expoenent is 0
    //      ??? -> fp: 
    //          - shift left by ZeroCnt+1 - to shift till the result is normalized
    //              - only shift fp -> fp if the intital value is denormalized
    //                  - this is a problem because the input to the lzc was the fraction rather than the mantissa
    //                  - rather have a few and-gates than an extra bit in the priority encoder??? *** is this true?
    assign CvtShiftAmtE = ToInt ? CvtCalcExpE[`LOGCVTLEN-1:0]&{`LOGCVTLEN{~CvtCalcExpE[`NE]}} :
                    CvtResDenormUfE&~IntToFp ? (`LOGCVTLEN)'(`NF-1)+CvtCalcExpE[`LOGCVTLEN-1:0] : 
                              (ZeroCnt+1)&{`LOGCVTLEN{XDenormE|IntToFp}};
    
    ///////////////////////////////////////////////////////////////////////////
    // exp calculations
    ///////////////////////////////////////////////////////////////////////////


    // *** possible optimizaations:
        //  - if subtracting exp by bias only the msb needs a full adder, the rest can be HA - dunno how to implement this for synth
        //  - Smaller exp -> Larger Exp can be calculated with: *** can use in Other units??? FMA??? insert this thing in later
        //          Exp if in range: {~Exp[SNE-1], Exp[SNE-2:0]}
        //          Exp in range if: Exp[SNE-1] = 1 & Exp[LNE-2:SNE] = 1111... & Exp[LNE-1] = 0 | Exp[SNE-1] = 0 & Exp[LNE-2:SNE] = 000... & Exp[LNE-1] = 1
        //                     i.e.: &Exp[LNE-2:SNE-1] xor Exp[LNE-1]
        //          Too big if:      Exp[LNE-1] = 1
        //          Too small if:    none of the above

    // Select the bias of the output
    //      fp -> int : select 1
    //      ??? -> fp : pick the new bias depending on the output format 
    if (`FPSIZES == 1) begin
        assign NewBias = ToInt ? (`NE-1)'(1) : (`NE-1)'(`BIAS); 

    end else if (`FPSIZES == 2) begin
        assign NewBias = ToInt ? (`NE-1)'(1) : OutFmt ? (`NE-1)'(`BIAS) : (`NE-1)'(`BIAS1); 

    end else if (`FPSIZES == 3) begin
        logic [`NE-2:0] NewBiasToFp;
        always_comb
            case (OutFmt)
                `FMT: NewBiasToFp =  (`NE-1)'(`BIAS);
                `FMT1: NewBiasToFp = (`NE-1)'(`BIAS1);
                `FMT2: NewBiasToFp = (`NE-1)'(`BIAS2);
                default: NewBiasToFp = {`NE-1{1'bx}};
            endcase
        assign NewBias = ToInt ? (`NE-1)'(1) : NewBiasToFp; 

    end else if (`FPSIZES == 4) begin        
        logic [`NE-2:0] NewBiasToFp;
        always_comb
            case (OutFmt)
                2'h3: NewBiasToFp =  (`NE-1)'(`Q_BIAS);
                2'h1: NewBiasToFp =  (`NE-1)'(`D_BIAS);
                2'h0: NewBiasToFp =  (`NE-1)'(`S_BIAS);
                2'h2: NewBiasToFp =  (`NE-1)'(`H_BIAS);
            endcase
        assign NewBias = ToInt ? (`NE-1)'(1) : NewBiasToFp; 
    end
    // select the old exponent
    //      int -> fp : largest bias + XLEN
    //      fp -> ??? : XExp
    assign OldExp = IntToFp ? (`NE)'(`BIAS)+(`NE)'(`XLEN) : XExpE;
    
    // calculate CalcExp
    //      fp -> fp : 
    //          - XExp - Largest bias + new bias - (ZeroCnt+1)
    //                                          only do ^ if the input was denormalized
    //              - convert the expoenent to the final preciaion (Exp - oldBias + newBias)
    //              - correct the expoent when there is a normalization shift ( + ZeroCnt+1) 
    //      fp -> int : XExp - Largest Bias + 1 - (ZeroCnt+1)
    //          |  `XLEN  zeros |     Mantissa      | 0's if nessisary | << CalcExp
    //          process:
    //              - start
    //                  |  `XLEN  zeros     |     Mantissa      | 0's if nessisary |
    //
    //              - shift left 1 (1)
    //                  | `XLEN-1 zeros |bit|     frac      | 0's if nessisary |
    //                                      . <- binary point
    //
    //              - shift left till unbiased exponent is 0 (XExp - Largest Bias)
    //                  |  0's |     Mantissa      |      0's if nessisary     |
    //                  |     keep        |
    //
    //              - if the input is denormalized then we dont shift... so the  "- (ZeroCnt+1)" is just leftovers from other options
    //      int -> fp : largest bias +  XLEN - Largest bias + new bias - 1 - ZeroCnt = XLEN + NewBias - 1 - ZeroCnt
    //              Process:
    //                  - shifted right by XLEN (XLEN)
    //                  - shift left to normilize (-1-ZeroCnt)
    //                  - newBias to make the biased exponent
    //          oldexp - biasold +newbias - (ZeroCnt+1)&(XDenormE|IntToFp)
    assign CvtCalcExpE = {1'b0, OldExp} - (`NE+1)'(`BIAS) + {2'b0, NewBias} - {{`NE{1'b0}}, XDenormE|IntToFp} - {{`NE-`LOGCVTLEN+1{1'b0}}, (ZeroCnt&{`LOGCVTLEN{XDenormE|IntToFp}})};
    // find if the result is dnormal or underflows
    //      - if Calculated expoenent is 0 or negitive (and the input/result is not exactaly 0)
    //      - can't underflow an integer to Fp conversion
    assign CvtResDenormUfE = (~|CvtCalcExpE | CvtCalcExpE[`NE])&~XZeroE&~IntToFp;

    
    ///////////////////////////////////////////////////////////////////////////
    // sign
    ///////////////////////////////////////////////////////////////////////////

    // determine the sign of the result
    //      - if int -> fp
    //          - if 64-bit : check the msb of the 64-bit integer input and if it's signed
    //          - if 32-bit : check the msb of the 32-bit integer input and if it's signed
    //      - otherwise: the floating point input's sign
    assign CvtResSgnE = IntToFp ? Int64 ? ForwardedSrcAE[`XLEN-1]&Signed : ForwardedSrcAE[31]&Signed : XSgnE;

endmodule


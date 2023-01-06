///////////////////////////////////////////
// cvtshiftcalc.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Conversion shift calculation
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

module cvtshiftcalc(
    input logic                     XZero,      // is the input zero?
    input logic                     ToInt,      // to integer conversion?
    input logic                     IntToFp,    // interger to floating point conversion?
    input logic  [`NE:0]            CvtCe,      // the calculated expoent
    input logic  [`NF:0]            Xm,         // input mantissas
    input logic  [`FMTBITS-1:0]     OutFmt,     // output format
    input logic  [`CVTLEN-1:0]      CvtLzcIn,   // input to the Leading Zero Counter (priority encoder)
    input logic                     CvtResSubnormUf, // is the conversion result subnormal or underlows
    output logic                    CvtResUf,       // does the cvt result unerflow
    output logic [`CVTLEN+`NF:0]    CvtShiftIn      // number to be shifted
);
    logic [$clog2(`NF):0]	ResNegNF;   // the result's fraction length negated (-NF)


    ///////////////////////////////////////////////////////////////////////////
    // shifter
    ///////////////////////////////////////////////////////////////////////////

    // seclect the input to the shifter
    //      fp  -> int:
    //          |  `XLEN  zeros |     Mantissa      | 0's if nessisary |
    //                          .
    //          Other problems:
    //              - if shifting to the right (neg CalcExp) then don't a 1 in the round bit (to prevent an incorrect plus 1 later durring rounding)
    //              - we do however want to keep the one in the sticky bit so set one of bits in the sticky bit area to 1
    //                  - ex: for the case 0010000.... (double)
    //      ??? -> fp:
    //          - if result is Subnormalized or underflowed then we want to shift right i.e. shift right then shift left:
    //              |  `NF-1  zeros   |     Mantissa      | 0's if nessisary | 
    //              .
    //          - otherwise:
    //              |     LzcInM      | 0's if nessisary | 
    //              .
    // change to int shift to the left one

    always_comb //                                            get rid of round bit if needed
    //                                                        |                    add sticky bit if needed
        if (ToInt)               CvtShiftIn = {{`XLEN{1'b0}}, Xm[`NF]&~CvtCe[`NE], Xm[`NF-1]|(CvtCe[`NE]&Xm[`NF]), Xm[`NF-2:0], {`CVTLEN-`XLEN{1'b0}}};
        else if (CvtResSubnormUf) CvtShiftIn = {{`NF-1{1'b0}}, Xm, {`CVTLEN-`NF+1{1'b0}}};
        else                     CvtShiftIn = {CvtLzcIn, {`NF+1{1'b0}}};
    
    // choose the negative of the fraction size
    if (`FPSIZES == 1) begin
        assign ResNegNF = -($clog2(`NF)+1)'(`NF); 

    end else if (`FPSIZES == 2) begin
        assign ResNegNF = OutFmt ? -($clog2(`NF)+1)'(`NF) : -($clog2(`NF)+1)'(`NF1);

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT:  ResNegNF = -($clog2(`NF)+1)'(`NF);
                `FMT1: ResNegNF = -($clog2(`NF)+1)'(`NF1);
                `FMT2: ResNegNF = -($clog2(`NF)+1)'(`NF2);
                default: ResNegNF = 1'bx;
            endcase

    end else if (`FPSIZES == 4) begin        
        always_comb
            case (OutFmt)
                2'h3: ResNegNF = -($clog2(`NF)+1)'(`Q_NF);
                2'h1: ResNegNF = -($clog2(`NF)+1)'(`D_NF);
                2'h0: ResNegNF = -($clog2(`NF)+1)'(`S_NF);
                2'h2: ResNegNF = -($clog2(`NF)+1)'(`H_NF);
            endcase
    end
    // determine if the result underflows ??? -> fp
    //      - if the first 1 is shifted out of the result then the result underflows
    //      - can't underflow an integer to fp conversions
    assign CvtResUf = ($signed(CvtCe) < $signed({{`NE-$clog2(`NF){1'b1}}, ResNegNF}))&~XZero&~IntToFp;
   
endmodule
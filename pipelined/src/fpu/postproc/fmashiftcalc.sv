///////////////////////////////////////////
// fmashiftcalc.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Fma shift calculation
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

module fmashiftcalc(
    input logic  [3*`NF+5:0]            FmaSm,       // the positive sum
    input logic  [$clog2(3*`NF+7)-1:0]  FmaSCnt,   // normalization shift count
    input logic  [`FMTBITS-1:0]         Fmt,       // precision 1 = double 0 = single
    input logic [`NE+1:0] FmaSe,
    output logic [`NE+1:0]              NormSumExp,          // exponent of the normalized sum not taking into account denormal or zero results
    output logic                        FmaSZero,    // is the result denormalized - calculated before LZA corection
    output logic                        FmaPreResultDenorm,    // is the result denormalized - calculated before LZA corection
    output logic [$clog2(3*`NF+7)-1:0]  FmaShiftAmt,   // normalization shift count
    output logic [3*`NF+7:0]            FmaShiftIn        // is the sum zero
);
    logic [`NE+1:0]             PreNormSumExp;       // the exponent of the normalized sum with the `FLEN bias
    logic [`NE+1:0] BiasCorr;

    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////
    //*** insert bias-bias simplification in fcvt.sv/phone pictures
    // Determine if the sum is zero
    assign FmaSZero = ~(|FmaSm);
    // calculate the sum's exponent
    assign PreNormSumExp = FmaSe + {{`NE+2-$unsigned($clog2(3*`NF+7)){1'b1}}, ~FmaSCnt} + (`NE+2)'(`NF+4);

    //convert the sum's exponent into the proper percision
    if (`FPSIZES == 1) begin
        assign NormSumExp = PreNormSumExp;

    end else if (`FPSIZES == 2) begin
        assign BiasCorr = Fmt ? (`NE+2)'(0) : (`NE+2)'(`BIAS1-`BIAS);
        assign NormSumExp = PreNormSumExp+BiasCorr;
        
    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (Fmt)
                `FMT: BiasCorr =  '0;
                `FMT1: BiasCorr = (`NE+2)'(`BIAS1-`BIAS);
                `FMT2: BiasCorr = (`NE+2)'(`BIAS2-`BIAS);
                default: BiasCorr = 'x;
            endcase
        end
        assign NormSumExp = PreNormSumExp+BiasCorr;

    end else if (`FPSIZES == 4) begin
        always_comb begin
            case (Fmt)
                2'h3: BiasCorr = '0;
                2'h1: BiasCorr = (`NE+2)'(`D_BIAS-`Q_BIAS);
                2'h0: BiasCorr = (`NE+2)'(`S_BIAS-`Q_BIAS);
                2'h2: BiasCorr = (`NE+2)'(`H_BIAS-`Q_BIAS);
            endcase
        end
        assign NormSumExp = PreNormSumExp+BiasCorr;

    end
    
    // determine if the result is denormalized
    
    if (`FPSIZES == 1) begin
        logic Sum0LEZ, Sum0GEFL;
        assign Sum0LEZ  = PreNormSumExp[`NE+1] | ~|PreNormSumExp;
        assign Sum0GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF-2));
        assign FmaPreResultDenorm = Sum0LEZ & Sum0GEFL & ~FmaSZero;

    end else if (`FPSIZES == 2) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL;
        assign Sum0LEZ  = PreNormSumExp[`NE+1] | ~|PreNormSumExp;
        assign Sum0GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF-2));
        assign Sum1LEZ  = $signed(PreNormSumExp) <= $signed((`NE+2)'(`BIAS-`BIAS1));
        assign Sum1GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF1-2+`BIAS-`BIAS1)) | ~|PreNormSumExp;
        assign FmaPreResultDenorm = (Fmt ? Sum0LEZ : Sum1LEZ) & (Fmt ? Sum0GEFL : Sum1GEFL) & ~FmaSZero;

    end else if (`FPSIZES == 3) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL, Sum2LEZ, Sum2GEFL;
        assign Sum0LEZ  = PreNormSumExp[`NE+1] | ~|PreNormSumExp;
        assign Sum0GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF-2));
        assign Sum1LEZ  = $signed(PreNormSumExp) <= $signed((`NE+2)'(`BIAS-`BIAS1));
        assign Sum1GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF1-2+`BIAS-`BIAS1)) | ~|PreNormSumExp;
        assign Sum2LEZ  = $signed(PreNormSumExp) <= $signed((`NE+2)'(`BIAS-`BIAS2));
        assign Sum2GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF2-2+`BIAS-`BIAS2)) | ~|PreNormSumExp;
        always_comb begin
            case (Fmt)
                `FMT: FmaPreResultDenorm = Sum0LEZ & Sum0GEFL & ~FmaSZero;
                `FMT1: FmaPreResultDenorm = Sum1LEZ & Sum1GEFL & ~FmaSZero;
                `FMT2: FmaPreResultDenorm = Sum2LEZ & Sum2GEFL & ~FmaSZero;
                default: FmaPreResultDenorm = 1'bx;
            endcase
        end

    end else if (`FPSIZES == 4) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL, Sum2LEZ, Sum2GEFL, Sum3LEZ, Sum3GEFL;
        assign Sum0LEZ  = PreNormSumExp[`NE+1] | ~|PreNormSumExp;
        assign Sum0GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF-2));
        assign Sum1LEZ  = $signed(PreNormSumExp) <= $signed((`NE+2)'(`BIAS-`D_BIAS));
        assign Sum1GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`D_NF-2+`BIAS-`D_BIAS)) | ~|PreNormSumExp;
        assign Sum2LEZ  = $signed(PreNormSumExp) <= $signed((`NE+2)'(`BIAS-`S_BIAS));
        assign Sum2GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`S_NF-2+`BIAS-`S_BIAS)) | ~|PreNormSumExp;
        assign Sum3LEZ  = $signed(PreNormSumExp) <= $signed((`NE+2)'(`BIAS-`H_BIAS));
        assign Sum3GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`H_NF-2+`BIAS-`H_BIAS)) | ~|PreNormSumExp;
        always_comb begin
            case (Fmt)
                2'h3: FmaPreResultDenorm = Sum0LEZ & Sum0GEFL & ~FmaSZero;
                2'h1: FmaPreResultDenorm = Sum1LEZ & Sum1GEFL & ~FmaSZero;
                2'h0: FmaPreResultDenorm = Sum2LEZ & Sum2GEFL & ~FmaSZero;
                2'h2: FmaPreResultDenorm = Sum3LEZ & Sum3GEFL & ~FmaSZero;
            endcase
        end

    end

    // 010. when should be 001.
    //      - shift left one
    //      - add one from exp
    //      - if kill prod dont add to exp

    // Determine if the result is denormal
    // assign FmaPreResultDenorm = $signed(NormSumExp)<=0 & ($signed(NormSumExp)>=$signed(-FracLen)) & ~FmaSZero;

    // set and calculate the shift input and amount
    //  - shift once if killing a product and the result is denormalized
    assign FmaShiftIn = {2'b0, FmaSm};
    if (`FPSIZES == 1)
        assign FmaShiftAmt = FmaPreResultDenorm ? FmaSe[$clog2(3*`NF+7)-1:0]+($clog2(3*`NF+7))'(`NF+3): FmaSCnt+1;
    else
        assign FmaShiftAmt = FmaPreResultDenorm ? FmaSe[$clog2(3*`NF+7)-1:0]+($clog2(3*`NF+7))'(`NF+3)+BiasCorr[$clog2(3*`NF+7)-1:0]: FmaSCnt+1;
endmodule

///////////////////////////////////////////
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
    input logic  [3*`NF+5:0]            SumM,       // the positive sum
    input logic  [`NE-1:0]              Ze,      // exponent of Z
    input logic  [`NE+1:0]              ProdExpM,   // X exponent + Y exponent - bias
    input logic  [$clog2(3*`NF+7)-1:0]  FmaNormCntM,   // normalization shift count
    input logic  [`FMTBITS-1:0]         Fmt,       // precision 1 = double 0 = single
    input logic                         KillProdM,  // is the product set to zero
    input logic 			            ZDenormM,
    output logic [`NE+1:0]              ConvNormSumExp,          // exponent of the normalized sum not taking into account denormal or zero results
    output logic                        SumZero,    // is the result denormalized - calculated before LZA corection
    output logic                        PreResultDenorm,    // is the result denormalized - calculated before LZA corection
    output logic [$clog2(3*`NF+7)-1:0]  FmaShiftAmt,   // normalization shift count
    output logic [3*`NF+8:0]            FmaShiftIn        // is the sum zero
);
    logic [$clog2(3*`NF+7)-1:0] DenormShift;        // right shift if the result is denormalized //***change this later
    logic [`NE+1:0]             NormSumExp;       // the exponent of the normalized sum with the `FLEN bias

    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////
    //*** insert bias-bias simplification in fcvt.sv/phone pictures
    // Determine if the sum is zero
    assign SumZero = ~(|SumM);

    // calculate the sum's exponent
    assign NormSumExp = KillProdM ? {2'b0, Ze[`NE-1:1], Ze[0]&~ZDenormM} : ProdExpM + -{{`NE+2-$unsigned($clog2(3*`NF+7)){1'b0}}, FmaNormCntM} - 1 + (`NE+2)'(`NF+4);

    //convert the sum's exponent into the proper percision
    if (`FPSIZES == 1) begin
        assign ConvNormSumExp = NormSumExp;

    end else if (`FPSIZES == 2) begin
        assign ConvNormSumExp = Fmt ? NormSumExp : (NormSumExp-(`NE+2)'(`BIAS)+(`NE+2)'(`BIAS1))&{`NE+2{|NormSumExp}};

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (Fmt)
                `FMT: ConvNormSumExp = NormSumExp;
                `FMT1: ConvNormSumExp = (NormSumExp-(`NE+2)'(`BIAS)+(`NE+2)'(`BIAS1))&{`NE+2{|NormSumExp}};
                `FMT2: ConvNormSumExp = (NormSumExp-(`NE+2)'(`BIAS)+(`NE+2)'(`BIAS2))&{`NE+2{|NormSumExp}};
                default: ConvNormSumExp = {`NE+2{1'bx}};
            endcase
        end

    end else if (`FPSIZES == 4) begin
        always_comb begin
            case (Fmt)
                2'h3: ConvNormSumExp = NormSumExp;
                2'h1: ConvNormSumExp = (NormSumExp-(`NE+2)'(`BIAS)+(`NE+2)'(`D_BIAS))&{`NE+2{|NormSumExp}};
                2'h0: ConvNormSumExp = (NormSumExp-(`NE+2)'(`BIAS)+(`NE+2)'(`S_BIAS))&{`NE+2{|NormSumExp}};
                2'h2: ConvNormSumExp = (NormSumExp-(`NE+2)'(`BIAS)+(`NE+2)'(`H_BIAS))&{`NE+2{|NormSumExp}};
            endcase
        end

    end
    
    // determine if the result is denormalized
    
    if (`FPSIZES == 1) begin
        logic Sum0LEZ, Sum0GEFL;
        assign Sum0LEZ  = NormSumExp[`NE+1] | ~|NormSumExp;
        assign Sum0GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`NF)-(`NE+2)'(2));
        assign PreResultDenorm = Sum0LEZ & Sum0GEFL & ~SumZero;

    end else if (`FPSIZES == 2) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL;
        assign Sum0LEZ  = NormSumExp[`NE+1] | ~|NormSumExp;
        assign Sum0GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`NF)-(`NE+2)'(2));
        assign Sum1LEZ  = $signed(NormSumExp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1));
        assign Sum1GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`NF1+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1)) | ~|NormSumExp;
        assign PreResultDenorm = (Fmt ? Sum0LEZ : Sum1LEZ) & (Fmt ? Sum0GEFL : Sum1GEFL) & ~SumZero;

    end else if (`FPSIZES == 3) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL, Sum2LEZ, Sum2GEFL;
        assign Sum0LEZ  = NormSumExp[`NE+1] | ~|NormSumExp;
        assign Sum0GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`NF)-(`NE+2)'(2));
        assign Sum1LEZ  = $signed(NormSumExp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1));
        assign Sum1GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`NF1+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1)) | ~|NormSumExp;
        assign Sum2LEZ  = $signed(NormSumExp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`BIAS2));
        assign Sum2GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`NF2+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`BIAS2)) | ~|NormSumExp;
        always_comb begin
            case (Fmt)
                `FMT: PreResultDenorm = Sum0LEZ & Sum0GEFL & ~SumZero;
                `FMT1: PreResultDenorm = Sum1LEZ & Sum1GEFL & ~SumZero;
                `FMT2: PreResultDenorm = Sum2LEZ & Sum2GEFL & ~SumZero;
                default: PreResultDenorm = 1'bx;
            endcase
        end

    end else if (`FPSIZES == 4) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL, Sum2LEZ, Sum2GEFL, Sum3LEZ, Sum3GEFL;
        assign Sum0LEZ  = NormSumExp[`NE+1] | ~|NormSumExp;
        assign Sum0GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`NF  )-(`NE+2)'(2));
        assign Sum1LEZ  = $signed(NormSumExp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`D_BIAS));
        assign Sum1GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`D_NF+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`D_BIAS)) | ~|NormSumExp;
        assign Sum2LEZ  = $signed(NormSumExp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`S_BIAS));
        assign Sum2GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`S_NF+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`S_BIAS)) | ~|NormSumExp;
        assign Sum3LEZ  = $signed(NormSumExp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`H_BIAS));
        assign Sum3GEFL = $signed(NormSumExp) >= $signed(-(`NE+2)'(`H_NF+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`H_BIAS)) | ~|NormSumExp;
        always_comb begin
            case (Fmt)
                2'h3: PreResultDenorm = Sum0LEZ & Sum0GEFL & ~SumZero;
                2'h1: PreResultDenorm = Sum1LEZ & Sum1GEFL & ~SumZero;
                2'h0: PreResultDenorm = Sum2LEZ & Sum2GEFL & ~SumZero;
                2'h2: PreResultDenorm = Sum3LEZ & Sum3GEFL & ~SumZero;
            endcase // *** remove checking to see if it's underflowed and only check for less than zero for denorm checking
        end

    end

    // 010. when should be 001.
    //      - shift left one
    //      - add one from exp
    //      - if kill prod dont add to exp

    // Determine if the result is denormal
    // assign PreResultDenorm = $signed(ConvNormSumExp)<=0 & ($signed(ConvNormSumExp)>=$signed(-FracLen)) & ~SumZero;

    // Determine the shift needed for denormal results
    //  - if not denorm add 1 to shift out the leading 1
    assign DenormShift = PreResultDenorm&~KillProdM ? ConvNormSumExp[$clog2(3*`NF+7)-1:0] : 1;
    // set and calculate the shift input and amount
    //  - shift once if killing a product and the result is denormalized
    assign FmaShiftIn = {3'b0, SumM};
    assign FmaShiftAmt = (FmaNormCntM&{$clog2(3*`NF+7){~KillProdM}})+DenormShift;
endmodule

///////////////////////////////////////////
// fmashiftcalc.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: FMA shift calculation
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

`include "wally-config.vh"

module fmashiftcalc(
  input  logic [`FMTBITS-1:0]         Fmt,            // precision 1 = double 0 = single
  input  logic [`NE+1:0]              FmaSe,          // sum's exponent
  input  logic [3*`NF+3:0]            FmaSm,          // the positive sum
  input  logic [$clog2(3*`NF+5)-1:0]  FmaSCnt,        // normalization shift count
  output logic [`NE+1:0]              NormSumExp,     // exponent of the normalized sum not taking into account Subnormal or zero results
  output logic                        FmaSZero,       // is the result subnormal - calculated before LZA corection
  output logic                        FmaPreResultSubnorm, // is the result subnormal - calculated before LZA corection
  output logic [$clog2(3*`NF+5)-1:0]  FmaShiftAmt,    // normalization shift count
  output logic [3*`NF+5:0]            FmaShiftIn      // is the sum zero
);
  logic [`NE+1:0] PreNormSumExp;  // the exponent of the normalized sum with the `FLEN bias
  logic [`NE+1:0] BiasCorr;       // correction for bias

  ///////////////////////////////////////////////////////////////////////////////
  // Normalization
  ///////////////////////////////////////////////////////////////////////////////

  // Determine if the sum is zero
  assign FmaSZero = ~(|FmaSm);

  // calculate the sum's exponent
  assign PreNormSumExp = FmaSe + {{`NE+2-$unsigned($clog2(3*`NF+5)){1'b1}}, ~FmaSCnt} + (`NE+2)'(`NF+3);

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
  
  // determine if the result is subnormal: (NormSumExp <= 0) & (NormSumExp >= -FracLen) & ~FmaSZero
  if (`FPSIZES == 1) begin
    logic Sum0LEZ, Sum0GEFL;
    assign Sum0LEZ  = PreNormSumExp[`NE+1] | ~|PreNormSumExp;
    assign Sum0GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF-2));
    assign FmaPreResultSubnorm = Sum0LEZ & Sum0GEFL & ~FmaSZero;
  end else if (`FPSIZES == 2) begin
    logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL;
    assign Sum0LEZ  = PreNormSumExp[`NE+1] | ~|PreNormSumExp;
    assign Sum0GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF-2));
    assign Sum1LEZ  = $signed(PreNormSumExp) <= $signed((`NE+2)'(`BIAS-`BIAS1));
    assign Sum1GEFL = $signed(PreNormSumExp) >= $signed((`NE+2)'(-`NF1-2+`BIAS-`BIAS1)) | ~|PreNormSumExp;
    assign FmaPreResultSubnorm = (Fmt ? Sum0LEZ : Sum1LEZ) & (Fmt ? Sum0GEFL : Sum1GEFL) & ~FmaSZero;
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
        `FMT: FmaPreResultSubnorm = Sum0LEZ & Sum0GEFL & ~FmaSZero;
        `FMT1: FmaPreResultSubnorm = Sum1LEZ & Sum1GEFL & ~FmaSZero;
        `FMT2: FmaPreResultSubnorm = Sum2LEZ & Sum2GEFL & ~FmaSZero;
        default: FmaPreResultSubnorm = 1'bx;
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
        2'h3: FmaPreResultSubnorm = Sum0LEZ & Sum0GEFL & ~FmaSZero;
        2'h1: FmaPreResultSubnorm = Sum1LEZ & Sum1GEFL & ~FmaSZero;
        2'h0: FmaPreResultSubnorm = Sum2LEZ & Sum2GEFL & ~FmaSZero;
        2'h2: FmaPreResultSubnorm = Sum3LEZ & Sum3GEFL & ~FmaSZero;
      endcase
    end
  end

  // set and calculate the shift input and amount
  //  - shift once if killing a product and the result is subnormal
  assign FmaShiftIn = {2'b0, FmaSm};
  if (`FPSIZES == 1) assign FmaShiftAmt = FmaPreResultSubnorm ? FmaSe[$clog2(3*`NF+5)-1:0]+($clog2(3*`NF+5))'(`NF+2): FmaSCnt+1;
  else               assign FmaShiftAmt = FmaPreResultSubnorm ? FmaSe[$clog2(3*`NF+5)-1:0]+($clog2(3*`NF+5))'(`NF+2)+BiasCorr[$clog2(3*`NF+5)-1:0]: FmaSCnt+1;
endmodule

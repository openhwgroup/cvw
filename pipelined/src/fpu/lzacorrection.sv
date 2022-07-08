///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: shift correction
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

module lzacorrection(
    input logic  [`NORMSHIFTSZ-1:0] Shifted,         // the shifted sum before LZA correction
    input logic                     FmaOp,
    input logic                     DivOp,
    input logic                     DivResDenorm,
    input logic  [`NE+1:0]          DivCalcExpM,
    input logic  [`NE+1:0]          DivDenormShift,
    input logic  [`NE+1:0]          ConvNormSumExp,          // exponent of the normalized sum not taking into account denormal or zero results
    input logic                     PreResultDenorm,    // is the result denormalized - calculated before LZA corection
    input logic                     KillProdM,  // is the product set to zero
    input logic                     SumZero,
    output logic [`CORRSHIFTSZ-1:0] CorrShifted,         // the shifted sum before LZA correction
    output logic [`NE+1:0]          CorrDivExp,
    output logic [`NE+1:0]          SumExp         // exponent of the normalized sum
);
    logic [3*`NF+5:0]      CorrSumShifted;     // the shifted sum after LZA correction
    logic [`CORRSHIFTSZ:0] CorrQuotShifted;
    logic                  ResDenorm;    // is the result denormalized
    logic                  LZAPlus1, LZAPlus2; // add one or two to the sum's exponent due to LZA correction

    // LZA correction
    assign LZAPlus1 = Shifted[`NORMSHIFTSZ-2];
    assign LZAPlus2 = Shifted[`NORMSHIFTSZ-1];
	// the only possible mantissa for a plus two is all zeroes - a one has to propigate all the way through a sum. so we can leave the bottom statement alone
    assign CorrSumShifted =  LZAPlus1 ? Shifted[`NORMSHIFTSZ-3:1] : Shifted[`NORMSHIFTSZ-4:0];
    //                        if the msb is 1 or the exponent was one, but the shifted quotent was < 1 (Denorm)
    assign CorrQuotShifted =  {LZAPlus2|(DivCalcExpM==1&~LZAPlus2) ? Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`CORRSHIFTSZ] : {Shifted[`NORMSHIFTSZ-2:`NORMSHIFTSZ-`CORRSHIFTSZ], 1'b0}, 1'b0};
    // if the result of the divider was calculated to be denormalized, then the result was correctly normalized, so select the top shifted bits
    assign CorrShifted = FmaOp ? {CorrSumShifted, {`CORRSHIFTSZ-(3*`NF+6){1'b0}}} : DivOp&~DivResDenorm ? CorrQuotShifted[`CORRSHIFTSZ-1:0] : Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`CORRSHIFTSZ];
    // Determine sum's exponent
    //                          if plus1                     If plus2                                      if said denorm but norm plus 1           if said denorm but norm plus 2
    assign SumExp = (ConvNormSumExp+{{`NE+1{1'b0}}, LZAPlus1&~KillProdM}+{{`NE{1'b0}}, LZAPlus2&~KillProdM, 1'b0}+{{`NE+1{1'b0}}, ~ResDenorm&PreResultDenorm&~KillProdM}+{{`NE+1{1'b0}}, &ConvNormSumExp&Shifted[3*`NF+6]&~KillProdM}) & {`NE+2{~(SumZero|ResDenorm)}};
    // recalculate if the result is denormalized
    assign ResDenorm = PreResultDenorm&~Shifted[`NORMSHIFTSZ-3]&~Shifted[`NORMSHIFTSZ-2];

    // the quotent is in the range [.5,2) if there is no early termination
    // if the quotent < 1 and not denormal then subtract 1 to account for the normalization shift
    assign CorrDivExp = ((DivResDenorm)&~DivDenormShift[`NE+1]) ? (`NE+2)'(0) : DivCalcExpM - {(`NE+1)'(0), ~LZAPlus2};
endmodule
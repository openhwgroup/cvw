///////////////////////////////////////////
// shiftcorrection.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: shift correction
// 
// A component of the CORE-V Wally configurable RISC-V project.
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

module shiftcorrection(
    input logic  [`NORMSHIFTSZ-1:0] Shifted,         // the shifted sum before LZA correction
    input logic                     FmaOp,
    input logic                     DivOp,
    input logic                     DivResSubnorm,
    input logic  [`NE+1:0]          DivQe,
    input logic                     DivSubnormShiftPos,
    input logic  [`NE+1:0]          NormSumExp,          // exponent of the normalized sum not taking into account Subnormal or zero results
    input logic                     FmaPreResultSubnorm,    // is the result Subnormalized - calculated before LZA corection
    input logic                     FmaSZero,
    output logic [`CORRSHIFTSZ-1:0] Mf,         // the shifted sum before LZA correction
    output logic [`NE+1:0]          Qe,
    output logic [`NE+1:0]          FmaMe         // exponent of the normalized sum
);
    logic [3*`NF+3:0]      CorrSumShifted;     // the shifted sum after LZA correction
    logic [`CORRSHIFTSZ-1:0] CorrQmShifted;
    logic                  ResSubnorm;    // is the result Subnormalized
    logic                  LZAPlus1; // add one or two to the sum's exponent due to LZA correction

    // LZA correction
    assign LZAPlus1 = Shifted[`NORMSHIFTSZ-1];
	// the only possible mantissa for a plus two is all zeroes - a one has to propigate all the way through a sum. so we can leave the bottom statement alone
    assign CorrSumShifted =  LZAPlus1 ? Shifted[`NORMSHIFTSZ-2:1] : Shifted[`NORMSHIFTSZ-3:0];
    //                        if the msb is 1 or the exponent was one, but the shifted quotent was < 1 (Subnorm)
    assign CorrQmShifted = (LZAPlus1|(DivQe==1&~LZAPlus1)) ? Shifted[`NORMSHIFTSZ-2:`NORMSHIFTSZ-`CORRSHIFTSZ-1] : Shifted[`NORMSHIFTSZ-3:`NORMSHIFTSZ-`CORRSHIFTSZ-2];
    // if the result of the divider was calculated to be Subnormalized, then the result was correctly normalized, so select the top shifted bits
    always_comb
        if(FmaOp)                       Mf = {CorrSumShifted, {`CORRSHIFTSZ-(3*`NF+4){1'b0}}};
        else if (DivOp&~DivResSubnorm)   Mf = CorrQmShifted;
        else                            Mf = Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`CORRSHIFTSZ];
    // Determine sum's exponent
    //                          if plus1                     If plus2                                      if said Subnorm but norm plus 1           if said Subnorm but norm plus 2
    assign FmaMe = (NormSumExp+{{`NE+1{1'b0}}, LZAPlus1} +{{`NE+1{1'b0}}, ~ResSubnorm&FmaPreResultSubnorm}) & {`NE+2{~(FmaSZero|ResSubnorm)}};
    // recalculate if the result is Subnormalized
    assign ResSubnorm = FmaPreResultSubnorm&~Shifted[`NORMSHIFTSZ-2]&~Shifted[`NORMSHIFTSZ-1];

    // the quotent is in the range [.5,2) if there is no early termination
    // if the quotent < 1 and not Subnormal then subtract 1 to account for the normalization shift
    assign Qe = (DivResSubnorm & DivSubnormShiftPos) ? '0 : DivQe - {(`NE+1)'(0), ~LZAPlus1};
endmodule
///////////////////////////////////////////
// divshiftcalc.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Division shift calculation
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
////////////////////////////////////////////////////////////////////////////////////////////////`include "wally-config.vh"

module divshiftcalc import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.DIVb:0]              DivQm,              // divsqrt significand
  input  logic [P.NE+1:0]              DivQe,              // divsqrt exponent
  output logic [P.LOGNORMSHIFTSZ-1:0]  DivShiftAmt,        // divsqrt shift amount
  output logic [P.NORMSHIFTSZ-1:0]     DivShiftIn,         // divsqrt shift input
  output logic                         DivResSubnorm,      // is the divsqrt result subnormal
  output logic                         DivSubnormShiftPos  // is the subnormal shift amount positive
);

  logic [P.LOGNORMSHIFTSZ-1:0]         NormShift;          // normalized result shift amount
  logic [P.LOGNORMSHIFTSZ-1:0]         DivSubnormShiftAmt; // subnormal result shift amount (killed if negitive)
  logic [P.NE+1:0]                     DivSubnormShift;    // subnormal result shift amount

  // is the result subnormal
  // if the exponent is 1 then the result needs to be normalized then the result is Subnormalizes
  assign DivResSubnorm = DivQe[P.NE+1]|(~|DivQe[P.NE+1:0]);

  // if the result is subnormal
  //  00000000x.xxxxxx...                     Exp = DivQe
  //  .00000000xxxxxxx... >> NF+1             Exp = DivQe+NF+1
  //  .00xxxxxxxxxxxxx... << DivQe+NF+1       Exp = +1
  //  .0000xxxxxxxxxxx... >> 1                Exp = 1
  // Left shift amount      = DivQe+NF+1-1
  assign DivSubnormShift    = (P.NE+2)'(P.NF)+DivQe;
  assign DivSubnormShiftPos = ~DivSubnormShift[P.NE+1];

  // if the result is normalized
  //  00000000x.xxxxxx...                     Exp = DivQe
  //  .00000000xxxxxxx... >> NF+1             Exp = DivQe+NF+1
  //  00000000.xxxxxxx... << NF               Exp = DivQe+1
  //  00000000x.xxxxxx... << NF               Exp = DivQe (extra shift done afterwards)
  //  00000000xx.xxxxx... << 1?               Exp = DivQe-1 (determined after)
  // inital Left shift amount  = NF
  // shift one more if the it's a minimally redundent radix 4 - one entire cycle needed for integer bit
  assign NormShift = (P.LOGNORMSHIFTSZ)'(P.NF);

  // if the shift amount is negitive then don't shift (keep sticky bit)
  // need to multiply the early termination shift by LOGR*DIVCOPIES =  left shift of log2(LOGR*DIVCOPIES)
  assign DivSubnormShiftAmt = DivSubnormShiftPos ? DivSubnormShift[P.LOGNORMSHIFTSZ-1:0] : '0;
  assign DivShiftAmt        = DivResSubnorm ? DivSubnormShiftAmt : NormShift;

  // pre-shift the divider result for normalization
  assign DivShiftIn = {{P.NF{1'b0}}, DivQm, {P.NORMSHIFTSZ-P.DIVb-1-P.NF{1'b0}}};
endmodule

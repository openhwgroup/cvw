///////////////////////////////////////////
// fmasign.sv
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: FMA Sign Logic
// 
// Documentation: RISC-V System on Chip Design Chapter 13 (Table 13.8)
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

module fmasign(    
  input  logic [2:0]  OpCtrl,     // opperation contol
  input  logic        Xs, Ys, Zs, // sign of the inputs
  output logic        Ps,         // the product's sign - takes opperation into account
  output logic        As,         // aligned addend sign used in fma - takes opperation into account
  output logic        InvA        // Effective subtraction: invert addend
);

  assign Ps = Xs ^ Ys ^ (OpCtrl[1]&~OpCtrl[2]); // product sign.  Negate for FMNADD or FNMSUB
  assign As = Zs^OpCtrl[0];                     // flip addend sign for subtraction
  assign InvA = As ^ Ps;                        // Effective subtraction when product and addend have opposite signs
endmodule

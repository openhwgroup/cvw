///////////////////////////////////////////
// fdivsqrtfgen2.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 2 F Addend Generator
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

module fdivsqrtfgen2 import cvw::*;  #(parameter cvw_t P) (
  input  logic              up, uz,
  input  logic [P.DIVb+3:0] C, U, UM,
  output logic [P.DIVb+3:0] F
);
  logic [P.DIVb+3:0]        FP, FN, FZ;

  // Generate for both positive and negative bits
  assign FP = ~(U << 1) & C;
  assign FN = (UM << 1) | (C & ~(C << 2));
  assign FZ = '0;

  always_comb     // Choose which adder input will be used
    if (up)       F = FP;
    else if (uz)  F = FZ;
    else          F = FN;
endmodule

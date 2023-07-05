///////////////////////////////////////////
// fdivsqrtfgen4.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 4 F Addend Generator
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

module fdivsqrtfgen4 import cvw::*;  #(parameter cvw_t P) (
  input  logic [3:0]        udigit,
  input  logic [P.DIVb+3:0] C, U, UM,
  output logic [P.DIVb+3:0] F
);
  logic [P.DIVb+3:0]        F2, F1, F0, FN1, FN2;
  
  // Generate for both positive and negative bits
  assign F2  = (~U << 2) & (C << 2);
  assign F1  = ~(U << 1) & C;
  assign F0  = '0;
  assign FN1 = (UM << 1) | (C & ~(C << 3));
  assign FN2 = (UM << 2) | ((C << 2) & ~(C << 4));

  // Choose which adder input will be used
  always_comb
    if (udigit[3])       F = F2;
    else if (udigit[2])  F = F1;
    else if (udigit[1])  F = FN1;
    else if (udigit[0])  F = FN2;
    else                 F = F0;
endmodule

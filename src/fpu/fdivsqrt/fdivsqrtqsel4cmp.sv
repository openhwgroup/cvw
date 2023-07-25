///////////////////////////////////////////
// fdivsqrtqsel4cmp.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Comparator-based Radix 4 Quotient Digit Selection
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

module fdivsqrtqsel4cmp (
  input  logic [2:0] Dmsbs,
  input  logic [4:0] Smsbs,
  input  logic [7:0] WSmsbs, WCmsbs,
  input  logic       SqrtE, j1,
  output logic [3:0] udigit
);
  logic [6:0] Wmsbs;
  logic [7:0] PreWmsbs;
  logic [2:0] A;

  assign PreWmsbs = WCmsbs + WSmsbs;
  assign Wmsbs = PreWmsbs[7:1];
  // D = 0001.xxx...
  // Dmsbs = |   |
  // W =      xxxx.xxx...
  // Wmsbs = |        |

  logic [6:0] mk2, mk1, mk0, mkm1;
  logic [6:0] mks2[7:0], mks1[7:0]; 

  // Prepopulate table of mks0
  assign mks2[0] = 12;
  assign mks2[1] = 14;
  assign mks2[2] = 16;
  assign mks2[3] = 17;
  assign mks2[4] = 18;
  assign mks2[5] = 20;
  assign mks2[6] = 22;
  assign mks2[7] = 23;
  assign mks1[0] = 4;
  assign mks1[1] = 4;
  assign mks1[2] = 6;
  assign mks1[3] = 6;
  assign mks1[4] = 6;
  assign mks1[5] = 8; // is the logic any cheaper if this is a 6?
  assign mks1[6] = 8;
  assign mks1[7] = 8;

  // Choose A for current operation
 always_comb
    if (SqrtE) begin 
      if (j1) A = 3'b101;
      else if (Smsbs == 5'b10000) A = 3'b111;
      else A = Smsbs[2:0];
    end else A = Dmsbs;

  // Choose selection constants based on a
  assign mk2 = mks2[A];
  assign mk1 = mks1[A];
  assign mk0 = -mks1[A];
  assign mkm1 = (A == 3'b000) ? -13 : -mks2[A]; // asymmetry in table
 
  // Compare residual W to selection constants to choose digit
  always_comb 
    if      ($signed(Wmsbs) >= $signed(mk2))  udigit = 4'b1000; // choose 2
    else if ($signed(Wmsbs) >= $signed(mk1))  udigit = 4'b0100; // choose 1
    else if ($signed(Wmsbs) >= $signed(mk0))  udigit = 4'b0000; // choose 0
    else if ($signed(Wmsbs) >= $signed(mkm1)) udigit = 4'b0010; // choose -1
    else                                      udigit = 4'b0001; // choose -2  
endmodule

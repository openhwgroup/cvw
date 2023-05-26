///////////////////////////////////////////
// tlbramline.sv
//
// Written: David_Harris@hmc.edu 4 July 2021
// Modified:
//
// Purpose: One line of the RAM, with enabled flip-flop and logic for reading into distributed OR
// 
// Documentation: RISC-V System on Chip Design Chapter 8
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

module tlbramline #(parameter WIDTH = 22)
  (input  logic             clk, reset,
   input  logic             re, we,
   input  logic [WIDTH-1:0] d,
   output logic [WIDTH-1:0] q,
   output logic             PTE_G);

   logic [WIDTH-1:0] line;

   flopenr #(WIDTH) pteflop(clk, reset, we, d, line);
   assign q = re ? line : 0;
   assign PTE_G = line[5]; // send global bit to CAM as part of ASID matching
endmodule

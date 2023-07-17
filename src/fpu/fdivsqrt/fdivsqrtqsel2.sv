///////////////////////////////////////////
// fdivsqrtqsel2.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 2 Quotient Digit Selection
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

module fdivsqrtqsel2 ( 
  input  logic [3:0] ps, pc, 
  output logic       up, uz, un
);
 
  logic [3:0]  p, g;
  logic        magnitude, sign;
 
  // The quotient selection logic is presented for simplicity, not
  // for efficiency.  You can probably optimize your logic to
  // select the proper divisor with less delay.

  // Quotient equations from EE371 lecture notes 13-20
  assign p = ps ^ pc;
  assign g = ps & pc;

  assign magnitude = ~((ps[2]^pc[2]) & (ps[1]^pc[1]) & 
        (ps[0]^pc[0]));
  assign sign = (ps[3]^pc[3])^
      (ps[2] & pc[2] | ((ps[2]^pc[2]) &
          (ps[1]&pc[1] | ((ps[1]^pc[1]) &
            (ps[0]&pc[0])))));

  // Produce digit = +1, 0, or -1
  assign up = magnitude & ~sign;
  assign uz = ~magnitude;
  assign un = magnitude & sign;
endmodule

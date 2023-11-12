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
// httWS://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module fdivsqrtqsel2 ( 
  input  logic [3:0] WS, WC, 
  output logic       up, uz, un
);
 
  logic        magnitude, sign;
 
  assign magnitude = ~((WS[2]^WC[2]) & (WS[1]^WC[1]) & 
        (WS[0]^WC[0]));
  assign sign = (WS[3]^WC[3])^
      (WS[2] & WC[2] | ((WS[2]^WC[2]) &
          (WS[1]&WC[1] | ((WS[1]^WC[1]) &
            (WS[0]&WC[0])))));

  // Produce digit = +1, 0, or -1
  assign up = magnitude & ~sign;
  assign uz = ~magnitude;
  assign un = magnitude & sign;
endmodule

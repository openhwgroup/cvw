///////////////////////////////////////////
// aes_mixcolumns.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu, David_Harris@hmc.edu
// Created: 20 February 2024
//
// Purpose: Galois field operation to an individual 32-bit word
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
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


module aes_Mixcolumns (
   input  logic [31:0] in,
   output logic [31:0] out);

   logic [7:0] in0, in1, in2, in3, out0, out1, out2, out3, t0, t1, t2, t3, temp;
   logic [15:0] rrot8_1, rrot8_2;

   assign {in0, in1, in2, in3} = in;
   assign temp = in0 ^ in1 ^ in2 ^ in3;

   galoismult_forward gm0 (in0^in1, t0);
   galoismult_forward gm1 (in1^in2, t1);
   galoismult_forward gm2 (in2^in3, t2);
   galoismult_forward gm3 (in3^in0, t3);

   assign out0 = in0 ^ temp ^ t3;
   assign out1 = in1 ^ temp ^ t0;
   assign out2 = in2 ^ temp ^ t1;
   assign out3 = in3 ^ temp ^ t2;
   
   assign out = {out0, out1, out2, out3};

endmodule

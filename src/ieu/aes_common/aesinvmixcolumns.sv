///////////////////////////////////////////
// aesinvmixcolumns.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 05 March 2024
//
// Purpose: AES Inverted Mix Column Function for use with AES
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

module aesinvmixcolumns(input logic [31:0] in, output logic [31:0] out);

   logic [7:0] in0, in1, in2, in3, temp;
   logic [10:0] xor0, xor1, xor2, xor3;
   
   assign {in0, in1, in2, in3} = in;
   assign temp = in0 ^ in1 ^ in2 ^ in3;

   assign xor0 = {temp, 3'b0} ^ {1'b0, in3^in1, 2'b0} ^ {2'b0, in3^in2, 1'b0} ^ {3'b0, temp} ^ {3'b0, in3};
   assign xor1 = {temp, 3'b0} ^ {1'b0, in2^in0, 2'b0} ^ {2'b0, in2^in1, 1'b0} ^ {3'b0, temp} ^ {3'b0, in2};
   assign xor2 = {temp, 3'b0} ^ {1'b0, in1^in3, 2'b0} ^ {2'b0, in1^in0, 1'b0} ^ {3'b0, temp} ^ {3'b0, in1};
   assign xor3 = {temp, 3'b0} ^ {1'b0, in0^in2, 2'b0} ^ {2'b0, in0^in3, 1'b0} ^ {3'b0, temp} ^ {3'b0, in0};

   galoismultinverse gm0 (xor0, out[7:0]);
   galoismultinverse gm1 (xor1, out[15:8]);
   galoismultinverse gm2 (xor2, out[23:16]);
   galoismultinverse gm3 (xor3, out[31:24]);

endmodule 

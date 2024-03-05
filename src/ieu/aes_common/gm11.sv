///////////////////////////////////////////
// gm11.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: Galois field operations for mix columns operation
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

module gm11(gm11_In, gm11_Out);
   
   input  logic [7:0] gm11_In;
   output logic [7:0] gm11_Out;

   // Internal Logic
   logic [7:0] 	      gm8_0_Out;
   logic [7:0] 	      gm2_0_Out;

   // Sub-Modules for sub-Galois operations
   gm8 gm8_0 (.gm8_In(gm11_In), .gm8_Out(gm8_0_Out));
   gm2 gm2_0 (.gm2_In(gm11_In), .gm2_Out(gm2_0_Out));

   // Set output to gm8(in) ^ gm2(in) ^ in
   assign gm11_Out = gm8_0_Out ^ gm2_0_Out ^ gm11_In;

endmodule 

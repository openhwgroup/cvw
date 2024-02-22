///////////////////////////////////////////
// gm3.sv
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

module gm3 (gm3_in, gm3_out);
   
   input logic [7:0] gm3_in;
   output logic [7:0] gm3_out;
   
   // Internal Logic
   logic [7:0] 	      gm2_0_out;
   
   // Sub-Modules for gm2 multiplication
   gm2 gm2_0 (.gm2_in(gm3_in), .gm2_out(gm2_0_out));
   
   // Assign Output
   assign gm3_out = gm2_0_out ^ gm3_in;
   
endmodule 
///////////////////////////////////////////
// galois_func.sv
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

module gm2 (gm2_in, gm2_out); 
   
   input logic [7:0]  gm2_in;
   output logic [7:0] gm2_out;
   
   // Set output to Galois Mult 2
   assign gm2_out = {gm2_in[6:0], 1'b0} ^ (8'h1b & {8{gm2_in[7]}});
   
endmodule 

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

module gm4 (gm4_in, gm4_out); 

   input logic [7:0] gm4_in;
   output logic [7:0] gm4_out;

   // Internal Logic
   logic [7:0] 	      gm2_0_out;
   logic [7:0] 	      gm2_1_out;

   // Sub-Modules for multiple gm2 multiplications
   gm2 gm2_0 (.gm2_in(gm4_in), .gm2_out(gm2_0_out));
   gm2 gm2_1 (.gm2_in(gm2_0_out), .gm2_out(gm2_1_out));

   // Assign output to second gm2 output
   assign gm4_out = gm2_1_out;

endmodule

module gm8 (gm8_in, gm8_out);
   
   input  logic [7:0] gm8_in;
   output logic [7:0] gm8_out;

   // Internal Logic
   logic [7:0] 	      gm2_0_out;
   logic [7:0] 	      gm4_0_out;

   // Sub-Modules for sub-Galois operations
   gm4 gm4_0 (.gm4_in(gm8_in), .gm4_out(gm4_0_out));
   gm2 gm2_0 (.gm2_in(gm4_0_out), .gm2_out(gm2_0_out));

   // Assign output to gm2 output
   assign gm8_out = gm2_0_out;

endmodule 

module gm9 (gm9_in, gm9_out);
   
   input  logic [7:0] gm9_in;
   output logic [7:0] gm9_out;

   // Internal Logic
   logic [7:0] 	      gm8_0_out;

   // Sub-Modules for sub-Galois operations
   gm8 gm8_0 (.gm8_in(gm9_in), .gm8_out(gm8_0_out));

   // Set output to gm8(in) ^ in
   assign gm9_out = gm8_0_out ^ gm9_in;

endmodule

module gm11 (gm11_in, gm11_out);
   
   input  logic [7:0] gm11_in;
   output logic [7:0] gm11_out;

   // Internal Logic
   logic [7:0] 	      gm8_0_out;
   logic [7:0] 	      gm2_0_out;

   // Sub-Modules for sub-Galois operations
   gm8 gm8_0 (.gm8_in(gm11_in), .gm8_out(gm8_0_out));
   gm2 gm2_0 (.gm2_in(gm11_in), .gm2_out(gm2_0_out));

   // Set output to gm8(in) ^ gm2(in) ^ in
   assign gm11_out = gm8_0_out ^ gm2_0_out ^ gm11_in;

endmodule 

module gm13 (gm13_in, gm13_out);

   input logic [7:0] gm13_in;
   output logic [7:0] gm13_out;

   // Internal Logic
   logic [7:0] 	      gm8_0_out;
   logic [7:0] 	      gm4_0_out;

   // Sub-Modules for sub-Galois operations
   gm8 gm8_0 (.gm8_in(gm13_in), .gm8_out(gm8_0_out));
   gm4 gm4_0 (.gm4_in(gm13_in), .gm4_out(gm4_0_out));

   // Set output to gm8(in) ^ gm4(in) ^ in
   assign gm13_out = gm8_0_out ^ gm4_0_out ^ gm13_in;

endmodule 

module gm14 (gm14_in, gm14_out);

   input  logic [7:0] gm14_in;
   output logic [7:0] gm14_out;

   // Internal Logic
   logic [7:0] 	      gm8_0_out;
   logic [7:0] 	      gm4_0_out;
   logic [7:0] 	      gm2_0_out;

   // Sub-Modules for sub-Galois operations
   gm8 gm8_0 (.gm8_in(gm14_in), .gm8_out(gm8_0_out));
   gm4 gm4_0 (.gm4_in(gm14_in), .gm4_out(gm4_0_out));
   gm2 gm2_0 (.gm2_in(gm14_in), .gm2_out(gm2_0_out));

   //Assign output to gm8(in) ^ gm4(in) ^ gm2(in)
   assign gm14_out = gm8_0_out ^ gm4_0_out ^ gm2_0_out;

endmodule 


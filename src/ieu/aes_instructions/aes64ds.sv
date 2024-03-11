///////////////////////////////////////////
// aes64ds.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes64ds instruction: RV64 final round decryption 
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

module aes64ds(
   input  logic [63:0] rs1,
   input  logic [63:0] rs2,
   output logic [63:0] DataOut
);
   
   logic [127:0] 		   ShiftRowOut;
   logic [31:0] 		   SboxOut0, SboxOut1;
   
   // Apply inverse shiftrows to rs2 and rs1
   aesinvshiftrow srow(.DataIn({rs2,rs1}), .DataOut(ShiftRowOut));
   
   // Apply full word inverse substitution to lower 2 words of shiftrow out
   aesinvsboxword inv_sbox_0(.in(ShiftRowOut[31:0]), .out(SboxOut0));
   aesinvsboxword inv_sbox_1(.in(ShiftRowOut[63:32]), .out(SboxOut1));
   
   // Concatenate the two substitution outputs to get result
   assign DataOut = {SboxOut1, SboxOut0};   
endmodule

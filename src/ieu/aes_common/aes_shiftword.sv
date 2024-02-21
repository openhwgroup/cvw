///////////////////////////////////////////
// aes_shiftword.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: AES Shiftrow shifting values
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

/*
 Purpose : This next module provides an alternative way to shift the values.
 in which it takes the shift number (essentially row number) as 
 an input and shifts cyclically to the left by that number of bits.
 the complexity here is removed from the module and is more complex in
 input selection.
 */

module aes_shiftword(input logic[1:0] shiftAmt, input logic [31:0]  dataIn,
		     output logic [31:0] dataOut);
   
   
   logic [7:0] 				 b0 = dataIn[7:0];
   logic [7:0] 				 b1 = dataIn[15:8];
   logic [7:0] 				 b2 = dataIn[23:16];
   logic [7:0] 				 b3 = dataIn[31:24];
   
   always_comb
     begin
	case(shiftAmt)	  
	  // 00 : Barrel Shift no bytes
	  2'b00 : dataOut = {b3, b2, b1, b0};
	  // 01 : Barrel Shift one byte
	  2'b01 : dataOut = {b0, b3, b2, b1};
	  // 10 : Barrel Shift two bytes
	  2'b10 : dataOut = {b1, b0, b3, b2};
	  // 11 : Barrel Shift three bytes
	  default : dataOut = {b2, b1, b0, b3};
	endcase
     end 
   
endmodule			

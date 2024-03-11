///////////////////////////////////////////
// rconlut128.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes64ks1i instruction
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

module rconlut128(
	input  logic [3:0] RD,
	output logic [7:0] rconOut
);
	
   always_comb
	case(RD)
	  4'h0 : rconOut = 8'h01;
	  4'h1 : rconOut = 8'h02;
	  4'h2 : rconOut = 8'h04;
	  4'h3 : rconOut = 8'h08;
	  4'h4 : rconOut = 8'h10;
	  4'h5 : rconOut = 8'h20;
	  4'h6 : rconOut = 8'h40;
	  4'h7 : rconOut = 8'h80;
	  4'h8 : rconOut = 8'h1b;
	  4'h9 : rconOut = 8'h36;
	  4'hA : rconOut = 8'h00;
	  default : rconOut = 8'h00;
	endcase	
endmodule

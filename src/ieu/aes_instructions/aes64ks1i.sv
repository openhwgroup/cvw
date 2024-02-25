///////////////////////////////////////////
// aes64ks1i.sv
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

module aes64ks1i(input logic [3:0] roundnum,
                 input logic [63:0]  rs1,
                 output logic [63:0] rd);                 
                 
   // Instantiate intermediary logic signals             
   logic [7:0] 			     rcon_preshift;
   logic [31:0] 		     rcon;
   logic 			     lastRoundFlag;
   logic [31:0] 		     rs1_rotate;
   logic [31:0] 		     tmp2;
   logic [31:0] 		     Sbox_Out;
   
   // Get rcon value from table
   rcon_lut_128 rc(.RD(roundnum), .rcon_out(rcon_preshift));    
   // Shift RCON value
   assign rcon = {24'b0, rcon_preshift};    
   // Flag will be set if roundnum = 0xA = 0b1010
   assign lastRoundFlag = roundnum[3] & ~roundnum[2] & roundnum[1] & ~roundnum[0];    
   // Get rotated value fo ruse in tmp2
   rrot8 rr(.x(rs1[63:32]), .result(rs1_rotate));    
   // Assign tmp2 to a mux based on lastRoundFlag
   assign tmp2 = lastRoundFlag ? rs1[63:32] : rs1_rotate;    
   // Substitute bytes of value obtained for tmp2 using Rijndael sbox
   aes_sbox_word sbox(.in(tmp2),.out(Sbox_Out));    
   assign rd[31:0] = Sbox_Out ^ rcon;
   assign rd[63:32] = Sbox_Out ^ rcon;
   
   // There may be some errors with this instruction.
   // Regression tests are passed successfully, but
   // the algorithm seems wrong. Check later.
	
endmodule

module rcon_lut_128(input logic [3:0] RD,
		    output logic [7:0] rcon_out);
	
   always_comb
     begin
	case(RD)
	  4'h0 : rcon_out = 8'h01;
	  4'h1 : rcon_out = 8'h02;
	  4'h2 : rcon_out = 8'h04;
	  4'h3 : rcon_out = 8'h08;
	  4'h4 : rcon_out = 8'h10;
	  4'h5 : rcon_out = 8'h20;
	  4'h6 : rcon_out = 8'h40;
	  4'h7 : rcon_out = 8'h80;
	  4'h8 : rcon_out = 8'h1b;
	  4'h9 : rcon_out = 8'h36;
	  4'hA : rcon_out = 8'h00;
	  default : rcon_out = 8'h00;
	endcase	
     end        

endmodule

module rrot8(input logic[31:0] x,
	     output logic [31:0] result);
   
   assign result[0] = x[8];
   assign result[1] = x[9];
   assign result[2] = x[10];
   assign result[3] = x[11];
   assign result[4] = x[12];
   assign result[5] = x[13];
   assign result[6] = x[14];
   assign result[7] = x[15];
   assign result[8] = x[16];
   assign result[9] = x[17];
   assign result[10] = x[18];
   assign result[11] = x[19];
   assign result[12] = x[20];
   assign result[13] = x[21];
   assign result[14] = x[22];
   assign result[15] = x[23];
   assign result[16] = x[24];
   assign result[17] = x[25];
   assign result[18] = x[26];
   assign result[19] = x[27];
   assign result[20] = x[28];
   assign result[21] = x[29];
   assign result[22] = x[30];
   assign result[23] = x[31];
   assign result[24] = x[0];
   assign result[25] = x[1];
   assign result[26] = x[2];
   assign result[27] = x[3];
   assign result[28] = x[4];
   assign result[29] = x[5];
   assign result[30] = x[6];
   assign result[31] = x[7];

endmodule

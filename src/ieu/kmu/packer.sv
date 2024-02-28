///////////////////////////////////////////
// packer.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 5 October 2023
//
// Purpose: RISCV kbitmanip pack operation unit
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

module packer #(parameter WIDTH=32) (
  input logic [WIDTH-1:0]  A, B,
  input logic [2:0] 	   PackSelect, 
  output logic [WIDTH-1:0] PackResult);
   
  logic [WIDTH/2-1:0] 	   low_half, high_half;
  logic [7:0] 		   low_halfh, high_halfh;
  logic [15:0] 	   low_halfw, high_halfw;
  
  logic [WIDTH-1:0] 	   Pack;
  logic [WIDTH-1:0] 	   PackH;
  logic [WIDTH-1:0] 	   PackW;
   
  assign low_half = A[WIDTH/2-1:0];
  assign high_half = B[WIDTH/2-1:0];
  assign low_halfh = A[7:0];
  assign high_halfh = B[7:0];
  assign low_halfw = A[15:0];
  assign high_halfw = B[15:0];   
  
  assign Pack = {high_half, low_half}; 
  assign PackH = {{(WIDTH-16){1'b0}}, high_halfh, low_halfh}; 
  assign PackW = {{(WIDTH-32){high_halfw[15]}}, high_halfw, low_halfw}; 

  always_comb 
  begin
	  if (PackSelect[1:0] == 2'b11)   PackResult = PackH;
	  else if (PackSelect[2] == 1'b0) PackResult = Pack;
	  else                            PackResult = PackW;
  end

endmodule

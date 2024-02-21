///////////////////////////////////////////
// revop.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 5 October 2023
//
// Purpose: RISCV kbitmanip reverse byte-wise operation unit
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

module revop #(parameter WIDTH=32) 
   (input  logic [WIDTH-1:0] A,  // Operands
    input logic [WIDTH-1:0]  RevA, // A Reversed
    input logic 	     revType, // rev8 or brev8 (LSB of immediate)
    output logic [WIDTH-1:0] RevResult); // results
   
   logic [WIDTH-1:0] 	     Rev8Result, Brev8Result;
   genvar 		     i;
   
   for (i=0; i<WIDTH; i+=8) begin:loop
      assign Rev8Result[WIDTH-i-1:WIDTH-i-8] = A[i+7:i];
      assign Brev8Result[i+7:i] = RevA[WIDTH-1-i:WIDTH-i-8];
   end
   
  mux2 #(WIDTH) revMux (Rev8Result, Brev8Result, revType, RevResult);
   
endmodule

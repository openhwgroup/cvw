///////////////////////////////////////////
// zbkc.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 27 November 2023
//
// Purpose: RISC-V ZBKC top level unit
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

module zbkc #(parameter WIDTH=32) 
   (input  logic [WIDTH-1:0] A, B,
    input logic 	     ZBKCSelect,
    output logic [WIDTH-1:0] ZBKCResult);
   
   logic [WIDTH-1:0] 	     temp, if_temp;
   integer 		     i;
   
   always_comb begin
      temp = 0;      
      if (ZBKCSelect != 1'b0) begin   // clmulh
	 for (i=1; i<WIDTH; i+=1) begin: clmulh
            if_temp = (B >> i) & 1;
            if(if_temp[0]) temp = temp ^ (A >> (WIDTH-i));
            else temp = temp;
	 end
      end
      else begin                      // clmul
	 for (i=0; i<WIDTH; i+=1) begin: clmul
            if_temp = (B >> i) & 1;
            if(if_temp[0]) temp = temp ^ (A << i);
            else temp = temp;
	 end
      end
   end
   assign ZBKCResult = temp;

endmodule

///////////////////////////////////////////
// sync_w2r.sv
//
// Written: Clifford E Cummings 16 June 2005
// Modified: james.stine@okstate.edu 19 February 2024
//
// Purpose: FIFO write-domain to read-domain synchronizer
// 
// Documentation: 
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
module sync_w2r #(parameter ADDRSIZE = 4)
   (rq2_wptr, wptr, rclk, rrst_n);

   input logic      [ADDRSIZE:0] wptr;
   input logic			 rclk;
   input logic 			 rrst_n;
   
   output logic [ADDRSIZE:0] 	 rq2_wptr;

   logic [ADDRSIZE:0] 		 rq1_wptr;

   always @(posedge rclk or negedge rrst_n)
     if (!rrst_n) {rq2_wptr,rq1_wptr} <= 0;   
     else         {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

endmodule // sync_w2r

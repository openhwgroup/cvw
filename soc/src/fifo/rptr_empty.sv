///////////////////////////////////////////
// rptr_empty.sv
//
// Written: Clifford E Cummings 16 June 2005
// Modified: james.stine@okstate.edu 19 February 2024
//
// Purpose: FIFO read pointer and empty generation logic
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
module rptr_empty #(parameter ADDRSIZE = 4)
   (rempty, raddr, rptr, rq2_wptr, rinc, rclk, rrst_n);

   input logic [ADDRSIZE:0]    rq2_wptr;
   input logic 		       rinc;
   input logic 		       rclk;
   input logic 		       rrst_n;   
   output logic 	       rempty;
   output logic [ADDRSIZE-1:0] raddr;
   output logic [ADDRSIZE  :0] rptr;

   logic [ADDRSIZE:0] 	       rbin;
   logic [ADDRSIZE:0] 	       rgraynext;
   logic [ADDRSIZE:0] 	       rbinnext;   

   //-------------------
   // GRAYSTYLE2 pointer
   //-------------------
   always @(posedge rclk or negedge rrst_n)
     if (!rrst_n) {rbin, rptr} <= 0;
     else         {rbin, rptr} <= {rbinnext, rgraynext};
   
   // Memory read-address pointer (okay to use binary to address memory)
   assign raddr     = rbin[ADDRSIZE-1:0];
   assign rbinnext  = rbin + (rinc & ~rempty);
   assign rgraynext = (rbinnext>>1) ^ rbinnext;
   
   //--------------------------------------------------------------- 
   // FIFO empty when the next rptr == synchronized wptr or on reset 
   //--------------------------------------------------------------- 
   assign rempty_val = (rgraynext == rq2_wptr);
   
   always @(posedge rclk or negedge rrst_n)
     if (!rrst_n) rempty <= 1'b1;   
     else         rempty <= rempty_val;
   
endmodule // rptr_empty

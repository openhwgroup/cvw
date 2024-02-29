///////////////////////////////////////////
// wptr_full.sv
//
// Written: Clifford E Cummings 16 June 2005
// Modified: james.stine@okstate.edu 19 February 2024
//
// Purpose: FIFO write pointer and full generation logic
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
module wptr_full  #(parameter ADDRSIZE = 4)
   (wfull, waddr, wptr, wq2_rptr, winc, wclk, wrst_n);

   input logic     [ADDRSIZE  :0] wq2_rptr;
   input logic			  winc;
   input logic 			  wclk;
   input logic 			  wrst_n;   
   
   output logic 		  wfull;
   output logic [ADDRSIZE-1:0] 	  waddr;
   output logic [ADDRSIZE:0] 	  wptr;
   
   logic [ADDRSIZE:0] 		  wbin;
   logic [ADDRSIZE:0] 		  wgraynext;
   logic [ADDRSIZE:0] 		  wbinnext;   

   // GRAYSTYLE2 pointer
   always @(posedge wclk or negedge wrst_n)
     if (!wrst_n) {wbin, wptr} <= 0;   
     else         {wbin, wptr} <= {wbinnext, wgraynext};

   // Memory write-address pointer (okay to use binary to address memory)
   assign waddr = wbin[ADDRSIZE-1:0];
   assign wbinnext  = wbin + (winc & ~wfull);
   assign wgraynext = (wbinnext>>1) ^ wbinnext;

   //------------------------------------------------------------------ 
   // Simplified version of the three necessary full-tests:
   // assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
   //                   (wgnext[ADDRSIZE-1]  !=wq2_rptr[ADDRSIZE-1]) &&
   //                   (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0])); 
   //------------------------------------------------------------------ 
   assign wfull_val = (wgraynext=={~wq2_rptr[ADDRSIZE:ADDRSIZE-1],
				   wq2_rptr[ADDRSIZE-2:0]});
   
   always @(posedge wclk or negedge wrst_n)
     if (!wrst_n) 
       wfull  <= 1'b0;
     else 
       wfull <= wfull_val;
   
endmodule // wptr_full



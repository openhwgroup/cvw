///////////////////////////////////////////
// fifo.sv
//
// Written: Clifford E Cummings 16 June 2005
// Modified: infinitymdm@gmail.com 29 February 2024
//
// Purpose: Asynchronous FIFO
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

module fifo #(parameter DSIZE = 8,
	       parameter ASIZE = 4)
   (rdata, wfull, rempty, wdata, 
    winc, wclk, wrst_n, rinc, rclk, rrst_n);

   input logic [DSIZE-1:0] wdata;   
   input logic 		   winc;
   input logic 		   wclk;
   input logic 		   wrst_n;
   input logic 		   rinc;
   input logic 		   rclk;
   input logic 		   rrst_n;
   
   output logic [DSIZE-1:0] rdata;
   output logic 	    wfull;
   output logic 	    rempty;   
   
   logic [ASIZE-1:0] 	    waddr, raddr;
   logic [ASIZE:0] 	    wptr, rptr, wq2_rptr, rq2_wptr;
   
   sync_r2w #(ASIZE)  sync_r2w  (.wq2_rptr(wq2_rptr), .rptr(rptr),
			    .wclk(wclk), .wrst_n(wrst_n));
   sync_w2r #(ASIZE)  sync_w2r  (.rq2_wptr(rq2_wptr), .wptr(wptr),
			    .rclk(rclk), .rrst_n(rrst_n));
   
   fifomem #(DSIZE, ASIZE) fifomem (.rdata(rdata), .wdata(wdata),
				    .waddr(waddr), .raddr(raddr),
				    .wclken(winc), .wfull(wfull),
				    .wclk(wclk));
   rptr_empty #(ASIZE)   rptr_empty (.rempty(rempty), .raddr(raddr),
				     .rptr(rptr), .rq2_wptr(rq2_wptr), 
				     .rinc(rinc), .rclk(rclk), 
				     .rrst_n(rrst_n));
   wptr_full  #(ASIZE) wptr_full (.wfull(wfull), .waddr(waddr),
				  .wptr(wptr), .wq2_rptr(wq2_rptr),
				  .winc(winc), .wclk(wclk),
				  .wrst_n(wrst_n));

endmodule // fifo1

   
   
   

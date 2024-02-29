///////////////////////////////////////////
// sync_r2w.sv
//
// Written: Clifford E Cummings 16 June 2005
// Modified: james.stine@okstate.edu 19 February 2024
//
// Purpose: FIFO read-domain to write-domain synchronizer
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
module sync_r2w #(parameter ADDRSIZE = 4)
   (wq2_rptr, rptr, wclk, wrst_n);

   input logic    [ADDRSIZE:0] rptr;
   input logic		       wclk;
   input logic 		       wrst_n;
   
   output logic [ADDRSIZE:0]   wq2_rptr;
  
   logic [ADDRSIZE:0] 	       wq1_rptr;

   always @(posedge wclk or negedge wrst_n)
     if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
     else         {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

endmodule // sync_r2w

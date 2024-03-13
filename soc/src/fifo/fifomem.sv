///////////////////////////////////////////
// fifomem.sv
//
// Written: Clifford E. Cummings 16 June 2005
// Modified: james.stine@okstate.edu 19 February 2024
//
// Purpose: FIFO memory buffer
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

// DATASIZE = Memory data word width
// ADDRSIZE = Number of mem address bits
module fifomem #(parameter  DATASIZE = 8, 
		 parameter  ADDRSIZE = 4) 
   (rdata, wdata, waddr, raddr, wclken, wfull, wclk);

   input logic [DATASIZE-1:0]  wdata;
   input logic [ADDRSIZE-1:0]  waddr;
   input logic [ADDRSIZE-1:0]  raddr;
   input logic		       wclken;
   input logic 		       wfull;
   input logic 		       wclk;
   output logic [DATASIZE-1:0] rdata;

   // RTL Verilog memory model
   localparam DEPTH = 1 << ADDRSIZE;   
   logic [DATASIZE-1:0]        mem [0:DEPTH-1];

   assign rdata = mem[raddr];   
   always @(posedge wclk)
     if (wclken && !wfull) mem[waddr] <= wdata;
   
endmodule // fifomem

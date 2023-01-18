///////////////////////////////////////////
// dtim.sv
//
// Written: Ross Thompson ross1728@gmail.com January 30, 2022
// Modified: 
//
// Purpose: simple memory with bus or cache.
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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

`include "wally-config.vh"

module dtim(
  input logic 				 clk, 
  input logic 				 ce,            // Chip Enable
  input logic [1:0] 		 MemRWM,        // Read/Write control
  input logic [`PA_BITS-1:0] AdrM,          // Execution stage memory address
  input logic 				 FlushW, 
  input logic [`LLEN-1:0] 	 WriteDataM,    // Write data from IEU
  input logic [`LLEN/8-1:0]  ByteMaskM,     // Selects which bytes within a word to write
  output logic [`LLEN-1:0] 	 ReadDataWordM  // Read data before subword selection
  );

  logic                      we;
 
  localparam ADDR_WDITH = $clog2(`DTIM_RANGE/8);
  localparam OFFSET     = $clog2(`LLEN/8);

  assign we = MemRWM[0]  & ~FlushW;  // have to ignore write if Trap.

  ram1p1rwbe #(.DEPTH(`DTIM_RANGE/8), .WIDTH(`LLEN)) 
    ram(.clk, .ce, .we, .bwe(ByteMaskM), .addr(AdrM[ADDR_WDITH+OFFSET-1:OFFSET]), .dout(ReadDataWordM), .din(WriteDataM));
endmodule  
  

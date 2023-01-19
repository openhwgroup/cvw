///////////////////////////////////////////
// irom.sv
//
// Written: Ross Thompson ross1728@gmail.com January 30, 2022
// Modified: 
//
// Purpose: simple instruction ROM
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

module irom(
  input logic 			  clk, 
  input logic 			  ce,        // Chip Enable.  0: Holds IROMInstrF constant
  input logic [`XLEN-1:0] Adr,       // PCNextFSpill
  output logic [31:0] 	  IROMInstrF // Instruction read data
);

  localparam ADDR_WDITH = $clog2(`IROM_RANGE/8); 
  localparam OFFSET = $clog2(`XLEN/8);

  logic [`XLEN-1:0] IROMInstrFFull;

  rom1p1r #(ADDR_WDITH, `XLEN) rom(.clk, .ce, .addr(Adr[ADDR_WDITH+OFFSET-1:OFFSET]), .dout(IROMInstrFFull));
  if (`XLEN == 32) assign IROMInstrF = IROMInstrFFull;
  // have to delay Ardr[OFFSET-1] by 1 cycle
  else             begin
    logic AdrD;
    flopen #(1) AdrReg(clk, ce, Adr[OFFSET-1], AdrD);
    assign IROMInstrF = AdrD ? IROMInstrFFull[63:32] : IROMInstrFFull[31:0];
  end
endmodule  
  

///////////////////////////////////////////
// subcachelineread
//
// Written: Ross Thompson ross1728@gmail.com February 04, 2022
//          Muxes the cache line downto the word size.  Also include possilbe save/restore registers/muxes.
//
// Purpose: Controller for the dcache fsm
//
// A component of the CORE-V Wally configurable RISC-V project.
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

module subcachelineread #(parameter LINELEN, WORDLEN, MUXINTERVAL)(
  input logic [$clog2(LINELEN/8) - $clog2(MUXINTERVAL/8) - 1 : 0]   PAdr,
  input logic [LINELEN-1:0]  ReadDataLine,
  output logic [WORDLEN-1:0] ReadDataWord);

  localparam WORDSPERLINE = LINELEN/MUXINTERVAL;
  // pad is for icache. Muxing extends over the cacheline boundary.
  localparam PADLEN = WORDLEN-MUXINTERVAL;
  logic [LINELEN+(WORDLEN-MUXINTERVAL)-1:0] ReadDataLinePad;
  logic [WORDLEN-1:0]          ReadDataLineSets [(LINELEN/MUXINTERVAL)-1:0];

  if (PADLEN > 0) begin
    logic [PADLEN-1:0]  Pad;
    assign Pad = '0;
    assign ReadDataLinePad = {Pad, ReadDataLine};    
  end else assign ReadDataLinePad = ReadDataLine;

  genvar index;
  for (index = 0; index < WORDSPERLINE; index++) begin:readdatalinesetsmux
	  assign ReadDataLineSets[index] = ReadDataLinePad[(index*MUXINTERVAL)+WORDLEN-1: (index*MUXINTERVAL)];
  end
  // variable input mux
  assign ReadDataWord = ReadDataLineSets[PAdr];
endmodule

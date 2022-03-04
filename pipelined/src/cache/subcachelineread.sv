///////////////////////////////////////////
// subcachelineread
//
// Written: Ross Thompson ross1728@gmail.com February 04, 2022
//          Muxes the cache line downto the word size.  Also include possilbe save/restore registers/muxes.
//
// Purpose: Controller for the dcache fsm
//
// A component of the Wally configurable RISC-V project.
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module subcachelineread #(parameter LINELEN, WORDLEN, MUXINTERVAL)(
  input logic                clk,
  input logic                reset,
  input logic [`PA_BITS-1:0] PAdr,
  input logic                save, restore,
  input logic [LINELEN-1:0]  ReadDataLine,
  output logic [WORDLEN-1:0] ReadDataWord);

  localparam WORDSPERLINE = LINELEN/MUXINTERVAL;
  localparam PADLEN = WORDLEN-MUXINTERVAL;
  // Convert the Read data bus ReadDataSelectWay into sets of XLEN so we can
  // easily build a variable input mux.
  // *** move this to LSU and IFU, also remove mux from busdp into LSU. 
  // *** give this a module name to match block diagram
  logic [LINELEN+(WORDLEN-MUXINTERVAL)-1:0] ReadDataLinePad;
  logic [WORDLEN-1:0]          ReadDataLineSets [(LINELEN/MUXINTERVAL)-1:0];
  logic [WORDLEN-1:0] ReadDataWordRaw, ReadDataWordSaved;

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
  // *** maybe remove REPLAY config later after deciding which way is best
  assign ReadDataWordRaw = ReadDataLineSets[PAdr[$clog2(LINELEN/8) - 1 : $clog2(MUXINTERVAL/8)]];
  if(!`REPLAY) begin
    flopen #(WORDLEN) cachereaddatasavereg(clk, save, ReadDataWordRaw, ReadDataWordSaved);
    mux2 #(WORDLEN) readdatasaverestoremux(ReadDataWordRaw, ReadDataWordSaved,
                                           restore, ReadDataWord);
  end else assign ReadDataWord = ReadDataWordRaw;
endmodule

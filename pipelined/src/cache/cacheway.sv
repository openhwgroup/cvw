///////////////////////////////////////////
// cacheway
//
// Written: ross1728@gmail.com July 07, 2021
//          Implements the data, tag, valid, dirty, and replacement bits.
//
// Purpose: Storage and read/write access to data cache data, tag valid, dirty, and replacement.
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

module cacheway #(parameter NUMLINES=512, parameter LINELEN = 256, TAGLEN = 26,
				  parameter OFFSETLEN = 5, parameter INDEXLEN = 9, parameter DIRTY_BITS = 1) (
  input logic                        clk,
  input logic                        ce,
  input logic                        reset,

  input logic [$clog2(NUMLINES)-1:0] RAdr,
  input logic [`PA_BITS-1:0]         PAdr,
  input logic [LINELEN-1:0]          CacheWriteData,
  input logic                        SetValidWay,
  input logic                        ClearValidWay,
  input logic                        SetDirtyWay,
  input logic                        ClearDirtyWay,
  input logic                        SelEvict,
  input logic                        SelFlush,
  input logic                        VictimWay,
  input logic                        FlushWay,
  input logic                        Invalidate,
  input logic                        Flush,
//  input logic [(`XLEN-1)/8:0]        ByteMask,
  input logic [LINELEN/8-1:0]        LineByteMask,

  output logic [LINELEN-1:0]         ReadDataLineWay,
  output logic                       HitWay,
  output logic                       VictimDirtyWay,
  output logic [TAGLEN-1:0]          VictimTagWay);

  localparam integer                 WORDSPERLINE = LINELEN/`XLEN;
  localparam integer                 BYTESPERLINE = LINELEN/8;
  localparam                         LOGWPL = $clog2(WORDSPERLINE);
  localparam                         LOGXLENBYTES = $clog2(`XLEN/8);
  localparam integer                 BYTESPERWORD = `XLEN/8;

  logic [NUMLINES-1:0]               ValidBits;
  logic [NUMLINES-1:0]               DirtyBits;
  logic [LINELEN-1:0]                ReadDataLine;
  logic [TAGLEN-1:0]                 ReadTag;
  logic                              Valid;
  logic                              Dirty;
  logic                              SelData;
  logic                              SelTag;
  logic                              SelectedWriteWordEn;
  logic [LINELEN/8-1:0]              FinalByteMask;
  
  /////////////////////////////////////////////////////////////////////////////////////////////
  // Write Enable demux
  /////////////////////////////////////////////////////////////////////////////////////////////
  // If writing the whole line set all write enables to 1, else only set the correct word.
  assign SelectedWriteWordEn = SetValidWay | SetDirtyWay;// ? '1 : SetDirtyWay ? MemPAdrDecoded : '0; // OR-AND
  assign FinalByteMask = SetValidWay ? '1 : LineByteMask; // OR

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Tag Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  sram1p1rw #(.DEPTH(NUMLINES), .WIDTH(TAGLEN)) CacheTagMem(.clk, .ce,
    .addr(RAdr), .dout(ReadTag), .bwe('1),
    .din(PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]), .we(SetValidWay & ~Flush));

  // AND portion of distributed tag multiplexer
  mux2 #(1) seltagmux(VictimWay, FlushWay, SelFlush, SelTag);
  assign VictimTagWay = SelTag ? ReadTag : '0; // AND part of AOMux
  assign VictimDirtyWay = SelTag & Dirty & Valid;
  assign HitWay = Valid & (ReadTag == PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]);

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Data Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  genvar                             words;

  localparam integer           SRAMLEN = 128;
  localparam integer           NUMSRAM = LINELEN/SRAMLEN;
  localparam integer           SRAMLENINBYTES = SRAMLEN/8;
  localparam integer           LOGNUMSRAM = $clog2(NUMSRAM);
  
  for(words = 0; words < NUMSRAM; words++) begin: word
    sram1p1rw #(.DEPTH(NUMLINES), .WIDTH(SRAMLEN)) CacheDataMem(.clk, .ce, .addr(RAdr),
      .dout(ReadDataLine[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .din(CacheWriteData[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .we(SelectedWriteWordEn & ~Flush), .bwe(FinalByteMask[SRAMLENINBYTES*(words+1)-1:SRAMLENINBYTES*words]));
  end

  // AND portion of distributed read multiplexers
  mux3 #(1) selecteddatamux(HitWay, VictimWay, FlushWay, {SelFlush, SelEvict}, SelData);
  assign ReadDataLineWay = SelData ? ReadDataLine : '0;  // AND part of AO mux.

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Valid Bits
  /////////////////////////////////////////////////////////////////////////////////////////////
  
  always_ff @(posedge clk) begin // Valid bit array, 
    if (reset | Invalidate) ValidBits        <= #1 '0;
    if(ce) begin Valid <= #1 ValidBits[RAdr];
      if (SetValidWay & ~Flush)      ValidBits[RAdr] <= #1 1'b1;
      else if (ClearValidWay & ~Flush)    ValidBits[RAdr] <= #1 1'b0;
    end
  end

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Dirty Bits
  /////////////////////////////////////////////////////////////////////////////////////////////

  // Dirty bits
  if (DIRTY_BITS) begin:dirty
    always_ff @(posedge clk) begin
      if (reset)              DirtyBits        <= #1 {NUMLINES{1'b0}};
      if(ce) begin
        Dirty <= #1 DirtyBits[RAdr];
        if (SetDirtyWay & ~Flush)   DirtyBits[RAdr] <= #1 1'b1;
        else if (ClearDirtyWay & ~Flush) DirtyBits[RAdr] <= #1 1'b0;
      end
    end
  end else assign Dirty = 1'b0;

endmodule



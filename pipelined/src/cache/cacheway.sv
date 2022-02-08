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
  input logic                        reset,

  input logic [$clog2(NUMLINES)-1:0] RAdr,
  input logic [`PA_BITS-1:0]         PAdr,
  input logic                        SRAMWayWriteEnable,
  input logic [LINELEN/`XLEN-1:0]    SRAMWordEnable,
  input logic                        TagWriteEnable,
  input logic [LINELEN-1:0]          WriteData,
  input logic                        SetValid,
  input logic                        ClearValid,
  input logic                        SetDirty,
  input logic                        ClearDirty,
  input logic                        SelEvict,
  input logic                        Victim,
  input logic                        InvalidateAll,
  input logic                        SelFlush,
  input logic                        Flush,

  output logic [LINELEN-1:0]         SelectedReadDataLine,
  output logic                       WayHit,
  output logic                       VictimDirty,
  output logic [TAGLEN-1:0]          VictimTag);

  logic [NUMLINES-1:0] 				  ValidBits;
  logic [NUMLINES-1:0] 				  DirtyBits;
  logic [LINELEN-1:0] 				  ReadDataLine;
  logic [TAGLEN-1:0] 				  ReadTag;
  logic 							  Valid;
  logic 							  Dirty;
  logic 							  SelData;
  logic                               SelTag;

  logic [$clog2(NUMLINES)-1:0] 		  RAdrD;
  logic 							  SetValidD, ClearValidD;
  logic 							  SetDirtyD, ClearDirtyD;
  logic 							  SRAMWayWriteEnableD;

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Tag Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  sram1rw #(.DEPTH(NUMLINES), .WIDTH(TAGLEN)) CacheTagMem(.clk(clk),
		.Adr(RAdr), .ReadData(ReadTag),
	  .WriteData(PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]), .WriteEnable(TagWriteEnable));

  // AND portion of distributed tag multiplexer
  assign SelTag = SelFlush ? Flush : Victim;
  assign VictimTag = SelTag ? ReadTag : '0; // AND part of AOMux
  assign VictimDirty = SelTag & Dirty & Valid;

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Data Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  // *** Potential optimization: if byte write enables are available, could remove subwordwrites
  genvar 							  words;
  for(words = 0; words < LINELEN/`XLEN; words++) begin: word
    sram1rw #(.DEPTH(NUMLINES), .WIDTH(`XLEN)) CacheDataMem(.clk(clk), .Adr(RAdr),
      .ReadData(ReadDataLine[(words+1)*`XLEN-1:words*`XLEN] ),
      .WriteData(WriteData[(words+1)*`XLEN-1:words*`XLEN]),
      .WriteEnable(SRAMWayWriteEnable & SRAMWordEnable[words]));
  end

  // AND portion of distributed read multiplexers
  assign WayHit = Valid & (ReadTag == PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]);
  assign SelData = SelFlush ? Flush : (SelEvict ? Victim : WayHit);  
  assign SelectedReadDataLine = SelData ? ReadDataLine : '0;  // AND part of AO mux.

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Valid Bits
  /////////////////////////////////////////////////////////////////////////////////////////////
  
  always_ff @(posedge clk) begin // Valid bit array, 
    if (reset | InvalidateAll)                              ValidBits        <= #1 '0;
    else if (SetValidD)                                     ValidBits[RAdrD] <= #1 1'b1;
    else if (ClearValidD) ValidBits[RAdrD] <= #1 1'b0;
	end
  // *** consider revisiting whether these delays are the best option? 
  flop #($clog2(NUMLINES)) RAdrDelayReg(clk, RAdr, RAdrD);
  flop #(3) ValidCtrlDelayReg(clk, {SetValid, ClearValid, SRAMWayWriteEnable},
    {SetValidD, ClearValidD, SRAMWayWriteEnableD});
  assign Valid = ValidBits[RAdrD];

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Dirty Bits
  /////////////////////////////////////////////////////////////////////////////////////////////

  // Dirty bits
  if (DIRTY_BITS) begin:dirty
    always_ff @(posedge clk) begin
      if (reset)                                              DirtyBits        <= #1 {NUMLINES{1'b0}};
      else if (SetDirtyD) DirtyBits[RAdrD] <= #1 1'b1;
      else if (ClearDirtyD) DirtyBits[RAdrD] <= #1 1'b0;
    end
    flop #(2) DirtyCtlDelayReg(clk, {SetDirty, ClearDirty}, {SetDirtyD, ClearDirtyD});
    assign Dirty = DirtyBits[RAdrD];
  end else assign Dirty = 1'b0;

endmodule



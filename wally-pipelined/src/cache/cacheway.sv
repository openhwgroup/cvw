///////////////////////////////////////////
// DCacheMem (Memory for the Data Cache)
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
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module cacheway #(parameter NUMLINES=512, parameter BLOCKLEN = 256, TAGLEN = 26,
		   parameter OFFSETLEN, parameter INDEXLEN, parameter DIRTY_BITS = 1) 
  (input logic 		       clk,
   input logic 			      reset,

   input logic [$clog2(NUMLINES)-1:0] RAdr,
   input logic [`PA_BITS-1:0] 	      PAdr,
   input logic 			      WriteEnable,
   input logic [BLOCKLEN/`XLEN-1:0]   WriteWordEnable,
   input logic 			      TagWriteEnable,
   input logic [BLOCKLEN-1:0] 	      WriteData,
   input logic 			      SetValid,
   input logic 			      ClearValid,
   input logic 			      SetDirty,
   input logic 			      ClearDirty,
   input logic 			      SelEvict,
   input logic 			      VictimWay,
   input logic 			      InvalidateAll,

   output logic [BLOCKLEN-1:0] 	      ReadDataBlockWayMasked,
   output logic 		      WayHit,
   output logic 		      VictimDirtyWay,
   output logic [TAGLEN-1:0] 	      VictimTagWay
   );

  logic [NUMLINES-1:0] 		      ValidBits, DirtyBits;
  logic [BLOCKLEN-1:0] 		      ReadDataBlockWay;
  logic [TAGLEN-1:0] 		      ReadTag;
  logic 			      Valid;
  logic 			      Dirty;
  logic 			      SelectedWay;

  genvar 			      words;

  generate
    for(words = 0; words < BLOCKLEN/`XLEN; words++) begin : word
      sram1rw #(.DEPTH(`XLEN), 
		.WIDTH(NUMLINES))
      CacheDataMem(.clk(clk),
		   .Addr(RAdr),
		   .ReadData(ReadDataBlockWay[(words+1)*`XLEN-1:words*`XLEN] ),
		   .WriteData(WriteData[(words+1)*`XLEN-1:words*`XLEN]),
		   .WriteEnable(WriteEnable & WriteWordEnable[words]));
    end
  endgenerate

  sram1rw #(.DEPTH(TAGLEN),
	    .WIDTH(NUMLINES))
  CacheTagMem(.clk(clk),
	      .Addr(RAdr),
	      .ReadData(ReadTag),
	      .WriteData(PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]),
	      .WriteEnable(TagWriteEnable));

  assign WayHit = Valid & (ReadTag == PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]);
  assign SelectedWay = SelEvict ? VictimWay : WayHit;  
  assign ReadDataBlockWayMasked = SelectedWay ? ReadDataBlockWay : '0;  // first part of AO mux.

  assign VictimDirtyWay = VictimWay & Dirty & Valid;
  assign VictimTagWay = VictimWay ? ReadTag : '0;
  
  always_ff @(posedge clk, posedge reset) begin
    if (reset) 
  	ValidBits <= {NUMLINES{1'b0}};
    else if (InvalidateAll) 
  	ValidBits <= {NUMLINES{1'b0}};
    else if (SetValid & WriteEnable) ValidBits[PAdr[INDEXLEN+OFFSETLEN-1:OFFSETLEN]] <= 1'b1;
    else if (ClearValid & WriteEnable) ValidBits[PAdr[INDEXLEN+OFFSETLEN-1:OFFSETLEN]] <= 1'b0;
    Valid <= ValidBits[RAdr];
  end

  generate
    if(DIRTY_BITS) begin
      always_ff @(posedge clk, posedge reset) begin
	if (reset) 
  	  DirtyBits <= {NUMLINES{1'b0}};
	else if (SetDirty & WriteEnable) DirtyBits[PAdr[INDEXLEN+OFFSETLEN-1:OFFSETLEN]] <= 1'b1;
	else if (ClearDirty & WriteEnable) DirtyBits[PAdr[INDEXLEN+OFFSETLEN-1:OFFSETLEN]] <= 1'b0;
	Dirty <= DirtyBits[RAdr];
      end
    end else begin
      assign Dirty = 1'b0;
    end
  endgenerate
  
endmodule // DCacheMemWay



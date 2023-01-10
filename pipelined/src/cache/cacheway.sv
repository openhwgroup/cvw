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

module cacheway #(parameter NUMLINES=512, parameter LINELEN = 256, TAGLEN = 26,
				  parameter OFFSETLEN = 5, parameter INDEXLEN = 9, parameter DIRTY_BITS = 1) (
  input logic                        clk,
  input logic                        CacheEn,
  input logic                        reset,
  input logic [$clog2(NUMLINES)-1:0] CAdr,
  input logic [`PA_BITS-1:0]         PAdr,
  input logic [LINELEN-1:0]          LineWriteData,
  input logic                        SetValid,
  input logic                        ClearValid,
  input logic                        SetDirty,
  input logic                        ClearDirty,
  input logic                        SelWriteback,
  input logic                        SelFlush,
  input logic                        VictimWay,
  input logic                        FlushWay,
  input logic                        InvalidateCache,
  input logic                        FlushStage,
//  input logic [(`XLEN-1)/8:0]        ByteMask,
  input logic [LINELEN/8-1:0]        LineByteMask,

  output logic [LINELEN-1:0]         ReadDataLineWay,
  output logic                       HitWay,
  output logic                       ValidWay,
  output logic                       DirtyWay,
  output logic [TAGLEN-1:0]          TagWay);

  localparam integer                 WORDSPERLINE = LINELEN/`XLEN;
  localparam integer                 BYTESPERLINE = LINELEN/8;
  localparam                         LOGWPL = $clog2(WORDSPERLINE);
  localparam                         LOGXLENBYTES = $clog2(`XLEN/8);
  localparam integer                 BYTESPERWORD = `XLEN/8;

  logic [NUMLINES-1:0]               ValidBits;
  logic [NUMLINES-1:0]               DirtyBits;
  logic [LINELEN-1:0]                ReadDataLine;
  logic [TAGLEN-1:0]                 ReadTag;
  logic                              Dirty;
  logic                              SelTag;
  logic                              SelectedWriteWordEn;
  logic [LINELEN/8-1:0]              FinalByteMask;
  logic                              SetValidEN;
  logic                              SetValidWay;
  logic                              ClearValidWay;
  logic                              SetDirtyWay;
  logic                              ClearDirtyWay;
  logic                              SelNonHit;
  logic                              SelData;
  logic                              FlushWayEn, VictimWayEn;
  

  // FlushWay and VictimWay are part of a one hot way selection.  Must clear them if FlushWay not selected
  // or VictimWay not selected.
  assign FlushWayEn = FlushWay & SelFlush;
  assign VictimWayEn = VictimWay & SelWriteback;
  
  assign SelNonHit = FlushWayEn | SetValid | SelWriteback;
  
  mux2 #(1) seltagmux(VictimWay, FlushWay, SelFlush, SelTag);
  //assign SelTag = VictimWay | FlushWay;
  //assign SelData = HitWay | FlushWayEn | VictimWayEn;
  
  mux2 #(1) selectedwaymux(HitWay, SelTag, SelNonHit , SelData);

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Write Enable demux
  /////////////////////////////////////////////////////////////////////////////////////////////

  // RT: Can we merge these two muxes?  This is also shared in cacheLRU.
  //mux3 #(1) selectwaymux(HitWay, VictimWay, FlushWay,     {SelFlush, SetValid}, SelData);
  //mux3 #(1) selecteddatamux(HitWay, VictimWay, FlushWay, {SelFlush, SelNonHit}, SelData);

  assign SetValidWay = SetValid & SelData;
  assign ClearValidWay = ClearValid & SelData;
  assign SetDirtyWay = SetDirty & SelData;
  assign ClearDirtyWay = ClearDirty & SelData;
  
  // If writing the whole line set all write enables to 1, else only set the correct word.
  assign SelectedWriteWordEn = (SetValidWay | SetDirtyWay) & ~FlushStage;
  assign FinalByteMask = SetValidWay ? '1 : LineByteMask; // OR
  assign SetValidEN = SetValidWay & ~FlushStage;

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Tag Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  ram1p1rwbe #(.DEPTH(NUMLINES), .WIDTH(TAGLEN)) CacheTagMem(.clk, .ce(CacheEn),
    .addr(CAdr), .dout(ReadTag), .bwe('1),
    .din(PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]), .we(SetValidEN));

  

  // AND portion of distributed tag multiplexer
  assign TagWay = SelTag ? ReadTag : '0; // AND part of AOMux
  assign DirtyWay = SelTag & Dirty & ValidWay;
  assign HitWay = ValidWay & (ReadTag == PAdr[`PA_BITS-1:OFFSETLEN+INDEXLEN]);

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Data Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  genvar                             words;

  localparam integer           SRAMLEN = 128;
  localparam integer           NUMSRAM = LINELEN/SRAMLEN;
  localparam integer           SRAMLENINBYTES = SRAMLEN/8;
  localparam integer           LOGNUMSRAM = $clog2(NUMSRAM);
  
  for(words = 0; words < NUMSRAM; words++) begin: word
    ram1p1rwbe #(.DEPTH(NUMLINES), .WIDTH(SRAMLEN)) CacheDataMem(.clk, .ce(CacheEn), .addr(CAdr),
      .dout(ReadDataLine[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .din(LineWriteData[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .we(SelectedWriteWordEn), .bwe(FinalByteMask[SRAMLENINBYTES*(words+1)-1:SRAMLENINBYTES*words]));
  end

  // AND portion of distributed read multiplexers
  assign ReadDataLineWay = SelData ? ReadDataLine : '0;  // AND part of AO mux.

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Valid Bits
  /////////////////////////////////////////////////////////////////////////////////////////////
  
  always_ff @(posedge clk) begin // Valid bit array, 
    if (reset) ValidBits        <= #1 '0;
    if(CacheEn) begin 
	  ValidWay <= #1 ValidBits[CAdr];
	  if(InvalidateCache & ~FlushStage)                    ValidBits <= #1 '0;
      else if (SetValidEN | (ClearValidWay & ~FlushStage)) ValidBits[CAdr] <= #1 SetValidWay;
    end
  end

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Dirty Bits
  /////////////////////////////////////////////////////////////////////////////////////////////

  // Dirty bits
  if (DIRTY_BITS) begin:dirty
    always_ff @(posedge clk) begin
      // reset is optional.  Consider merging with TAG array in the future.
      //if (reset) DirtyBits <= #1 {NUMLINES{1'b0}}; 
      if(CacheEn) begin
        Dirty <= #1 DirtyBits[CAdr];
        if((SetDirtyWay | ClearDirtyWay) & ~FlushStage) DirtyBits[CAdr] <= #1 SetDirtyWay;
      end
    end
  end else assign Dirty = 1'b0;


endmodule



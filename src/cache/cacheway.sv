///////////////////////////////////////////
// cacheway
//
// Written: Ross Thompson ross1728@gmail.com 
// Created: 7 July 2021
// Modified: 20 January 2023
//
// Purpose: Storage and read/write access to data cache data, tag valid, dirty, and replacement.
// 
// Documentation: RISC-V System on Chip Design Chapter 7 (Figure 7.11)
//
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

module cacheway #(parameter NUMLINES=512, LINELEN = 256, TAGLEN = 26,
				          OFFSETLEN = 5, INDEXLEN = 9, DIRTY_BITS = 1) (
  input  logic                        clk,
  input  logic                        reset,
  input  logic                        FlushStage,     // Pipeline flush of second stage (prevent writes and bus operations)
  input  logic                        CacheEn,        // Enable the cache memory arrays.  Disable hold read data constant
  input  logic [$clog2(NUMLINES)-1:0] CAdr,           // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [`PA_BITS-1:0]         PAdr,           // Physical address 
  input  logic [LINELEN-1:0]          LineWriteData,  // Final data written to cache (D$ only)
  input  logic                        SetValid,       // Set the dirty bit in the selected way and set
  input  logic                        ClearValid,     // Clear the valid bit in the selected way and set
  input  logic                        SetDirty,       // Set the dirty bit in the selected way and set
  input  logic                        ClearDirty,     // Clear the dirty bit in the selected way and set
  input  logic                        SelWriteback,   // Overrides cached tag check to select a specific way and set for writeback
  input  logic                        SelFlush,       // [0] Use SelAdr, [1] SRAM reads/writes from FlushAdr
  input  logic                        VictimWay,      // LRU selected this way as victim to evict
  input  logic                        FlushWay,       // This way is selected for flush and possible writeback if dirty
  input  logic                        InvalidateCache,//Clear all valid bits
  input  logic [LINELEN/8-1:0]        LineByteMask,   // Final byte enables to cache (D$ only)

  output logic [LINELEN-1:0]          ReadDataLineWay,// This way's read data if valid
  output logic                        HitWay,         // This way hits
  output logic                        ValidWay,       // This way is valid
  output logic                        DirtyWay,       // This way is dirty
  output logic [TAGLEN-1:0]           TagWay);        // THis way's tag if valid

  localparam                          WORDSPERLINE = LINELEN/`XLEN;
  localparam                          BYTESPERLINE = LINELEN/8;
  localparam                          LOGWPL = $clog2(WORDSPERLINE);
  localparam                          LOGXLENBYTES = $clog2(`XLEN/8);
  localparam                          BYTESPERWORD = `XLEN/8;

  logic [NUMLINES-1:0]                ValidBits;
  logic [NUMLINES-1:0]                DirtyBits;
  logic [LINELEN-1:0]                 ReadDataLine;
  logic [TAGLEN-1:0]                  ReadTag;
  logic                               Dirty;
  logic                               SelTag;
  logic                               SelectedWriteWordEn;
  logic [LINELEN/8-1:0]               FinalByteMask;
  logic                               SetValidEN;
  logic                               SetValidWay;
  logic                               ClearValidWay;
  logic                               SetDirtyWay;
  logic                               ClearDirtyWay;
  logic                               SelNonHit;
  logic                               SelData;
  logic                               FlushWayEn, VictimWayEn;

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

  genvar               words;

  localparam           SRAMLEN = 128;
  localparam           NUMSRAM = LINELEN/SRAMLEN;
  localparam           SRAMLENINBYTES = SRAMLEN/8;
  localparam           LOGNUMSRAM = $clog2(NUMSRAM);
  
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
	  if(InvalidateCache)                    ValidBits <= #1 '0;
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



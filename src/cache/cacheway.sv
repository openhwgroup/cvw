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

module cacheway import cvw::*; #(parameter cvw_t P, 
                  parameter PA_BITS, XLEN, NUMLINES=512, LINELEN = 256, TAGLEN = 26,
                  OFFSETLEN = 5, INDEXLEN = 9, READ_ONLY_CACHE = 0) (
  input  logic                        clk,
  input  logic                        reset,
  input  logic                        FlushStage,     // Pipeline flush of second stage (prevent writes and bus operations)
  input  logic                        CacheEn,        // Enable the cache memory arrays.  Disable hold read data constant
  input  logic [$clog2(NUMLINES)-1:0] CacheSet,       // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [PA_BITS-1:0]          PAdr,           // Physical address 
  input  logic [LINELEN-1:0]          LineWriteData,  // Final data written to cache (D$ only)
  input  logic                        SetValid,       // Set the valid bit in the selected way and set
  input  logic                        SetDirty,       // Set the dirty bit in the selected way and set
  input  logic                        ClearDirty,     // Clear the dirty bit in the selected way and set
  input  logic                        SelWriteback,   // Overrides cached tag check to select a specific way and set for writeback
  input  logic                        SelFlush,       // [0] Use SelAdr, [1] SRAM reads/writes from FlushAdr
  input  logic                        VictimWay,      // LRU selected this way as victim to evict
  input  logic                        FlushWay,       // This way is selected for flush and possible writeback if dirty
  input  logic                        InvalidateCache,// Clear all valid bits
  input  logic [LINELEN/8-1:0]        LineByteMask,   // Final byte enables to cache (D$ only)

  output logic [LINELEN-1:0]          ReadDataLineWay,// This way's read data if valid
  output logic                        HitWay,         // This way hits
  output logic                        ValidWay,       // This way is valid
  output logic                        DirtyWay,       // This way is dirty
  output logic [TAGLEN-1:0]           TagWay);        // This way's tag if valid

  localparam                          WORDSPERLINE = LINELEN/XLEN;
  localparam                          BYTESPERLINE = LINELEN/8;
  localparam                          LOGWPL = $clog2(WORDSPERLINE);
  localparam                          LOGXLENBYTES = $clog2(XLEN/8);
  localparam                          BYTESPERWORD = XLEN/8;

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
  logic                               SetDirtyWay;
  logic                               ClearDirtyWay;
  logic                               SelNonHit;
  logic                               SelData;


  if (!READ_ONLY_CACHE) begin:flushlogic
    logic                               FlushWayEn;

    mux2 #(1) seltagmux(VictimWay, FlushWay, SelFlush, SelTag);

    // FlushWay is part of a one hot way selection. Must clear it if FlushWay not selected.
    // coverage off -item e 1 -fecexprrow 3
    // nonzero ways will never see SelFlush=0 while FlushWay=1 since FlushWay only advances on a subset of SelFlush assertion cases.
    assign FlushWayEn = FlushWay & SelFlush;
    assign SelNonHit = FlushWayEn | SetValid | SelWriteback;
  end else begin:flushlogic // no flush operation for read-only caches.
    assign SelTag = VictimWay;
    assign SelNonHit = SetValid;
  end

  mux2 #(1) selectedwaymux(HitWay, SelTag, SelNonHit , SelData);

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Write Enable demux
  /////////////////////////////////////////////////////////////////////////////////////////////

  assign SetValidWay = SetValid & SelData;
  assign SetDirtyWay = SetDirty & SelData;                                 // exclusion-tag: icache SetDirtyWay
  assign ClearDirtyWay = ClearDirty & SelData;
  assign SelectedWriteWordEn = (SetValidWay | SetDirtyWay) & ~FlushStage;  // exclusion-tag: icache SelectedWiteWordEn
  assign SetValidEN = SetValidWay & ~FlushStage;                           // exclusion-tag: cache SetValidEN

  // If writing the whole line set all write enables to 1, else only set the correct word.
  assign FinalByteMask = SetValidWay ? '1 : LineByteMask; // OR

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Tag Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  ram1p1rwe #(.P(P), .DEPTH(NUMLINES), .WIDTH(TAGLEN)) CacheTagMem(.clk, .ce(CacheEn),
    .addr(CacheSet), .dout(ReadTag),
    .din(PAdr[PA_BITS-1:OFFSETLEN+INDEXLEN]), .we(SetValidEN));

  // AND portion of distributed tag multiplexer
  assign TagWay = SelTag ? ReadTag : '0; // AND part of AOMux
  assign DirtyWay = SelTag & Dirty & ValidWay;
  assign HitWay = ValidWay & (ReadTag == PAdr[PA_BITS-1:OFFSETLEN+INDEXLEN]);

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Data Array
  /////////////////////////////////////////////////////////////////////////////////////////////

  genvar               words;

  localparam           SRAMLEN = 128;             // *** make this a global parameter
  localparam           NUMSRAM = LINELEN/SRAMLEN;
  localparam           SRAMLENINBYTES = SRAMLEN/8;
  localparam           LOGNUMSRAM = $clog2(NUMSRAM);
  
  for(words = 0; words < NUMSRAM; words++) begin: word
    if (!READ_ONLY_CACHE) begin:wordram
      ram1p1rwbe #(.P(P), .DEPTH(NUMLINES), .WIDTH(SRAMLEN)) CacheDataMem(.clk, .ce(CacheEn), .addr(CacheSet),
      .dout(ReadDataLine[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .din(LineWriteData[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .we(SelectedWriteWordEn), .bwe(FinalByteMask[SRAMLENINBYTES*(words+1)-1:SRAMLENINBYTES*words]));
    end else begin:wordram // no byte-enable needed for i$.
      ram1p1rwe #(.P(P), .DEPTH(NUMLINES), .WIDTH(SRAMLEN)) CacheDataMem(.clk, .ce(CacheEn), .addr(CacheSet),
      .dout(ReadDataLine[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .din(LineWriteData[SRAMLEN*(words+1)-1:SRAMLEN*words]),
      .we(SelectedWriteWordEn));
    end
  end

  // AND portion of distributed read multiplexers
  assign ReadDataLineWay = SelData ? ReadDataLine : '0;  // AND part of AO mux.

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Valid Bits
  /////////////////////////////////////////////////////////////////////////////////////////////
  
  always_ff @(posedge clk) begin // Valid bit array, 
    if (reset) ValidBits        <= #1 '0;
    if(CacheEn) begin 
      ValidWay <= #1 ValidBits[CacheSet];
      if(InvalidateCache)                    ValidBits <= #1 '0; // exclusion-tag: dcache invalidateway
      else if (SetValidEN) ValidBits[CacheSet] <= #1 SetValidWay;
    end
  end

  /////////////////////////////////////////////////////////////////////////////////////////////
  // Dirty Bits
  /////////////////////////////////////////////////////////////////////////////////////////////

  // Dirty bits
  if (!READ_ONLY_CACHE) begin:dirty
    always_ff @(posedge clk) begin
      // reset is optional.  Consider merging with TAG array in the future.
      //if (reset) DirtyBits <= #1 {NUMLINES{1'b0}}; 
      if(CacheEn) begin
        Dirty <= #1 DirtyBits[CacheSet];
        if((SetDirtyWay | ClearDirtyWay) & ~FlushStage) DirtyBits[CacheSet] <= #1 SetDirtyWay;
      end
    end
  end else assign Dirty = 1'b0;
endmodule

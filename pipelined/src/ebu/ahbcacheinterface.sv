///////////////////////////////////////////
// ahbcacheinterface.sv
//
// Written: Ross Thompson ross1728@gmail.com August 29, 2022
// Modified: 
//
// Purpose: Cache/Bus data path.
// Bus Side logic
// register the fetch data from the next level of memory.
// This register should be necessary for timing.  There is no register in the uncore or
// ahblite controller between the memories and this cache.
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

module ahbcacheinterface #(parameter BEATSPERLINE, LINELEN, LOGWPL, CACHE_ENABLED)
  (
  input logic                 HCLK, HRESETn,
  
  // bus interface
  input logic                 HREADY,
  input logic [`AHBW-1:0]     HRDATA,
  output logic [2:0]          HSIZE,
  output logic [2:0]          HBURST,
  output logic [1:0]          HTRANS,
  output logic                HWRITE,
  output logic [`PA_BITS-1:0] HADDR,
  output logic [`AHBW-1:0]    HWDATA,
  output logic [`AHBW/8-1:0]  HWSTRB,
  output logic [LOGWPL-1:0]   BeatCount,
  
  // cache interface
  input logic [`PA_BITS-1:0]  CacheBusAdr,
  input logic [`LLEN-1:0]     CacheReadDataWordM,
  input logic [`LLEN-1:0]     WriteDataM,
  input logic                 CacheableOrFlushCacheM,
  input logic [1:0]           CacheBusRW,
  output logic                CacheBusAck,
  output logic [LINELEN-1:0]  FetchBuffer, 
  input logic                 Cacheable,
 
  // lsu/ifu interface
  input logic                 Flush,
  input logic [`PA_BITS-1:0]  PAdr,
  input logic [1:0]           BusRW,
  input logic                 Stall,
  input logic [2:0]           Funct3,
  output logic                SelBusBeat,
  output logic                BusStall,
  output logic                BusCommitted);
  
  localparam integer          LLENPOVERAHBW = `LLEN / `AHBW; // *** fix me duplciated in lsu.

  localparam integer   BeatCountThreshold = CACHE_ENABLED ? BEATSPERLINE - 1 : 0;
  logic [`PA_BITS-1:0] LocalHADDR;
  logic [LOGWPL-1:0]   BeatCountDelayed;
  logic                CaptureEn;
  logic [`AHBW-1:0]    PreHWDATA;

  genvar                      index;
  for (index = 0; index < BEATSPERLINE; index++) begin:fetchbuffer
    logic [BEATSPERLINE-1:0] CaptureBeat;
    assign CaptureBeat[index] = CaptureEn & (index == BeatCountDelayed);
    flopen #(`AHBW) fb(.clk(HCLK), .en(CaptureBeat[index]), .d(HRDATA),
      .q(FetchBuffer[(index+1)*`AHBW-1:index*`AHBW]));
  end

  mux2 #(`PA_BITS) localadrmux(PAdr, CacheBusAdr, Cacheable, LocalHADDR);
  assign HADDR = ({{`PA_BITS-LOGWPL{1'b0}}, BeatCount} << $clog2(`AHBW/8)) + LocalHADDR;

  mux2 #(3) sizemux(.d0(Funct3), .d1(`AHBW == 32 ? 3'b010 : 3'b011), .s(Cacheable), .y(HSIZE));

  // When AHBW is less than LLEN need extra muxes to select the subword from cache's read data.
  logic [`AHBW-1:0]          CacheReadDataWordAHB;
  if(LLENPOVERAHBW > 1) begin
    logic [`AHBW-1:0]          AHBWordSets [(LLENPOVERAHBW)-1:0];
    genvar                     index;
    for (index = 0; index < LLENPOVERAHBW; index++) begin:readdatalinesetsmux
	  assign AHBWordSets[index] = CacheReadDataWordM[(index*`AHBW)+`AHBW-1: (index*`AHBW)];
    end
    assign CacheReadDataWordAHB = AHBWordSets[BeatCount[$clog2(LLENPOVERAHBW)-1:0]];
  end else assign CacheReadDataWordAHB = CacheReadDataWordM[`AHBW-1:0];      
  mux2 #(`AHBW) HWDATAMux(.d0(CacheReadDataWordAHB), .d1(WriteDataM[`AHBW-1:0]),
     .s(~(CacheableOrFlushCacheM)), .y(PreHWDATA));
  flopen #(`AHBW) wdreg(HCLK, HREADY, PreHWDATA, HWDATA); // delay HWDATA by 1 cycle per spec

  // *** bummer need a second byte mask for bus as it is AHBW rather than LLEN.
  // probably can merge by muxing PAdrM's LLEN/8-1 index bit based on HTRANS being != 0.
  logic [`AHBW/8-1:0]  BusByteMaskM;
  swbytemask #(`AHBW) busswbytemask(.Size(HSIZE), .Adr(HADDR[$clog2(`AHBW/8)-1:0]), .ByteMask(BusByteMaskM));
  
  flopen #(`AHBW/8) HWSTRBReg(HCLK, HREADY, BusByteMaskM[`AHBW/8-1:0], HWSTRB);
  

  buscachefsm #(BeatCountThreshold, LOGWPL) AHBBuscachefsm(
    .HCLK, .HRESETn, .Flush, .BusRW, .Stall, .BusCommitted, .BusStall, .CaptureEn, .SelBusBeat,
    .CacheBusRW, .CacheBusAck, .BeatCount, .BeatCountDelayed,
	.HREADY, .HTRANS, .HWRITE, .HBURST);
endmodule

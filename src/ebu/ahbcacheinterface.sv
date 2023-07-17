///////////////////////////////////////////
// ahbcacheinterface.sv
//
// Written: Ross Thompson ross1728@gmail.com
// Created: August 29, 2022
// Modified: 18 January 2023
//
// Purpose: Translates cache bus requests and uncached ieu memory requests into AHB transactions.
//
// Documentation: RISC-V System on Chip Design Chapter 9 (Figure 9.8)
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

module ahbcacheinterface #(
  parameter AHBW,
  parameter LLEN,
  parameter PA_BITS,
  parameter BEATSPERLINE,  // Number of AHBW words (beats) in cacheline
  parameter AHBWLOGBWPL,   // Log2 of ^
  parameter LINELEN,       // Number of bits in cacheline
  parameter LLENPOVERAHBW, // Number of AHB beats in a LLEN word. AHBW cannot be larger than LLEN. (implementation limitation)
  parameter READ_ONLY_CACHE
)(
  input  logic                HCLK, HRESETn,
  // bus interface controls
  input  logic                HREADY,                  // AHB peripheral ready
  output logic [1:0]          HTRANS,                  // AHB transaction type, 00: IDLE, 10 NON_SEQ, 11 SEQ
  output logic                HWRITE,                  // AHB 0: Read operation 1: Write operation 
  output logic [2:0]          HSIZE,                   // AHB transaction width
  output logic [2:0]          HBURST,                  // AHB burst length
  // bus interface buses
  input  logic [AHBW-1:0]     HRDATA,                  // AHB read data
  output logic [PA_BITS-1:0]  HADDR,                   // AHB address
  output logic [AHBW-1:0]     HWDATA,                  // AHB write data
  output logic [AHBW/8-1:0]   HWSTRB,                  // AHB byte mask
  
  // cache interface
  input  logic [PA_BITS-1:0]  CacheBusAdr,            // Address of cache line
  input  logic [LLEN-1:0]     CacheReadDataWordM,     // One word of cache line during a writeback
  input  logic                CacheableOrFlushCacheM, // Memory operation is cacheable or flushing D$
  input  logic                Cacheable,              // Memory operation is cachable
  input  logic [1:0]          CacheBusRW,             // Cache bus operation, 01: writeback, 10: fetch
  output logic                CacheBusAck,            // Handshake to $ indicating bus transaction completed
  output logic [LINELEN-1:0]  FetchBuffer,            // Register to hold beats of cache line as the arrive from bus
  output logic [AHBWLOGBWPL-1:0] BeatCount,           // Beat position within the cache line in the Address Phase
  output logic                SelBusBeat,             // Tells the cache to select the word from ReadData or WriteData from BeatCount rather than PAdr

  // uncached interface 
  input logic [PA_BITS-1:0]   PAdr,                    // Physical address of uncached memory operation
  input logic [LLEN-1:0]      WriteDataM,              // IEU write data for uncached store
  input logic [1:0]           BusRW,                   // Uncached memory operation read/write control: 10: read, 01: write
  input logic [2:0]           Funct3,                  // Size of uncached memory operation

  // lsu/ifu interface
  input logic                 Stall,                   // Core pipeline is stalled
  input logic                 Flush,                   // Pipeline stage flush. Prevents bus transaction from starting
  output logic                BusStall,                // Bus is busy with an in flight memory operation
  output logic                BusCommitted);           // Bus is busy with an in flight memory operation and it is not safe to take an interrupt
  

  localparam                  BeatCountThreshold = BEATSPERLINE - 1;  // Largest beat index
  logic [PA_BITS-1:0]         LocalHADDR;                             // Address after selecting between cached and uncached operation
  logic [AHBWLOGBWPL-1:0]     BeatCountDelayed;                       // Beat within the cache line in the second (Data) cache stage
  logic                       CaptureEn;                              // Enable updating the Fetch buffer with valid data from HRDATA
  logic [AHBW/8-1:0]          BusByteMaskM;                           // Byte enables within a word. For cache request all 1s
  logic [AHBW-1:0]            PreHWDATA;                              // AHB Address phase write data

  genvar                      index;

  // fetch buffer is made of BEATSPERLINE flip-flops
  for (index = 0; index < BEATSPERLINE; index++) begin:fetchbuffer
    logic [BEATSPERLINE-1:0] CaptureBeat;
    assign CaptureBeat[index] = CaptureEn & (index == BeatCountDelayed);
    flopen #(AHBW) fb(.clk(HCLK), .en(CaptureBeat[index]), .d(HRDATA),
      .q(FetchBuffer[(index+1)*AHBW-1:index*AHBW]));
  end

  mux2 #(PA_BITS) localadrmux(PAdr, CacheBusAdr, Cacheable, LocalHADDR);
  assign HADDR = ({{PA_BITS-AHBWLOGBWPL{1'b0}}, BeatCount} << $clog2(AHBW/8)) + LocalHADDR;

  mux2 #(3) sizemux(.d0(Funct3), .d1(AHBW == 32 ? 3'b010 : 3'b011), .s(Cacheable), .y(HSIZE));

  // When AHBW is less than LLEN need extra muxes to select the subword from cache's read data.
  logic [AHBW-1:0]          CacheReadDataWordAHB;
  if(LLENPOVERAHBW > 1) begin
    logic [AHBW-1:0]          AHBWordSets [(LLENPOVERAHBW)-1:0];
    genvar                     index;
    for (index = 0; index < LLENPOVERAHBW; index++) begin:readdatalinesetsmux
        assign AHBWordSets[index] = CacheReadDataWordM[(index*AHBW)+AHBW-1: (index*AHBW)];
    end
    assign CacheReadDataWordAHB = AHBWordSets[BeatCount[$clog2(LLENPOVERAHBW)-1:0]];
  end else assign CacheReadDataWordAHB = CacheReadDataWordM[AHBW-1:0];      
  
  mux2 #(AHBW) HWDATAMux(.d0(CacheReadDataWordAHB), .d1(WriteDataM[AHBW-1:0]),
    .s(~(CacheableOrFlushCacheM)), .y(PreHWDATA));
  flopen #(AHBW) wdreg(HCLK, HREADY, PreHWDATA, HWDATA); // delay HWDATA by 1 cycle per spec

  // *** bummer need a second byte mask for bus as it is AHBW rather than LLEN.
  // probably can merge by muxing PAdrM's LLEN/8-1 index bit based on HTRANS being != 0.
  swbytemask #(AHBW) busswbytemask(.Size(HSIZE), .Adr(HADDR[$clog2(AHBW/8)-1:0]), .ByteMask(BusByteMaskM));
  
  flopen #(AHBW/8) HWSTRBReg(HCLK, HREADY, BusByteMaskM[AHBW/8-1:0], HWSTRB);
  
  buscachefsm #(BeatCountThreshold, AHBWLOGBWPL, READ_ONLY_CACHE) AHBBuscachefsm(
    .HCLK, .HRESETn, .Flush, .BusRW, .Stall, .BusCommitted, .BusStall, .CaptureEn, .SelBusBeat,
    .CacheBusRW, .CacheBusAck, .BeatCount, .BeatCountDelayed,
    .HREADY, .HTRANS, .HWRITE, .HBURST);
endmodule

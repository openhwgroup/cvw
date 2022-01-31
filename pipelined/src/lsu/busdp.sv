///////////////////////////////////////////
// busdp.sv
//
// Written: Ross Thompson ross1728@gmail.com January 30, 2022
// Modified: 
//
// Purpose: Bus data path.
// Bus Side logic
// register the fetch data from the next level of memory.
// This register should be necessary for timing.  There is no register in the uncore or
// ahblite controller between the memories and this cache.
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

module busdp #(parameter WORDSPERLINE, parameter LINELEN)
  (
  input logic                 clk, reset,
  // bus interface
  input logic [`XLEN-1:0]     LSUBusHRDATA,
  input logic                 LSUBusAck,
  output logic                LSUBusWrite,
  output logic                LSUBusRead,
  output logic [`XLEN-1:0]    LSUBusHWDATA,
  output logic [2:0]          LSUBusSize, 
  input logic [2:0]           LSUFunct3M,
  output logic [`PA_BITS-1:0] LSUBusAdr,

  // cache interface.
  input logic [`PA_BITS-1:0]  DCacheBusAdr,
  input logic [`XLEN-1:0]     ReadDataLineSetsM [WORDSPERLINE-1:0],
  input logic                 DCacheFetchLine,
  input logic                 DCacheWriteLine,
  output logic                DCacheBusAck,
  output logic [LINELEN-1:0]  DCacheMemWriteData,
 
  // lsu interface
  input logic [`PA_BITS-1:0]  LSUPAdrM,
  input logic [`XLEN-1:0]     FinalAMOWriteDataM,
  input logic [`XLEN-1:0]     ReadDataWordM,
  output logic [`XLEN-1:0]    ReadDataWordMuxM,
  input logic                 IgnoreRequest,
  input logic [1:0]           LSURWM,
  input logic                 CPUBusy,
  input logic                 CacheableM,
  output logic                BusStall,
  output logic                BusCommittedM);
  

  localparam integer   WordCountThreshold = `MEM_DCACHE ? WORDSPERLINE - 1 : 0;
  localparam integer   LOGWPL = `MEM_DCACHE ? $clog2(WORDSPERLINE) : 1;

  logic                       SelUncachedAdr;
  logic [`XLEN-1:0]           PreLSUBusHWDATA;
  logic [`PA_BITS-1:0]        LocalLSUBusAdr;
  logic [LOGWPL-1:0]          WordCount;
  genvar                      index;

    for (index = 0; index < WORDSPERLINE; index++) begin:fetchbuffer
      flopen #(`XLEN) fb(.clk, .en(LSUBusAck & LSUBusRead & (index == WordCount)),
                         .d(LSUBusHRDATA), .q(DCacheMemWriteData[(index+1)*`XLEN-1:index*`XLEN]));
    end

    assign LocalLSUBusAdr = SelUncachedAdr ? LSUPAdrM : DCacheBusAdr ;
    assign LSUBusAdr = ({{`PA_BITS-LOGWPL{1'b0}}, WordCount} << $clog2(`XLEN/8)) + LocalLSUBusAdr;
    assign PreLSUBusHWDATA = ReadDataLineSetsM[WordCount]; // only in lsu, not ifu
    // exclude the subword write for uncached.  We don't read the data first so we cannot
    // select the subword by masking.  Subword write also exists inside the uncore to
    // suport subword masking for i/o.  I'm not sure if this is necessary.
    assign LSUBusHWDATA = SelUncachedAdr ? FinalAMOWriteDataM : PreLSUBusHWDATA;  // only in lsu, not ifu

    assign LSUBusSize = SelUncachedAdr ? LSUFunct3M : (`XLEN == 32 ? 3'b010 : 3'b011); // ifu: always the XLEN value.

    // select between dcache and direct from the BUS. Always selected if no dcache.
    mux2 #(`XLEN) UnCachedDataMux(.d0(ReadDataWordM),
          .d1(DCacheMemWriteData[`XLEN-1:0]),
          .s(SelUncachedAdr),
          .y(ReadDataWordMuxM));

    busfsm #(WordCountThreshold, LOGWPL, `MEM_DCACHE)
    busfsm(.clk, .reset, .IgnoreRequest, .LSURWM, .DCacheFetchLine, .DCacheWriteLine,
		   .LSUBusAck, .CPUBusy, .CacheableM, .BusStall, .LSUBusWrite, .LSUBusRead,
		   .DCacheBusAck, .BusCommittedM, .SelUncachedAdr, .WordCount);

endmodule

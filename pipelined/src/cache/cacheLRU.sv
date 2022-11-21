///////////////////////////////////////////
// dcache (data cache)
//
// Written: ross1728@gmail.com July 20, 2021
//          Implements Pseudo LRU
//          Tested for Powers of 2.
//
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

module cacheLRU
  #(parameter NUMWAYS = 4, SETLEN = 9, OFFSETLEN = 5, NUMLINES = 128)(
   input logic                clk, reset, ce,
   input logic [NUMWAYS-1:0]  HitWay,
   output logic [NUMWAYS-1:0] VictimWay,
   input logic [SETLEN-1:0]   RAdr,
   input logic                LRUWriteEn, SetValid);

  logic [NUMWAYS-2:0]                  LRUMemory [NUMLINES-1:0];
  logic [NUMWAYS-2:0]                  CurrLRU;
  logic [NUMWAYS-2:0]                  NewLRU;
  logic [NUMWAYS-1:0]                  Way;

  localparam                           LOGNUMWAYS = $clog2(NUMWAYS);

  logic [LOGNUMWAYS-1:0]               WayEncoded;
  logic [NUMWAYS-2:0]                  WayExpanded;
  genvar                               row;

  /* verilator lint_off UNOPTFLAT */
  // Ross: For some reason verilator does not like this.  I checked and it is not a circular path.
  logic [NUMWAYS-2:0]                  MuxEnables;
  logic [LOGNUMWAYS-1:0] Intermediate [NUMWAYS-2:0];
  /* verilator lint_on UNOPTFLAT */

  function integer log2 (integer value);
    for (log2=0; value>0; log2=log2+1)
      value = value>>1;
    return log2;
  endfunction // log2

  // On a miss we need to ignore HitWay and derive the new replacement bits with the VictimWay.
  mux2 #(NUMWAYS) WayMux(HitWay, VictimWay, SetValid, Way);
  binencoder #(NUMWAYS) encoder(Way, WayEncoded);

  // bit duplication
  // expand HitWay as HitWay[3], {{2}{HitWay[2]}}, {{4}{HitWay[1]}, {{8{HitWay[0]}}, ...
  for(row = 0; row < LOGNUMWAYS; row++) begin
    localparam integer DuplicationFactor = 2**(LOGNUMWAYS-row-1);
    localparam integer StartIndex = NUMWAYS-2 - DuplicationFactor + 1;
    localparam integer EndIndex = NUMWAYS-2 - 2 * DuplicationFactor + 2;
    assign WayExpanded[StartIndex : EndIndex] = {{DuplicationFactor}{WayEncoded[row]}};
  end

  genvar               r, a, s;
  assign MuxEnables[NUMWAYS-2] = '1;
  for(s = NUMWAYS-2; s >= NUMWAYS/2; s--) begin : enables
    localparam p = NUMWAYS - s - 1;
    localparam g = log2(p);
    localparam t0 = s - p;
    localparam t1 = t0 - 1;
    localparam r = LOGNUMWAYS - g;
    assign MuxEnables[t0] = MuxEnables[s] & ~WayEncoded[r];
    assign MuxEnables[t1] = MuxEnables[s] & WayEncoded[r];
  end

  mux2 #(1) LRUMuxes[NUMWAYS-2:0](CurrLRU, ~WayExpanded, MuxEnables, NewLRU);

  always_ff @(posedge clk) begin
    if (reset) for (int set = 0; set < NUMLINES; set++) LRUMemory[set] <= '0;
    if(ce) begin
      if (LRUWriteEn) begin 
        LRUMemory[RAdr] <= NewLRU;
        CurrLRU <= #1 NewLRU;
      end else begin
        CurrLRU <= #1 LRUMemory[RAdr];
      end
    end
  end
  for(s = NUMWAYS-2; s >= NUMWAYS/2; s--) begin
    //localparam p = NUMWAYS - s - 1;
    //localparam t0 = s - p;
    //localparam t1 = t0 - 1;
    localparam t1 = 2*s - NUMWAYS;
    localparam t0 = t1 + 1;
    assign Intermediate[s] = CurrLRU[s] ? Intermediate[t1] : Intermediate[t0];
  end
  for(s = NUMWAYS/2-1; s >= 0; s--) begin
    localparam int1 = (NUMWAYS/2-1-s)*2 + 1;
    localparam int0 = int1-1;
    assign Intermediate[s] = CurrLRU[s] ? int1[LOGNUMWAYS-1:0] : int0[LOGNUMWAYS-1:0];
  end

  decoder #(LOGNUMWAYS) decoder (Intermediate[NUMWAYS-2], VictimWay);
endmodule



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
   input logic                clk, reset, ce, FlushStage,
   input logic [NUMWAYS-1:0]  HitWay,
   input logic [NUMWAYS-1:0]  ValidWay,
   output logic [NUMWAYS-1:0] VictimWay,
   input logic [SETLEN-1:0]   CAdr,
   input logic [SETLEN-1:0]   PAdr,
   input logic                LRUWriteEn, SetValid, InvalidateCache);

  logic [NUMWAYS-2:0]                  LRUMemory [NUMLINES-1:0];
  logic [NUMWAYS-2:0]                  CurrLRU;
  logic [NUMWAYS-2:0]                  NextLRU;
  logic [NUMWAYS-1:0]                  Way;

  localparam                           LOGNUMWAYS = $clog2(NUMWAYS);

  logic [LOGNUMWAYS-1:0]               WayEncoded;
  logic [NUMWAYS-2:0]                  WayExpanded;
  logic                                AllValid;
  
  genvar                               row;

  /* verilator lint_off UNOPTFLAT */
  // Ross: For some reason verilator does not like this.  I checked and it is not a circular path.
  logic [NUMWAYS-2:0]                  LRUUpdate;
  logic [LOGNUMWAYS-1:0] Intermediate [NUMWAYS-2:0];
  /* verilator lint_on UNOPTFLAT */

  assign AllValid = &ValidWay;

  ///// Update replacement bits.
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
  assign LRUUpdate[NUMWAYS-2] = '1;
  for(s = NUMWAYS-2; s >= NUMWAYS/2; s--) begin : enables
    localparam p = NUMWAYS - s - 1;
    localparam g = log2(p);
    localparam t0 = s - p;
    localparam t1 = t0 - 1;
    localparam r = LOGNUMWAYS - g;
    assign LRUUpdate[t0] = LRUUpdate[s] & ~WayEncoded[r];
    assign LRUUpdate[t1] = LRUUpdate[s] & WayEncoded[r];
  end

  mux2 #(1) LRUMuxes[NUMWAYS-2:0](CurrLRU, ~WayExpanded, LRUUpdate, NextLRU);

  // Compute next victim way.
  for(s = NUMWAYS-2; s >= NUMWAYS/2; s--) begin
    localparam t0 = 2*s - NUMWAYS;
    localparam t1 = t0 + 1;
    assign Intermediate[s] = CurrLRU[s] ? Intermediate[t1] : Intermediate[t0];
  end
  for(s = NUMWAYS/2-1; s >= 0; s--) begin
    localparam int0 = (NUMWAYS/2-1-s)*2;
    localparam int1 = int0 + 1;
    assign Intermediate[s] = CurrLRU[s] ? int1[LOGNUMWAYS-1:0] : int0[LOGNUMWAYS-1:0];
  end

  logic [NUMWAYS-1:0] FirstZero;
  logic [LOGNUMWAYS-1:0] FirstZeroWay;
  logic [LOGNUMWAYS-1:0] VictimWayEnc;
  
  priorityonehot #(NUMWAYS) FirstZeroEncoder(~ValidWay, FirstZero);
  binencoder #(NUMWAYS) FirstZeroWayEncoder(FirstZero, FirstZeroWay);
  mux2 #(LOGNUMWAYS) VictimMux(FirstZeroWay, Intermediate[NUMWAYS-2], AllValid, VictimWayEnc);
  //decoder #(LOGNUMWAYS) decoder (Intermediate[NUMWAYS-2], VictimWay);
  decoder #(LOGNUMWAYS) decoder (VictimWayEnc, VictimWay);

  // LRU storage must be reset for modelsim to run. However the reset value does not actually matter in practice.
  always_ff @(posedge clk) begin
    if (reset) for (int set = 0; set < NUMLINES; set++) LRUMemory[set] <= '0;
    if(ce) begin
      if(InvalidateCache & ~FlushStage) for (int set = 0; set < NUMLINES; set++) LRUMemory[set] <= '0;
      else if (LRUWriteEn & ~FlushStage) begin 
        LRUMemory[PAdr] <= NextLRU;
        CurrLRU <= #1 NextLRU;
      end else begin
        CurrLRU <= #1 LRUMemory[CAdr];
      end
    end
  end

endmodule



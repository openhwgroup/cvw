///////////////////////////////////////////
// dcache (data cache)
//
// Written: ross1728@gmail.com July 20, 2021
//          Implements Pseudo LRU
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

module cachereplacementpolicy
  #(parameter NUMWAYS = 4, SETLEN = 9, OFFSETLEN = 5, NUMLINES = 128)(
   input logic                clk, reset,
   input logic [NUMWAYS-1:0]  HitWay,
   output logic [NUMWAYS-1:0] VictimWay,
   input logic [`PA_BITS-1:0] PAdr,
   input logic [SETLEN-1:0]   RAdr,
   input logic                LRUWriteEn);

  logic [NUMWAYS-2:0]                  LRUEn, LRUMask;
  logic [NUMWAYS-2:0]                  ReplacementBits [NUMLINES-1:0];
  logic [NUMWAYS-2:0]                  LineReplacementBits;
  logic [NUMWAYS-2:0]                  NewReplacement;
  logic [NUMWAYS-2:0]                  NewReplacementD;  
  logic [SETLEN+OFFSETLEN-1:OFFSETLEN] PAdrD;
  logic [SETLEN-1:0]                   RAdrD;
  logic                                LRUWriteEnD;

  initial begin
      assert (NUMWAYS == 2 || NUMWAYS == 4) else $error("Only 2 or 4 ways supported");
  end
  
  // Pipeline Delay Registers
  flopr #(SETLEN) RAdrDelayReg(clk, reset, RAdr, RAdrD);
  flopr #(SETLEN) PAdrDelayReg(clk, reset, PAdr[SETLEN+OFFSETLEN-1:OFFSETLEN], PAdrD);
  flopr #(1) LRUWriteEnDelayReg(clk, reset, LRUWriteEn, LRUWriteEnD);
  flopr #(NUMWAYS-1) NewReplacementDelayReg(clk, reset, NewReplacement, NewReplacementD);

  // Replacement Bits: Register file
  // Needs to be resettable for simulation, but could omit reset for synthesis ***
  always_ff @(posedge clk) 
    if (reset) for (int set = 0; set < NUMLINES; set++) ReplacementBits[set] = '0;
    else if (LRUWriteEnD) ReplacementBits[PAdrD[SETLEN+OFFSETLEN-1:OFFSETLEN]] = NewReplacementD;
  assign LineReplacementBits = ReplacementBits[RAdrD];

  genvar 		      index;
  if(NUMWAYS == 2) begin : PseudoLRU
    assign LRUEn[0] = 1'b0;
    assign NewReplacement[0] = HitWay[1];
    assign VictimWay[1] = ~LineReplacementBits[0];
    assign VictimWay[0] = LineReplacementBits[0];
  end else if (NUMWAYS == 4) begin : PseudoLRU
    // 1 hot encoding for VictimWay; LRU = LineReplacementBits
    //| LRU 2 | LRU 1 | LRU 0 |  VictimWay
    //+-------+-------+-------+-----------
    //|     1 | -     | 1     | 0001
    //|     1 | -     | 0     | 0010
    //|     0 | 1     | -     | 0100
    //|     0 | 0     | -     | 1000

    assign VictimWay[0] = ~LineReplacementBits[2] & ~LineReplacementBits[0];
    assign VictimWay[1] = ~LineReplacementBits[2] & LineReplacementBits[0];
    assign VictimWay[2] = LineReplacementBits[2] & ~LineReplacementBits[1];
    assign VictimWay[3] = LineReplacementBits[2] & LineReplacementBits[1];      

    // New LRU bits which are updated is function only of the HitWay.
    // However the not updated bits come from the old LRU.
    assign LRUEn[2] = |HitWay;
    assign LRUEn[1] = HitWay[3] | HitWay[2];
    assign LRUEn[0] = HitWay[1] | HitWay[0];

    assign LRUMask[2] = HitWay[1] | HitWay[0];
    assign LRUMask[1] = HitWay[2];
    assign LRUMask[0] = HitWay[0];

    mux2 #(1) LRUMuxes[NUMWAYS-2:0](LineReplacementBits, LRUMask, LRUEn, NewReplacement);
  end 
  /*  *** 8-way not yet working - look for a general way to write this for all NUMWAYS
  else if (NUMWAYS == 8) begin : PseudoLRU

    // selects
    assign LRUEn[6] = 1'b1;
    assign LRUEn[5] = HitWay[7] | HitWay[6] | HitWay[5] | HitWay[4];
    assign LRUEn[4] = HitWay[7] | HitWay[6];
    assign LRUEn[3] = HitWay[5] | HitWay[4];
    assign LRUEn[2] = HitWay[3] | HitWay[2] | HitWay[1] | HitWay[0];
    assign LRUEn[1] = HitWay[3] | HitWay[2];
    assign LRUEn[0] = HitWay[1] | HitWay[0];

    // mask
    assign LRUMask[6] = HitWay[7] | HitWay[6] | HitWay[5] | HitWay[4];
    assign LRUMask[5] = HitWay[7] | HitWay[6];
    assign LRUMask[4] = HitWay[7];
    assign LRUMask[3] = HitWay[5];
    assign LRUMask[2] = HitWay[3] | HitWay[2];
    assign LRUMask[1] = HitWay[2];
    assign LRUMask[0] = HitWay[0];

    for(index = 0; index < NUMWAYS-1; index++)
      assign NewReplacement[index] = LRUEn[index] ? LRUMask[index] : LineReplacementBits[index];

    assign EncVicWay[2] = LineReplacementBits[6];
    assign EncVicWay[1] = LineReplacementBits[6] ? LineReplacementBits[5] : LineReplacementBits[2];
    assign EncVicWay[0] = LineReplacementBits[6] ? LineReplacementBits[5] ? LineReplacementBits[4] : LineReplacementBits[3] :
        LineReplacementBits[2] ? LineReplacementBits[1] : LineReplacementBits[0];
    

    onehotdecoder #(3) 
    waydec(.bin(EncVicWay),
      .decoded({VictimWay[0], VictimWay[1], VictimWay[2], VictimWay[3],
          VictimWay[4], VictimWay[5], VictimWay[6], VictimWay[7]}));
  end */
endmodule



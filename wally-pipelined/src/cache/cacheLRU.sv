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

module cacheLRU
  #(NUMWAYS)
  (input logic [NUMWAYS-2:0] LRUIn,
   input logic [NUMWAYS-1:0] WayIn,
   output logic [NUMWAYS-2:0] LRUOut,
   output logic [NUMWAYS-1:0] VictimWay
   );

  //  *** Only implements 2, 4, and 8 way
  // I would like parametersize this in the future.

  logic [NUMWAYS-2:0] 	      NewLRUEn;
  logic [$clog2(NUMWAYS)-1:0] EncodedWay;
  logic 		      Hit;
  assign Hit = |WayIn;

  generate
    if(NUMWAYS == 2) begin : TwoWay
      
      assign EncodedWay[0] = WayIn[1];

      assign NewLRUEn[0] = 1'b0;

      assign LRUOut[0] = WayIn[1];

      assign VictimWay[1] = ~LRUIn[0];
      assign VictimWay[0] = LRUIn[0];
      
    end else if (NUMWAYS == 4) begin : FourWay 
      assign EncodedWay[0] = WayIn[1] | WayIn[3];
      assign EncodedWay[1] = WayIn[2] | WayIn[3];

      assign NewLRUEn[2] = 1'b1;
      assign NewLRUEn[1] = EncodedWay[1];
      assign NewLRUEn[0] = ~EncodedWay[1];

      assign LRUOut[2] = NewLRUEn[2] & Hit ? EncodedWay[1] : LRUIn[2];
      assign LRUOut[1] = NewLRUEn[1] & Hit ? EncodedWay[0] : LRUIn[1];
      assign LRUOut[0] = NewLRUEn[0] & Hit ? EncodedWay[0] : LRUIn[0];      

      assign VictimWay[3] = LRUOut[2] & LRUOut[1];      
      assign VictimWay[2] = LRUOut[2] & ~LRUOut[1];
      assign VictimWay[1] = ~LRUOut[2] & LRUOut[0];
      assign VictimWay[0] = ~LRUOut[2] & ~LRUOut[0];

    end else if (NUMWAYS == 8) begin : EightWay
      assign EncodedWay[0] = WayIn[1] | WayIn[3] | WayIn[5] | WayIn[7];
      assign EncodedWay[1] = WayIn[2] | WayIn[3] | WayIn[6] | WayIn[7];
      assign EncodedWay[2] = WayIn[4] | WayIn[5] | WayIn[6] | WayIn[7];

      assign NewLRUEn[6] = 1'b1;
      assign NewLRUEn[5] = EncodedWay[2];
      assign NewLRUEn[4] = ~EncodedWay[2];
      assign NewLRUEn[3] = EncodedWay[2] & EncodedWay[1];
      assign NewLRUEn[2] = EncodedWay[2] & ~EncodedWay[1];
      assign NewLRUEn[1] = ~EncodedWay[2] & EncodedWay[1];
      assign NewLRUEn[0] = ~EncodedWay[2] & ~EncodedWay[1];     

      assign LRUOut[6] = NewLRUEn[6] & Hit ? EncodedWay[2] : LRUIn[6];
      assign LRUOut[5] = NewLRUEn[5] & Hit ? EncodedWay[1] : LRUIn[5];
      assign LRUOut[4] = NewLRUEn[4] & Hit ? EncodedWay[1] : LRUIn[4];
      assign LRUOut[3] = NewLRUEn[3] & Hit ? EncodedWay[0] : LRUIn[3];
      assign LRUOut[2] = NewLRUEn[2] & Hit ? EncodedWay[0] : LRUIn[2];
      assign LRUOut[1] = NewLRUEn[1] & Hit ? EncodedWay[0] : LRUIn[1];
      assign LRUOut[0] = NewLRUEn[0] & Hit ? EncodedWay[0] : LRUIn[0];      

      assign VictimWay[7] = LRUOut[6] & LRUOut[5] & LRUOut[3];
      assign VictimWay[6] = LRUOut[6] & LRUOut[5] & ~LRUOut[3];
      assign VictimWay[5] = LRUOut[6] & ~LRUOut[5] & LRUOut[2];
      assign VictimWay[4] = LRUOut[6] & ~LRUOut[5] & ~LRUOut[2];
      assign VictimWay[3] = ~LRUOut[6] & LRUOut[4] & LRUOut[1];
      assign VictimWay[2] = ~LRUOut[6] & LRUOut[4] & ~LRUOut[1];
      assign VictimWay[1] = ~LRUOut[6] & ~LRUOut[4] & LRUOut[0];
      assign VictimWay[0] = ~LRUOut[6] & ~LRUOut[4] & ~LRUOut[0];

    end
  endgenerate
  
endmodule

  

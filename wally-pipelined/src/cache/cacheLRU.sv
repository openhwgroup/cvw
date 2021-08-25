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

  logic [NUMWAYS-2:0] 	      LRUEn, LRUMask;
  logic [$clog2(NUMWAYS)-1:0] EncVicWay;

  genvar 		      index;
  generate
    if(NUMWAYS == 2) begin : TwoWay
      
      assign LRUEn[0] = 1'b0;

      assign LRUOut[0] = WayIn[1];

      assign VictimWay[1] = ~LRUIn[0];
      assign VictimWay[0] = LRUIn[0];
      
    end else if (NUMWAYS == 4) begin : FourWay 

      // selects
      assign LRUEn[2] = 1'b1;
      assign LRUEn[1] = WayIn[3];      
      assign LRUEn[0] = WayIn[3] | WayIn[2];

      // mask
      assign LRUMask[0] = WayIn[1];
      assign LRUMask[1] = WayIn[3];      
      assign LRUMask[2] = WayIn[3] | WayIn[2];

      for(index = 0; index < NUMWAYS-1; index++)
	assign LRUOut[index] = LRUEn[index] ? LRUMask[index] : LRUIn[index];

      assign EncVicWay[1] = LRUIn[2];
      assign EncVicWay[0] = LRUIn[2] ? LRUIn[0] : LRUIn[1];

      onehotdecoder #(2) 
      waydec(.bin(EncVicWay),
		    .decoded({VictimWay[0], VictimWay[1], VictimWay[2], VictimWay[3]}));

    end else if (NUMWAYS == 8) begin : EightWay

      // selects
      assign LRUEn[6] = 1'b1;
      assign LRUEn[5] = WayIn[7] | WayIn[6] | WayIn[5] | WayIn[4];
      assign LRUEn[4] = WayIn[7] | WayIn[6];
      assign LRUEn[3] = WayIn[5] | WayIn[4];
      assign LRUEn[2] = WayIn[3] | WayIn[2] | WayIn[1] | WayIn[0];
      assign LRUEn[1] = WayIn[3] | WayIn[2];
      assign LRUEn[0] = WayIn[1] | WayIn[0];

      // mask
      assign LRUMask[6] = WayIn[7] | WayIn[6] | WayIn[5] | WayIn[4];
      assign LRUMask[5] = WayIn[7] | WayIn[6];
      assign LRUMask[4] = WayIn[7];
      assign LRUMask[3] = WayIn[5];
      assign LRUMask[2] = WayIn[3] | WayIn[2];
      assign LRUMask[1] = WayIn[2];
      assign LRUMask[0] = WayIn[0];

      for(index = 0; index < NUMWAYS-1; index++)
	assign LRUOut[index] = LRUEn[index] ? LRUMask[index] : LRUIn[index];

      assign EncVicWay[2] = LRUIn[6];
      assign EncVicWay[1] = LRUIn[6] ? LRUIn[5] : LRUIn[2];
      assign EncVicWay[0] = LRUIn[6] ? LRUIn[5] ? LRUIn[4] : LRUIn[3] :
			    LRUIn[2] ? LRUIn[1] : LRUIn[0];
      

      onehotdecoder #(3) 
      waydec(.bin(EncVicWay),
		    .decoded({VictimWay[0], VictimWay[1], VictimWay[2], VictimWay[3],
			      VictimWay[4], VictimWay[5], VictimWay[6], VictimWay[7]}));
    end
  endgenerate
  
endmodule

  

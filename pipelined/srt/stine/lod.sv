///////////////////////////////////////////
// lod.sv
//
// Written: James.Stine@okstate.edu 1 February 2021
// Modified: 
//
// Purpose: Integer Divide instructions
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

module lod2 (P, V, B);

   input logic  [1:0] B;

   output logic P;
   output logic V;

   assign V = B[0] | B[1];
   assign P = B[0] & ~B[1];
   
endmodule // lo2

module lod_hier #(parameter WIDTH=8) 
   (input logic [WIDTH-1:0]          B,
    output logic [$clog2(WIDTH)-1:0] ZP,
    output logic 		     ZV);

   if (WIDTH == 128)
     lod128 lod128 (ZP, ZV, B);	      
   else if (WIDTH == 64)
     lod64 lod64 (ZP, ZV, B);	   
   else if (WIDTH == 32)
     lod32 lod32 (ZP, ZV, B);
   else if (WIDTH == 16)
     lod16 lod16 (ZP, ZV, B);
   else if (WIDTH == 8)
     lod8 lod8 (ZP, ZV, B);
   else if (WIDTH == 4)
     lod4 lod4 (ZP, ZV, B);

endmodule // lod_hier

module lod4 (ZP, ZV, B);

   input logic [3:0]  B;

   logic  	       ZPa;
   logic  	       ZPb;
   logic 	       ZVa;
   logic 	       ZVb;   

   output logic [1:0]  ZP;
   output logic        ZV;

   lod2 l1(ZPa, ZVa, B[1:0]);
   lod2 l2(ZPb, ZVb, B[3:2]);

   assign ZP[0:0] = ZVb ? ZPb : ZPa;
   assign ZP[1]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lod4

module lod8 (ZP, ZV, B);

   input logic [7:0]  B;

   logic [1:0] 	       ZPa;
   logic [1:0] 	       ZPb;
   logic 	       ZVa;
   logic 	       ZVb;   

   output logic [2:0]  ZP;
   output logic        ZV;

   lod4 l1(ZPa, ZVa, B[3:0]);
   lod4 l2(ZPb, ZVb, B[7:4]);

   assign ZP[1:0] = ZVb ? ZPb : ZPa;
   assign ZP[2]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lod8

module lod16 (ZP, ZV, B);

   input logic [15:0]  B;

   logic [2:0] 	       ZPa;
   logic [2:0] 	       ZPb;
   logic 	       ZVa;
   logic 	       ZVb;   

   output logic [3:0]  ZP;
   output logic        ZV;

   lod8 l1(ZPa, ZVa, B[7:0]);
   lod8 l2(ZPb, ZVb, B[15:8]);

   assign ZP[2:0] = ZVb ? ZPb : ZPa;
   assign ZP[3]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lod16

module lod32 (ZP, ZV, B);

   input logic [31:0] B;

   logic [3:0] 	      ZPa;
   logic [3:0] 	      ZPb;
   logic 	      ZVa;
   logic 	      ZVb;
   
   output logic [4:0] ZP;
   output logic       ZV;
   
   lod16 l1(ZPa, ZVa, B[15:0]);
   lod16 l2(ZPb, ZVb, B[31:16]);
   
   assign ZP[3:0] = ZVb ? ZPb : ZPa;
   assign ZP[4]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lod32

module lod64 (ZP, ZV, B);

   input logic [63:0]  B;
   
   logic [4:0] 	       ZPa;
   logic [4:0] 	       ZPb;
   logic 	       ZVa;
   logic 	       ZVb;
   
   output logic [5:0]  ZP;
   output logic        ZV;
   
   lod32 l1(ZPa, ZVa, B[31:0]);
   lod32 l2(ZPb, ZVb, B[63:32]);
   
   assign ZP[4:0] = ZVb ? ZPb : ZPa;
   assign ZP[5]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lod64

module lod128 (ZP, ZV, B);

   input logic [127:0]  B;
   
   logic [5:0] 	       ZPa;
   logic [5:0] 	       ZPb;
   logic 	       ZVa;
   logic 	       ZVb;
   
   output logic [6:0]  ZP;
   output logic        ZV;
   
   lod64 l1(ZPa, ZVa, B[63:0]);
   lod64 l2(ZPb, ZVb, B[127:64]);
   
   assign ZP[5:0] = ZVb ? ZPb : ZPa;
   assign ZP[6]   = ~ZVb;
   assign ZV = ZVa | ZVb;

endmodule // lod128

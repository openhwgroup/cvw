///////////////////////////////////////////
//
// Written: James Stine
// Modified: 8/1/2018
//
// Purpose: Bipartite Lookup for sqrt part of fpdivsqrt
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

module sbtm_sqrt (input logic [11:0] a, output logic [10:0] y);

   // bit partitions
   logic [4:0] x0;
   logic [2:0] x1;
   logic [3:0] x2;
   logic [2:0] x2_1cmp;   
   // mem outputs
   logic [13:0] y0;
   logic [5:0]  y1;
   // input to CPA
   logic [14:0] op1;
   logic [14:0] op2;
   logic [14:0] p; 
   logic        cout;  

   assign x0 = a[11:7];
   assign x1 = a[6:4];
   assign x2 = a[3:0];   

   sbtm_a2 mem1 ({x0, x1}, y0);
   assign op1 = {y0, 1'b0};
   
   // 1s cmp per sbtm/stam
   assign x2_1cmp = x2[3] ? ~x2[2:0] : x2[2:0];   
   sbtm_a3 mem2 ({x0, x2_1cmp}, y1);
   // 1s cmp per sbtm/stam
   assign op2 = x2[3] ? {{8{1'b1}}, ~y1, 1'b1} :
		{8'b0, y1, 1'b1};
   
   // CPA
   assign {cout, p} = op1 + op2; 
   assign y = p[14:4];

endmodule // sbtm2


   


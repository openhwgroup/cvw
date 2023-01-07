///////////////////////////////////////////
// fdivsqrtqsel4cmp.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Comparator-based Radix 4 Quotient Digit Selection
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

module fdivsqrtqsel4cmp (
  input  logic [2:0] Dmsbs,
  input  logic [4:0] Smsbs,
  input  logic [7:0] WSmsbs, WCmsbs,
  input  logic SqrtE, j1,
  output logic [3:0] udigit
);
	logic [6:0] Wmsbs;
	logic [7:0] PreWmsbs;
	logic [2:0] A;

	assign PreWmsbs = WCmsbs + WSmsbs;
	assign Wmsbs = PreWmsbs[7:1];
	// D = 0001.xxx...
	// Dmsbs = |   |
  // W =      xxxx.xxx...
	// Wmsbs = |        |

  logic [6:0] mk2, mk1, mk0, mkm1;
  logic [6:0] mks2[7:0], mks1[7:0]; 

  // Prepopulate table of mks0
  assign mks2[0] = 12;
  assign mks2[1] = 14;
  assign mks2[2] = 16;
  assign mks2[3] = 17;
  assign mks2[4] = 18;
  assign mks2[5] = 20;
  assign mks2[6] = 22;
  assign mks2[7] = 23;
  assign mks1[0] = 4;
  assign mks1[1] = 4;
  assign mks1[2] = 6;
  assign mks1[3] = 6;
  assign mks1[4] = 6;
  assign mks1[5] = 8; // is the logic any cheaper if this is a 6?
  assign mks1[6] = 8;
  assign mks1[7] = 8;

  // Choose A for current operation
 always_comb
    if (SqrtE) begin 
      if (j1) A = 3'b101;
      else if (Smsbs == 5'b10000) A = 3'b111;
      else A = Smsbs[2:0];
    end else A = Dmsbs;

  // Choose selection constants based on a
  assign mk2 = mks2[A];
  assign mk1 = mks1[A];
  assign mk0 = -mks1[A];
  assign mkm1 = (A == 3'b000) ? -13 : -mks2[A]; // asymmetry in table
 
  // Compare residual W to selection constants to choose digit
  always_comb 
    if ($signed(Wmsbs) >= $signed(mk2)) udigit = 4'b1000; // choose 2
    else if ($signed(Wmsbs) >= $signed(mk1)) udigit = 4'b0100; // choose 1
    else if ($signed(Wmsbs) >= $signed(mk0)) udigit = 4'b0000; // choose 0
    else if ($signed(Wmsbs) >= $signed(mkm1)) udigit = 4'b0010; // choose -1
    else udigit = 4'b0001; // choose -2	
endmodule

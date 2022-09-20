///////////////////////////////////////////
// fdivsqrtqsel2.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 2 Quotient Digit Selection
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

module fdivsqrtqsel2 ( 
  input  logic [3:0] ps, pc, 
  output logic         qp, qz, qn
);
 
  logic [3:0]  p, g;
  logic          magnitude, sign, cout;

  // The quotient selection logic is presented for simplicity, not
  // for efficiency.  You can probably optimize your logic to
  // select the proper divisor with less delay.

  // Qmient equations from EE371 lecture notes 13-20
  assign p = ps ^ pc;
  assign g = ps & pc;

  //assign magnitude = ~(&p[2:0]);
  assign cout = g[2] | (p[2] & (g[1] | p[1] & g[0]));
  //assign sign = p[3] ^ cout;
  assign magnitude = ~((ps[2]^pc[2]) & (ps[1]^pc[1]) & 
			  (ps[0]^pc[0]));
  assign sign = (ps[3]^pc[3])^
      (ps[2] & pc[2] | ((ps[2]^pc[2]) &
			    (ps[1]&pc[1] | ((ps[1]^pc[1]) &
						(ps[0]&pc[0])))));

  // Produce quotient = +1, 0, or -1
  assign qp = magnitude & ~sign;
  assign qz = ~magnitude;
  assign qn = magnitude & sign;
endmodule

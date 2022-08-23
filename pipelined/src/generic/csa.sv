///////////////////////////////////////////
// csa.sv
//
// Written: Katherine Parry and David_Harris@hmc.edu 21 August 2022
// Modified: 
//
// Purpose: 3:2 carry-save adder
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

module csa #(parameter N=16) (
  input  logic [N-1:0] x, y, z, 
  input  logic         cin, 
  output logic [N-1:0] s, c
);

  // This block adds x, y, z, and cin to produce 
  // a result s / c in carry-save redundant form.
  // cin is just added to the least significant bit
  // s + c = x + y + z + cin
 
  assign s = x ^ y ^ z;
  assign c = {x[N-2:0] & (y[N-2:0] | z[N-2:0]) | 
		    (y[N-2:0] & z[N-2:0]), cin};
endmodule

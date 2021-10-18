///////////////////////////////////////////
// redundantmul.sv
//
// Written: David_Harris@hmc.edu and ssanghai@hm.edu 10/11/2021
// Modified: 
//
// Purpose: redundant multiplier 
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

module redundantmul #(parameter WIDTH =8)(
  input  logic [WIDTH-1:0] a,b,
  output logic [2*WIDTH-1:0] out0, out1);

  generate
     if (`DESIGN_COMPILER == 1)
       DW02_multp #(WIDTH, WIDTH, 2*WIDTH) mul(.a, .b, .tc(1'b0), .out0, .out1);
     else if (`DESIGN_COMPILER == 2)
       mult_cs #(WIDTH) mul(.a, .b, .tc(1'b0), .sum(out0), .carry(out1));
     else begin // force a nonredunant multipler.  This will simulate properly and also is appropriate for FPGAs.
       assign out0 = a * b;
       assign out1 = 0;
     end
  endgenerate

endmodule



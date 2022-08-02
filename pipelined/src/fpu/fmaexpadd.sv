///////////////////////////////////////////
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: FMA exponent addition
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

module fmaexpadd(    
    input  logic [`FMTBITS-1:0] Fmt,          // format of the output: single double half quad
    input  logic [`NE-1:0]      Xe, Ye,  // input's exponents
    input  logic                XZero, YZero,        // are the inputs zero
    output logic [`NE+1:0]      Pe       // product's exponent B^(1023)NE+2
);

   logic 			PZero;
   
    // kill the exponent if the product is zero - either X or Y is 0
   assign PZero = XZero | YZero;
    assign Pe = PZero ? '0 : ({2'b0, Xe} + {2'b0, Ye} - {2'b0, (`NE)'(`BIAS)});

endmodule

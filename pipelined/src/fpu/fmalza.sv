///////////////////////////////////////////
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: Leading Zero Anticipator
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

module fmalza #(WIDTH) ( // [Schmookler & Nowka, Leading zero anticipation and detection, IEEE Sym. Computer Arithmetic, 2001]
    input logic [WIDTH-1:0] 	       A, // addend
    input logic [2*`NF+3:0] 	       Pm, // product
    input logic 		       Cin, // carry in
    input logic sub,
    output logic [$clog2(WIDTH+1)-1:0] SCnt   // normalization shift count for the positive result
    ); 

   logic [WIDTH:0] 	       F;
   logic [WIDTH-1:0]  B, P, G, K;
    logic [WIDTH-1:0] Pp1, Gm1, Km1;

    assign B = {{(`NF+2){1'b0}}, Pm}; // Zero extend product

    assign P = A^B;
    assign G = A&B;
    assign K= ~A&~B;

   assign Pp1 = {sub, P[WIDTH-1:1]};
   assign Gm1 = {G[WIDTH-2:0], Cin};
   assign Km1 = {K[WIDTH-2:0], ~Cin};
   
    // Apply function to determine Leading pattern
    //      - note: the paper linked above uses the numbering system where 0 is the most significant bit
    assign F[WIDTH] = ~sub&P[WIDTH-1];
    assign F[WIDTH-1:0] = (Pp1&(G&~Km1 | K&~Gm1)) | (~Pp1&(K&~Km1 | G&~Gm1));

    lzc #(WIDTH+1) lzc (.num(F), .ZeroCnt(SCnt));
endmodule

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

module fmalza( // [Schmookler & Nowka, Leading zero anticipation and detection, IEEE Sym. Computer Arithmetic, 2001]
    input logic  [3*`NF+6:0] A,     // addend
    input logic  [2*`NF+3:0] P,     // product
    output logic [$clog2(3*`NF+7)-1:0]       SCnt   // normalization shift count for the positive result
    ); 
    
    logic [3*`NF+6:0] T;
    logic [3*`NF+6:0] G;
    logic [3*`NF+6:0] Z;
    logic [3*`NF+6:0] f;

    assign T[3*`NF+6:2*`NF+4] = A[3*`NF+6:2*`NF+4];
    assign G[3*`NF+6:2*`NF+4] = 0;
    assign Z[3*`NF+6:2*`NF+4] = ~A[3*`NF+6:2*`NF+4];
    assign T[2*`NF+3:0] = A[2*`NF+3:0]^P;
    assign G[2*`NF+3:0] = A[2*`NF+3:0]&P;
    assign Z[2*`NF+3:0] = ~A[2*`NF+3:0]&~P;


    // Apply function to determine Leading pattern
    //      - note: the paper linked above uses the numbering system where 0 is the most significant bit
    //f[n] = ~T[n]&T[n-1]           note: n is the MSB
    //f[i] = (T[i+1]&(G[i]&~Z[i-1] | Z[i]&~G[i-1])) | (~T[i+1]&(Z[i]&~Z[i-1] | G[i]&~G[i-1]))
    assign f[3*`NF+6] = ~T[3*`NF+6]&T[3*`NF+5];
    assign f[3*`NF+5:0] = (T[3*`NF+6:1]&(G[3*`NF+5:0]&{~Z[3*`NF+4:0], 1'b0} | Z[3*`NF+5:0]&{~G[3*`NF+4:0], 1'b1})) | (~T[3*`NF+6:1]&(Z[3*`NF+5:0]&{~Z[3*`NF+4:0], 1'b0} | G[3*`NF+5:0]&{~G[3*`NF+4:0], 1'b1}));



    lzc #(3*`NF+7) lzc (.num(f), .ZeroCnt(SCnt));
  
endmodule

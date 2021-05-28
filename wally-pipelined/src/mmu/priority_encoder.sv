///////////////////////////////////////////
// priority_encoder.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 7 April 2021
// Based on implementation from https://www.allaboutcircuits.com/ip-cores/communication-controller/priority-encoder/
// *** Give proper LGPL attribution for above source
// Modified: Teo Ene 15 Apr 2021:
//              Temporarily removed paramterized priority encoder for non-parameterized one
//              To get synthesis working quickly
//           Kmacsaigoren@hmc.edu 28 May 2021:
//              Added working version of parameterized priority encoder. 
//
// Purpose: One-hot encoding to binary encoder
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

module priority_encoder #(parameter BINARY_BITS = 3) (
  input  logic  [2**BINARY_BITS - 1:0] one_hot,
  output logic  [BINARY_BITS - 1:0] binary
);

  integer i;
  always_comb begin
    binary = 0;
    for (i = 0; i < 2**BINARY_BITS; i++) begin
      if (one_hot[i]) binary = i; // prioritizes the most significant bit
    end
  end
  // *** triple check synthesizability here

  // Ideally this mimics the following:
  /*
  always_comb begin
    casex (one_hot)
      1xx ... x: binary = BINARY_BITS - 1;
      01x ... x: binary = BINARY_BITS - 2;
      001 ... x: binary = BINARY_BITS - 3;
      
      {...}

      00 ... 1xx: binary = 2;
      00 ... 01x: binary = 1;
      00 ... 001: binary = 0;
  end
  */
endmodule

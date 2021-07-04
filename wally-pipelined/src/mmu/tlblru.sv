///////////////////////////////////////////
// tlblru.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 16 February 2021
// Modified:
//
// Purpose: Implementation of bit pseudo least-recently-used algorithm for
//          cache evictions. Outputs the index of the next entry to be written.
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

module tlblru #(parameter ENTRY_BITS = 3) (
  input logic                     clk, reset,
  input logic                     TLBWrite,
  input logic                     TLBFlush,
  input logic [2**ENTRY_BITS-1:0]    ReadLines,
  input logic                     CAMHit,
  output logic [2**ENTRY_BITS-1:0]   WriteLines
);

  localparam NENTRIES = 2**ENTRY_BITS;

  // Keep a "recently-used" record for each TLB entry. On access, set to 1
  logic [NENTRIES-1:0] RUBits, RUBitsNext, RUBitsAccessed;

  // One-hot encodings of which line is being accessed
  logic [NENTRIES-1:0] AccessLines;
  
  // High if the next access causes all RU bits to be 1
  logic                AllUsed;

  // Find the first line not recently used
  tlbpriority #(NENTRIES) nru(~RUBits, WriteLines);

  // Track recently used lines, updating on a CAM Hit or TLB write
  assign AccessLines = TLBWrite ? WriteLines : ReadLines;
  assign RUBitsAccessed = AccessLines | RUBits;
  assign AllUsed = &RUBitsAccessed; // if all recently used, then clear to none
  assign RUBitsNext = AllUsed ? 0 : RUBitsAccessed; 
  flopenrc #(NENTRIES) lrustate(clk, reset, TLBFlush, (CAMHit || TLBWrite), RUBitsNext, RUBits);

endmodule

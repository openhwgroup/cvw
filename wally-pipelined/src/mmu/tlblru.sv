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

module tlblru #(parameter TLB_ENTRIES = 8) (
  input  logic                clk, reset,
  input  logic                TLBWrite,
  input  logic                TLBFlush,
  input  logic [TLB_ENTRIES-1:0] Matches,
  input  logic                CAMHit,
  output logic [TLB_ENTRIES-1:0] WriteEnables
);

  logic [TLB_ENTRIES-1:0] RUBits, RUBitsNext, RUBitsAccessed;
  logic [TLB_ENTRIES-1:0] WriteLines;
  logic [TLB_ENTRIES-1:0] AccessLines; // One-hot encodings of which line is being accessed
  logic                AllUsed;  // High if the next access causes all RU bits to be 1

  // Find the first line not recently used
  tlbpriority #(TLB_ENTRIES) nru(~RUBits, WriteLines);

  // Track recently used lines, updating on a CAM Hit or TLB write
  assign WriteEnables = WriteLines & {(TLB_ENTRIES){TLBWrite}};
  assign AccessLines = TLBWrite ? WriteLines : Matches;
  assign RUBitsAccessed = AccessLines | RUBits;
  assign AllUsed = &RUBitsAccessed; // if all recently used, then clear to none
  assign RUBitsNext = AllUsed ? 0 : RUBitsAccessed; 
  flopenrc #(TLB_ENTRIES) lrustate(clk, reset, TLBFlush, (CAMHit || TLBWrite), RUBitsNext, RUBits);
  // *** seems like enable must be ORd with TLBFlush to ensure flop fires on a flush.  DH 7/8/21
endmodule

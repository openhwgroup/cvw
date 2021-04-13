///////////////////////////////////////////
// tlb_cam.sv
//
// Written: jtorrey@hmc.edu 16 February 2021
// Modified:
//
// Purpose: Stores virtual page numbers with cached translations.
//          Determines whether a given virtual page number is in the TLB.
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

module tlb_cam #(parameter ENTRY_BITS = 3,
                 parameter KEY_BITS   = 20,
                 parameter HIGH_SEGMENT_BITS = 10) (
  input                    clk, reset,
  input  [KEY_BITS-1:0]    VirtualPageNumber,
  input  [1:0]             PageTypeWrite,
  input  [ENTRY_BITS-1:0]  WriteIndex,
  input                    TLBWrite,
  input                    TLBFlush,
  output [ENTRY_BITS-1:0]  VPNIndex,
  output [1:0]             HitPageType,
  output                   CAMHit
);

  localparam NENTRIES = 2**ENTRY_BITS;

  logic [NENTRIES-1:0] CAMLineWrite;
  logic [1:0] PageTypeList [0:NENTRIES-1];
  logic [NENTRIES-1:0] Matches;

  // Determine which CAM line should be written, based on a binary index
  decoder #(ENTRY_BITS) decoder(WriteIndex, CAMLineWrite);

  // Create NENTRIES CAM lines, each of which will independently consider
  // whether the requested virtual address is a match. Each line stores the
  // original virtual page number from when the address was written, regardless
  // of page type. However, matches are determined based on a subset of the
  // page number segments.
  generate
    genvar i;
    for (i = 0; i < NENTRIES; i++) begin
      cam_line #(KEY_BITS, HIGH_SEGMENT_BITS) cam_line(
        .CAMLineWrite(CAMLineWrite[i] && TLBWrite),
        .PageType(PageTypeList[i]),
        .Match(Matches[i]),
        .*);
    end
  endgenerate

  // In case there are multiple matches in the CAM, select only one
  // *** it might be guaranteed that the CAM will never have multiple matches.
  // If so, this is just an encoder
  priority_encoder #(ENTRY_BITS) match_priority(Matches, VPNIndex);

  assign CAMHit = |Matches & ~TLBFlush;
  assign HitPageType = PageTypeList[VPNIndex];

endmodule

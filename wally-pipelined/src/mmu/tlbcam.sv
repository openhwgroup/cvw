///////////////////////////////////////////
// tlbcam.sv
//
// Written: jtorrey@hmc.edu 16 February 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
//            Implemented SV48 on top of SV39. This included adding the SvMode signal input and wally constants
//            Mostly this was to make the cam_lines work.
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

`include "wally-config.vh"

module tlbcam #(parameter ENTRY_BITS = 3,
                 parameter KEY_BITS   = 20,
                 parameter SEGMENT_BITS = 10) (
  input logic                     clk, reset,
  input logic [KEY_BITS-1:0]      VirtualPageNumber,
  input logic [1:0]               PageTypeWriteVal,
//  input logic [`SVMODE_BITS-1:0]  SvMode, // *** may not need to be used.
  input logic                     TLBWrite,
  input logic                     TLBFlush,
  input logic [2**ENTRY_BITS-1:0] WriteLines,

  output logic [ENTRY_BITS-1:0]   VPNIndex,
  output logic [1:0]              HitPageType,
  output logic                    CAMHit
);

  localparam NENTRIES = 2**ENTRY_BITS;


  logic [1:0] PageTypeList [0:NENTRIES-1];
  logic [NENTRIES-1:0] Matches;

  // Create NENTRIES CAM lines, each of which will independently consider
  // whether the requested virtual address is a match. Each line stores the
  // original virtual page number from when the address was written, regardless
  // of page type. However, matches are determined based on a subset of the
  // page number segments.
  generate
    genvar i;
    for (i = 0; i < NENTRIES; i++) begin
      camline #(KEY_BITS, SEGMENT_BITS) camline(
        .CAMLineWrite(WriteLines[i] && TLBWrite),
        .PageType(PageTypeList[i]),
        .Match(Matches[i]),
        .*);
    end
  endgenerate

  // In case there are multiple matches in the CAM, select only one
  // *** it might be guaranteed that the CAM will never have multiple matches.
  // If so, this is just an encoder
  priorityencoder #(ENTRY_BITS) matchencoder(Matches, VPNIndex);

  assign CAMHit = |Matches & ~TLBFlush;
  assign HitPageType = PageTypeList[VPNIndex];

endmodule

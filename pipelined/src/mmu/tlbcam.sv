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

module tlbcam #(parameter TLB_ENTRIES = 8,
                parameter KEY_BITS   = 20,
                parameter SEGMENT_BITS = 10) (
  input logic                     clk, reset,
  input logic [`VPN_BITS-1:0]     VPN,
  input logic [1:0]               PageTypeWriteVal,
  input  logic                    SV39Mode,
  input logic                     TLBFlush,
  input logic [TLB_ENTRIES-1:0]   WriteEnables,
  input logic [TLB_ENTRIES-1:0]   PTE_Gs,
  input logic [`ASID_BITS-1:0]    SATP_ASID,
  output logic [TLB_ENTRIES-1:0]  Matches,
  output logic [1:0]              HitPageType,
  output logic                    CAMHit
);

  logic [1:0] PageTypeRead [TLB_ENTRIES-1:0];

  // Create TLB_ENTRIES CAM lines, each of which will independently consider
  // whether the requested virtual address is a match. Each line stores the
  // original virtual page number from when the address was written, regardless
  // of page type. However, matches are determined based on a subset of the
  // page number segments.

  tlbcamline #(KEY_BITS, SEGMENT_BITS) camlines[TLB_ENTRIES-1:0](
    .clk, .reset, .VPN, .SATP_ASID, .SV39Mode, .PTE_G(PTE_Gs), .PageTypeWriteVal, .TLBFlush,
    .WriteEnable(WriteEnables), .PageTypeRead, .Match(Matches));
  assign CAMHit = |Matches & ~TLBFlush;
  or_rows #(TLB_ENTRIES,2) PageTypeOr(PageTypeRead, HitPageType);
endmodule


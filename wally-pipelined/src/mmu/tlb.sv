///////////////////////////////////////////
// tlb.sv
//
// Written: jtorrey@hmc.edu 16 February 2021
// Modified:
//
// Purpose: Example translation lookaside buffer
//           Cache of virtural-to-physical address translations
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
`include "wally-constants.vh"

/**
 * sv32 specs
 * ----------
 * Virtual address [31:0] (32 bits)
 *    [________________________________]
 *     |--VPN1--||--VPN0--||----OFF---|
 *         10        10         12
 * 
 * Physical address [33:0] (34 bits)
 *  [__________________________________]
 *   |---PPN1---||--PPN0--||----OFF---|
 *        12         10         12
 * 
 * Page Table Entry [31:0] (32 bits)
 *    [________________________________]
 *     |---PPN1---||--PPN0--|||DAGUXWRV
 *          12         10    ^^
 *                         RSW(2) -- for OS
 */

/* *** TODO:
 * - add LRU algorithm (select the write index based on which entry was used
 *   least recently)
 * - refactor modules into multiple files
 */

// The TLB will have 2**ENTRY_BITS total entries
module tlb #(parameter ENTRY_BITS = 3) (
  input              clk, reset,

  // Current value of satp CSR (from privileged unit)
  input  [`XLEN-1:0] SATP_REGW,

  // Current privilege level of the processeor
  input  [1:0]       PrivilegeModeW,

  // High if the TLB is currently being accessed
  input              TLBAccess,

  // Virtual address input
  input  [`XLEN-1:0] VirtualAddress,

  // Controls for writing a new entry to the TLB
  input  [`XLEN-1:0] PageTableEntryWrite,
  input  [1:0]       PageTypeWrite,
  input              TLBWrite,

  // Invalidate all TLB entries
  input              TLBFlush,

  // Physical address outputs
  output [`XLEN-1:0] PhysicalAddress,
  output             TLBMiss,
  output             TLBHit,

  // Faults
  output             TLBPageFault
);

  logic SvMode;
  logic Translate;

  generate
    if (`XLEN == 32) begin
      assign SvMode = SATP_REGW[31];  // *** change to an enum somehow?
    end else begin
      assign SvMode = SATP_REGW[63]; // currently just a boolean whether translation enabled
    end
  endgenerate
  // *** Currently fake virtual memory being on for testing purposes
  // *** DO NOT ENABLE UNLESS TESTING
  // assign SvMode = 1;

  assign Translate = SvMode & (PrivilegeModeW != `M_MODE);

  // *** If we want to support multiple virtual memory modes (ie sv39 AND sv48),
  // we could have some muxes that control which parameters are current.
  // Although then some of the signals are not big enough. But that's a problem
  // for much later.

  // Index (currently random) to write the next TLB entry
  logic [ENTRY_BITS-1:0] WriteIndex;

  // Sections of the virtual and physical addresses
  logic [`VPN_BITS-1:0] VirtualPageNumber;
  logic [`PPN_BITS-1:0] PhysicalPageNumber, PhysicalPageNumberMixed;
  logic [7:0]           PTEAccessBits;
  logic [11:0]          PageOffset;
  logic [`PA_BITS-1:0]  PhysicalAddressFull;

  // Pattern location in the CAM and type of page hit
  logic [ENTRY_BITS-1:0] VPNIndex;
  logic [1:0]            HitPageType;

  // RAM access location
  logic [ENTRY_BITS-1:0] EntryIndex;

  logic             CAMHit;

  assign VirtualPageNumber = VirtualAddress[`VPN_BITS+11:12];
  assign PageOffset        = VirtualAddress[11:0];

  // Currently use random replacement algorithm
  tlb_rand rdm(.*);

  tlb_ram #(ENTRY_BITS) ram(.*);
  tlb_cam #(ENTRY_BITS, `VPN_BITS, `VPN_SEGMENT_BITS) cam(.*);

  // *** check whether access is allowed, otherwise fault
  assign TLBPageFault = 0; // *** temporary

  localparam EXTRA_PHYSICAL_BITS = `PPN_HIGH_SEGMENT_BITS - `VPN_SEGMENT_BITS;

  page_number_mixer #(`PPN_BITS, `PPN_HIGH_SEGMENT_BITS)
    physical_mixer(PhysicalPageNumber,
      {{EXTRA_PHYSICAL_BITS{1'b0}}, VirtualPageNumber},
      HitPageType,
      PhysicalPageNumberMixed);

  assign PhysicalAddressFull = (TLBHit) ?
    {PhysicalPageNumberMixed, PageOffset} : '0;

  generate
    if (`XLEN == 32) begin
      mux2 #(`XLEN) addressmux(VirtualAddress, PhysicalAddressFull[31:0], Translate, PhysicalAddress);
    end else begin
      mux2 #(`XLEN) addressmux(VirtualAddress, {8'b0, PhysicalAddressFull}, Translate, PhysicalAddress);
    end
  endgenerate

  assign TLBHit = CAMHit & TLBAccess;
  assign TLBMiss = ~TLBHit & ~TLBFlush & Translate & TLBAccess;
endmodule

// *** use actual flop notation instead of initialbegin and alwaysff
module tlb_ram #(parameter ENTRY_BITS = 3) (
  input                   clk, reset,
  input  [ENTRY_BITS-1:0] VPNIndex,  // Index to read from
  input  [ENTRY_BITS-1:0] WriteIndex,
  input  [`XLEN-1:0]      PageTableEntryWrite,
  input                   TLBWrite,

  output [`PPN_BITS-1:0]  PhysicalPageNumber,
  output [7:0]            PTEAccessBits
);

  localparam NENTRIES = 2**ENTRY_BITS;

  logic [`XLEN-1:0] ram [0:NENTRIES-1];
  logic [`XLEN-1:0] PageTableEntry;
  always @(posedge clk) begin
    if (TLBWrite) ram[WriteIndex] <= PageTableEntryWrite;
  end

  assign PageTableEntry = ram[VPNIndex];
  assign PTEAccessBits = PageTableEntry[7:0];
  assign PhysicalPageNumber = PageTableEntry[`PPN_BITS+9:10];

  initial begin
    for (int i = 0; i < NENTRIES; i++)
      ram[i] = `XLEN'b0;
  end

endmodule

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
  priority_encoder #(ENTRY_BITS) match_priority(Matches, VPNIndex);

  assign CAMHit = |Matches & ~TLBFlush;
  assign HitPageType = PageTypeList[VPNIndex];

endmodule

module tlb_rand #(parameter ENTRY_BITS = 3) (
  input                   clk, reset,
  output [ENTRY_BITS-1:0] WriteIndex
);

  logic [31:0] data;
  assign data = $urandom;
  assign WriteIndex = data[ENTRY_BITS-1:0];
  
endmodule

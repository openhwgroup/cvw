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

  // Whether translation should occur
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
  logic [`PA_BITS-1:0]  PhysicalAddressFull;

  // Sections of the page table entry
  logic [7:0]           PTEAccessBits;
  logic [11:0]          PageOffset;

  // Pattern location in the CAM and type of page hit
  logic [ENTRY_BITS-1:0] VPNIndex;
  logic [1:0]            HitPageType;

  // Whether the virtual address has a match in the CAM
  logic                  CAMHit;

  assign VirtualPageNumber = VirtualAddress[`VPN_BITS+11:12];
  assign PageOffset        = VirtualAddress[11:0];

  // Currently use random replacement algorithm
  tlb_rand rdm(.*);

  tlb_ram #(ENTRY_BITS) ram(.*);
  tlb_cam #(ENTRY_BITS, `VPN_BITS, `VPN_SEGMENT_BITS) cam(.*);

  // *** check whether access is allowed, otherwise fault
  assign TLBPageFault = 0; // *** temporary

  // *** Not the cleanest solution.
  // The highest segment of the physical page number has some extra bits
  // than the highest segment of the virtual page number.
  localparam EXTRA_PHYSICAL_BITS = `PPN_HIGH_SEGMENT_BITS - `VPN_SEGMENT_BITS;

  // Replace segments of the virtual page number with segments of the physical
  // page number. For 4 KB pages, the entire virtual page number is replaced.
  // For superpages, some segments are considered offsets into a larger page.
  page_number_mixer #(`PPN_BITS, `PPN_HIGH_SEGMENT_BITS)
    physical_mixer(PhysicalPageNumber,
      {{EXTRA_PHYSICAL_BITS{1'b0}}, VirtualPageNumber},
      HitPageType,
      PhysicalPageNumberMixed);

  // Provide physical address only on TLBHits to cause catastrophic errors if
  // garbage address is used.
  assign PhysicalAddressFull = (TLBHit) ?
    {PhysicalPageNumberMixed, PageOffset} : '0;

  // Output the hit physical address if translation is currently on.
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

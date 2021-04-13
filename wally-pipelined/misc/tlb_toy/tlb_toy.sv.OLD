///////////////////////////////////////////
// tlb_toy.sv
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
module tlb_toy #(parameter ENTRY_BITS = 3) (
  input              clk, reset,

  // Current value of satp CSR (from privileged unit)
  input  [`XLEN-1:0] SATP,  // *** How do we get this?

  // Virtual address input
  input  [`XLEN-1:0] VirtualAddress,

  // Controls for writing a new entry to the TLB
  input  [`XLEN-1:0] PageTableEntryWrite,
  input              TLBWrite,

  // Invalidate all TLB entries
  input              TLBFlush,

  // Physical address outputs
  output [`XLEN-1:0] PhysicalAddress,
  output             TLBMiss,
  output             TLBHit
);

  generate
    if (`XLEN == 32) begin: ARCH
      localparam VPN_BITS = 20;
      localparam PPN_BITS = 22;
      localparam PA_BITS = 34;

      logic SvMode;
      assign SvMode = SATP[31];  // *** change to an enum somehow?
    end else begin: ARCH
      localparam VPN_BITS = 27;
      localparam PPN_BITS = 44;
      localparam PA_BITS = 56;

      logic SvMode;  // currently just a boolean whether translation enabled
      assign SvMode = SATP[63];  // *** change to an enum somehow?
    end
  endgenerate

  // Index (currently random) to write the next TLB entry
  logic [ENTRY_BITS-1:0] WriteIndex;

  // Sections of the virtual and physical addresses
  logic [ARCH.VPN_BITS-1:0] VirtualPageNumber;
  logic [ARCH.PPN_BITS-1:0] PhysicalPageNumber;
  logic [11:0]              PageOffset;
  logic [ARCH.PA_BITS-1:0]  PhysicalAddressFull;

  // Pattern and pattern location in the CAM
  logic [ENTRY_BITS-1:0] VPNIndex;

  // RAM access location
  logic [ENTRY_BITS-1:0] EntryIndex;

  // Page table entry matching the virtual address
  logic [`XLEN-1:0] PageTableEntry;

  assign VirtualPageNumber = VirtualAddress[ARCH.VPN_BITS+11:12];
  assign PageOffset        = VirtualAddress[11:0];

  // Choose a read or write location to the entry list
  mux2 #(3) indexmux(VPNIndex, WriteIndex, TLBWrite, EntryIndex);

  // Currently use random replacement algorithm
  tlb_rand rdm(.*);

  tlb_ram #(ENTRY_BITS) ram(.*);
  tlb_cam #(ENTRY_BITS, ARCH.VPN_BITS) cam(.*);

  always_comb begin
    assign PhysicalPageNumber = PageTableEntry[ARCH.PPN_BITS+9:10];

    if (TLBHit) begin
      assign PhysicalAddressFull = {PhysicalPageNumber, PageOffset};
    end else begin
      assign PhysicalAddressFull = 8'b0; // *** Actual behavior; disabled until walker functioning
      //assign PhysicalAddressFull = {2'b0, VirtualPageNumber, PageOffset} // *** pass through should be removed as soon as walker ready
    end
  end

  generate
    if (`XLEN == 32) begin
      mux2 #(`XLEN) addressmux(VirtualAddress, PhysicalAddressFull[31:0], ARCH.SvMode, PhysicalAddress);
    end else begin
      mux2 #(`XLEN) addressmux(VirtualAddress, {8'b0, PhysicalAddressFull}, ARCH.SvMode, PhysicalAddress);
    end
  endgenerate

  assign TLBMiss = ~TLBHit & ~(TLBWrite | TLBFlush) & ARCH.SvMode;
endmodule

module tlb_ram #(parameter ENTRY_BITS = 3) (
  input                   clk, reset,
  input  [ENTRY_BITS-1:0] EntryIndex,
  input  [`XLEN-1:0]      PageTableEntryWrite,
  input                   TLBWrite,

  output [`XLEN-1:0]      PageTableEntry
);

  localparam NENTRIES = 2**ENTRY_BITS;

  logic [`XLEN-1:0] ram [0:NENTRIES-1];
  always @(posedge clk) begin
    if (TLBWrite) ram[EntryIndex] <= PageTableEntryWrite;
  end

  assign PageTableEntry = ram[EntryIndex];
    
  initial begin
    for (int i = 0; i < NENTRIES; i++)
      ram[i] = `XLEN'b0;
  end

endmodule

module tlb_cam #(parameter ENTRY_BITS = 3,
                 parameter KEY_BITS   = 20) (
  input                    clk, reset,
  input  [KEY_BITS-1:0]    VirtualPageNumber,
  input  [ENTRY_BITS-1:0]  WriteIndex,
  input                    TLBWrite,
  input                    TLBFlush,
  output [ENTRY_BITS-1:0]  VPNIndex,
  output                   TLBHit
);

  localparam NENTRIES = 2**ENTRY_BITS;

  // Each entry of this memory has KEY_BITS for the key plus one valid bit.
  logic [KEY_BITS:0] ram [0:NENTRIES-1];

  logic [ENTRY_BITS-1:0] matched_address_comb;
  logic                  match_found_comb;

  always @(posedge clk) begin
    if (TLBWrite) ram[WriteIndex] <= {1'b1,VirtualPageNumber};
    if (TLBFlush) begin
      for (int i = 0; i < NENTRIES; i++)
        ram[i][KEY_BITS] = 1'b0;  // Zero out msb (valid bit) of all entries
    end
  end

  // *** Check whether this for loop synthesizes correctly
  always_comb begin
    match_found_comb = 1'b0;
    matched_address_comb = '0;
    for (int i = 0; i < NENTRIES; i++) begin
      if (ram[i] == {1'b1,VirtualPageNumber} && !match_found_comb) begin
        matched_address_comb = i;
        match_found_comb = 1;
      end else begin
        matched_address_comb = matched_address_comb;
        match_found_comb = match_found_comb;
      end
    end
  end

  assign VPNIndex = matched_address_comb;
  assign TLBHit = match_found_comb & ~(TLBWrite | TLBFlush);

  initial begin
    for (int i = 0; i < NENTRIES; i++)
      ram[i] <= '0;
  end

endmodule

module tlb_rand #(parameter ENTRY_BITS = 3) (
  input        clk, reset,
  output [ENTRY_BITS:0] WriteIndex
);

  logic [31:0] data;
  assign data = $urandom;
  assign WriteIndex = data[ENTRY_BITS:0];
  
endmodule

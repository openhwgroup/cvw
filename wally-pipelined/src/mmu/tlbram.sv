///////////////////////////////////////////
// tlbram.sv
//
// Written: jtorrey@hmc.edu & tfleming@hmc.edu 16 February 2021
// Modified:
//
// Purpose: Stores page table entries of cached address translations.
//          Outputs the physical page number and access bits of the current
//          virtual address on a TLB hit.
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

module tlbram #(parameter ENTRY_BITS = 3) (
  input logic                       clk, reset,
  //input logic [ENTRY_BITS-1:0]      VPNIndex,  // Index to read from
//  input logic [ENTRY_BITS-1:0]      WriteIndex, // *** unused?
  input logic [`XLEN-1:0]           PTEWriteVal,
//  input logic                       TLBWrite,
  input logic [2**ENTRY_BITS-1:0]   ReadLines, WriteEnables,

  output logic [`PPN_BITS-1:0]      PhysicalPageNumber,
  output logic [7:0]                PTEAccessBits
);

  localparam NENTRIES = 2**ENTRY_BITS;

  logic [`XLEN-1:0] RamRead[NENTRIES-1:0];
  logic [`XLEN-1:0] PageTableEntry;

  // Generate a flop for every entry in the RAM
  tlbramline #(`XLEN) tlblineram[NENTRIES-1:0](clk, reset, ReadLines, WriteEnables, PTEWriteVal, RamRead);
  
  assign PageTableEntry = RamRead.or; // OR each column of RAM read to read PTE
  assign PTEAccessBits = PageTableEntry[7:0];
  assign PhysicalPageNumber = PageTableEntry[`PPN_BITS+9:10];
endmodule

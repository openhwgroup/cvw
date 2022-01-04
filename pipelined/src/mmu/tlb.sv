///////////////////////////////////////////
// tlb.sv
//
// Written: jtorrey@hmc.edu 16 February 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
//            Implemented SV48 on top of SV39. This included adding the SvMode signal,
//            and using it to decide the translate signal and get the virtual page number
//
// Purpose: Translation lookaside buffer
//          Cache of virtural-to-physical address translations
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

/**
 * SV32 specs
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

`include "wally-config.vh"

// The TLB will have 2**ENTRY_BITS total entries
module tlb #(parameter TLB_ENTRIES = 8,
             parameter ITLB = 0) (
  input logic              clk, reset,

  // Current value of satp CSR (from privileged unit)
  input logic  [`SVMODE_BITS-1:0] SATP_MODE,
  input logic  [`ASID_BITS-1:0] SATP_ASID,
  input logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic  [1:0]       STATUS_MPP,

  // Current privilege level of the processeor
  input logic  [1:0]       PrivilegeModeW,

  // 00 - TLB is not being accessed
  // 1x - TLB is accessed for a read (or an instruction)
  // x1 - TLB is accessed for a write
  // 11 - TLB is accessed for both read and write
  input logic              ReadAccess, WriteAccess,
  input logic              DisableTranslation,

  // address input before translation (could be physical or virtual)
  input logic  [`XLEN-1:0] VAdr,

  // Controls for writing a new entry to the TLB
  input logic  [`XLEN-1:0] PTE,
  input logic  [1:0]       PageTypeWriteVal,
  input logic              TLBWrite,

  // Invalidate all TLB entries
  input logic              TLBFlush,

  // Physical address outputs
  output logic [`PA_BITS-1:0] TLBPAdr,
  output logic             TLBMiss,
  output logic             TLBHit,
  output logic             Translate,

  // Faults
  output logic             TLBPageFault
);

  logic [TLB_ENTRIES-1:0] Matches, WriteEnables, PTE_Gs; // used as the one-hot encoding of WriteIndex

  // Sections of the virtual and physical addresses
  logic [`VPN_BITS-1:0] VPN;
  logic [`PPN_BITS-1:0] PPN;

  // Sections of the page table entry
  logic [7:0]           PTEAccessBits;

  logic [1:0]            HitPageType;
  logic                  CAMHit;
  logic                  SV39Mode;

  logic 				 Misaligned;
  logic 				 MegapageMisaligned;

  // Ross Thompson.  If we are going to write invalid PTEs into the TLB should
  // we cache Misaligned along with the PTE?  This only has to be computed once
  // in the hptw as it is always the same regardless of the VPN.
  if(`XLEN == 32) begin
	assign MegapageMisaligned = |(PPN[9:0]); // must have zero PPN0
	assign Misaligned = (HitPageType == 2'b01) & MegapageMisaligned;
  end else begin
	logic 				 GigapageMisaligned, TerapageMisaligned;
	assign TerapageMisaligned = |(PPN[26:0]); // must have zero PPN2, PPN1, PPN0
	assign GigapageMisaligned = |(PPN[17:0]); // must have zero PPN1 and PPN0
	assign MegapageMisaligned = |(PPN[8:0]); // must have zero PPN0		  
	assign Misaligned = ((HitPageType == 2'b11) & TerapageMisaligned) | 
						((HitPageType == 2'b10) & GigapageMisaligned) | 
						((HitPageType == 2'b01) & MegapageMisaligned);
  end

  assign VPN = VAdr[`VPN_BITS+11:12];

  tlbcontrol #(ITLB) tlbcontrol(.SATP_MODE, .VAdr, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
                        .PrivilegeModeW, .ReadAccess, .WriteAccess, .DisableTranslation, .TLBFlush,
                        .PTEAccessBits, .CAMHit, .Misaligned, .TLBMiss, .TLBHit, .TLBPageFault, 
                        .SV39Mode, .Translate);

  tlblru #(TLB_ENTRIES) lru(.clk, .reset, .TLBWrite, .TLBFlush, .Matches, .CAMHit, .WriteEnables);
  tlbcam #(TLB_ENTRIES, `VPN_BITS + `ASID_BITS, `VPN_SEGMENT_BITS) 
    tlbcam(.clk, .reset, .VPN, .PageTypeWriteVal, .SV39Mode, .TLBFlush, .WriteEnables, .PTE_Gs, 
           .SATP_ASID, .Matches, .HitPageType, .CAMHit);
  tlbram #(TLB_ENTRIES) tlbram(.clk, .reset, .PTE, .Matches, .WriteEnables, .PPN, .PTEAccessBits, .PTE_Gs);

  // Replace segments of the virtual page number with segments of the physical
  // page number. For 4 KB pages, the entire virtual page number is replaced.
  // For superpages, some segments are considered offsets into a larger page.
  tlbmixer Mixer(.VPN, .PPN, .HitPageType, .Offset(VAdr[11:0]), .TLBHit, .TLBPAdr);

endmodule

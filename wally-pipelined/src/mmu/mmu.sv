///////////////////////////////////////////
// mmu.sv
//
// Written: david_harris@hmc.edu and kmacsaigoren@hmc.edu 4 June 2021
// Modified: 
//
// Purpose: Memory management unit, including TLB, PMA, PMP
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

// The TLB will have 2**ENTRY_BITS total entries

module mmu #(parameter IMMU = 0) (
  input              clk, reset,
  // Current value of satp CSR (from privileged unit)
  input  [`XLEN-1:0] SATP_REGW,
  input              STATUS_MXR, STATUS_SUM,

  // Current privilege level of the processeor
  input  [1:0]       PrivilegeModeW,

  // 00 - TLB is not being accessed
  // 1x - TLB is accessed for a read (or an instruction)
  // x1 - TLB is accessed for a write
  // 11 - TLB is accessed for both read and write
  input [1:0]        TLBAccessType,

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
  output             TLBPageFault,

    // PMA checker signals
  input  logic [31:0]      HADDR,
  input  logic [2:0]       HSIZE, HBURST,
  input  logic             HWRITE,
  input  logic             AtomicAccessM, ExecuteAccessF, WriteAccessM, ReadAccessM,
  output logic             Cacheable, Idempotent, AtomicAllowed,
  output logic             SquashBusAccess,
  output logic [5:0]       HSELRegions

);

  // Translation lookaside buffer

  tlb tlb #(.ENTRY_BITS(.ENTRY_BITS), .ITLB(IMMU)) itlb(.*);

  ///////////////////////////////////////////
  // Check physical memory accesses
  ///////////////////////////////////////////

  pmachecker pmachecker(.*);
  pmpchecker pmpchecker(.*);

  *** to edit
  edit PMP/PMA to use phyisical address information instead of HADDR / AHB signals [Later after it works]
  *move PMA checker to MMU from privileged
  *move PMP checker to MMU from privileged
  *delete PMA/PMP signals from priviliged & above no longer needed
  replace TLB with MMU in IFU and DMEM
  adjust for two PMA/PMP outputs (IFU, DMEM) instead of just one for Bus
  Move M_MODE, other constants from each config file to wally-constants, #include wally-constants as needed

endmodule
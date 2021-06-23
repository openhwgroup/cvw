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

module mmu #(parameter ENTRY_BITS = 3,
             parameter IMMU = 0) (

  input logic              clk, reset,
  // Current value of satp CSR (from privileged unit)
  input logic  [`XLEN-1:0] SATP_REGW,
  input logic              STATUS_MXR, STATUS_SUM,

  // Current privilege level of the processeor
  input logic  [1:0]       PrivilegeModeW,

  // 00 - TLB is not being accessed
  // 1x - TLB is accessed for a read (or an instruction)
  // x1 - TLB is accessed for a write
  // 11 - TLB is accessed for both read and write
  input logic [1:0]        TLBAccessType,
  input logic              DisableTranslation,

  // Virtual address input
  input logic  [`XLEN-1:0] VirtualAddress,
  input logic  [1:0]       Size, // 00 = 8 bits, 01 = 16 bits, 10 = 32 bits , 11 = 64 bits

  // Controls for writing a new entry to the TLB
  input logic  [`XLEN-1:0] PTEWriteVal,
  input logic  [1:0]       PageTypeWriteVal,
  input logic              TLBWrite,

  // Invalidate all TLB entries
  input logic              TLBFlush,

  // Physical address outputs
  output logic [`PA_BITS-1:0] PhysicalAddress,
  output logic             TLBMiss,
  output logic             TLBHit,

  // Faults
  output logic             TLBPageFault,

  // PMA checker signals
  input  logic [31:0]      HADDR,
  input  logic [2:0]       HSIZE,
  input  logic             HWRITE,
  input  logic             AtomicAccessM, ExecuteAccessF, WriteAccessM, ReadAccessM,
  input  logic [63:0]      PMPCFG01_REGW, PMPCFG23_REGW, // *** all of these come from the privileged unit, so thwyre gonna have to come over into ifu and dmem
  input  var logic  [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0], 

  output logic             SquashBusAccess, // *** send to privileged unit
  output logic             PMPInstrAccessFaultF, PMPLoadAccessFaultM, PMPStoreAccessFaultM,
  output logic             PMAInstrAccessFaultF, PMALoadAccessFaultM, PMAStoreAccessFaultM,
  output logic [5:0]       HSELRegions

);

  logic PMPSquashBusAccess, PMASquashBusAccess;
  logic Cacheable, Idempotent, AtomicAllowed; // *** here so that the pmachecker has somewhere to put these outputs. *** I'm leaving them as outputs to pma checker, but I'm stopping them here.
  // Translation lookaside buffer

  tlb #(.ENTRY_BITS(ENTRY_BITS), .ITLB(IMMU)) tlb(.*);

  ///////////////////////////////////////////
  // Check physical memory accesses
  ///////////////////////////////////////////

  pmachecker pmachecker(.*);
  pmpchecker pmpchecker(.*);


  assign SquashBusAccess = PMASquashBusAccess || PMPSquashBusAccess;

endmodule

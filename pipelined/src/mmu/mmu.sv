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

module mmu #(parameter TLB_ENTRIES = 8, // number of TLB Entries
             parameter IMMU = 0) (

  input logic                 clk, reset,
  // Current value of satp CSR (from privileged unit)
  input logic [`XLEN-1:0]     SATP_REGW,
  input logic                 STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic [1:0]           STATUS_MPP,

  // Current privilege level of the processeor
  input logic [1:0]           PrivilegeModeW,

  // 00 - TLB is not being accessed
  // 1x - TLB is accessed for a read (or an instruction)
  // x1 - TLB is accessed for a write
  // 11 - TLB is accessed for both read and write
  input logic                 DisableTranslation,

  // VAdr is the virtual/physical address from IEU or physical address from HPTW.
  // PhysicalAddress is selected to be PAdr when no translation or the translated VAdr (TLBPAdr)
  // when there is translation.
  input logic [`XLEN+1:0]     VAdr,
  input logic [1:0]           Size, // 00 = 8 bits, 01 = 16 bits, 10 = 32 bits , 11 = 64 bits

  // Controls for writing a new entry to the TLB
  input logic [`XLEN-1:0]     PTE,
  input logic [1:0]           PageTypeWriteVal,
  input logic                 TLBWrite,

  // Invalidate all TLB entries
  input logic                 TLBFlush,

  // Physical address outputs
  output logic [`PA_BITS-1:0] PhysicalAddress,
  output logic                TLBMiss,
  output logic                Cacheable, Idempotent, AtomicAllowed, SelTIM,

  // Faults
  output logic                InstrAccessFaultF, LoadAccessFaultM, StoreAmoAccessFaultM,
  output logic                InstrPageFaultF, LoadPageFaultM, StoreAmoPageFaultM,
  output logic                DAPageFault,
  output logic                LoadMisalignedFaultM, StoreAmoMisalignedFaultM,

  // PMA checker signals
  input logic                 AtomicAccessM, ExecuteAccessF, WriteAccessM, ReadAccessM,
  input var                   logic [7:0] PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  input var                   logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0]
);

  logic [`PA_BITS-1:0] TLBPAdr;
  // Translation lookaside buffer

  logic PMAInstrAccessFaultF, PMPInstrAccessFaultF;
  logic PMALoadAccessFaultM, PMPLoadAccessFaultM;
  logic PMAStoreAmoAccessFaultM, PMPStoreAmoAccessFaultM;
  logic DataMisalignedM;
  logic Translate;
  logic TLBHit;
  logic TLBPageFault;
  
  // only instantiate TLB if Virtual Memory is supported
  if (`VIRTMEM_SUPPORTED) begin:tlb
    logic ReadAccess, WriteAccess;
    assign ReadAccess = ExecuteAccessF | ReadAccessM; // execute also acts as a TLB read.  Execute and Read are never active for the same MMU, so safe to mix pipestages
    assign WriteAccess = WriteAccessM;
    tlb #(.TLB_ENTRIES(TLB_ENTRIES), .ITLB(IMMU)) 
      tlb(.clk, .reset,
          .SATP_MODE(SATP_REGW[`XLEN-1:`XLEN-`SVMODE_BITS]),
          .SATP_ASID(SATP_REGW[`ASID_BASE+`ASID_BITS-1:`ASID_BASE]),
          .VAdr(VAdr[`XLEN-1:0]), .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
          .PrivilegeModeW, .ReadAccess, .WriteAccess,
          .DisableTranslation, .PTE, .PageTypeWriteVal,
          .TLBWrite, .TLBFlush, .TLBPAdr, .TLBMiss, .TLBHit, 
          .Translate, .TLBPageFault, .DAPageFault);
  end else begin:tlb// just pass address through as physical
    assign Translate = 0;
    assign TLBMiss = 0;
    assign TLBHit = 1; // *** is this necessary
    assign TLBPageFault = 0;
  end

  // If translation is occuring, select translated physical address from TLB
  // the lower 12 bits are the page offset. These are never changed from the orginal
  // non translated address.
  //mux2 #(`PA_BITS) addressmux(PAdr, TLBPAdr, Translate, PhysicalAddress);
  mux2 #(`PA_BITS-12) addressmux(VAdr[`PA_BITS-1:12], TLBPAdr[`PA_BITS-1:12], Translate, PhysicalAddress[`PA_BITS-1:12]);
  assign PhysicalAddress[11:0] = VAdr[11:0];
  
  
  ///////////////////////////////////////////
  // Check physical memory accesses
  ///////////////////////////////////////////

  pmachecker pmachecker(.PhysicalAddress, .Size,
                        .AtomicAccessM, .ExecuteAccessF, .WriteAccessM, .ReadAccessM,
                        .Cacheable, .Idempotent, .AtomicAllowed, .SelTIM,
                        .PMAInstrAccessFaultF, .PMALoadAccessFaultM, .PMAStoreAmoAccessFaultM);
 
  pmpchecker pmpchecker(.PhysicalAddress, .PrivilegeModeW,
                        .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW,
                        .ExecuteAccessF, .WriteAccessM, .ReadAccessM,
                        .PMPInstrAccessFaultF, .PMPLoadAccessFaultM, .PMPStoreAmoAccessFaultM);

  // Access faults
  // If TLB miss and translating we want to not have faults from the PMA and PMP checkers.
  assign InstrAccessFaultF = (PMAInstrAccessFaultF | PMPInstrAccessFaultF) & ~(Translate & ~TLBHit);
  assign LoadAccessFaultM = (PMALoadAccessFaultM | PMPLoadAccessFaultM) & ~(Translate & ~TLBHit);
  assign StoreAmoAccessFaultM = (PMAStoreAmoAccessFaultM | PMPStoreAmoAccessFaultM) & ~(Translate & ~TLBHit);

  // Misaligned faults
   always_comb
    case(Size[1:0]) 
      2'b00:  DataMisalignedM = 0;                 // lb, sb, lbu
      2'b01:  DataMisalignedM = VAdr[0];           // lh, sh, lhu
      2'b10:  DataMisalignedM = VAdr[1] | VAdr[0]; // lw, sw, flw, fsw, lwu
      2'b11:  DataMisalignedM = |VAdr[2:0];        // ld, sd, fld, fsd
    endcase 
  assign LoadMisalignedFaultM = DataMisalignedM & ReadAccessM;
  assign StoreAmoMisalignedFaultM = DataMisalignedM & (WriteAccessM | AtomicAccessM);

  // Specify which type of page fault is occurring
  assign InstrPageFaultF = TLBPageFault & ExecuteAccessF;
  assign LoadPageFaultM = TLBPageFault & ReadAccessM;
  assign StoreAmoPageFaultM = TLBPageFault & (WriteAccessM | AtomicAccessM);
endmodule

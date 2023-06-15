///////////////////////////////////////////
// mmu.sv
//
// Written: david_harris@hmc.edu and kmacsaigoren@hmc.edu 4 June 2021
// Modified: 
//
// Purpose: Memory management unit, including TLB, PMA, PMP
// 
// Documentation: RISC-V System on Chip Design Chapter 8
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module mmu import cvw::*;  #(parameter cvw_t P,
                             parameter TLB_ENTRIES = 8, IMMU = 0) (
  input  logic                 clk, reset,
  input  logic [P.XLEN-1:0]    SATP_REGW,          // Current value of satp CSR (from privileged unit)
  input  logic                 STATUS_MXR,         // Status CSR: make executable page readable
  input  logic                 STATUS_SUM,         // Status CSR: Supervisor access to user memory
  input  logic                 STATUS_MPRV,        // Status CSR: modify machine privilege
  input  logic [1:0]           STATUS_MPP,         // Status CSR: previous machine privilege level
  input  logic [1:0]           PrivilegeModeW,     // Current privilege level of the processeor
  input  logic                 DisableTranslation, // virtual address translation disabled during D$ flush and HPTW walk that use physical addresses
  input  logic [P.XLEN+1:0]    VAdr,               // virtual/physical address from IEU or physical address from HPTW
  input  logic [1:0]           Size,               // access size: 00 = 8 bits, 01 = 16 bits, 10 = 32 bits , 11 = 64 bits
  input  logic [P.XLEN-1:0]    PTE,                // page table entry
  input  logic [1:0]           PageTypeWriteVal,   // page type
  input  logic                 TLBWrite,           // write TLB entry
  input  logic                 TLBFlush,           // Invalidate all TLB entries
  output logic [P.PA_BITS-1:0] PhysicalAddress,    // PAdr when no translation, or translated VAdr (TLBPAdr) when there is translation
  output logic                 TLBMiss,            // Miss TLB
  output logic                 Cacheable,          // PMA indicates memory address is cachable
  output logic                 Idempotent,         // PMA indicates memory address is idempotent
  output logic                 SelTIM,             // Select a tightly integrated memory
  // Faults
  output logic                 InstrAccessFaultF, LoadAccessFaultM, StoreAmoAccessFaultM, // access fault sources
  output logic                 InstrPageFaultF, LoadPageFaultM, StoreAmoPageFaultM,       // page fault sources
  output logic                 UpdateDA,                                                  // page fault due to setting dirty or access bit
  output logic                 LoadMisalignedFaultM, StoreAmoMisalignedFaultM,            // misaligned fault sources
  // PMA checker signals
  input  logic                 AtomicAccessM, ExecuteAccessF, WriteAccessM, ReadAccessM,  // access type
  input var logic [7:0]        PMPCFG_ARRAY_REGW[P.PMP_ENTRIES-1:0],                      // PMP configuration
  input var logic [P.PA_BITS-3:0] PMPADDR_ARRAY_REGW[P.PMP_ENTRIES-1:0]                   // PMP addresses
);

  logic [P.PA_BITS-1:0]        TLBPAdr;                  // physical address for TLB                   
  logic                        PMAInstrAccessFaultF;     // Instruction access fault from PMA
  logic                        PMPInstrAccessFaultF;     // Instruction access fault from PMP
  logic                        PMALoadAccessFaultM;      // Load access fault from PMA
  logic                        PMPLoadAccessFaultM;      // Load access fault from PMP
  logic                        PMAStoreAmoAccessFaultM;  // Store or AMO access fault from PMA
  logic                        PMPStoreAmoAccessFaultM;  // Store or AMO access fault from PMP
  logic                        DataMisalignedM;          // load or store misaligned
  logic                        Translate;                // Translation occurs when virtual memory is active and DisableTranslation is off
  logic                        TLBHit;                   // Hit in TLB
  logic                        TLBPageFault;             // Page fault from TLB
  logic                        ReadNoAmoAccessM;         // Read that is not part of atomic operation causes Load faults.  Otherwise StoreAmo faults
  
  // only instantiate TLB if Virtual Memory is supported
  if (P.VIRTMEM_SUPPORTED) begin:tlb
    logic ReadAccess, WriteAccess;
    assign ReadAccess = ExecuteAccessF | ReadAccessM; // execute also acts as a TLB read.  Execute and Read are never active for the same MMU, so safe to mix pipestages
    assign WriteAccess = WriteAccessM;
    tlb #(.P(P), .TLB_ENTRIES(TLB_ENTRIES), .ITLB(IMMU)) tlb(
          .clk, .reset,
          .SATP_MODE(SATP_REGW[P.XLEN-1:P.XLEN-P.SVMODE_BITS]),
          .SATP_ASID(SATP_REGW[P.ASID_BASE+P.ASID_BITS-1:P.ASID_BASE]),
          .VAdr(VAdr[P.XLEN-1:0]), .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
          .PrivilegeModeW, .ReadAccess, .WriteAccess,
          .DisableTranslation, .PTE, .PageTypeWriteVal,
          .TLBWrite, .TLBFlush, .TLBPAdr, .TLBMiss, .TLBHit, 
          .Translate, .TLBPageFault, .UpdateDA);
  end else begin:tlb // just pass address through as physical
    assign Translate    = 0;
    assign TLBMiss      = 0;
    assign TLBHit       = 1; // *** is this necessary
    assign TLBPageFault = 0;
  end

  // If translation is occuring, select translated physical address from TLB
  // the lower 12 bits are the page offset. These are never changed from the orginal
  // non translated address.
  mux2 #(P.PA_BITS-12) addressmux(VAdr[P.PA_BITS-1:12], TLBPAdr[P.PA_BITS-1:12], Translate, PhysicalAddress[P.PA_BITS-1:12]);
  assign PhysicalAddress[11:0] = VAdr[11:0];
  
  ///////////////////////////////////////////
  // Check physical memory accesses
  ///////////////////////////////////////////

  pmachecker #(P) pmachecker(.PhysicalAddress, .Size,
    .AtomicAccessM, .ExecuteAccessF, .WriteAccessM, .ReadAccessM,
    .Cacheable, .Idempotent, .SelTIM,
    .PMAInstrAccessFaultF, .PMALoadAccessFaultM, .PMAStoreAmoAccessFaultM);
 
  if (P.PMP_ENTRIES > 0) begin : pmp
    pmpchecker #(P) pmpchecker(.PhysicalAddress, .PrivilegeModeW,
      .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW,
      .ExecuteAccessF, .WriteAccessM, .ReadAccessM,
      .PMPInstrAccessFaultF, .PMPLoadAccessFaultM, .PMPStoreAmoAccessFaultM);
  end else begin
    assign PMPInstrAccessFaultF     = 0;
    assign PMPStoreAmoAccessFaultM  = 0;
    assign PMPLoadAccessFaultM      = 0;
  end

  assign ReadNoAmoAccessM = ReadAccessM & ~WriteAccessM;// AMO causes StoreAmo rather than Load fault

  // Access faults
  // If TLB miss and translating we want to not have faults from the PMA and PMP checkers.
  assign InstrAccessFaultF    = (PMAInstrAccessFaultF    | PMPInstrAccessFaultF)    & ~TLBMiss;
  assign LoadAccessFaultM     = (PMALoadAccessFaultM     | PMPLoadAccessFaultM)     & ~TLBMiss;
  assign StoreAmoAccessFaultM = (PMAStoreAmoAccessFaultM | PMPStoreAmoAccessFaultM) & ~TLBMiss;

  // Misaligned faults
   always_comb // exclusion-tag: immu-wordaccess
    case(Size[1:0]) 
      2'b00:  DataMisalignedM = 0;                 // lb, sb, lbu
      2'b01:  DataMisalignedM = VAdr[0];           // lh, sh, lhu
      2'b10:  DataMisalignedM = VAdr[1] | VAdr[0]; // lw, sw, flw, fsw, lwu
      2'b11:  DataMisalignedM = |VAdr[2:0];        // ld, sd, fld, fsd
    endcase 
  assign LoadMisalignedFaultM     = DataMisalignedM & ReadNoAmoAccessM;
  assign StoreAmoMisalignedFaultM = DataMisalignedM & WriteAccessM;

  // Specify which type of page fault is occurring
  assign InstrPageFaultF    = TLBPageFault & ExecuteAccessF;
  assign LoadPageFaultM     = TLBPageFault & ReadNoAmoAccessM; 
  assign StoreAmoPageFaultM = TLBPageFault & WriteAccessM;
endmodule

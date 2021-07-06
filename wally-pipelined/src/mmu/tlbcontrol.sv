///////////////////////////////////////////
// tlbcontrol.sv
//
// Written: David_Harris@hmc.edu 5 July 2021
// Modified: 
//
// Purpose: Control signals for TLB
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
module tlbcontrol #(parameter TLB_ENTRIES = 8,
                    parameter ITLB = 0) (
//  input logic              clk, reset,

  // Current value of satp CSR (from privileged unit)
  input logic  [`XLEN-1:0] SATP_REGW,
  input logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic  [1:0]       STATUS_MPP,
  input logic  [1:0]       PrivilegeModeW, // Current privilege level of the processeor

  // 00 - TLB is not being accessed
  // 1x - TLB is accessed for a read (or an instruction)
  // x1 - TLB is accessed for a write
  // 11 - TLB is accessed for both read and write
  input logic              ReadAccess, WriteAccess,
  input logic              DisableTranslation,
  input logic              TLBFlush, // Invalidate all TLB entries
  input logic [7:0]        PTEAccessBits,
  input logic              CAMHit,
  output logic             TLBMiss,
  output logic             TLBHit,
  output logic             TLBPageFault,
  output logic [1:0]       EffectivePrivilegeMode,
  output logic [`SVMODE_BITS-1:0] SvMode,
  output logic             Translate
);

  // Sections of the page table entry
  logic [11:0]          PageOffset;

  logic PTE_D, PTE_A, PTE_U, PTE_X, PTE_W, PTE_R; // Useful PTE Control Bits
  logic                  DAFault;
  logic                  TLBAccess;

  // Grab the sv mode from SATP and determine whether translation should occur
  assign SvMode = SATP_REGW[`XLEN-1:`XLEN-`SVMODE_BITS];
  assign EffectivePrivilegeMode = (ITLB == 1) ? PrivilegeModeW : (STATUS_MPRV ? STATUS_MPP : PrivilegeModeW); // DTLB uses MPP mode when MPRV is 1
  assign Translate = (SvMode != `NO_TRANSLATE) & (EffectivePrivilegeMode != `M_MODE) & ~ DisableTranslation; 

  // Determine whether TLB is being used
  assign TLBAccess = ReadAccess || WriteAccess;

  // unswizzle useful PTE bits
  assign {PTE_D, PTE_A} = PTEAccessBits[7:6];
  assign {PTE_U, PTE_X, PTE_W, PTE_R} = PTEAccessBits[4:1];
 
  // Check whether the access is allowed, page faulting if not.
  generate
    if (ITLB == 1) begin
      logic ImproperPrivilege;

      // User mode may only execute user mode pages, and supervisor mode may
      // only execute non-user mode pages.
      assign ImproperPrivilege = ((EffectivePrivilegeMode == `U_MODE) && ~PTE_U) ||
        ((EffectivePrivilegeMode == `S_MODE) && PTE_U);
      // fault for software handling if access bit is off
      assign DAFault = ~PTE_A;
      assign TLBPageFault = Translate && TLBHit && (ImproperPrivilege || ~PTE_X || DAFault);
    end else begin
      logic ImproperPrivilege, InvalidRead, InvalidWrite;

      // User mode may only load/store from user mode pages, and supervisor mode
      // may only access user mode pages when STATUS_SUM is low.
      assign ImproperPrivilege = ((EffectivePrivilegeMode == `U_MODE) && ~PTE_U) ||
        ((EffectivePrivilegeMode == `S_MODE) && PTE_U && ~STATUS_SUM);
      // Check for read error. Reads are invalid when the page is not readable
      // (and executable pages are not readable) or when the page is neither
      // readable nor executable (and executable pages are readable).
      assign InvalidRead = ReadAccess && ~PTE_R && (~STATUS_MXR | ~PTE_X);
      // Check for write error. Writes are invalid when the page's write bit is
      // low.
      assign InvalidWrite = WriteAccess && ~PTE_W;
      // Fault for software handling if access bit is off or writing a page with dirty bit off
      assign DAFault = ~PTE_A | WriteAccess & ~PTE_D; 
      assign TLBPageFault = Translate && TLBHit && (ImproperPrivilege || InvalidRead || InvalidWrite || DAFault);
    end
  endgenerate

  assign TLBHit = CAMHit & TLBAccess;
  assign TLBMiss = ~TLBHit & ~TLBFlush & Translate & TLBAccess;
endmodule

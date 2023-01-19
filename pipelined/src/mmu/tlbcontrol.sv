///////////////////////////////////////////
// tlbcontrol.sv
//
// Written: David_Harris@hmc.edu 5 July 2021
// Modified: 
//
// Purpose: Control signals for TLB
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

`include "wally-config.vh"

module tlbcontrol #(parameter ITLB = 0) (
  input  logic [`SVMODE_BITS-1:0] SATP_MODE,
  input  logic [`XLEN-1:0]        VAdr,
  input  logic                    STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input  logic [1:0]              STATUS_MPP,
  input  logic [1:0]              PrivilegeModeW, // Current privilege level of the processeor
  input  logic                    ReadAccess, WriteAccess,
  input  logic                    DisableTranslation,
  input  logic                    TLBFlush, // Invalidate all TLB entries
  input  logic [7:0]              PTEAccessBits,
  input  logic                    CAMHit,
  input  logic                    Misaligned,
  output logic                    TLBMiss,
  output logic                    TLBHit,
  output logic                    TLBPageFault,
  output logic                    DAPageFault,
  output logic                    SV39Mode,
  output logic                    Translate
);

  // Sections of the page table entry
  logic [1:0]                     EffectivePrivilegeMode;

  logic                           PTE_D, PTE_A, PTE_U, PTE_X, PTE_W, PTE_R, PTE_V; // Useful PTE Control Bits
  logic                           UpperBitsUnequalPageFault;
  logic                           TLBAccess;
  logic                           ImproperPrivilege;

  // Grab the sv mode from SATP and determine whether translation should occur
  assign EffectivePrivilegeMode = (ITLB == 1) ? PrivilegeModeW : (STATUS_MPRV ? STATUS_MPP : PrivilegeModeW); // DTLB uses MPP mode when MPRV is 1
  assign Translate = (SATP_MODE != `NO_TRANSLATE) & (EffectivePrivilegeMode != `M_MODE) & ~DisableTranslation; 

  // Determine whether TLB is being used
  assign TLBAccess = ReadAccess | WriteAccess;

  // Check that upper bits are legal (all 0s or all 1s)
  vm64check vm64check(.SATP_MODE, .VAdr, .SV39Mode, .UpperBitsUnequalPageFault);

  // unswizzle useful PTE bits
  assign {PTE_D, PTE_A} = PTEAccessBits[7:6];
  assign {PTE_U, PTE_X, PTE_W, PTE_R, PTE_V} = PTEAccessBits[4:0];
 
  // Check whether the access is allowed, page faulting if not.
  if (ITLB == 1) begin:itlb // Instruction TLB fault checking
    // User mode may only execute user mode pages, and supervisor mode may
    // only execute non-user mode pages.
    assign ImproperPrivilege = ((EffectivePrivilegeMode == `U_MODE) & ~PTE_U) |
      ((EffectivePrivilegeMode == `S_MODE) & PTE_U);
    if(`HPTW_WRITES_SUPPORTED) begin : hptwwrites
      assign DAPageFault = Translate & TLBHit & ~PTE_A & ~TLBPageFault;
      assign TLBPageFault = (Translate  & TLBHit & (ImproperPrivilege | ~PTE_X | UpperBitsUnequalPageFault | Misaligned | ~PTE_V));
    end else begin
      // fault for software handling if access bit is off
      assign DAPageFault = ~PTE_A;
      assign TLBPageFault = (Translate  & TLBHit & (ImproperPrivilege | ~PTE_X | DAPageFault | UpperBitsUnequalPageFault | Misaligned | ~PTE_V));
    end
  end else begin:dtlb // Data TLB fault checking
    logic InvalidRead, InvalidWrite;

    // User mode may only load/store from user mode pages, and supervisor mode
    // may only access user mode pages when STATUS_SUM is low.
    assign ImproperPrivilege = ((EffectivePrivilegeMode == `U_MODE) & ~PTE_U) |
      ((EffectivePrivilegeMode == `S_MODE) & PTE_U & ~STATUS_SUM);
    // Check for read error. Reads are invalid when the page is not readable
    // (and executable pages are not readable) or when the page is neither
    // readable nor executable (and executable pages are readable).
    assign InvalidRead = ReadAccess & ~PTE_R & (~STATUS_MXR | ~PTE_X);
    // Check for write error. Writes are invalid when the page's write bit is
    // low.
    assign InvalidWrite = WriteAccess & ~PTE_W;
    if(`HPTW_WRITES_SUPPORTED) begin : hptwwrites
      assign DAPageFault = Translate & TLBHit & (~PTE_A | WriteAccess & ~PTE_D) & ~TLBPageFault; 
      assign TLBPageFault =  (Translate & TLBHit & (ImproperPrivilege | InvalidRead | InvalidWrite | UpperBitsUnequalPageFault | Misaligned | ~PTE_V));
    end else begin
      // Fault for software handling if access bit is off or writing a page with dirty bit off
      assign DAPageFault = ~PTE_A | WriteAccess & ~PTE_D; 
      assign TLBPageFault = (Translate & TLBHit & (ImproperPrivilege | InvalidRead | InvalidWrite | DAPageFault | UpperBitsUnequalPageFault | Misaligned | ~PTE_V));
    end
  end

  assign TLBHit = CAMHit & TLBAccess;
  assign TLBMiss = (~CAMHit | TLBFlush) & Translate & TLBAccess;
endmodule

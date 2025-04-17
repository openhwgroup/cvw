///////////////////////////////////////////
// pmpchecker.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 28 April 2021
// Modified: 
//
// Purpose: Examines all physical memory accesses and checks them against the
//          current values of the physical memory protection (PMP) registers.
//          Can raise an access fault on illegal reads, writes, and instruction
//          fetches.
// 
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
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

module pmpchecker import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.PA_BITS-1:0]     PhysicalAddress,  
  input  logic [1:0]               EffectivePrivilegeModeW,
  // ModelSim has a switch -svinputport which controls whether input ports
  // are nets (wires) or vars by default. The default setting of this switch is
  // `relaxed`, which means that signals are nets if and only if they are
  // scalars or one-dimensional vectors. Since this is a two-dimensional vector,
  // this will be understood as a var. However, if we don't supply the `var`
  // keyword, the compiler warns us that it's interpreting the signal as a var,
  // which we might not intend.
  input  var logic [7:0]           PMPCFG_ARRAY_REGW[P.PMP_ENTRIES-1:0],
  input  var logic [P.PA_BITS-3:0] PMPADDR_ARRAY_REGW [P.PMP_ENTRIES-1:0],
  input  logic                     ExecuteAccessF, WriteAccessM, ReadAccessM,
  input  logic [1:0]               Size,
  input  logic [3:0]               CMOpM,
  output logic                     PMPInstrAccessFaultF,
  output logic                     PMPLoadAccessFaultM,
  output logic                     PMPStoreAmoAccessFaultM
);

  // Bit i is high when the address falls in PMP region i
  logic                            EnforcePMP; // should PMP be checked in this privilege level
  logic [P.PMP_ENTRIES-1:0]        Match;      // physical address matches one of the pmp ranges
  logic [P.PMP_ENTRIES-1:0]        FirstMatch; // onehot encoding for the first pmpaddr to match the current address.
  logic [P.PMP_ENTRIES-1:0]        L, X, W, R; // PMP matches and has flag set
  logic [P.PMP_ENTRIES-1:0]        PAgePMPAdr; // for TOR PMP matching, PhysicalAddress > PMPAdr[i]
  logic [P.PA_BITS-1:0]            PMPTop[P.PMP_ENTRIES-1:0];     // Upper end of each region, for checking that the access is fully within the region
  logic                            PMPCMOAccessFault, PMPCBOMAccessFault, PMPCBOZAccessFault;
  logic [2:0]                      SizeBytesMinus1;
  logic                            MatchingR, MatchingW, MatchingX, MatchingL;
  logic [P.PA_BITS-1:0]            MatchingPMPTop, PhysicalAddressTop;
  logic                            TooBig;

  if (P.PMP_ENTRIES > 0) begin: pmp // prevent complaints about array of no elements when PMP_ENTRIES = 0
    pmpadrdec #(P) pmpadrdecs[P.PMP_ENTRIES-1:0](
      .PhysicalAddress, 
      .Size,
      .PMPCfg(PMPCFG_ARRAY_REGW),
      .PMPAdr(PMPADDR_ARRAY_REGW),
      .FirstMatch,
      .PAgePMPAdrIn({PAgePMPAdr[P.PMP_ENTRIES-2:0], 1'b1}),
      .PAgePMPAdrOut(PAgePMPAdr),
      .Match, .PMPTop, .L, .X, .W, .R);
  end

  priorityonehot #(P.PMP_ENTRIES) pmppriority(.a(Match), .y(FirstMatch)); // combine the match signal from all the adress decoders to find the first one that matches.

  // Distributed AND-OR mux to select the first matching results
  // If the access does not match all bytes of the PMP region, it is too big and the matches are disabled
  assign MatchingR = |(R & FirstMatch) & ~TooBig;
  assign MatchingW = |(W & FirstMatch) & ~TooBig;
  assign MatchingX = |(X & FirstMatch) & ~TooBig;
  assign MatchingL = |(L & FirstMatch);
  or_rows #(P.PMP_ENTRIES, P.PA_BITS) PTEOr(PMPTop, MatchingPMPTop);

  // Matching PMP entry must match all bytes of an access, or the access fails (Priv Spec 3.7.1.3)
  // First find the size of the access in terms of the offset to the most significant byte
  always_comb
    case (Size)
      2'b00: SizeBytesMinus1 = 3'd0;
      2'b01: SizeBytesMinus1 = 3'd1;
      2'b10: SizeBytesMinus1 = 3'd3;
      2'b11: SizeBytesMinus1 = 3'd7;
    endcase
  // Then find the top of the access and see if it is beyond the top of the region
  assign PhysicalAddressTop = PhysicalAddress + {{P.PA_BITS-3{1'b0}}, SizeBytesMinus1}; // top of the access range
  assign TooBig = PhysicalAddressTop > MatchingPMPTop; // check if the access goes beyond the top of the PMP region

  // Only enforce PMP checking for effective S and U modes (accounting for mstatus.MPRV) or in Machine mode when L bit is set in selected region
  assign EnforcePMP = (EffectivePrivilegeModeW != P.M_MODE) | MatchingL;

  assign PMPCBOMAccessFault     = EnforcePMP & (|CMOpM[2:0]) & ~MatchingR ; // checking R is sufficient because W implies R in PMP  // exclusion-tag: immu-pmpcbom
  assign PMPCBOZAccessFault     = EnforcePMP & CMOpM[3] & ~MatchingW ;          // exclusion-tag: immu-pmpcboz
  assign PMPCMOAccessFault      = PMPCBOZAccessFault | PMPCBOMAccessFault;              // exclusion-tag: immu-pmpcboaccess

  assign PMPInstrAccessFaultF     = EnforcePMP & ExecuteAccessF & ~MatchingX ;
  assign PMPStoreAmoAccessFaultM  = (EnforcePMP & WriteAccessM & ~MatchingW)  | PMPCMOAccessFault; // exclusion-tag: immu-pmpstoreamoaccessfault
  assign PMPLoadAccessFaultM      = EnforcePMP & ReadAccessM & ~WriteAccessM & ~MatchingR;
 endmodule

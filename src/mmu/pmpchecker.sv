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
  input  var logic [P.PA_BITS-3:0] PMPADDR_ARRAY_REGW[P.PMP_ENTRIES-1:0],
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
  logic                            PMPCMOAccessFault, PMPCBOMAccessFault, PMPCBOZAccessFault;
  logic [2:0]                      SizeBytesMinus1;
  logic                            MatchingR, MatchingW, MatchingX, MatchingL;

  // Signals for end-of-access PMP boundary crossing detection
  logic [P.PA_BITS-1:0]            EndAddress;       // last byte address of the access
  logic [P.PMP_ENTRIES-1:0]        EndMatch;         // end address matches PMP region i
  logic [P.PMP_ENTRIES-1:0]        EndFirstMatch;    // first matching region for end address
  logic [P.PMP_ENTRIES-1:0]        EndL, EndX, EndW, EndR; // end address permission bits
  logic [P.PMP_ENTRIES-1:0]        EndPAgePMPAdr;    // TOR chain for end address
  logic                            EndMatchingR, EndMatchingW; // end address permitted for R/W
  logic                            PMPBoundaryLoadFault, PMPBoundaryStoreFault;


  if (P.PMP_ENTRIES > 0) begin : pmp // prevent complaints about array of no elements when PMP_ENTRIES = 0
    pmpadrdec #(P) pmpadrdecs[P.PMP_ENTRIES-1:0](
      .PhysicalAddress,
      .Size,
      .PMPCfg(PMPCFG_ARRAY_REGW),
      .PMPAdr(PMPADDR_ARRAY_REGW),
      .FirstMatch,
      .PAgePMPAdrIn({PAgePMPAdr[P.PMP_ENTRIES-2:0], 1'b1}),
      .PAgePMPAdrOut(PAgePMPAdr),
      .Match, .L, .X, .W, .R);

    // Check PMP permissions at the last byte of multi-byte accesses to detect boundary crossings
    assign SizeBytesMinus1 = (2**Size) - 1;
    assign EndAddress = PhysicalAddress + {{(P.PA_BITS-3){1'b0}}, SizeBytesMinus1};

    pmpadrdec #(P) pmpadrdecs_end[P.PMP_ENTRIES-1:0](
      .PhysicalAddress(EndAddress),
      .Size(2'b00),
      .PMPCfg(PMPCFG_ARRAY_REGW),
      .PMPAdr(PMPADDR_ARRAY_REGW),
      .FirstMatch(1'b0),
      .PAgePMPAdrIn({EndPAgePMPAdr[P.PMP_ENTRIES-2:0], 1'b1}),
      .PAgePMPAdrOut(EndPAgePMPAdr),
      .Match(EndMatch), .L(EndL), .X(EndX), .W(EndW), .R(EndR));
  end

  priorityonehot #(P.PMP_ENTRIES) pmppriority(.a(Match), .y(FirstMatch)); // combine the match signal from all the address decoders to find the first one that matches.

  // Distributed AND-OR mux to select the first matching results
  assign MatchingR = |(R & FirstMatch);
  assign MatchingW = |(W & FirstMatch);
  assign MatchingX = |(X & FirstMatch);
  assign MatchingL = |(L & FirstMatch);

  // Only enforce PMP checking for effective S and U modes (accounting for mstatus.MPRV) or in Machine mode when L bit is set in selected region
  assign EnforcePMP = (EffectivePrivilegeModeW != P.M_MODE) | MatchingL;

  // Check end-of-access PMP permissions for boundary crossing detection
  // When multi-byte access spans multiple PMP regions, all bytes must be permitted
  priorityonehot #(P.PMP_ENTRIES) pmppriority_end(.a(EndMatch), .y(EndFirstMatch));
  assign EndMatchingR = |(EndR & EndFirstMatch);
  assign EndMatchingW = |(EndW & EndFirstMatch);

  // Boundary crossing fault: access start and end match different PMP regions, and
  // the end address falls in a region (or unprotected area) that doesn't permit the access
  assign PMPBoundaryLoadFault  = EnforcePMP & ReadAccessM  & ~WriteAccessM & ~EndMatchingR & (FirstMatch != EndFirstMatch);
  assign PMPBoundaryStoreFault = EnforcePMP & WriteAccessM & ~EndMatchingW & (FirstMatch != EndFirstMatch);

  assign PMPCBOMAccessFault     = EnforcePMP & (|CMOpM[2:0]) & ~MatchingR ; // checking R is sufficient because W implies R in PMP  // exclusion-tag: immu-pmpcbom
  assign PMPCBOZAccessFault     = EnforcePMP & CMOpM[3] & ~MatchingW ;          // exclusion-tag: immu-pmpcboz
  assign PMPCMOAccessFault      = PMPCBOZAccessFault | PMPCBOMAccessFault;              // exclusion-tag: immu-pmpcboaccess

  assign PMPInstrAccessFaultF     = EnforcePMP & ExecuteAccessF & ~MatchingX ;
  assign PMPStoreAmoAccessFaultM  = (EnforcePMP & WriteAccessM & ~MatchingW)  | PMPCMOAccessFault | PMPBoundaryStoreFault; // exclusion-tag: immu-pmpstoreamoaccessfault
  assign PMPLoadAccessFaultM      = (EnforcePMP & ReadAccessM & ~WriteAccessM & ~MatchingR) | PMPBoundaryLoadFault;
 endmodule

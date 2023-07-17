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

module pmpchecker import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.PA_BITS-1:0]     PhysicalAddress,  
  input  logic [1:0]               PrivilegeModeW,
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

  if (P.PMP_ENTRIES > 0) begin: pmp // prevent complaints about array of no elements when PMP_ENTRIES = 0
    pmpadrdec #(P) pmpadrdecs[P.PMP_ENTRIES-1:0](
      .PhysicalAddress, 
      .PMPCfg(PMPCFG_ARRAY_REGW),
      .PMPAdr(PMPADDR_ARRAY_REGW),
      .PAgePMPAdrIn({PAgePMPAdr[P.PMP_ENTRIES-2:0], 1'b1}),
      .PAgePMPAdrOut(PAgePMPAdr),
      .Match, .L, .X, .W, .R);
  end

  priorityonehot #(P.PMP_ENTRIES) pmppriority(.a(Match), .y(FirstMatch)); // combine the match signal from all the adress decoders to find the first one that matches.

  // Only enforce PMP checking for S and U modes or in Machine mode when L bit is set in selected region
  assign EnforcePMP = (PrivilegeModeW != P.M_MODE) | (|(L & FirstMatch)); // *** switch to this logic when PMP is initialized for non-machine mode

  assign PMPInstrAccessFaultF     = EnforcePMP & ExecuteAccessF & ~|(X & FirstMatch) ;
  assign PMPStoreAmoAccessFaultM  = EnforcePMP & WriteAccessM   & ~|(W & FirstMatch) ;
  assign PMPLoadAccessFaultM      = EnforcePMP & ReadAccessM    & ~|(R & FirstMatch) ;
 endmodule

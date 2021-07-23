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

module pmpchecker (
  input  logic [`PA_BITS-1:0]      PhysicalAddress,  
  input  logic [1:0]               PrivilegeModeW,

  // *** ModelSim has a switch -svinputport which controls whether input ports
  // are nets (wires) or vars by default. The default setting of this switch is
  // `relaxed`, which means that signals are nets if and only if they are
  // scalars or one-dimensional vectors. Since this is a two-dimensional vector,
  // this will be understood as a var. However, if we don't supply the `var`
  // keyword, the compiler warns us that it's interpreting the signal as a var,
  // which we might not intend.
  input  var logic [7:0]   PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  input  var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0],

  input  logic             ExecuteAccessF, WriteAccessM, ReadAccessM,

  output logic             PMPSquashBusAccess,

  output logic             PMPInstrAccessFaultF,
  output logic             PMPLoadAccessFaultM,
  output logic             PMPStoreAccessFaultM
);


  // Bit i is high when the address falls in PMP region i
  logic                    EnforcePMP;
  logic [7:0]              PMPCfg[`PMP_ENTRIES-1:0];
  logic [`PMP_ENTRIES-1:0] Match, FirstMatch;      // PMP Entry matches
  logic [`PMP_ENTRIES-1:0] Active;     // PMP register i is non-null
  logic [`PMP_ENTRIES-1:0] L, X, W, R; // PMP matches and has flag set
  logic [`PMP_ENTRIES-1:0]   PAgePMPAdr;  // for TOR PMP matching, PhysicalAddress > PMPAdr[i]
  genvar i,j;

  pmpadrdec pmpadrdecs[`PMP_ENTRIES-1:0](
    .PhysicalAddress, 
    .PMPCfg(PMPCFG_ARRAY_REGW),
    .PMPAdr(PMPADDR_ARRAY_REGW),
    .PAgePMPAdrIn({PAgePMPAdr[`PMP_ENTRIES-2:0], 1'b1}),
    .PAgePMPAdrOut(PAgePMPAdr),
    .FirstMatch, .Match, .Active, .L, .X, .W, .R);

  priorityonehot #(`PMP_ENTRIES) pmppriority(.a(Match), .y(FirstMatch)); // Take the ripple gates/signals out of the pmpadrdec and into another unit.

  // Only enforce PMP checking for S and U modes when at least one PMP is active or in Machine mode when L bit is set in selected region
  assign EnforcePMP = (PrivilegeModeW == `M_MODE) ? |L : |Active; 

  assign PMPInstrAccessFaultF = EnforcePMP && ExecuteAccessF && ~|X;
  assign PMPStoreAccessFaultM = EnforcePMP && WriteAccessM   && ~|W;
  assign PMPLoadAccessFaultM  = EnforcePMP && ReadAccessM    && ~|R;

  assign PMPSquashBusAccess = PMPInstrAccessFaultF | PMPLoadAccessFaultM | PMPStoreAccessFaultM;

endmodule

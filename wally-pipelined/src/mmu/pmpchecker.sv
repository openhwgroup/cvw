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
  input  var logic [63:0]      PMPCFG_ARRAY_REGW[`PMP_ENTRIES/8-1:0],
  input  var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0],

  input  logic             ExecuteAccessF, WriteAccessM, ReadAccessM,

  output logic             PMPSquashBusAccess,

  output logic             PMPInstrAccessFaultF,
  output logic             PMPLoadAccessFaultM,
  output logic             PMPStoreAccessFaultM
);

  // Bit i is high when the address falls in PMP region i
  logic [`PMP_ENTRIES-1:0] Regions, FirstMatch;
  logic        EnforcePMP;

  logic [7:0] PMPCFG [`PMP_ENTRIES-1:0];

  // Bit i is high when the address is greater than or equal to PMPADR[i]
  // Used for determining whether TOR PMP regions match
  logic [`PMP_ENTRIES-1:0] AboveRegion;

  // Bit i is high if PMP register i is non-null
  logic [`PMP_ENTRIES-1:0] ActiveRegion;

  logic [`PMP_ENTRIES-1:0] L_Bits, X_Bits, W_Bits, R_Bits;

  genvar i,j;

  pmpadrdec pmpadrdec(.PhysicalAddress(PhysicalAddress), 
                      .AdrMode(PMPCFG[0][4:3]),
                      .CurrentPMPAdr(PMPADDR_ARRAY_REGW[0]),
                      .AdrAtLeastPreviousPMP(1'b1),
                      .AdrAtLeastCurrentPMP(AboveRegion[0]),
                      .Match(Regions[0]));

  assign ActiveRegion[0] = |PMPCFG[0][4:3];

  generate // *** only for PMP_ENTRIES > 0
    for (i = 1; i < `PMP_ENTRIES; i++) begin
      pmpadrdec pmpadrdec(.PhysicalAddress(PhysicalAddress), 
                          .AdrMode(PMPCFG[i][4:3]),
                          .CurrentPMPAdr(PMPADDR_ARRAY_REGW[i]),
                          .AdrAtLeastPreviousPMP(AboveRegion[i-1]),
                          .AdrAtLeastCurrentPMP(AboveRegion[i]),
                          .Match(Regions[i]));
      
      assign ActiveRegion[i] = |PMPCFG[i][4:3];
    end
  endgenerate

  // verilator lint_off UNOPTFLAT
  logic [`PMP_ENTRIES-1:0] NoLowerMatch;
  generate
    // verilator lint_off WIDTH
    for (j=0; j<`PMP_ENTRIES; j = j+8) begin
      assign {PMPCFG[j+7], PMPCFG[j+6], PMPCFG[j+5], PMPCFG[j+4],
              PMPCFG[j+3], PMPCFG[j+2], PMPCFG[j+1], PMPCFG[j]} = PMPCFG_ARRAY_REGW[j/8];
    end
    // verilator lint_on WIDTH
    for (i=0; i<`PMP_ENTRIES; i++) begin
      if (i==0) begin
	 assign FirstMatch[i] = Regions[i];
	assign NoLowerMatch[i] = ~Regions[i];
      end else begin
	 assign FirstMatch[i] = Regions[i] & NoLowerMatch[i];
	assign NoLowerMatch[i] = NoLowerMatch[i-1] & ~Regions[i];
      end
      assign L_Bits[i] = PMPCFG[i][7] & FirstMatch[i];
      assign X_Bits[i] = PMPCFG[i][2] & FirstMatch[i];
      assign W_Bits[i] = PMPCFG[i][1] & FirstMatch[i];
      assign R_Bits[i] = PMPCFG[i][0] & FirstMatch[i];
    end
    // verilator lint_on UNOPTFLAT
  endgenerate

  // Only enforce PMP checking for S and U modes when at least one PMP is active or in Machine mode when L bit is set in selected region
  assign EnforcePMP = (PrivilegeModeW == `M_MODE) ? |L_Bits : |ActiveRegion;

  assign PMPInstrAccessFaultF = EnforcePMP && ExecuteAccessF && ~|X_Bits;
  assign PMPStoreAccessFaultM = EnforcePMP && WriteAccessM   && ~|W_Bits;
  assign PMPLoadAccessFaultM  = EnforcePMP && ReadAccessM    && ~|R_Bits;

  assign PMPSquashBusAccess = PMPInstrAccessFaultF | PMPLoadAccessFaultM | PMPStoreAccessFaultM;

endmodule

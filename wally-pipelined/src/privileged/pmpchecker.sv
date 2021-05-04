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
  input  logic             clk, reset,

  input  logic [31:0]      HADDR,

  input  logic [1:0]       PrivilegeModeW,

  input  logic [1:0]       STATUS_MPP,
  input  logic             STATUS_MPRV,

  input  logic [63:0]      PMPCFG01_REGW, PMPCFG23_REGW,

  input  logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [0:15],

  input  logic             ExecuteAccessF, WriteAccessM, ReadAccessM,

  output logic             PMPSquashBusAccess,

  output logic             PMPInstrAccessFaultF,
  output logic             PMPLoadAccessFaultM,
  output logic             PMPStoreAccessFaultM
);

  // Bit i is high when the address falls in PMP region i
  logic [15:0] Regions;
  logic [3:0]  MatchedRegion;
  logic        Match, EnforcePMP;

  logic [7:0] PMPCFG [0:15];

  // Bit i is high when the address is greater than or equal to PMPADR[i]
  // Used for determining whether TOR PMP regions match
  logic [15:0] AboveRegion;

  // Bit i is high if PMP register i is non-null
  logic [15:0] ActiveRegion;

  logic L_Bit, X_Bit, W_Bit, R_Bit;
  logic InvalidExecute, InvalidWrite, InvalidRead;

  assign {PMPCFG[15], PMPCFG[14], PMPCFG[13], PMPCFG[12],
          PMPCFG[11], PMPCFG[10], PMPCFG[9], PMPCFG[8]} = PMPCFG23_REGW;

  assign {PMPCFG[7], PMPCFG[6], PMPCFG[5], PMPCFG[4],
          PMPCFG[3], PMPCFG[2], PMPCFG[1], PMPCFG[0]} = PMPCFG01_REGW;

  pmpadrdec pmpadrdec(.HADDR(HADDR), .AdrMode(PMPCFG[0][4:3]),
                      .CurrentPMPAdr(PMPADDR_ARRAY_REGW[0]),
                      .AdrAtLeastPreviousPMP(1'b1),
                      .AdrAtLeastCurrentPMP(AboveRegion[0]),
                      .Match(Regions[0]));
  assign ActiveRegion[0] = |PMPCFG[0][4:3];

  generate
    genvar i;
    for (i = 1; i < 16; i++) begin
      pmpadrdec pmpadrdec(.HADDR(HADDR), .AdrMode(PMPCFG[i][4:3]),
                          .CurrentPMPAdr(PMPADDR_ARRAY_REGW[i]),
                          .AdrAtLeastPreviousPMP(AboveRegion[i-1]),
                          .AdrAtLeastCurrentPMP(AboveRegion[i]),
                          .Match(Regions[i]));
      
      assign ActiveRegion[i] = |PMPCFG[i][4:3];
    end
  endgenerate

  assign Match = |Regions;

  // Only enforce PMP checking for S and U modes when at least one PMP is active
  assign EnforcePMP = |ActiveRegion;

  always_comb
    casez (Regions)
      16'b???????????????1: MatchedRegion = 0;
      16'b??????????????10: MatchedRegion = 1;
      16'b?????????????100: MatchedRegion = 2;
      16'b????????????1000: MatchedRegion = 3;
      16'b???????????10000: MatchedRegion = 4;
      16'b??????????100000: MatchedRegion = 5;
      16'b?????????1000000: MatchedRegion = 6;
      16'b????????10000000: MatchedRegion = 7;
      16'b???????100000000: MatchedRegion = 8;
      16'b??????1000000000: MatchedRegion = 9;
      16'b?????10000000000: MatchedRegion = 10;
      16'b????100000000000: MatchedRegion = 11;
      16'b???1000000000000: MatchedRegion = 12;
      16'b??10000000000000: MatchedRegion = 13;
      16'b?100000000000000: MatchedRegion = 14;
      16'b1000000000000000: MatchedRegion = 15;
      default:              MatchedRegion = 0; // Should only occur if there is no match
    endcase

  assign L_Bit = PMPCFG[MatchedRegion][7] && Match;
  assign X_Bit = PMPCFG[MatchedRegion][2] && Match;
  assign W_Bit = PMPCFG[MatchedRegion][1] && Match;
  assign R_Bit = PMPCFG[MatchedRegion][0] && Match;

  assign InvalidExecute = ExecuteAccessF && ~X_Bit;
  assign InvalidWrite   = WriteAccessM   && ~W_Bit;
  assign InvalidRead    = ReadAccessM    && ~R_Bit;

  assign PMPInstrAccessFaultF = (PrivilegeModeW == `M_MODE) ?
                                  Match && L_Bit && InvalidExecute :
                                  EnforcePMP && InvalidExecute;
  assign PMPStoreAccessFaultM = (PrivilegeModeW == `M_MODE) ?
                                  Match && L_Bit && InvalidWrite :
                                  EnforcePMP && InvalidWrite;
  assign PMPLoadAccessFaultM  = (PrivilegeModeW == `M_MODE) ?
                                  Match && L_Bit && InvalidRead :
                                  EnforcePMP && InvalidRead;

/*
  assign PMPInstrAccessFaultF = 1'b0;
  assign PMPStoreAccessFaultM = 1'b0;
  assign PMPLoadAccessFaultM  =  1'b0;
*/

  /*
  If no PMP entry matches an M-mode access, the access succeeds. If no PMP entry matches an
S-mode or U-mode access, but at least one PMP entry is implemented, the access fails.
*/

  assign PMPSquashBusAccess = PMPInstrAccessFaultF || PMPLoadAccessFaultM || PMPStoreAccessFaultM;

endmodule

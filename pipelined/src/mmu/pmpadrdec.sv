///////////////////////////////////////////
// pmpadrdec.sv
//
// Written: tfleming@hmc.edu 28 April 2021
// Modified: 
//
// Purpose: Address decoder for the PMP checker. Decides whether a given address
//          falls within the PMP range for each address-matching mode
//          (top-of-range/TOR, naturally aligned four-byte region/NA4, and
//          naturally aligned power-of-two region/NAPOT), then selects the
//          output based on which mode is input.
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

module pmpadrdec (
  input  logic [`PA_BITS-1:0]      PhysicalAddress,
  input  logic [7:0]       PMPCfg,
  input  logic [`XLEN-1:0] PMPAdr,
  input  logic             PAgePMPAdrIn,
  input  logic             FirstMatch,
  output logic             PAgePMPAdrOut,
  output logic             Match, Active, 
  output logic             L, X, W, R
);
      
  localparam TOR   = 2'b01;
  localparam NA4   = 2'b10;
  localparam NAPOT = 2'b11;

  logic TORMatch, NAMatch;
  logic PAltPMPAdr;
  logic [`PA_BITS-1:0] CurrentAdrFull;
  logic [1:0] AdrMode;


  assign AdrMode = PMPCfg[4:3];

  // The two lsb of the physical address don't matter for this checking.
  // The following code includes them, but hardwires the PMP checker lsbs to 00
  // and masks them later.  Logic synthesis should optimize away these bottom bits.
 
  // Top-of-range (TOR)
  // Append two implicit trailing 0's to PMPAdr value
  assign CurrentAdrFull  = {PMPAdr[`PA_BITS-3:0],  2'b00};
  assign PAltPMPAdr = {1'b0, PhysicalAddress} < {1'b0, CurrentAdrFull}; // unsigned comparison
  assign PAgePMPAdrOut = ~PAltPMPAdr;
  assign TORMatch = PAgePMPAdrIn & PAltPMPAdr;

  // Naturally aligned regions
  logic [`PA_BITS-1:0] NAMask, NABase;

  assign NAMask[1:0] = {2'b11};
  assign NAMask[`PA_BITS-1:2] = (PMPAdr[`PA_BITS-3:0] + {{(`PA_BITS-3){1'b0}}, (AdrMode == NAPOT)}) ^ PMPAdr[`PA_BITS-3:0];
  // generates a mask where the bottom k bits are 1, corresponding to a size of 2^k bytes for this memory region. 
  // This assumes we're using at least an NA4 region, but works for any size NAPOT region.
  assign NABase = {(PMPAdr[`PA_BITS-3:0] & ~NAMask[`PA_BITS-1:2]), 2'b00}; // base physical address of the pmp. 
  
  assign NAMatch = &((NABase ~^ PhysicalAddress) | NAMask); // check if upper bits of base address match, ignore lower bits correspoonding to inside the memory range

  assign Match = (AdrMode == TOR) ? TORMatch : 
                 (AdrMode == NA4 | AdrMode == NAPOT) ? NAMatch :
                 0;

  assign L = PMPCfg[7] & FirstMatch;
  assign X = PMPCfg[2] & FirstMatch;
  assign W = PMPCfg[1] & FirstMatch;
  assign R = PMPCfg[0] & FirstMatch;
  assign Active = |PMPCfg[4:3];
 endmodule


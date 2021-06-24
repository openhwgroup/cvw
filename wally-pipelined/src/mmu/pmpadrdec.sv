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
//  input  logic [31:0]      HADDR, // *** replace with PAdr
  input  logic [1:0]       AdrMode,
  input  logic [`XLEN-1:0] CurrentPMPAdr,
  input  logic             AdrAtLeastPreviousPMP,
  output logic             AdrAtLeastCurrentPMP,
  output logic             Match
);

  localparam TOR   = 2'b01;
  localparam NA4   = 2'b10;
  localparam NAPOT = 2'b11;

  logic TORMatch, NAMatch;
  logic AdrBelowCurrentPMP;
  logic [`PA_BITS-1:0] CurrentAdrFull;
//  logic [`PA_BITS-1:0] FakePhysAdr; 

  // ***replace this when the true physical address from MMU is available
//  assign FakePhysAdr = {{(`PA_BITS-32){1'b0}}, HADDR};
 
  // Top-of-range (TOR)
  // Append two implicit trailing 0's to PMPAdr value
  assign CurrentAdrFull  = {CurrentPMPAdr[`PA_BITS-3:0],  2'b00};
  assign AdrBelowCurrentPMP = PhysicalAddress < CurrentAdrFull; // *** make sure unsigned comparison works correctly
  assign AdrAtLeastCurrentPMP = ~AdrBelowCurrentPMP;
  assign TORMatch = AdrAtLeastPreviousPMP && AdrBelowCurrentPMP;

  // Naturally aligned regions
  // *** should be able to optimize away bottom 2 bits

  // verilator lint_off UNOPTFLAT
  logic [`PA_BITS-1:0] Mask;
  genvar i;
  
  // create a mask of which bits to ignore
  generate
    assign Mask[1:0] = 2'b11;
    assign Mask[2] = (AdrMode == NAPOT); // mask has 0s in upper bis for NA4 region
    for (i=3; i < `PA_BITS; i=i+1) 
      assign Mask[i] = Mask[i-1] & CurrentPMPAdr[i-3]; // NAPOT mask: 1's indicate bits to ignore
   endgenerate
  // verilator lint_on UNOPTFLAT

  assign NAMatch = &((PhysicalAddress ~^ CurrentAdrFull) | Mask);

 /* generate
    if (`XLEN == 32 || `XLEN == 64) begin // ***redo for various sizes
      // priority encoder to translate address to range
      // *** We'd like to replace this with a better priority encoder
      // *** We should not be truncating 64 bit physical addresses to 32 bits...
      // *** there is an easy combinatinoal way to do this with a cascade of AND gates O(32) rather than O(32^2) dh
      always_comb
        if (AdrMode == NA4) Range = (2**2) - 1;
        else casez (CurrentPMPAdr[31:0]) // NAPOT regions
          32'b???????????????????????????????0: Range = (2**3)  - 1;
          32'b??????????????????????????????01: Range = (2**4)  - 1;
          32'b?????????????????????????????011: Range = (2**5)  - 1;
          32'b????????????????????????????0111: Range = (2**6)  - 1;
          32'b???????????????????????????01111: Range = (2**7)  - 1;
          32'b??????????????????????????011111: Range = (2**8)  - 1;
          32'b?????????????????????????0111111: Range = (2**9)  - 1;
          32'b????????????????????????01111111: Range = (2**10) - 1;
          32'b???????????????????????011111111: Range = (2**11) - 1;
          32'b??????????????????????0111111111: Range = (2**12) - 1;
          32'b?????????????????????01111111111: Range = (2**13) - 1;
          32'b????????????????????011111111111: Range = (2**14) - 1;
          32'b???????????????????0111111111111: Range = (2**15) - 1;
          32'b??????????????????01111111111111: Range = (2**16) - 1;
          32'b?????????????????011111111111111: Range = (2**17) - 1;
          32'b????????????????0111111111111111: Range = (2**18) - 1;
          32'b???????????????01111111111111111: Range = (2**19) - 1;
          32'b??????????????011111111111111111: Range = (2**20) - 1;
          32'b?????????????0111111111111111111: Range = (2**21) - 1;
          32'b????????????01111111111111111111: Range = (2**22) - 1;
          32'b???????????011111111111111111111: Range = (2**23) - 1;
          32'b??????????0111111111111111111111: Range = (2**24) - 1;
          32'b?????????01111111111111111111111: Range = (2**25) - 1;
          32'b????????011111111111111111111111: Range = (2**26) - 1;
          32'b???????0111111111111111111111111: Range = (2**27) - 1;
          32'b??????01111111111111111111111111: Range = (2**28) - 1;
          32'b?????011111111111111111111111111: Range = (2**29) - 1;
          32'b????0111111111111111111111111111: Range = (2**30) - 1;
          32'b???01111111111111111111111111111: Range = (2**31) - 1;
          32'b??011111111111111111111111111111: Range = (2**32) - 1;
          32'b?0111111111111111111111111111111: Range = (2**33) - 1;
          32'b01111111111111111111111111111111: Range = (2**34) - 1;
          32'b11111111111111111111111111111111: Range = (2**35) - 1;
          default:                              Range = '0;
        endcase
    end else begin
      assign Range = '0;
    end
  endgenerate 

  // *** Range should not be truncated... but our physical address space is
  // currently only 32 bits wide.
  // with a bit of combining of range selection,  this could be shared with NA4Match ***
   assign NAMatch = &((HADDR ~^ CurrentAdrFull) | Range[31:0]);*/

  assign Match = (AdrMode == TOR) ? TORMatch : 
                 (AdrMode == NA4 || AdrMode == NAPOT) ? NAMatch :
                 0;

endmodule


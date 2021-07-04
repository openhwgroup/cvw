///////////////////////////////////////////
// tlbphysicalpagemask.sv
//
// Written: David Harris and kmacsaigoren@hmc.edu 7 June 2021
// Modified:
// 
//
// Purpose: Takes two page numbers and replaces segments of the first page
//          number with segments from the second, based on the page type.
//          NOTE: this DOES NOT include the 12 bit offset, which is the same no matter the translation mode or page type.
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

module physicalpagemask (
    input logic [`VPN_BITS-1:0]    VPN,
    input logic [`PPN_BITS-1:0]    PPN,
    input logic [1:0]              PageType,

    output logic [`PPN_BITS-1:0]   MixedPageNumber 
);

  localparam EXTRA_BITS = `PPN_BITS - `VPN_BITS;
  logic [`PPN_BITS-1:0] ZeroExtendedVPN;
  logic [`PPN_BITS-1:0] PageNumberMask;

  generate
    if (`XLEN == 32) begin
      always_comb 
        case (PageType[0])
          // the widths of these constansts are hardocded here to match `PPN_BITS in the wally-constants file.
          0: PageNumberMask = 22'h3FFFFF; // kilopage: 22 bits of PPN, 0 bits of VPN
          1: PageNumberMask = 22'h3FFC00; // megapage: 12 bits of PPN, 10 bits of VPN
        endcase
    end else begin
      always_comb 
        case (PageType[1:0])
          0: PageNumberMask = 44'hFFFFFFFFFFF; // kilopage: 44 bits of PPN, 0 bits of VPN
          1: PageNumberMask = 44'hFFFFFFFFE00; // megapage: 35 bits of PPN, 9 bits of VPN
          2: PageNumberMask = 44'hFFFFFFC0000; // gigapage: 26 bits of PPN, 18 bits of VPN
          3: PageNumberMask = 44'hFFFF8000000; // terapage: 17 bits of PPN, 27 bits of VPN
          //     Bus widths accomodate SV48. In SV39, all of these
          //     busses are the widths for sv48, but extra bits should be zeroed out by the mux
          //     in the tlb when it generates VPN from the full virtualadress.
        endcase
    end
  endgenerate

  // merge low segments of VPN with high segments of PPN decided by the pagetype.
  assign ZeroExtendedVPN = {{EXTRA_BITS{1'b0}}, VPN}; // forces the VPN to be the same width as PPN.
  assign MixedPageNumber = (ZeroExtendedVPN & ~PageNumberMask) | (PPN & PageNumberMask);

endmodule

///////////////////////////////////////////
// tlbmixer.sv
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
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module tlbmixer (
    input  logic [`VPN_BITS-1:0]   VPN,
    input  logic [`PPN_BITS-1:0]   PPN,
    input  logic [1:0]             HitPageType,
    input  logic [11:0]            Offset,
    input  logic                   TLBHit,
    output logic [`PA_BITS-1:0]    TLBPAdr
);

  localparam EXTRA_BITS = `PPN_BITS - `VPN_BITS;
  logic [`PPN_BITS-1:0] ZeroExtendedVPN;
  logic [`PPN_BITS-1:0] PageNumberMask;
  logic [`PPN_BITS-1:0] PPNMixed;

  // produce PageNumberMask with 1s where virtual page number bits should be untranslaetd for superpages
  if (`XLEN == 32)
    // kilopage: 22 bits of PPN, 0 bits of VPN
    // megapage: 12 bits of PPN, 10 bits of VPN
    mux2 #(22) pnm(22'h000000, 22'h0003FF, HitPageType[0], PageNumberMask);
  else
    // kilopage: 44 bits of PPN, 0 bits of VPN
    // megapage: 35 bits of PPN, 9 bits of VPN
    // gigapage: 26 bits of PPN, 18 bits of VPN
    // terapage: 17 bits of PPN, 27 bits of VPN
    mux4 #(44) pnm(44'h00000000000, 44'h000000001FF, 44'h0000003FFFF, 44'h00007FFFFFF, HitPageType, PageNumberMask);
 
  // merge low segments of VPN with high segments of PPN decided by the pagetype.
  assign ZeroExtendedVPN = {{EXTRA_BITS{1'b0}}, VPN}; // forces the VPN to be the same width as PPN.
  assign PPNMixed = PPN | ZeroExtendedVPN & PageNumberMask; // 
  //mux2 #(1) mixmux[`PPN_BITS-1:0](ZeroExtendedVPN, PPN, PageNumberMask, PPNMixed);
  //assign PPNMixed = (ZeroExtendedVPN & ~PageNumberMask) | (PPN & PageNumberMask);
  // Output the hit physical address if translation is currently on.
  // Provide physical address of zero if not TLBHits, to cause segmentation error if miss somehow percolated through signal
  mux2 #(`PA_BITS) hitmux('0, {PPNMixed, Offset}, TLBHit, TLBPAdr); // set PA to 0 if TLB misses, to cause segementation error if this miss somehow passes through system

endmodule

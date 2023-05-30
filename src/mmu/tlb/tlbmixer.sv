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

module tlbmixer import cvw::*;  #(parameter cvw_t P) (
    input  logic [P.VPN_BITS-1:0]   VPN,
    input  logic [P.PPN_BITS-1:0]   PPN,
    input  logic [1:0]             HitPageType,
    input  logic [11:0]            Offset,
    input  logic                   TLBHit,
    output logic [P.PA_BITS-1:0]    TLBPAdr
);

  localparam EXTRA_BITS = P.PPN_BITS - P.VPN_BITS;
  logic [P.PPN_BITS-1:0] ZeroExtendedVPN;
  logic [P.PPN_BITS-1:0] PageNumberMask;
  logic [P.PPN_BITS-1:0] PPNMixed;

  // produce PageNumberMask with 1s where virtual page number bits should be untranslaetd for superpages
  if (P.XLEN == 32)
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
  //mux2 #(1) mixmux[P.PPN_BITS-1:0](ZeroExtendedVPN, PPN, PageNumberMask, PPNMixed);
  //assign PPNMixed = (ZeroExtendedVPN & ~PageNumberMask) | (PPN & PageNumberMask);
  // Output the hit physical address if translation is currently on.
  // Provide physical address of zero if not TLBHits, to cause segmentation error if miss somehow percolated through signal
  mux2 #(P.PA_BITS) hitmux('0, {PPNMixed, Offset}, TLBHit, TLBPAdr); // set PA to 0 if TLB misses, to cause segementation error if this miss somehow passes through system

endmodule

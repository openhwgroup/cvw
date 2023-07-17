///////////////////////////////////////////
// tlbcamline.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 6 April 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
//            Implemented SV48 on top of SV39. This included adding SvMode input signal and the wally constants
//            Mostly this was done to make the PageNumberMixer work.
//
// Purpose: CAM line for the translation lookaside buffer (TLB)
//          Determines whether a virtual page number matches the stored key.
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

module tlbcamline import cvw::*;  #(parameter cvw_t P, 
                                    parameter KEY_BITS = 20, SEGMENT_BITS = 10) (
  input  logic                  clk, reset,
  input  logic [P.VPN_BITS-1:0]  VPN, // The requested page number to compare against the key
  input  logic [P.ASID_BITS-1:0] SATP_ASID,
  input  logic                  SV39Mode,
  input  logic                  WriteEnable,  // Write a new entry to this line
  input  logic                  PTE_G,
  input  logic [1:0]            PageTypeWriteVal,
  input  logic                  TLBFlush,   // Flush this line (set valid to 0)
  output logic [1:0]            PageTypeRead,  // *** should this be the stored version or the always updated one?
  output logic                  Match
);

  // PageTypeRead is a key for a tera, giga, mega, or kilopage.
  // PageType == 2'b00 --> kilopage
  // PageType == 2'b01 --> megapage
  // PageType == 2'b10 --> gigapage
  // PageType == 2'b11 --> terapage

  // This entry has KEY_BITS for the key plus one valid bit.
  logic                Valid;
  logic [KEY_BITS-1:0] Key;
  logic [1:0]          PageType;
  
  // Split up key and query into sections for each page table level.
  logic [P.ASID_BITS-1:0] Key_ASID;
  logic [SEGMENT_BITS-1:0] Key0, Key1, Query0, Query1;
  logic MatchASID, Match0, Match1;

  assign MatchASID = (SATP_ASID == Key_ASID) | PTE_G; 

  if (P.XLEN == 32) begin: match

    assign {Key_ASID, Key1, Key0} = Key;
    assign {Query1, Query0} = VPN;

    // Calculate the actual match value based on the input vpn and the page type.
    // For example, a megapage in SV32 only cares about VPN[1], so VPN[0]
    // should automatically match.
    assign Match0 = (Query0 == Key0) | (PageType[0]); // least signifcant section
    assign Match1 = (Query1 == Key1);

    assign Match = Match0 & Match1 & MatchASID & Valid;
  end else begin: match

    logic [SEGMENT_BITS-1:0] Key2, Key3, Query2, Query3;
    logic Match2, Match3;

    assign {Query3, Query2, Query1, Query0} = VPN;
    assign {Key_ASID, Key3, Key2, Key1, Key0} = Key;

    // Calculate the actual match value based on the input vpn and the page type.
    // For example, a gigapage in SV39 only cares about VPN[2], so VPN[0] and VPN[1]
    // should automatically match.
    assign Match0 = (Query0 == Key0) | (PageType > 2'd0); // least signifcant section
    assign Match1 = (Query1 == Key1) | (PageType > 2'd1);
    assign Match2 = (Query2 == Key2) | (PageType > 2'd2);
    assign Match3 = (Query3 == Key3) | SV39Mode; // this should always match in sv39 because they aren't used
    
    assign Match = Match0 & Match1 & Match2 & Match3 & MatchASID & Valid;
  end

  // On a write, update the type of the page referred to by this line.
  flopenr #(2) pagetypeflop(clk, reset, WriteEnable, PageTypeWriteVal, PageType);
  assign PageTypeRead = PageType & {2{Match}};

  // On a write, set the valid bit high and update the stored key.
  // On a flush, zero the valid bit and leave the key unchanged.
  // *** Might we want to update stored key right away to output match on the
  // write cycle? (using a mux)
  flopenr #(1) validbitflop(clk, reset, WriteEnable | TLBFlush, ~TLBFlush, Valid);
  flopenr #(KEY_BITS) keyflop(clk, reset, WriteEnable, {SATP_ASID, VPN}, Key);
endmodule

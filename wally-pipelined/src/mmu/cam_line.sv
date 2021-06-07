///////////////////////////////////////////
// cam_line.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 6 April 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
//            Implemented SV48 on top of SV39. This included adding SvMode input signal and the wally constants
//            Mostly this was done to make the PageNumberMixer work.
//
// Purpose: CAM line for the translation lookaside buffer (TLB)
//          Determines whether a virtual address matches the stored key.
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

module cam_line #(parameter KEY_BITS = 20,
                  parameter SEGMENT_BITS = 10) (
  input                 clk, reset,

  // input to check which SvMode is running
  input [`SVMODE_BITS-1:0] SvMode,
  
  // The requested page number to compare against the key
  input [KEY_BITS-1:0]  VirtualPageNumber,

  // Signals to write a new entry to this line
  input                 CAMLineWrite,
  input  [1:0]          PageTypeWrite,

  // Flush this line (set valid to 0)
  input                 TLBFlush,

  // This entry is a key for a tera, giga, mega, or kilopage.
  // PageType == 2'b00 --> kilopage
  // PageType == 2'b01 --> megapage
  // PageType == 2'b10 --> gigapage
  // PageType == 2'b11 --> terapage
  output [1:0]          PageType,  // *** should this be the stored version or the always updated one?
  output                Match
);

  // This entry has KEY_BITS for the key plus one valid bit.
  logic                Valid;
  logic [KEY_BITS-1:0] Key;
  

  // Split up key and VPN into sections for each page table level.
  logic [SEGMENT_BITS-1:0] Key0, Key1, VPN0, VPN1;
  logic MatchVPN0, MatchVPN1;

  generate
    if (`XLEN == 32) begin
      assign {Key1, Key0} = Key;
      assign {VPN1, VPN0} = VirtualPageNumber;

      assign MatchVPN0 = (VPN0 == Key0) || (PageType[0]); // least signifcant section
      assign MatchVPN1 = (VPN1 == Key1);

      assign Match = MatchVPN0 & MatchVPN1 & Valid;
    end else begin
      logic [SEGMENT_BITS-1:0] Key2, Key3, VPN2, VPN3;
      logic MatchVPN2, MatchVPN3;

      assign {VPN3, VPN2, VPN1, VPN0} = VirtualPageNumber;
      assign {Key3, Key2, Key1, Key0} = Key;

      assign MatchVPN0 = (VPN0 == Key0) || (PageType > 2'd0); // least signifcant section
      assign MatchVPN1 = (VPN1 == Key1) || (PageType > 2'd1);
      assign MatchVPN2 = (VPN2 == Key2) || (PageType > 2'd2);
      assign MatchVPN3 = (VPN3 == Key3); // *** this should always match in sv39 since both vPN3 and key3 are zeroed by the pagetable walker before getting to the cam
      
      assign Match = MatchVPN0 & MatchVPN1 & MatchVPN2 & MatchVPN3 & Valid;
    end
  endgenerate

  // When determining a match for a superpage, we might use only a portion of
  // the input VirtualPageNumber. Unused parts of the VirtualPageNumber are
  // zeroed in VirtualPageNumberQuery to better match with Key.
  logic [KEY_BITS-1:0] VirtualPageNumberQuery;

  // On a write, update the type of the page referred to by this line.
  flopenr #(2) pagetypeflop(clk, reset, CAMLineWrite, PageTypeWrite, PageType);
  //mux2 #(2) pagetypemux(StoredPageType, PageTypeWrite, CAMLineWrite, PageType);

  // On a write, set the valid bit high and update the stored key.
  // On a flush, zero the valid bit and leave the key unchanged.
  // *** Might we want to update stored key right away to output match on the
  // write cycle? (using a mux)
  flopenrc #(1) validbitflop(clk, reset, TLBFlush, CAMLineWrite, 1'b1, Valid);
  flopenr #(KEY_BITS) keyflop(clk, reset, CAMLineWrite, VirtualPageNumber, Key);

  // Calculate the actual query key based on the input key and the page type.
  // For example, a megapage in SV39 only cares about VPN2 and VPN1, so VPN0
  // should automatically match.
//  logic [KEY_BITS-1:0] PageNumberMask, MaskedKey, MaskedQuery;
  // this is the max possible length of the vpn, as listed in wally-constants.
  // for modes with a mode with fewer bits in the vpn, the extra levels in MaskedQuery 
  // and MaskedKey should have been zeroed out by the tlb before coming through the cam as VirtualPageNumber.
  generate
      if (`XLEN == 32) begin

      end else begin

      end
  endgenerate


endmodule

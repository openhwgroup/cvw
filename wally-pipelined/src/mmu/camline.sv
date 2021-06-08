///////////////////////////////////////////
// camline.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 6 April 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
//            Implemented SV48 on top of SV39. This included adding SvMode input signal and the wally constants
//            Mostly this was done to make the PageNumberMixer work.
//
// Purpose: CAM line for the translation lookaside buffer (TLB)
//          Determines whether a virtual page number matches the stored key.
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

module camline #(parameter KEY_BITS = 20,
                  parameter SEGMENT_BITS = 10) (
  input logic                 clk, reset,

  // input to check which SvMode is running
//  input logic [`SVMODE_BITS-1:0] SvMode, // *** may no longer be needed.
  
  // The requested page number to compare against the key
  input logic [KEY_BITS-1:0]  VirtualPageNumber,

  // Signals to write a new entry to this line
  input logic                 CAMLineWrite,
  input logic [1:0]           PageTypeWriteVal,

  // Flush this line (set valid to 0)
  input logic                 TLBFlush,

  // This entry is a key for a tera, giga, mega, or kilopage.
  // PageType == 2'b00 --> kilopage
  // PageType == 2'b01 --> megapage
  // PageType == 2'b10 --> gigapage
  // PageType == 2'b11 --> terapage
  output logic [1:0]          PageType,  // *** should this be the stored version or the always updated one?
  output logic                Match
);

  // This entry has KEY_BITS for the key plus one valid bit.
  logic                Valid;
  logic [KEY_BITS-1:0] Key;
  

  // Split up key and query into sections for each page table level.
  logic [SEGMENT_BITS-1:0] Key0, Key1, Query0, Query1;
  logic Match0, Match1;

  generate
    if (`XLEN == 32) begin

      assign {Key1, Key0} = Key;
      assign {Query1, Query0} = VirtualPageNumber;

      // Calculate the actual match value based on the input vpn and the page type.
      // For example, a megapage in SV32 only cares about VPN[1], so VPN[0]
      // should automatically match.
      assign Match0 = (Query0 == Key0) || (PageType[0]); // least signifcant section
      assign Match1 = (Query1 == Key1);

      assign Match = Match0 & Match1 & Valid;
    end else begin

      logic [SEGMENT_BITS-1:0] Key2, Key3, Query2, Query3;
      logic Match2, Match3;

      assign {Query3, Query2, Query1, Query0} = VirtualPageNumber;
      assign {Key3, Key2, Key1, Key0} = Key;

      // Calculate the actual match value based on the input vpn and the page type.
      // For example, a gigapage in SV only cares about VPN[2], so VPN[0] and VPN[1]
      // should automatically match.
      assign Match0 = (Query0 == Key0) || (PageType > 2'd0); // least signifcant section
      assign Match1 = (Query1 == Key1) || (PageType > 2'd1);
      assign Match2 = (Query2 == Key2) || (PageType > 2'd2);
      assign Match3 = (Query3 == Key3); // *** this should always match in sv39 since both vPN3 and key3 are zeroed by the pagetable walker before getting to the cam
      
      assign Match = Match0 & Match1 & Match2 & Match3 & Valid;
    end
  endgenerate

  // On a write, update the type of the page referred to by this line.
  flopenr #(2) pagetypeflop(clk, reset, CAMLineWrite, PageTypeWriteVal, PageType);
  //mux2 #(2) pagetypemux(StoredPageType, PageTypeWrite, CAMLineWrite, PageType);

  // On a write, set the valid bit high and update the stored key.
  // On a flush, zero the valid bit and leave the key unchanged.
  // *** Might we want to update stored key right away to output match on the
  // write cycle? (using a mux)
  flopenrc #(1) validbitflop(clk, reset, TLBFlush, CAMLineWrite, 1'b1, Valid);
  flopenr #(KEY_BITS) keyflop(clk, reset, CAMLineWrite, VirtualPageNumber, Key);

endmodule

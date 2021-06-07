///////////////////////////////////////////
// page_number_mixer.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 6 April 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
//              Implemented SV48 on top of SV39. This included adding a 3rd Segment to each of the pagenumbers,
//              Ensuring that the BITS and HIGH_SEGMENT_BITS inputs were correct everywhere this module gets instatniated,
//              Adding seveeral muxes to decide the bit selection to turn pagenumbers into segments based on SV mode,
//              Adding support for terapage/newgigapage encoding.
//
// Purpose: Takes two page numbers and replaces segments of the first page
//          number with segments from the second, based on the page type.
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

module physicalpagemask #(parameter BITS = 20,
                           parameter HIGH_SEGMENT_BITS = 10) (
    input  [BITS-1:0]  ****       VirtualAddress,
    input  [BITS-1:0] ***        PPN,
    input  [1:0]              PageType,
    input  [`SVMODE_BITS-1:0] SvMode,

    output [BITS-1:0]***         PhysicalAddress
);

  logic [***] OffsetMask;

  generate
    if (`XLEN == 32) begin
      always_comb 
        case (PageType[0])
          0: OffsetMask = 34'h3FFFFF000; // kilopage: 22 bits of PPN, 12 bits of offset
          1: OffsetMask = 34'h3FFC00000; // megapage: 12 bits of PPN, 22 bits of offset
        endcase
    end else begin
      always_comb 
        case (PageType[1:0])
          0: OffsetMask = 56'hFFFFFFFFFFF000; // kilopage: 44 bits of PPN, 12 bits of offset
          1: OffsetMask = 56'hFFFFFFFFE00000; // megapage: 35 bits of PPN, 21 bits of offset
          2: OffsetMask = 56'hFFFFFFC0000000; // gigapage: 26 bits of PPN, 30 bits of offset
          3: OffsetMask = 56'hFFFF8000000000; // terapage: 17 bits of PPN, 39 bits of offset
        endcase
  endgenerate

  // merge low bits of the virtual address containing the offset with high bits of the PPN
  assign PhysicalAddress = VirtualAddress & ~OffsetMask | ((PPN<<12) & OffsetMask);

endmodule

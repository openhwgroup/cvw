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

module page_number_mixer #(parameter BITS = 20,
                           parameter HIGH_SEGMENT_BITS = 10) (
    input  [BITS-1:0]         PageNumber,
    input  [BITS-1:0]         MixPageNumber,
    input  [1:0]              PageType,
    input  [`SVMODE_BITS-1:0] SvMode,

    output [BITS-1:0]         PageNumberCombined
);

  // The upper segment might have a different width than the lower segments.
  // For example, an SV39 PTE has 26 bits for PPN2 and 9 bits for the other
  // segments. This is outside the 'if XLEN' b/c the constant is already configured
  // to the correct value for the XLEN in the relevant wally-constants.vh file.
  localparam LOW_SEGMENT_BITS = `VPN_SEGMENT_BITS;
  // *** each time this module is implemented, low segment bits is either
  // `VPN_SEGMENT_BITS or `PPN_LOW_SEGMENT_BITS (if it existed)
  // in every mode so far, these are the same, so it's left as it is above. 

  generate
    if (`XLEN == 32) begin
      always_comb 

      logic [HIGH_SEGMENT_BITS-1:0] Segment1, MixSegment1, Segment1Combined;
      logic [LOW_SEGMENT_BITS-1:0]  Segment0, MixSegment0, Segment0Combined;

      // Unswizzle segments of the input page numbers
      assign {Segment1, Segment0} = PageNumber;
      assign {MixSegment1, MixSegment0} = MixPageNumber;

      // Pass through the high segment
      assign Segment1Combined = Segment1;

      // Either pass through or zero out segment 0
      mux2 #(LOW_SEGMENT_BITS) segment0mux(Segment0, MixSegment0, PageType[0], Segment0Combined);

      // Reswizzle segments of the combined page number
      assign PageNumberCombined = {Segment1Combined, Segment0Combined};
    end else begin

      // After segment 0 and 1 of the page number, the width of each segment is dependant on the SvMode.
      // For this reason, each segment bus is the width of its widest value across each mode
      // when a smaller value needs to be loaded in to a wider bus, it's loaded in the least significant bits
      // and left padded with zeros. MAKE SURE that if a value is being padded with zeros here,
      // that it's padded with zeros everywhere else in the MMU ans beyond to avoid false misses in the TLB.
      logic [HIGH_SEGMENT_BITS-1:0] Segment3, MixSegment3, Segment3Combined;
      logic [HIGH_SEGMENT_BITS + LOW_SEGMENT_BITS-1:0]  Segment2, MixSegment2, Segment2Combined;
      logic [LOW_SEGMENT_BITS-1:0]  Segment1, MixSegment1, Segment1Combined;
      logic [LOW_SEGMENT_BITS-1:0]  Segment0, MixSegment0, Segment0Combined;
      

      // Unswizzle segments of the input page number
      // *** these muxes assume that only Sv48 and SV39 are implemented in rv64. for future SV57 and up,
      //      there will have to be more muxes to select which value each segment gets.
      //      as a cool reminder: BITS is the width of the page number, virt or phys, coming into this module
      //      while high segment bits is the width of the highest segment of that page number.
      //      Note for future work: this module has to work with both VPNs and PPNs and due to their differing 
      //         widths and the fact that the ppn has one longer segment at the top makes the muxes below very confusing.
      //      Potentially very annoying thing for future workers: the number of bits in a ppn is always 44 (for SV39 and48)
      //         but in SV57 and above, this might be a new longer length. In that case these selectors will most likely
      //         become even more complicated and confusing.
      assign Segment3 = (SvMode == `SV48) ? 
                        PageNumber[BITS-1:3*LOW_SEGMENT_BITS] : // take the top segment or not
                        {HIGH_SEGMENT_BITS{1'b0}}; // for virtual page numbers in SV39, both options should be zeros.
      assign Segment2 = (SvMode == `SV48) ? 
                        {{HIGH_SEGMENT_BITS{1'b0}}, PageNumber[3*LOW_SEGMENT_BITS-1:2*LOW_SEGMENT_BITS]} : // just take another low segment left padded with zeros.
                        PageNumber[BITS-1:2*LOW_SEGMENT_BITS]; // otherwise take the rest of the PageNumber
      assign Segment1 = PageNumber[2*LOW_SEGMENT_BITS-1:LOW_SEGMENT_BITS];
      assign Segment0 = PageNumber[LOW_SEGMENT_BITS-1:0];


      assign MixSegment3 = (SvMode == `SV48) ? 
                        MixPageNumber[BITS-1:3*LOW_SEGMENT_BITS] : // take the top segment or not
                        {HIGH_SEGMENT_BITS{1'b0}}; // for virtual page numbers in SV39, both options should be zeros.
      assign MixSegment2 = (SvMode == `SV48) ? 
                        {{HIGH_SEGMENT_BITS{1'b0}}, MixPageNumber[3*LOW_SEGMENT_BITS-1:2*LOW_SEGMENT_BITS]} : // just take another low segment left padded with zeros.
                        MixPageNumber[BITS-1:2*LOW_SEGMENT_BITS]; // otherwise take the rest of the PageNumber
      assign MixSegment1 = MixPageNumber[2*LOW_SEGMENT_BITS-1:LOW_SEGMENT_BITS];
      assign MixSegment0 = MixPageNumber[LOW_SEGMENT_BITS-1:0];


      // Pass through the high segment
      assign Segment3Combined = Segment3;

      // Either pass through or zero out lower segments based on the page type
      assign Segment2Combined = (PageType[1] && PageType[0]) ? MixSegment2 : Segment2; // terapage (page == 11)
      assign Segment1Combined = (PageType[1]) ? MixSegment1 : Segment1; // gigapage and higher (page == 10 or 11)
      assign Segment0Combined = (PageType[1] || PageType[0]) ? MixSegment0 : Segment0; // megapage and higher (page == 01 or 10 or 11)

      // Reswizzle segments of the combined page number
      assign PageNumberCombined = (SvMode == `SV48) ? 
                                  {Segment3Combined, Segment2Combined[LOW_SEGMENT_BITS-1:0], Segment1Combined, Segment0Combined} :
                                  {Segment2Combined, Segment1Combined, Segment0Combined};
    end
  endgenerate
endmodule

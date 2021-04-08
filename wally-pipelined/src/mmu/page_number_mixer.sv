///////////////////////////////////////////
// page_number_mixer.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 6 April 2021
// Modified:
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
    input  [BITS-1:0] PageNumber,
    input  [BITS-1:0] MixPageNumber,
    input  [1:0]      PageType,
    output [BITS-1:0] PageNumberCombined
);

  generate
    // *** Just checking XLEN is not enough to support sv39 AND sv48.
    if (`XLEN == 32) begin
      // The upper segment might have a different width than the lower segments.
      // For example, an sv39 PTE has 26 bits for PPN2 and 9 bits for the other
      // segments.
      localparam LOW_SEGMENT_BITS = (BITS - HIGH_SEGMENT_BITS);

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
      // The upper segment might have a different width than the lower segments.
      // For example, an sv39 PTE has 26 bits for PPN2 and 9 bits for the other
      // segments.
      localparam LOW_SEGMENT_BITS = (BITS - HIGH_SEGMENT_BITS) / 2;

      logic [HIGH_SEGMENT_BITS-1:0] Segment2, MixSegment2, Segment2Combined;
      logic [LOW_SEGMENT_BITS-1:0]  Segment1, MixSegment1, Segment1Combined;
      logic [LOW_SEGMENT_BITS-1:0]  Segment0, MixSegment0, Segment0Combined;

      // Unswizzle segments of the input page number
      assign {Segment2, Segment1, Segment0} = PageNumber;
      assign {MixSegment2, MixSegment1, MixSegment0} = MixPageNumber;

      // Pass through the high segment
      assign Segment2Combined = Segment2;

      // Either pass through or zero out segments 1 and 0 based on the page type
      mux2 #(LOW_SEGMENT_BITS) segment1mux(Segment1, MixSegment1, PageType[1], Segment1Combined);
      mux2 #(LOW_SEGMENT_BITS) segment0mux(Segment0, MixSegment0, PageType[0], Segment0Combined);

      // Reswizzle segments of the combined page number
      assign PageNumberCombined = {Segment2Combined, Segment1Combined, Segment0Combined};
    end
  endgenerate
endmodule

///////////////////////////////////////////
// swbytemask.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: On-chip RAM, external to core
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

module swbytemask #(parameter WORDLEN = 64)(
  input logic [2:0]              Size,
  input logic [$clog2(WORDLEN/8)-1:0] Adr,
  output logic [WORDLEN/8-1:0]   ByteMask);

  assign ByteMask = ((2**(2**Size))-1) << Adr;

/* Equivalent to the following for WORDLEN = 64
 if(WORDLEN == 64) begin
    always_comb begin
      case(Size[1:0])
        2'b00: begin ByteMask = 8'b00000000; ByteMask[Adr[2:0]] = 1; end // sb
        2'b01: case (Adr[2:1])
                  2'b00: ByteMask = 8'b0000_0011;
                  2'b01: ByteMask = 8'b0000_1100;
                  2'b10: ByteMask = 8'b0011_0000;
                  2'b11: ByteMask = 8'b1100_0000;
                endcase
        2'b10: if (Adr[2]) ByteMask = 8'b11110000;
               else        ByteMask = 8'b00001111;
        2'b11: ByteMask = 8'b1111_1111;
        default ByteMask = 8'b0000_0000;
      endcase
    end
  end
*/

endmodule

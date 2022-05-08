///////////////////////////////////////////
// subwordwrite.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Masking and muxing for subword writes
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

module subwordwrite (
  input logic [2:0]          LSUPAdrM,
  input logic [2:0]          LSUFunct3M,
  input logic [`XLEN-1:0]    AMOWriteDataM,
  output logic [`XLEN-1:0]   LittleEndianWriteDataM,
  output logic [`XLEN/8-1:0] ByteMaskM
);

  // Compute byte masks
  swbytemask swbytemask(.Size(LSUFunct3M[1:0]), .Adr(LSUPAdrM), .ByteMask(ByteMaskM));
  
  // Replicate data for subword writes
  if (`XLEN == 64) begin:sww
    always_comb 
      case(LSUFunct3M[1:0])
        2'b00:  LittleEndianWriteDataM = {8{AMOWriteDataM[7:0]}};  // sb
        2'b01:  LittleEndianWriteDataM = {4{AMOWriteDataM[15:0]}}; // sh
        2'b10:  LittleEndianWriteDataM = {2{AMOWriteDataM[31:0]}}; // sw
        2'b11:  LittleEndianWriteDataM = AMOWriteDataM;            // sw
      endcase
  end else begin:sww // 32-bit
    always_comb 
      case(LSUFunct3M[1:0])
        2'b00:  LittleEndianWriteDataM = {4{AMOWriteDataM[7:0]}};  // sb
        2'b01:  LittleEndianWriteDataM = {2{AMOWriteDataM[15:0]}}; // sh
        2'b10:  LittleEndianWriteDataM = AMOWriteDataM;            // sw
        default: LittleEndianWriteDataM = AMOWriteDataM; // shouldn't happen
      endcase
  end
endmodule

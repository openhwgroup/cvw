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
  input logic [3:0]          HSIZED,
  input logic [`XLEN-1:0]    HWDATAIN,
  output logic [`XLEN-1:0]   HWDATA,
  output logic [`XLEN/8-1:0] ByteMaskM
                     );
                  
  logic [`XLEN-1:0]          WriteDataSubwordDuplicated;

  swbytemask swbytemask(.HSIZED, .HADDRD(LSUPAdrM), .ByteMask(ByteMaskM));
  
  if (`XLEN == 64) begin:sww
    // Handle subword writes
    always_comb 
      case(HSIZED[1:0])
        2'b00:  WriteDataSubwordDuplicated = {8{HWDATAIN[7:0]}};  // sb
        2'b01:  WriteDataSubwordDuplicated = {4{HWDATAIN[15:0]}}; // sh
        2'b10:  WriteDataSubwordDuplicated = {2{HWDATAIN[31:0]}}; // sw
        2'b11:  WriteDataSubwordDuplicated = HWDATAIN;            // sw
      endcase

    always_comb begin
      HWDATA='0;
      if (ByteMaskM[0]) HWDATA[7:0]   = WriteDataSubwordDuplicated[7:0];
      if (ByteMaskM[1]) HWDATA[15:8]  = WriteDataSubwordDuplicated[15:8];
      if (ByteMaskM[2]) HWDATA[23:16] = WriteDataSubwordDuplicated[23:16];
      if (ByteMaskM[3]) HWDATA[31:24] = WriteDataSubwordDuplicated[31:24];
      if (ByteMaskM[4]) HWDATA[39:32] = WriteDataSubwordDuplicated[39:32];
      if (ByteMaskM[5]) HWDATA[47:40] = WriteDataSubwordDuplicated[47:40];
      if (ByteMaskM[6]) HWDATA[55:48] = WriteDataSubwordDuplicated[55:48];
      if (ByteMaskM[7]) HWDATA[63:56] = WriteDataSubwordDuplicated[63:56];
    end 

  end else begin:sww // 32-bit
    // Handle subword writes
    always_comb 
      case(HSIZED[1:0])
        2'b00:  WriteDataSubwordDuplicated = {4{HWDATAIN[7:0]}};  // sb
        2'b01:  WriteDataSubwordDuplicated = {2{HWDATAIN[15:0]}}; // sh
        2'b10:  WriteDataSubwordDuplicated = HWDATAIN;            // sw
        default: WriteDataSubwordDuplicated = HWDATAIN; // shouldn't happen
      endcase

    always_comb begin
      HWDATA='0;
      if (ByteMaskM[0]) HWDATA[7:0]   = WriteDataSubwordDuplicated[7:0];
      if (ByteMaskM[1]) HWDATA[15:8]  = WriteDataSubwordDuplicated[15:8];
      if (ByteMaskM[2]) HWDATA[23:16] = WriteDataSubwordDuplicated[23:16];
      if (ByteMaskM[3]) HWDATA[31:24] = WriteDataSubwordDuplicated[31:24];
    end 

  end
endmodule

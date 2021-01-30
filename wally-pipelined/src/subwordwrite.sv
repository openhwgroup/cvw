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

module subwordwrite (
  input  logic [`XLEN-1:0] HRDATA,
  input  logic [31:0]      HADDR,
  input  logic [2:0]       HSIZE,
  input  logic [`XLEN-1:0] HWDATAIN,
  output logic [`XLEN-1:0] HWDATA
);
                  
  logic [7:0]  ByteM; // *** declare locally to generate as either 4 or 8 bits
  logic [15:0] HalfwordM;
  logic [`XLEN-1:0] WriteDataSubwordDuplicated;
  logic [7:0]      ByteMaskM;
  
  generate
    if (`XLEN == 64) begin
      // Compute write mask
      always_comb 
        case(HSIZE[1:0])
          2'b00:  begin ByteMaskM = 8'b00000000; ByteMaskM[HADDR[2:0]] = 1; end // sb
          2'b01:  case (HADDR[2:1])
                    2'b00: ByteMaskM = 8'b00000011;
                    2'b01: ByteMaskM = 8'b00001100;
                    2'b10: ByteMaskM = 8'b00110000;
                    2'b11: ByteMaskM = 8'b11000000;
                  endcase
          2'b10:  if (HADDR[2]) ByteMaskM = 8'b11110000;
                   else        ByteMaskM = 8'b00001111;
          2'b11:  ByteMaskM = 8'b11111111;
        endcase

      // Handle subword writes
      always_comb 
        case(HSIZE[1:0])
          2'b00:  WriteDataSubwordDuplicated = {8{HWDATAIN[7:0]}};  // sb
          2'b01:  WriteDataSubwordDuplicated = {4{HWDATAIN[15:0]}}; // sh
          2'b10:  WriteDataSubwordDuplicated = {2{HWDATAIN[31:0]}}; // sw
          2'b11:  WriteDataSubwordDuplicated = HWDATAIN;            // sw
        endcase

      always_comb begin
        HWDATA=HRDATA;
        if (ByteMaskM[0]) HWDATA[7:0]   = WriteDataSubwordDuplicated[7:0];
        if (ByteMaskM[1]) HWDATA[15:8]  = WriteDataSubwordDuplicated[15:8];
        if (ByteMaskM[2]) HWDATA[23:16] = WriteDataSubwordDuplicated[23:16];
        if (ByteMaskM[3]) HWDATA[31:24] = WriteDataSubwordDuplicated[31:24];
	      if (ByteMaskM[4]) HWDATA[39:32] = WriteDataSubwordDuplicated[39:32];
	      if (ByteMaskM[5]) HWDATA[47:40] = WriteDataSubwordDuplicated[47:40];
      	if (ByteMaskM[6]) HWDATA[55:48] = WriteDataSubwordDuplicated[55:48];
	      if (ByteMaskM[7]) HWDATA[63:56] = WriteDataSubwordDuplicated[63:56];
      end 

    end else begin // 32-bit
      // Compute write mask
      always_comb 
        case(HSIZE[1:0])
          2'b00:  begin ByteMaskM = 8'b0000; ByteMaskM[{1'b0, HADDR[1:0]}] = 1; end // sb
          2'b01:  if (HADDR[1]) ByteMaskM = 8'b1100;
                   else         ByteMaskM = 8'b0011;
          2'b10:  ByteMaskM = 8'b1111;
          default: ByteMaskM = 8'b111; // shouldn't happen
        endcase

      // Handle subword writes
      always_comb 
        case(HSIZE[1:0])
          2'b00:  WriteDataSubwordDuplicated = {4{HWDATAIN[7:0]}};  // sb
          2'b01:  WriteDataSubwordDuplicated = {2{HWDATAIN[15:0]}}; // sh
          2'b10:  WriteDataSubwordDuplicated = HWDATAIN;            // sw
          default: WriteDataSubwordDuplicated = HWDATAIN; // shouldn't happen
        endcase

      always_comb begin
        HWDATA=HRDATA;
        if (ByteMaskM[0]) HWDATA[7:0]   = WriteDataSubwordDuplicated[7:0];
        if (ByteMaskM[1]) HWDATA[15:8]  = WriteDataSubwordDuplicated[15:8];
        if (ByteMaskM[2]) HWDATA[23:16] = WriteDataSubwordDuplicated[23:16];
        if (ByteMaskM[3]) HWDATA[31:24] = WriteDataSubwordDuplicated[31:24];
      end 

    end
  endgenerate

endmodule

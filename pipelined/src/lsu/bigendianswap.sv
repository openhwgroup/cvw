///////////////////////////////////////////
// bigendianswap.sv
//
// Written: David_Harris@hmc.edu 7 May 2022
// Modified: 
//
// Purpose: Swap byte order for Big-Endian accesses
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

module bigendianswap #(parameter LEN=`XLEN) (
  input  logic             BigEndianM,
  input  logic [LEN-1:0] a,
  output logic [LEN-1:0] y); 

  if(LEN == 128) begin
    always_comb 
        if (BigEndianM) begin // swap endianness
            y[127:120] = a[7:0];
            y[119:112] = a[15:8];
            y[111:104] = a[23:16];
            y[103:96]  = a[31:24];
            y[95:88]   = a[39:32];
            y[87:80]   = a[47:40];
            y[79:72]   = a[55:48];
            y[71:64]   = a[63:56];
            y[63:56]   = a[71:64];
            y[55:48]   = a[79:72];
            y[47:40]   = a[87:80];
            y[39:32]   = a[95:88];
            y[31:24]   = a[103:96];
            y[23:16]   = a[111:104];
            y[15:8]    = a[119:112];
            y[7:0]     = a[127:120];
        end else y = a;
  end else if(LEN == 64) begin
    always_comb 
        if (BigEndianM) begin // swap endianness
            y[63:56] = a[7:0];
            y[55:48] = a[15:8];
            y[47:40] = a[23:16];
            y[39:32] = a[31:24];
            y[31:24] = a[39:32];
            y[23:16] = a[47:40];
            y[15:8]  = a[55:48];
            y[7:0]   = a[63:56];
        end else y = a;
  end else begin
    always_comb
      if (BigEndianM) begin
            y[31:24] = a[7:0];
            y[23:16] = a[15:8];
            y[15:8]  = a[23:16];
            y[7:0]   = a[31:24];
      end else y = a;
  end
endmodule

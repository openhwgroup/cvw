///////////////////////////////////////////
// endianswap.sv
//
// Written: David_Harris@hmc.edu
// Created: 7 May 2022
// Modified: 18 January 2023
//
// Purpose: Swap byte order for Big-Endian accesses
// 
// Documentation: RISC-V System on Chip Design Chapter 5 (Figure 5.9)
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module endianswapdouble #(parameter LEN) (
  input  logic            BigEndianM,
  input  logic [LEN-1:0]  a,
  output logic [LEN-1:0]  y
); 

  if(LEN == 256) begin
    always_comb 
      if (BigEndianM) begin // swap endianness
        y[255:248] = a[7:0];
        y[247:240] = a[15:8];
        y[239:232] = a[23:16];
        y[231:224] = a[31:24];
        y[223:216] = a[39:32];
        y[215:208] = a[47:40];
        y[207:200] = a[55:48];
        y[199:192] = a[63:56];
        y[191:184] = a[71:64];
        y[183:176] = a[79:72];
        y[175:168] = a[87:80];
        y[167:160] = a[95:88];
        y[159:152] = a[103:96];
        y[151:144] = a[111:104];
        y[143:136] = a[119:112];
        y[135:128] = a[127:120];
        y[127:120] = a[135:128];
        y[119:112] = a[142:136];
        y[111:104] = a[152:144];
        y[103:96]  = a[159:152];
        y[95:88]   = a[167:160];
        y[87:80]   = a[175:168];
        y[79:72]   = a[183:176];
        y[71:64]   = a[191:184];
        y[63:56]   = a[199:192];
        y[55:48]   = a[207:200];
        y[47:40]   = a[215:208];
        y[39:32]   = a[223:216];
        y[31:24]   = a[231:224];
        y[23:16]   = a[239:232];
        y[15:8]    = a[247:240];
        y[7:0]     = a[255:248];
      end else y = a;
  end else if(LEN == 128) begin
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

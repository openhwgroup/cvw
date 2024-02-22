///////////////////////////////////////////
// subwordwrite.sv
//
// Written: David_Harris@hmc.edu
// Created: 9 January 2021
// Modified: 18 January 2023 
//
// Purpose: Masking and muxing for subword writes
// 
// Documentation: RISC-V System on Chip Design Chapter 4 (Figure 4.9)
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

module subwordwritedouble #(parameter LLEN) (
  input logic [2:0]         LSUFunct3M,
  input logic [2:0]         PAdrM,
  input logic               FpLoadStoreM, 
  input logic               BigEndianM, 
  input logic               AllowShiftM,
  input logic [LLEN-1:0]    IMAFWriteDataM,
  output logic [LLEN*2-1:0] LittleEndianWriteDataM
);

  // *** RT: This is logic is duplicated in subwordreaddouble. Merge the two.
  logic [4:0]               PAdrSwap;
  logic [4:0]               BigEndianPAdr;
  logic [4:0]               LengthM;
  // Funct3M[2] is the unsigned bit. mask upper bits.
  // Funct3M[1:0] is the size of the memory access.
  // cacheable, BigEndian
  // 10: PAdrM[2:0]
  // 11: BigEndianPAdr
  // 00: 00000
  // 01: 11111
  mux4 #(5) OffsetMux(5'b0, 5'b11111, {2'b0, PAdrM}, BigEndianPAdr, {AllowShiftM, BigEndianM}, PAdrSwap);
  //assign PAdrSwap = BigEndianM ? BigEndianPAdr : {2'b0, PAdrM};
  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off WIDTHTRUNC */
  assign BigEndianPAdr = (LLEN/4) - PAdrM - LengthM;
  /* verilator lint_on WIDTHTRUNC */
  /* verilator lint_on WIDTHEXPAND */

  always_comb
    case(LSUFunct3M & {FpLoadStoreM, 2'b11})
      3'b000: LengthM = 5'd1;
      3'b001: LengthM = 5'd2;
      3'b010: LengthM = 5'd4;
      3'b011: LengthM = 5'd8;
      3'b100: LengthM = 5'd16;
      default: LengthM = 5'd8;
    endcase // case (LSUFunct3M & {FpLoadStoreM, 2'b11})

  // *** RT: End duplicated logic

  logic [LLEN*2-1:0]        IMAFWriteData2M;
  assign IMAFWriteData2M = {IMAFWriteDataM, IMAFWriteDataM};
  localparam OffsetIndex = $clog2(LLEN/8);
  logic [LLEN*2-1:0]        LittleEndianWriteDataMTemp;
  // *** RT: Switch to something like this.
  assign LittleEndianWriteDataMTemp = (IMAFWriteData2M << PAdrSwap[OffsetIndex-1:0]) | (IMAFWriteData2M >> ~PAdrSwap[OffsetIndex-1:0]);
  

  // Replicate data for subword writes
  if (LLEN == 128) begin:sww
    always_comb 
      case(PAdrSwap[3:0])
        4'b0000:  LittleEndianWriteDataM = {128'b0, IMAFWriteDataM       };
        4'b0001:  LittleEndianWriteDataM = {120'b0, IMAFWriteDataM, 8'b0 };
        4'b0010:  LittleEndianWriteDataM = {112'b0, IMAFWriteDataM, 16'b0};
        4'b0011:  LittleEndianWriteDataM = {104'b0, IMAFWriteDataM, 24'b0};
        4'b0100:  LittleEndianWriteDataM = {96'b0,  IMAFWriteDataM, 32'b0};
        4'b0101:  LittleEndianWriteDataM = {88'b0,  IMAFWriteDataM, 40'b0};
        4'b0110:  LittleEndianWriteDataM = {80'b0,  IMAFWriteDataM, 48'b0};
        4'b0111:  LittleEndianWriteDataM = {72'b0,  IMAFWriteDataM, 56'b0};
        4'b1000:  LittleEndianWriteDataM = {64'b0,  IMAFWriteDataM, 64'b0};
        4'b1001:  LittleEndianWriteDataM = {56'b0,  IMAFWriteDataM, 72'b0 };
        4'b1010:  LittleEndianWriteDataM = {48'b0,  IMAFWriteDataM, 80'b0};
        4'b1011:  LittleEndianWriteDataM = {40'b0,  IMAFWriteDataM, 88'b0};
        4'b1100:  LittleEndianWriteDataM = {32'b0,  IMAFWriteDataM, 96'b0};
        4'b1101:  LittleEndianWriteDataM = {24'b0,  IMAFWriteDataM, 104'b0};
        4'b1110:  LittleEndianWriteDataM = {16'b0,  IMAFWriteDataM, 112'b0};
        4'b1111:  LittleEndianWriteDataM = {8'b0,   IMAFWriteDataM, 120'b0};
        default: LittleEndianWriteDataM = IMAFWriteDataM;            // sq
      endcase
  end else if (LLEN == 64) begin:sww
    always_comb 
      case(PAdrSwap[2:0])
        3'b000:  LittleEndianWriteDataM = {IMAFWriteDataM,       IMAFWriteDataM};
        3'b001:  LittleEndianWriteDataM = {IMAFWriteDataM[55:0], IMAFWriteDataM, IMAFWriteDataM[63:56]};
        3'b010:  LittleEndianWriteDataM = {IMAFWriteDataM[47:0], IMAFWriteDataM, IMAFWriteDataM[63:48]};
        3'b011:  LittleEndianWriteDataM = {IMAFWriteDataM[39:0], IMAFWriteDataM, IMAFWriteDataM[63:40]};
        3'b100:  LittleEndianWriteDataM = {IMAFWriteDataM[31:0], IMAFWriteDataM, IMAFWriteDataM[63:32]};
        3'b101:  LittleEndianWriteDataM = {IMAFWriteDataM[23:0], IMAFWriteDataM, IMAFWriteDataM[63:24]};
        3'b110:  LittleEndianWriteDataM = {IMAFWriteDataM[15:0], IMAFWriteDataM, IMAFWriteDataM[63:16]};
        3'b111:  LittleEndianWriteDataM = {IMAFWriteDataM[7:0],  IMAFWriteDataM, IMAFWriteDataM[63:8] };
      endcase
  end else begin:sww // 32-bit
    always_comb 
      case(PAdrSwap[1:0])
        2'b00:  LittleEndianWriteDataM = {32'b0, IMAFWriteDataM       };
        2'b01:  LittleEndianWriteDataM = {24'b0, IMAFWriteDataM, 8'b0 };
        2'b10:  LittleEndianWriteDataM = {16'b0, IMAFWriteDataM, 16'b0};
        2'b11:  LittleEndianWriteDataM = {8'b0,  IMAFWriteDataM, 24'b0};
        default: LittleEndianWriteDataM = IMAFWriteDataM;            // shouldn't happen
      endcase
  end
endmodule

///////////////////////////////////////////
// subwordwritemisaligned.sv
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

module subwordwritemisaligned #(parameter LLEN) (
  input logic [2:0]         LSUFunct3M,
  input logic [2:0]         PAdrM,
  input logic               FpLoadStoreM, 
  input logic               BigEndianM, 
  input logic               AllowShiftM,
  input logic [LLEN-1:0]    IMAFWriteDataM,
  output logic [LLEN*2-1:0] LittleEndianWriteDataM
);

  // *** RT: This is logic is duplicated in subwordreadmisaligned. Merge the two.
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

  assign LittleEndianWriteDataM = (IMAFWriteData2M << (PAdrSwap[OffsetIndex-1:0] * 8)) | (IMAFWriteData2M >> (LLEN - (PAdrSwap[OffsetIndex-1:0] * 8)));
  
endmodule

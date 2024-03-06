///////////////////////////////////////////
// subwordread.sv
//
// Written: David_Harris@hmc.edu 
// Created: 9 January 2021
// Modified: 18 January 2023 
//
// Purpose: Extract subwords and sign extend for reads
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

module subwordreaddouble #(parameter LLEN) 
  (
   input logic [LLEN*2-1:0] ReadDataWordMuxM,
   input logic [2:0]        PAdrM,
   input logic [2:0]        Funct3M,
   input logic              FpLoadStoreM, 
   input logic              BigEndianM, 
   output logic [LLEN-1:0]  ReadDataM
);

  logic [7:0]               ByteM; 
  logic [15:0]              HalfwordM;
  logic [4:0]               PAdrSwap;
  logic [4:0]               BigEndianPAdr;
  logic [4:0]               LengthM;
  
  // Funct3M[2] is the unsigned bit. mask upper bits.
  // Funct3M[1:0] is the size of the memory access.
  assign PAdrSwap = BigEndianM ? BigEndianPAdr : {2'b0, PAdrM};
  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off WIDTHTRUNC */
  assign BigEndianPAdr = (LLEN/4) - PAdrM - LengthM;
  /* verilator lint_on WIDTHTRUNC */
  /* verilator lint_on WIDTHEXPAND */

  always_comb
    case(Funct3M & {FpLoadStoreM, 2'b11})
      3'b000: LengthM = 5'd1;
      3'b001: LengthM = 5'd2;
      3'b010: LengthM = 5'd4;
      3'b011: LengthM = 5'd8;
      3'b100: LengthM = 5'd16;
      default: LengthM = 5'd8;
    endcase

  if (LLEN == 128) begin:swrmux
    logic [31:0] WordM;
    logic [63:0] DblWordM;
    logic [63:0] QdWordM;
    always_comb
      case(PAdrSwap)
        5'b00000: QdWordM = ReadDataWordMuxM[127:0];
        5'b00001: QdWordM = ReadDataWordMuxM[135:8];
        5'b00010: QdWordM = ReadDataWordMuxM[143:16];
        5'b00011: QdWordM = ReadDataWordMuxM[151:24];
        5'b00100: QdWordM = ReadDataWordMuxM[159:32];
        5'b00101: QdWordM = ReadDataWordMuxM[167:40];
        5'b00110: QdWordM = ReadDataWordMuxM[175:48];
        5'b00111: QdWordM = ReadDataWordMuxM[183:56];
        5'b01000: QdWordM = ReadDataWordMuxM[191:64];
        5'b01001: QdWordM = ReadDataWordMuxM[199:72];
        5'b01010: QdWordM = ReadDataWordMuxM[207:80];
        5'b01011: QdWordM = ReadDataWordMuxM[215:88];
        5'b01100: QdWordM = ReadDataWordMuxM[223:96];
        5'b01101: QdWordM = ReadDataWordMuxM[231:104];
        5'b01110: QdWordM = ReadDataWordMuxM[239:112];
        5'b01111: QdWordM = ReadDataWordMuxM[247:120];
        5'b10000: QdWordM = ReadDataWordMuxM[255:128];
        5'b10001: QdWordM = {8'b0, ReadDataWordMuxM[255:136]};
        5'b10010: QdWordM = {16'b0, ReadDataWordMuxM[255:144]};        
        5'b10011: QdWordM = {24'b0, ReadDataWordMuxM[255:152]};        
        5'b10100: QdWordM = {32'b0, ReadDataWordMuxM[255:160]};        
        5'b10101: QdWordM = {40'b0, ReadDataWordMuxM[255:168]};        
        5'b10110: QdWordM = {48'b0, ReadDataWordMuxM[255:176]};        
        5'b10111: QdWordM = {56'b0, ReadDataWordMuxM[255:184]};        
        5'b11000: QdWordM = {64'b0, ReadDataWordMuxM[255:192]};        
        5'b11001: QdWordM = {72'b0, ReadDataWordMuxM[255:200]};        
        5'b11010: QdWordM = {80'b0, ReadDataWordMuxM[255:208]};        
        5'b11011: QdWordM = {88'b0, ReadDataWordMuxM[255:216]};        
        5'b11100: QdWordM = {96'b0, ReadDataWordMuxM[255:224]};        
        5'b11101: QdWordM = {104'b0, ReadDataWordMuxM[255:232]};        
        5'b11110: QdWordM = {112'b0, ReadDataWordMuxM[255:240]};        
        5'b11111: QdWordM = {120'b0, ReadDataWordMuxM[255:248]};
      endcase

  assign ByteM = QdWordM[7:0];
  assign HalfwordM = QdWordM[15:0];
  assign WordM = QdWordM[31:0];
  assign DblWordM = QdWordM[63:0];

    // sign extension/ NaN boxing
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                              // lb
      3'b001:  ReadDataM = {{LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]}; // lh/flh
      3'b010:  ReadDataM = {{LLEN-32{WordM[31]|FpLoadStoreM}}, WordM[31:0]};         // lw/flw
      3'b011:  ReadDataM = {{LLEN-64{DblWordM[63]|FpLoadStoreM}}, DblWordM[63:0]};   // ld/fld
      3'b100:  ReadDataM = {{LLEN-8{1'b0}}, ByteM[7:0]};                             // lbu
    //3'b100:  ReadDataM = FpLoadStoreM ? ReadDataWordMuxM : {{LLEN-8{1'b0}}, ByteM[7:0]}; // lbu/flq   - only needed when LLEN=128
      3'b101:  ReadDataM = {{LLEN-16{1'b0}}, HalfwordM[15:0]};                       // lhu
      3'b110:  ReadDataM = {{LLEN-32{1'b0}}, WordM[31:0]};                           // lwu
      default: ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                              // Shouldn't happen
    endcase

  end else if (LLEN == 64) begin:swrmux
    logic [31:0] WordM;
    logic [63:0] DblWordM;
    always_comb
      case(PAdrSwap[3:0])
        4'b0000: DblWordM = ReadDataWordMuxM[63:0];
        4'b0001: DblWordM = ReadDataWordMuxM[71:8];
        4'b0010: DblWordM = ReadDataWordMuxM[79:16];
        4'b0011: DblWordM = ReadDataWordMuxM[87:24];
        4'b0100: DblWordM = ReadDataWordMuxM[95:32];
        4'b0101: DblWordM = ReadDataWordMuxM[103:40];
        4'b0110: DblWordM = ReadDataWordMuxM[111:48];
        4'b0111: DblWordM = ReadDataWordMuxM[119:56];
        4'b1000: DblWordM = ReadDataWordMuxM[127:64];
        4'b1001: DblWordM = {8'b0, ReadDataWordMuxM[127:72]};
        4'b1010: DblWordM = {16'b0, ReadDataWordMuxM[127:80]};
        4'b1011: DblWordM = {24'b0, ReadDataWordMuxM[127:88]};
        4'b1100: DblWordM = {32'b0, ReadDataWordMuxM[127:96]};
        4'b1101: DblWordM = {40'b0, ReadDataWordMuxM[127:104]};
        4'b1110: DblWordM = {48'b0, ReadDataWordMuxM[127:112]};
        4'b1111: DblWordM = {56'b0, ReadDataWordMuxM[127:120]};
      endcase

  assign ByteM = DblWordM[7:0];
  assign HalfwordM = DblWordM[15:0];
  assign WordM = DblWordM[31:0];

    // sign extension/ NaN boxing
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                              // lb
      3'b001:  ReadDataM = {{LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]}; // lh/flh
      3'b010:  ReadDataM = {{LLEN-32{WordM[31]|FpLoadStoreM}}, WordM[31:0]};         // lw/flw
      3'b011:  ReadDataM = {{LLEN-64{DblWordM[63]|FpLoadStoreM}}, DblWordM[63:0]};   // ld/fld
      3'b100:  ReadDataM = {{LLEN-8{1'b0}}, ByteM[7:0]};                             // lbu
    //3'b100:  ReadDataM = FpLoadStoreM ? ReadDataWordMuxM : {{LLEN-8{1'b0}}, ByteM[7:0]}; // lbu/flq   - only needed when LLEN=128
      3'b101:  ReadDataM = {{LLEN-16{1'b0}}, HalfwordM[15:0]};                       // lhu
      3'b110:  ReadDataM = {{LLEN-32{1'b0}}, WordM[31:0]};                           // lwu
      default: ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                              // Shouldn't happen
    endcase

  end else begin:swrmux // 32-bit

  logic [31:0] WordM;
  always_comb
    case(PAdrSwap[2:0])
      3'b000: WordM = ReadDataWordMuxM[31:0];
      3'b001: WordM = ReadDataWordMuxM[39:8];
      3'b010: WordM = ReadDataWordMuxM[47:16];
      3'b011: WordM = ReadDataWordMuxM[55:24];
      3'b100: WordM = ReadDataWordMuxM[63:32];
      3'b101: WordM = {8'b0, ReadDataWordMuxM[63:40]};
      3'b110: WordM = {16'b0, ReadDataWordMuxM[63:48]};
      3'b111: WordM = {24'b0, ReadDataWordMuxM[63:56]};
    endcase

  assign ByteM = WordM[7:0];
  assign HalfwordM = WordM[15:0];

    // sign extension
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                                            // lb
      3'b001:  ReadDataM = {{LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]};               // lh/flh
      3'b010:  ReadDataM = {{LLEN-32{ReadDataWordMuxM[31]|FpLoadStoreM}}, ReadDataWordMuxM[31:0]}; // lw/flw
      3'b011:  ReadDataM = ReadDataWordMuxM[LLEN-1:0];                                             // fld
      3'b100:  ReadDataM = {{LLEN-8{1'b0}}, ByteM[7:0]};                                           // lbu
      3'b101:  ReadDataM = {{LLEN-16{1'b0}}, HalfwordM[15:0]};                                     // lhu
      default: ReadDataM = ReadDataWordMuxM[LLEN-1:0];                                             // Shouldn't happen
    endcase
  end
endmodule

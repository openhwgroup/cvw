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

module subwordreadVar1 #(parameter LLEN) 
  (
   input logic [LLEN-1:0]          ReadDataWordMuxM,
   input logic [$clog(LLEN/8)-1:0] PAdrM,
   input logic [2:0]               Funct3M,
   input logic                     FpLoadStoreM, 
   input logic                     BigEndianM, 
   output logic [LLEN/2-1:0]       ReadDataM
);

  localparam OFFSET_LEN = $clog(LLEN/8);
  localparam HLEN = LLEN/2;
  logic [7:0]               ByteM; 
  logic [15:0]              HalfwordM;
  logic [OFFSET_LEN-1:0]    PAdrSwap;
  // Funct3M[2] is the unsigned bit. mask upper bits.
  // Funct3M[1:0] is the size of the memory access.
  assign PAdrSwap = PAdrM ^ {OFFSET_LEN{BigEndianM}};

  if (LLEN == 128) begin:swrmux
    // ByteMe mux
    always_comb
    case(PAdrSwap[3:0])
      4'b0000: ByteM = ReadDataWordMuxM[7:0];
      4'b0001: ByteM = ReadDataWordMuxM[15:8];
      4'b0010: ByteM = ReadDataWordMuxM[23:16];
      4'b0011: ByteM = ReadDataWordMuxM[31:24];
      4'b0100: ByteM = ReadDataWordMuxM[39:32];
      4'b0101: ByteM = ReadDataWordMuxM[47:40];
      4'b0110: ByteM = ReadDataWordMuxM[55:48];
      4'b0111: ByteM = ReadDataWordMuxM[63:56];
      4'b1000: ByteM = ReadDataWordMuxM[71:64];      
      4'b1001: ByteM = ReadDataWordMuxM[79:72];      
      4'b1010: ByteM = ReadDataWordMuxM[87:80];      
      4'b1011: ByteM = ReadDataWordMuxM[95:88];      
      4'b1100: ByteM = ReadDataWordMuxM[103:96];      
      4'b1101: ByteM = ReadDataWordMuxM[111:104];      
      4'b1110: ByteM = ReadDataWordMuxM[119:112];      
      4'b1111: ByteM = ReadDataWordMuxM[127:120];      
    endcase
  
    // halfword mux
    always_comb
    case(PAdrSwap[3:0])
      4'b0000: HalfwordM = ReadDataWordMuxM[15:0];
      4'b0001: HalfwordM = ReadDataWordMuxM[23:8];
      4'b0010: HalfwordM = ReadDataWordMuxM[31:16];
      4'b0011: HalfwordM = ReadDataWordMuxM[39:24];
      4'b0100: HalfwordM = ReadDataWordMuxM[47:32];
      4'b0101: HalfwordM = ReadDataWordMuxM[55:40];
      4'b0110: HalfwordM = ReadDataWordMuxM[63:48];
      4'b0111: HalfwordM = ReadDataWordMuxM[71:56];
      4'b1000: HalfwordM = ReadDataWordMuxM[79:64];
      4'b1001: HalfwordM = ReadDataWordMuxM[87:72];
      4'b1010: HalfwordM = ReadDataWordMuxM[95:80];
      4'b1011: HalfwordM = ReadDataWordMuxM[103:88];
      4'b1100: HalfwordM = ReadDataWordMuxM[111:96];
      4'b1101: HalfwordM = ReadDataWordMuxM[119:104];
      4'b1110: HalfwordM = ReadDataWordMuxM[127:112];
      //4'b1111: HalfwordM = {ReadDataWordMuxM[7:0], ReadDataWordMuxM[127:120]}; // *** might be ok to zero extend rather than wrap around
      4'b1111: HalfwordM = {8'b0, ReadDataWordMuxM[127:120]}; // *** might be ok to zero extend rather than wrap around
    endcase
    
    logic [31:0] WordM;
    
    always_comb
      case(PAdrSwap[3:0])
        4'b0000: WordM = ReadDataWordMuxM[31:0];
        4'b0001: WordM = ReadDataWordMuxM[39:8];
        4'b0010: WordM = ReadDataWordMuxM[47:16];
        4'b0011: WordM = ReadDataWordMuxM[55:24];
        4'b0100: WordM = ReadDataWordMuxM[63:32];
        4'b0101: WordM = ReadDataWordMuxM[71:40];
        4'b0111: WordM = ReadDataWordMuxM[79:48];
        4'b1000: WordM = ReadDataWordMuxM[87:56];
        4'b1001: WordM = ReadDataWordMuxM[95:64];
        4'b1010: WordM = ReadDataWordMuxM[103:72];
        4'b1011: WordM = ReadDataWordMuxM[111:80];
        4'b1011: WordM = ReadDataWordMuxM[119:88];
        4'b1100: WordM = ReadDataWordMuxM[127:96];
        4'b1101: WordM = {8'b0, ReadDataWordMuxM[127:104]};
        4'b1110: WordM = {16'b0, ReadDataWordMuxM[127:112]};
        4'b1111: WordM = {24'b0, ReadDataWordMuxM[127:120]};
      endcase

    logic [63:0] DblWordM;
    always_comb
      case(PAdrSwap[3:0])
        4'b0000: DblWordMM = ReadDataWordMuxM[63:0];
        4'b0001: DblWordMM = ReadDataWordMuxM[71:8];
        4'b0010: DblWordMM = ReadDataWordMuxM[79:16];
        4'b0011: DblWordMM = ReadDataWordMuxM[87:24];
        4'b0100: DblWordMM = ReadDataWordMuxM[95:32];
        4'b0101: DblWordMM = ReadDataWordMuxM[103:40];
        4'b0111: DblWordMM = ReadDataWordMuxM[111:48];
        4'b1000: DblWordMM = ReadDataWordMuxM[119:56];
        4'b1001: DblWordMM = ReadDataWordMuxM[127:64];
        4'b1010: DblWordMM = {8'b0, ReadDataWordMuxM[103:72]};
        4'b1011: DblWordMM = {16'b0, ReadDataWordMuxM[111:80]};
        4'b1011: DblWordMM = {24'b0, ReadDataWordMuxM[119:88]};
        4'b1100: DblWordMM = {32'b0, ReadDataWordMuxM[127:96]};
        4'b1101: DblWordMM = {40'b0, ReadDataWordMuxM[127:104]};
        4'b1110: DblWordMM = {48'b0, ReadDataWordMuxM[127:112]};
        4'b1111: DblWordMM = {56'b0, ReadDataWordMuxM[127:120]};
      endcase

    // sign extension/ NaN boxing
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{HLEN-8{ByteM[7]}}, ByteM};                              // lb
      3'b001:  ReadDataM = {{HLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]}; // lh/flh
      3'b010:  ReadDataM = {{HLEN-32{WordM[31]|FpLoadStoreM}}, WordM[31:0]};         // lw/flw
      3'b011:  ReadDataM = {{HLEN-64{DblWordM[63]|FpLoadStoreM}}, DblWordM[63:0]};   // ld/fld
      3'b100:  ReadDataM = {{HLEN-8{1'b0}}, ByteM[7:0]};                             // lbu
    //3'b100:  ReadDataM = FpLoadStoreM ? ReadDataWordMuxM : {{HLEN-8{1'b0}}, ByteM[7:0]}; // lbu/flq   - only needed when LLEN=128
      3'b101:  ReadDataM = {{HLEN-16{1'b0}}, HalfwordM[15:0]};                       // lhu
      3'b110:  ReadDataM = {{HLEN-32{1'b0}}, WordM[31:0]};                           // lwu
      default: ReadDataM = ReadDataWordMuxM[HLEN-1:0];                                         // Shouldn't happen
    endcase

  end else if (LLEN == 64) begin:swrmux
    // ByteMe mux
    always_comb
    case(PAdrSwap[2:0])
      3'b000: ByteM = ReadDataWordMuxM[7:0];
      3'b001: ByteM = ReadDataWordMuxM[15:8];
      3'b010: ByteM = ReadDataWordMuxM[23:16];
      3'b011: ByteM = ReadDataWordMuxM[31:24];
      3'b100: ByteM = ReadDataWordMuxM[39:32];
      3'b101: ByteM = ReadDataWordMuxM[47:40];
      3'b110: ByteM = ReadDataWordMuxM[55:48];
      3'b111: ByteM = ReadDataWordMuxM[63:56];
    endcase
  
    // halfword mux
    always_comb
    case(PAdrSwap[2:0])
      3'b000: HalfwordM = ReadDataWordMuxM[15:0];
      3'b001: HalfwordM = ReadDataWordMuxM[23:8];
      3'b010: HalfwordM = ReadDataWordMuxM[31:16];
      3'b011: HalfwordM = ReadDataWordMuxM[39:24];
      3'b100: HalfwordM = ReadDataWordMuxM[47:32];
      3'b011: HalfwordM = ReadDataWordMuxM[55:40];
      3'b110: HalfwordM = ReadDataWordMuxM[63:48];
      3'b011: HalfwordM = {8'b0, ReadDataWordMuxM[63:56]};
    endcase
    
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

    logic [63:0] DblWordM;
    always_comb
      case(PAdrSwap[2:0])
        3'b000: DblWordMM = ReadDataWordMuxM[63:0];
        3'b001: DblWordMM = {8'b0, ReadDataWordMuxM[63:8]};
        3'b010: DblWordMM = {16'b0, ReadDataWordMuxM[63:16]};
        3'b011: DblWordMM = {24'b0, ReadDataWordMuxM[63:24]};
        3'b100: DblWordMM = {32'b0, ReadDataWordMuxM[63:32]};
        3'b101: DblWordMM = {40'b0, ReadDataWordMuxM[63:40]};
        3'b110: DblWordMM = {48'b0, ReadDataWordMuxM[63:48]};
        3'b111: DblWordMM = {56'b0, ReadDataWordMuxM[63:56]};
      endcase

    // sign extension/ NaN boxing
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{HLEN-8{ByteM[7]}}, ByteM};                              // lb
      3'b001:  ReadDataM = {{HLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]}; // lh/flh
      3'b010:  ReadDataM = {{HLEN-32{WordM[31]|FpLoadStoreM}}, WordM[31:0]};         // lw/flw
      3'b011:  ReadDataM = {{HLEN-64{DblWordM[63]|FpLoadStoreM}}, DblWordM[63:0]};   // ld/fld
      3'b100:  ReadDataM = {{HLEN-8{1'b0}}, ByteM[7:0]};                             // lbu
    //3'b100:  ReadDataM = FpLoadStoreM ? ReadDataWordMuxM : {{HLEN-8{1'b0}}, ByteM[7:0]}; // lbu/flq   - only needed when LLEN=128
      3'b101:  ReadDataM = {{HLEN-16{1'b0}}, HalfwordM[15:0]};                       // lhu
      3'b110:  ReadDataM = {{HLEN-32{1'b0}}, WordM[31:0]};                           // lwu
      default: ReadDataM = ReadDataWordMuxM;                                         // Shouldn't happen
    endcase

  end else begin:swrmux // 32-bit
    // byte mux
    always_comb
    case(PAdrSwap[1:0])
      2'b00: ByteM = ReadDataWordMuxM[7:0];
      2'b01: ByteM = ReadDataWordMuxM[15:8];
      2'b10: ByteM = ReadDataWordMuxM[23:16];
      2'b11: ByteM = ReadDataWordMuxM[31:24];
    endcase
  
    // halfword mux
    always_comb
    case(PAdrSwap[1:0])
      2'b00: HalfwordM = ReadDataWordMuxM[15:0];
      2'b01: HalfwordM = ReadDataWordMuxM[23:8];
      2'b10: HalfwordM = ReadDataWordMuxM[31:16];
      2'b11: HalfwordM = {8'b0, ReadDataWordMuxM[31:24]};
    endcase

    // sign extension
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{HLEN-8{ByteM[7]}}, ByteM};                                            // lb
      3'b001:  ReadDataM = {{HLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]};               // lh/flh
      3'b010:  ReadDataM = {{HLEN-32{ReadDataWordMuxM[31]|FpLoadStoreM}}, ReadDataWordMuxM[31:0]}; // lw/flw
      3'b011:  ReadDataM = ReadDataWordMuxM;                                                        // fld
      3'b100:  ReadDataM = {{HLEN-8{1'b0}}, ByteM[7:0]};                                           // lbu
      3'b101:  ReadDataM = {{HLEN-16{1'b0}}, HalfwordM[15:0]};                                     // lhu
      default: ReadDataM = ReadDataWordMuxM;                                                        // Shouldn't happen
    endcase
  end
endmodule

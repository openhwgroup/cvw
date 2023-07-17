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

module subwordread #(parameter LLEN) 
  (
   input logic [LLEN-1:0]   ReadDataWordMuxM,
   input logic [2:0]        PAdrM,
   input logic [2:0]        Funct3M,
   input logic              FpLoadStoreM, 
   input logic              BigEndianM, 
   output logic [LLEN-1:0]  ReadDataM
);

  logic [7:0]               ByteM; 
  logic [15:0]              HalfwordM;
  logic [2:0]               PAdrSwap;
  // Funct3M[2] is the unsigned bit. mask upper bits.
  // Funct3M[1:0] is the size of the memory access.
  assign PAdrSwap = PAdrM ^ {3{BigEndianM}};

  if (LLEN == 64) begin:swrmux
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
    case(PAdrSwap[2:1])
      2'b00: HalfwordM = ReadDataWordMuxM[15:0];
      2'b01: HalfwordM = ReadDataWordMuxM[31:16];
      2'b10: HalfwordM = ReadDataWordMuxM[47:32];
      2'b11: HalfwordM = ReadDataWordMuxM[63:48];
    endcase
    
    logic [31:0] WordM;
    
    always_comb
      case(PAdrSwap[2])
        1'b0: WordM = ReadDataWordMuxM[31:0];
        1'b1: WordM = ReadDataWordMuxM[63:32];
      endcase

    logic [63:0] DblWordM;
    assign DblWordM = ReadDataWordMuxM[63:0];

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
    case(PAdrSwap[1])
      1'b0: HalfwordM = ReadDataWordMuxM[15:0];
      1'b1: HalfwordM = ReadDataWordMuxM[31:16];
    endcase

    // sign extension
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                                            // lb
      3'b001:  ReadDataM = {{LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]};               // lh/flh
      3'b010:  ReadDataM = {{LLEN-32{ReadDataWordMuxM[31]|FpLoadStoreM}}, ReadDataWordMuxM[31:0]}; // lw/flw
      3'b011:  ReadDataM = ReadDataWordMuxM;                                                        // fld
      3'b100:  ReadDataM = {{LLEN-8{1'b0}}, ByteM[7:0]};                                           // lbu
      3'b101:  ReadDataM = {{LLEN-16{1'b0}}, HalfwordM[15:0]};                                     // lhu
      default: ReadDataM = ReadDataWordMuxM;                                                        // Shouldn't happen
    endcase
  end
endmodule

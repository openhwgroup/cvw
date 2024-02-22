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

module subwordreadmisaligned #(parameter LLEN) 
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
  logic [31:0]              WordM;
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

  logic [LLEN*2-1:0]        ReadDataAlignedM;
  assign ReadDataAlignedM = ReadDataWordMuxM >> (PAdrSwap[$clog2(LLEN/4)-1:0] * 8);
  
  assign ByteM = ReadDataAlignedM[7:0];
  assign HalfwordM = ReadDataAlignedM[15:0];
  assign WordM = ReadDataAlignedM[31:0];

  if (LLEN == 128) begin:swrmux
    logic [63:0] DblWordM;
    logic [127:0] QdWordM;
    
    assign DblWordM = ReadDataAlignedM[63:0];
    assign QdWordM =ReadDataAlignedM[127:0];

    // sign extension/ NaN boxing
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                              // lb
      3'b001:  ReadDataM = {{LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]}; // lh/flh
      3'b010:  ReadDataM = {{LLEN-32{WordM[31]|FpLoadStoreM}}, WordM[31:0]};         // lw/flw
      3'b011:  ReadDataM = {{LLEN-64{DblWordM[63]|FpLoadStoreM}}, DblWordM[63:0]};   // ld/fld
      3'b100:  ReadDataM = {{LLEN-8{1'b0}}, ByteM[7:0]};                             // lbu
      3'b100:  ReadDataM = FpLoadStoreM ? QdWordM : {{LLEN-8{1'b0}}, ByteM[7:0]};    // lbu/flq   - only needed when LLEN=128
      3'b101:  ReadDataM = {{LLEN-16{1'b0}}, HalfwordM[15:0]};                       // lhu
      3'b110:  ReadDataM = {{LLEN-32{1'b0}}, WordM[31:0]};                           // lwu
      default: ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                              // Shouldn't happen
    endcase

  end else if (LLEN == 64) begin:swrmux
    logic [63:0] DblWordM;

    assign DblWordM = ReadDataAlignedM[63:0];

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

    // sign extension
    always_comb
    case(Funct3M)
      3'b000:  ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                                            // lb
      3'b001:  ReadDataM = {{LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]};               // lh/flh
      3'b010:  ReadDataM = {{LLEN-32{WordM[31]|FpLoadStoreM}}, WordM[31:0]};                       // lw/flw

      3'b011:  ReadDataM = WordM[LLEN-1:0];                                                        // fld

      3'b100:  ReadDataM = {{LLEN-8{1'b0}}, ByteM[7:0]};                                           // lbu
      3'b101:  ReadDataM = {{LLEN-16{1'b0}}, HalfwordM[15:0]};                                     // lhu

      default: ReadDataM = {{LLEN-8{ByteM[7]}}, ByteM};                                            // Shouldn't happen
    endcase
  end
endmodule

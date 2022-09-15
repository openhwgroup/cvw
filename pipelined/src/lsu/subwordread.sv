///////////////////////////////////////////
// subwordread.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Extract subwords and sign extend for reads
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

module subwordread 
  (
   input logic [`LLEN-1:0] 	ReadDataWordMuxM,
   input logic [2:0] 		PAdrM,
   input logic [2:0] 		Funct3M,
   input logic              FpLoadStoreM, 
   input logic              BigEndianM, 
   output logic [`LLEN-1:0] ReadDataM
   );

  logic [7:0] 				ByteM; 
  logic [15:0] 				HalfwordM;
  logic [2:0]               PAdrSwap;
  // Funct3M[2] is the unsigned bit. mask upper bits.
  // Funct3M[1:0] is the size of the memory access.
  assign PAdrSwap = PAdrM ^ {3{BigEndianM}};

  if (`XLEN == 64) begin:swrmux
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
      3'b000:  ReadDataM = {{`LLEN-8{ByteM[7]}}, ByteM};                              // lb
      3'b001:  if(`ZFH_SUPPORTED) 
                    ReadDataM = {{`LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]}; // lh/flh
               else ReadDataM = {{`LLEN-16{HalfwordM[15]}}, HalfwordM[15:0]};         // lh 
      3'b010:  if(`F_SUPPORTED) 
                    ReadDataM = {{`LLEN-32{WordM[31]|FpLoadStoreM}}, WordM[31:0]};         // lw/flw
               else ReadDataM = {{`LLEN-32{WordM[31]}}, WordM[31:0]};                 // lw
      3'b011:  if(`D_SUPPORTED) 
                    ReadDataM = {{`LLEN-64{DblWordM[63]|FpLoadStoreM}}, DblWordM[63:0]};   // ld/fld
               else ReadDataM = {{`LLEN-64{DblWordM[63]}}, DblWordM[63:0]};           // ld/fld
      3'b100:    if(`Q_SUPPORTED) 
                    ReadDataM = FpLoadStoreM ? ReadDataWordMuxM : {{`LLEN-8{1'b0}}, ByteM[7:0]}; // lbu/flq
                 else 
                    ReadDataM = {{`LLEN-8{1'b0}}, ByteM[7:0]};    // lbu
      3'b101:  ReadDataM = {{`LLEN-16{1'b0}}, HalfwordM[15:0]};   // lhu
      3'b110:  ReadDataM = {{`LLEN-32{1'b0}}, WordM[31:0]};       // lwu
      default: ReadDataM = ReadDataWordMuxM; // Shouldn't happen
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
      3'b000:  ReadDataM = {{`LLEN-8{ByteM[7]}}, ByteM};                              // lb
      3'b001:  if(`ZFH_SUPPORTED) 
                    ReadDataM = {{`LLEN-16{HalfwordM[15]|FpLoadStoreM}}, HalfwordM[15:0]}; // lh/flh
               else ReadDataM = {{`LLEN-16{HalfwordM[15]}}, HalfwordM[15:0]};         // lh 
      3'b010:  if(`F_SUPPORTED) 
                    ReadDataM = {{`LLEN-32{ReadDataWordMuxM[31]|FpLoadStoreM}}, ReadDataWordMuxM[31:0]};         // lw/flw
               else ReadDataM = {{`LLEN-32{ReadDataWordMuxM[31]}}, ReadDataWordMuxM[31:0]};                 // lw
      3'b011:  ReadDataM = ReadDataWordMuxM;                      // fld
      3'b100:  ReadDataM = {{`LLEN-8{1'b0}}, ByteM[7:0]};         // lbu
      3'b101:  ReadDataM = {{`LLEN-16{1'b0}}, HalfwordM[15:0]};   // lhu
      default: ReadDataM = ReadDataWordMuxM; // Shouldn't happen
    endcase
  end
endmodule

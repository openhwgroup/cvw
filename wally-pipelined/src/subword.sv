///////////////////////////////////////////
// subword.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Masking and muxing for subword accesses
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

module subword (
  input  logic [1:0]       MemRWM,
  input  logic [`XLEN-1:0] ReadDataUnmaskedM,
  input  logic [`XLEN-1:0] AdrM,
  input  logic [2:0]       Funct3M,
  output logic [`XLEN-1:0] ReadDataM,
  input  logic [`XLEN-1:0] WriteDataM,
  output logic [`XLEN-1:0] MaskedWriteDataM
);
                  
  logic [7:0]  ByteM; // *** declare locally to generate as either 4 or 8 bits
  logic [15:0] HalfwordM;
  logic [`XLEN-1:0] WriteDataSubwordDuplicated;
  logic [7:0]      ByteMaskM;
  
  generate
    if (`XLEN == 64) begin
      // ByteMe mux
      always_comb
      case(AdrM[2:0])
        3'b000: ByteM = ReadDataUnmaskedM[7:0];
        3'b001: ByteM = ReadDataUnmaskedM[15:8];
        3'b010: ByteM = ReadDataUnmaskedM[23:16];
        3'b011: ByteM = ReadDataUnmaskedM[31:24];
        3'b100: ByteM = ReadDataUnmaskedM[39:32];
        3'b101: ByteM = ReadDataUnmaskedM[47:40];
        3'b110: ByteM = ReadDataUnmaskedM[55:48];
        3'b111: ByteM = ReadDataUnmaskedM[63:56];
      endcase
    
      // halfword mux
      always_comb
      case(AdrM[2:1])
        2'b00: HalfwordM = ReadDataUnmaskedM[15:0];
        2'b01: HalfwordM = ReadDataUnmaskedM[31:16];
        2'b10: HalfwordM = ReadDataUnmaskedM[47:32];
        2'b11: HalfwordM = ReadDataUnmaskedM[63:48];
      endcase
      
      logic [31:0] WordM;
      
      always_comb
        case(AdrM[2])
          1'b0: WordM = ReadDataUnmaskedM[31:0];
          1'b1: WordM = ReadDataUnmaskedM[63:32];
        endcase

      // sign extension
      always_comb
      case(Funct3M) 
        3'b000:  ReadDataM = {{56{ByteM[7]}}, ByteM};                  // lb
        3'b001:  ReadDataM = {{48{HalfwordM[15]}}, HalfwordM[15:0]}; // lh 
        3'b010:  ReadDataM = {{32{WordM[31]}}, WordM[31:0]};           // lw
        3'b011:  ReadDataM = ReadDataUnmaskedM;                              // ld
        3'b100:  ReadDataM = {56'b0, ByteM[7:0]};                     // lbu
        3'b101:  ReadDataM = {48'b0, HalfwordM[15:0]};               // lhu
        3'b110:  ReadDataM = {32'b0, WordM[31:0]};                    // lwu
        default: ReadDataM = 64'b0;
      endcase
    
      // Memory control
    
      // Compute write mask
      always_comb 
        case(Funct3M)
          3'b000:  begin ByteMaskM = 8'b00000000; ByteMaskM[AdrM[2:0]] = 1; end // sb
          3'b001:  case (AdrM[2:1])
                    2'b00: ByteMaskM = 8'b00000011;
                    2'b01: ByteMaskM = 8'b00001100;
                    2'b10: ByteMaskM = 8'b00110000;
                    2'b11: ByteMaskM = 8'b11000000;
                  endcase
          3'b010:  if (AdrM[2]) ByteMaskM = 8'b11110000;
                   else        ByteMaskM = 8'b00001111;
          3'b011:  ByteMaskM = 8'b11111111;
          default: ByteMaskM = 8'b00000000;
        endcase

      // Handle subword writes
      always_comb 
        case(Funct3M)
          3'b000:  WriteDataSubwordDuplicated = {8{WriteDataM[7:0]}};  // sb
          3'b001:  WriteDataSubwordDuplicated = {4{WriteDataM[15:0]}}; // sh
          3'b010:  WriteDataSubwordDuplicated = {2{WriteDataM[31:0]}}; // sw
          3'b011:  WriteDataSubwordDuplicated = WriteDataM;            // sw
          default: WriteDataSubwordDuplicated = 64'b0;
        endcase

      always_comb begin
        MaskedWriteDataM=ReadDataUnmaskedM;
        if (ByteMaskM[0]) MaskedWriteDataM[7:0]   = WriteDataSubwordDuplicated[7:0];
        if (ByteMaskM[1]) MaskedWriteDataM[15:8]  = WriteDataSubwordDuplicated[15:8];
        if (ByteMaskM[2]) MaskedWriteDataM[23:16] = WriteDataSubwordDuplicated[23:16];
        if (ByteMaskM[3]) MaskedWriteDataM[31:24] = WriteDataSubwordDuplicated[31:24];
	      if (ByteMaskM[4]) MaskedWriteDataM[39:32] = WriteDataSubwordDuplicated[39:32];
	      if (ByteMaskM[5]) MaskedWriteDataM[47:40] = WriteDataSubwordDuplicated[47:40];
      	if (ByteMaskM[6]) MaskedWriteDataM[55:48] = WriteDataSubwordDuplicated[55:48];
	      if (ByteMaskM[7]) MaskedWriteDataM[63:56] = WriteDataSubwordDuplicated[63:56];
      end 

    end else begin // 32-bit
      // byte mux
      always_comb
      case(AdrM[1:0])
        2'b00: ByteM = ReadDataUnmaskedM[7:0];
        2'b01: ByteM = ReadDataUnmaskedM[15:8];
        2'b10: ByteM = ReadDataUnmaskedM[23:16];
        2'b11: ByteM = ReadDataUnmaskedM[31:24];
      endcase
    
      // halfword mux
      always_comb
      case(AdrM[1])
        1'b0: HalfwordM = ReadDataUnmaskedM[15:0];
        1'b1: HalfwordM = ReadDataUnmaskedM[31:16];
      endcase

      // sign extension
      always_comb
      case(Funct3M) 
        3'b000:  ReadDataM = {{24{ByteM[7]}}, ByteM};                  // lb
        3'b001:  ReadDataM = {{16{HalfwordM[15]}}, HalfwordM[15:0]}; // lh 
        3'b010:  ReadDataM = ReadDataUnmaskedM;                              // lw
        3'b100:  ReadDataM = {24'b0, ByteM[7:0]};                     // lbu
        3'b101:  ReadDataM = {16'b0, HalfwordM[15:0]};               // lhu
        default: ReadDataM = 32'b0;
      endcase
    
      // Memory control
    
      // Compute write mask
      always_comb 
        case(Funct3M)
          3'b000:  begin ByteMaskM = 8'b0000; ByteMaskM[{1'b0, AdrM[1:0]}] = 1; end // sb
          3'b001:  if (AdrM[1]) ByteMaskM = 8'b1100;
                   else         ByteMaskM = 8'b0011;
          3'b010:  ByteMaskM = 8'b1111;
          default: ByteMaskM = 8'b0000;
        endcase

      // Handle subword writes
      always_comb 
        case(Funct3M)
          3'b000:  WriteDataSubwordDuplicated = {4{WriteDataM[7:0]}};  // sb
          3'b001:  WriteDataSubwordDuplicated = {2{WriteDataM[15:0]}}; // sh
          3'b010:  WriteDataSubwordDuplicated = WriteDataM;            // sw
          default: WriteDataSubwordDuplicated = 32'b0;
        endcase

      always_comb begin
        MaskedWriteDataM=ReadDataUnmaskedM;
        if (ByteMaskM[0]) MaskedWriteDataM[7:0]   = WriteDataSubwordDuplicated[7:0];
        if (ByteMaskM[1]) MaskedWriteDataM[15:8]  = WriteDataSubwordDuplicated[15:8];
        if (ByteMaskM[2]) MaskedWriteDataM[23:16] = WriteDataSubwordDuplicated[23:16];
        if (ByteMaskM[3]) MaskedWriteDataM[31:24] = WriteDataSubwordDuplicated[31:24];
      end 

    end
  endgenerate

endmodule

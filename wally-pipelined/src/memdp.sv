///////////////////////////////////////////
// memdp.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Memory datapath for subword accesses
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

module memdp (
  input  logic [1:0]      MemRWM,
  input  logic [`XLEN-1:0] ReadDataM,
  input  logic [`XLEN-1:0] AdrM,
  input  logic [2:0]      Funct3M,
  output logic [`XLEN-1:0] ReadDataExtM,
  input  logic [`XLEN-1:0] WriteDataFullM,
  output logic [`XLEN-1:0] WriteDataM,
  output logic [7:0]      ByteMaskM,
  input  logic            DataAccessFaultM,
  output logic            LoadMisalignedFaultM, LoadAccessFaultM,
  output logic            StoreMisalignedFaultM, StoreAccessFaultM);
                  
  logic [7:0]  bytM;
  logic [15:0] HalfwordM;
  logic        UnalignedM;
  
  generate
    if (`XLEN == 64) begin
      // bytMe mux
      always_comb
      case(AdrM[2:0])
        3'b000: bytM = ReadDataM[7:0];
        3'b001: bytM = ReadDataM[15:8];
        3'b010: bytM = ReadDataM[23:16];
        3'b011: bytM = ReadDataM[31:24];
        3'b100: bytM = ReadDataM[39:32];
        3'b101: bytM = ReadDataM[47:40];
        3'b110: bytM = ReadDataM[55:48];
        3'b111: bytM = ReadDataM[63:56];
      endcase
    
      // halfword mux
      always_comb
      case(AdrM[2:1])
        2'b00: HalfwordM = ReadDataM[15:0];
        2'b01: HalfwordM = ReadDataM[31:16];
        2'b10: HalfwordM = ReadDataM[47:32];
        2'b11: HalfwordM = ReadDataM[63:48];
      endcase
      
      logic [31:0] word;
      
      always_comb
        case(AdrM[2])
          1'b0: word = ReadDataM[31:0];
          1'b1: word = ReadDataM[63:32];
        endcase

      // sign extension
      always_comb
      case(Funct3M) 
        3'b000:  ReadDataExtM = {{56{bytM[7]}}, bytM};                  // lb
        3'b001:  ReadDataExtM = {{48{HalfwordM[15]}}, HalfwordM[15:0]}; // lh 
        3'b010:  ReadDataExtM = {{32{word[31]}}, word[31:0]};           // lw
        3'b011:  ReadDataExtM = ReadDataM;                              // ld
        3'b100:  ReadDataExtM = {56'b0, bytM[7:0]};                     // lbu
        3'b101:  ReadDataExtM = {48'b0, HalfwordM[15:0]};               // lhu
        3'b110:  ReadDataExtM = {32'b0, word[31:0]};                    // lwu
        default: ReadDataExtM = 64'b0;
      endcase
    
      // Memory control
    
      // Compute write mask
      always_comb 
        if (StoreMisalignedFaultM || StoreAccessFaultM) ByteMaskM = 8'b00000000; // discard Unaligned stores
        else case(Funct3M)
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
        3'b000:  WriteDataM = {8{WriteDataFullM[7:0]}};  // sb
        3'b001:  WriteDataM = {4{WriteDataFullM[15:0]}}; // sh
        3'b010:  WriteDataM = {2{WriteDataFullM[31:0]}}; // sw
        3'b011:  WriteDataM = WriteDataFullM;            // sw
        default: WriteDataM = 64'b0;
      endcase
     
    end else begin // 32-bit
      // byte mux
      always_comb
      case(AdrM[1:0])
        2'b00: bytM = ReadDataM[7:0];
        2'b01: bytM = ReadDataM[15:8];
        2'b10: bytM = ReadDataM[23:16];
        2'b11: bytM = ReadDataM[31:24];
      endcase
    
      // halfword mux
      always_comb
      case(AdrM[1])
        1'b0: HalfwordM = ReadDataM[15:0];
        1'b1: HalfwordM = ReadDataM[31:16];
      endcase

      // sign extension
      always_comb
      case(Funct3M) 
        3'b000:  ReadDataExtM = {{24{bytM[7]}}, bytM};                  // lb
        3'b001:  ReadDataExtM = {{16{HalfwordM[15]}}, HalfwordM[15:0]}; // lh 
        3'b010:  ReadDataExtM = ReadDataM;                              // lw
        3'b100:  ReadDataExtM = {24'b0, bytM[7:0]};                     // lbu
        3'b101:  ReadDataExtM = {16'b0, HalfwordM[15:0]};               // lhu
        default: ReadDataExtM = 32'b0;
      endcase
    
      // Memory control
    
      // Compute write mask
      always_comb 
        if (StoreMisalignedFaultM || StoreAccessFaultM) ByteMaskM = 8'b0000; // discard Unaligned stores
        else case(Funct3M)
          3'b000:  begin ByteMaskM = 8'b0000; ByteMaskM[{1'b0,AdrM[1:0]}] = 1; end // sb
          3'b001:  if (AdrM[1]) ByteMaskM = 8'b1100;
                   else         ByteMaskM = 8'b0011;
          3'b010:  ByteMaskM = 8'b1111;
          default: ByteMaskM = 8'b0000;
        endcase

      // Handle subword writes
      always_comb 
      case(Funct3M)
        3'b000:  WriteDataM = {4{WriteDataFullM[7:0]}};  // sb
        3'b001:  WriteDataM = {2{WriteDataFullM[15:0]}}; // sh
        3'b010:  WriteDataM = WriteDataFullM;            // sw
        default: WriteDataM = 32'b0;
      endcase
    end
  endgenerate

	// Determine if an Unaligned access is taking place
	always_comb
		case(Funct3M) 
		  3'b000:  UnalignedM = 0;                 // lb, sb
		  3'b001:  UnalignedM = AdrM[0];           // lh, sh
		  3'b010:  UnalignedM = AdrM[1] | AdrM[0]; // lw, sw, flw, fsw
		  3'b011:  UnalignedM = |AdrM[2:0];        // ld, sd, fld, fsd
		  3'b100:  UnalignedM = 0;                 // lbu
		  3'b101:  UnalignedM = AdrM[0];           // lhu
		  3'b110:  UnalignedM = |AdrM[1:0];        // lwu
		  default: UnalignedM = 0;
		endcase 

  // Determine if address is valid
  assign LoadMisalignedFaultM = UnalignedM & MemRWM[1];
  assign LoadAccessFaultM = DataAccessFaultM & MemRWM[0];
  assign StoreMisalignedFaultM = UnalignedM & MemRWM[0];
  assign StoreAccessFaultM = DataAccessFaultM & MemRWM[0];
endmodule

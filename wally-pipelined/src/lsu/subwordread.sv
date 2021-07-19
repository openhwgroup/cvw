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

module subwordread (
  // from AHB Interface
  input  logic [`XLEN-1:0] HRDATA,
  input  logic [2:0]      HADDRD,
  //input  logic             UnsignedLoadM, 
  input  logic [3:0]       HSIZED,
  // to ifu/dmems
  output logic [`XLEN-1:0] HRDATAMasked
);
                  
  logic [7:0]  ByteM; 
  logic [15:0] HalfwordM;
  
  generate
    if (`XLEN == 64) begin
      // ByteMe mux
      always_comb
      case(HADDRD[2:0])
        3'b000: ByteM = HRDATA[7:0];
        3'b001: ByteM = HRDATA[15:8];
        3'b010: ByteM = HRDATA[23:16];
        3'b011: ByteM = HRDATA[31:24];
        3'b100: ByteM = HRDATA[39:32];
        3'b101: ByteM = HRDATA[47:40];
        3'b110: ByteM = HRDATA[55:48];
        3'b111: ByteM = HRDATA[63:56];
      endcase
    
      // halfword mux
      always_comb
      case(HADDRD[2:1])
        2'b00: HalfwordM = HRDATA[15:0];
        2'b01: HalfwordM = HRDATA[31:16];
        2'b10: HalfwordM = HRDATA[47:32];
        2'b11: HalfwordM = HRDATA[63:48];
      endcase
      
      logic [31:0] WordM;
      
      always_comb
        case(HADDRD[2])
          1'b0: WordM = HRDATA[31:0];
          1'b1: WordM = HRDATA[63:32];
        endcase

      // sign extension
      always_comb
      case({HSIZED[3], HSIZED[1:0]}) // HSIZED[3] indicates unsigned load
        3'b000:  HRDATAMasked = {{56{ByteM[7]}}, ByteM};                  // lb
        3'b001:  HRDATAMasked = {{48{HalfwordM[15]}}, HalfwordM[15:0]};   // lh 
        3'b010:  HRDATAMasked = {{32{WordM[31]}}, WordM[31:0]};           // lw
        3'b011:  HRDATAMasked = HRDATA;                                   // ld
        3'b100:  HRDATAMasked = {56'b0, ByteM[7:0]};                      // lbu
        3'b101:  HRDATAMasked = {48'b0, HalfwordM[15:0]};                 // lhu
        3'b110:  HRDATAMasked = {32'b0, WordM[31:0]};                     // lwu
        default: HRDATAMasked = HRDATA; // Shouldn't happen
      endcase
    end else begin // 32-bit
      // byte mux
      always_comb
      case(HADDRD[1:0])
        2'b00: ByteM = HRDATA[7:0];
        2'b01: ByteM = HRDATA[15:8];
        2'b10: ByteM = HRDATA[23:16];
        2'b11: ByteM = HRDATA[31:24];
      endcase
    
      // halfword mux
      always_comb
      case(HADDRD[1])
        1'b0: HalfwordM = HRDATA[15:0];
        1'b1: HalfwordM = HRDATA[31:16];
      endcase

      // sign extension
      always_comb
      case({HSIZED[3], HSIZED[1:0]}) 
        3'b000:  HRDATAMasked = {{24{ByteM[7]}}, ByteM};                  // lb
        3'b001:  HRDATAMasked = {{16{HalfwordM[15]}}, HalfwordM[15:0]};   // lh 
        3'b010:  HRDATAMasked = HRDATA;                                   // lw
        3'b100:  HRDATAMasked = {24'b0, ByteM[7:0]};                      // lbu
        3'b101:  HRDATAMasked = {16'b0, HalfwordM[15:0]};                 // lhu
        default: HRDATAMasked = HRDATA;
      endcase
    end
  endgenerate
endmodule

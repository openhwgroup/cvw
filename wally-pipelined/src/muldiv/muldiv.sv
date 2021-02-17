///////////////////////////////////////////
// muldiv.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: M extension multiply and divide
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

module muldiv (
  input  logic             clk, reset,
  // Decode Stage interface
  input  logic [31:0]      InstrD, 
  // Execute Stage interface
  input  logic [`XLEN-1:0] SrcAE, SrcBE,
  input  logic [2:0]       Funct3E,
  input  logic             MulDivE, W64E,
  // Writeback stage
  output logic [`XLEN-1:0] MulDivResultW,
  // hazards
  input  logic             FlushM, FlushW 
);

  generate
    if (`M_SUPPORTED) begin
      logic [`XLEN-1:0] MulDivResultE, MulDivResultM;
      logic [`XLEN-1:0] PrelimResultE;
      logic [`XLEN-1:0] QuotE, RemE;
      logic [`XLEN*2-1:0] ProdE;

      mul mul(.*);

      if (WIDTH==32) begin
        divide4x32 div(.clk(clk), .reset(reset), 
                       .N(SrcAE), .D(SrcBE), .Q(QuotE), .rem0(RemE),
                       .start(), .div0(), .done(), .divone());
      end else begin // WIDTH=64
        divide4x64 div(.clk(clk), .reset(reset), 
                       .N(SrcAE), .D(SrcBE), .Q(QuotE), .rem0(RemE),
                       .start(), .div0(), .done(), .divone());
      end
      
      // Select result
      always_comb
        case (Funct3E)
          3'b000: PrelimResultE = ProdE[`XLEN-1:0];
          3'b001: PrelimResultE = ProdE[`XLEN*2-1:`XLEN];
          3'b010: PrelimResultE = ProdE[`XLEN*2-1:`XLEN];
          3'b011: PrelimResultE = ProdE[`XLEN*2-1:`XLEN];
          3'b100: PrelimResultE = QuotE;
          3'b101: PrelimResultE = QuotE;
          3'b110: PrelimResultE = RemE;
          3'b111: PrelimResultE = RemE;
        endcase
    
      // Handle sign extension for W-type instructions
      if (`XLEN == 64) begin // RV64 has W-type instructions
        assign MulDivResultE = W64E ? {{32{PrelimResultE[31]}}, PrelimResultE[31:0]} : PrelimResultE;
      end else begin // RV32 has no W-type instructions
        assign MulDivResultE = PrelimResultE;
      end

      floprc #(`XLEN) MulDivResultMReg(clk, reset, FlushM, MulDivResultE, MulDivResultM);
      floprc #(`XLEN) MulDivResultWReg(clk, reset, FlushW, MulDivResultM, MulDivResultW);
    end else begin // no M instructions supported
      assign MulDivResultW = 0; 
    end
  endgenerate
endmodule


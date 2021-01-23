///////////////////////////////////////////
// clint.sv
//
// Written: David_Harris@hmc.edu 14 January 2021
// Modified: 
//
// Purpose: Core-Local Interruptor
//   See FE310-G002-Manual-v19p05 for specifications
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

module clint (
  input  logic            clk, reset, 
  input  logic [1:0]      MemRWclintM,
  input  logic [15:0]     AdrM, 
  input  logic [`XLEN-1:0] MaskedWriteDataM,
  output logic [`XLEN-1:0] RdCLINTM,
  output logic            TimerIntM, SwIntM);

  logic [63:0] MTIMECMP, MTIME;
  logic        MSIP;

  logic [15:0] entry;
  logic            memread, memwrite;

  assign memread  = MemRWclintM[1];
  assign memwrite = MemRWclintM[0];
  
  // word aligned reads
  generate
    if (`XLEN==64)
      assign #2 entry = {AdrM[15:3], 3'b000};
    else
      assign #2 entry = {AdrM[15:2], 2'b00}; 
  endgenerate
  

  // register access
  generate
    if (`XLEN==64) begin
      always_comb begin
        case(entry)
          16'h0000: RdCLINTM = {63'b0, MSIP};
          16'h4000: RdCLINTM = MTIMECMP;
          16'hBFF8: RdCLINTM = MTIME;
          default:  RdCLINTM = 0;
        endcase
      end 
      always_ff @(posedge clk or posedge reset) 
        if (reset) begin
          MSIP <= 0;
          MTIME <= 0;
          // MTIMECMP is not reset
        end else begin
          if (entry == 16'h0000) MSIP <= MaskedWriteDataM[0];
          if (entry == 16'h4000) MTIMECMP <= MaskedWriteDataM;
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
          if (entry == 16'hBFF8) MTIME <= MaskedWriteDataM;
          else MTIME <= MTIME + 1;
        end
    end else begin // 32-bit
      always_comb begin
        case(entry)
          16'h0000: RdCLINTM = {31'b0, MSIP};
          16'h4000: RdCLINTM = MTIMECMP[31:0];
          16'h4004: RdCLINTM = MTIMECMP[63:32];
          16'hBFF8: RdCLINTM = MTIME[31:0];
          16'hBFFC: RdCLINTM = MTIME[63:32];
          default:  RdCLINTM = 0;
        endcase
      end 
      always_ff @(posedge clk or posedge reset) 
        if (reset) begin
          MSIP <= 0;
          MTIME <= 0;
          // MTIMECMP is not reset
        end else begin
          if (entry == 16'h0000) MSIP <= MaskedWriteDataM[0];
          if (entry == 16'h4000) MTIMECMP[31:0] <= MaskedWriteDataM;
          if (entry == 16'h4004) MTIMECMP[63:32] <= MaskedWriteDataM;
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
          if (entry == 16'hBFF8) MTIME[31:0] <= MaskedWriteDataM;
          else if (entry == 16'hBFFC) MTIME[63:32]<= MaskedWriteDataM;
          else MTIME <= MTIME + 1;
        end
    end
  endgenerate

  // Software interrupt when MSIP is set
  assign SwIntM = MSIP;
  // Timer interrupt when MTIME >= MTIMECMP
  assign TimerIntM = ({1'b0, MTIME} >= {1'b0, MTIMECMP}); // unsigned comparison

endmodule


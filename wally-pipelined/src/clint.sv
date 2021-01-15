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

`include "wally-macros.sv"

module clint #(parameter XLEN=32) (
  input  logic            clk, reset, 
  input  logic [1:0]      MemRWM,
  input  logic [7:0]      ByteMaskM,
  input  logic [15:0]     AdrM, 
  input  logic [XLEN-1:0] WdM,
  output logic [XLEN-1:0] RdM,
  output logic            TimerIntM, SwIntM);

  logic [63:0] MTIMECMP, MTIME;
  logic        MSIP;

  logic [XLEN-1:0] read, write;
  logic [15:0] entry;
  logic            memread, memwrite;

  assign memread  = MemRWM[1];
  assign memwrite = MemRWM[0];
  
  // word aligned reads
  generate
    if (XLEN==64)
      assign #2 entry = {AdrM[15:3], 3'b000};
    else
      assign #2 entry = {AdrM[15:2], 2'b00}; 
  endgenerate
  

  // register access
  generate
    if (XLEN==64) begin
      always_comb begin
        case(entry)
          16'h0000: read = {63'b0, MSIP};
          16'h4000: read = MTIMECMP;
          16'hBFF8: read = MTIME;
          default:  read = 0;
        endcase
        write=read;
        if (ByteMaskM[0]) write[7:0]   = WdM[7:0];
        if (ByteMaskM[1]) write[15:8]  = WdM[15:8];
        if (ByteMaskM[2]) write[23:16] = WdM[23:16];
        if (ByteMaskM[3]) write[31:24] = WdM[31:24];
	      if (ByteMaskM[4]) write[39:32] = WdM[39:32];
	      if (ByteMaskM[5]) write[47:40] = WdM[47:40];
      	if (ByteMaskM[6]) write[55:48] = WdM[55:48];
	      if (ByteMaskM[7]) write[63:56] = WdM[63:56];
      end 
      always_ff @(posedge clk or posedge reset) 
        if (reset) begin
          MSIP <= 0;
          MTIME <= 0;
          // MTIMECMP is not reset
        end else begin
          if (entry == 16'h0000) MSIP <= write[0];
          if (entry == 16'h4000) MTIMECMP <= write;
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
          if (entry == 16'hBFF8) MTIME <= write;
          else MTIME <= MTIME + 1;
        end
    end else begin // 32-bit
      always_comb begin
        case(entry)
          16'h0000: read = {31'b0, MSIP};
          16'h4000: read = MTIMECMP[31:0];
          16'h4004: read = MTIMECMP[63:32];
          16'hBFF8: read = MTIME[31:0];
          16'hBFFC: read = MTIME[63:32];
          default:  read = 0;
        endcase
        write=read;
        if (ByteMaskM[0]) write[7:0]   = WdM[7:0];
        if (ByteMaskM[1]) write[15:8]  = WdM[15:8];
        if (ByteMaskM[2]) write[23:16] = WdM[23:16];
        if (ByteMaskM[3]) write[31:24] = WdM[31:24];
      end 
      always_ff @(posedge clk or posedge reset) 
        if (reset) begin
          MSIP <= 0;
          MTIME <= 0;
          // MTIMECMP is not reset
        end else begin
          if (entry == 16'h0000) MSIP <= write[0];
          if (entry == 16'h4000) MTIMECMP[31:0] <= write;
          if (entry == 16'h4004) MTIMECMP[63:32] <= write;
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
          if (entry == 16'hBFF8) MTIME[31:0] <= write;
          else if (entry == 16'hBFFC) MTIME[63:32]<= write;
          else MTIME <= MTIME + 1;
        end
    end
  endgenerate

  // read
  assign RdM = memread ? read: 0;

  // Software interrupt when MSIP is set
  assign SwIntM = MSIP;
  // Timer interrupt when MTIME >= MTIMECMP
  assign TimerIntM = ({1'b0, MTIME} >= {1'b0, MTIMECMP}); // unsigned comparison

endmodule


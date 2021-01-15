///////////////////////////////////////////
// gpio.sv
//
// Written: David_Harris@hmc.edu 14 January 2021
// Modified: 
//
// Purpose: General Purpose I/O peripheral
//   See FE310-G002-Manual-v19p05 for specifications
//   No interrupts, drive strength, or pull-ups supported
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

module gpio #(parameter XLEN=32) (
  input  logic            clk, reset, 
  input  logic [1:0]      MemRWM,
  input  logic [7:0]      ByteMaskM,
  input  logic [7:0]      AdrM, 
  input  logic [XLEN-1:0] WdM,
  output logic [XLEN-1:0] RdM,
  input  logic [31:0]     GPIOPinsIn,
  output logic [31:0]     GPIOPinsOut, GPIOPinsEn);

  logic [31:0] INPUT_VAL, INPUT_EN, OUTPUT_EN, OUTPUT_VAL;
 
  logic [XLEN-1:0] read, write;
  logic [15:0] entry;
  logic            memread, memwrite;

  assign memread  = MemRWM[1];
  assign memwrite = MemRWM[0];
  
  // word aligned reads
  generate
    if (XLEN==64)
      assign #2 entry = {AdrM[7:3], 3'b000};
    else
      assign #2 entry = {AdrM[7:2], 2'b00}; 
  endgenerate
  
  assign INPUT_VAL = GPIOPinsIn & INPUT_EN;
  assign GPIOPinsOut = OUTPUT_VAL;
  assign GPIOPinsEn = OUTPUT_EN;

  // register access
  generate
    if (XLEN==64) begin
      always_comb begin
        case(entry)
          8'h00: read = {INPUT_EN, INPUT_VAL};
          8'h08: read = {OUTPUT_VAL, OUTPUT_EN};
          8'h40: read = 0; // OUT_XOR reads as 0
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
          INPUT_EN <= 0;
          OUTPUT_EN <= 0;
          // OUTPUT_VAL <= 0; // spec indicates synchronous rset (software control)
        end else begin
          if (entry == 8'h00) INPUT_EN <= write[63:32];
          if (entry == 8'h08) {OUTPUT_VAL, OUTPUT_EN} <= write;
          if (entry == 8'h40) OUTPUT_VAL <= OUTPUT_VAL ^ write[31:0]; // OUT_XOR
        end
    end else begin // 32-bit
      always_comb begin
        case(entry)
          8'h00: read = INPUT_VAL;
          8'h04: read = INPUT_EN;
          8'h08: read = OUTPUT_EN;
          8'h0C: read = OUTPUT_VAL;
          8'h40: read = 0; // OUT_XOR reads as 0
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
          INPUT_EN <= 0;
          OUTPUT_EN <= 0;
          //OUTPUT_VAL <= 0;// spec indicates synchronous rset (software control)
        end else begin
          if (entry == 8'h04) INPUT_EN <= write;
          if (entry == 8'h08) OUTPUT_EN <= write;
          if (entry == 8'h0C) OUTPUT_VAL <= write;
          if (entry == 8'h40) OUTPUT_VAL <= OUTPUT_VAL ^ write; // OUT_XOR
        end
    end
  endgenerate

  // read
  assign RdM = memread ? read: 0;
endmodule


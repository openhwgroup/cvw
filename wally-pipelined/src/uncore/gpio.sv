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

`include "wally-config.vh"

module gpio (
  input  logic             HCLK, HRESETn,
  input  logic [1:0]       MemRWgpio,
  input  logic [7:0]       HADDR, 
  input  logic [`XLEN-1:0] HWDATA,
  output logic [`XLEN-1:0] HREADGPIO,
  output logic             HRESPGPIO, HREADYGPIO,
  input  logic [31:0]      GPIOPinsIn,
  output logic [31:0]      GPIOPinsOut, GPIOPinsEn);

  logic [31:0] INPUT_VAL, INPUT_EN, OUTPUT_EN, OUTPUT_VAL;
 
  logic [7:0] entry;
  logic            memread, memwrite;

  assign memread  = MemRWgpio[1];
  assign memwrite = MemRWgpio[0];
  assign HRESPGPIO = 0; // OK
  always_ff @(posedge HCLK) // delay response to data cycle
    HREADYGPIO <= memread | memwrite;
//  assign HREADYGPIO = 1; // Respond immediately
  
  // word aligned reads
  generate
    if (`XLEN==64)
      assign #2 entry = {HADDR[7:3], 3'b000};
    else
      assign #2 entry = {HADDR[7:2], 2'b00}; 
  endgenerate
  
  generate 
    if (`GPIO_LOOPBACK_TEST) // connect OUT to IN for loopback testing
      assign INPUT_VAL = GPIOPinsOut & INPUT_EN & OUTPUT_EN;
    else
      assign INPUT_VAL = GPIOPinsIn & INPUT_EN;
  endgenerate
  assign GPIOPinsOut = OUTPUT_VAL;
  assign GPIOPinsEn = OUTPUT_EN;

  // register access
  generate
    if (`XLEN==64) begin
      always_ff @(posedge HCLK) begin
        case(entry)
          8'h00: HREADGPIO <= {INPUT_EN, INPUT_VAL};
          8'h08: HREADGPIO <= {OUTPUT_VAL, OUTPUT_EN};
          8'h40: HREADGPIO <= 0; // OUT_XOR reads as 0
          default:  HREADGPIO <= 0;
        endcase
      end 
      always_ff @(posedge HCLK or negedge HRESETn) 
        if (~HRESETn) begin
          INPUT_EN <= 0;
          OUTPUT_EN <= 0;
          OUTPUT_VAL <= 0; // spec indicates synchronous reset (software control)
        end else if (memwrite) begin
          if (entry == 8'h00) INPUT_EN <= HWDATA[63:32];
          if (entry == 8'h08) {OUTPUT_VAL, OUTPUT_EN} <= HWDATA;
          if (entry == 8'h40) OUTPUT_VAL <= OUTPUT_VAL ^ HWDATA[31:0]; // OUT_XOR
        end
    end else begin // 32-bit
      always_ff @(posedge HCLK) begin
        case(entry)
          8'h00: HREADGPIO <= INPUT_VAL;
          8'h04: HREADGPIO <= INPUT_EN;
          8'h08: HREADGPIO <= OUTPUT_EN;
          8'h0C: HREADGPIO <= OUTPUT_VAL;
          8'h40: HREADGPIO <= 0; // OUT_XOR reads as 0
          default:  HREADGPIO <= 0;
        endcase
      end 
      always_ff @(posedge HCLK or negedge HRESETn) 
        if (~HRESETn) begin
          INPUT_EN <= 0;
          OUTPUT_EN <= 0;
          //OUTPUT_VAL <= 0;// spec indicates synchronous rset (software control)
        end else if (memwrite) begin
          if (entry == 8'h04) INPUT_EN <= HWDATA;
          if (entry == 8'h08) OUTPUT_EN <= HWDATA;
          if (entry == 8'h0C) OUTPUT_VAL <= HWDATA;
          if (entry == 8'h40) OUTPUT_VAL <= OUTPUT_VAL ^ HWDATA; // OUT_XOR
        end
    end
  endgenerate
endmodule


///////////////////////////////////////////
// gpio.sv
//
// Written: David_Harris@hmc.edu 14 January 2021
// Modified: bbracker@hmc.edu 15 Apr. 2021
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
  input  logic             HSELGPIO,
  input  logic [7:0]       HADDR, 
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             HWRITE,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  output logic [`XLEN-1:0] HREADGPIO,
  output logic             HRESPGPIO, HREADYGPIO,
  input  logic [31:0]      GPIOPinsIn,
  output logic [31:0]      GPIOPinsOut, GPIOPinsEn,
  output logic             GPIOIntr);

  logic [31:0] input0d, input1d, input2d, input3d;
  logic [31:0] input_val, input_en, output_en, output_val;
  logic [31:0] rise_ie, rise_ip, fall_ie, fall_ip, high_ie, high_ip, low_ie, low_ip; 

  logic initTrans, memwrite;
  logic [7:0] entry, entryd;
  logic [31:0] Din, Dout;
  
  // AHB I/O
  assign entry = {HADDR[7:2],2'b0};
  assign initTrans = HREADY & HSELGPIO & (HTRANS != 2'b00);
  // entryd and memwrite are delayed by a cycle because AHB controller waits a cycle before outputting write data
  flopr #(1) memwriteflop(HCLK, ~HRESETn, initTrans & HWRITE, memwrite);
  flopr #(8) entrydflop(HCLK, ~HRESETn, entry, entryd);
  assign HRESPGPIO = 0; // OK
  assign HREADYGPIO = 1'b1; // GPIO never takes >1 cycle to respond

  // account for subword read/write circuitry
  // -- Note GPIO registers are 32 bits no matter what; access them with LW SW.
  //    (At least that's what I think when FE310 spec says "only naturally aligned 32-bit accesses are supported")
  if (`XLEN == 64) begin
    assign Din =       entryd[2] ? HWDATA[63:32] : HWDATA[31:0];
    assign HREADGPIO = entryd[2] ? {Dout,32'b0}  : {32'b0,Dout};
  end else begin // 32-bit
    assign Din = HWDATA[31:0];
    assign HREADGPIO = Dout;
  end

  // register access
  always_ff @(posedge HCLK, negedge HRESETn) begin
    // writes
    if (~HRESETn) begin
      // asynch reset
      input_en <= 0;
      output_en <= 0;
      // *** synch reset not yet implemented
      output_val <= #1 0;
      rise_ie <= #1 0;
      rise_ip <= #1 0;
      fall_ie <= #1 0;
      fall_ip <= #1 0;
      high_ie <= #1 0;
      high_ip <= #1 0;
      low_ie <= #1 0;
      low_ip <= #1 0;
    end else begin
      // writes
      if (memwrite)
        // According to FE310 spec: Once the interrupt is pending, it will remain set until a 1 is written to the *_ip register at that bit.
        /* verilator lint_off CASEINCOMPLETE */
        case(entryd)
          8'h04: input_en <= #1 Din;
          8'h08: output_en <= #1 Din;
          8'h0C: output_val <= #1 Din;
          8'h18: rise_ie <= #1 Din;
          8'h20: fall_ie <= #1 Din;
          8'h28: high_ie <= #1 Din;
          8'h30: low_ie  <= #1 Din;
          8'h40: output_val <= #1 output_val ^ Din; // OUT_XOR
        endcase
        /* verilator lint_on CASEINCOMPLETE */
      // reads
      case(entry)
        8'h00: Dout <= #1 input_val;
        8'h04: Dout <= #1 input_en;
        8'h08: Dout <= #1 output_en;
        8'h0C: Dout <= #1 output_val;
        8'h18: Dout <= #1 rise_ie;
        8'h1C: Dout <= #1 rise_ip;
        8'h20: Dout <= #1 fall_ie;
        8'h24: Dout <= #1 fall_ip;
        8'h28: Dout <= #1 high_ie;
        8'h2C: Dout <= #1 high_ip;
        8'h30: Dout <= #1 low_ie;
        8'h34: Dout <= #1 low_ip;
        8'h40: Dout <= #1 0; // OUT_XOR reads as 0
        default: Dout <= #1 0;
      endcase
      // interrupts
      if (memwrite & (entryd == 8'h1C))
        rise_ip <= rise_ip & ~Din;
      else
        rise_ip <= rise_ip | (input2d & ~input3d);
      if (memwrite & (entryd == 8'h24))
        fall_ip <= fall_ip & ~Din;
      else
        fall_ip <= fall_ip | (~input2d & input3d);
      if (memwrite & (entryd == 8'h2C))
        high_ip <= high_ip & ~Din;
      else
        high_ip <= high_ip | input3d;
      if (memwrite & (entryd == 8'h34))
        low_ip <= low_ip & ~Din;
      else
        low_ip <= low_ip | ~input3d;
    end
  end

  // chip i/o
  // connect OUT to IN for loopback testing
  if (`GPIO_LOOPBACK_TEST) assign input0d = GPIOPinsOut & input_en & output_en;
  else                     assign input0d = GPIOPinsIn  & input_en;
  flop #(32) sync1(HCLK,input0d,input1d);
  flop #(32) sync2(HCLK,input1d,input2d);
  flop #(32) sync3(HCLK,input2d,input3d);
  assign input_val = input3d;
  assign GPIOPinsOut = output_val;
  assign GPIOPinsEn = output_en;

  assign GPIOIntr = |{(rise_ip & rise_ie),(fall_ip & fall_ie),(high_ip & high_ie),(low_ip & low_ie)};
endmodule


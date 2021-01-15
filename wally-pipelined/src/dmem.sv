///////////////////////////////////////////
// dmem.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Data memory
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

// *** need idiom to map onto cache RAM with byte writes
// *** and use memread signal to reduce power when reads aren't needed
module dmem #(parameter XLEN=32) (
  input  logic            clk, reset,
  input  logic [1:0]      MemRWM,
  input  logic [7:0]      ByteMaskM,
  input  logic [XLEN-1:0] AdrM, WdM,
  output logic [XLEN-1:0] RdM,
  output logic            AccessFaultM,
  output logic            TimerIntM, SwIntM,
  input  logic [31:0] GPIOPinsIn,
  output logic [31:0] GPIOPinsOut, GPIOPinsEn);
  
  logic [XLEN-1:0] RdTimM, RdCLINTM, RdGPIOM;
  logic            TimEnM, CLINTEnM, GPIOEnM;

  // Address decoding
  // *** need to check top bits
  assign TimEnM = AdrM[31] & ~(|AdrM[30:19]); // 0x80000000 - 0x8007FFFF  *** check top bits too
  assign CLINTEnM = ~(|AdrM[XLEN-1:26]) & AdrM[25] & ~(|AdrM[24:16]); // 0x02000000-0x0200FFFF
  assign GPIOEnM = (AdrM[31:8] == 24'h10012); // 0x10012000-0x100120FF

  // tightly integrated memory
  dtim #(XLEN) dtim(clk, MemRWM & {2{TimEnM}}, ByteMaskM, AdrM[18:0], WdM, RdTimM);

  // memory-mapped I/O peripherals
  clint #(XLEN) clint(clk, reset, MemRWM & {2{CLINTEnM}}, ByteMaskM, AdrM[15:0], WdM, RdCLINTM,
    TimerIntM, SwIntM);
  gpio #(XLEN) gpio(clk, reset, MemRWM & {2{GPIOEnM}}, ByteMaskM, AdrM[7:0], WdM, RdGPIOM,
    GPIOPinsIn, GPIOPinsOut, GPIOPinsEn);

  // *** add cache and interface to external memory & other peripherals
  
  // merge reads
  assign RdM = RdTimM | RdCLINTM | RdGPIOM;
  assign AccessFaultM = ~(|TimEnM | CLINTEnM | GPIOEnM);

endmodule


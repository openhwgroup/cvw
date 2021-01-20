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
  input  logic [XLEN-1:0] AdrM, WriteDataM,
  output logic [XLEN-1:0] ReadDataM,
  output logic            DataAccessFaultM,
  output logic            TimerIntM, SwIntM,
  input  logic [31:0]     GPIOPinsIn,
  output logic [31:0]     GPIOPinsOut, GPIOPinsEn);
  
  logic [XLEN-1:0] MaskedWriteDataM;
  logic [XLEN-1:0] RdTimM, RdCLINTM, RdGPIOM;
  logic            TimEnM, CLINTEnM, GPIOEnM;
  logic [1:0]      MemRWdtimM, MemRWclintM, MemRWgpioM;

  // Address decoding
  generate
    if (XLEN == 64)
      assign TimEnM = ~(|AdrM[XLEN-1:32]) & AdrM[31] & ~(|AdrM[30:19]); // 0x000...80000000 - 0x000...8007FFFF
    else
      assign TimEnM = AdrM[31] & ~(|AdrM[30:19]); // 0x80000000 - 0x8007FFFF
  endgenerate
  assign CLINTEnM = ~(|AdrM[XLEN-1:26]) & AdrM[25] & ~(|AdrM[24:16]); // 0x02000000-0x0200FFFF
  assign GPIOEnM = (AdrM[31:8] == 24'h10012); // 0x10012000-0x100120FF

  assign MemRWdtimM  = MemRWM & {2{TimEnM}};
  assign MemRWclintM = MemRWM & {2{CLINTEnM}};
  assign MemRWgpioM  = MemRWM & {2{GPIOEnM}};

  // tightly integrated memory
  dtim #(XLEN) dtim(.AdrM(AdrM[18:0]), .*);

  // memory-mapped I/O peripherals
  clint #(XLEN) clint(.AdrM(AdrM[15:0]), .*);
  gpio #(XLEN) gpio(.AdrM(AdrM[7:0]), .*);

  // *** add cache and interface to external memory & other peripherals
  
  // merge reads
  assign ReadDataM = ({XLEN{TimEnM}} & RdTimM) | ({XLEN{CLINTEnM}} & RdCLINTM) | ({XLEN{GPIOEnM}} & RdGPIOM);
  assign DataAccessFaultM = ~(|TimEnM | CLINTEnM | GPIOEnM);

  // byte masking
   // write each byte based on the byte mask
  generate
    if (XLEN==64) begin
      always_comb begin
        MaskedWriteDataM=ReadDataM;
        if (ByteMaskM[0]) MaskedWriteDataM[7:0]   = WriteDataM[7:0];
        if (ByteMaskM[1]) MaskedWriteDataM[15:8]  = WriteDataM[15:8];
        if (ByteMaskM[2]) MaskedWriteDataM[23:16] = WriteDataM[23:16];
        if (ByteMaskM[3]) MaskedWriteDataM[31:24] = WriteDataM[31:24];
	      if (ByteMaskM[4]) MaskedWriteDataM[39:32] = WriteDataM[39:32];
	      if (ByteMaskM[5]) MaskedWriteDataM[47:40] = WriteDataM[47:40];
      	if (ByteMaskM[6]) MaskedWriteDataM[55:48] = WriteDataM[55:48];
	      if (ByteMaskM[7]) MaskedWriteDataM[63:56] = WriteDataM[63:56];
      end 
    end else begin // 32-bit
      always_comb begin
        if (ByteMaskM[0]) MaskedWriteDataM[7:0]   = WriteDataM[7:0];
        if (ByteMaskM[1]) MaskedWriteDataM[15:8]  = WriteDataM[15:8];
        if (ByteMaskM[2]) MaskedWriteDataM[23:16] = WriteDataM[23:16];
        if (ByteMaskM[3]) MaskedWriteDataM[31:24] = WriteDataM[31:24];
      end 
    end
  endgenerate

endmodule


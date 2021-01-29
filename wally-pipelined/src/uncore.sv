///////////////////////////////////////////
// uncore.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: System-on-Chip components outside the core (hart)
//          Memories, peripherals, external bus control
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

// *** need idiom to map onto cache RAM with byte writes
// *** and use memread signal to reduce power when reads aren't needed
module uncore (
  input  logic            clk, reset,
  // bus interface
  input  logic [1:0]      MemRWM,
  input  logic [`XLEN-1:0] AdrM, WriteDataM,
  input  logic [2:0]       Funct3M,
  output logic [`XLEN-1:0] ReadDataM,
  output logic            DataAccessFaultM,
  // peripheral pins
  output logic            TimerIntM, SwIntM,
  input  logic [31:0]     GPIOPinsIn,
  output logic [31:0]     GPIOPinsOut, GPIOPinsEn, 
  input  logic            UARTSin,
  output logic            UARTSout
  );
  
  logic [`XLEN-1:0] MaskedWriteDataM;
  logic [`XLEN-1:0] ReadDataUnmaskedM;
  logic [`XLEN-1:0] RdTimM, RdCLINTM, RdGPIOM, RdUARTM;
  logic            TimEnM, CLINTEnM, GPIOEnM, UARTEnM;
  logic [1:0]      MemRWdtimM, MemRWclintM, MemRWgpioM, MemRWuartM;
  logic            UARTIntr;// *** will need to tie INTR to an interrupt handler

  // Address decoding
  // *** generalize, use configurable
  generate
    if (`XLEN == 64)
      assign TimEnM = ~(|AdrM[`XLEN-1:32]) & AdrM[31] & ~(|AdrM[30:19]); // 0x000...80000000 - 0x000...8007FFFF
    else
      assign TimEnM = AdrM[31] & ~(|AdrM[30:19]); // 0x80000000 - 0x8007FFFF
  endgenerate
  assign CLINTEnM = ~(|AdrM[`XLEN-1:26]) & AdrM[25] & ~(|AdrM[24:16]); // 0x02000000-0x0200FFFF
  assign GPIOEnM = (AdrM[31:8] == 24'h10012); // 0x10012000-0x100120FF
  assign UARTEnM = ~(|AdrM[`XLEN-1:29]) & AdrM[28] & ~(|AdrM[27:3]); // 0x10000000-0x10000007

  // Enable read or write based on decoded address.
  assign MemRWdtimM  = MemRWM & {2{TimEnM}};
  assign MemRWclintM = MemRWM & {2{CLINTEnM}};
  assign MemRWgpioM  = MemRWM & {2{GPIOEnM}};
  assign MemRWuartM  = MemRWM & {2{UARTEnM}};

  // tightly integrated memory
  dtim dtim(.AdrM(AdrM[18:0]), .*);

  // memory-mapped I/O peripherals
  clint clint(.AdrM(AdrM[15:0]), .*);
  gpio gpio(.AdrM(AdrM[7:0]), .*); // *** may want to add GPIO interrupts
  uart uart(.TXRDYb(), .RXRDYb(), .INTR(UARTIntr), .SIN(UARTSin), .SOUT(UARTSout),
            .DSRb(1'b1), .DCDb(1'b1), .CTSb(1'b0), .RIb(1'b1), 
            .RTSb(), .DTRb(), .OUT1b(), .OUT2b(), .*); 

  // *** Interface to off-chip memory would appear as another peripheral
  
  // merge reads
  assign ReadDataUnmaskedM = ({`XLEN{TimEnM}} & RdTimM) | ({`XLEN{CLINTEnM}} & RdCLINTM) | 
                     ({`XLEN{GPIOEnM}} & RdGPIOM) | ({`XLEN{UARTEnM}} & RdUARTM);
  assign DataAccessFaultM = ~(TimEnM | CLINTEnM | GPIOEnM | UARTEnM);

  // subword accesses: converts ReadDataUnmaskedM to ReadDataM and WriteDataM to MaskedWriteDataM
  subword subword(.*);
 
endmodule


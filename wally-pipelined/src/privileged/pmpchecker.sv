///////////////////////////////////////////
// pmpchecker.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 28 April 2021
// Modified: 
//
// Purpose: Examines all physical memory accesses and checks them against the
//          current values of the physical memory protection (PMP) registers.
//          Can raise an access fault on illegal reads, writes, and instruction
//          fetches.
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

module pmpchecker (
  input  logic        clk, reset,

  input  logic [31:0] HADDR,

  input  logic [1:0]  PrivilegeModeW,

  input  logic [1:0]  STATUS_MPP,
  input  logic        STATUS_MPRV,

  input  logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [0:15],

  input  logic        ExecuteAccessF, WriteAccessM, ReadAccessM,

  output logic        PMPSquashBusAccess,

  output logic        PMPInstrAccessFaultF,
  output logic        PMPLoadAccessFaultM,
  output logic        PMPStoreAccessFaultM
);

  assign PMPSquashBusAccess = '0;
  assign PMPInstrAccessFaultF = '0;
  assign PMPLoadAccessFaultM = '0;
  assign PMPStoreAccessFaultM = '0;

  

  /*
  // Signals are high if the memory access is within the given region
  logic HSELBootTim, HSELTim, HSELCLINT, HSELGPIO, HSELUART, HSELPLIC;

  logic PreHSELUART;

  logic ExecutableRegion, ReadableRegion, WritableRegion;
  logic Empty;

  // Determine which region of physical memory (if any) is being accessed
  adrdec boottimdec(HADDR, `BOOTTIMBASE, `BOOTTIMRANGE, HSELBootTim);
  adrdec timdec(HADDR, `TIMBASE, `TIMRANGE, HSELTim);
  adrdec clintdec(HADDR, `CLINTBASE, `CLINTRANGE, HSELCLINT);
  adrdec gpiodec(HADDR, `GPIOBASE, `GPIORANGE, HSELGPIO);
  adrdec uartdec(HADDR, `UARTBASE, `UARTRANGE, PreHSELUART);
  adrdec plicdec(HADDR, `PLICBASE, `PLICRANGE, HSELPLIC);

  // *** Should this fault?
  assign HSELUART = PreHSELUART && (HSIZE == 3'b000); // only byte writes to UART are supported

  // Swizzle region bits
  assign HSELRegions = {HSELBootTim, HSELTim, HSELCLINT, HSELGPIO, HSELUART, HSELPLIC};

  // Only RAM memory regions are cacheable
  assign Cacheable = HSELBootTim | HSELTim;

  // *** Temporarily assume only RAM regions are idempotent -- likely wrong
  assign Idempotent = HSELBootTim | HSELTim;

  // *** Temporarily assume only RAM regions allow full atomic operations -- likely wrong
  assign AtomicAllowed = HSELBootTim | HSELTim;

  assign ExecutableRegion = HSELBootTim | HSELTim;
  assign ReadableRegion = HSELBootTim | HSELTim | HSELCLINT | HSELGPIO | HSELUART | HSELPLIC;
  assign WritableRegion = HSELBootTim | HSELTim | HSELCLINT | HSELGPIO | HSELUART | HSELPLIC;

  assign Empty = ~|HSELRegions;

  assign InstrAccessFaultF = ExecuteAccessF && (Empty || ~ExecutableRegion);
  assign LoadAccessFaultM = ReadAccessM && (Empty || ~ReadableRegion);
  assign StoreAccessFaultM = WriteAccessM && (Empty || ~WritableRegion);

  assign SquashBusAccess = InstrAccessFaultF || LoadAccessFaultM || StoreAccessFaultM;
  */

endmodule

///////////////////////////////////////////
// pmachecker.sv
//
// Written: tfleming@hmc.edu & jtorrey@hmc.edu 20 April 2021
// Modified: 
//
// Purpose: Examines all physical memory accesses and identifies attributes of
//          the memory region accessed.
//          Can report illegal accesses to the trap unit and cause a fault.
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

module pmachecker (
//  input  logic        clk, reset, // *** unused in this module and all sub modules.

  input  logic [31:0] HADDR,
  input  logic [2:0]  HSIZE,
//  input  logic [2:0]  HBURST, //  *** in AHBlite, HBURST is hardwired to zero for single bursts only allowed. consider removing from this module if unused.

  input  logic        AtomicAccessM, ExecuteAccessF, WriteAccessM, ReadAccessM, // *** atomicaccessM is unused but might want to stay in for future use.

  output logic        Cacheable, Idempotent, AtomicAllowed,
  output logic        PMASquashBusAccess,

  output logic [5:0]  HSELRegions,

  output logic        PMAInstrAccessFaultF,
  output logic        PMALoadAccessFaultM,
  output logic        PMAStoreAccessFaultM
);

  // Signals are high if the memory access is within the given region
  logic BootTim, Tim, CLINT, GPIO, UART, PLIC;
  logic [5:0] Regions;

  // Actual HSEL signals sent to uncore
  logic HSELBootTim, HSELTim, HSELCLINT, HSELGPIO, HSELUART, HSELPLIC;
  logic ValidBootTim, ValidTim, ValidCLINT, ValidGPIO, ValidUART, ValidPLIC;

  logic PMAAccessFault;
  logic AccessRW, AccessRWX, AccessRX;

  // Determine what type of access is being made
  assign AccessRW = ReadAccessM | WriteAccessM;
  assign AccessRWX = ReadAccessM | WriteAccessM | ExecuteAccessF;
  assign AccessRX = ReadAccessM | ExecuteAccessF;


  // Determine which region of physical memory (if any) is being accessed
  pmaadrdec boottimdec(HADDR, `BOOTTIMBASE, `BOOTTIMRANGE, `BOOTTIMSUPPORTED, BootTim);
  pmaadrdec timdec(HADDR, `TIMBASE, `TIMRANGE, `TIMSUPPORTED, Tim);
  pmaadrdec clintdec(HADDR, `CLINTBASE, `CLINTRANGE, `CLINTSUPPORTED, CLINT);
  pmaadrdec gpiodec(HADDR, `GPIOBASE, `GPIORANGE, `GPIOSUPPORTED, GPIO);
  pmaadrdec uartdec(HADDR, `UARTBASE, `UARTRANGE, `UARTSUPPORTED, UART);
  pmaadrdec plicdec(HADDR, `PLICBASE, `PLICRANGE, `PLICSUPPORTED, PLIC);

  // Swizzle region bits
  assign Regions = {BootTim, Tim, CLINT, GPIO, UART, PLIC};

  // Only RAM memory regions are cacheable
  assign Cacheable = BootTim | Tim;
  assign Idempotent = BootTim | Tim;
  assign AtomicAllowed = BootTim | Tim;

  assign ValidBootTim = '1;
  assign ValidTim = '1;
  assign ValidCLINT = ~ExecuteAccessF && ((HSIZE == 3'b011 && `XLEN==64) || (HSIZE == 3'b010 && `XLEN==32));
  assign ValidGPIO  = ~ExecuteAccessF && (HSIZE == 3'b010);
  assign ValidUART  = ~ExecuteAccessF && (HSIZE == 3'b000);
  assign ValidPLIC  = ~ExecuteAccessF && (HSIZE == 3'b010);

  assign HSELBootTim = BootTim && ValidBootTim; 
  assign HSELTim     = Tim     && ValidTim;
  assign HSELCLINT   = CLINT   && ValidCLINT;
  assign HSELGPIO    = GPIO    && ValidGPIO;
  assign HSELUART    = UART    && ValidUART; // only byte writes to UART are supported
  assign HSELPLIC    = PLIC    && ValidPLIC;

  // Swizzle region bits
  assign HSELRegions = {HSELBootTim, HSELTim, HSELCLINT, HSELGPIO, HSELUART, HSELPLIC};

  assign PMAAccessFault = ~|HSELRegions;

  assign PMAInstrAccessFaultF = ExecuteAccessF && PMAAccessFault;
  assign PMALoadAccessFaultM  = ReadAccessM    && PMAAccessFault;
  assign PMAStoreAccessFaultM = WriteAccessM   && PMAAccessFault;

  assign PMASquashBusAccess = PMAAccessFault && AccessRWX;
endmodule

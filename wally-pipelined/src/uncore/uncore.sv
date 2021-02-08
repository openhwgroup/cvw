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
  // AHB Bus Interface
  input  logic             HCLK, HRESETn,
  input  logic [31:0]      HADDR,
  input  logic [`AHBW-1:0] HWDATAIN,
  input  logic             HWRITE,
  input  logic [2:0]       HSIZE,
  input  logic [2:0]       HBURST,
  input  logic [3:0]       HPROT,
  input  logic [1:0]       HTRANS,
  input  logic             HMASTLOCK,
  input  logic [`AHBW-1:0] HRDATAEXT,
  input  logic             HREADYEXT, HRESPEXT,
  output logic [`AHBW-1:0] HRDATA,
  output logic             HREADY, HRESP,
  // delayed signals
  input  logic [2:0]       HADDRD,
  input  logic [3:0]       HSIZED,
  input  logic             HWRITED,
  // bus interface
  output logic             DataAccessFaultM,
  // peripheral pins
  output logic             TimerIntM, SwIntM,
  input  logic [31:0]      GPIOPinsIn,
  output logic [31:0]      GPIOPinsOut, GPIOPinsEn, 
  input  logic             UARTSin,
  output logic             UARTSout
  );
  
  logic [`XLEN-1:0] HWDATA;
  logic [`XLEN-1:0] HREADTim, HREADCLINT, HREADGPIO, HREADUART;
  logic            HSELTim, HSELCLINT, HSELGPIO, PreHSELUART, HSELUART;
  logic            HRESPTim, HRESPCLINT, HRESPGPIO, HRESPUART;
  logic            HREADYTim, HREADYCLINT, HREADYGPIO, HREADYUART;  
  logic            MemRW;
  logic [1:0]      MemRWtim, MemRWclint, MemRWgpio, MemRWuart;
  logic            UARTIntr;// *** will need to tie INTR to an interrupt handler
  

  // AHB Address decoder
  adrdec timdec(HADDR, `TIMBASE, `TIMRANGE, HSELTim);
  adrdec clintdec(HADDR, `CLINTBASE, `CLINTRANGE, HSELCLINT);
  adrdec gpiodec(HADDR, `GPIOBASE, `GPIORANGE, HSELGPIO);
  adrdec uartdec(HADDR, `UARTBASE, `UARTRANGE, PreHSELUART);
  assign HSELUART = PreHSELUART && (HSIZE == 3'b000); // only byte writes to UART are supported
  
  // Enable read or write based on decoded address
  assign MemRW = {~HWRITE, HWRITED};
  assign MemRWtim = MemRW & {2{HSELTim}};
  assign MemRWclint = MemRW & {2{HSELCLINT}};
  assign MemRWgpio = MemRW & {2{HSELGPIO}};
  assign MemRWuart = MemRW & {2{HSELUART}};
/*  always_ff @(posedge HCLK) begin
    HADDRD <= HADDR;
    MemRWtim  <= MemRW & {2{HSELTim}};
    MemRWclint <= MemRW & {2{HSELCLINT}};
    MemRWgpio  <= MemRW & {2{HSELGPIO}};
    MemRWuart  <= MemRW & {2{HSELUART}};
  end */

  // subword accesses: converts HWDATAIN to HWDATA
  subwordwrite sww(.*);

  // tightly integrated memory
  dtim dtim(.HADDR(HADDR[18:0]), .*);

  // memory-mapped I/O peripherals
  clint clint(.HADDR(HADDR[15:0]), .*);
  gpio gpio(.HADDR(HADDR[7:0]), .*); // *** may want to add GPIO interrupts
  uart uart(.HADDR(HADDR[2:0]), .TXRDYb(), .RXRDYb(), .INTR(UARTIntr), .SIN(UARTSin), .SOUT(UARTSout),
            .DSRb(1'b1), .DCDb(1'b1), .CTSb(1'b0), .RIb(1'b1), 
            .RTSb(), .DTRb(), .OUT1b(), .OUT2b(), .*); 

  // mux could also include external memory  
  // AHB Read Multiplexer
  assign HRDATA = ({`XLEN{HSELTim}} & HREADTim) | ({`XLEN{HSELCLINT}} & HREADCLINT) | 
                     ({`XLEN{HSELGPIO}} & HREADGPIO) | ({`XLEN{HSELUART}} & HREADUART);
  assign HRESP = HSELTim & HRESPTim | HSELCLINT & HRESPCLINT | HSELGPIO & HRESPGPIO | HSELUART & HRESPUART;
  assign HREADY = HSELTim & HREADYTim | HSELCLINT & HREADYCLINT | HSELGPIO & HREADYGPIO | HSELUART & HREADYUART;

  // Faults
  assign DataAccessFaultM = ~(HSELTim | HSELCLINT | HSELGPIO | HSELUART);

 
endmodule


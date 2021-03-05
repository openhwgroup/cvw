///////////////////////////////////////////
// uncore.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: Ben Bracker 6 Mar 2021 to better fit AMBA 3 AHB-Lite spec
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
  logic            HSELTimD, HSELCLINTD, HSELGPIOD, HSELUARTD;
  logic            HRESPTim, HRESPCLINT, HRESPGPIO, HRESPUART;
  logic            HREADYTim, HREADYCLINT, HREADYGPIO, HREADYUART;  
  `ifdef BOOTTIMBASE
  logic [`XLEN-1:0] HREADBootTim; 
  logic            HSELBootTim, HSELBootTimD, HRESPBootTim, HREADYBootTim;
  logic [1:0]      MemRWboottim;
  `endif
  logic            UARTIntr;// *** will need to tie INTR to an interrupt handler
  

  // AHB Address decoder
  adrdec timdec(HADDR, `TIMBASE, `TIMRANGE, HSELTim);
  `ifdef BOOTTIMBASE
  adrdec boottimdec(HADDR, `BOOTTIMBASE, `BOOTTIMRANGE, HSELBootTim);
  `endif
  adrdec clintdec(HADDR, `CLINTBASE, `CLINTRANGE, HSELCLINT);
  `ifdef GPIOBASE
  adrdec gpiodec(HADDR, `GPIOBASE, `GPIORANGE, HSELGPIO); 
  `endif
  adrdec uartdec(HADDR, `UARTBASE, `UARTRANGE, PreHSELUART);
  assign HSELUART = PreHSELUART && (HSIZE == 3'b000); // only byte writes to UART are supported

  // subword accesses: converts HWDATAIN to HWDATA
  subwordwrite sww(.*);

  // tightly integrated memory
  dtim #(.BASE(`TIMBASE), .RANGE(`TIMRANGE)) dtim (.*);
  `ifdef BOOTTIMBASE
  dtim #(.BASE(`BOOTTIMBASE), .RANGE(`BOOTTIMRANGE)) bootdtim(.HSELTim(HSELBootTim), .HREADTim(HREADBootTim), .HRESPTim(HRESPBootTim), .HREADYTim(HREADYBootTim), .*);
  `endif

  // memory-mapped I/O peripherals
  clint clint(.HADDR(HADDR[15:0]), .*);
  `ifdef GPIOBASE
  gpio gpio(.HADDR(HADDR[7:0]), .*); // *** may want to add GPIO interrupts
  `endif
  uart uart(.HADDR(HADDR[2:0]), .TXRDYb(), .RXRDYb(), .INTR(UARTIntr), .SIN(UARTSin), .SOUT(UARTSout),
            .DSRb(1'b1), .DCDb(1'b1), .CTSb(1'b0), .RIb(1'b1), 
            .RTSb(), .DTRb(), .OUT1b(), .OUT2b(), .*);

  // mux could also include external memory  
  // AHB Read Multiplexer
  assign HRDATA = ({`XLEN{HSELTimD}} & HREADTim) | ({`XLEN{HSELCLINTD}} & HREADCLINT) | 
                    `ifdef GPIOBASE
                     ({`XLEN{HSELGPIOD}} & HREADGPIO) |
                    `endif
                    `ifdef BOOTTIMBASE
                     ({`XLEN{HSELBootTimD}} & HREADBootTim) |
                    `endif
                     ({`XLEN{HSELUARTD}} & HREADUART);
  assign HRESP = HSELTimD & HRESPTim | HSELCLINTD & HRESPCLINT | 
                 `ifdef GPIOBASE
                 HSELGPIOD & HRESPGPIO | 
                 `endif
                 `ifdef BOOTTIMBASE
                 HSELBootTimD & HRESPBootTim | 
                 `endif
                 HSELUARTD & HRESPUART;
  assign HREADY = HSELTimD & HREADYTim | HSELCLINTD & HREADYCLINT | 
                  `ifdef GPIOBASE
                  HSELGPIOD & HREADYGPIO | 
                  `endif
                  `ifdef BOOTTIMBASE
                  HSELBootTimD & HREADYBootTim | 
                  `endif
                  HSELUARTD & HREADYUART;

  // Faults
  assign DataAccessFaultM = ~(HSELTimD | HSELCLINTD | 
                            `ifdef GPIOBASE
                            HSELGPIOD |
                            `endif
                            `ifdef BOOTTIMBASE
                            HSELBootTimD |
                            `endif
                            HSELUARTD);


  // Synchronized Address Decoder (figure 4-2 in spec)
  always_ff @(posedge HCLK) begin
    HSELTimD   <= HSELTim;
    HSELCLINTD <= HSELCLINT;
    `ifdef GPIOBASE
    HSELGPIOD  <= HSELGPIO;
    `endif
    HSELUARTD  <= HSELUART;
    `ifdef BOOTTIMBASE
    HSELBootTimD <= HSELBootTim;
    `endif
  end
endmodule


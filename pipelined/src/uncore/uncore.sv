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
  input  logic             TIMECLK,
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
  output logic             HSELEXT,
  // delayed signals
  input  logic [2:0]       HADDRD,
  input  logic [3:0]       HSIZED,
  input  logic             HWRITED,
  // peripheral pins
  output logic             TimerIntM, SwIntM, ExtIntM,
  input  logic [31:0]      GPIOPinsIn,
  output logic [31:0]      GPIOPinsOut, GPIOPinsEn, 
  input  logic             UARTSin,
  output logic             UARTSout,
  output logic             SDCCmdOut,
  output logic             SDCCmdOE,
  input  logic             SDCCmdIn,
  input  logic [3:0]       SDCDatIn,
  output logic             SDCCLK,
  output logic [63:0]      MTIME_CLINT
);
  
  logic [`XLEN-1:0] HWDATA;
  logic [`XLEN-1:0] HREADRam, HREADCLINT, HREADPLIC, HREADGPIO, HREADUART, HREADSDC;

  logic [8:0]      HSELRegions;
  logic            HSELRam, HSELCLINT, HSELPLIC, HSELGPIO, HSELUART, HSELSDC;
  logic            HSELEXTD, HSELRamD, HSELCLINTD, HSELPLICD, HSELGPIOD, HSELUARTD, HSELSDCD;
  logic            HRESPRam, HRESPCLINT, HRESPPLIC, HRESPGPIO, HRESPUART, HRESPSDC;
  logic            HREADYRam, HREADYCLINT, HREADYPLIC, HREADYGPIO, HREADYUART, HRESPSDCD;
  logic [`XLEN-1:0] HREADBootRom; 
  logic            HSELBootRom, HSELBootRomD, HRESPBootRom, HREADYBootRom, HREADYSDC;
  logic            HSELNoneD;
  logic            UARTIntr,GPIOIntr;
  logic 	   SDCIntM;
  
  // Determine which region of physical memory (if any) is being accessed
  // Use a trimmed down portion of the PMA checker - only the address decoders
  // Set access types to all 1 as don't cares because the MMU has already done access checking
  adrdecs adrdecs({{(`PA_BITS-32){1'b0}}, HADDR}, 1'b1, 1'b1, 1'b1, HSIZE[1:0], HSELRegions);

  // unswizzle HSEL signals
  assign {HSELEXT, HSELBootRom, HSELRam, HSELCLINT, HSELGPIO, HSELUART, HSELPLIC, HSELSDC} = HSELRegions[7:0];

  // subword accesses: converts HWDATAIN to HWDATA
  subwordwrite sww(
    .HRDATA, 
    .HADDRD, .HSIZED, 
    .HWDATAIN, .HWDATA);

//  generate
    // on-chip RAM outside hart
    if (`RAM_SUPPORTED) begin : ram
      ram #(
        .BASE(`RAM_BASE), .RANGE(`RAM_RANGE)) ram (
        .HCLK, .HRESETn, 
        .HSELRam, .HADDR,
        .HWRITE, .HREADY,
        .HTRANS, .HWDATA, .HREADRam,
        .HRESPRam, .HREADYRam);
    end

    if (`BOOTROM_SUPPORTED) begin : bootrom
      ram #(.BASE(`BOOTROM_BASE), .RANGE(`BOOTROM_RANGE))
      bootrom(
        .HCLK, .HRESETn, 
        .HSELRam(HSELBootRom), .HADDR,
        .HWRITE, .HREADY, .HTRANS,
        .HWDATA,
        .HREADRam(HREADBootRom), .HRESPRam(HRESPBootRom), .HREADYRam(HREADYBootRom));
    end

    // memory-mapped I/O peripherals
    if (`CLINT_SUPPORTED == 1) begin : clint
      clint clint(
        .HCLK, .HRESETn, .TIMECLK,
        .HSELCLINT, .HADDR(HADDR[15:0]), .HWRITE,
        .HWDATA, .HREADY, .HTRANS,
        .HREADCLINT,
        .HRESPCLINT, .HREADYCLINT,
        .MTIME(MTIME_CLINT), 
        .TimerIntM, .SwIntM);

    end else begin : clint
      assign MTIME_CLINT = 0;
      assign TimerIntM = 0; assign SwIntM = 0;
    end
    if (`PLIC_SUPPORTED == 1) begin : plic
      plic plic(
        .HCLK, .HRESETn, 
        .HSELPLIC, .HADDR(HADDR[27:0]),
        .HWRITE, .HREADY, .HTRANS, .HWDATA,
        .UARTIntr, .GPIOIntr,
        .HREADPLIC, .HRESPPLIC, .HREADYPLIC,
        .ExtIntM);
    end else begin : plic
      assign ExtIntM = 0;
    end
    if (`GPIO_SUPPORTED == 1) begin : gpio
      gpio gpio(
        .HCLK, .HRESETn, .HSELGPIO,
        .HADDR(HADDR[7:0]), 
        .HWDATA,
        .HWRITE, .HREADY, 
        .HTRANS,
        .HREADGPIO,
        .HRESPGPIO, .HREADYGPIO,
        .GPIOPinsIn,
        .GPIOPinsOut, .GPIOPinsEn,
        .GPIOIntr);

    end else begin : gpio
      assign GPIOPinsOut = 0; assign GPIOPinsEn = 0; assign GPIOIntr = 0;
    end
    if (`UART_SUPPORTED == 1) begin : uart
      uart uart(
        .HCLK, .HRESETn, 
        .HSELUART,
        .HADDR(HADDR[2:0]), 
        .HWRITE, .HWDATA,
        .HREADUART, .HRESPUART, .HREADYUART,
        .SIN(UARTSin), .DSRb(1'b1), .DCDb(1'b1), .CTSb(1'b0), .RIb(1'b1), // from E1A driver from RS232 interface
        .SOUT(UARTSout), .RTSb(), .DTRb(),                                // to E1A driver to RS232 interface
        .OUT1b(), .OUT2b(), .INTR(UARTIntr), .TXRDYb(), .RXRDYb());       // to CPU
    end else begin : uart
      assign UARTSout = 0; assign UARTIntr = 0; 
    end
    if (`SDC_SUPPORTED == 1) begin : sdc
      SDC SDC(.HCLK, .HRESETn, .HSELSDC, .HADDR(HADDR[4:0]), .HWRITE, .HREADY, .HTRANS,
	      .HWDATA, .HREADSDC, .HRESPSDC, .HREADYSDC,
	      // sdc interface
	      .SDCCmdOut, .SDCCmdIn, .SDCCmdOE, .SDCDatIn, .SDCCLK,
	      // interrupt to PLIC
	      .SDCIntM	      
	      );
    end else begin : sdc
      assign SDCCLK = 0; 
      assign SDCCmdOut = 0;
      assign SDCCmdOE = 0;
    end
//  endgenerate

  // mux could also include external memory  
  // AHB Read Multiplexer
  assign HRDATA = ({`XLEN{HSELRamD}} & HREADRam) |
		  ({`XLEN{HSELEXTD}} & HRDATAEXT) |   
                  ({`XLEN{HSELCLINTD}} & HREADCLINT) |
                  ({`XLEN{HSELPLICD}} & HREADPLIC) | 
                  ({`XLEN{HSELGPIOD}} & HREADGPIO) |
                  ({`XLEN{HSELBootRomD}} & HREADBootRom) |
                  ({`XLEN{HSELUARTD}} & HREADUART) |
                  ({`XLEN{HSELSDCD}} & HREADSDC);

  assign HRESP = HSELRamD & HRESPRam |
		 HSELEXTD & HRESPEXT |
                 HSELCLINTD & HRESPCLINT |
                 HSELPLICD & HRESPPLIC |
                 HSELGPIOD & HRESPGPIO | 
                 HSELBootRomD & HRESPBootRom |
                 HSELUARTD & HRESPUART |
                 HSELSDC & HRESPSDC;		 

  assign HREADY = HSELRamD & HREADYRam |
		  HSELEXTD & HREADYEXT |		  
                  HSELCLINTD & HREADYCLINT |
                  HSELPLICD & HREADYPLIC |
                  HSELGPIOD & HREADYGPIO | 
                  HSELBootRomD & HREADYBootRom |
                  HSELUARTD & HREADYUART |
                  HSELSDCD & HREADYSDC |		  
                  HSELNoneD; // don't lock up the bus if no region is being accessed

  // Address Decoder Delay (figure 4-2 in spec)
  flopr #(9) hseldelayreg(HCLK, ~HRESETn, HSELRegions, {HSELNoneD, HSELEXTD, HSELBootRomD, HSELRamD, HSELCLINTD, HSELGPIOD, HSELUARTD, HSELPLICD, HSELSDCD});
endmodule


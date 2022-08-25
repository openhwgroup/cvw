///////////////////////////////////////////
// uncore.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: Ben Bracker 6 Mar 2021 to better fit AMBA 3 AHB-Lite spec
//
// Purpose: System-on-Chip components outside the core
//          Memories, peripherals, external bus control
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

// *** need idiom to map onto cache RAM with byte writes
// *** and use memread signal to reduce power when reads aren't needed
module uncore (
  // AHB Bus Interface
  input  logic             HCLK, HRESETn,
  input  logic             TIMECLK,
  input  logic [31:0]      HADDR,
  input  logic [`AHBW-1:0] HWDATA,
  input  logic [`XLEN/8-1:0] HWSTRB,
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
  input  logic             HWRITED,
  // peripheral pins
  output logic             MTimerInt, MSwInt, MExtInt, SExtInt,
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
  
  logic [`XLEN-1:0] HREADRam, HREADSDC;

  logic [8:0]      HSELRegions;
  logic            HSELRam, HSELCLINT, HSELPLIC, HSELGPIO, HSELUART, HSELSDC;
  logic            HSELEXTD, HSELRamD, HSELCLINTD, HSELPLICD, HSELGPIOD, HSELUARTD, HSELSDCD;
  logic            HRESPRam,  HRESPSDC;
  logic            HREADYRam, HRESPSDCD;
  logic [`XLEN-1:0] HREADBootRom; 
  logic            HSELBootRom, HSELBootRomD, HRESPBootRom, HREADYBootRom, HREADYSDC;
  logic            HSELNoneD;
  logic            UARTIntr,GPIOIntr;
  logic 	   SDCIntM;
  
  logic PCLK, PRESETn, PWRITE, PENABLE;
  logic [3:0] PSEL, PREADY;
  logic [31:0] PADDR;
  logic [`XLEN-1:0] PWDATA;
  logic [`XLEN/8-1:0] PSTRB;
  logic [3:0][`XLEN-1:0] PRDATA;
  logic [`XLEN-1:0] HREADBRIDGE;
  logic HRESPBRIDGE, HREADYBRIDGE, HSELBRIDGE, HSELBRIDGED;

  // Determine which region of physical memory (if any) is being accessed
  // Use a trimmed down portion of the PMA checker - only the address decoders
  // Set access types to all 1 as don't cares because the MMU has already done access checking
  adrdecs adrdecs({{(`PA_BITS-32){1'b0}}, HADDR}, 1'b1, 1'b1, 1'b1, HSIZE[1:0], HSELRegions);

  // unswizzle HSEL signals
  assign {HSELEXT, HSELBootRom, HSELRam, HSELCLINT, HSELGPIO, HSELUART, HSELPLIC, HSELSDC} = HSELRegions[7:0];

  // AHB -> APB bridge
  ahbapbbridge #(4) ahbapbbridge
    (.HCLK, .HRESETn, .HSEL({HSELUART, HSELPLIC, HSELCLINT, HSELGPIO}), .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HTRANS, .HREADY, 
     .HRDATA(HREADBRIDGE), .HRESP(HRESPBRIDGE), .HREADYOUT(HREADYBRIDGE),
     .PCLK, .PRESETn, .PSEL, .PWRITE, .PENABLE, .PADDR, .PWDATA, .PSTRB, .PREADY, .PRDATA);
  assign HSELBRIDGE = HSELGPIO | HSELCLINT | HSELPLIC | HSELUART; // if any of the bridge signals are selected
                
  // on-chip RAM
  if (`UNCORE_RAM_SUPPORTED) begin : ram
    ram_ahb #(
      .BASE(`UNCORE_RAM_BASE), .RANGE(`UNCORE_RAM_RANGE)) ram (
      .HCLK, .HRESETn, 
      .HSELRam, .HADDR,
      .HWRITE, .HREADY, 
      .HTRANS, .HWDATA, .HWSTRB, .HREADRam,
      .HRESPRam, .HREADYRam);
  end

 if (`BOOTROM_SUPPORTED) begin : bootrom
    rom_ahb #(.BASE(`BOOTROM_BASE), .RANGE(`BOOTROM_RANGE))
    bootrom(
      .HCLK, .HRESETn, 
      .HSELRom(HSELBootRom), .HADDR,
      .HREADY, .HTRANS, 
      .HREADRom(HREADBootRom), .HRESPRom(HRESPBootRom), .HREADYRom(HREADYBootRom));
  end

  // memory-mapped I/O peripherals
  if (`CLINT_SUPPORTED == 1) begin : clint
    clint_apb clint(
      .PCLK, .PRESETn, .PSEL(PSEL[1]), .PADDR(PADDR[15:0]), .PWDATA, .PSTRB, .PWRITE, .PENABLE, 
      .PRDATA(PRDATA[1]), .PREADY(PREADY[1]), 
      .MTIME(MTIME_CLINT), 
      .MTimerInt, .MSwInt);

  end else begin : clint
    assign MTIME_CLINT = 0;
    assign MTimerInt = 0; assign MSwInt = 0;
  end
  if (`PLIC_SUPPORTED == 1) begin : plic
    plic_apb plic(
      .PCLK, .PRESETn, .PSEL(PSEL[2]), .PADDR(PADDR[27:0]), .PWDATA, .PSTRB, .PWRITE, .PENABLE, 
      .PRDATA(PRDATA[2]), .PREADY(PREADY[2]), 
      .UARTIntr, .GPIOIntr,
      .MExtInt, .SExtInt);
  end else begin : plic
    assign MExtInt = 0;
    assign SExtInt = 0;
  end
  if (`GPIO_SUPPORTED == 1) begin : gpio
    gpio_apb gpio(
      .PCLK, .PRESETn, .PSEL(PSEL[0]), .PADDR(PADDR[7:0]), .PWDATA, .PSTRB, .PWRITE, .PENABLE, 
      .PRDATA(PRDATA[0]), .PREADY(PREADY[0]), 
      .iof0(), .iof1(), .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn, .GPIOIntr);
  end else begin : gpio
    assign GPIOPinsOut = 0; assign GPIOPinsEn = 0; assign GPIOIntr = 0;
  end
  if (`UART_SUPPORTED == 1) begin : uart
    uart_apb uart(
      .PCLK, .PRESETn, .PSEL(PSEL[3]), .PADDR(PADDR[2:0]), .PWDATA, .PSTRB, .PWRITE, .PENABLE, 
      .PRDATA(PRDATA[3]), .PREADY(PREADY[3]), 
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

  // AHB Read Multiplexer
  assign HRDATA = ({`XLEN{HSELRamD}} & HREADRam) |
		              ({`XLEN{HSELEXTD}} & HRDATAEXT) |   
                  ({`XLEN{HSELBRIDGED}} & HREADBRIDGE) |
                  ({`XLEN{HSELBootRomD}} & HREADBootRom) |
                  ({`XLEN{HSELSDCD}} & HREADSDC);

  assign HRESP = HSELRamD & HRESPRam |
		             HSELEXTD & HRESPEXT |
                 HSELBRIDGE & HRESPBRIDGE |
                 HSELBootRomD & HRESPBootRom |
                 HSELSDC & HRESPSDC;		 

  assign HREADY = HSELRamD & HREADYRam |
		              HSELEXTD & HREADYEXT |		  
                  HSELBRIDGED & HREADYBRIDGE |
                  HSELBootRomD & HREADYBootRom |
                  HSELSDCD & HREADYSDC |		  
                  HSELNoneD; // don't lock up the bus if no region is being accessed

  // Address Decoder Delay (figure 4-2 in spec)
  flopr #(9) hseldelayreg(HCLK, ~HRESETn, HSELRegions, {HSELNoneD, HSELEXTD, HSELBootRomD, HSELRamD, HSELCLINTD, HSELGPIOD, HSELUARTD, HSELPLICD, HSELSDCD});
  flopr #(1) hselbridgedelayreg(HCLK, ~HRESETn, HSELBRIDGE, HSELBRIDGED);
endmodule


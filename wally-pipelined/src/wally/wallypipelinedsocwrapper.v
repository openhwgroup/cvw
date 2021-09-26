///////////////////////////////////////////
// wally-pipelinedsoc.sv
//
// Written: David_Harris@hmc.edu 6 November 2020
// Modified: 
//
// Purpose: System on chip including pipelined processor and memories
// Full RV32/64IC instruction set
//
// Note: the CSRs do not support the following features
//- Disabling portions of the instruction set with bits of the MISA register
//- Changing from RV64 to RV32 by writing the SXL/UXL bits of the STATUS register
// As of January 2020, virtual memory is not yet supported
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

module wallypipelinedsocwrapper (
  input 	     clk, reset, 
  // AHB Lite Interface
  // inputs from external memory
  input [`AHBW-1:0]  HRDATAEXT,
  input 	     HREADYEXT, HRESPEXT,
  output 	     HSELEXT,
  // outputs to external memory, shared with uncore memory
  output 	     HCLK, HRESETn,
  output [31:0]      HADDR,
  output [`AHBW-1:0] HWDATA,
  output 	     HWRITE,
  output [2:0] 	     HSIZE,
  output [2:0] 	     HBURST,
  output [3:0] 	     HPROT,
  output [1:0] 	     HTRANS,
  output 	     HMASTLOCK,
  output 	     HREADY, 
  // I/O Interface
  input [3:0] 	     GPIOPinsIn_IO,
  output [4:0] 	     GPIOPinsOut_IO,
  input 	     UARTSin,
  output 	     UARTSout,
  input 	     ddr4_calib_complete,
  input [3:0] 	     SDCDat,
  output 	     SDCCLK,
  inout              SDCCmd	     
);

  wire [31:0] 	     GPIOPinsEn;
  wire [31:0] 	     GPIOPinsIn;
  wire [31:0] 	     GPIOPinsOut;
    
  // to instruction memory *** remove later
  wire [`XLEN-1:0] PCF;

  // Uncore signals
  wire [`AHBW-1:0] HRDATA;   // from AHB mux in uncore
  wire             HRESP;
  wire [5:0]       HSELRegions;
  wire             InstrAccessFaultF, DataAccessFaultM;
  wire             TimerIntM, SwIntM; // from CLINT
  wire [63:0]      MTIME_CLINT, MTIMECMP_CLINT; // from CLINT to CSRs
  wire             ExtIntM; // from PLIC
  wire [2:0]       HADDRD;
  wire [3:0]       HSIZED;
  wire             HWRITED;
  wire [15:0]      rd2; // bogus, delete when real multicycle fetch works
  wire [31:0]      InstrF;


  assign GPIOPinsOut_IO = GPIOPinsOut[4:0];
  assign GPIOPinsIn = {28'b0, GPIOPinsIn_IO};

  // wrapper for fpga
  wallypipelinedsoc wallypipelinedsoc
    (.clk(clk),
     .reset(reset),
     .HRDATAEXT(HRDATAEXT),
     .HREADYEXT(HREADYEXT),
     .HRESPEXT(HRESPEXT),
     .HSELEXT(HSELEXT),     
     .HCLK(HCLK),
     .HRESETn(HRESETn),
     .HADDR(HADDR),
     .HWDATA(HWDATA),
     .HWRITE(HWRITE),
     .HSIZE(HSIZE),
     .HBURST(HBURST),
     .HPROT(HPROT),
     .HTRANS(HTRANS),
     .HMASTLOCK(HMASTLOCK),
     .HREADY(HREADY),     
     .GPIOPinsIn(GPIOPinsIn),
     .GPIOPinsOut(GPIOPinsOut),
     .GPIOPinsEn(GPIOPinsEn),
     .UARTSin(UARTSin),
     .UARTSout(UARTSout),
     .SDCDat(SDCDat),
     .SDCCLK(SDCCLK),
     .SDCCmd(SDCCmd));
  
endmodule

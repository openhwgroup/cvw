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

module wallypipelinedsoc (
  input logic 		   clk, reset, 
  // AHB Lite Interface
  // inputs from external memory
  input logic [`AHBW-1:0]  HRDATAEXT,
  input logic 		   HREADYEXT, HRESPEXT,
  output logic 		   HSELEXT,
  // outputs to external memory, shared with uncore memory
  output logic 		   HCLK, HRESETn,
  output logic [31:0] 	   HADDR,
  output logic [`AHBW-1:0] HWDATA,
  output logic 		   HWRITE,
  output logic [2:0] 	   HSIZE,
  output logic [2:0] 	   HBURST,
  output logic [3:0] 	   HPROT,
  output logic [1:0] 	   HTRANS,
  output logic 		   HMASTLOCK,
  output logic 		   HREADY,
  // I/O Interface
  input logic [31:0] 	   GPIOPinsIn,
  output logic [31:0] 	   GPIOPinsOut, GPIOPinsEn,
  input logic 		   UARTSin,
  output logic 		   UARTSout,
  input logic 		   SDCCmdIn,
  output logic 		   SDCCmdOut,
  output logic 		   SDCCmdOE,			  
  input logic [3:0] 	   SDCDatIn,
  output logic 		   SDCCLK			  
);

  // to instruction memory *** remove later
  logic [`XLEN-1:0] PCF;

  // Uncore signals
  logic [`AHBW-1:0] HRDATA;   // from AHB mux in uncore
  //logic             HREADY, HRESP;
  logic [5:0]       HSELRegions;
  logic             InstrAccessFaultF, DataAccessFaultM;
  logic             TimerIntM, SwIntM; // from CLINT
  logic [63:0]      MTIME_CLINT, MTIMECMP_CLINT; // from CLINT to CSRs
  logic             ExtIntM; // from PLIC
  logic [2:0]       HADDRD;
  logic [3:0]       HSIZED;
  logic             HWRITED;
  logic [15:0]      rd2; // bogus, delete when real multicycle fetch works
  logic [31:0]      InstrF;
  logic 	    HRESP;

/* -----\/----- EXCLUDED -----\/-----
  logic             SDCCmdOut;
  logic             SDCCmdOE;
  logic             SDCCmdIn;
 -----/\----- EXCLUDED -----/\----- */
//  logic [3:0] 	    SDCDatIn;

  // it turn out vivado cannot infer these at this level of the hierarchy.
  //assign SDCCmd = SDCCmdOE ? SDCCmdOut : 1'bz;
  //assign SDCCmdIn = SDCCmd;
  //assign SDCDatIn = SDCDat; // when write supported this will be a tristate
   
  // instantiate processor and memories
  wallypipelinedhart hart(.clk, .reset,
    .PCF,  .TimerIntM, .ExtIntM, .SwIntM, .DataAccessFaultM, 
    .MTIME_CLINT, .MTIMECMP_CLINT, .rd2, 
    .HRDATA, .HREADY, .HRESP, .HCLK, .HRESETn, .HADDR, .HWDATA,
    .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK,
    .HSELRegions, .HADDRD, .HSIZED, .HWRITED
   );

  // instructions now come from uncore memory. This line can be removed at any time.
  // imem imem(.AdrF(PCF[`XLEN-1:1]), .*); // temporary until uncore memory is finished***
  uncore uncore(.HCLK, .HRESETn,
    .HADDR, .HWDATAIN(HWDATA), .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK, .HRDATAEXT,
    .HREADYEXT, .HRESPEXT, .HRDATA, .HREADY, .HRESP, .HADDRD, .HSIZED, .HWRITED,
    .TimerIntM, .SwIntM, .ExtIntM, .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn, .UARTSin, .UARTSout, .MTIME_CLINT, .MTIMECMP_CLINT,
		.HSELEXT,
		.SDCCmdOut, .SDCCmdOE, .SDCCmdIn, .SDCDatIn, .SDCCLK
		
);
endmodule

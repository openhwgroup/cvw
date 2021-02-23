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

module wallypipelinedsocbusybear (
  input  logic             clk, reset, 
  // AHB Lite Interface
  // inputs from external memory
  input  logic [`AHBW-1:0] HRDATAEXT,
  input  logic             HREADYEXT, HRESPEXT,
  // outputs to external memory, shared with uncore memory
  output logic             HCLK, HRESETn,
  output logic [31:0]      HADDR,
  output logic [`AHBW-1:0] HWDATA,
  output logic             HWRITE,
  output logic [2:0]       HSIZE,
  output logic [2:0]       HBURST,
  output logic [3:0]       HPROT,
  output logic [1:0]       HTRANS,
  output logic             HMASTLOCK,
  // I/O Interface
  input  logic [31:0]      GPIOPinsIn,
  output logic [31:0]      GPIOPinsOut, GPIOPinsEn,
  input  logic             UARTSin,
  output logic             UARTSout,
  // to instruction memory *** remove later
  output logic [`XLEN-1:0] PCF,
  input  logic [31:0]      InstrF,
  input  logic [`AHBW-1:0] HRDATA   // from AHB mux in uncore
);


  // Uncore signals
  logic             HREADY, HRESP;
  logic        InstrAccessFaultF, DataAccessFaultM;
  logic        TimerIntM, SwIntM; // from CLINT
  logic        ExtIntM = 0; // not yet connected

  
  // for now, seem to need these to be like this
  // until we get a better idea
  assign HREADY = 1;
  assign HRESP = 0;
  assign InstrAccessFaultF = 0;
  assign DataAccessFaultM = 0;
   
  // instantiate processor and memories
  wallypipelinedhart hart(.*);

  //imem imem(.AdrF(PCF[`XLEN-1:1]), .*); // temporary until uncore memory is finished***
  //uncore uncore(.HWDATAIN(HWDATA), .*);
endmodule

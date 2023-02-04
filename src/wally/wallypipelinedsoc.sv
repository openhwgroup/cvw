///////////////////////////////////////////
// wally-pipelinedsoc.sv
//
// Written: David_Harris@hmc.edu 6 November 2020
// Modified: 
//
// Purpose: System on chip including pipelined processor and uncore memories/peripherals
//
// Documentation: RISC-V System on Chip Design (Figure 6.20)
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

//import cvw::*;  // global CORE-V-Wally parameters
`include "wally-config.vh"

module wallypipelinedsoc (
  input  logic 		            clk, 
  input  logic                reset_ext,        // external asynchronous reset pin
  output logic                reset,            // reset synchronized to clk to prevent races on release
  // AHB Interface
  input  logic [`AHBW-1:0]     HRDATAEXT,
  input  logic 		            HREADYEXT, HRESPEXT,
  output logic 		            HSELEXT,
  // outputs to external memory, shared with uncore memory
  output logic 		            HCLK, HRESETn,
  output logic [`PA_BITS-1:0]  HADDR,
  output logic [`AHBW-1:0]     HWDATA,
  output logic [`XLEN/8-1:0]   HWSTRB,
  output logic 		            HWRITE,
  output logic [2:0] 	        HSIZE,
  output logic [2:0] 	        HBURST,
  output logic [3:0] 	        HPROT,
  output logic [1:0] 	        HTRANS,
  output logic 		            HMASTLOCK,
  output logic 		            HREADY,
  // I/O Interface
  input  logic                TIMECLK,          // optional for CLINT MTIME counter
  input  logic [31:0] 	      GPIOPinsIn,       // inputs from GPIO
  output logic [31:0] 	      GPIOPinsOut,      // output values for GPIO
  output logic [31:0]         GPIOPinsEn,       // output enables for GPIO
  input  logic 		            UARTSin,          // UART serial data input
  output logic 		            UARTSout,         // UART serial data output
  input  logic 		            SDCCmdIn,         // SDC Command input
  output logic 		            SDCCmdOut,        // SDC Command output
  output logic 		            SDCCmdOE,			    // SDC Command output enable
  input  logic [3:0] 	        SDCDatIn,         // SDC data input
  output logic 		            SDCCLK			      // SDC clock
);

  // Uncore signals
  logic [`AHBW-1:0]            HRDATA;           // from AHB mux in uncore
  logic                       HRESP;            // response from AHB
  logic                       MTimerInt, MSwInt; // timer and software interrupts from CLINT
  logic [63:0]                MTIME_CLINT;      // from CLINT to CSRs
  logic                       MExtInt,SExtInt;  // from PLIC

  // synchronize reset to SOC clock domain
  synchronizer resetsync(.clk, .d(reset_ext), .q(reset)); 
   
  // instantiate processor and internal memories
  wallypipelinedcore core(.clk, .reset,
    .MTimerInt, .MExtInt, .SExtInt, .MSwInt, .MTIME_CLINT,
    .HRDATA, .HREADY, .HRESP, .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB,
    .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK
   );

  // instantiate uncore if a bus interface exists
  if (`BUS_SUPPORTED) begin : uncore
    uncore uncore(.HCLK, .HRESETn, .TIMECLK,
      .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK, .HRDATAEXT,
      .HREADYEXT, .HRESPEXT, .HRDATA, .HREADY, .HRESP, .HSELEXT,
      .MTimerInt, .MSwInt, .MExtInt, .SExtInt, .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn, .UARTSin, 
	    .UARTSout, .MTIME_CLINT, 
	    .SDCCmdOut, .SDCCmdOE, .SDCCmdIn, .SDCDatIn, .SDCCLK);
  end

endmodule

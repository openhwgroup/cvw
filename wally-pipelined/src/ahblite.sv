///////////////////////////////////////////
// ahblite.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: AHB Lite External Bus Unit
//          See ARM_HIH0033A_AMBA_AHB-Lite_SPEC 1.0
//          Arbitrates requests from instruction and data streams
//          Connects hart to peripherals and I/O pins on SOC
//          Bus width presently matches XLEN
//          Anticipate replacing this with an AXI bus interface to communicate with FPGA DRAM/Flash controllers
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

module ahblite (
  input  logic             clk, reset,
  // Load control
  input  logic             UnsignedLoadM,
  // Signals from Instruction Cache
  input  logic [`XLEN-1:0] IPAdrD,
  input  logic             IReadD,
  output logic [`XLEN-1:0] IRData,
  output logic             IReady,
  // Signals from Data Cache
  input  logic [`XLEN-1:0] DPAdrM,
  input  logic             DReadM, DWriteM,
  input  logic [`XLEN-1:0] DWDataM,
  input  logic [1:0]       DSizeM,
  output logic [`XLEN-1:0] DRData,
  output logic             DReady,
  // AHB-Lite external signals
  input  logic [`AHBW-1:0] HRDATA,
  input  logic             HREADY, HRESP,
  output logic             HCLK, HRESETn,
  output logic [31:0]      HADDR, 
  output logic [`AHBW-1:0] HWDATA,
  output logic             HWRITE, 
  output logic [2:0]       HSIZE,
  output logic [2:0]       HBURST,
  output logic [3:0]       HPROT,
  output logic [1:0]       HTRANS,
  output logic             HMASTLOCK
);

  logic GrantData;
  logic [2:0] ISize;
  logic [`AHBW-1:0] HRDATAMasked;

  assign HCLK = clk;
  assign HRESETn = ~reset;

  // Arbitrate requests by giving data priority over instructions
  assign GrantData = DReadM | DWriteM;

  // *** initially support HABW = XLEN

  // Choose ISize based on XLen
  generate
    if (`AHBW == 32) assign ISize = 3'b010; // 32-bit transfers
    else             assign ISize = 3'b011; // 64-bit transfers
  endgenerate

  // drive bus outputs
  assign HADDR = GrantData ? DPAdrM[31:0] : IPAdrD[31:0];
  assign HWDATA = DWDataM;
  //flop #(`XLEN) wdreg(HCLK, DWDataM, HWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN
  assign HWRITE = DWriteM; 
  assign HSIZE = GrantData ? {1'b0, DSizeM} : ISize;
  assign HBURST = 3'b000; // Single burst only supported; consider generalizing for cache fillsfHPROT
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HTRANS = IReadD | DReadM | DWriteM ? 2'b10 : 2'b00; // NONSEQ if reading or writing, IDLE otherwise
  assign HMASTLOCK = 0; // no locking supported
                  
  // Route signals to Instruction and Data Caches
  // *** assumes AHBW = XLEN
  assign IRData = HRDATAMasked;
  assign IReady = HREADY & IReadD & ~GrantData;
  assign DRData = HRDATAMasked;
  assign DReady = HREADY & GrantData;

  // *** consider adding memory access faults based on HRESP being high
  //   InstrAccessFaultF, DataAccessFaultM,

  subwordread swr(.*);

endmodule


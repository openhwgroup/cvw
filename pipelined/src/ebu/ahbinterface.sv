///////////////////////////////////////////
// ahbinterface.sv
//
// Written: Ross Thompson ross1728@gmail.com August 29, 2022
// Modified: 
//
// Purpose: Cache/Bus data path.
// Bus Side logic
// register the fetch data from the next level of memory.
// This register should be necessary for timing.  There is no register in the uncore or
// ahblite controller between the memories and this cache.
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

module ahbinterface #(parameter LSU = 0) // **** modify to use LSU/ifu parameter to control widths of buses
  (
  input logic                HCLK, HRESETn,
  
  // bus interface
  input logic                HREADY,
  input logic [`XLEN-1:0]    HRDATA,
  output logic [1:0]         HTRANS,
  output logic               HWRITE,
  output logic [`XLEN-1:0]   HWDATA,
  output logic [`XLEN/8-1:0] HWSTRB,
  
  // lsu/ifu interface
  input logic [1:0]          RW,
  input logic [`XLEN/8-1:0]  ByteMask,
  input logic [`XLEN-1:0]    WriteData,
  input logic                CPUBusy,
  output logic               BusStall,
  output logic               BusCommitted,
  output logic [(LSU ? `XLEN : 32)-1:0]   ReadDataWord);
  
  logic                       CaptureEn;

  /// *** only 32 bit for IFU.
  localparam                  LEN = (LSU ? `XLEN : 32);
  
  flopen #(LEN) fb(.clk(HCLK), .en(CaptureEn), .d(HRDATA[LEN-1:0]), .q(ReadDataWord));

  if(LSU) begin
    // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN    
    flop #(`XLEN) wdreg(HCLK, WriteData, HWDATA); 
    flop #(`XLEN/8) HWSTRBReg(HCLK, ByteMask, HWSTRB);
  end else begin
    assign HWDATA = '0;
    assign HWSTRB = '0;
  end    

  busfsm busfsm(.HCLK, .HRESETn, .RW,
    .BusCommitted, .CPUBusy, .BusStall, .CaptureEn, .HREADY,
    .HTRANS, .HWRITE);
endmodule

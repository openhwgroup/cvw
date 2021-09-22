///////////////////////////////////////////
// SDC.sv
//
// Written: Ross Thompson September 22, 2021
// Modified: 
//
// Purpose: SDC interface to AHBLite BUS.
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

`define SDCCLKDIV 2

module SDC 
  (input  logic             HCLK, 
   input logic 		    HRESETn,
   input logic 		    HSELSDC,
   input logic [4:0] 	    HADDR,
   input logic 		    HWRITE,
   input logic 		    HREADY,
   input logic [1:0] 	    HTRANS,
   input logic [`XLEN-1:0]  HWDATA,
   output logic [`XLEN-1:0] HREADSDC,
   output logic 	    HRESPSDC, 
   output logic 	    HREADYSDC,

   //sd card interface
   // place the tristate drivers at the top.  this level
   // will use dedicated 1 direction ports.
   output logic 	    SDCmdOut,
   input logic 		    SDCmdIn,
   output logic 	    SDCmdOE,
   input logic 		    SDDatIn,
   output logic 	    SDCLK,

   // interrupt to PLIC
   output logic 	    SDCIntM);

  logic 		    initTrans;
  logic 		    RegRead;
  logic 		    RegWrite;

  // *** reduce size later
  logic [31:0] 		    CLKDiv;
  

  // registers
  //| Offset | Name    | Size | Purpose                                        |
  //|--------+---------+------+------------------------------------------------|
  //|    0x0 | CLKDiv  |    4 | Divide HCLK to produce SDCLK                   |
  //|    0x4 | Status  |    4 | Provide status to software                     |
  //|    0x8 | Control |    4 | Send commands to SDC                           |
  //|    0xC | Size    |    4 | Size of data command (only 512 byte supported) |
  //|   0x10 | address |    8 | address of operation                           |
  //|   0x18 | data    |    8 | Data Bus interface                             |  
  
  // Currently using a mailbox style interface.   Data is passed through the Data register (0x10)
  // The card will support 3 operations
  // 1. initialize
  // 2. read
  // 3. write
  // all read and write operations will occur on 512 bytes (4096 bits) of data
  // starting at the 512 byte aligned address in the address register  This register
  // is the byte address.

  // currently does not support writes

  assign InitTrans = HREADY & HSELTSDC & (HTRANS != 2'b00);
  assign RegWrite = InitTrans & HWRITE;
  assign RegRead = InitTrans & ~HWRITE;  

  // *** need to delay
  flopenl #(32) CLKDivReg(HCLK, ~HRESETn, , HADDR == '0 & RegWrite, HWRITE, `SDCCLKDIV, CLKDiv);
  
  
endmodule
	    

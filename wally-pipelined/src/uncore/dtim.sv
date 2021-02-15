///////////////////////////////////////////
// dtim.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Data tightly integrated memory
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

module dtim (
  input  logic             HCLK, HRESETn, 
  input  logic [1:0]       MemRWtim,
  input  logic [18:0]      HADDR, 
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             HSELTim,
  output logic [`XLEN-1:0] HREADTim,
  output logic             HRESPTim, HREADYTim
);

  logic [`XLEN-1:0] RAM[0:65535];
  logic [18:0] HWADDR;
  logic [`XLEN-1:0] HREADTim0;

//  logic [`XLEN-1:0] write;
  logic [15:0] entry;
  logic            memread, memwrite;
  logic [3:0] busycount;

  // busy FSM to extend READY signal
  always_ff @(posedge HCLK, negedge HRESETn) 
    if (~HRESETn) begin
      HREADYTim <= 1;
    end else begin
      if (HREADYTim & HSELTim) begin
        busycount <= 0;
        HREADYTim <= #1 0;
      end else if (~HREADYTim) begin
        if (busycount == 2) begin // TIM latency, for testing purposes
          HREADYTim <= #1 1;
        end else begin
          busycount <= busycount + 1;
        end
      end
    end

 /* always_ff @(posedge HCLK, negedge HRESETn) 
    if (~HRESETn) begin
      HREADYTim <= 0;
    end else begin
      HREADYTim <= HSELTim; // always respond one cycle later
    end */


  assign memread = MemRWtim[1];
  assign memwrite = MemRWtim[0];
//  always_ff @(posedge HCLK)
//    memwrite <= MemRWtim[0]; // delay memwrite to write phase
  assign HRESPTim = 0; // OK
//  assign HREADYTim = 1; // Respond immediately; *** extend this 


  // Model memory read and write
  
  generate
    if (`XLEN == 64)  begin
//      always_ff @(negedge HCLK) 
//        if (memwrite) RAM[HWADDR[17:3]] <= HWDATA;
      always_ff @(posedge HCLK) begin
        //if (memwrite) RAM[HADDR[17:3]] <= HWDATA;  
        HWADDR <= HADDR;
        HREADTim0 <= RAM[HADDR[17:3]];
        if (memwrite && HREADYTim) RAM[HWADDR[17:3]] <= HWDATA;
      end
    end else begin 
//      always_ff @(negedge HCLK) 
//        if (memwrite) RAM[HWADDR[17:2]] <= HWDATA;
      always_ff @(posedge HCLK) begin
        //if (memwrite) RAM[HADDR[17:2]] <= HWDATA;
        HWADDR <= HADDR;  
        HREADTim0 <= RAM[HADDR[17:2]];
        if (memwrite && HREADYTim) RAM[HWADDR[17:2]] <= HWDATA;
      end
    end
  endgenerate

  assign HREADTim = HREADYTim ? HREADTim0 : 'bz;
endmodule


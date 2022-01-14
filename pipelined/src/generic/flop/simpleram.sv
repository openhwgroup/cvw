///////////////////////////////////////////
// simpleram.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: On-chip SIMPLERAM, external to hart
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

module simpleram #(parameter BASE=0, RANGE = 65535) (
  input  logic             HCLK, HRESETn, 
  input  logic             HSELRam,
  input  logic [31:0]      HADDR,
  input  logic             HWRITE,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  input  logic [`XLEN-1:0] HWDATA,
  output logic [`XLEN-1:0] HREADRam,
  output logic             HRESPRam, HREADYRam
);

  localparam MemStartAddr = BASE>>(1+`XLEN/32);
  localparam MemEndAddr = (RANGE+BASE)>>1+(`XLEN/32);
  
  logic [`XLEN-1:0] RAM[BASE>>(1+`XLEN/32):(RANGE+BASE)>>1+(`XLEN/32)];
  logic [31:0] HWADDR, A;
  logic [`XLEN-1:0] HREADRam0;

  logic        prevHREADYRam, risingHREADYRam;
  logic        initTrans;
  logic        memwrite;
  logic [3:0]  busycount;

  
  /* verilator lint_off WIDTH */
  if (`XLEN == 64)  begin:ramrw
    always_ff @(posedge HCLK) begin
      if (HWRITE & |HTRANS) RAM[HADDR[31:3]] <= #1 HWDATA;
    end
  end else begin 
    always_ff @(posedge HCLK) begin:ramrw
      if (HWRITE & |HTRANS) RAM[HADDR[31:2]] <= #1 HWDATA;
    end
  end

  // read
  if(`XLEN == 64) begin: ramr
    assign HREADRam0 = RAM[HADDR[31:3]];
  end else begin
    assign HREADRam0 = RAM[HADDR[31:2]];
  end

  /* verilator lint_on WIDTH */

  assign HREADRam = HREADRam0;
endmodule


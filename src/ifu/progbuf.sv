///////////////////////////////////////////
// progbuf.sv
//
// Written: matthew.n.otto@okstate.edu
// Created: 18 June 2024
//
// Purpose: Holds small programs to be executed in debug mode
//          This module acts like a small ROM except it can be written by serial Scanning via the Debug Module
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License Version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module progbuf import cvw::*;  #(parameter cvw_t P) (
    input  logic        clk, reset,
    input  logic [3:0]  Addr,
    output logic [31:0] ProgBufInstrF,

    input  logic [3:0]  ScanAddr,
    input  logic        Scan,
    input  logic        ScanIn
);

  localparam PROGBUF_SIZE = (P.PROGBUF_RANGE+1)/4;
  localparam ADDR_WIDTH = $clog2(PROGBUF_SIZE);
  
  bit [31:0] RAM [PROGBUF_SIZE-1:0];

  logic EnPrevClk;
  logic WriteProgBuf;
  logic [32:0] WriteData;
  logic [ADDR_WIDTH-1:0] AddrM;

  flopr #(1) Scanenhist (.clk, .reset, .d(Scan), .q(EnPrevClk));
  assign WriteProgBuf = ~Scan & EnPrevClk;

  assign WriteData[32] = ScanIn;
  genvar i;
  for (i=0; i<32; i=i+1) begin
    flopenr #(1) Scanreg (.clk, .reset, .en(Scan), .d(WriteData[i+1]), .q(WriteData[i]));
  end

  assign AddrM = WriteProgBuf ? ScanAddr[ADDR_WIDTH-1:0] : Addr[ADDR_WIDTH-1:0];

  always_ff @(posedge clk) begin
    if (WriteProgBuf)
      RAM[AddrM] <= WriteData;
    if (reset)
      ProgBufInstrF <= 0;
    else
      ProgBufInstrF <= RAM[AddrM];
  end

endmodule

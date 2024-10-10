///////////////////////////////////////////
// fetchbuffer.sv
//
// Written: chickson@hmc.edu ; vkrishna@hmc.edu
// Created: 30 September 2024
// Modified: 3 October 2024
//
// Purpose: Store multiple instructions in a cyclic FIFO
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
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

module fetchbuffer import cvw::*; #(parameter cvw_t P) (
	input  logic        clk, reset,
	input  logic        StallD, FlushD,
	input  logic [31:0] WriteData,
	output logic [31:0] ReadData,
	output logic        FetchBufferStallF
);
  localparam [31:0] nop = 32'h00000013;
  logic      [31:0] Readf0, Readf1, Readf2, ReadFetchBuffer;
  logic      [2:0]  ReadPtr, WritePtr;
  logic             Empty, Full;

  assign Empty  = |(ReadPtr & WritePtr); // Bitwise and the read&write ptr, and or the bits of the result together
  assign Full   = |({WritePtr[1:0], WritePtr[2]} & ReadPtr); // Same as above but left rotate WritePtr to "add 1"
  assign FetchBufferStallF = Full;

  // will go in a generate block once this is parameterized
  flopenr #(32) f0 (.clk, .reset(reset | FlushD), .en(WritePtr[0]), .d(WriteData), .q(Readf0));
  flopenr #(32) f1 (.clk, .reset(reset | FlushD), .en(WritePtr[1]), .d(WriteData), .q(Readf1));
  flopenr #(32) f2 (.clk, .reset(reset | FlushD), .en(WritePtr[2]), .d(WriteData), .q(Readf2));

  // always_comb begin : readMuxes
  //   // Mux read data from the three registers
  //   case (ReadPtr)
  //     3'b001:  ReadFetchBuffer = Readf0;
  //     3'b010:  ReadFetchBuffer = Readf1;
  //     3'b100:  ReadFetchBuffer = Readf2;
  //     default: ReadFetchBuffer = nop; // just in case?
  //   endcase
  //   // issue nop when appropriate
  //   ReadData = Empty ? nop : ReadFetchBuffer;
  // end


  // Fetch buffer entries anded with read ptr for AO Muxing
  logic [31:0] DaoArr [2:0];
  //     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Make parameterizable
  assign DaoArr[0] = ReadPtr[0] ? Readf0 : '0;
  assign DaoArr[1] = ReadPtr[1] ? Readf1 : '0;
  assign DaoArr[2] = ReadPtr[2] ? Readf2 : '0;

  or_rows #(3, 32) ReadFBAOMux(.a(DaoArr), .y(ReadFetchBuffer));
  //        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Make parameterizable

  assign ReadData = Empty ? nop : ReadFetchBuffer;

  always_ff @(posedge clk) begin : shiftRegister
    if (reset) begin
      WritePtr <= 3'b001;
      ReadPtr  <= 3'b001;
    end else begin
      WritePtr <= ~Full ? {WritePtr[1:0], WritePtr[2]} : WritePtr;
      ReadPtr <= ~(StallD | Empty) ? {ReadPtr[1:0], ReadPtr[2]} : ReadPtr;
    end
  end
endmodule

///////////////////////////////////////////
// atomic.sv
//
// Written: Ross Thompson ross1728@gmail.com January 31, 2022
// Modified:
//
// Purpose: atomic data path.
// 
// A component of the CORE-V Wally configurable RISC-V project.
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

`include "wally-config.vh"

module atomic (
  input logic                clk,
  input logic                reset, StallW,
  input logic [`XLEN-1:0]    ReadDataM,
  input logic [`XLEN-1:0]    IHWriteDataM, 
  input logic [`PA_BITS-1:0] PAdrM,
  input logic [6:0]          LSUFunct7M,
  input logic [2:0]          LSUFunct3M,
  input logic [1:0]          LSUAtomicM,
  input logic [1:0]          PreLSURWM,
  input logic                IgnoreRequest,
  output logic [`XLEN-1:0]   IMAWriteDataM,
  output logic               SquashSCW,
  output logic [1:0]         LSURWM);

  logic [`XLEN-1:0] AMOResult;
  logic               MemReadM;

  amoalu amoalu(.srca(ReadDataM), .srcb(IHWriteDataM), .funct(LSUFunct7M), .width(LSUFunct3M[1:0]), 
                .result(AMOResult));
  mux2 #(`XLEN) wdmux(IHWriteDataM, AMOResult, LSUAtomicM[1], IMAWriteDataM);
  assign MemReadM = PreLSURWM[1] & ~IgnoreRequest;
  lrsc lrsc(.clk, .reset, .StallW, .MemReadM, .PreLSURWM, .LSUAtomicM, .PAdrM,
    .SquashSCW, .LSURWM);

endmodule  

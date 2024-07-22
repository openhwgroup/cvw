///////////////////////////////////////////
// rvvisynth.sv
//
// Written: Rose Thompson ross1728@gmail.com
// Created: 23 January 2024
// Modified: 23 January 2024
//
// Purpose: Synthesizable rvvi bridge from Wally to generic compressed format.
//
// Documentation: 
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

`define FPGA 0

module rvvisynth import cvw::*; #(parameter cvw_t P,
                                  parameter integer MAX_CSRS, TOTAL_CSRS = 36)(
  input logic clk, reset,
  input logic                                     StallE, StallM, StallW, FlushE, FlushM, FlushW,
  // required
  input logic [P.XLEN-1:0]                        PCM,
  input logic                                     InstrValidM,
  input logic [31:0]                              InstrRawD,
  input logic [63:0]                              Mcycle, Minstret,
  input logic                                     TrapM,
  input logic [1:0]                               PrivilegeModeW,
  // registers gpr and fpr
  input logic                                     GPRWen, FPRWen,
  input logic [4:0]                               GPRAddr, FPRAddr,
  input logic [P.XLEN-1:0]                        GPRValue, FPRValue,
  input logic [P.XLEN-1:0]                        CSRArray [TOTAL_CSRS-1:0],
  output logic valid,
  output logic [187+(3*P.XLEN) + MAX_CSRS*(P.XLEN+12)-1:0] rvvi
  );

  // pipeline controlls

  // required
  logic [P.XLEN-1:0]                        PCW;
  logic                                     InstrValidW;
  logic [31:0]                              InstrRawE, InstrRawM, InstrRawW;
  logic                                     TrapW;

  // registers gpr and fpr
  logic [P.XLEN-1:0]                        XLENZeros;
  logic [TOTAL_CSRS-1:0]                    CSRArrayWen;
  logic [P.XLEN-1:0]                        CSRValue [MAX_CSRS-1:0];
  logic [TOTAL_CSRS-1:0]                    CSRWen [MAX_CSRS-1:0];
  logic [11:0]                              CSRAddr [MAX_CSRS-1:0];
  logic [MAX_CSRS-1:0]                      EnabledCSRs;
  logic [11:0]                              CSRCount;
  logic [177+P.XLEN-1:0]                    Required;
  logic [10+2*P.XLEN-1:0]                   Registers;
  logic [MAX_CSRS*(P.XLEN+12)-1:0]          CSRs;
     
  assign XLENZeros = '0;

  // start out easy and just populate Required
  // PC, inst, mcycle, minstret, trap, mode
  
  flopenrc #(1)      InstrValidMReg (clk, reset, FlushW, ~StallW, InstrValidM, InstrValidW);
  flopenrc #(P.XLEN) PCWReg (clk, reset, FlushW, ~StallW, PCM, PCW);
  flopenrc #(32)     InstrRawEReg (clk, reset, FlushE, ~StallE, InstrRawD, InstrRawE);
  flopenrc #(32)     InstrRawMReg (clk, reset, FlushM, ~StallM, InstrRawE, InstrRawM);
  flopenrc #(32)     InstrRawWReg (clk, reset, FlushW, ~StallW, InstrRawM, InstrRawW);
  flopenrc #(1)      TrapWReg (clk, reset, 1'b0, ~StallW, TrapM, TrapW);

  assign valid  = InstrValidW & ~StallW;
  assign Required = {CSRCount, FPRWen, GPRWen, PrivilegeModeW, TrapW, Minstret, Mcycle, InstrRawW, PCW};
  assign Registers = {FPRWen, GPRWen} == 2'b11 ? {FPRValue, FPRAddr, GPRValue, GPRAddr} :
                     {FPRWen, GPRWen} == 2'b01 ? {XLENZeros, 5'b0, GPRValue, GPRAddr} :
                     {FPRWen, GPRWen} == 2'b10 ? {XLENZeros, 5'b0, FPRValue, FPRAddr} :
                     '0;

  // the CSRs are complex
  // 1. we need to get the CSR values
  // 2. we check if the CSR value changes by registering the value then XORing with the old value.
  // 3. Then use priorityaomux to collect CSR values and addresses for compating into the compressed rvvi format

  // step 2
  genvar                                    index;
  for (index = 0; index < TOTAL_CSRS; index = index + 1) begin
    regchangedetect #(P.XLEN) changedetect(clk, reset, CSRArray[index], CSRArrayWen[index]);
  end

  // step 3a
  for(index = 0; index < MAX_CSRS; index = index + 1) begin
    logic [MAX_CSRS-index-1:0] CSRWenShort;
    priorityaomux #(MAX_CSRS-index, P.XLEN) priorityaomux(CSRArrayWen[MAX_CSRS-1:index], CSRArray[MAX_CSRS-1:index], CSRValue[index], CSRWenShort);
    assign CSRWen[index] = {{{index}{1'b0}}, CSRWenShort};
    // step 3b
    csrindextoaddr #(TOTAL_CSRS) csrindextoaddr(CSRWen[index], CSRAddr[index]);
    assign CSRs[(index+1) * (P.XLEN + 12)- 1: index * (P.XLEN + 12)] = {CSRValue[index], CSRAddr[index]};
    assign EnabledCSRs[index] = |CSRWenShort;
  end
  assign CSRCount = +EnabledCSRs;
  assign rvvi = {CSRs, Registers, Required};
  
endmodule
                                                                 

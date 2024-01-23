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

module rvvisynth import cvw::*; #(parameter cvw_t P,
                                  parameter integer MAX_CSR)(
  input logic clk, reset,
  output logic valid,
  output logic [163+P.XLEN-1:0] Requied,
  output logic [12+2*P.XLEN-1:0] Registers,
  output logic [12+MAX_CSR*(P.XLEN+12)-1:0] CSRs
  );

  // pipeline controlls
  logic                                     StallW, FlushW;
  // required
  logic [P.XLEN-1:0]                        PCM, PCW;
  logic                                     InstrValidM, InstrValidW;
  logic [31:0]                              InstrRawD, InstrRawE, InstrRawM, InstrRawW;
  logic [63:0]                              Mcycle, Minstret;
  logic                                     TrapM, TrapW;
  logic [1:0]                               PrivilegeModeW;
  // registers gpr and fpr
  logic                                     GPRWen, FPRWen;
  logic [4:0]                               GPRAddr, FPRAddr;
  logic [P.XLEN-1:0]                        GPRValue, FPRValue;
  logic [P.XLEN-1:0]                        XLENZeros;
   
  // get signals from the core.
  assign StallW         = testbench.dut.core.StallW;
  assign FlushW         = testbench.dut.core.FlushW;
  assign InstrValidM    = testbench.dut.core.ieu.InstrValidM;
  assign InstrRawD      = testbench.dut.core.ifu.InstrRawD;
  assign PCM            = testbench.dut.core.ifu.PCM;
  assign Mcycle         = testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[0];
  assign Minstret       = testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2];
  assign TrapM          = testbench.dut.core.TrapM;
  assign PrivilegeModeW = testbench.dut.core.priv.priv.privmode.PrivilegeModeW;
  assign GPRAddr        = testbench.dut.core.ieu.dp.regf.a3;
  assign GPRWen         = testbench.dut.core.ieu.dp.regf.we3;
  assign GPRValue       = testbench.dut.core.ieu.dp.regf.wd3;
  assign FPRAddr        = testbench.dut.core.fpu.fpu.fregfile.a4;
  assign FPRWen         = testbench.dut.core.fpu.fpu.fregfile.we4;
  assign FPRValue       = testbench.dut.core.fpu.fpu.fregfile.wd4;


  //
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
  assign Required = {PrivilegeModeW, TrapW, Minstret, Mcycle, InstrRawW, PCW};
  assign Registers = {FPRWen, GPRWen} == 2'b11 ? {FPRValue, FPRAddr, GPRValue, GPRAddr, FPRWen, GPRWen} :
                     {FPRWen, GPRWen} == 2'b01 ? {XLENZeros, 5'b0, GPRValue, GPRAddr, FPRWen, GPRWen} :
                     {FPRWen, GPRWen} == 2'b10 ? {FPRValue, FPRAddr, XLENZeros, 5'b0, FPRWen, GPRWen} :
                     {XLENZeros, 5'b0, XLENZeros, 5'b0, FPRWen, GPRWen};

endmodule
                                                                 

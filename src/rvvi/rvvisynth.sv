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

`define FPGA 1

module rvvisynth import cvw::*; #(parameter cvw_t P,
                                  parameter integer MAX_CSRS)(
  input logic clk, reset,
  output logic valid,
  output logic [187+(3*P.XLEN) + MAX_CSRS*(P.XLEN+12)-1:0] rvvi
  );

  localparam TOTAL_CSRS = 36;
  
  // pipeline controlls
  logic                                     StallE, StallM, StallW, FlushE, FlushM, FlushW;
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
  logic [P.XLEN-1:0]                        CSRArray [TOTAL_CSRS-1:0];
  logic [TOTAL_CSRS-1:0]                    CSRArrayWen;
  logic [P.XLEN-1:0]                        CSRValue [MAX_CSRS-1:0];
  logic [TOTAL_CSRS-1:0]                    CSRWen [MAX_CSRS-1:0];
  logic [11:0]                              CSRAddr [MAX_CSRS-1:0];
  logic [MAX_CSRS-1:0]                      EnabledCSRs;
  logic [11:0]                              CSRCount;
  logic [177+P.XLEN-1:0]                    Required;
  logic [10+2*P.XLEN-1:0]                   Registers;
  logic [MAX_CSRS*(P.XLEN+12)-1:0]       CSRs;
     
  // get signals from the core.
   if (`FPGA) begin
  assign StallE         = fpgaTop.wallypipelinedsoc.core.StallE;
  assign StallM         = fpgaTop.wallypipelinedsoc.core.StallM;
  assign StallW         = fpgaTop.wallypipelinedsoc.core.StallW;
  assign FlushE         = fpgaTop.wallypipelinedsoc.core.FlushE;
  assign FlushM         = fpgaTop.wallypipelinedsoc.core.FlushM;
  assign FlushW         = fpgaTop.wallypipelinedsoc.core.FlushW;
  assign InstrValidM    = fpgaTop.wallypipelinedsoc.core.ieu.InstrValidM;
  assign InstrRawD      = fpgaTop.wallypipelinedsoc.core.ifu.InstrRawD;
  assign PCM            = fpgaTop.wallypipelinedsoc.core.ifu.PCM;
  assign Mcycle         = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[0];
  assign Minstret       = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2];
  assign TrapM          = fpgaTop.wallypipelinedsoc.core.TrapM;
  assign PrivilegeModeW = fpgaTop.wallypipelinedsoc.core.priv.priv.privmode.PrivilegeModeW;
  assign GPRAddr        = fpgaTop.wallypipelinedsoc.core.ieu.dp.regf.a3;
  assign GPRWen         = fpgaTop.wallypipelinedsoc.core.ieu.dp.regf.we3;
  assign GPRValue       = fpgaTop.wallypipelinedsoc.core.ieu.dp.regf.wd3;
  assign FPRAddr        = fpgaTop.wallypipelinedsoc.core.fpu.fpu.fregfile.a4;
  assign FPRWen         = fpgaTop.wallypipelinedsoc.core.fpu.fpu.fregfile.we4;
  assign FPRValue       = fpgaTop.wallypipelinedsoc.core.fpu.fpu.fregfile.wd4;

  assign CSRArray[0] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MSTATUS_REGW; // 12'h300
  assign CSRArray[1] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MSTATUSH_REGW; // 12'h310
  assign CSRArray[2] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MTVEC_REGW; // 12'h305
  assign CSRArray[3] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MEPC_REGW; // 12'h341
  assign CSRArray[4] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MCOUNTEREN_REGW; // 12'h306
  assign CSRArray[5] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MCOUNTINHIBIT_REGW; // 12'h320
  assign CSRArray[6] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MEDELEG_REGW; // 12'h302
  assign CSRArray[7] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MIDELEG_REGW; // 12'h303
  assign CSRArray[8] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MIP_REGW; // 12'h344
  assign CSRArray[9] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MIE_REGW; // 12'h304
  assign CSRArray[10] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MISA_REGW; // 12'h301
  assign CSRArray[11] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MENVCFG_REGW; // 12'h30A
  assign CSRArray[12] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MHARTID_REGW; // 12'hF14
  assign CSRArray[13] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MSCRATCH_REGW; // 12'h340
  assign CSRArray[14] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MCAUSE_REGW; // 12'h342
  assign CSRArray[15] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MTVAL_REGW; // 12'h343
  assign CSRArray[16] = 0; // 12'hF11
  assign CSRArray[17] = 0; // 12'hF12
  assign CSRArray[18] = {{P.XLEN-12{1'b0}}, 12'h100}; //P.XLEN'h100; // 12'hF13
  assign CSRArray[19] = 0; // 12'hF15
  assign CSRArray[20] = 0; // 12'h34A
	  // supervisor CSRs
  assign CSRArray[21] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.SSTATUS_REGW; // 12'h100
  assign CSRArray[22] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MIE_REGW & 12'h222; // 12'h104
  assign CSRArray[23] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.STVEC_REGW; // 12'h105
  assign CSRArray[24] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.SEPC_REGW; // 12'h141
  assign CSRArray[25] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.SCOUNTEREN_REGW; // 12'h106
  assign CSRArray[26] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.SENVCFG_REGW; // 12'h10A
  assign CSRArray[27] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.SATP_REGW; // 12'h180
  assign CSRArray[28] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.SSCRATCH_REGW; // 12'h140
  assign CSRArray[29] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.STVAL_REGW; // 12'h143
  assign CSRArray[30] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.SCAUSE_REGW; // 12'h142
  assign CSRArray[31] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MIP_REGW & 12'h222 & fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrm.MIDELEG_REGW; // 12'h144
  assign CSRArray[32] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csrs.csrs.STIMECMP_REGW; // 12'h14D
	  // user CSRs
  assign CSRArray[33] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csru.csru.FFLAGS_REGW; // 12'h001
  assign CSRArray[34] = fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csru.csru.FRM_REGW; // 12'h002
  assign CSRArray[35] = {fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csru.csru.FRM_REGW, fpgaTop.wallypipelinedsoc.core.priv.priv.csr.csru.csru.FFLAGS_REGW}; // 12'h003
   end else begin // if (`FPGA)
        assign StallE         = dut.core.StallE;
  assign StallM         = dut.core.StallM;
  assign StallW         = dut.core.StallW;
  assign FlushE         = dut.core.FlushE;
  assign FlushM         = dut.core.FlushM;
  assign FlushW         = dut.core.FlushW;
  assign InstrValidM    = dut.core.ieu.InstrValidM;
  assign InstrRawD      = dut.core.ifu.InstrRawD;
  assign PCM            = dut.core.ifu.PCM;
  assign Mcycle         = dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[0];
  assign Minstret       = dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2];
  assign TrapM          = dut.core.TrapM;
  assign PrivilegeModeW = dut.core.priv.priv.privmode.PrivilegeModeW;
  assign GPRAddr        = dut.core.ieu.dp.regf.a3;
  assign GPRWen         = dut.core.ieu.dp.regf.we3;
  assign GPRValue       = dut.core.ieu.dp.regf.wd3;
  assign FPRAddr        = dut.core.fpu.fpu.fregfile.a4;
  assign FPRWen         = dut.core.fpu.fpu.fregfile.we4;
  assign FPRValue       = dut.core.fpu.fpu.fregfile.wd4;

  assign CSRArray[0] = dut.core.priv.priv.csr.csrm.MSTATUS_REGW; // 12'h300
  assign CSRArray[1] = dut.core.priv.priv.csr.csrm.MSTATUSH_REGW; // 12'h310
  assign CSRArray[2] = dut.core.priv.priv.csr.csrm.MTVEC_REGW; // 12'h305
  assign CSRArray[3] = dut.core.priv.priv.csr.csrm.MEPC_REGW; // 12'h341
  assign CSRArray[4] = dut.core.priv.priv.csr.csrm.MCOUNTEREN_REGW; // 12'h306
  assign CSRArray[5] = dut.core.priv.priv.csr.csrm.MCOUNTINHIBIT_REGW; // 12'h320
  assign CSRArray[6] = dut.core.priv.priv.csr.csrm.MEDELEG_REGW; // 12'h302
  assign CSRArray[7] = dut.core.priv.priv.csr.csrm.MIDELEG_REGW; // 12'h303
  assign CSRArray[8] = dut.core.priv.priv.csr.csrm.MIP_REGW; // 12'h344
  assign CSRArray[9] = dut.core.priv.priv.csr.csrm.MIE_REGW; // 12'h304
  assign CSRArray[10] = dut.core.priv.priv.csr.csrm.MISA_REGW; // 12'h301
  assign CSRArray[11] = dut.core.priv.priv.csr.csrm.MENVCFG_REGW; // 12'h30A
  assign CSRArray[12] = dut.core.priv.priv.csr.csrm.MHARTID_REGW; // 12'hF14
  assign CSRArray[13] = dut.core.priv.priv.csr.csrm.MSCRATCH_REGW; // 12'h340
  assign CSRArray[14] = dut.core.priv.priv.csr.csrm.MCAUSE_REGW; // 12'h342
  assign CSRArray[15] = dut.core.priv.priv.csr.csrm.MTVAL_REGW; // 12'h343
  assign CSRArray[16] = 0; // 12'hF11
  assign CSRArray[17] = 0; // 12'hF12
  assign CSRArray[18] = {{P.XLEN-12{1'b0}}, 12'h100}; //P.XLEN'h100; // 12'hF13
  assign CSRArray[19] = 0; // 12'hF15
  assign CSRArray[20] = 0; // 12'h34A
	  // supervisor CSRs
  assign CSRArray[21] = dut.core.priv.priv.csr.csrs.csrs.SSTATUS_REGW; // 12'h100
  assign CSRArray[22] = dut.core.priv.priv.csr.csrm.MIE_REGW & 12'h222; // 12'h104
  assign CSRArray[23] = dut.core.priv.priv.csr.csrs.csrs.STVEC_REGW; // 12'h105
  assign CSRArray[24] = dut.core.priv.priv.csr.csrs.csrs.SEPC_REGW; // 12'h141
  assign CSRArray[25] = dut.core.priv.priv.csr.csrs.csrs.SCOUNTEREN_REGW; // 12'h106
  assign CSRArray[26] = dut.core.priv.priv.csr.csrs.csrs.SENVCFG_REGW; // 12'h10A
  assign CSRArray[27] = dut.core.priv.priv.csr.csrs.csrs.SATP_REGW; // 12'h180
  assign CSRArray[28] = dut.core.priv.priv.csr.csrs.csrs.SSCRATCH_REGW; // 12'h140
  assign CSRArray[29] = dut.core.priv.priv.csr.csrs.csrs.STVAL_REGW; // 12'h143
  assign CSRArray[30] = dut.core.priv.priv.csr.csrs.csrs.SCAUSE_REGW; // 12'h142
  assign CSRArray[31] = dut.core.priv.priv.csr.csrm.MIP_REGW & 12'h222 & dut.core.priv.priv.csr.csrm.MIDELEG_REGW; // 12'h144
  assign CSRArray[32] = dut.core.priv.priv.csr.csrs.csrs.STIMECMP_REGW; // 12'h14D
	  // user CSRs
  assign CSRArray[33] = dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW; // 12'h001
  assign CSRArray[34] = dut.core.priv.priv.csr.csru.csru.FRM_REGW; // 12'h002
  assign CSRArray[35] = {dut.core.priv.priv.csr.csru.csru.FRM_REGW, dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW}; // 12'h003
   end

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
                                                                 

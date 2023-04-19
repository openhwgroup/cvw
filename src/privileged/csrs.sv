///////////////////////////////////////////
// csrs.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//          dottolia@hmc.edu 3 May 2021 - fix bug with stvec getting wrong value
//
// Purpose: Supervisor-Mode Control and Status Registers
//          See RISC-V Privileged Mode Specification 20190608 
//
// Documentation: RISC-V System on Chip Design Chapter 5
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

`include "wally-config.vh"

module csrs import cvw::*;  #(parameter cvw_t P, 
  // Supervisor CSRs
  SSTATUS = 12'h100,
  SIE = 12'h104,
  STVEC = 12'h105,
  SCOUNTEREN = 12'h106,
  SSCRATCH = 12'h140,
  SEPC = 12'h141,
  SCAUSE = 12'h142,
  STVAL = 12'h143,
  SIP= 12'h144,
  STIMECMP = 12'h14D,
  STIMECMPH = 12'h15D,
  SATP = 12'h180) (
  input  logic             clk, reset, 
  input  logic             CSRSWriteM, STrapM,
  input  logic [11:0]      CSRAdrM,
  input  logic [P.XLEN-1:0] NextEPCM, NextMtvalM, SSTATUS_REGW, 
  input  logic [4:0]       NextCauseM,
  input  logic             STATUS_TVM,
  input  logic             MCOUNTEREN_TM, // TM bit (1) of MCOUNTEREN; cause illegal instruction when trying to access STIMECMP if clear
  input  logic [P.XLEN-1:0] CSRWriteValM,
  input  logic [1:0]       PrivilegeModeW,
  output logic [P.XLEN-1:0] CSRSReadValM, STVEC_REGW,
  output logic [P.XLEN-1:0] SEPC_REGW,      
  output logic [31:0]      SCOUNTEREN_REGW, 
  output logic [P.XLEN-1:0] SATP_REGW,
  input  logic [11:0]      MIP_REGW, MIE_REGW, MIDELEG_REGW,
  input  logic [63:0]      MTIME_CLINT,
  output logic             WriteSSTATUSM,
  output logic             IllegalCSRSAccessM,
  output logic             STimerInt
);

  // Constants
  localparam ZERO = {(P.XLEN){1'b0}};
  localparam SEDELEG_MASK = ~(ZERO | `XLEN'b111 << 9);

  logic                    WriteSTVECM;
  logic                    WriteSSCRATCHM, WriteSEPCM;
  logic                    WriteSCAUSEM, WriteSTVALM, WriteSATPM, WriteSCOUNTERENM;
  logic                    WriteSTIMECMPM, WriteSTIMECMPHM;
  logic [P.XLEN-1:0]        SSCRATCH_REGW, STVAL_REGW, SCAUSE_REGW;
  logic [63:0]             STIMECMP_REGW;
  
  // write enables
  assign WriteSSTATUSM = CSRSWriteM & (CSRAdrM == SSTATUS);
  assign WriteSTVECM = CSRSWriteM & (CSRAdrM == STVEC);
  assign WriteSSCRATCHM = CSRSWriteM & (CSRAdrM == SSCRATCH);
  assign WriteSEPCM = STrapM | (CSRSWriteM & (CSRAdrM == SEPC));
  assign WriteSCAUSEM = STrapM | (CSRSWriteM & (CSRAdrM == SCAUSE));
  assign WriteSTVALM = STrapM | (CSRSWriteM & (CSRAdrM == STVAL));
  assign WriteSATPM = CSRSWriteM & (CSRAdrM == SATP) & (PrivilegeModeW == P.M_MODE | ~STATUS_TVM);
  assign WriteSCOUNTERENM = CSRSWriteM & (CSRAdrM == SCOUNTEREN);
  assign WriteSTIMECMPM = CSRSWriteM & (CSRAdrM == STIMECMP) & (PrivilegeModeW == P.M_MODE | MCOUNTEREN_TM);
  assign WriteSTIMECMPHM = CSRSWriteM & (CSRAdrM == STIMECMPH) & (PrivilegeModeW == P.M_MODE | MCOUNTEREN_TM) & (P.XLEN == 32);

  // CSRs
  flopenr #(P.XLEN) STVECreg(clk, reset, WriteSTVECM, {CSRWriteValM[P.XLEN-1:2], 1'b0, CSRWriteValM[0]}, STVEC_REGW); 
  flopenr #(P.XLEN) SSCRATCHreg(clk, reset, WriteSSCRATCHM, CSRWriteValM, SSCRATCH_REGW);
  flopenr #(P.XLEN) SEPCreg(clk, reset, WriteSEPCM, NextEPCM, SEPC_REGW); 
  flopenr #(P.XLEN) SCAUSEreg(clk, reset, WriteSCAUSEM, {NextCauseM[4], {(P.XLEN-5){1'b0}}, NextCauseM[3:0]}, SCAUSE_REGW);
  flopenr #(P.XLEN) STVALreg(clk, reset, WriteSTVALM, NextMtvalM, STVAL_REGW);
  if (P.VIRTMEM_SUPPORTED)
    flopenr #(P.XLEN) SATPreg(clk, reset, WriteSATPM, CSRWriteValM, SATP_REGW);
  else
    assign SATP_REGW = 0; // hardwire to zero if virtual memory not supported
  flopenr #(32)   SCOUNTERENreg(clk, reset, WriteSCOUNTERENM, CSRWriteValM[31:0], SCOUNTEREN_REGW);
  if (P.SSTC_SUPPORTED) begin : sstc
    if (P.XLEN == 64) begin : sstc64
      flopenl #(P.XLEN) STIMECMPreg(clk, reset, WriteSTIMECMPM, CSRWriteValM, 64'hFFFFFFFFFFFFFFFF, STIMECMP_REGW);
    end else begin : sstc32
      flopenl #(P.XLEN) STIMECMPreg(clk, reset, WriteSTIMECMPM, CSRWriteValM, 32'hFFFFFFFF, STIMECMP_REGW[31:0]);
      flopenl #(P.XLEN) STIMECMPHreg(clk, reset, WriteSTIMECMPHM, CSRWriteValM, 32'hFFFFFFFF, STIMECMP_REGW[63:32]);
    end
  end else assign STIMECMP_REGW = 0;

  // Supervisor timer interrupt logic
  // Spec is a bit peculiar - Machine timer interrupts are produced in CLINT, while Supervisor timer interrupts are in CSRs
  if (P.SSTC_SUPPORTED)
   assign STimerInt = ({1'b0, MTIME_CLINT} >= {1'b0, STIMECMP_REGW}); // unsigned comparison
  else 
    assign STimerInt = 0;
    
  // CSR Reads
  always_comb begin:csrr
    IllegalCSRSAccessM = 0;
    case (CSRAdrM) 
      SSTATUS:   CSRSReadValM = SSTATUS_REGW;
      STVEC:     CSRSReadValM = STVEC_REGW;
      SIP:       CSRSReadValM = {{(P.XLEN-12){1'b0}}, MIP_REGW & 12'h222 & MIDELEG_REGW}; // only read supervisor fields  
      SIE:       CSRSReadValM = {{(P.XLEN-12){1'b0}}, MIE_REGW & 12'h222 & MIDELEG_REGW}; // only read supervisor fields
      SSCRATCH:  CSRSReadValM = SSCRATCH_REGW;
      SEPC:      CSRSReadValM = SEPC_REGW;
      SCAUSE:    CSRSReadValM = SCAUSE_REGW;
      STVAL:     CSRSReadValM = STVAL_REGW;
      SATP:      if (P.VIRTMEM_SUPPORTED & (PrivilegeModeW == P.M_MODE | ~STATUS_TVM)) CSRSReadValM = SATP_REGW;
                 else begin
                   CSRSReadValM = 0;
                   IllegalCSRSAccessM = 1;
                 end
      SCOUNTEREN:CSRSReadValM = {{(P.XLEN-32){1'b0}}, SCOUNTEREN_REGW};
      STIMECMP:  if (P.SSTC_SUPPORTED & (PrivilegeModeW == P.M_MODE | MCOUNTEREN_TM)) CSRSReadValM = STIMECMP_REGW[P.XLEN-1:0]; 
                 else begin 
                   CSRSReadValM = 0;
                   IllegalCSRSAccessM = 1;
                 end
      STIMECMPH: if (P.SSTC_SUPPORTED & (P.XLEN == 32) & (PrivilegeModeW == P.M_MODE | MCOUNTEREN_TM)) CSRSReadValM[31:0] = STIMECMP_REGW[63:32];
                 else begin // not supported for RV64
                   CSRSReadValM = 0;
                   IllegalCSRSAccessM = 1;
                 end
      default: begin
                  CSRSReadValM = 0; 
                  IllegalCSRSAccessM = 1;  
               end       
    endcase
  end
endmodule

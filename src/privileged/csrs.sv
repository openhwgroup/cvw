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

module csrs #(parameter 
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
  SATP = 12'h180) (
  input logic 	     clk, reset, 
  input logic 	     InstrValidNotFlushedM, 
  input logic 	     CSRSWriteM, STrapM,
  input logic [11:0] 	     CSRAdrM,
  input logic [`XLEN-1:0]  NextEPCM, NextCauseM, NextMtvalM, SSTATUS_REGW, 
  input logic 	     STATUS_TVM,
  input logic [`XLEN-1:0]  CSRWriteValM,
  input logic [1:0] 	     PrivilegeModeW,
  output logic [`XLEN-1:0] CSRSReadValM, STVEC_REGW,
  output logic [`XLEN-1:0] SEPC_REGW,      
  output logic [31:0]      SCOUNTEREN_REGW, 
  output logic [`XLEN-1:0] SATP_REGW,
  input logic [11:0] MIP_REGW, MIE_REGW, MIDELEG_REGW,
  output logic 	     WriteSSTATUSM,
  output logic 	     IllegalCSRSAccessM
);

  // Constants
  localparam ZERO = {(`XLEN){1'b0}};
  localparam SEDELEG_MASK = ~(ZERO | `XLEN'b111 << 9);

  logic               WriteSTVECM;
  logic               WriteSSCRATCHM, WriteSEPCM;
  logic               WriteSCAUSEM, WriteSTVALM, WriteSATPM, WriteSCOUNTERENM;
  logic [`XLEN-1:0] SSCRATCH_REGW, STVAL_REGW;
  logic [`XLEN-1:0] SCAUSE_REGW;      
  
  // write enables
  assign WriteSSTATUSM = CSRSWriteM & (CSRAdrM == SSTATUS)  & InstrValidNotFlushedM;
  assign WriteSTVECM = CSRSWriteM & (CSRAdrM == STVEC) & InstrValidNotFlushedM;
  assign WriteSSCRATCHM = CSRSWriteM & (CSRAdrM == SSCRATCH) & InstrValidNotFlushedM;
  assign WriteSEPCM = STrapM | (CSRSWriteM & (CSRAdrM == SEPC)) & InstrValidNotFlushedM;
  assign WriteSCAUSEM = STrapM | (CSRSWriteM & (CSRAdrM == SCAUSE)) & InstrValidNotFlushedM;
  assign WriteSTVALM = STrapM | (CSRSWriteM & (CSRAdrM == STVAL)) & InstrValidNotFlushedM;
  assign WriteSATPM = CSRSWriteM & (CSRAdrM == SATP) & (PrivilegeModeW == `M_MODE | ~STATUS_TVM) & InstrValidNotFlushedM;
  assign WriteSCOUNTERENM = CSRSWriteM & (CSRAdrM == SCOUNTEREN) & InstrValidNotFlushedM;

  // CSRs
  flopenr #(`XLEN) STVECreg(clk, reset, WriteSTVECM, {CSRWriteValM[`XLEN-1:2], 1'b0, CSRWriteValM[0]}, STVEC_REGW); 
  flopenr #(`XLEN) SSCRATCHreg(clk, reset, WriteSSCRATCHM, CSRWriteValM, SSCRATCH_REGW);
  flopenr #(`XLEN) SEPCreg(clk, reset, WriteSEPCM, NextEPCM, SEPC_REGW); 
  flopenr #(`XLEN) SCAUSEreg(clk, reset, WriteSCAUSEM, NextCauseM, SCAUSE_REGW);
  flopenr #(`XLEN) STVALreg(clk, reset, WriteSTVALM, NextMtvalM, STVAL_REGW);
  if (`VIRTMEM_SUPPORTED)
    flopenr #(`XLEN) SATPreg(clk, reset, WriteSATPM, CSRWriteValM, SATP_REGW);
  else
    assign SATP_REGW = 0; // hardwire to zero if virtual memory not supported
  flopens #(32)   SCOUNTERENreg(clk, reset, WriteSCOUNTERENM, CSRWriteValM[31:0], SCOUNTEREN_REGW);

  // CSR Reads
  always_comb begin:csrr
    IllegalCSRSAccessM = 0;
    case (CSRAdrM) 
      SSTATUS:   CSRSReadValM = SSTATUS_REGW;
      STVEC:     CSRSReadValM = STVEC_REGW;
      SIP:       CSRSReadValM = {{(`XLEN-12){1'b0}}, MIP_REGW & 12'h222 & MIDELEG_REGW}; // only read supervisor fields  
      SIE:       CSRSReadValM = {{(`XLEN-12){1'b0}}, MIE_REGW & 12'h222}; // only read supervisor fields
      SSCRATCH:  CSRSReadValM = SSCRATCH_REGW;
      SEPC:      CSRSReadValM = SEPC_REGW;
      SCAUSE:    CSRSReadValM = SCAUSE_REGW;
      STVAL:     CSRSReadValM = STVAL_REGW;
      SATP:      if (`VIRTMEM_SUPPORTED & (PrivilegeModeW == `M_MODE | ~STATUS_TVM)) CSRSReadValM = SATP_REGW;
                  else begin
                    CSRSReadValM = 0;
                    if (PrivilegeModeW == `S_MODE & STATUS_TVM) IllegalCSRSAccessM = 1;
                  end
      SCOUNTEREN:CSRSReadValM = {{(`XLEN-32){1'b0}}, SCOUNTEREN_REGW};
      default: begin
                  CSRSReadValM = 0; 
                  IllegalCSRSAccessM = 1;  
      end       
    endcase
  end
endmodule

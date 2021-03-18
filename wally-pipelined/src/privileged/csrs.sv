///////////////////////////////////////////
// csrs.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Supervisor-Mode Control and Status Registers
//          See RISC-V Privileged Mode Specification 20190608 
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

module csrs #(parameter 
  // Supervisor CSRs
  SSTATUS = 12'h100,
  SEDELEG = 12'h102,
  SIDELEG = 12'h103,
  SIE = 12'h104,
  STVEC = 12'h105,
  SCOUNTEREN = 12'h106,
  SSCRATCH = 12'h140,
  SEPC = 12'h141,
  SCAUSE = 12'h142,
  STVAL = 12'h143,
  SIP= 12'h144,
  SATP = 12'h180) (
    input  logic             clk, reset, 
    input  logic             CSRSWriteM, STrapM,
    input  logic [11:0]      CSRAdrM,
    input  logic [`XLEN-1:0] NextEPCM, NextCauseM, NextMtvalM, SSTATUS_REGW, 
    input  logic [`XLEN-1:0] CSRWriteValM,
    output logic [`XLEN-1:0] CSRSReadValM, SEPC_REGW, STVEC_REGW, 
    output logic [31:0]      SCOUNTEREN_REGW,     
    output logic [`XLEN-1:0] SEDELEG_REGW, SIDELEG_REGW, 
    output logic [`XLEN-1:0] SATP_REGW,
    input  logic [11:0]      SIP_REGW, SIE_REGW,
    output logic             WriteSSTATUSM,
    output logic             IllegalCSRSAccessM
  );

  logic [`XLEN-1:0] zero = 0;
  logic [31:0] allones = {32{1'b1}};
  logic [`XLEN-1:0] SEDELEG_MASK = ~(zero | 3'b111 << 9); // sedeleg[11:9] hardwired to zero per Privileged Spec 3.1.8

  // Supervisor mode CSRs sometimes supported
  generate  
    if (`S_SUPPORTED) begin
      logic WriteSTVECM;
      logic WriteSSCRATCHM, WriteSEPCM;
      logic WriteSCAUSEM, WriteSTVALM, WriteSATPM, WriteSCOUNTERENM;
      logic [`XLEN-1:0] SSCRATCH_REGW, SCAUSE_REGW, STVAL_REGW;
      
      assign WriteSSTATUSM = CSRSWriteM && (CSRAdrM == SSTATUS);
      assign WriteSTVECM = CSRSWriteM && (CSRAdrM == STVEC);
      assign WriteSSCRATCHM = CSRSWriteM && (CSRAdrM == SSCRATCH);
      assign WriteSEPCM = STrapM | (CSRSWriteM && (CSRAdrM == SEPC));
      assign WriteSCAUSEM = STrapM | (CSRSWriteM && (CSRAdrM == SCAUSE));
      assign WriteSTVALM = STrapM | (CSRSWriteM && (CSRAdrM == STVAL));
      assign WriteSATPM = STrapM | (CSRSWriteM && (CSRAdrM == SATP));
      assign WriteSCOUNTERENM = CSRSWriteM && (CSRAdrM == SCOUNTEREN);

      // CSRs
      flopenl #(`XLEN) STVECreg(clk, reset, WriteSTVECM, CSRWriteValM, zero, STVEC_REGW); //busybear: change reset to 0
      flopenr #(`XLEN) SSCRATCHreg(clk, reset, WriteSSCRATCHM, CSRWriteValM, SSCRATCH_REGW);
      flopenr #(`XLEN) SEPCreg(clk, reset, WriteSEPCM, NextEPCM, SEPC_REGW); 
      flopenl #(`XLEN) SCAUSEreg(clk, reset, WriteSCAUSEM, NextCauseM, zero, SCAUSE_REGW); 
      flopenr #(`XLEN) STVALreg(clk, reset, WriteSTVALM, NextMtvalM, STVAL_REGW);
      flopenr #(`XLEN) SATPreg(clk, reset, WriteSATPM, CSRWriteValM, SATP_REGW);
      if (`OVPSIM_CSR_CONFIG)
        flopenl #(32)   SCOUNTERENreg(clk, reset, WriteSCOUNTERENM, {CSRWriteValM[31:2],1'b0,CSRWriteValM[0]}, 32'b0, SCOUNTEREN_REGW);
      else
        flopenl #(32)   SCOUNTERENreg(clk, reset, WriteSCOUNTERENM, CSRWriteValM[31:0], allones, SCOUNTEREN_REGW);
      if (`N_SUPPORTED) begin
        logic WriteSEDELEGM, WriteSIDELEGM;
        assign WriteSEDELEGM = CSRSWriteM && (CSRAdrM == SEDELEG);
        assign WriteSIDELEGM = CSRSWriteM && (CSRAdrM == SIDELEG);
        flopenl #(`XLEN) SEDELEGreg(clk, reset, WriteSEDELEGM, CSRWriteValM & SEDELEG_MASK, zero, SEDELEG_REGW);
        flopenl #(`XLEN) SIDELEGreg(clk, reset, WriteSIDELEGM, CSRWriteValM, zero, SIDELEG_REGW);
      end else begin
        assign SEDELEG_REGW = 0;
        assign SIDELEG_REGW = 0;
      end

      // CSR Reads
      always_comb begin
        IllegalCSRSAccessM = !(`N_SUPPORTED)  && (CSRAdrM == SEDELEG || CSRAdrM == SIDELEG); // trap on DELEG register access when no N-mode
        case (CSRAdrM) 
          SSTATUS:   CSRSReadValM = SSTATUS_REGW;
          STVEC:     CSRSReadValM = STVEC_REGW;
          SEDELEG:   CSRSReadValM = SEDELEG_REGW;
          SIDELEG:   CSRSReadValM = SIDELEG_REGW;
          SIP:       CSRSReadValM = {{(`XLEN-12){1'b0}}, SIP_REGW};
          SIE:       CSRSReadValM = {{(`XLEN-12){1'b0}}, SIE_REGW};
          SSCRATCH:  CSRSReadValM = SSCRATCH_REGW;
          SEPC:      CSRSReadValM = SEPC_REGW;
          SCAUSE:    CSRSReadValM = SCAUSE_REGW;
          STVAL:     CSRSReadValM = STVAL_REGW;
          SATP:      CSRSReadValM = SATP_REGW;
          SCOUNTEREN:CSRSReadValM = {{(`XLEN-32){1'b0}}, SCOUNTEREN_REGW};
          default: begin
                     CSRSReadValM = 0; 
                     IllegalCSRSAccessM = 1;  
          end       
        endcase
      end
    end else begin
      assign WriteSSTATUSM = 0;
      assign CSRSReadValM = 0;
      assign SEPC_REGW = 0;
      assign STVEC_REGW = 0;
      assign SEDELEG_REGW = 0;
      assign SIDELEG_REGW = 0;
      assign SCOUNTEREN_REGW = 0;
      assign SATP_REGW = 0;
      assign IllegalCSRSAccessM = 1;
    end
  endgenerate
endmodule

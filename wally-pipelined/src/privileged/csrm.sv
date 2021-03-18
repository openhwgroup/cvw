///////////////////////////////////////////
// csrm.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Machine-Mode Control and Status Registers
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

module csrm #(parameter 
  // Machine CSRs
  MVENDORID = 12'hF11,
  MARCHID = 12'hF12,
  MIMPID = 12'hF13,
  MHARTID = 12'hF14,
  MSTATUS = 12'h300,
  MISA_ADR = 12'h301,
  MEDELEG = 12'h302,
  MIDELEG = 12'h303,
  MIE = 12'h304,
  MTVEC = 12'h305,
  MCOUNTEREN = 12'h306,
  MSTATUSH = 12'h310,
  MCOUNTINHIBIT = 12'h320,
  MSCRATCH = 12'h340,
  MEPC = 12'h341,
  MCAUSE = 12'h342,
  MTVAL = 12'h343,
  MIP = 12'h344,
  PMPCFG0 = 12'h3A0,
  PMPCFG1 = 12'h3A1,
  PMPCFG2 = 12'h3A2,
  PMPCFG3 = 12'h3A3,
  PMPADDR0 = 12'h3B0,
  //... more physical memory protection
  PMPADDR15 = 12'h3BF,
  TSELECT = 12'h7A0,
  TDATA1 = 12'h7A1,
  TDATA2 = 12'h7A2,
  TDATA3 = 12'h7A3,
  DCSR = 12'h7B0,
  DPC = 12'h7B1,
  DSCRATCH0 = 12'h7B2,
  DSCRATCH1 = 12'h7B3) (
    input  logic             clk, reset, 
    input  logic             CSRMWriteM, MTrapM,
    input  logic [11:0]      CSRAdrM,
    input  logic [`XLEN-1:0] NextEPCM, NextCauseM, NextMtvalM, MSTATUS_REGW, 
    input  logic [`XLEN-1:0] CSRWriteValM,
    output logic [`XLEN-1:0] CSRMReadValM, MEPC_REGW, MTVEC_REGW, 
    output logic [31:0]      MCOUNTEREN_REGW, MCOUNTINHIBIT_REGW, 
    output logic [`XLEN-1:0] MEDELEG_REGW, MIDELEG_REGW, 
    input  logic [11:0]      MIP_REGW, MIE_REGW,
    output logic             WriteMSTATUSM,
    output logic             IllegalCSRMAccessM
  );

  logic [`XLEN-1:0] MISA_REGW;
  logic [`XLEN-1:0] MSCRATCH_REGW,MCAUSE_REGW, MTVAL_REGW;
  logic [63:0] PMPCFG01_REGW, PMPCFG23_REGW; // 64-bit registers in RV64, or two 32-bit registers in RV32
  logic [`XLEN-1:0] PMPADDR0_REGW; // will need to add more
  logic [`XLEN-1:0] zero = 0;
  logic [31:0]     allones = {32{1'b1}};
  logic [`XLEN-1:0] MEDELEG_MASK = ~(zero | 1'b1 << 11); // medeleg[11] hardwired to zero per Privileged Spec 3.1.8
  logic [`XLEN-1:0] MIDELEG_MASK = {{(`XLEN-12){1'b0}}, 12'h222}; // only allow delegating interrupts to supervisor mode
  logic            WriteMTVECM, WriteMEDELEGM, WriteMIDELEGM;
  logic            WriteMSCRATCHM, WriteMEPCM, WriteMCAUSEM, WriteMTVALM;
  logic            WriteMCOUNTERENM, WriteMCOUNTINHIBITM;
  logic            WritePMPCFG0M, WritePMPCFG2M;
  logic            WritePMPADDR0M; 
  logic [25:0]     MISAbits = `MISA;

  // MISA is hardwired.  Spec says it could be written to disable features, but this is not supported by Wally
  assign MISA_REGW = {(`XLEN == 32 ? 2'b01 : 2'b10), {(`XLEN-28){1'b0}}, MISAbits};

  // Write machine Mode CSRs 
  assign WriteMSTATUSM = CSRMWriteM && (CSRAdrM == MSTATUS);
  assign WriteMTVECM = CSRMWriteM && (CSRAdrM == MTVEC);
  assign WriteMEDELEGM = CSRMWriteM && (CSRAdrM == MEDELEG);
  assign WriteMIDELEGM = CSRMWriteM && (CSRAdrM == MIDELEG);
  assign WriteMSCRATCHM = CSRMWriteM && (CSRAdrM == MSCRATCH);
  assign WriteMEPCM = MTrapM | (CSRMWriteM && (CSRAdrM == MEPC));
  assign WriteMCAUSEM = MTrapM | (CSRMWriteM && (CSRAdrM == MCAUSE));
  assign WriteMTVALM = MTrapM | (CSRMWriteM && (CSRAdrM == MTVAL));
  assign WritePMPCFG0M = (CSRMWriteM && (CSRAdrM == PMPCFG0));
  assign WritePMPCFG2M = (CSRMWriteM && (CSRAdrM == PMPCFG2));
  assign WritePMPADDR0M = (CSRMWriteM && (CSRAdrM == PMPADDR0));
  assign WriteMCOUNTERENM = CSRMWriteM && (CSRAdrM == MCOUNTEREN);
  assign WriteMCOUNTINHIBITM = CSRMWriteM && (CSRAdrM == MCOUNTINHIBIT);

  // CSRs
  flopenl #(`XLEN) MTVECreg(clk, reset, WriteMTVECM, CSRWriteValM, `XLEN'b0, MTVEC_REGW); //busybear: changed reset value to 0
  generate
    if (`S_SUPPORTED | (`U_SUPPORTED & `N_SUPPORTED)) begin // DELEG registers should exist
      flopenl #(`XLEN) MEDELEGreg(clk, reset, WriteMEDELEGM, CSRWriteValM & MEDELEG_MASK, zero, MEDELEG_REGW);
      flopenl #(`XLEN) MIDELEGreg(clk, reset, WriteMIDELEGM, CSRWriteValM & MIDELEG_MASK, zero, MIDELEG_REGW);
    end else begin
      assign MEDELEG_REGW = 0;
      assign MIDELEG_REGW = 0;
    end
  endgenerate

//  flopenl #(`XLEN) MIPreg(clk, reset, WriteMIPM, CSRWriteValM, zero, MIP_REGW);
//  flopenl #(`XLEN) MIEreg(clk, reset, WriteMIEM, CSRWriteValM, zero, MIE_REGW);
  flopenr #(`XLEN) MSCRATCHreg(clk, reset, WriteMSCRATCHM, CSRWriteValM, MSCRATCH_REGW);
  flopenr #(`XLEN) MEPCreg(clk, reset, WriteMEPCM, NextEPCM, MEPC_REGW); 
  flopenr #(`XLEN) MCAUSEreg(clk, reset, WriteMCAUSEM, NextCauseM, MCAUSE_REGW); 
  flopenr #(`XLEN) MTVALreg(clk, reset, WriteMTVALM, NextMtvalM, MTVAL_REGW);
  generate
    if (`OVPSIM_CSR_CONFIG)
      flopenl #(32)   MCOUNTERENreg(clk, reset, WriteMCOUNTERENM, {CSRWriteValM[31:2],1'b0,CSRWriteValM[0]}, 32'b0, MCOUNTEREN_REGW);
    else
      flopenl #(32)   MCOUNTERENreg(clk, reset, WriteMCOUNTERENM, CSRWriteValM[31:0], allones, MCOUNTEREN_REGW);
  endgenerate
  flopenl #(32)   MCOUNTINHIBITreg(clk, reset, WriteMCOUNTINHIBITM, CSRWriteValM[31:0], allones, MCOUNTINHIBIT_REGW);
  flopenr #(`XLEN) PMPADDR0reg(clk, reset, WritePMPADDR0M, CSRWriteValM, PMPADDR0_REGW);  
  // PMPCFG registers are a pair of 64-bit in RV64 and four 32-bit in RV32
  generate
    if (`XLEN==64) begin
      flopenr #(`XLEN) PMPCFG01reg(clk, reset, WritePMPCFG0M, CSRWriteValM, PMPCFG01_REGW);
      flopenr #(`XLEN) PMPCFG23reg(clk, reset, WritePMPCFG2M, CSRWriteValM, PMPCFG23_REGW);      
    end else begin
      logic WritePMPCFG1M, WritePMPCFG3M;
      assign WritePMPCFG1M = MTrapM | (CSRMWriteM && (CSRAdrM == PMPCFG1));
      assign WritePMPCFG3M = MTrapM | (CSRMWriteM && (CSRAdrM == PMPCFG3));
      flopenr #(`XLEN) PMPCFG0reg(clk, reset, WritePMPCFG0M, CSRWriteValM, PMPCFG01_REGW[31:0]);
      flopenr #(`XLEN) PMPCFG1reg(clk, reset, WritePMPCFG1M, CSRWriteValM, PMPCFG01_REGW[63:32]);            
      flopenr #(`XLEN) PMPCFG2reg(clk, reset, WritePMPCFG2M, CSRWriteValM, PMPCFG23_REGW[31:0]);
      flopenr #(`XLEN) PMPCFG3reg(clk, reset, WritePMPCFG3M, CSRWriteValM, PMPCFG23_REGW[63:32]);            
    end
  endgenerate
  // Read machine mode CSRs
  always_comb begin
    IllegalCSRMAccessM = !(`S_SUPPORTED | `U_SUPPORTED & `N_SUPPORTED) && 
                          (CSRAdrM == MEDELEG || CSRAdrM == MIDELEG); // trap on DELEG register access when no S or N-mode
    case (CSRAdrM) 
      MISA_ADR:  CSRMReadValM = MISA_REGW;
      MVENDORID: CSRMReadValM = 0;
      MARCHID:   CSRMReadValM = 0;
      MIMPID:    CSRMReadValM = 'h100; // pipelined implementation
      MHARTID:   CSRMReadValM = 0; 
      MSTATUS:   CSRMReadValM = MSTATUS_REGW;
      MSTATUSH:  CSRMReadValM = 0; // flush this out later if MBE and SBE fields are supported
      MTVEC:     CSRMReadValM = MTVEC_REGW;
      MEDELEG:   CSRMReadValM = MEDELEG_REGW;
      MIDELEG:   CSRMReadValM = MIDELEG_REGW;
      MIP:       CSRMReadValM = {{(`XLEN-12){1'b0}}, MIP_REGW};
      MIE:       CSRMReadValM = {{(`XLEN-12){1'b0}}, MIE_REGW};
      MSCRATCH:  CSRMReadValM = MSCRATCH_REGW;
      MEPC:      CSRMReadValM = MEPC_REGW;
      MCAUSE:    CSRMReadValM = MCAUSE_REGW;
      MTVAL:     CSRMReadValM = MTVAL_REGW;
      MCOUNTEREN:CSRMReadValM = {{(`XLEN-32){1'b0}}, MCOUNTEREN_REGW};
      MCOUNTINHIBIT:CSRMReadValM = {{(`XLEN-32){1'b0}}, MCOUNTINHIBIT_REGW};
      PMPCFG0:   CSRMReadValM = PMPCFG01_REGW[`XLEN-1:0];
      PMPCFG1:   CSRMReadValM = {{(`XLEN-32){1'b0}}, PMPCFG01_REGW[63:31]};
      PMPCFG2:   CSRMReadValM = PMPCFG23_REGW[`XLEN-1:0];
      PMPCFG3:   CSRMReadValM = {{(`XLEN-32){1'b0}}, PMPCFG23_REGW[63:31]};
      PMPADDR0:  CSRMReadValM = PMPADDR0_REGW;
      default: begin
                 CSRMReadValM = 0;
                 IllegalCSRMAccessM = 1;
      end
    endcase
  end
endmodule

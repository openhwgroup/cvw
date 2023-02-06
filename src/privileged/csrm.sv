///////////////////////////////////////////
// csrm.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//          dottolia@hmc.edu 7 April 2021
//
// Purpose: Machine-Mode Control and Status Registers
//          See RISC-V Privileged Mode Specification 20190608 
// Note: the CSRs do not support the following optional features
//   - Disabling portions of the instruction set with bits of the MISA register
//   - Changing from RV64 to RV32 by writing the SXL/UXL bits of the STATUS register
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

module csrm #(parameter 
  // Machine CSRs
  MVENDORID = 12'hF11,
  MARCHID = 12'hF12,
  MIMPID = 12'hF13,
  MHARTID = 12'hF14,
  MCONFIGPTR = 12'hF15,
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
  MTINST = 12'h34A,
  PMPCFG0 = 12'h3A0,
  // .. up to 15 more at consecutive addresses
  PMPADDR0 = 12'h3B0,
  // ... up to 63 more at consecutive addresses
  TSELECT = 12'h7A0,
  TDATA1 = 12'h7A1,
  TDATA2 = 12'h7A2,
  TDATA3 = 12'h7A3,
  DCSR = 12'h7B0,
  DPC = 12'h7B1,
  DSCRATCH0 = 12'h7B2,
  DSCRATCH1 = 12'h7B3,
  // Constants
  ZERO = {(`XLEN){1'b0}},
  MEDELEG_MASK = ~(ZERO | `XLEN'b1 << 11),
  MIDELEG_MASK = 12'h222 // we choose to not make machine interrupts delegable
) (
  input  logic 	            clk, reset, 
  input  logic 	            InstrValidNotFlushedM, 
  input  logic 	            CSRMWriteM, MTrapM,
  input  logic [11:0] 	    CSRAdrM,
  input  logic [`XLEN-1:0]  NextEPCM, NextCauseM, NextMtvalM, MSTATUS_REGW, MSTATUSH_REGW,
  input  logic [`XLEN-1:0]  CSRWriteValM,
  input  logic [11:0] 	     MIP_REGW, MIE_REGW,
  output logic [`XLEN-1:0]  CSRMReadValM, MTVEC_REGW,
  output logic [`XLEN-1:0] MEPC_REGW,    
  output logic [31:0]       MCOUNTEREN_REGW, MCOUNTINHIBIT_REGW, 
  output logic [`XLEN-1:0] MEDELEG_REGW,
  output logic [11:0]      MIDELEG_REGW,
  output var logic [7:0]    PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  output var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0],
  output logic 	            WriteMSTATUSM, WriteMSTATUSHM,
  output logic 	            IllegalCSRMAccessM, IllegalCSRMWriteReadonlyM
);

  logic [`XLEN-1:0]         MISA_REGW, MHARTID_REGW;
  logic [`XLEN-1:0] MSCRATCH_REGW;
  logic [`XLEN-1:0] MCAUSE_REGW, MTVAL_REGW;
  logic                     WriteMTVECM, WriteMEDELEGM, WriteMIDELEGM;
  logic                     WriteMSCRATCHM, WriteMEPCM, WriteMCAUSEM, WriteMTVALM;
  logic                     WriteMCOUNTERENM, WriteMCOUNTINHIBITM;

 // There are PMP_ENTRIES = 0, 16, or 64 PMPADDR registers, each of which has its own flop
  genvar i;
  if (`PMP_ENTRIES > 0) begin:pmp
    logic [`PMP_ENTRIES-1:0] WritePMPCFGM;
    logic [`PMP_ENTRIES-1:0] WritePMPADDRM ; 
    logic [`PMP_ENTRIES-1:0] ADDRLocked, CFGLocked;
    for(i=0; i<`PMP_ENTRIES; i++) begin
      // when the lock bit is set, don't allow writes to the PMPCFG or PMPADDR
      // also, when the lock bit of the next entry is set and the next entry is TOR, don't allow writes to this entry PMPADDR
      assign CFGLocked[i] = PMPCFG_ARRAY_REGW[i][7];
      if (i == `PMP_ENTRIES-1) 
        assign ADDRLocked[i] = PMPCFG_ARRAY_REGW[i][7];
      else
        assign ADDRLocked[i] = PMPCFG_ARRAY_REGW[i][7] | (PMPCFG_ARRAY_REGW[i+1][7] & PMPCFG_ARRAY_REGW[i+1][4:3] == 2'b01);
      
      assign WritePMPADDRM[i] = (CSRMWriteM & (CSRAdrM == (PMPADDR0+i))) & InstrValidNotFlushedM & ~ADDRLocked[i];
      flopenr #(`XLEN) PMPADDRreg(clk, reset, WritePMPADDRM[i], CSRWriteValM, PMPADDR_ARRAY_REGW[i]);
      if (`XLEN==64) begin
        assign WritePMPCFGM[i] = (CSRMWriteM & (CSRAdrM == (PMPCFG0+2*(i/8)))) & InstrValidNotFlushedM & ~CFGLocked[i];
        flopenr #(8) PMPCFGreg(clk, reset, WritePMPCFGM[i], CSRWriteValM[(i%8)*8+7:(i%8)*8], PMPCFG_ARRAY_REGW[i]);
      end else begin
        assign WritePMPCFGM[i]  = (CSRMWriteM & (CSRAdrM == (PMPCFG0+i/4))) & InstrValidNotFlushedM & ~CFGLocked[i];
        flopenr #(8) PMPCFGreg(clk, reset, WritePMPCFGM[i], CSRWriteValM[(i%4)*8+7:(i%4)*8], PMPCFG_ARRAY_REGW[i]);
      end
    end
  end

  localparam MISA_26 = (`MISA) & 32'h03ffffff;

  // MISA is hardwired.  Spec says it could be written to disable features, but this is not supported by Wally
  assign MISA_REGW = {(`XLEN == 32 ? 2'b01 : 2'b10), {(`XLEN-28){1'b0}}, MISA_26[25:0]};

  // MHARTID is hardwired. It only exists as a signal so that the testbench can easily see it.
  assign MHARTID_REGW = 0;

  // Write machine Mode CSRs 
  assign WriteMSTATUSM = CSRMWriteM & (CSRAdrM == MSTATUS) & InstrValidNotFlushedM;
  assign WriteMSTATUSHM = CSRMWriteM & (CSRAdrM == MSTATUSH) & InstrValidNotFlushedM & (`XLEN==32);
  assign WriteMTVECM = CSRMWriteM & (CSRAdrM == MTVEC) & InstrValidNotFlushedM;
  assign WriteMEDELEGM = CSRMWriteM & (CSRAdrM == MEDELEG) & InstrValidNotFlushedM;
  assign WriteMIDELEGM = CSRMWriteM & (CSRAdrM == MIDELEG) & InstrValidNotFlushedM;
  assign WriteMSCRATCHM = CSRMWriteM & (CSRAdrM == MSCRATCH) & InstrValidNotFlushedM;
  assign WriteMEPCM = MTrapM | (CSRMWriteM & (CSRAdrM == MEPC)) & InstrValidNotFlushedM;
  assign WriteMCAUSEM = MTrapM | (CSRMWriteM & (CSRAdrM == MCAUSE)) & InstrValidNotFlushedM;
  assign WriteMTVALM = MTrapM | (CSRMWriteM & (CSRAdrM == MTVAL)) & InstrValidNotFlushedM;
  assign WriteMCOUNTERENM = CSRMWriteM & (CSRAdrM == MCOUNTEREN) & InstrValidNotFlushedM;
  assign WriteMCOUNTINHIBITM = CSRMWriteM & (CSRAdrM == MCOUNTINHIBIT) & InstrValidNotFlushedM;

  assign IllegalCSRMWriteReadonlyM = CSRMWriteM & (CSRAdrM == MVENDORID | CSRAdrM == MARCHID | CSRAdrM == MIMPID | CSRAdrM == MHARTID);

  // CSRs
  flopenr #(`XLEN) MTVECreg(clk, reset, WriteMTVECM, {CSRWriteValM[`XLEN-1:2], 1'b0, CSRWriteValM[0]}, MTVEC_REGW); 
  if (`S_SUPPORTED) begin:deleg // DELEG registers should exist
    flopenr #(`XLEN) MEDELEGreg(clk, reset, WriteMEDELEGM, CSRWriteValM & MEDELEG_MASK, MEDELEG_REGW);
    flopenr #(12)    MIDELEGreg(clk, reset, WriteMIDELEGM, CSRWriteValM[11:0] & MIDELEG_MASK, MIDELEG_REGW);
  end else assign {MEDELEG_REGW, MIDELEG_REGW} = 0;

  flopenr #(`XLEN) MSCRATCHreg(clk, reset, WriteMSCRATCHM, CSRWriteValM, MSCRATCH_REGW);
  flopenr #(`XLEN) MEPCreg(clk, reset, WriteMEPCM, NextEPCM, MEPC_REGW); 
  flopenr #(`XLEN) MCAUSEreg(clk, reset, WriteMCAUSEM, NextCauseM, MCAUSE_REGW);
  if(`QEMU) assign MTVAL_REGW = `XLEN'b0; // MTVAL tied to 0 in QEMU configuration
  else flopenr #(`XLEN) MTVALreg(clk, reset, WriteMTVALM, NextMtvalM, MTVAL_REGW);
  flopenr #(32)   MCOUNTINHIBITreg(clk, reset, WriteMCOUNTINHIBITM, CSRWriteValM[31:0], MCOUNTINHIBIT_REGW);
  if (`U_SUPPORTED) begin: mcounteren // MCOUNTEREN only exists when user mode is supported
    flopenr #(32)   MCOUNTERENreg(clk, reset, WriteMCOUNTERENM, CSRWriteValM[31:0], MCOUNTEREN_REGW);
  end else assign MCOUNTEREN_REGW = '0;

  // Read machine mode CSRs
  // verilator lint_off WIDTH
  logic [5:0] entry;
  always_comb begin
    entry = '0;
    IllegalCSRMAccessM = !(`S_SUPPORTED) & (CSRAdrM == MEDELEG | CSRAdrM == MIDELEG); // trap on DELEG register access when no S or N-mode
    if (CSRAdrM >= PMPADDR0 & CSRAdrM < PMPADDR0 + `PMP_ENTRIES) // reading a PMP entry
      CSRMReadValM = PMPADDR_ARRAY_REGW[CSRAdrM - PMPADDR0];
    else if (CSRAdrM >= PMPCFG0 & CSRAdrM < PMPCFG0 + `PMP_ENTRIES/4) begin
      if (`XLEN==64) begin
        entry = ({CSRAdrM[11:1], 1'b0} - PMPCFG0)*4; // disregard odd entries in RV64
        CSRMReadValM = {PMPCFG_ARRAY_REGW[entry+7],PMPCFG_ARRAY_REGW[entry+6],PMPCFG_ARRAY_REGW[entry+5],PMPCFG_ARRAY_REGW[entry+4],
                        PMPCFG_ARRAY_REGW[entry+3],PMPCFG_ARRAY_REGW[entry+2],PMPCFG_ARRAY_REGW[entry+1],PMPCFG_ARRAY_REGW[entry]};
      end else begin
        entry = (CSRAdrM - PMPCFG0)*4;
        CSRMReadValM = {PMPCFG_ARRAY_REGW[entry+3],PMPCFG_ARRAY_REGW[entry+2],PMPCFG_ARRAY_REGW[entry+1],PMPCFG_ARRAY_REGW[entry]};
      end
    end
    else case (CSRAdrM) 
      MISA_ADR:  CSRMReadValM = MISA_REGW;
      MVENDORID: CSRMReadValM = 0;
      MARCHID:   CSRMReadValM = 0;
      MIMPID:    CSRMReadValM = `XLEN'h100; // pipelined implementation
      MHARTID:   CSRMReadValM = MHARTID_REGW; // hardwired to 0 
      MCONFIGPTR: CSRMReadValM = 0; // hardwired to 0
      MSTATUS:   CSRMReadValM = MSTATUS_REGW;
      MSTATUSH:  CSRMReadValM = MSTATUSH_REGW; 
      MTVEC:     CSRMReadValM = MTVEC_REGW;
      MEDELEG:   CSRMReadValM = MEDELEG_REGW;
      MIDELEG:   CSRMReadValM = {{(`XLEN-12){1'b0}}, MIDELEG_REGW};
      MIP:       CSRMReadValM = {{(`XLEN-12){1'b0}}, MIP_REGW};
      MIE:       CSRMReadValM = {{(`XLEN-12){1'b0}}, MIE_REGW};
      MSCRATCH:  CSRMReadValM = MSCRATCH_REGW;
      MEPC:      CSRMReadValM = MEPC_REGW;
      MCAUSE:    CSRMReadValM = MCAUSE_REGW;
      MTVAL:     CSRMReadValM = MTVAL_REGW;
      MTINST:    CSRMReadValM = 0; // implemented as trivial zero
      MCOUNTEREN:CSRMReadValM = {{(`XLEN-32){1'b0}}, MCOUNTEREN_REGW};
      MCOUNTINHIBIT:CSRMReadValM = {{(`XLEN-32){1'b0}}, MCOUNTINHIBIT_REGW};

      default: begin
                 CSRMReadValM = 0;
                 IllegalCSRMAccessM = 1;
      end
    endcase
  end
  // verilator lint_on WIDTH
endmodule

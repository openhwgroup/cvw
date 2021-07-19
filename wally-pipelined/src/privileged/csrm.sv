///////////////////////////////////////////
// csrm.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//          dottolia@hmc.edu 7 April 2021
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
   MIDELEG_MASK = {{(`XLEN-12){1'b0}}, 12'h222}
) (
    input  logic             clk, reset, 
    input  logic             StallW,
    input  logic             CSRMWriteM, MTrapM,
    input  logic [11:0]      CSRAdrM,
    input  logic [`XLEN-1:0] NextEPCM, NextCauseM, NextMtvalM, MSTATUS_REGW, 
    input  logic [`XLEN-1:0] CSRWriteValM,
    output logic [`XLEN-1:0] CSRMReadValM, MEPC_REGW, MTVEC_REGW, 
    output logic [31:0]      MCOUNTEREN_REGW, MCOUNTINHIBIT_REGW, 
    output logic [`XLEN-1:0]      MEDELEG_REGW, MIDELEG_REGW,
    // 64-bit registers in RV64, or two 32-bit registers in RV32
    //output var logic [63:0]      PMPCFG_ARRAY_REGW[`PMP_ENTRIES/8-1:0],
    output var logic [7:0]   PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
    output var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0],
    input  logic [11:0]      MIP_REGW, MIE_REGW,
    output logic             WriteMSTATUSM,
    output logic             IllegalCSRMAccessM, IllegalCSRMWriteReadonlyM
  );

  logic [`XLEN-1:0] MISA_REGW, MHARTID_REGW;
  logic [`XLEN-1:0] MSCRATCH_REGW, MCAUSE_REGW, MTVAL_REGW;

  logic            WriteMTVECM, WriteMEDELEGM, WriteMIDELEGM;
  logic            WriteMSCRATCHM, WriteMEPCM, WriteMCAUSEM, WriteMTVALM;
  logic            WriteMCOUNTERENM, WriteMCOUNTINHIBITM;
  logic [`PMP_ENTRIES-1:0] WritePMPCFGM;
  logic [`PMP_ENTRIES-1:0] WritePMPADDRM ; 
  logic [`PMP_ENTRIES-1:0] ADDRLocked, CFGLocked;

  localparam MISA_26 = (`MISA) & 32'h03ffffff;

  // MISA is hardwired.  Spec says it could be written to disable features, but this is not supported by Wally
  assign MISA_REGW = {(`XLEN == 32 ? 2'b01 : 2'b10), {(`XLEN-28){1'b0}}, MISA_26[25:0]};

  // MHARTID is hardwired. It only exists as a signal so that the testbench can easily see it.
  assign MHARTID_REGW = 0;

  // Write machine Mode CSRs 
  assign WriteMSTATUSM = CSRMWriteM && (CSRAdrM == MSTATUS) && ~StallW;
  assign WriteMTVECM = CSRMWriteM && (CSRAdrM == MTVEC) && ~StallW;
  assign WriteMEDELEGM = CSRMWriteM && (CSRAdrM == MEDELEG) && ~StallW;
  assign WriteMIDELEGM = CSRMWriteM && (CSRAdrM == MIDELEG) && ~StallW;
  assign WriteMSCRATCHM = CSRMWriteM && (CSRAdrM == MSCRATCH) && ~StallW;
  assign WriteMEPCM = MTrapM | (CSRMWriteM && (CSRAdrM == MEPC)) && ~StallW;
  assign WriteMCAUSEM = MTrapM | (CSRMWriteM && (CSRAdrM == MCAUSE)) && ~StallW;
  assign WriteMTVALM = MTrapM | (CSRMWriteM && (CSRAdrM == MTVAL)) && ~StallW;
  assign WriteMCOUNTERENM = CSRMWriteM && (CSRAdrM == MCOUNTEREN) && ~StallW;
  assign WriteMCOUNTINHIBITM = CSRMWriteM && (CSRAdrM == MCOUNTINHIBIT) && ~StallW;

  assign IllegalCSRMWriteReadonlyM = CSRMWriteM && (CSRAdrM == MVENDORID || CSRAdrM == MARCHID || CSRAdrM == MIMPID || CSRAdrM == MHARTID);

  // CSRs
  flopenl #(`XLEN) MTVECreg(clk, reset, WriteMTVECM, {CSRWriteValM[`XLEN-1:2], 1'b0, CSRWriteValM[0]}, `XLEN'b0, MTVEC_REGW); //busybear: changed reset value to 0
  generate
    if (`S_SUPPORTED | (`U_SUPPORTED & `N_SUPPORTED)) begin // DELEG registers should exist
      flopenl #(`XLEN) MEDELEGreg(clk, reset, WriteMEDELEGM, CSRWriteValM & MEDELEG_MASK /*12'h7FF*/, `XLEN'b0, MEDELEG_REGW);
      flopenl #(`XLEN) MIDELEGreg(clk, reset, WriteMIDELEGM, CSRWriteValM & MIDELEG_MASK /*12'h222*/, `XLEN'b0, MIDELEG_REGW);
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
    if (`BUSYBEAR == 1)
      flopenl #(32)   MCOUNTERENreg(clk, reset, WriteMCOUNTERENM, {CSRWriteValM[31:2],1'b0,CSRWriteValM[0]}, 32'b0, MCOUNTEREN_REGW);
    else if (`BUILDROOT == 1)
      flopenl #(32)   MCOUNTERENreg(clk, reset, WriteMCOUNTERENM, CSRWriteValM[31:0], 32'h0, MCOUNTEREN_REGW);
    else
      flopenl #(32)   MCOUNTERENreg(clk, reset, WriteMCOUNTERENM, CSRWriteValM[31:0], 32'hFFFFFFFF, MCOUNTEREN_REGW);
  endgenerate
  flopenl #(32)   MCOUNTINHIBITreg(clk, reset, WriteMCOUNTINHIBITM, CSRWriteValM[31:0], 32'h0, MCOUNTINHIBIT_REGW);

  // There are PMP_ENTRIES = 0, 16, or 64 PMPADDR registers, each of which has its own flop

  // *** need to add support for locked PMPCFG and PMPADR
  genvar i;
  generate
    for(i=0; i<`PMP_ENTRIES; i++) begin
      // when the lock bit is set, don't allow writes to the PMPCFG or PMPADDR
      // also, when the lock bit of the next entry is set and the next entry is TOR, don't allow writes to this entry PMPADDR
      assign CFGLocked[i] = PMPCFG_ARRAY_REGW[i][7];
      if (i == `PMP_ENTRIES-1) 
        assign ADDRLocked[i] = PMPCFG_ARRAY_REGW[i][7];
      else
        assign ADDRLocked[i] = PMPCFG_ARRAY_REGW[i][7] | (PMPCFG_ARRAY_REGW[i+1][7] & PMPCFG_ARRAY_REGW[i+1][4:3] == 2'b01);
      
      assign WritePMPADDRM[i] = (CSRMWriteM & (CSRAdrM == (PMPADDR0+i))) & ~StallW & ~ADDRLocked[i];
      flopenr #(`XLEN) PMPADDRreg(clk, reset, WritePMPADDRM[i], CSRWriteValM, PMPADDR_ARRAY_REGW[i]);
      if (`XLEN==64) begin
        assign WritePMPCFGM[i] = (CSRMWriteM & (CSRAdrM == (PMPCFG0+2*(i/8)))) & ~StallW & ~CFGLocked[i];
        flopenr #(8) PMPCFGreg(clk, reset, WritePMPCFGM[i], CSRWriteValM[(i%8)*8+7:(i%8)*8], PMPCFG_ARRAY_REGW[i]);
      end else begin
        assign WritePMPCFGM[i]  = (CSRMWriteM & (CSRAdrM == (PMPCFG0+i/4))) & ~StallW & ~CFGLocked[i];
//        assign WritePMPCFGHM[i] = (CSRMWriteM && (CSRAdrM == PMPCFG0+2*i+1)) && ~StallW;
        flopenr #(8) PMPCFGreg(clk, reset, WritePMPCFGM[i], CSRWriteValM[(i%4)*8+7:(i%4)*8], PMPCFG_ARRAY_REGW[i]);
//        flopenr #(`XLEN) PMPCFGHreg(clk, reset, WritePMPCFGHM[i], CSRWriteValM, PMPCFG_ARRAY_REGW[i][63:32]);
      end
    end
  endgenerate

  // Read machine mode CSRs
  // verilator lint_off WIDTH
  logic [5:0] entry;
  always_comb begin
    entry = '0;
    IllegalCSRMAccessM = !(`S_SUPPORTED | `U_SUPPORTED & `N_SUPPORTED) && 
                          (CSRAdrM == MEDELEG || CSRAdrM == MIDELEG); // trap on DELEG register access when no S or N-mode
    if (CSRAdrM >= PMPADDR0 && CSRAdrM < PMPADDR0 + `PMP_ENTRIES) // reading a PMP entry
      CSRMReadValM = PMPADDR_ARRAY_REGW[CSRAdrM - PMPADDR0];
    else if (CSRAdrM >= PMPCFG0 && CSRAdrM < PMPCFG0 + `PMP_ENTRIES/4) begin
      if (`XLEN==64) begin
        entry = ({CSRAdrM[11:1], 1'b0} - PMPCFG0)*4; // disregard odd entries in RV64
        CSRMReadValM = {PMPCFG_ARRAY_REGW[entry+7],PMPCFG_ARRAY_REGW[entry+6],PMPCFG_ARRAY_REGW[entry+5],PMPCFG_ARRAY_REGW[entry+4],
                        PMPCFG_ARRAY_REGW[entry+3],PMPCFG_ARRAY_REGW[entry+2],PMPCFG_ARRAY_REGW[entry+1],PMPCFG_ARRAY_REGW[entry]};
      end else begin
        entry = (CSRAdrM - PMPCFG0)*4;
        CSRMReadValM = {PMPCFG_ARRAY_REGW[entry+3],PMPCFG_ARRAY_REGW[entry+2],PMPCFG_ARRAY_REGW[entry+1],PMPCFG_ARRAY_REGW[entry]};
      end

      /*
      if (~CSRAdrM[0]) CSRMReadValM = {PMPCFG_ARRAY_REGW[]};
      else             CSRMReadValM = {{(`XLEN-32){1'b0}}, PMPCFG_ARRAY_REGW[(CSRAdrM - PMPCFG0-1)/2][63:32]};*/
    end
    else case (CSRAdrM) 
      MISA_ADR:  CSRMReadValM = MISA_REGW;
      MVENDORID: CSRMReadValM = 0;
      MARCHID:   CSRMReadValM = 0;
      MIMPID:    CSRMReadValM = `XLEN'h100; // pipelined implementation
      MHARTID:   CSRMReadValM = MHARTID_REGW; // hardwired to 0 
      MSTATUS:   CSRMReadValM = MSTATUS_REGW;
      MSTATUSH:  CSRMReadValM = 0; // flush this out later if MBE and SBE fields are supported
      MTVEC:     CSRMReadValM = MTVEC_REGW;
      //MEDELEG:   CSRMReadValM = {{(`XLEN-12){1'b0}}, MEDELEG_REGW};
      //MIDELEG:   CSRMReadValM = {{(`XLEN-12){1'b0}}, MIDELEG_REGW};
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

      default: begin
                 CSRMReadValM = 0;
                 IllegalCSRMAccessM = 1;
      end
    endcase
  end
  // verilator lint_on WIDTH
endmodule

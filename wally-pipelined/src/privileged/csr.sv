///////////////////////////////////////////
// csr.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//          dottolia@hmc.edu 7 April 2021
//
// Purpose: Counter Control and Status Registers
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

module csr #(parameter
  // Constants
  UIP_REGW = 12'b0, // N user-mode exceptions not supported
  UIE_REGW = 12'b0
  ) (
  input  logic             clk, reset,
  input  logic             FlushW, StallD, StallE, StallM, StallW,
  input  logic [31:0]      InstrD,InstrE,InstrM, 
  input  logic [`XLEN-1:0] PCF, PCD, PCE, PCM, SrcAM,
  input  logic             InterruptM,
  input  logic             CSRReadM, CSRWriteM, TrapM, MTrapM, STrapM, UTrapM, mretM, sretM, uretM,
  input  logic             TimerIntM, ExtIntM, SwIntM,
  input  logic [63:0]      MTIME_CLINT, MTIMECMP_CLINT,
  input  logic             InstrValidW, FloatRegWriteW, LoadStallD,
  input  logic 		   BPPredDirWrongM,
  input  logic 		   BTBPredPCWrongM,
  input  logic 		   RASPredPCWrongM,
  input  logic 		   BPPredClassNonCFIWrongM,
  input  logic [4:0]       InstrClassM,
  input  logic [1:0]       NextPrivilegeModeM, PrivilegeModeW,
  input  logic [`XLEN-1:0] CauseM, NextFaultMtvalM,
  input  logic             BreakpointFaultM, EcallFaultM,
  input  logic             InstrMisalignedFaultM, InstrAccessFaultM, IllegalInstrFaultM,
  input  logic             LoadMisalignedFaultM, StoreMisalignedFaultM, LoadAccessFaultM, StoreAccessFaultM,
  output logic [1:0]       STATUS_MPP,
  output logic             STATUS_SPP, STATUS_TSR,
  output logic [`XLEN-1:0] MEPC_REGW, SEPC_REGW, UEPC_REGW, UTVEC_REGW, STVEC_REGW, MTVEC_REGW,
  output logic [`XLEN-1:0]      MEDELEG_REGW, MIDELEG_REGW, SEDELEG_REGW, SIDELEG_REGW, 
  output logic [`XLEN-1:0] SATP_REGW,
  output logic [11:0]      MIP_REGW, MIE_REGW, SIP_REGW, SIE_REGW,
  output logic             STATUS_MIE, STATUS_SIE,
  output logic             STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  output var logic [7:0]      PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  output var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0],
  input  logic [4:0]       SetFflagsM,
  output logic [2:0]       FRM_REGW, 
//  output logic [11:0]     MIP_REGW, SIP_REGW, UIP_REGW, MIE_REGW, SIE_REGW, UIE_REGW,
  output logic [`XLEN-1:0] CSRReadValW,
  output logic             IllegalCSRAccessM
);

  localparam NOP = 32'h13;
  logic [`XLEN-1:0] CSRMReadValM, CSRSReadValM, CSRUReadValM, CSRNReadValM, CSRCReadValM, CSRReadValM;
  logic [`XLEN-1:0] CSRSrcM, CSRRWM, CSRRSM, CSRRCM, CSRWriteValM;
 
  logic [`XLEN-1:0] MSTATUS_REGW, SSTATUS_REGW, USTATUS_REGW;
  logic [31:0]     MCOUNTINHIBIT_REGW, MCOUNTEREN_REGW, SCOUNTEREN_REGW;
  logic            WriteMSTATUSM, WriteSSTATUSM, WriteUSTATUSM;
  logic            CSRMWriteM, CSRSWriteM, CSRUWriteM;
  logic            STATUS_TVM;

  logic [`XLEN-1:0] UnalignedNextEPCM, NextEPCM, NextCauseM, NextMtvalM;

  logic [11:0] CSRAdrM;
  //logic [11:0] UIP_REGW, UIE_REGW = 0; // N user-mode exceptions not supported
  logic        IllegalCSRCAccessM, IllegalCSRMAccessM, IllegalCSRSAccessM, IllegalCSRUAccessM, IllegalCSRNAccessM, InsufficientCSRPrivilegeM;
  logic IllegalCSRMWriteReadonlyM;
  
  generate
    if (`ZCSR_SUPPORTED) begin
      // modify CSRs
      always_comb begin
        // Choose either rs1 or uimm[4:0] as source
        CSRSrcM = InstrM[14] ? {{(`XLEN-5){1'b0}}, InstrM[19:15]} : SrcAM;
        // Compute AND/OR modification
        CSRRWM = CSRSrcM;
        CSRRSM = CSRReadValM | CSRSrcM;
        CSRRCM = CSRReadValM & ~CSRSrcM;
        case (InstrM[13:12])
          2'b01:  CSRWriteValM = CSRRWM;
          2'b10:  CSRWriteValM = CSRRSM;
          2'b11:  CSRWriteValM = CSRRCM;
          default: CSRWriteValM = CSRReadValM;
        endcase
      end

      // write CSRs
      assign CSRAdrM = InstrM[31:20];
      assign UnalignedNextEPCM = TrapM ? PCM : CSRWriteValM;
      assign NextEPCM = `C_SUPPORTED ? {UnalignedNextEPCM[`XLEN-1:1], 1'b0} : {UnalignedNextEPCM[`XLEN-1:2], 2'b00}; // 3.1.15 alignment
      assign NextCauseM = TrapM ? CauseM : CSRWriteValM;
      assign NextMtvalM = TrapM ? NextFaultMtvalM : CSRWriteValM;
      assign CSRMWriteM = CSRWriteM && (PrivilegeModeW == `M_MODE);
      assign CSRSWriteM = CSRWriteM && (|PrivilegeModeW);
      assign CSRUWriteM = CSRWriteM;  

      csri  csri(.*);
      csrsr csrsr(.*);
      csrc  counters(.*);
      csrm  csrm(.*); // Machine Mode CSRs
      csrs  csrs(.*);
      csrn  csrn(.CSRNWriteM(CSRUWriteM), .*);  // User Mode Exception Registers
      csru  csru(.*); // Floating Point Flags are part of User MOde

      // merge CSR Reads
      assign CSRReadValM = CSRUReadValM | CSRSReadValM | CSRMReadValM | CSRCReadValM | CSRNReadValM; 
      // *** add W stall 2/22/21 dh to try fixing memory stalls
//      floprc #(`XLEN) CSRValWReg(clk, reset, FlushW, CSRReadValM, CSRReadValW);
      flopenrc #(`XLEN) CSRValWReg(clk, reset, FlushW, ~StallW, CSRReadValM, CSRReadValW);

      // merge illegal accesses: illegal if none of the CSR addresses is legal or privilege is insufficient
      assign InsufficientCSRPrivilegeM = (CSRAdrM[9:8] == 2'b11 && PrivilegeModeW != `M_MODE) ||
                                        (CSRAdrM[9:8] == 2'b01 && PrivilegeModeW == `U_MODE);
      assign IllegalCSRAccessM = ((IllegalCSRCAccessM && IllegalCSRMAccessM && 
        IllegalCSRSAccessM && IllegalCSRUAccessM  && IllegalCSRNAccessM ||
        InsufficientCSRPrivilegeM) && CSRReadM) || IllegalCSRMWriteReadonlyM;
    end else begin // CSRs not implemented
      assign STATUS_MPP = 2'b11;
      assign STATUS_SPP = 2'b0;
      assign STATUS_TSR = 0;
      assign MEPC_REGW = 0;
      assign SEPC_REGW = 0;
      assign UEPC_REGW = 0;
      assign UTVEC_REGW = 0;
      assign STVEC_REGW = 0;
      assign MTVEC_REGW = 0;
      assign MEDELEG_REGW = 0;
      assign MIDELEG_REGW = 0;
      assign SEDELEG_REGW = 0;
      assign SIDELEG_REGW = 0;
      assign SATP_REGW = 0;
      assign MIP_REGW = 0;
      assign MIE_REGW = 0;
      assign STATUS_MIE = 0;
      assign STATUS_SIE = 0;
      assign FRM_REGW = 0;
      assign CSRReadValM = 0;
      assign IllegalCSRAccessM = CSRReadM;
    end
  endgenerate
endmodule

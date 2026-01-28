///////////////////////////////////////////
// csrh.sv
//
// Written: nchulani@hmc.edu, vkrishna@hmc.edu, jgong@hmc.edu 11 November 2025
// Purpose: Hypervisor-Mode Control and Status Registers
//          See RISC-V Privileged Mode Specification (Hypervisor Extension)
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
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

module csrh import cvw::*;  #(parameter cvw_t P) (
  input  logic              clk, reset,
  input  logic              CSRHWriteM,       // High if operation is a write
  input  logic              CSRWriteM,        // CSR instruction writes
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  input  logic [1:0]        PrivilegeModeW,   // Current privilege mode (U, S, M)
  input  logic              VirtModeW,        // Virtualization mode (VS/VU)
  input  logic              FRegWriteM,       // VS FP writeback updates vsstatus.FS
  input  logic              WriteFRMM,        // VS CSR write to FRM updates vsstatus.FS
  input  logic              SetOrWriteFFLAGSM,// VS CSR write to FFLAGS updates vsstatus.FS
  input  logic              TrapGVAM,         // Trap writes guest virtual address to tval
  input  logic              VSCSRDirectM,     // VS CSR accessed via its own address in V=1
  input  logic [11:0]       MIP_REGW,         // mip register for HIP calculation

  input  logic              TrapM,            // Trap occurred
  input  logic              TrapToHSM,        // Trap targets HS-mode
  input  logic              TrapToVSM,        // Trap targets VS-mode
  input  logic              sretM,            // SRET in M stage
  input  logic [31:0]       InstrM,           // Instruction for mtinst/htinst decode
  input  logic [P.XLEN-1:0] NextEPCM,         // EPC value for trap/return
  input  logic [4:0]        NextCauseM,       // Exception/interrupt cause
  input  logic [P.XLEN-1:0] NextMtvalM,       // Value for {v,s,}tval on trap
  input  logic [P.XLEN-1:0] NextHtvalM,       // Value for htval on trap

  output logic [P.XLEN-1:0] CSRHReadValM,
  output logic              IllegalCSRHAccessM,
  output logic              HSTATUS_SPV,
  output logic              HSTATUS_VTSR, HSTATUS_VTW, HSTATUS_VTVM,
  output logic              HSTATUS_VSBE,
  output logic              VSSTATUS_SPP,
  output logic              VSSTATUS_SUM, VSSTATUS_MXR, VSSTATUS_UBE,
  output logic [1:0]        VSSTATUS_FS,
  output logic [63:0]       HEDELEG_REGW,
  output logic [11:0]       HIDELEG_REGW,
  output logic [31:0]       HCOUNTEREN_REGW,
  output logic [P.XLEN-1:0] VSTVEC_REGW,
  output logic [P.XLEN-1:0] VSEPC_REGW
);

  logic [P.XLEN-1:0] MTINST_REGW;
  logic [P.XLEN-1:0] MTVAL2_REGW;
  logic [P.XLEN-1:0] HSTATUS_REGW;
  logic [P.XLEN-1:0] VSSTATUS_REGW;
  logic              HSTATUS_GVA, HSTATUS_SPVP, HSTATUS_HU;
  logic [5:0]        HSTATUS_VGEIN;
  logic [1:0]        HSTATUS_VSXL, HSTATUS_HUPMM;
  logic              VSSTATUS_SD, VSSTATUS_SPELP, VSSTATUS_SDT;
  logic              VSSTATUS_MXR_INT, VSSTATUS_SUM_INT;
  logic              VSSTATUS_SPIE, VSSTATUS_SIE;
  logic [1:0]        VSSTATUS_FS_INT, VSSTATUS_XS, VSSTATUS_UXL, VSSTATUS_VS;
  logic [P.XLEN-1:0] HIE_REGW;
  logic [11:0]       VSIE_REGW;
  logic [63:0] HTIMEDELTA_REGW;
  logic [P.XLEN-1:0] HGEIE_REGW;
  logic [63:0]       HENVCFG_REGW;
  logic [P.XLEN-1:0] HTVAL_REGW;
  logic [P.XLEN-1:0] VSTVAL_REGW;
  logic [11:0]       VSIP_REGW;
  logic [11:0]       HVIP_REGW; // 12 bits due to top bits being 0
  logic [P.XLEN-1:0] HTINST_REGW;
  logic [P.XLEN-1:0] HGATP_REGW;
  logic [P.XLEN-1:0] HGEIP_REGW;
  logic [P.XLEN-1:0] VSSCRATCH_REGW;
  logic [P.XLEN-1:0] VSCAUSE_REGW;
  logic [P.XLEN-1:0] VSATP_REGW;
  logic [63:0] VSTIMECMP_REGW;

  // Hypervisor CSR Addresses
  localparam MTINST     = 12'h34A;
  localparam MTVAL2     = 12'h34B;
  localparam HSTATUS    = 12'h600;
  localparam VSSTATUS   = 12'h200;
  localparam HEDELEG    = 12'h602;
  localparam HEDELEGH    = 12'h612;
  localparam HIDELEG    = 12'h603;
  localparam HIE        = 12'h604;
  localparam VSIE       = 12'h204;
  localparam HTIMEDELTA = 12'h605;
  localparam HTIMEDELTAH = 12'h615;
  localparam HCOUNTEREN = 12'h606;
  localparam HGEIE      = 12'h607;
  localparam HENVCFG    = 12'h60A;
  localparam HENVCFGH   = 12'h61A;
  localparam HTVAL      = 12'h643;
  localparam VSTVAL    = 12'h243;
  localparam HIP        = 12'h644;
  localparam VSIP        = 12'h244;
  localparam HVIP       = 12'h645;
  localparam HTINST     = 12'h64A;
  localparam HGATP      = 12'h680;
  localparam HGEIP      = 12'hE12;
  localparam VSTVEC     = 12'h205;
  localparam VSSCRATCH  = 12'h240;
  localparam VSEPC      = 12'h241;
  localparam VSCAUSE    = 12'h242;
  localparam VSATP      = 12'h280;
  localparam VSTIMECMP  = 12'h24D;
  localparam VSTIMECMPH = 12'h25D;
  localparam [63:0] HEDELEG_MASK = 64'h0000_0000_0000_FFFF;
  localparam [11:0] HIDELEG_MASK = 12'hFFF;

  // Write Enables for CSR instructions
  logic WriteMTINSTM;
  logic WriteMTVAL2M;
  logic WriteHSTATUSM, WriteVSSTATUS;
  logic WriteHEDELEGM, WriteHEDELEGHM;
  logic WriteHIDELEGM;
  logic WriteHIEM, WriteVSIEM;
  logic WriteHTIMEDELTAM, WriteHTIMEDELTAHM;
  logic WriteHCOUNTERENM;
  logic WriteHGEIEM;
  logic WriteHENVCFGM, WriteHENVCFGHM;
  logic WriteHTVALM, WriteVSTVALM;
  logic WriteVSIPM;
  logic WriteHVIPM;
  logic WriteHTINSTM;
  logic WriteHGATPM;
  logic WriteHGEIPM;
  logic WriteVSTVECM;
  logic WriteVSSCRATCHM;
  logic WriteVSEPCM;
  logic WriteVSCAUSEM;
  logic WriteVSATPM;
  logic WriteVSTIMECMPM, WriteVSTIMECMPHM;
  logic AllowVSTimecmpAccess;
  logic HSTrapM, VSTrapM;
  logic PrivReturnHSM, PrivReturnVSM;
  logic [P.XLEN-1:0] NextMtinstM;
  logic [P.XLEN-1:0] NextHtinstM;
  logic [P.XLEN-1:0] NextMtval2M;

  // Next Value Muxes
  logic [P.XLEN-1:0] NextHTVAL;
  logic [P.XLEN-1:0] NextHTINST;
  logic [63:0]       NextHEDELEG;
  logic [11:0]       NextHIDELEG;
  logic [P.XLEN-1:0] VSTVECWriteValM;

  // CSR Write Validation Intermediates
  logic LegalHAccessM;
  logic LegalVSAccessM;
  logic ReadOnlyCSR;
  logic ValidHWrite, ValidVSWrite;
  logic LegalAccessM;

  // H-CSRs are accessible in M-Mode or HS-Mode.
  // VS-CSRs are accessible in M-Mode or HS-Mode; in VS-Mode they are accessed via S-CSR remapping.
  // Access is ILLEGAL in U-Mode (U/VU), and H-CSRs are illegal in VS-Mode.
  assign LegalHAccessM = (PrivilegeModeW == P.M_MODE) |
                        ((PrivilegeModeW == P.S_MODE) & ~VirtModeW);
  assign LegalVSAccessM = (PrivilegeModeW == P.M_MODE) |
                          ((PrivilegeModeW == P.S_MODE) & (~VirtModeW | ~VSCSRDirectM));

  assign ReadOnlyCSR = (CSRAdrM == HIP) | (CSRAdrM == HGEIP);

  assign ValidHWrite  = CSRHWriteM & LegalHAccessM & ~ReadOnlyCSR;
  assign ValidVSWrite = CSRHWriteM & LegalVSAccessM;

  assign HSTrapM = TrapM & TrapToHSM;
  assign VSTrapM = TrapM & TrapToVSM;
  assign PrivReturnHSM = sretM & (PrivilegeModeW == P.S_MODE) & ~VirtModeW;
  assign PrivReturnVSM = sretM & (PrivilegeModeW == P.S_MODE) &  VirtModeW;

  // mtinst/htinst/mtval2 are derived from the trapped instruction (InstrM); not yet implemented.
  assign NextMtinstM = '0;
  assign NextHtinstM = '0;
  assign NextMtval2M = '0;

  // Write enables for each CSR (from CSR instruction)
  assign WriteMTINSTM     = ValidHWrite & (CSRAdrM == MTINST) & (PrivilegeModeW == P.M_MODE);
  assign WriteMTVAL2M     = ValidHWrite & (CSRAdrM == MTVAL2) & (PrivilegeModeW == P.M_MODE);
  assign WriteHSTATUSM    = ValidHWrite & (CSRAdrM == HSTATUS);
  assign WriteVSSTATUS    = ValidVSWrite & (CSRAdrM == VSSTATUS);
  assign WriteHEDELEGM    = ValidHWrite & (CSRAdrM == HEDELEG);
  assign WriteHEDELEGHM   = (P.XLEN == 32) & (ValidHWrite & (CSRAdrM == HEDELEGH));
  assign WriteHIDELEGM    = ValidHWrite & (CSRAdrM == HIDELEG);
  assign WriteHIEM        = ValidHWrite & (CSRAdrM == HIE);
  assign WriteVSIEM       = ValidVSWrite & (CSRAdrM == VSIE);
  assign WriteHTIMEDELTAM = ValidHWrite & (CSRAdrM == HTIMEDELTA);
  assign WriteHTIMEDELTAHM = (P.XLEN == 32) & (ValidHWrite & (CSRAdrM == HTIMEDELTAH));
  assign WriteHCOUNTERENM = ValidHWrite & (CSRAdrM == HCOUNTEREN);
  assign WriteHGEIEM      = ValidHWrite & (CSRAdrM == HGEIE);
  assign WriteHENVCFGM    = ValidHWrite & (CSRAdrM == HENVCFG);
  assign WriteHENVCFGHM   = (P.XLEN == 32) & (ValidHWrite & (CSRAdrM == HENVCFGH));
  assign WriteHTVALM      = ValidHWrite & (CSRAdrM == HTVAL);
  assign WriteVSTVALM     = ValidVSWrite & (CSRAdrM == VSTVAL);
  assign WriteVSIPM       = ValidVSWrite & (CSRAdrM == VSIP);
  assign WriteHVIPM       = ValidHWrite & (CSRAdrM == HVIP);
  assign WriteHTINSTM     = ValidHWrite & (CSRAdrM == HTINST);
  assign WriteHGATPM      = ValidHWrite & (CSRAdrM == HGATP);
  assign WriteHGEIPM      = 1'b0; // TODO: Add external interrupt handling
  assign WriteVSTVECM     = ValidVSWrite & (CSRAdrM == VSTVEC);
  assign WriteVSSCRATCHM  = ValidVSWrite & (CSRAdrM == VSSCRATCH);
  assign WriteVSEPCM      = ValidVSWrite & (CSRAdrM == VSEPC);
  assign WriteVSCAUSEM    = ValidVSWrite & (CSRAdrM == VSCAUSE);
  assign WriteVSATPM      = ValidVSWrite & (CSRAdrM == VSATP) & P.VIRTMEM_SUPPORTED;
  // HCOUNTEREN.TM gates vstimecmp access in VS-mode.
  assign AllowVSTimecmpAccess = ~VirtModeW | HCOUNTEREN_REGW[1];
  assign WriteVSTIMECMPM  = ValidVSWrite & (CSRAdrM == VSTIMECMP) & P.SSTC_SUPPORTED & AllowVSTimecmpAccess;
  assign WriteVSTIMECMPHM = (P.XLEN == 32) & P.SSTC_SUPPORTED &
                            (ValidVSWrite & (CSRAdrM == VSTIMECMPH)) & AllowVSTimecmpAccess;


  // MTINST
  flopenr #(P.XLEN) MTINSTreg(clk, reset, WriteMTINSTM, NextMtinstM, MTINST_REGW);

  // MTVAL2
  flopenr #(P.XLEN) MTVAL2reg(clk, reset, WriteMTVAL2M, NextMtval2M, MTVAL2_REGW);


  // HSTATUS
  // HS-visible virtualization control; SPV tracks prior V on HS traps and clears on HS sret.
  always_ff @(posedge clk)
    if (reset) begin
      HSTATUS_SPV   <= 1'b0;
      HSTATUS_SPVP  <= 1'b0;
      HSTATUS_GVA   <= 1'b0;
      HSTATUS_VSBE  <= 1'b0;
      HSTATUS_HU    <= 1'b0;
      HSTATUS_VGEIN <= 6'b0;
      HSTATUS_VTVM  <= 1'b0;
      HSTATUS_VTW   <= 1'b0;
      HSTATUS_VTSR  <= 1'b0;
    end else if (HSTrapM) begin
      HSTATUS_SPV <= VirtModeW;
      if (VirtModeW)
        HSTATUS_SPVP <= PrivilegeModeW[0];
      HSTATUS_GVA <= TrapGVAM;
    end else if (PrivReturnHSM) begin
      HSTATUS_SPV <= 1'b0;
    end else if (WriteHSTATUSM) begin
      HSTATUS_VSBE  <= P.BIGENDIAN_SUPPORTED & CSRWriteValM[5];
      HSTATUS_GVA   <= CSRWriteValM[6];
      HSTATUS_SPV   <= CSRWriteValM[7];
      HSTATUS_SPVP  <= CSRWriteValM[8];
      HSTATUS_HU    <= P.U_SUPPORTED & CSRWriteValM[9];
      HSTATUS_VGEIN <= CSRWriteValM[17:12];
      HSTATUS_VTVM  <= CSRWriteValM[20];
      HSTATUS_VTW   <= CSRWriteValM[21];
      HSTATUS_VTSR  <= CSRWriteValM[22];
    end

  assign HSTATUS_VSXL = (P.XLEN == 64) ? 2'b10 : 2'b00;
  assign HSTATUS_HUPMM = 2'b00;

  if (P.XLEN == 64) begin : hstatus64
    assign HSTATUS_REGW = {14'b0, HSTATUS_HUPMM, 14'b0, HSTATUS_VSXL, 9'b0,
                           HSTATUS_VTSR, HSTATUS_VTW, HSTATUS_VTVM, 2'b0,
                           HSTATUS_VGEIN, 2'b0, HSTATUS_HU, HSTATUS_SPVP,
                           HSTATUS_SPV, HSTATUS_GVA, HSTATUS_VSBE, 5'b0};
  end else begin : hstatus32
    assign HSTATUS_REGW = {9'b0, HSTATUS_VTSR, HSTATUS_VTW, HSTATUS_VTVM, 2'b0,
                           HSTATUS_VGEIN, 2'b0, HSTATUS_HU, HSTATUS_SPVP,
                           HSTATUS_SPV, HSTATUS_GVA, HSTATUS_VSBE, 5'b0};
  end

  // VSSTATUS
  // Guest-visible SSTATUS state, updated on VS traps/returns or CSR writes.
  assign VSSTATUS_MXR = P.S_SUPPORTED & VSSTATUS_MXR_INT;
  assign VSSTATUS_SUM = P.S_SUPPORTED & P.VIRTMEM_SUPPORTED & VSSTATUS_SUM_INT;
  assign VSSTATUS_FS  = P.F_SUPPORTED ? VSSTATUS_FS_INT : 2'b00;
  assign VSSTATUS_XS  = 2'b00;
  assign VSSTATUS_VS  = 2'b00;
  assign VSSTATUS_SPELP = 1'b0;
  assign VSSTATUS_SDT = 1'b0;
  assign VSSTATUS_SD  = (VSSTATUS_FS == 2'b11) | (VSSTATUS_XS == 2'b11) | (VSSTATUS_VS == 2'b11);
  assign VSSTATUS_UXL = P.U_SUPPORTED ? ((P.XLEN == 64) ? 2'b10 : 2'b01) : 2'b00;

  if (P.XLEN == 64) begin : vsstatus64
    assign VSSTATUS_REGW = {VSSTATUS_SD, 29'b0, VSSTATUS_UXL, 7'b0,
                            VSSTATUS_SDT, VSSTATUS_SPELP, 3'b0,
                            VSSTATUS_MXR, VSSTATUS_SUM, 1'b0,
                            VSSTATUS_XS, VSSTATUS_FS, 2'b0, VSSTATUS_VS,
                            VSSTATUS_SPP, 1'b0, VSSTATUS_UBE, VSSTATUS_SPIE,
                            3'b0, VSSTATUS_SIE, 1'b0};
  end else begin : vsstatus32
    assign VSSTATUS_REGW = {VSSTATUS_SD, 6'b0, VSSTATUS_SDT, VSSTATUS_SPELP, 3'b0,
                            VSSTATUS_MXR, VSSTATUS_SUM, 1'b0,
                            VSSTATUS_XS, VSSTATUS_FS, 2'b0, VSSTATUS_VS,
                            VSSTATUS_SPP, 1'b0, VSSTATUS_UBE, VSSTATUS_SPIE,
                            3'b0, VSSTATUS_SIE, 1'b0};
  end

  // VSSTATUS update mirrors SSTATUS ordering in csrsr for easier sharing.
  always_ff @(posedge clk)
    if (reset) begin
      VSSTATUS_MXR_INT <= 1'b0;
      VSSTATUS_SUM_INT <= 1'b0;
      VSSTATUS_FS_INT  <= 2'b00;
      VSSTATUS_SPP     <= 1'b0;
      VSSTATUS_SPIE    <= 1'b0;
      VSSTATUS_SIE     <= 1'b0;
      VSSTATUS_UBE     <= 1'b0;
    end else if (VSTrapM) begin
      VSSTATUS_SPIE <= VSSTATUS_SIE;
      VSSTATUS_SIE  <= 1'b0;
      VSSTATUS_SPP  <= PrivilegeModeW[0];
    end else if (PrivReturnVSM) begin
      VSSTATUS_SIE  <= VSSTATUS_SPIE;
      VSSTATUS_SPIE <= 1'b1;
      VSSTATUS_SPP  <= 1'b0;
    end else if (WriteVSSTATUS) begin
      VSSTATUS_MXR_INT <= P.S_SUPPORTED & CSRWriteValM[19];
      VSSTATUS_SUM_INT <= P.VIRTMEM_SUPPORTED & CSRWriteValM[18];
      VSSTATUS_FS_INT  <= CSRWriteValM[14:13];
      VSSTATUS_SPP     <= P.S_SUPPORTED & CSRWriteValM[8];
      VSSTATUS_SPIE    <= P.S_SUPPORTED & CSRWriteValM[5];
      VSSTATUS_SIE     <= P.S_SUPPORTED & CSRWriteValM[1];
      VSSTATUS_UBE     <= P.U_SUPPORTED & P.BIGENDIAN_SUPPORTED & CSRWriteValM[6];
    end else if (VirtModeW & (FRegWriteM | WriteFRMM | SetOrWriteFFLAGSM)) begin
      VSSTATUS_FS_INT  <= 2'b11;
    end

  // Exception and Interrupt Delegation Registers
  // Mask off read-only zero bits (see ISA 15.2.2)
  always_comb begin
    NextHEDELEG = HEDELEG_REGW;
    if (WriteHEDELEGM)  NextHEDELEG[31:0]  = CSRWriteValM[31:0] & HEDELEG_MASK[31:0];
    if (WriteHEDELEGHM) NextHEDELEG[63:32] = CSRWriteValM[31:0] & HEDELEG_MASK[63:32];
  end
  flopenr #(64) HEDELEGreg(clk, reset, (WriteHEDELEGM | WriteHEDELEGHM), NextHEDELEG, HEDELEG_REGW);

  assign NextHIDELEG = WriteHIDELEGM ? (CSRWriteValM[11:0] & HIDELEG_MASK) : HIDELEG_REGW;
  flopenr #(12) HIDELEGreg(clk, reset, WriteHIDELEGM, NextHIDELEG, HIDELEG_REGW);

  // Interrupt Enable / Pending
  flopenr #(P.XLEN) HIEreg(clk, reset, WriteHIEM, CSRWriteValM, HIE_REGW);
  flopenr #(12)     HVIPreg(clk, reset, WriteHVIPM, CSRWriteValM[11:0], HVIP_REGW);
  flopenr #(P.XLEN) HGEIEreg(clk, reset, WriteHGEIEM, CSRWriteValM, HGEIE_REGW);
  flopenr #(12)     VSIEreg(clk, reset, WriteVSIEM, CSRWriteValM[11:0], VSIE_REGW);
  flopenr #(12)     VSIPreg(clk, reset, WriteVSIPM, CSRWriteValM[11:0], VSIP_REGW);

  // HTVAL: Written by CSR instructions and by hardware on traps
  assign NextHTVAL = HSTrapM ? NextHtvalM : CSRWriteValM;
  flopenr #(P.XLEN) HTVALreg(clk, reset, (WriteHTVALM | HSTrapM), NextHTVAL, HTVAL_REGW);

  // HTINST: Written by CSR instructions and by hardware on traps
  assign NextHTINST = HSTrapM ? NextHtinstM : CSRWriteValM;
  flopenr #(P.XLEN) HTINSTreg(clk, reset, (WriteHTINSTM | HSTrapM), NextHTINST, HTINST_REGW);

  // VS CSRs: Guest-visible S-mode state
  assign VSTVECWriteValM = CSRWriteValM[0] ? {CSRWriteValM[P.XLEN-1:6], 6'b000001} :
                                              {CSRWriteValM[P.XLEN-1:2], 2'b00};
  flopenr #(P.XLEN) VSTVECreg(clk, reset, WriteVSTVECM, VSTVECWriteValM, VSTVEC_REGW);
  flopenr #(P.XLEN) VSSCRATCHreg(clk, reset, WriteVSSCRATCHM, CSRWriteValM, VSSCRATCH_REGW);
  flopenr #(P.XLEN) VSEPCreg(clk, reset, (VSTrapM | WriteVSEPCM), NextEPCM, VSEPC_REGW);
  flopenr #(P.XLEN) VSCAUSEreg(clk, reset, (VSTrapM | WriteVSCAUSEM),
                              {NextCauseM[4], {(P.XLEN-5){1'b0}}, NextCauseM[3:0]}, VSCAUSE_REGW);
  flopenr #(P.XLEN) VSTVALreg(clk, reset, (VSTrapM | WriteVSTVALM), NextMtvalM, VSTVAL_REGW);
  if (P.VIRTMEM_SUPPORTED)
    flopenr #(P.XLEN) VSATPreg(clk, reset, WriteVSATPM, CSRWriteValM, VSATP_REGW);
  else
    assign VSATP_REGW = '0;

  if (P.SSTC_SUPPORTED) begin : vstc
    if (P.XLEN == 64) begin : vstc64
      flopenr #(P.XLEN) VSTIMECMPreg(clk, reset, WriteVSTIMECMPM, CSRWriteValM, VSTIMECMP_REGW);
    end else begin : vstc32
      flopenr #(P.XLEN) VSTIMECMPreg(clk, reset, WriteVSTIMECMPM, CSRWriteValM, VSTIMECMP_REGW[31:0]);
      flopenr #(P.XLEN) VSTIMECMPHreg(clk, reset, WriteVSTIMECMPHM, CSRWriteValM, VSTIMECMP_REGW[63:32]);
    end
  end else assign VSTIMECMP_REGW = '0;

  // Address Translation
  flopenr #(P.XLEN) HGATPreg(clk, reset, WriteHGATPM, CSRWriteValM, HGATP_REGW);

  // Configuration & Timers
  flopenr #(32) HCOUNTERENreg(clk, reset, WriteHCOUNTERENM, CSRWriteValM[31:0], HCOUNTEREN_REGW);
  if (P.XLEN == 64) begin : henvcfg_regs_64
    flopenr #(P.XLEN) HENVCFGreg(clk, reset, WriteHENVCFGM, {32'b0, CSRWriteValM[31:0]}, HENVCFG_REGW);
  end else begin : henvcfg_regs_32
    flopenr #(P.XLEN) HENVCFGreg(clk, reset, WriteHENVCFGM, CSRWriteValM, HENVCFG_REGW[31:0]);
    flopenr #(P.XLEN) HENVCFGHreg(clk, reset, WriteHENVCFGHM, CSRWriteValM, HENVCFG_REGW[63:32]);
  end
  if (P.XLEN == 64) begin : htimedelta_regs_64
    flopenr #(P.XLEN) HTIMEDELTAreg(clk, reset, WriteHTIMEDELTAM, CSRWriteValM, HTIMEDELTA_REGW);
  end else begin : htimedelta_regs_32
    flopenr #(P.XLEN) HTIMEDELTAreg(clk, reset, WriteHTIMEDELTAM, CSRWriteValM, HTIMEDELTA_REGW[31:0]);
    flopenr #(P.XLEN) HTIMEDELTAHreg(clk, reset, WriteHTIMEDELTAHM, CSRWriteValM, HTIMEDELTA_REGW[63:32]);
  end
  flopenr #(P.XLEN) HGEIPreg(clk, reset, WriteHGEIPM, CSRWriteValM, HGEIP_REGW);


  // CSR Read and Illegal Access Logic
  always_comb begin : csrrh
    CSRHReadValM = '0;
    LegalAccessM = 1'b0;

    case (CSRAdrM)
      MTINST:     begin LegalAccessM = (PrivilegeModeW == P.M_MODE); CSRHReadValM = MTINST_REGW; end
      MTVAL2:     begin LegalAccessM = (PrivilegeModeW == P.M_MODE); CSRHReadValM = MTVAL2_REGW; end
      HSTATUS:    begin LegalAccessM = LegalHAccessM; CSRHReadValM = HSTATUS_REGW; end
      HEDELEG:    begin LegalAccessM = LegalHAccessM; CSRHReadValM = HEDELEG_REGW[P.XLEN-1:0]; end
      HEDELEGH:   begin LegalAccessM = LegalHAccessM & (P.XLEN == 32); CSRHReadValM = HEDELEG_REGW[63:32]; end
      HIDELEG:    begin LegalAccessM = LegalHAccessM; CSRHReadValM = {{(P.XLEN-12){1'b0}}, HIDELEG_REGW}; end
      HIE:        begin LegalAccessM = LegalHAccessM; CSRHReadValM = HIE_REGW; end
      HTIMEDELTA: begin LegalAccessM = LegalHAccessM; CSRHReadValM = HTIMEDELTA_REGW[P.XLEN-1:0]; end
      HTIMEDELTAH:begin LegalAccessM = LegalHAccessM & (P.XLEN == 32); CSRHReadValM = HTIMEDELTA_REGW[63:32]; end
      HCOUNTEREN: begin LegalAccessM = LegalHAccessM; CSRHReadValM = {{(P.XLEN-32){1'b0}}, HCOUNTEREN_REGW}; end
      HGEIE:      begin LegalAccessM = LegalHAccessM; CSRHReadValM = HGEIE_REGW; end
      HENVCFG:    begin LegalAccessM = LegalHAccessM; CSRHReadValM = HENVCFG_REGW[P.XLEN-1:0]; end
      HENVCFGH:   begin LegalAccessM = LegalHAccessM & (P.XLEN == 32); CSRHReadValM = HENVCFG_REGW[63:32]; end
      HTVAL:      begin LegalAccessM = LegalHAccessM; CSRHReadValM = HTVAL_REGW; end
      HIP:        begin LegalAccessM = LegalHAccessM; CSRHReadValM = {{(P.XLEN-12){1'b0}}, (HVIP_REGW | MIP_REGW)}; end
      HVIP:       begin LegalAccessM = LegalHAccessM; CSRHReadValM = {{(P.XLEN-12){1'b0}}, HVIP_REGW}; end
      HTINST:     begin LegalAccessM = LegalHAccessM; CSRHReadValM = HTINST_REGW; end
      HGATP:      begin LegalAccessM = LegalHAccessM; CSRHReadValM = HGATP_REGW; end
      HGEIP:      begin LegalAccessM = LegalHAccessM; CSRHReadValM = HGEIP_REGW; end

      VSSTATUS:   begin LegalAccessM = LegalVSAccessM; CSRHReadValM = VSSTATUS_REGW; end
      VSIE:       begin LegalAccessM = LegalVSAccessM; CSRHReadValM = {{(P.XLEN-12){1'b0}}, VSIE_REGW}; end
      VSTVEC:     begin LegalAccessM = LegalVSAccessM; CSRHReadValM = VSTVEC_REGW; end
      VSSCRATCH:  begin LegalAccessM = LegalVSAccessM; CSRHReadValM = VSSCRATCH_REGW; end
      VSEPC:      begin LegalAccessM = LegalVSAccessM; CSRHReadValM = VSEPC_REGW; end
      VSCAUSE:    begin LegalAccessM = LegalVSAccessM; CSRHReadValM = VSCAUSE_REGW; end
      VSTVAL:     begin LegalAccessM = LegalVSAccessM; CSRHReadValM = VSTVAL_REGW; end
      VSIP:       begin LegalAccessM = LegalVSAccessM; CSRHReadValM = {{(P.XLEN-12){1'b0}}, VSIP_REGW}; end
      VSATP:      begin LegalAccessM = LegalVSAccessM & P.VIRTMEM_SUPPORTED; CSRHReadValM = VSATP_REGW; end
      VSTIMECMP:  begin LegalAccessM = LegalVSAccessM & P.SSTC_SUPPORTED & AllowVSTimecmpAccess; CSRHReadValM = VSTIMECMP_REGW[P.XLEN-1:0]; end
      VSTIMECMPH: begin LegalAccessM = LegalVSAccessM & P.SSTC_SUPPORTED & (P.XLEN == 32) & AllowVSTimecmpAccess; CSRHReadValM = VSTIMECMP_REGW[63:32]; end

      default:    begin LegalAccessM = 1'b0; CSRHReadValM = '0; end
    endcase
    if (~LegalAccessM) CSRHReadValM = '0;
    IllegalCSRHAccessM = ~LegalAccessM;
    if (CSRWriteM && ReadOnlyCSR)
      IllegalCSRHAccessM = 1'b1;
  end

endmodule

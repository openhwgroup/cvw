///////////////////////////////////////////
// rad.sv
//
// Written: matthew.n.otto@okstate.edu
// Created: 28 April 2024
//
// Purpose: Decodes the register address and generates various control signals 
//          required to access target register on the debug scan chain
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License Version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module rad import cvw::*; #(parameter cvw_t P) (
  input  logic [2:0]        AarSize,
  input  logic [15:0]       Regno,
  output logic              GPRegNo,
  output logic              FPRegNo,
  output logic              CSRegNo,
  output logic [9:0]        ScanChainLen,
  output logic [9:0]        ShiftCount,
  output logic              InvalidRegNo,
  output logic              RegReadOnly,
  output logic [11:0]       RegAddr,
  output logic [P.LLEN-1:0] ARMask
);
  `include "debug.vh"

  localparam TRAPMLEN = P.ZICSR_SUPPORTED ? 1 : 0;
  localparam PCMLEN = (P.ZICSR_SUPPORTED | P.BPRED_SUPPORTED) ? P.XLEN : 0;
  localparam INSTRMLEN = (P.ZICSR_SUPPORTED | P.A_SUPPORTED) ? 32 : 0;
  localparam MEMRWMLEN = 2;
  localparam INSTRVALIDMLEN = 1;
  localparam WRITEDATAMLEN = P.XLEN;
  localparam IEUADRMLEN = P.XLEN;
  localparam READDATAMLEN = P.LLEN;
  localparam SCANCHAINLEN = P.LLEN - 1 
    + TRAPMLEN + PCMLEN + INSTRMLEN
    + MEMRWMLEN + INSTRVALIDMLEN + WRITEDATAMLEN
    + IEUADRMLEN + READDATAMLEN;

  localparam TRAPM_IDX = TRAPMLEN;
  localparam PCM_IDX = TRAPM_IDX + PCMLEN;
  localparam INSTRM_IDX = PCM_IDX + INSTRMLEN;
  localparam MEMRWM_IDX = INSTRM_IDX + MEMRWMLEN;
  localparam INSTRVALIDM_IDX = MEMRWM_IDX + INSTRVALIDMLEN;
  localparam WRITEDATAM_IDX = INSTRVALIDM_IDX + WRITEDATAMLEN;
  localparam IEUADRM_IDX = WRITEDATAM_IDX + IEUADRMLEN;
  localparam READDATAM_IDX = IEUADRM_IDX + READDATAMLEN;

  logic [P.LLEN:0] Mask;

  assign RegAddr = Regno[11:0];
  assign ScanChainLen = (CSRegNo | GPRegNo) ? P.XLEN : FPRegNo ? P.FLEN : SCANCHAINLEN;

  // Register decoder
  always_comb begin
    InvalidRegNo = 0;
    RegReadOnly = 0;
    CSRegNo = 0;
    GPRegNo = 0;
    FPRegNo = 0;
    case (Regno) inside
      [`FFLAGS_REGNO:`FCSR_REGNO],
      [`MSTATUS_REGNO:`MCOUNTEREN_REGNO], //  InvalidRegNo = ~P.ZICSR_SUPPORTED;
      `MENVCFG_REGNO,
      `MSTATUSH_REGNO,
      `MENVCFGH_REGNO,
      `MCOUNTINHIBIT_REGNO,
      [`MSCRATCH_REGNO:`MIP_REGNO],
      [`PMPCFG0_REGNO:`PMPADDR3F_REGNO], // TODO This is variable len (P.PA_BITS)?
      [`TSELECT_REGNO:`TDATA3_REGNO],
      [`DCSR_REGNO:`DPC_REGNO],
      `SIP_REGNO,
      `MIP_REGNO,
      `MHPMEVENTBASE_REGNO,
      `MHPMCOUNTERBASE_REGNO,
      `MHPMCOUNTERHBASE_REGNO,
      [`HPMCOUNTERBASE_REGNO:`TIME_REGNO],
      [`HPMCOUNTERHBASE_REGNO:`TIMEH_REGNO],
      `SSTATUS_REGNO,
      [`SIE_REGNO:`SCOUNTEREN_REGNO],
      `SENVCFG_REGNO,
      [`SSCRATCH_REGNO:`SIP_REGNO],
      `STIMECMP_REGNO,
      `STIMECMPH_REGNO,
      `SATP_REGNO,
      `SIE_REGNO,
      `SIP_REGNO,
      `MIE_REGNO,
      `MIP_REGNO : begin
        ShiftCount = P.LLEN - 1;
        CSRegNo = 1;
        //RegReadOnly = 1;
      end

      [`HPMCOUNTERBASE_REGNO:`TIME_REGNO],
      [`HPMCOUNTERHBASE_REGNO:`TIMEH_REGNO],
      [`MVENDORID_REGNO:`MCONFIGPTR_REGNO] : begin
        ShiftCount = P.LLEN - 1;
        CSRegNo = 1;
        RegReadOnly = 1;
      end

      [`X0_REGNO:`X15_REGNO] : begin
        ShiftCount = P.LLEN - 1;
        GPRegNo = 1;
      end
      [`X16_REGNO:`X31_REGNO] : begin
        ShiftCount = P.LLEN - 1;
        InvalidRegNo = P.E_SUPPORTED;
        GPRegNo = 1;
      end
      [`FP0_REGNO:`FP31_REGNO] : begin
        ShiftCount = P.LLEN - 1;
        InvalidRegNo = ~(P.F_SUPPORTED | P.D_SUPPORTED | P.Q_SUPPORTED);
        FPRegNo = 1;
      end
      `TRAPM_REGNO : begin
        ShiftCount = SCANCHAINLEN - TRAPM_IDX;
        InvalidRegNo = ~P.ZICSR_SUPPORTED;
        RegReadOnly = 1;
      end
      `PCM_REGNO : begin
        ShiftCount = SCANCHAINLEN - PCM_IDX;
        InvalidRegNo = ~(P.ZICSR_SUPPORTED | P.BPRED_SUPPORTED);
      end
      `INSTRM_REGNO : begin
        ShiftCount = SCANCHAINLEN - INSTRM_IDX;
        InvalidRegNo = ~(P.ZICSR_SUPPORTED | P.A_SUPPORTED);
      end
      `MEMRWM_REGNO      : ShiftCount = SCANCHAINLEN - MEMRWM_IDX;
      `INSTRVALIDM_REGNO : ShiftCount = SCANCHAINLEN - INSTRVALIDM_IDX;
      `WRITEDATAM_REGNO  : ShiftCount = SCANCHAINLEN - WRITEDATAM_IDX;
      `IEUADRM_REGNO     : ShiftCount = SCANCHAINLEN - IEUADRM_IDX;
      `READDATAM_REGNO : begin
        ShiftCount = SCANCHAINLEN - READDATAM_IDX;
        RegReadOnly = 1;
      end
      default : begin
        ShiftCount = 0;
        InvalidRegNo = 1;
      end
    endcase
  end

  // Mask calculator
  always_comb begin
    Mask = 0;
    case (Regno) inside
      `TRAPM_REGNO             : Mask = {1{1'b1}};
      `INSTRM_REGNO            : Mask = {32{1'b1}};
      `MEMRWM_REGNO            : Mask = {2{1'b1}};
      `INSTRVALIDM_REGNO       : Mask = {1{1'b1}};
      `READDATAM_REGNO         : Mask = {P.LLEN{1'b1}};
      [`FP0_REGNO:`FP31_REGNO] : Mask = {P.FLEN{1'b1}};
      default                  : Mask = {P.XLEN{1'b1}};
    endcase
  end

  assign ARMask[31:0] = Mask[31:0];
  if (P.LLEN >= 64)
    assign ARMask[63:32] = (AarSize == 3'b011 | AarSize == 3'b100) ? Mask[63:32] : '0;
  if (P.LLEN == 128)
    assign ARMask[127:64] = (AarSize == 3'b100) ? Mask[127:64] : '0;

endmodule

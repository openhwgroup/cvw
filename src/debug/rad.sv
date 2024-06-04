///////////////////////////////////////////
// rad.sv
//
// Written: matthew.n.otto@okstate.edu
// Created: 28 April 2024
//
// Purpose: Calculates the numbers of shifts required to access target register on the debug scan chain
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
  input  logic [2:0]               AarSize,
  input  logic [15:0]              Regno,
  output logic                     GPRRegNo,
  output logic [9:0]               ScanChainLen,
  output logic [9:0]               ShiftCount,
  output logic                     InvalidRegNo,
  output logic                     RegReadOnly,
  output logic [P.E_SUPPORTED+3:0] GPRAddr,
  output logic [P.XLEN-1:0]        ARMask
);
  `include "debug.vh"

  localparam MISALEN = P.ZICSR_SUPPORTED ? P.XLEN : 0;
  localparam TRAPMLEN = P.ZICSR_SUPPORTED ? 1 : 0;
  localparam PCMLEN = (P.ZICSR_SUPPORTED | P.BPRED_SUPPORTED) ? P.XLEN : 0;
  localparam INSTRMLEN = (P.ZICSR_SUPPORTED | P.A_SUPPORTED) ? 32 : 0;
  localparam MEMRWMLEN = 2;
  localparam INSTRVALIDMLEN = 1;
  localparam WRITEDATAMLEN = P.XLEN;
  localparam IEUADRMLEN = P.XLEN;
  localparam READDATAMLEN = P.LLEN;
  localparam SCANCHAINLEN = P.XLEN - 1 
    + MISALEN + TRAPMLEN + PCMLEN + INSTRMLEN
    + MEMRWMLEN + INSTRVALIDMLEN + WRITEDATAMLEN
    + IEUADRMLEN + READDATAMLEN;
  localparam GPRCHAINLEN = P.XLEN;

  localparam MISA_IDX = MISALEN;
  localparam TRAPM_IDX = MISA_IDX + TRAPMLEN;
  localparam PCM_IDX = TRAPM_IDX + PCMLEN;
  localparam INSTRM_IDX = PCM_IDX + INSTRMLEN;
  localparam MEMRWM_IDX = INSTRM_IDX + MEMRWMLEN;
  localparam INSTRVALIDM_IDX = MEMRWM_IDX + INSTRVALIDMLEN;
  localparam WRITEDATAM_IDX = INSTRVALIDM_IDX + WRITEDATAMLEN;
  localparam IEUADRM_IDX = WRITEDATAM_IDX + IEUADRMLEN;
  localparam READDATAM_IDX = IEUADRM_IDX + READDATAMLEN;

  logic [P.XLEN:0] Mask;

  assign ScanChainLen = GPRRegNo ? GPRCHAINLEN : SCANCHAINLEN;

  if (P.E_SUPPORTED)
    assign GPRAddr = Regno[4:0];
  else
    assign GPRAddr = Regno[3:0];

  // Register decoder
  always_comb begin
    InvalidRegNo = 0;
    RegReadOnly = 0;
    GPRRegNo = 0;
    casez (Regno)
      16'h100? : begin
        ShiftCount = P.XLEN - 1;
        GPRRegNo = 1;
      end
      16'h101? : begin
        ShiftCount = P.XLEN - 1;
        InvalidRegNo = ~P.E_SUPPORTED;
        GPRRegNo = 1;
      end
      `MISA : begin
        ShiftCount = SCANCHAINLEN - MISA_IDX;
        InvalidRegNo = ~P.ZICSR_SUPPORTED;
        RegReadOnly = 1;
      end
      `TRAPM : begin
        ShiftCount = SCANCHAINLEN - TRAPM_IDX;
        InvalidRegNo = ~P.ZICSR_SUPPORTED;
        RegReadOnly = 1;
      end
      `PCM : begin
        ShiftCount = SCANCHAINLEN - PCM_IDX;
        InvalidRegNo = ~(P.ZICSR_SUPPORTED | P.BPRED_SUPPORTED);
      end
      `INSTRM : begin
        ShiftCount = SCANCHAINLEN - INSTRM_IDX;
        InvalidRegNo = ~(P.ZICSR_SUPPORTED | P.A_SUPPORTED);
      end
      `MEMRWM      : ShiftCount = SCANCHAINLEN - MEMRWM_IDX;
      `INSTRVALIDM : ShiftCount = SCANCHAINLEN - INSTRVALIDM_IDX;
      `WRITEDATAM  : ShiftCount = SCANCHAINLEN - WRITEDATAM_IDX;
      `IEUADRM     : ShiftCount = SCANCHAINLEN - IEUADRM_IDX;
      `READDATAM : begin
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
    case(Regno)
      `TRAPM       : Mask = {1{1'b1}};
      `INSTRM      : Mask = {32{1'b1}};
      `MEMRWM      : Mask = {2{1'b1}};
      `INSTRVALIDM : Mask = {1{1'b1}};
      `READDATAM   : Mask = {P.LLEN{1'b1}};
      default      : Mask = {P.XLEN{1'b1}};
    endcase
  end

  assign ARMask[31:0] = Mask[31:0];
  if (P.XLEN >= 64)
    assign ARMask[63:32] = (AarSize == 3'b011 | AarSize == 3'b100) ? Mask[63:32] : '0;
  if (P.XLEN == 128)
    assign ARMask[127:64] = (AarSize == 3'b100) ? Mask[127:64] : '0;

endmodule

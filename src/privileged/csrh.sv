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
  input  logic              CSRHWriteM,        // High if operation is a write
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  input  logic [1:0]        PrivilegeModeW,    // Current privilege mode (U, S, M)
  input  logic              NextVirtModeM,     // Next V-mode bit (for hstatus.SPV)
  input  logic              VirtModeW,         // Virtualization mode (VS/VU)
  input  logic [11:0]       MIP_REGW,          // mip register for HIP calculation

  input  logic              HSTrapM,           // Trap occurred in HS-mode
  input  logic              PrivReturnHSM,     // Privilege return (sret) from HS-mode
  input  logic [P.XLEN-1:0] NextEPCM,          // Value for hepc on trap
  input  logic [4:0] NextCauseM,               // Value for hcause on trap
  input  logic [P.XLEN-1:0] NextHtvalM,        // Value for htval on trap
  input  logic [P.XLEN-1:0] NextTinstM,        // Value for htinst on trap

  output logic [P.XLEN-1:0] CSRHReadValM,
  output logic              IllegalCSRHAccessM,

  // Exported Registers
  output logic [P.XLEN-1:0] HSTATUS_REGW,
  output logic [P.XLEN-1:0] HEDELEG_REGW,
  output logic [P.XLEN-1:0] HIDELEG_REGW,
  output logic [P.XLEN-1:0] HEPC_REGW,
  output logic [P.XLEN-1:0] HCAUSE_REGW,
  output logic [11:0]       HVIP_REGW,
  output logic [P.XLEN-1:0] HIE_REGW,
  output logic [P.XLEN-1:0] HGEIE_REGW,
  output logic [P.XLEN-1:0] HENVCFG_REGW,
  output logic [P.XLEN-1:0] HENVCFGH_REGW,      // Added for RV32
  output logic [P.XLEN-1:0] HCOUNTEREN_REGW,
  output logic [P.XLEN-1:0] HGATP_REGW,
  output logic [P.XLEN-1:0] HTVAL_REGW,
  output logic [P.XLEN-1:0] HTINST_REGW
);

  // Hypervisor CSR Addresses
  localparam HSTATUS     = 12'h600;
  localparam HEDELEG     = 12'h602;
  localparam HEDELEGH    = 12'h612;
  localparam HIDELEG     = 12'h603;
  localparam HIE         = 12'h604;
  localparam HTIMEDELTA  = 12'h605;
  localparam HTIMEDELTAH = 12'h615;
  localparam HCOUNTEREN  = 12'h606;
  localparam HGEIE       = 12'h607;
  localparam HENVCFG     = 12'h60A;
  localparam HENVCFGH    = 12'h61A;             // For RV32 only
  localparam HEPC        = 12'h640;
  localparam HCAUSE      = 12'h641;
  localparam HTVAL       = 12'h643;
  localparam HIP         = 12'h644;
  localparam HVIP        = 12'h645;
  localparam HTINST      = 12'h64A;
  localparam HGATP       = 12'h680;

  // Write Enables for CSR instructions
  logic WriteHSTATUSM, WriteHEDELEGM, WriteHEDELEGHM, WriteHIDELEGM;
  logic WriteHIEM, WriteHTIMEDELTAM, WriteHTIMEDELTAHM, WriteHCOUNTERENM;
  logic WriteHGEIEM, WriteHENVCFGM, WriteHENVCFGHM, WriteHTVALM;
  logic WriteHVIPM, WriteHTINSTM, WriteHGATPM;
  logic WriteHEPCM, WriteHCAUSEM;

  logic [P.XLEN-1:0] HTIMEDELTA_REGW;  // Internal register for htimedelta
  logic [P.XLEN-1:0] NextHSTATUS;      // HSTATUS next value mux
  logic [P.XLEN-1:0] NextHEPC;         // HEPC next value mux
  logic [P.XLEN-1:0] NextHCAUSE;       // HCAUSE next value mux
  logic [P.XLEN-1:0] NextHTVAL;        // HTVAL next value mux
  logic [P.XLEN-1:0] NextHTINST;       // HTINST next value mux
  logic LegalHAccessW;                 // CSR Write Validation Intermediates
  logic ReadOnlyCSRM;
  logic ValidWriteM;

  // H-CSRs are accessible in M-Mode or HS-Mode.
  // HS-Mode is S-Mode when VirtModeW is 0.
  // Access is ILLEGAL in U-Mode (U/VU) and VS-Mode (S-Mode when VirtModeW=1).
  assign LegalHAccessW = (PrivilegeModeW == P.M_MODE) |
                        ((PrivilegeModeW == P.S_MODE) & ~VirtModeW);

  assign ReadOnlyCSRM = (CSRAdrM == HIP);

  assign ValidWriteM = CSRHWriteM & LegalHAccessW & ~ReadOnlyCSRM;

  // Write enables for each CSR (from CSR instruction)
  assign WriteHSTATUSM     = ValidWriteM & (CSRAdrM == HSTATUS);
  assign WriteHEDELEGM     = ValidWriteM & (CSRAdrM == HEDELEG);
  assign WriteHEDELEGHM    = ValidWriteM & (CSRAdrM == HEDELEGH) & (P.XLEN = 32);
  assign WriteHIDELEGM     = ValidWriteM & (CSRAdrM == HIDELEG);
  assign WriteHIEM         = ValidWriteM & (CSRAdrM == HIE);
  assign WriteHTIMEDELTAM  = ValidWriteM & (CSRAdrM == HTIMEDELTA);
  assign WriteHTIMEDELTAHM = ValidWriteM & (CSRAdrM == HTIMEDELTAH) & (P.XLEN = 32);
  assign WriteHCOUNTERENM  = ValidWriteM & (CSRAdrM == HCOUNTEREN);
  assign WriteHGEIEM       = ValidWriteM & (CSRAdrM == HGEIE);
  assign WriteHENVCFGM     = ValidWriteM & (CSRAdrM == HENVCFG);
  assign WriteHENVCFGHM   = (P.XLEN == 32) & (ValidWriteM & (CSRAdrM == HENVCFGH));
  assign WriteHEPCM       = ValidWriteM & (CSRAdrM == HEPC);
  assign WriteHCAUSEM     = ValidWriteM & (CSRAdrM == HCAUSE);
  assign WriteHTVALM      = ValidWriteM & (CSRAdrM == HTVAL);
  assign WriteHVIPM       = ValidWriteM & (CSRAdrM == HVIP);
  assign WriteHTINSTM     = ValidWriteM & (CSRAdrM == HTINST);
  assign WriteHGATPM      = ValidWriteM & (CSRAdrM == HGATP);

  // HSTATUS
  // This register is written by CSR instructions and by hardware on sret
  // Three-way mux: CSR write -> CSRWriteValM, sret -> update SPV bit (bit 7), otherwise -> hold
  assign NextHSTATUS = WriteHSTATUSM ? CSRWriteValM :
                       PrivReturnHSM ? {HSTATUS_REGW[P.XLEN-1:8], NextVirtModeM, HSTATUS_REGW[6:0]} :
                       HSTATUS_REGW;
  flopr #(P.XLEN) HSTATUSreg(clk, reset, NextHSTATUS, HSTATUS_REGW);

  // Exception and Interrupt Delegation Registers
  if #(P.XLEN == 64) begin: henvcfg64
    flopenr #(P.XLEN) HEDELEGreg(clk, reset, WriteHEDELEGM, CSRWriteValM, HEDELEG_REGW);
  end else begin: henvcfg32
    flopenr #(P.XELN) HEDELEGreg(clk, reset, WriteHEDELEGM, CSRWriteValM, HEDELEG_REGW[31:0]);
    flopenr #(P.XLEN) HEDELEGHreg(clk, reset, WriteHEDELEGHM, CSRWriteValM, HEDELEG_REGW[63:32]);
  end
  flopenr #(P.XLEN) HIDELEGreg(clk, reset, WriteHIDELEGM, CSRWriteValM, HIDELEG_REGW);

  // Interrupt Enable / Pending
  flopenr #(P.XLEN) HIEreg(clk, reset, WriteHIEM, CSRWriteValM, HIE_REGW);
  flopenr #(12)     HVIPreg(clk, reset, WriteHVIPM, CSRWriteValM[11:0], HVIP_REGW);
  flopenr #(P.XLEN) HGEIEreg(clk, reset, WriteHGEIEM, CSRWriteValM, HGEIE_REGW);

  // Trap Handling
  // HEPC: Written by CSR instructions and by hardware on traps
  assign NextHEPC = HSTrapM ? NextEPCM : CSRWriteValM;
  flopenr #(P.XLEN) HEPCreg(clk, reset, (WriteHEPCM | HSTrapM), NextHEPC, HEPC_REGW);

  // HTVAL: Written by CSR instructions and by hardware on traps
  assign NextHTVAL = HSTrapM ? NextHtvalM : CSRWriteValM;
  flopenr #(P.XLEN) HTVALreg(clk, reset, (WriteHTVALM | HSTrapM), NextHTVAL, HTVAL_REGW);

  // HTINST: Written by CSR instructions and by hardware on traps
  assign NextHTINST = HSTrapM ? NextTinstM : CSRWriteValM;
  flopenr #(P.XLEN) HTINSTreg(clk, reset, (WriteHTINSTM | HSTrapM), NextHTINST, HTINST_REGW);

  // Address Translation
  flopenr #(P.XLEN) HGATPreg(clk, reset, WriteHGATPM, CSRWriteValM, HGATP_REGW);

  // Configuration & Timers
  flopenr #(32) HCOUNTERENreg(clk, reset, WriteHCOUNTERENM, CSRWriteValM, HCOUNTEREN_REGW);
  if #(P.XLEN == 64) begin: henvcfg64
    flopenr #(P.XLEN) HENVCFGreg(clk, reset, WriteHENVCFGM, CSRWriteValM, HENVCFG_REGW);
  end else begin: henvcfg32
    flopenr #(P.XELN) HENVCFGreg(clk, reset, WriteHENVCFGM, CSRWriteValM, HENVCFG_REGW[31:0]);
    flopenr #(P.XLEN) HENVCFGHreg(clk, reset, WriteHENVCFGHM, CSRWriteValM, HENVCFG_REGW[63:32]);
  end
  if #(P.XLEN == 64) begin: htimedelta64
    flopenr #(P.XLEN) HTIMEDELTAreg(clk, reset, WriteHTIMEDELTAM, CSRWriteValM, HTIMEDELTA_REGW);
  end else begin: htimedelta32
    flopenr #(P.XELN) HTIMEDELTAreg(clk, reset, WriteHTIMEDELTAM, CSRWriteValM, HTIMEDELTA_REGW[31:0]);
    flopenr #(P.XLEN) HTIMEDELTAHreg(clk, reset, WriteHTIMEDELTAM, CSRWriteValM, HTIMEDELTA_REGW[63:32]);
  end



  // CSR Read and Illegal Access Logic
  always_comb begin : csrrh
    CSRHReadValM = '0;
    IllegalCSRHAccessM = 1'b0;

    if (~LegalHAccessW) begin : illegalaccess
      IllegalCSRHAccessM = 1'b1;
    end else begin : legalaccess_mux
      case (CSRAdrM)
        HSTATUS:    CSRHReadValM = HSTATUS_REGW;
        HEDELEG:    CSRHReadValM = HEDELEG_REGW;
        HEDELEGH:   if (P.XLEN == 32) begin// not supported for RV64
                      CSRHReadValM = {{(P.XLEN - 32){1'b0}}, HEDELEG_REGW[63:32]};
                    end else begin
                      CSRHReadValM = '0;
                      IllegalCSRHAccessM = 1'b1;
                    end
        HIDELEG:    CSRHReadValM = HIDELEG_REGW;
        HIE:        CSRHReadValM = HIE_REGW;
        HTIMEDELTA: CSRHReadValM = HTIMEDELTA_REGW;
        HTIMEDELTAH:if (P.XLEN == 32) begin// not supported for RV64
                      CSRHReadValM = {{(P.XLEN - 32){1'b0}}, HTIMEDELTA_REGW[63:32]};
                    end else begin
                      CSRHReadValM = '0;
                      IllegalCSRHAccessM = 1'b1;
                    end
        HCOUNTEREN: CSRHReadValM = HCOUNTEREN_REGW;
        HGEIE:      CSRHReadValM = HGEIE_REGW;
        HENVCFG:    CSRHReadValM = HENVCFG_REGW;
        HENVCFGH:   if (P.XLEN == 32) begin// not supported for RV64
                      CSRHReadValM = {{(P.XLEN - 32){1'b0}}, HENVCFG_REGW[63:32]};
                    end else begin
                      CSRHReadValM = '0;
                      IllegalCSRHAccessM = 1'b1;
                    end
        HEPC:       CSRHReadValM = HEPC_REGW;
        HTVAL:      CSRHReadValM = HTVAL_REGW;
        HIP:        CSRHReadValM = {{(P.XLEN-12){1'b0}}, (HVIP_REGW | MIP_REGW)}; // Read-only derived value
        HVIP:       CSRHReadValM = {{(P.XLEN-12){1'b0}}, HVIP_REGW};
        HTINST:     CSRHReadValM = HTINST_REGW;
        HGATP:      CSRHReadValM = HGATP_REGW;
        default:    CSRHReadValM = '0;                                            // Access to non-existent CSR reads 0
      endcase

      if (CSRHWriteM && ReadOnlyCSRM) begin
        IllegalCSRHAccessM = 1'b1;
      end
    end
  end

endmodule

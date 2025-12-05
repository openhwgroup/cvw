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
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  input  logic [1:0]        PrivilegeModeW,   // Current privilege mode (U, S, M)
  input  logic              NextVirtModeM,     // Next V-mode bit (for hstatus.SPV)
  input  logic              VirtModeW,        // Virtualization mode (VS/VU)
  input  logic [11:0]       MIP_REGW,         // mip register for HIP calculation

  input  logic              HSTrapM,          // Trap occurred in HS-mode
  input  logic              PrivReturnHSM,   // Privilege return (sret) from HS-mode
  input  logic [P.XLEN-1:0] NextEPCM,         // Value for hepc on trap
  input  logic [4:0] NextCauseM,      // Value for hcause on trap
  input  logic [P.XLEN-1:0] NextMtvalM,       // Value for htval on trap
  input  logic [P.XLEN-1:0] NextTinstM,       // Value for htinst on trap

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
  output logic [P.XLEN-1:0] HENVCFGH_REGW, // Added for RV32
  output logic [P.XLEN-1:0] HCOUNTEREN_REGW,
  output logic [P.XLEN-1:0] HGATP_REGW,
  output logic [P.XLEN-1:0] HTVAL_REGW,
  output logic [P.XLEN-1:0] HTINST_REGW
);

  // Hypervisor CSR Addresses
  localparam HSTATUS    = 12'h600;
  localparam HEDELEG    = 12'h602;
  localparam HIDELEG    = 12'h603;
  localparam HIE        = 12'h604;
  localparam HTIMEDELTA = 12'h605;
  localparam HCOUNTEREN = 12'h606;
  localparam HGEIE      = 12'h607;
  localparam HENVCFG    = 12'h60A;
  localparam HENVCFGH   = 12'h61A; // For RV32 only
  localparam HEPC       = 12'h640;
  localparam HCAUSE     = 12'h641;
  localparam HTVAL      = 12'h643;
  localparam HIP        = 12'h644;
  localparam HVIP       = 12'h645;
  localparam HTINST     = 12'h64A;
  localparam HGATP      = 12'h680;

  // Write Enables for CSR instructions
  logic WriteHSTATUSM, WriteHEDELEGM, WriteHIDELEGM;
  logic WriteHIEM, WriteHTIMEDELTAM, WriteHCOUNTERENM;
  logic WriteHGEIEM, WriteHENVCFGM, WriteHENVCFGHM, WriteHTVALM;
  logic WriteHVIPM, WriteHTINSTM, WriteHGATPM;
  logic WriteHEPCM, WriteHCAUSSEM;

  // Internal register for htimedelta
  logic [P.XLEN-1:0] HTIMEDELTA_REGW;

  // HSTATUS next value mux
  logic [P.XLEN-1:0] NextHSTATUS;

  // HEPC next value mux
  logic [P.XLEN-1:0] NextHEPC;

  // HCAUSE next value mux
  logic [P.XLEN-1:0] NextHCAUSE;

  // HTVAL next value mux
  logic [P.XLEN-1:0] NextHTVAL;

  // HTINST next value mux
  logic [P.XLEN-1:0] NextHTINST;

  // CSR Write Validation Intermediates
  logic LegalHAccess;
  logic ReadOnlyCSR;
  logic ValidWrite;

  // H-CSRs are accessible in M-Mode or HS-Mode.
  // HS-Mode is S-Mode when VirtModeW is 0.
  // Access is ILLEGAL in U-Mode (U/VU) and VS-Mode (S-Mode when VirtModeW=1).
  assign LegalHAccess = (PrivilegeModeW == P.M_MODE) |
                        ((PrivilegeModeW == P.S_MODE) & ~VirtModeW);

  assign ReadOnlyCSR = (CSRAdrM == HIP);

  assign ValidWrite = CSRHWriteM & LegalHAccess & ~ReadOnlyCSR;

  // Write enables for each CSR (from CSR instruction)
  assign WriteHSTATUSM    = ValidWrite & (CSRAdrM == HSTATUS);
  assign WriteHEDELEGM    = ValidWrite & (CSRAdrM == HEDELEG);
  assign WriteHIDELEGM    = ValidWrite & (CSRAdrM == HIDELEG); // Fixed typo CSRAdrMA -> CSRAdrM
  assign WriteHIEM        = ValidWrite & (CSRAdrM == HIE);
  assign WriteHTIMEDELTAM = ValidWrite & (CSRAdrM == HTIMEDELTA);
  assign WriteHCOUNTERENM = ValidWrite & (CSRAdrM == HCOUNTEREN);
  assign WriteHGEIEM      = ValidWrite & (CSRAdrM == HGEIE);
  assign WriteHENVCFGM    = ValidWrite & (CSRAdrM == HENVCFG);
  // henvcfgh only exists and is writable for RV32
  assign WriteHENVCFGHM   = (P.XLEN == 32) & (ValidWrite & (CSRAdrM == HENVCFGH));
  assign WriteHEPCM       = ValidWrite & (CSRAdrM == HEPC);
  assign WriteHCAUSSEM    = ValidWrite & (CSRAdrM == HCAUSE);
  assign WriteHTVALM      = ValidWrite & (CSRAdrM == HTVAL);
  assign WriteHVIPM       = ValidWrite & (CSRAdrM == HVIP);
  assign WriteHTINSTM     = ValidWrite & (CSRAdrM == HTINST);
  assign WriteHGATPM      = ValidWrite & (CSRAdrM == HGATP);

  // HSTATUS
  // This register is written by CSR instructions and by hardware on sret
  // Three-way mux: CSR write -> CSRWriteValM, sret -> update SPV bit (bit 7), otherwise -> hold
  assign NextHSTATUS = WriteHSTATUSM ? CSRWriteValM :
                       PrivReturnHSM ? {HSTATUS_REGW[P.XLEN-1:8], NextVirtModeM, HSTATUS_REGW[6:0]} :
                       HSTATUS_REGW;
  flopr #(P.XLEN) HSTATUSreg(clk, reset, NextHSTATUS, HSTATUS_REGW);

  // Exception and Interrupt Delegation Registers
  flopenr #(P.XLEN) HEDELEGreg(clk, reset, WriteHEDELEGM, CSRWriteValM, HEDELEG_REGW);
  flopenr #(P.XLEN) HIDELEGreg(clk, reset, WriteHIDELEGM, CSRWriteValM, HIDELEG_REGW);

  // Interrupt Enable / Pending
  flopenr #(P.XLEN) HIEreg(clk, reset, WriteHIEM, CSRWriteValM, HIE_REGW);
  flopenr #(12)     HVIPreg(clk, reset, WriteHVIPM, CSRWriteValM[11:0], HVIP_REGW);
  flopenr #(P.XLEN) HGEIEreg(clk, reset, WriteHGEIEM, CSRWriteValM, HGEIE_REGW);

  // Trap Handling
  // HEPC: Written by CSR instructions and by hardware on traps
  assign NextHEPC = HSTrapM ? NextEPCM : CSRWriteValM;
  flopenr #(P.XLEN) HEPCreg(clk, reset, (WriteHEPCM | HSTrapM), NextHEPC, HEPC_REGW);

  // HCAUSE: Written by CSR instructions and by hardware on traps
  assign NextHCAUSE = HSTrapM ? {{(P.XLEN-5){1'b0}}, NextCauseM} : CSRWriteValM;
  flopenr #(P.XLEN) HCAUSEreg (clk, reset, (WriteHCAUSSEM | HSTrapM), NextHCAUSE, HCAUSE_REGW);

  // HTVAL: Written by CSR instructions and by hardware on traps
  assign NextHTVAL = HSTrapM ? NextMtvalM : CSRWriteValM;
  flopenr #(P.XLEN) HTVALreg(clk, reset, (WriteHTVALM | HSTrapM), NextHTVAL, HTVAL_REGW);

  // HTINST: Written by CSR instructions and by hardware on traps
  assign NextHTINST = HSTrapM ? NextTinstM : CSRWriteValM;
  flopenr #(P.XLEN) HTINSTreg(clk, reset, (WriteHTINSTM | HSTrapM), NextHTINST, HTINST_REGW);

  // Address Translation
  flopenr #(P.XLEN) HGATPreg(clk, reset, WriteHGATPM, CSRWriteValM, HGATP_REGW);

  // Configuration & Timers
  flopenr #(P.XLEN) HCOUNTERENreg(clk, reset, WriteHCOUNTERENM, CSRWriteValM, HCOUNTEREN_REGW);
  flopenr #(P.XLEN) HENVCFGreg(clk, reset, WriteHENVCFGM, CSRWriteValM, HENVCFG_REGW);
  flopenr #(P.XLEN) HENVCFGHreg(clk, reset, WriteHENVCFGHM, CSRWriteValM, HENVCFGH_REGW);
  flopenr #(P.XLEN) HTIMEDELTAreg(clk, reset, WriteHTIMEDELTAM, CSRWriteValM, HTIMEDELTA_REGW);


  // CSR Read and Illegal Access Logic
  always_comb begin : csrrh
    CSRHReadValM = '0;
    IllegalCSRHAccessM = 1'b0;

    if (~LegalHAccess) begin : illegalaccess
      IllegalCSRHAccessM = 1'b1;
    end else begin : legalacess_mux
      case (CSRAdrM)
        HSTATUS:    CSRHReadValM = HSTATUS_REGW;
        HEDELEG:    CSRHReadValM = HEDELEG_REGW;
        HIDELEG:    CSRHReadValM = HIDELEG_REGW;
        HIE:        CSRHReadValM = HIE_REGW;
        HTIMEDELTA: CSRHReadValM = HTIMEDELTA_REGW;
        HCOUNTEREN: CSRHReadValM = HCOUNTEREN_REGW;
        HGEIE:      CSRHReadValM = HGEIE_REGW;
        HENVCFG:    CSRHReadValM = HENVCFG_REGW;
        HENVCFGH:   CSRHReadValM = HENVCFGH_REGW; // Only exists for RV32, reads 0 for RV64
        HEPC:       CSRHReadValM = HEPC_REGW;
        HCAUSE:     CSRHReadValM = HCAUSE_REGW;
        HTVAL:      CSRHReadValM = HTVAL_REGW;
        HIP:        CSRHReadValM = {{(P.XLEN-12){1'b0}}, (HVIP_REGW | MIP_REGW)}; // Read-only derived value
        HVIP:       CSRHReadValM = {{(P.XLEN-12){1'b0}}, HVIP_REGW};
        HTINST:     CSRHReadValM = HTINST_REGW;
        HGATP:      CSRHReadValM = HGATP_REGW;
        default:    CSRHReadValM = '0; // Access to non-existent CSR reads 0
      endcase

      if (CSRHWriteM && ReadOnlyCSR) begin
        IllegalCSRHAccessM = 1'b1;
      end
    end
  end

endmodule

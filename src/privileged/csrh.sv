///////////////////////////////////////////
// csrh.sv
//
// Written: 
//
// Purpose: Hypervisor-Mode Control and Status Registers
//          See RISC-V Privileged Mode Specification and Hypervisor Extension
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2025 Harvey Mudd College
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module csrh import cvw::*;  #(parameter cvw_t P) (
  input  logic              clk, reset,
  // CSR write and trap indicators
  input  logic              CSRHWriteM,            // write strobe when this block is selected
  input  logic              HTrapM,                // trap is targeting HS (V=0 domain)

  // CSR address and data
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] NextEPCM,              // (currently unused in this block)
  input  logic [P.XLEN-1:0] NextMtvalM,            // (currently unused in this block)
  input  logic [P.XLEN-1:0] NextCauseM,            // full XLEN mcause-style encoding (currently unused here)
  input  logic [P.XLEN-1:0] CSRWriteValM,

  // Current privilege and virtualization mode
  input  logic [1:0]        PrivilegeModeW,        // (unused here; decode handled at top-level CSR)
  input  logic              VirtModeW,             // current V

  // CSR read data and side-band
  output logic [P.XLEN-1:0] CSRHReadValM,
  output logic              WriteHSTATUSM,
  output logic              IllegalCSRHAccessM,
  output logic              HSTATUS_SPV            // expose SPV to privmode.sv
);

  // ------------------------------------------------------------
  // CSR address map (H-extension)
  // ------------------------------------------------------------
  localparam HSTATUS  = 12'h600;
  localparam HEDELEG  = 12'h602;
  localparam HIDELEG  = 12'h603;

  // Masks (WARL) for delegation CSRs.
  // Keep conservative for bring-up; refine as you add more causes.
  localparam logic [15:0] HEDELEG_MASK = 16'hB3FE; // similar to MEDELEG but for HS->VS exceptions
  localparam logic [11:0] HIDELEG_MASK = 12'h222;  // supervisor-timer/soft/external to VS

  // ------------------------------------------------------------
  // Write enables
  // ------------------------------------------------------------
  assign WriteHSTATUSM = CSRHWriteM & (CSRAdrM == HSTATUS);
  logic WriteHEDELEGM, WriteHIDELEGM;
  assign WriteHEDELEGM = CSRHWriteM & (CSRAdrM == HEDELEG);
  assign WriteHIDELEGM = CSRHWriteM & (CSRAdrM == HIDELEG);

  // ------------------------------------------------------------
  // Registers
  // ------------------------------------------------------------
  logic [P.XLEN-1:0] HSTATUS_REGW;
  logic [15:0]       HEDELEG_REGW;
  logic [11:0]       HIDELEG_REGW;

  // HSTATUS fields we currently model
  localparam int HSTATUS_SPV_BIT = 7;

  logic HSTATUS_SPV_Q;     // registered SPV
  logic NextHSTATUS_SPV;   // next SPV

  generate
    if (P.H_SUPPORTED) begin : hypervisor
      // Next-state for SPV:
      //  - On trap into HS (HTrapM), SPV captures *current* V.
      //  - On explicit write, SPV comes from CSRWriteValM[7].
      //  - Otherwise, hold.
      always_comb begin
        NextHSTATUS_SPV = HSTATUS_SPV_Q;
        if (HTrapM) begin
          NextHSTATUS_SPV = VirtModeW;
        end else if (WriteHSTATUSM) begin
          NextHSTATUS_SPV = CSRWriteValM[HSTATUS_SPV_BIT];
        end
      end

      // SPV flop. Enable on either an HS trap or a write to HSTATUS.
      flopenr #(1) HSTATUS_SPVreg(
        .clk(clk),
        .reset(reset),
        .en(WriteHSTATUSM | HTrapM),
        .d(NextHSTATUS_SPV),
        .q(HSTATUS_SPV_Q)
      );

      // Construct HSTATUS read value: only SPV is implemented; other bits read as zero for now.
      assign HSTATUS_REGW = {{(P.XLEN-(HSTATUS_SPV_BIT+1)){1'b0}}, HSTATUS_SPV_Q, {{HSTATUS_SPV_BIT}{1'b0}}};

      // HEDELEG / HIDELEG registers
      flopenr #(16) HEDELEGreg(
        .clk(clk), .reset(reset),
        .en(WriteHEDELEGM),
        .d(CSRWriteValM[15:0] & HEDELEG_MASK),
        .q(HEDELEG_REGW)
      );

      flopenr #(12) HIDELEGreg(
        .clk(clk), .reset(reset),
        .en(WriteHIDELEGM),
        .d(CSRWriteValM[11:0] & HIDELEG_MASK),
        .q(HIDELEG_REGW)
      );

      // Export SPV bit
      assign HSTATUS_SPV = HSTATUS_SPV_Q;

    end else begin : no_h
      assign HSTATUS_REGW = '0;
      assign HEDELEG_REGW = '0;
      assign HIDELEG_REGW = '0;
      assign HSTATUS_SPV  = 1'b0;
    end
  endgenerate

  // ------------------------------------------------------------
  // CSR Read mux & illegal access
  // ------------------------------------------------------------
  always_comb begin
    CSRHReadValM       = '0;
    IllegalCSRHAccessM = 1'b0;
    if (P.H_SUPPORTED) begin
      unique case (CSRAdrM)
        HSTATUS: CSRHReadValM = HSTATUS_REGW;
        HEDELEG: CSRHReadValM = {{(P.XLEN-16){1'b0}}, HEDELEG_REGW};
        HIDELEG: CSRHReadValM = {{(P.XLEN-12){1'b0}}, HIDELEG_REGW};
        default: begin
          CSRHReadValM       = '0;
          IllegalCSRHAccessM = 1'b1;
        end
      endcase
    end else begin
      CSRHReadValM       = '0;
      IllegalCSRHAccessM = 1'b1;
    end
  end

  // ------------------------------------------------------------
  // Tie off unused inputs to appease lint (no logic created).
  // ------------------------------------------------------------
  // synopsys translate_off
  // verilator lint_off UNUSED
  logic _unused_ok;
  assign _unused_ok = &{1'b0, NextEPCM, NextMtvalM, NextCauseM, PrivilegeModeW};
  // verilator lint_on  UNUSED
  // synopsys translate_on

endmodule
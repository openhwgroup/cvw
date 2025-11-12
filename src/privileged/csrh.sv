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
  input  logic              CSRHWriteM, HTrapM,
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] NextEPCM, NextMtvalM,
  input  logic [4:0]        NextCauseM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  input  logic [1:0]        PrivilegeModeW,
  input  logic              VirtModeW,
  output logic [P.XLEN-1:0] CSRHReadValM,
  output logic              WriteHSTATUSM,
  output logic              IllegalCSRHAccessM,
  output logic              HSTATUS_SPV
);

  // Hypervisor CSRs
  localparam HSTATUS  = 12'h600;
  localparam HEDELEG  = 12'h602;
  localparam HIDELEG  = 12'h603;
  // Constants
  localparam HEDELEG_MASK  = 16'hB3FE; // similar to MEDELEG, but hypervisor-specific exceptions
  localparam HIDELEG_MASK  = 12'h222;  // similar to MIDELEG, supervisor interrupts delegable to VS

  logic                    WriteHEDELEGM, WriteHIDELEGM;
  logic [P.XLEN-1:0]       HSTATUS_REGW;
  logic [15:0]             HEDELEG_REGW;
  logic [11:0]             HIDELEG_REGW;

  // Write enables
  assign WriteHSTATUSM  = CSRHWriteM & (CSRAdrM == HSTATUS);
  assign WriteHEDELEGM  = CSRHWriteM & (CSRAdrM == HEDELEG);
  assign WriteHIDELEGM  = CSRHWriteM & (CSRAdrM == HIDELEG);

  // HSTATUS register fields
  // Based on RISC-V Hypervisor Extension spec
  // Key fields: SPV (Supervisor Previous Virtual mode) at bit 7
  logic HSTATUS_SPV_INT;
  logic NextHSTATUS_SPV;

  // CSRs
  if (P.H_SUPPORTED) begin:hypervisor
    // HSTATUS SPV field update logic
    // SPV is updated on trap to VS mode, or can be written explicitly
    always_comb begin
      if (HTrapM) begin
        // On trap to VS, save current virtual mode
        NextHSTATUS_SPV = VirtModeW;
      end else if (WriteHSTATUSM) begin
        // Explicit write to HSTATUS
        NextHSTATUS_SPV = CSRWriteValM[7] & P.H_SUPPORTED;
      end else begin
        NextHSTATUS_SPV = HSTATUS_SPV_INT;
      end
    end

    // HSTATUS SPV register
    flopenr #(1) HSTATUS_SPVreg(clk, reset, WriteHSTATUSM | HTrapM, NextHSTATUS_SPV, HSTATUS_SPV_INT);

    // Construct HSTATUS read value
    // HSTATUS format: [XLEN-1:8] reserved, [7] SPV, [6:0] reserved/other fields
    assign HSTATUS_REGW = {
      {(P.XLEN-8){1'b0}},
      HSTATUS_SPV_INT,
      {(7){1'b0}}
    };

    // HEDELEG - Hypervisor Exception Delegation
    flopenr #(16) HEDELEGreg(clk, reset, WriteHEDELEGM, CSRWriteValM[15:0] & HEDELEG_MASK, HEDELEG_REGW);

    // HIDELEG - Hypervisor Interrupt Delegation
    flopenr #(12) HIDELEGreg(clk, reset, WriteHIDELEGM, CSRWriteValM[11:0] & HIDELEG_MASK, HIDELEG_REGW);

    // Output SPV for use in privmode.sv
    assign HSTATUS_SPV = HSTATUS_SPV_INT;
  end else begin
    assign HSTATUS_REGW = '0;
    assign HEDELEG_REGW = '0;
    assign HIDELEG_REGW = '0;
    assign HSTATUS_SPV = 1'b0;
  end

  // CSR Reads
  always_comb begin
    IllegalCSRHAccessM = 1'b0;
    if (P.H_SUPPORTED) begin
      case (CSRAdrM)
        HSTATUS:  CSRHReadValM = HSTATUS_REGW;
        HEDELEG:  CSRHReadValM = {{(P.XLEN-16){1'b0}}, HEDELEG_REGW};
        HIDELEG:  CSRHReadValM = {{(P.XLEN-12){1'b0}}, HIDELEG_REGW};
        default: begin
          CSRHReadValM = '0;
          IllegalCSRHAccessM = 1'b1;
        end
      endcase
    end else begin
      CSRHReadValM = '0;
      IllegalCSRHAccessM = 1'b1;
    end
  end
endmodule


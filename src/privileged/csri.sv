///////////////////////////////////////////
// csri.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified:
//
// Purpose: Interrupt Control & Status Registers (IP, EI)
//          See RISC-V Privileged Mode Specification 20190608 & 20210108 draft
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
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

module csri import cvw::*;  #(parameter cvw_t P) (
  input  logic              clk, reset,
  input  logic              CSRMWriteM, CSRSWriteM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  input  logic [11:0]       CSRAdrM,
  input  logic              MExtInt, SExtInt, MTimerInt, STimerInt, MSwInt,
  input  logic [11:0]       HIP_MIP_REGW, // mip aliases for {VSEIP,VSTIP,VSSIP} from hip
  input  logic              WriteHIEM, WriteVSIEM,
  input  logic [11:0]       HIDELEG_REGW,
  input  logic [11:0]       MIDELEG_REGW,
  input  logic              ENVCFG_STCE,
  output logic [11:0]       HIE_REGW,
  output logic [11:0]       MIP_REGW, MIE_REGW,
  output logic [11:0]       MIP_REGW_writeable // only SEIP, STIP, SSIP are actually writeable; the rest are hardwired to 0
);

  logic [11:0]              MIP_WRITE_MASK, SIP_WRITE_MASK, MIE_WRITE_MASK, SIE_WRITE_MASK, HIE_WRITE_MASK, NextMIE_REGW;
  logic                     WriteMIPM, WriteMIEM, WriteSIPM, WriteSIEM, WriteMIEMasked;
  logic                     STIP;

  localparam MIE = 12'h304;
  localparam MIP = 12'h344;
  localparam SIE = 12'h104;
  localparam SIP = 12'h144;

  // Interrupt Write Enables
  assign WriteMIPM = CSRMWriteM & (CSRAdrM == MIP);
  assign WriteMIEM = CSRMWriteM & (CSRAdrM == MIE);
  assign WriteSIPM = CSRSWriteM & (CSRAdrM == SIP);
  assign WriteSIEM = CSRSWriteM & (CSRAdrM == SIE);

  // Interrupt Pending and Enable Registers
  // MEIP, MTIP, MSIP are read-only
  // SEIP, STIP, SSIP is writable in MIP if S mode exists
  // SSIP is writable in SIP if S mode exists
  if (P.S_SUPPORTED) begin:mask
    if (P.SSTC_SUPPORTED) begin
      assign MIP_WRITE_MASK = ENVCFG_STCE ? 12'h202 : 12'h222; // SEIP and SSIP are writable, but STIP is not writable when STIMECMP is implemented (see SSTC spec)
      assign STIP = ENVCFG_STCE ? STimerInt : MIP_REGW_writeable[5];
    end else begin
      assign MIP_WRITE_MASK = 12'h222; // SEIP, STIP, SSIP are writeable in MIP (20210108-draft 3.1.9)
      assign STIP = MIP_REGW_writeable[5];
    end
    assign SIP_WRITE_MASK = 12'h002 & MIDELEG_REGW; // SSIP is writeable in SIP (privileged 20210108-draft 4.1.3)
    assign MIE_WRITE_MASK = 12'hAAA | HIE_WRITE_MASK;
  end else begin:mask
    assign MIP_WRITE_MASK = 12'h000;
    assign SIP_WRITE_MASK = 12'h000;
    assign MIE_WRITE_MASK = 12'h888 | HIE_WRITE_MASK;
    assign STIP = '0;
  end
  assign SIE_WRITE_MASK = 12'h222 & MIDELEG_REGW;
  always_ff @(posedge clk)
    if (reset)          MIP_REGW_writeable <= 12'b0;
    else if (WriteMIPM) MIP_REGW_writeable <= (CSRWriteValM[11:0] & MIP_WRITE_MASK);
    else if (WriteSIPM) MIP_REGW_writeable <= (CSRWriteValM[11:0] & SIP_WRITE_MASK) | (MIP_REGW_writeable & ~SIP_WRITE_MASK);

  // mie owns all implemented enable state.  hie and vsie are aliases that
  // update/view the H-added bits in mie, matching the existing sie aliasing.
  if (P.H_SUPPORTED) begin : mie_h
    assign HIE_WRITE_MASK = 12'h444;
    assign WriteMIEMasked = WriteMIEM | WriteSIEM | WriteHIEM | WriteVSIEM;
    always_comb begin
      NextMIE_REGW = MIE_REGW;
      if (WriteMIEM)
        NextMIE_REGW = CSRWriteValM[11:0] & MIE_WRITE_MASK;
      else if (WriteSIEM)
        NextMIE_REGW = (MIE_REGW & ~SIE_WRITE_MASK) | (CSRWriteValM[11:0] & SIE_WRITE_MASK);
      else if (WriteHIEM)
        NextMIE_REGW = (MIE_REGW & ~HIE_WRITE_MASK) | (CSRWriteValM[11:0] & HIE_WRITE_MASK);
      else if (WriteVSIEM) begin
        if (HIDELEG_REGW[2])  NextMIE_REGW[2]  = CSRWriteValM[1]; // SSIE -> VSSIE
        if (HIDELEG_REGW[6])  NextMIE_REGW[6]  = CSRWriteValM[5]; // STIE -> VSTIE
        if (HIDELEG_REGW[10]) NextMIE_REGW[10] = CSRWriteValM[9]; // SEIE -> VSEIE
      end
    end
  end else begin : mie_noh
    assign HIE_WRITE_MASK = 12'h000;
    assign WriteMIEMasked = WriteMIEM | WriteSIEM;
    always_comb begin
      NextMIE_REGW = MIE_REGW;
      if (WriteMIEM)
        NextMIE_REGW = CSRWriteValM[11:0] & MIE_WRITE_MASK;
      else if (WriteSIEM)
        NextMIE_REGW = (MIE_REGW & ~SIE_WRITE_MASK) | (CSRWriteValM[11:0] & SIE_WRITE_MASK);
    end
  end
  always_ff @(posedge clk)
    if (reset) MIE_REGW <= 12'b0;
    else if (WriteMIEMasked) MIE_REGW <= NextMIE_REGW;

  assign HIE_REGW = MIE_REGW & HIE_WRITE_MASK;

  // TODO: Add SGEIP alias at bit 12 once MIP/MIE buses are widened beyond 12 bits.
  if (P.H_SUPPORTED) begin : mip_h
    assign MIP_REGW = {MExtInt,   HIP_MIP_REGW[10], SExtInt|MIP_REGW_writeable[9],  1'b0,
                       MTimerInt, HIP_MIP_REGW[6],  STIP,                            1'b0,
                       MSwInt,    HIP_MIP_REGW[2],  MIP_REGW_writeable[1],           1'b0};
  end else begin : mip_noh
    assign MIP_REGW = {MExtInt,   1'b0, SExtInt|MIP_REGW_writeable[9],  1'b0,
                       MTimerInt, 1'b0, STIP,                            1'b0,
                       MSwInt,    1'b0, MIP_REGW_writeable[1],           1'b0};
  end
endmodule

///////////////////////////////////////////
// csrd.sv
//
// Written: matthew.n.otto@okstate.edu
// Created: 13 June 2024
//
// Purpose: Debug Control and Status Registers
//          See RISC-V Debug Specification (4.10)
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

module csrd import cvw::*;  #(parameter cvw_t P) (
  input  logic              clk, reset,
  input  logic              DebugMode,
  input  logic [1:0]        PrivilegeModeW,
  input  logic              CSRWriteDM,
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  output logic [P.XLEN-1:0] CSRDReadValM,
  output logic              IllegalCSRDAccessM,

  input  logic [2:0]        DebugCause,
  output logic              Step,
  output logic [P.XLEN-1:0] DPC,
  input  logic [P.XLEN-1:0] PCNextF,
  input  logic              EnterDebugMode
);
  `include "debug.vh"

  localparam DCSR_ADDR = 12'h7B0;  // Debug Control and Status Register 
  localparam DPC_ADDR  = 12'h7B1;  // Debug PC 

  logic CSRDWriteM;
  logic [31:0] DCSR;
  logic [P.XLEN-1:0] DPCWriteVal;
  logic WriteDCSRM;
  logic WriteDPCM;

  // DCSR fields
  const logic [3:0] DebugVer = 4;
  const logic       ebreakVS = 0;
  const logic       ebreakVU = 0;
  logic             ebreakM;
  logic             ebreakS;
  logic             ebreakU;
  const logic       StepIE = 0;
  const logic       StopCount = 0;
  const logic       StopTime = 0;
  logic [2:0]       Cause;
  const logic       V = 0;
  const logic       MPrvEn = 0;
  logic             NMIP;      // pending non-maskable interrupt
  logic [1:0]       Prv;


  assign CSRDWriteM = CSRWriteDM & (PrivilegeModeW == P.M_MODE) & DebugMode;

  assign WriteDCSRM = CSRDWriteM & (CSRAdrM == DCSR_ADDR);
  assign WriteDPCM  = CSRDWriteM & (CSRAdrM == DPC_ADDR);

  always_ff @(posedge clk) begin
    if (reset) begin
      Prv <= 2'h3;
      Cause <= 3'h0;
    end else if (EnterDebugMode) begin
      Prv <= PrivilegeModeW;
      Cause <= DebugCause;
  end

  flopenr #(4) DCSRreg (clk, reset, WriteDCSRM, 
    {CSRWriteValM[`EBREAKM], CSRWriteValM[`EBREAKS], CSRWriteValM[`EBREAKU], CSRWriteValM[`STEP]}, 
    {ebreakM, ebreakS, ebreakU, Step});

  assign DCSR = {DebugVer, 10'b0, ebreakVS, ebreakVU, ebreakM, 1'b0, ebreakS, ebreakU, StepIE,
                      StopCount, StopTime, Cause, V, MPrvEn, NMIP, Step, Prv};

  assign DPCWriteVal = EnterDebugMode ? PCNextF : CSRWriteValM;
  flopenr #(P.XLEN) DPCreg (clk, reset, WriteDPCM | EnterDebugMode, DPCWriteVal, DPC);

  always_comb begin
    CSRDReadValM = '0;
    IllegalCSRDAccessM = 1'b0;
    if (~((PrivilegeModeW == P.M_MODE) & DebugMode))
      IllegalCSRDAccessM = 1'b1;
    else
      case (CSRAdrM)
        DCSR_ADDR : CSRDReadValM = DCSR;
        DPC_ADDR  : CSRDReadValM = DPC;
        default: IllegalCSRDAccessM = 1'b1;
      endcase
  end

endmodule
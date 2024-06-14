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
  input  logic              CSRWriteDM,
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  output logic [P.XLEN-1:0] CSRDReadValM,
  output logic              IllegalCSRDAccessM,

  output logic              Step
);
  `include "debug.vh"

  localparam DCSR = 12'h7B0;  // Debug Control and Status Register 
  localparam DPC  = 12'h7B1;  // Debug PC 

  // TODO: these registers are only accessible from Debug Mode.
  logic [31:0] DCSR_REGW;
  logic [31:0] DPC_REGW;
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
  logic [2:0]       Cause;     // TODO: give reason for entering debug mode
  const logic       V = 0;
  const logic       MPrvEn = 0;
  logic             NMIP;      // pending non-maskable interrupt
  logic [1:0]       Prv;



  assign WriteDCSRM = CSRWriteDM & (CSRAdrM == DCSR);
  assign WriteDPCM  = CSRWriteDM & (CSRAdrM == DPC);

  always_ff @(posedge clk) begin
    if (reset)
      Prv <= 3;
    //else if (Halt) // TODO: trigger when hart enters debug mode
    //  Prv <= // hart priv mode
    else if (WriteDCSRM)
      Prv <= CSRWriteValM[`PRV]; // TODO: overwrite hart privilege mode
  end

  flopenr ebreakreg(clk, reset, WriteDCSRM, 
    {CSRWriteValM[`EBREAKM], CSRWriteValM[`EBREAKS], CSRWriteValM[`EBREAKU], CSRWriteValM[`STEP]}, 
    {ebreakM, ebreakS, ebreakU, Step});


  assign DCSR_REGW = {4'b0100, 10'b0, ebreakVS, ebreakVU, ebreakM, 1'b0, ebreakS, ebreakU, StepIE,
                      StopCount, StopTime, Cause, V, MPrvEn, NMIP, Step, Prv};
  assign DPC_REGW = {32'hd099f00d};

  always_comb begin
    CSRDReadValM = 0;
    IllegalCSRDAccessM = 0;
    case (CSRAdrM)
      DCSR   : CSRDReadValM = DCSR_REGW;
      DPC    : CSRDReadValM = DPC_REGW;
      default: IllegalCSRDAccessM = 1'b1;
    endcase
  end

endmodule
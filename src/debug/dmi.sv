///////////////////////////////////////////
// dmi.sv
//
// Written: matthew.n.otto@okstate.edu, james.stine@okstate.edu
// Created: 15 March 2024
//
// Purpose: Interface between DM and DTM
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

module dmi #(parameter ADDR_WIDTH) (
  input  logic                  clk, rst,

  // DM Signals
  output logic                  NewCmd,
  output logic [ADDR_WIDTH-1:0] NewCmdAddress,
  output logic [31:0]           NewCmdData,
  output logic [1:0]            NewCmdOP,
  input  logic                  CmdComplete,
  input  logic [31:0]           RspCmdData,
  input  logic [1:0]            RspCmdOP,

  // DTM Signals
  output logic                  ReqReady,
  input  logic                  ReqValid,
  input  logic [ADDR_WIDTH-1:0] ReqAddress,
  input  logic [31:0]           ReqData,
  input  logic [1:0]            ReqOP,
  input  logic                  RspReady,
  output logic                  RspValid,
  output logic [31:0]           RspData,
  output logic [1:0]            RspOP
);
  `include "debug.vh"

  enum {
    IDLE,
    REQ_ACK,
    PROCESSING,
    COMPLETE
  } State, NextState;

  // DMI
  always_ff @(posedge clk) begin
    if (rst)
      State <= IDLE;
    else
      State <= NextState;
  end

  always_comb begin
    NextState = State;
    NewCmd = 0;
    NewCmdAddress = 0;
    NewCmdData = 0;
    NewCmdOP = 0;

    case (State)
      IDLE : begin
        ReqReady = 1;
        RspValid = 0;
        RspOP = `OP_BUSY;
        if (ReqValid) 
          NextState = REQ_ACK;
      end

      REQ_ACK : begin
        ReqReady = 0;
        RspValid = 0;
        RspOP = `OP_BUSY;
        NewCmd = 1;
        NewCmdAddress = ReqAddress;
        NewCmdData = ReqData;
        NewCmdOP = ReqOP;
        if (~ReqValid)
          NextState = PROCESSING;
      end

      PROCESSING : begin
        ReqReady = 0;
        RspValid = 1;
        RspOP = `OP_BUSY;
        if (CmdComplete)
          NextState = COMPLETE;
      end

      COMPLETE : begin
        ReqReady = 0;
        RspValid = 1;
        RspData = RspCmdData;
        RspOP = RspCmdOP;
        if (~RspReady)
          NextState = IDLE;
      end
    endcase
  end

endmodule

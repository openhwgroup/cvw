///////////////////////////////////////////
// dtm.sv
//
// Written: matthew.n.otto@okstate.edu, james.stine@okstate.edu
// Created: 15 March 2024
//
// Purpose: debug transport module (dtm) : allows external debugger to communicate with dm
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
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

// To recovert from a core reset, DTM will need to DtmHardReset (or trstn / tms zeroscan).
//    This is mentioned in spec
// To recover from DTM reset, core will probably need to be reset

module dtm #(parameter ADDR_WIDTH, parameter JTAG_DEVICE_ID) (
  // System clock
  input  logic                  clk, rst,
  // External JTAG signals
  input  logic                  tck,
  input  logic                  tdi,
  input  logic                  tms,
  output logic                  tdo,

  // DMI signals
  input  logic                  ReqReady,
  output logic                  ReqValid,
  output logic [ADDR_WIDTH-1:0] ReqAddress,
  output logic [31:0]           ReqData,
  output logic [1:0]            ReqOP,
  output logic                  RspReady,
  input  logic                  RspValid,
  input  logic [31:0]           RspData,
  input  logic [1:0]            RspOP
);
  `include "debug.vh"

  enum logic [1:0] {IDLE, START, WAIT, COMPLETE} DMIState;

  // Clock Domain Crossing
  logic                     tcks; // Synchronized JTAG clock
  logic                     resetn; // TODO: reset DM (but not hart)
  logic                     UpdateDtmcs;
  logic [31:0]              DtmcsIn;
  logic [31:0]              DtmcsOut;
  logic                     UpdateDmi;
  logic                     CaptureDmi;
  logic [34+ADDR_WIDTH-1:0] DmiIn;
  logic [34+ADDR_WIDTH-1:0] DmiOut;

  // DTMCS Register
  const logic [2:0]         ErrInfo = 0;
  logic                     DtmHardReset;
  logic                     DmiReset;
  const logic [2:0]         Idle = 0;
  logic [1:0]               DmiStat;
  const logic [5:0]         ABits = ADDR_WIDTH;
  const logic [3:0]         Version = 1; // DTM spec version 1

  logic [31:0]              ValRspData;
  logic [1:0]               ValRspOP;
  logic                     Sticky;

  assign DmiOut = {ReqAddress, ValRspData, ValRspOP};
  assign DmiStat = ValRspOP;

  // Synchronize the edges of tck to the system clock
  synchronizer clksync (.clk(clk), .d(tck), .q(tcks));

  jtag #(.ADDR_WIDTH(ADDR_WIDTH), .DEVICE_ID(JTAG_DEVICE_ID)) jtag (.rst, .tck(tcks), .tdi, .tms, .tdo,
    .resetn, .UpdateDtmcs, .DtmcsIn, .DtmcsOut, .CaptureDmi, .UpdateDmi, .DmiIn, .DmiOut);


  // DTMCS
  assign DtmcsOut = {11'b0, ErrInfo, 3'b0, Idle, DmiStat, ABits, Version};
  always_ff @(posedge clk) begin
    if (rst | ~resetn | DtmHardReset) begin
      DtmHardReset <= 0;
      DmiReset <= 0;
    end else if (UpdateDtmcs) begin
      DtmHardReset <= DtmcsIn[17];
      DmiReset <= DtmcsIn[16];
    end else if (DmiReset) begin
      DmiReset <= 0;
    end
  end

  // DMI
  always_ff @(posedge clk) begin
    if (rst | ~resetn | DtmHardReset) begin
      ValRspData <= 0;
      ValRspOP <= `OP_SUCCESS;
      //ErrInfo <= 4;
      Sticky <= 0;
      DMIState <= IDLE;
    end else if (DmiReset) begin
      ValRspOP <= `OP_SUCCESS;
      //ErrInfo <= 4;
      Sticky <= 0;
    end else
      case (DMIState)
        IDLE : begin
          if (UpdateDmi & ~Sticky & DmiIn[1:0] != `OP_NOP) begin
            {ReqAddress, ReqData, ReqOP} <= DmiIn;
            ReqValid <= 1;
            // DmiOut is captured immediately on CaptureDmi
            // this preemptively sets BUSY for next capture unless overwritten
            ValRspOP <= `OP_BUSY;
            DMIState <= START;
          end else begin
            ReqValid <= 0;
            if (~Sticky)
              ValRspOP <= `OP_SUCCESS;
          end
        end

        START : begin
          if (ReqReady) begin
            ReqValid <= 0;
            RspReady <= 1;
            DMIState <= WAIT;
          end
        end

        WAIT : begin
          if (RspValid) begin
            ValRspData <= RspData;
            if (~Sticky) // update OP if it isn't currently a sticky value
              ValRspOP <= RspOP;
            if (RspOP == `OP_FAILED | RspOP == `OP_BUSY)
              Sticky <= 1;
            //if (RspOP == `OP_FAILED)
            //  ErrInfo <= 3;
            DMIState <= COMPLETE;
          end else if (CaptureDmi)
            Sticky <= 1;
        end

        COMPLETE : begin
          if (CaptureDmi) begin
            RspReady <= 0;
            DMIState <= IDLE;
          end
        end
      endcase
  end

endmodule

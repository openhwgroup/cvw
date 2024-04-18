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

// TODO: recover from reset from either side (DTM or DM)
// trstn at inopportune time likely causes dmi to lock up

// To recovert from a core reset, DTM will need to DtmHardReset (or trstn / tms zeroscan).
//    This is mentioned in spec
// To recover from DTM reset, core will probably need to be reset

module dtm #(parameter ADDR_WIDTH, parameter JTAG_DEVICE_ID) (
  // System clock
  input  logic                  clk,
  // External JTAG signals
  input  logic                  tck, 
  input  logic                  tdi, 
  input  logic                  tms, 
  input  logic                  trstn,
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

  enum {
    READY,
    ACK,
    IDLE
  } DMIState;

  logic [ADDR_WIDTH-1:0] RspAddress;

  logic                     tcks; // Synchronized JTAG clock
  logic                     resetn;
  logic                     CaptureDtmcs;
  logic                     UpdateDtmcs;
  logic [31:0]              DtmcsIn;
  logic [31:0]              DtmcsOut;
  logic                     CaptureDmi;
  logic                     UpdateDmi;
  logic [34+ADDR_WIDTH-1:0] DmiIn;
  logic [34+ADDR_WIDTH-1:0] DmiOut;

  // DTMCS Register
  logic [2:0]                 ErrInfo;
  logic                       DtmHardReset;
  logic                       DmiReset;
  const logic [2:0]           Idle = 0; // TODO: increase this if DM ops incurr some latency (6.1.4)
  logic [1:0]                 DmiStat;
  const logic [5:0]           ABits = ADDR_WIDTH;
  const logic [3:0]           Version = 1; // DTM spec version 1

  assign RspAddress = ReqAddress;
  assign DmiOut = {RspAddress, RspData, RspOP};

  // Synchronize the edges of tck to the system clock
  // TODO use synchronizer in src/generic/flop
  synchronizer clksync (.clk(clk), .d(tck), .q(tcks));

  jtag #(.ADDR_WIDTH(ADDR_WIDTH), .DEVICE_ID(JTAG_DEVICE_ID)) jtag (.tck(tcks), .tdi, .tms, .trstn(trstn), .tdo,
    .resetn, .CaptureDtmcs, .UpdateDtmcs, .DtmcsIn, .DtmcsOut, .CaptureDmi, .UpdateDmi, .DmiIn, .DmiOut);


  // DTMCS
  assign DtmcsOut = {11'b0, ErrInfo, 3'b0, Idle, DmiStat, ABits, Version};
  always_ff @(posedge tcks) begin
    if (~resetn || DtmHardReset) begin
      DtmHardReset <= 0;
      DmiReset <= 0;
    end else if (UpdateDtmcs) begin
      DtmHardReset <= DtmcsIn[17];
      DmiReset <= DtmcsIn[16];
    end else if (DmiReset) begin
      DmiReset <= 0;
    end

    // sticky status logic
    if (~resetn || DtmHardReset || DmiReset) begin
      DmiStat <= 0;
      ErrInfo <= 4;
    end else begin
      if (~(DmiStat == 2 || DmiStat == 3))
        DmiStat <= RspOP;
      if (RspOP == 2)
        ErrInfo <= 3;
    end
  end

  // DMI
  always_ff @(posedge tcks) begin
    if (~resetn || DtmHardReset)
      DMIState <= READY;
    else
      case (DMIState)
        READY : begin
          if (UpdateDmi) begin
            ReqValid <= 1;
            {ReqAddress, ReqData, ReqOP} <= DmiIn;
          end
          if ((UpdateDmi || ReqValid) && ReqReady)
            DMIState <= ACK;
        end

        ACK : begin
          if (~ReqReady) begin
            ReqValid <= 0;
            RspReady <= 1;
            DMIState <= IDLE;
          end
        end

        IDLE : begin
          if (RspValid && (RspOP == `OP_SUCCESS || RspOP == `OP_FAILED)) begin
            RspReady <= 0;
            DMIState <= READY;
          end
        end
      endcase
  end

endmodule

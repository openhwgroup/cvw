///////////////////////////////////////////
// tap_controller.sv
//
// Written: Jacob Pease jacobpease@protonmail.com,
//          James E. Stine james.stine@okstate.edu
// Created: August 1st, 2025
// Modified: 
//
// Purpose: Debug Transport Module
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

//`include "debug.vh"
module dtm import cvw::*; #(parameter cvw_t P) (
  input logic         clk, 
  input logic         reset,
  input logic         tck, 
  input logic         tms, 
  input logic         tdi,
  output logic        tdo,
  // output              dmi_req_t dmi_req,
  // dmi_req.addr
  // dmi_req.data
  // dmi_req.op
  // dmi_req.ready
  // dmi_req.valid

  // dmi_rsp.data
  // dmi_rsp.op
  // dmi_rsp.ready
  // dmi_rsp.valid

  // DMI REQUEST
  output logic [6:0]  DMIADDR,
  output logic [31:0] DMIDATA,
  output logic [1:0]  DMIOP,
  output logic        DMIREADY,
  output logic        DMIVALID,

  // DMI RESPONSE
  input logic [31:0]  DMIRSPDATA,
  input logic [1:0]   DMIRSPOP,
  input logic         DMIRSPREADY,
  input logic         DMIRSPVALID
                            
 // input               dmi_rsp_t dmi_rsp
);
   
  // Tap Controller stuff
  logic 	resetn; 
  logic 	enable;
  logic 	select; 
  logic 	ShiftIR;
  logic 	CaptureIR;
  logic 	ClockIR;
  logic 	UpdateIR;
  logic 	ShiftDR;
  logic 	ClockDR;
  logic 	UpdateDR;

  // Instruction Register
  logic [P.DTM_INSTR_WIDTH-1:0]  currentInst;
   
  // Select outputs
  logic 		   tdo_dr, tdo_ir, tdo_mux, tdo_delayed;
   
  // Edge detecting UpdateDR. Avoids cases where UpdateDR is still
  // high for multiple clock cycles.
  logic        UpdateDRSync;
  logic [1:0]  UpdateDRSamples;
  logic        UpdateDRValid;
   
  // Test Data Register Stuff
  //dtmcs_t dtmcs, dtmcs_next;
  logic [31:0] dtmcs, DTMCSNext;
  // dmi_t dmi_next, dmi_next_reg, dmi;

  logic [P.ABITS + 34 - 1:0] DMINextReg, DMINext, dmi;
  // logic [1:0] DMIStat;
   
  // Debug Module Interface Control
  logic 		   UpdateDMI;
  logic 		   UpdateDTMCS;
  logic 		   DTMHardReset;
  logic 		   DMIReset;   
  logic 		   Sticky;

  typedef enum logic [1:0] {
    NOP = 2'b00,
    RD  = 2'b01,
    WR  = 2'b10
  } DMIOPW;
  
  enum logic {IDLE, BUSY} DMIState;
   
  // Temporarily tying tresetn to resetn. This isn't the way JTAG
  // recommends doing it, but the debug spec and neorv32 seem to
  // imply it's ok to do so.
  tap_controller controller (tck, reset, tms, tdi,
    resetn, enable, select,
    ShiftIR, CaptureIR, ClockIR, UpdateIR,
    ShiftDR, ClockDR, UpdateDR);

  // IR
  inst_reg instructionreg (tck, tdi, resetn,
    ShiftIR, CaptureIR, ClockIR, UpdateIR,
    tdo_ir, currentInst);

  // tdr = Test Data Register
  data_reg tdr (tck, tdi, resetn, currentInst, ShiftDR, ClockDR, UpdateDR,
    DTMCSNext, dtmcs, DMINext, dmi, tdo_dr);
   
  // Choose output of tdo 
  always_comb begin
    case(select)
      1'b0: tdo_mux = tdo_dr;
      1'b1: tdo_mux = tdo_ir;
    endcase
  end

  // FIXME: may be problematic (investigate)
  flop #(1) tdo_ff (~tck, tdo_mux, tdo_delayed);
  assign tdo = enable ? tdo_delayed : 1'bz;
  // The JTAG-side of the DTM runs on TCK, while the Debug Module
  // (DM) and DMI bus live on our system clock, we need a clean
  // clock-domain crossing (CDC) between them.   
  synchronizer updatesync (clk, UpdateDR, UpdateDRSync);
   
  always_ff @(posedge clk) begin
    if (reset) begin
      UpdateDRSamples <= 2'b0;
    end else begin
      if (UpdateDRSync) UpdateDRSamples[0] <= 1;
      else UpdateDRSamples[0] <= 0;
      UpdateDRSamples[1] <= UpdateDRSamples[0];
    end
  end

  assign UpdateDRValid = (UpdateDRSamples == 2'b01);    
  assign UpdateDTMCS = UpdateDRValid & (currentInst[4:0] == 5'b10000);
  assign UpdateDMI = UpdateDRValid & (currentInst[4:0] == 5'b10001);

  // DTMCS
  always_ff @(posedge clk) begin
    if (reset | ~resetn | DTMHardReset) begin
      DTMHardReset <= 0;
      DMIReset <= 0;
    end else if (UpdateDTMCS) begin
      // DMIReset <= dtmcs.dmireset;
      // DTMHardReset <= dtmcs.dtmhardreset;
      DMIReset <= dtmcs[17];
      DTMHardReset <= dtmcs[16];
    end else if (DMIReset) begin
      DMIReset <= 0;
    end
  end 
   
  //assign dtmcs_next = {11'b0, 3'd4, 4'b0, dmi_next.op, `ABITS, 4'b1};
  // assign dtmcs_next.reserved0 = 11'b0;
  // assign dtmcs_next.errinfo = 3'd4;
  // assign dtmcs_next.dtmhardreset = DTMHardReset;
  // assign dtmcs_next.dmireset = DMIReset;
  // assign dtmcs_next.reserved1 = 1'b0;
  // assign dtmcs_next.idle = 3'd0;
  // assign dtmcs_next.dmistat = dmi_next.op;
  // assign dtmcs_next.abits = P.ABITS;
  // assign dtmcs_next.version = 4'b1;
  
  assign DTMCSNext = {11'b0, 3'd4, DTMHardReset, DMIReset, 1'b0, 3'd0, DMINextReg[1:0], P.ABITS, 4'b1};
   
  // Sticky error
  always_ff @(posedge clk) begin
    if (reset | ~resetn | DMIReset == 1 | DTMHardReset == 1) begin
      Sticky <= 0;
    end else if ((DMIState == BUSY) & (UpdateDMI)) begin
      Sticky <= 1;
    end
  end
  
  // DMI
  always_ff @(posedge clk) begin
    if (reset | ~resetn | DTMHardReset) begin
      //dmi_next_reg.op <= NOP;
      DMINextReg[1:0] <= NOP;
      // dmi_req.ready <= 1'b1;
      DMIREADY <= 1'b1;
      DMIVALID <= 1'b0;
      //dmi_req.valid <= 1'b0;
      DMIState <= IDLE;
    end else begin
      case(DMIState)
        IDLE: begin
          if (UpdateDMI) begin
            //dmi_req.addr <= dmi.addr;
            //dmi_req.data <= dmi.data;
            DMIADDR <= dmi[P.ABITS+34-1:34];
            DMIDATA <= dmi[33:2];
            if ((dmi[1:0] == RD) | (dmi[1:0] == WR)) begin
              //dmi_req.op <= dmi.op;
              //dmi_req.valid <= 1'b1;
              DMIOP <= dmi[1:0];
              DMIVALID <= 1'b1;
              DMIState <= BUSY;
            end
          end else begin
            DMIState <= IDLE;
          end
        end           
        BUSY: begin
          if (DMIRSPVALID) begin
            //dmi_req.op <= NOP;
            //dmi_req.valid <= 1'b0;
            //dmi_next_reg.data <= dmi_rsp.data;
            //dmi_next_reg.op <= dmi_rsp.op;
            DMIOP <= NOP;
            DMIVALID <= 1'b0;
            DMINextReg[33:2] <= DMIRSPDATA;
            DMINextReg[1:0] <= DMIRSPOP;
            DMIState <= IDLE;
          end else begin
            DMIState <= BUSY;
          end
        end           
        default: DMIState <= IDLE;
      endcase
    end
  end 
   
  // assign dmi_next.addr = dmi_req.addr;
  // assign dmi_next.data = dmi_next_reg.data;
  // assign dmi_next.op = Sticky ? 2'b11 : dmi_next_reg.op;

  assign DMINext = {DMIADDR, DMINextReg[33:2], Sticky ? 2'b11 : DMINextReg[1:0]};
  
   
endmodule

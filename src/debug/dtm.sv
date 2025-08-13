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

`include "debug.vh"
module dtm (
   input logic  clk, 
   input logic 	rst,
   // JTAG Interface
   input logic 	tck, 
   input logic 	tms, 
   input logic 	tdi,
   output logic tdo,
   // debug module interface (DMI)
   // Signals go here. neorv32 defines two packed structs.
   output 	dmi_t dmi_req,
   input 	dmi_rsp_t dmi_rsp);
   
    // Tap Controller stuff
   logic 	resetn; 
   logic 	enable;
   logic 	select; 
   logic 	ShiftIR;
   logic 	ClockIR;
   logic 	UpdateIR;
   logic 	ShiftDR;
   logic 	ClockDR;
   logic 	UpdateDR;

   // Instruction Register
   logic [`INSTWIDTH-1:0] currentInst;
   
   // Select outputs
   logic 		  tdo_dr, tdo_ir, tdo_mux, tdo_delayed;
   
   // Synchronizer signals
   logic 		  tck_sync, tms_sync, tdi_sync;
   
   // Synchronizing tck, tms, and tdi
   synchronizer tck_synchronizer (clk, tck, tck_sync);
   synchronizer tms_synchronizer (clk, tms, tms_sync);
   synchronizer tdi_synchronizer (clk, tdi, tdi_sync);
   
   // Edge detecting UpdateDR. Avoids cases where UpdateDR is still
   // high for multiple clock cycles.
   logic [1:0] 		  UpdateDRSamples;
   logic 		  UpdateDRValid;
   
   // Test Data Register Stuff
   dtmcs_t dtmcs, dtmcs_next;
   dmi_t dmi_next, dmi_next_reg, dmi;
   // logic [1:0] DMIStat;
   
   // Debug Module Interface Control
   logic 		  UpdateDMI;
   logic 		  UpdateDTMCS;
   logic 		  DTMHardReset;
   logic 		  DMIReset;
   
   logic 		  Sticky;
   
   enum 		  logic {IDLE, BUSY} DMIState;
   
   // Temporarily tying trstn to rstn. This isn't the way JTAG
   // recommends doing it, but the debug spec and neorv32 seem to
   // imply it's ok to do so.

   // think maybe we should not do it this way despite debug spec (jes)
   
   tap_controller controller (tck_sync, rst, tms_sync, tdi_sync,
			      resetn, enable, select,
			      ShiftIR, ClockIR, UpdateIR,
			      ShiftDR, ClockDR, UpdateDR);
   
    inst_reg instructionreg (tdi_sync, resetn,
			     ShiftIR, ClockIR, UpdateIR,
			     tdo_ir, currentInst);

    // tdr = Test Data Register
    data_reg tdr (tck_sync, tdi_sync, resetn,
		  currentInst,
		  ShiftDR, ClockDR, UpdateDR,
		  dtmcs_next, dtmcs,
		  dmi_next, dmi, tdo_dr);

   // Choose output of tdo 
   always_comb begin
      case(select)
        1'b0: tdo_mux = tdo_dr;
        1'b1: tdo_mux = tdo_ir;
      endcase
   end

    flop #(1) tdo_ff (~tck_sync, tdo_mux, tdo_delayed);
    assign tdo = enable ? tdo_delayed : 1'bz;

    always_ff @(posedge clk) begin
        if (rst) begin
            UpdateDRSamples <= 2'b0;
        end else begin
            if (UpdateDR) UpdateDRSamples[0] <= 1;
            else UpdateDRSamples[0] <= 0;
            UpdateDRSamples[1] <= UpdateDRSamples[0];
        end
    end

    assign UpdateDRValid = (UpdateDRSamples == 2'b01);
    
    assign UpdateDTMCS = UpdateDRValid & (currentInst == DTMCS);
    assign UpdateDMI = UpdateDRValid & (currentInst == DMIREG);
    

    // DTMCS
    always_ff @(posedge clk) begin
        if (rst | ~resetn | DTMHardReset) begin
            DTMHardReset <= 0;
            DMIReset <= 0;
        end else if (UpdateDTMCS) begin
            DMIReset <= dtmcs.dmireset;
            DTMHardReset <= dtmcs.dtmhardreset;
        end else if (DMIReset) begin
            DMIReset <= 0;
        end
    end // always_ff @ (posedge clk)

    //assign dtmcs_next = {11'b0, 3'd4, 4'b0, dmi_next.op, `ABITS, 4'b1};
    assign dtmcs_next.reserved0 = 11'b0;
    assign dtmcs_next.errinfo = 3'd4;
    assign dtmcs_next.dtmhardreset = DTMHardReset;
    assign dtmcs_next.dmireset = DMIReset;
    assign dtmcs_next.reserved1 = 1'b0;
    assign dtmcs_next.idle = 3'd0;
    assign dtmcs_next.dmistat = dmi_next.op;
    assign dtmcs_next.abits = `ABITS;
    assign dtmcs_next.version = 4'b1;
    
    // Sticky error
    always_ff @(posedge clk) begin
        if (rst | ~resetn | DMIReset == 1 | DTMHardReset == 1) begin
            Sticky <= 0;
        end else if ((DMIState == BUSY) & (UpdateDMI)) begin
            Sticky <= 1;
        end
    end

    // DMI
    always_ff @(posedge clk) begin
        if (rst | ~resetn | DTMHardReset) begin
            dmi_next_reg.op <= NOP;
            DMIState <= IDLE;
        end else begin
            case(DMIState)
                IDLE: begin
                    if (UpdateDMI) begin
                        dmi_req.addr <= dmi.addr;
                        dmi_req.data <= dmi.data;
                        if ((dmi.op == RD) | (dmi.op == WR)) begin
                            dmi_req.op <= dmi.op;
                            DMIState <= BUSY;
                        end
                    end
                end
              
                BUSY: begin
                    if (dmi_rsp.ack) begin
                        dmi_req.op <= NOP;
                        dmi_next_reg.data <= dmi_rsp.data;
                        dmi_next_reg.op <= dmi_rsp.op;
                        DMIState <= IDLE;
                    end
                end
              
                default: DMIState <= IDLE;
            endcase
        end
    end // always_ff @ (posedge clk)

    assign dmi_next.addr = dmi_req.addr;
    assign dmi_next.data = dmi_next_reg.data;
    assign dmi_next.op = Sticky ? 2'b11 : dmi_next_reg.op;
    
endmodule

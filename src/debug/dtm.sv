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
module dtm(
    input logic clk, rst,
    // JTAG Interface
    input logic  tck, tms, tdi,
    output logic tdo,
    // debug module interface (DMI)
    // Signals go here. neorv32 defines two packed structs.
    output dmi_t dmi
);
    logic resetn, enable, select; 
    logic ShiftIR, ClockIR, UpdateIR;
    logic ShiftDR, ClockDR, UpdateDR;
    logic [`INSTWIDTH-1:0] currentInst;

    // Select outputs
    logic tdo_dr, tdo_ir, tdo_mux;

    // Synchronizer signals
    logic tck_sync, tms_sync, tdi_sync;
    
    // Synchronizing tck, tms, and tdi
    synchronizer tck_synchronizer (clk, tck, tck_sync);
    synchronizer tms_synchronizer (clk, tms, tms_sync);
    synchronizer tdi_synchronizer (clk, tdi, tdi_sync);
    
    // Temporarily tying trstn to rstn. This isn't the way JTAG
    // recommends doing it, but the debug spec and neorv32 seem to
    // imply it's ok to do so.
    tap_controller controller(
        tck_sync, rst, tms_sync, tdi_sync, tdo,
        resetn, enable, select,
        ShiftIR, ClockIR, UpdateIR,
        ShiftDR, ClockDR, UpdateDR
    );

    inst_reg instructionreg (
        tdi_sync, resetn,
        ClockIR, UpdateIR, ShiftIR,
        tdo_ir,
        currentInst
    );

    // tdr = Test Data Register
    data_reg tdr (
        tck_sync, tdi_sync, resetn,
        currentInst,
        ClockDR, UpdateDR, ShiftDR,
        tdo_dr
    );

    // Choose output of tdo 
    always_comb begin
        case(select)
            1'b0: tdo_mux = tdo_ir;
            1'b1: tdo_mux = tdo_dr;
        endcase
    end

    // Dr. Harris suggests the output is flopped.
    // Otto's original implementation is combinational.
    // NeoRV32 is flopped.
    flop #(1) tdo_ff (~tck_sync, tdo_mux, tdo);

    // Instruction Block
    // - Instruction Register
    // - Instruction Decoder?

    
    
    // Test Data Registers
    // - Boundary Scan Register
    //   * According to the DM spec, this doesn't exist here. Can
    //     confirm with the neorv32 implementation.
    // - IDCODE Register
    // - DTM Control and Status
    // - Debug Module Interface Access? (Is this supposed to be shifted?)
    // - Bypass Register
    // - TDO driver? (Dr. Harris includes this here)

    // DMI (Debug Module Interface) - Extra logic must be included for
    // this, whether it exists in the Test Data Registers block or
    // right here outside of it.
    
    // I'd prefer to have the TDO driver here since it muxes between
    // the Instruction register output and the Test Data Register
    // output. a.k.a. Separation of concerns.
endmodule

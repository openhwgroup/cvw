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
    input logic clk, rstn,
    // JTAG Interface
    input logic  tck, tms, tdi,
    output logic tdo,
    // debug module interface (DMI)
    // Signals go here. neorv32 defines two packed structs.
    output dmi_t dmi
);
    logic reset, enable, select; 
    logic ShiftIR, ClockIR, UpdateIR;
    logic ShiftDR, ClockDR, UpdateDR;

    // Temporarily tying trstn to rstn. This isn't the way JTAG
    // recommends doing it, but the debug spec and neorv32 seem to
    // imply it's ok to do so.
    tap_controller controller(
        tck, rstn, tms, tdi, tdo,
        reset, enable, select,
        ShiftIR, ClockIR, UpdateIR,
        ShiftDR, ClockDR, UpdateDR
    );

    // Instruction Block
    // - Instruction Register
    // - Instruction Decoder

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

///////////////////////////////////////////
// data_reg.sv
//
// Written: Jacob Pease jacobpease@protonmail.com,
//          James E. Stine james.stine@okstate.edu
// Created: August 4th, 2025
// Modified: 
//
// Purpose: Test Data Registers in the Debug Transport Module.
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

module data_reg #(parameter INSTWIDTH = 5) (
    input logic                 tck, tdi, resetn,
    input logic [INSTWIDTH-1:0] currentInst, 
    input logic                 ShiftDR, ClockDR, UpdateDR,
    input dtmcs_t               dtmcs_next,
    output dtmcs_t              dtmcs,
    input dmi_t                 dmi_next,
    output dmi_t                dmi,                                        
    output logic                tdo
);
    logic tdo_idcode;
    logic tdo_dtmcs;
    logic tdo_dmi;
    logic tdo_bypass;

    // ID Code
    idreg #(32) idcode(
        tck, tdi, resetn,
        32'h1002AC05,
        ShiftDR, ClockDR,
        tdo_idcode
    );

    // DTMCS
    internalreg #(32) dtmcsreg(
        tck, tdi, resetn,
        dtmcs_next,
        `DTMCS_RESET,
        ShiftDR, ClockDR,
        dtmcs,
        tdo_dtmcs
    );

    // DMI
    internalreg #(`DMI_WIDTH) dmireg(
        tck, tdi, resetn,
        dmi_next,
        {(34 + `ABITS){1'b0}},
        ShiftDR, ClockDR,
        dmi,
        tdo_dmi
    );
    
    // BYPASS
    always_ff @(posedge tck, negedge resetn) begin
        if (~resetn) tdo_bypass <= 0;
        else if (currentInst == BYPASS) tdo_bypass <= tdi;
    end

    // Mux data register output based on current instruction
    always_comb begin
        case (currentInst)
            IDCODE : tdo = tdo_idcode;
            DTMCS  : tdo = tdo_dtmcs;
            DMIREG    : tdo = tdo_dmi;
            BYPASS : tdo = tdo_bypass;
            default        : tdo = tdo_bypass; // Bypass instruction 11111 and 00000
        endcase
    end

endmodule

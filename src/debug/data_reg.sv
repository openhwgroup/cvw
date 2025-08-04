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
    input logic                 ClockDR, UpdateDR, ShiftDR,
    output logic                tdo
);
    logic tdo_idcode;

    dtmcs_t dtmcs;
    logic tdo_dtmcs;

    logic tdo_dmi;
    
    logic tdo_bypass;

    ID Code
    idreg #(32) idcode(
        tck, tdi, resetn,
        32'h1002AC05,
        ShiftDR, ClockDR,
        tdo_idcode
    );

    // always @(posedge ClockDR, negedge resetn) begin
    //     if (~resetn) begin
    //         dtmcs.reserved0 <= '0;
    //         dtmcs.errinfo <= 4;
    //         dtmcs.dtmhardreset <= 0;
    //         dtmcs.dtmreset <= 0;
    //         dtmcs.reserved1 <= 1;
    //         dtmcs.idle <= 0;
    //         dtmcs.dmistat <= 0;
    //         dtmcs.abits <= `ABITS;
    //         dmtcs.version <= 1;
    //     end else begin // if (~resetn)
            
    //     end
    // end
    

    // DTMCS
    internalreg #(32) dtmcs(
        tck, tdi, resetn,
        
    );

    // DMI
    internalreg #(`DMIWIDTH) dmireg(
        tck, tdi, resetn,
        
    );
    
    // BYPASS
    always @(posedge tck, negedge resetn) begin
        if (~resetn) tdo_bypass <= 0;
        else if (currentInst == DTMINST.BYPASS) tdo_bypass <= tdi;
    end

    // Mux data register output based on current instruction
    always_comb begin
        case (currentInst)
            DTMINST.IDCODE : tdo = tdo_idcode;
            DTMINST.DTMCS  : tdo = tdo_dtmcs;
            DTMINST.DMI    : tdo = tdo_dmi;
            DTMINST.BYPASS : tdo = tdo_bypass;
            default        : tdo = tdo_bypass; // Bypass instruction 11111 and 00000
        endcase
    end

endmodule

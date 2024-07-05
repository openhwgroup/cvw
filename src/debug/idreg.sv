///////////////////////////////////////////
// idreg.sv
//
// Written: matthew.n.otto@okstate.edu, james.stine@okstate.edu
// Created: 15 March 2024
//
// Purpose: JTAG device identification register
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

module idreg #(parameter DEVICE_ID) (
    input  logic tdi,
    input  logic clockDR,
    input  logic captureDR,
    output logic tdo
);

    logic [32:0] ShiftReg;
    assign ShiftReg[32] = tdi;
    assign tdo = ShiftReg[0];

    genvar i;
    for (i = 0; i < 32; i = i + 1) begin
        if (i == 0)
            flop #(1) idregi (.clk(clockDR), .d(captureDR ? 1'b1 : ShiftReg[i+1]), .q(ShiftReg[i]));
        else
            flop #(1) idregi (.clk(clockDR), .d(captureDR ? DEVICE_ID[i] : ShiftReg[i+1]), .q(ShiftReg[i]));
    end
endmodule

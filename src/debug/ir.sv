///////////////////////////////////////////
// ir.sv
//
// Written: matthew.n.otto@okstate.edu, james.stine@okstate.edu
// Created: 15 March 2024
//
// Purpose: JTAG instruction register
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

module ir (
  input  logic clockIR,
  input  logic tdi,
  input  logic resetn, 
  input  logic captureIR,
  input  logic updateIR,
  output logic tdo,
  output logic BypassInstr,
  output logic IDCodeInstr,
  output logic DtmcsIntrs,
  output logic DmiInstr
);

  localparam INST_REG_WIDTH = 5;

  logic [INST_REG_WIDTH:0] shift_reg;
  logic [3:0]              decoded;


  assign shift_reg[INST_REG_WIDTH] = tdi;
  assign tdo = shift_reg[0];

  // Shift register
  always @(posedge clockIR) begin
    shift_reg[0] <= shift_reg[1] || captureIR;
  end
  genvar i;
  for (i = INST_REG_WIDTH; i > 1; i = i - 1) begin
    always @(posedge clockIR) begin
      shift_reg[i-1] <= shift_reg[i] && ~captureIR;
    end
  end

  // Instruction decoder
  // 6.1.2
  always_comb begin
    unique case (shift_reg[INST_REG_WIDTH-1:0])
      5'h00   : decoded <= 4'b1000; // bypass
      5'h01   : decoded <= 4'b0100; // idcode
      5'h10   : decoded <= 4'b0010; // dtmcs
      5'h11   : decoded <= 4'b0001; // dmi
      5'h1F   : decoded <= 4'b1000; // bypass
      default : decoded <= 4'b1000; // bypass
    endcase
  end

  // Flop decoded instruction to minimizes switching during shiftIR
  always @(posedge updateIR or negedge resetn) begin
    if (~resetn)
      {BypassInstr, IDCodeInstr, DtmcsIntrs, DmiInstr} <= 4'b0100;
    else if (updateIR)
      {BypassInstr, IDCodeInstr, DtmcsIntrs, DmiInstr} <= decoded;
  end
endmodule

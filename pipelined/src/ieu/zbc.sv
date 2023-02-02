///////////////////////////////////////////
// zbc.sv
//
// Written: Kevin Kim <kekim@hmc.edu> and Kip Macsai-Goren <kmacsaigoren@hmc.edu>
// Created: 2 February 2023
// Modified: 
//
// Purpose: RISC-V single bit manipulation unit (ZBC instructions)
//
// Documentation: RISC-V System on Chip Design Chapter ***
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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

`include "wally-config.vh"

module zbs #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,       // Operands
  //input  logic [2:0]       ALUControl, // With Funct3, indicates operation to perform
  input  logic [6:0]       Funct7,
  input  logic [2:0]       Funct3,     // With ***Control, indicates operation to perform
  output logic [WIDTH-1:0] ZBCResult);     // ZBC result



endmodule
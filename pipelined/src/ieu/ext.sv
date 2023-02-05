
///////////////////////////////////////////
// cnt.sv
//
// Written: Kevin Kim <kekim@hmc.edu>
// Created: 4 February 2023
// Modified: 
//
// Purpose: Sign/Zero Extension Submodule
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

module ext #(parameter WIDTH = 32) (
  input  logic [WIDTH-1:0] A,            // Operand
  output logic [WIDTH-1:0] sexthResult,  // sign extend halfword result
  output logic [WIDTH-1:0] sextbResult,  // sign extend byte result
  output logic [WIDTH-1:0] zexthResult); // zero extend halfword result 

  assign sexthResult = {{(WIDTH-16){A[15]}},A[15:0]};
  assign zexthResult = {{(WIDTH-16){1'b0}},A[15:0]};
  assign sextbResult = {{(WIDTH-8){A[7]}},A[7:0]};
 
endmodule
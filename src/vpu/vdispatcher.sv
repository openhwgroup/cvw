///////////////////////////////////////////
// vdispatcher.sv
//
// Written: Rose Thompson rose.thompson@skyworksinc.com
// Created: 1 September 2026
// Modified: 1 September 2026
//
// Purpose: vector dispatcher module
//
// Documentation: RISC-V System on Chip Design Volume 2
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-26 Harvey Mudd College & Oklahoma State University & Skyworks Solutions Inc.
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

module vdispatcher import cvw::*;  #(parameter cvw_t P) (
  input  logic        clk, reset,
  // Decode stage control signals
  input  logic        StallD, FlushD,          // Stall, flush Decode stage
  input  logic [31:0] InstrD,                  // Instruction in Decode stage
  input  logic        VectorD,                 // This instruction is a vector
  // hand shaking controls
  output logic [VPU_MAX_EU-1:0] ControllerValidD,
  input  logic [VPU_MAX_EU-1:0] ExecutionUnitReadyD,
  // output micro vector instruction
  output logic [31:0] MicroInstrD,             // lmul sequenced micro-op instruction in Decode stage
  output logic MicroVectorD
);

  logic        IncrMicroOpD;            // Next micro vector instruction when lmul > 1


endmodule

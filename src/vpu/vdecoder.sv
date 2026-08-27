///////////////////////////////////////////
// vdecoder.sv
//
// Written: Rose Thompson rose.thompson@skyworksinc.com
// Created: 26 August 2026
// Modified: 26 August 2026
//
// Purpose: vector decoder module
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

module vdecoder import cvw::*;  #(parameter cvw_t P) (
  input  logic        clk, reset,
  // Decode stage control signals
  input  logic        StallD, FlushD,          // Stall, flush Decode stage
  input  logic [31:0] InstrD,                  // Instruction in Decode stage
  input  logic  VectorD,                       // This instruction is a vector

  // Decode stage outputs
  output logic [4:0] Vs1D, Vs2D,               // Vector Source 1 and 2
  output logic [4:0] VdD,                      // Vector Destination read (overwrite)
  output logic VMD,                            // 0 = mask enabled, 1 mask disabled
  output logic [5:0] Funct6D,
  output logic [2:0] Funct3D,
  // VLSU control
  output logic [2:0] NfD,                      // segment load/store, number of fields in each segment
  output logic MewD,                           // extended memory element width
  output logic [1:0] MopD,                     // memory addressing mode
  output logic [4:0] lumop,                    // unit-stride load control
  output logic [4:0] sumop                     // unit-stride store control
);




endmodule

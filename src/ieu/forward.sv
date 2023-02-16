///////////////////////////////////////////
// forward.sv
//
// Written: David_Harris@hmc.edu, Sarah.Harris@unlv.edu
// Created: 9 January 2021
// Modified: 
//
// Purpose: Determine datapath forwarding
// 
// Documentation: RISC-V System on Chip Design Chapter 4 (Section 4.2.2.3)
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

module forward(
  // Detect hazards
  input  logic [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW, // Source and destination registers
  input  logic        MemReadE, MDUE, CSRReadE,              // Execute stage instruction is a load (MemReadE), divide (MDUE), or CSR read (CSRReadE)
  input  logic        RegWriteM, RegWriteW,                  // Instruction in Memory or Writeback stage writes register file
  input  logic	      FCvtIntE,                              // FPU convert float to int
  input  logic        SCE,                                   // Store Conditional instruction
  // Forwarding controls
  output logic [1:0]  ForwardAE, ForwardBE,                  // Select signals for forwarding multiplexers
  output logic        FCvtIntStallD, LoadStallD, MDUStallD, CSRRdStallD // Stall due to conversion, load, multiply/divide, CSR read
);

  logic MatchDE;                                             // Match between a source register in Decode stage and destination register in Execute stage
  
  always_comb begin
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;
    if (Rs1E != 5'b0)
      if      ((Rs1E == RdM) & RegWriteM) ForwardAE = 2'b10;
      else if ((Rs1E == RdW) & RegWriteW) ForwardAE = 2'b01;
 
    if (Rs2E != 5'b0)
      if      ((Rs2E == RdM) & RegWriteM) ForwardBE = 2'b10;
      else if ((Rs2E == RdW) & RegWriteW) ForwardBE = 2'b01;
  end

  // Stall on dependent operations that finish in Mem Stage and can't bypass in time
  assign MatchDE = ((Rs1D == RdE) | (Rs2D == RdE)) & (RdE != 5'b0); // Decode-stage instruction source depends on result from execute stage instruction
  assign FCvtIntStallD = FCvtIntE & MatchDE; // FPU to Integer transfers have single-cycle latency except fcvt
  assign LoadStallD = (MemReadE|SCE) & MatchDE;  
  assign MDUStallD = MDUE & MatchDE; // Int mult/div is at least two cycle latency, even when coming from the FDIV
  assign CSRRdStallD = CSRReadE & MatchDE;
endmodule

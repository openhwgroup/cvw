///////////////////////////////////////////
// vpu.sv
//
// Written: Rose Thompson rose.thompson@skyworksinc.com
// Modified: 8/24/2026
//
// Purpose: Vector Processing Unit
//
// Documentation: RISC-V System on Chip Design Vol. 2
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-26 Harvey Mudd College & Oklahoma State University & Skyworks Solutions Inc
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

module vpu import cvw::*;  #(parameter cvw_t P) (
  input  logic                 clk,
  input  logic                 reset,
  // Hazards
  input  logic                 StallD, StallE, StallM, StallW,      // stall signals (from HZU)
  input  logic                 FlushD, FlushE, FlushM, FlushW,      // flush signals (from HZU)
  output logic                 VPUFrontEndBusyD,                    // Stall the decode stage (To HZU)


  // TODO ***
  // Add CSRs between priv and VPU

  // Decode stage
  input  logic [31:0]          InstrD,                             // instruction (from IFU)
  input  logic VectorD,                                            // This instruction is a vector
  // Execute state
  input  logic [P.XLEN-1:0]    ForwardedSrcAE, ForwardedSrcBE,     // Integer/FP input for convert, move (from IEU)
  // Memory stage
  // TODO *** Cannot use decoded control from IEU because the there are overlapping vector instructions?
  output logic [P.VPU_LSU_BLEN-1:0]    VWriteDataM [P.VPU_LSU_EU-1:0],          // Data to be written to memory (to LSU)
  output logic                 IllegalVPUInstrD,                   // Is the instruction an illegal fpu instruction (to IFU)
  // Writeback stage
  input  logic [P.VPU_LSU_BLEN-1:0]    VReadDataW [P.VPU_LSU_EU-1:0], // Read data (from LSU)
  output logic [P.XLEN-1:0] VResultIntFPW                            // Int or FP result for X or F regs.
);

  // divide into control and data path

  // decoder inputs
  // InstrD and VectorD
  // outputs the controls and a valid for this specific vector instruction

  // some of the comments shall move to the hazard unit when implemented.
  // the controller directs this vector instruction to a vector Execution Unit (EU) and reads the VRF.
  // If all the EUs are currently operating on an instruction and cannot take a new instruction, then
  // the controller waits by asserting VPUFrontEndBusyD.
  // VPUFrontEndBusyD is used by the hazard unit to stall the front end.
  // When transitioning from scalar to vector instructions, if the scalar takes a long time such as div or load miss,
  // the VPU must be delayed to ensure inorder commit.  StallE, StallM, and StallW need to post pone the progress of
  // vector instruction progress under this condiction.

  assign VResultIntFPW = '0;
  assign IllegalVPUInstrD = '0;
  genvar i;
  for(i = 0; i < P.VPU_LSU_LANES; i++) begin
      assign VWriteDataM[i] = '0;
  end
  assign VPUFrontEndBusyD = '0;




endmodule; // vpu

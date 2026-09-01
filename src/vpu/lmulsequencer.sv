///////////////////////////////////////////
// lmulsequencer.sv
//
// Written: Rose Thompson rose.thompson@skyworksinc.com
// Created: 1 September 2026
// Modified: 1 September 2026
//
// Purpose: sequence multiple micro-op vector instructions based on lmul
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

module lmulsequencer import cvw::*;  #(parameter cvw_t P) (
  input  logic        clk, reset,
  // Decode stage control signals
  input  logic        StallD, FlushD,          // Stall, flush Decode stage
  input  logic [31:0] InstrD,                  // Instruction in Decode stage
  input  logic        VectorD,                 // This instruction is a vector
  input  logic [4:0]  Vs1D, Vs2D, VdD,
  input  logic [6:0]  lmulDecodedD,
  // hand shaking controls
  input  logic        AnyExecutionUnitReadyD,
  // output micro vector instruction
  output logic [4:0]  Vs1FinalD, Vs2FinalD, VdFinalDm
);

  logic        IncrMicroOpD;            // Next micro vector instruction when lmul > 1

  logic        IncrD;
  logic [4:0]  Vs1P1D, Vs2P1D, VdP1D;
  logic [4:0]  Vs1P1QD, Vs2P1QD, VdQD;
  logic [4:0]  Vs1FinalD, Vs2FinalD, VdFinalD;
  logic [3:0]  lmulCntrD;
  logic        lmulCntrDone, lmulCntrLoad;
  logic        lmulCntrFirstCaptureD;
  logic [3:0]  lmulIntD;

  typedef enum logic {STATE_BEGIN, STATE_INCR} statetype;
  statetype CurrState, NextState;

  assign lmulIntD = lmulDecodedD[6:3];
  assign lmulCntrFirstCaptureD = lmulCntrD > 1;

  flopenr #(5) Vs1IncrReg (clk, reset, IncrD, Vs1P1D, Vs1QD);
  mux2 #(5) Vs1Mux (Vs1FinalD, lmulCntrFirstCaptureD, Vs1D, Vs1QD);
  flopenr #(5) Vs2IncrReg (clk, reset, IncrD, Vs2P1D, Vs2QD);
  mux2 #(5) Vs2Mux (Vs2FinalD, lmulCntrFirstCaptureD, Vs2D, Vs2QD);
  flopenr #(5) VdIncrReg  (clk, reset, IncrD, VdP1D,  VdQD);
  mux2 #(5) VdMux (VdFinalD, lmulCntrFirstCaptureD,   VdD, VdQD);


  flopenl #(4) counter (clk, lmulCntrLoad, IncrD, lmulCntrP1, 4'b0001, lmulCntrD);
  assign lmulCntrDone = lmulCntrD == lmulDecodedD;

  always_ff @(posedge clk)
    if(reset | FlushD) CurrState <= STATE_BEGIN;
    else CurrState <= NextState;

  assign IncrD = AnyExecutionUnitReadyD & VectorD;

  always_comb begin
    NextStaten = STATE_BEGIN;
    case(CurrState)
      STATE_BEGIN: if(VectorD & (lmulIntD > 4'd1) & IncrD) NextState = STATE_INCR;
      STATE_INCR:  if(lmulCntrD == lmulIntD) NextState = STATE_BEGIN;
      else NextState = STATE_INCR;
      default: NextState = STATE_BEGIN;
    endcase
  end

endmodule

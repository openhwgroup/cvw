///////////////////////////////////////////
// fdivsqrtfsm.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: divsqrt state machine for multi-cycle operations
// 
// Documentation: RISC-V System on Chip Design Chapter 13
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

module fdivsqrtfsm import cvw::*;  #(parameter cvw_t P) (
  input  logic clk, 
  input  logic reset, 
  input  logic [P.FMTBITS-1:0] FmtE,
  input  logic XInfE, YInfE, 
  input  logic XZeroE, YZeroE, 
  input  logic XNaNE, YNaNE, 
  input  logic FDivStartE, IDivStartE,
  input  logic XsE,
  input  logic SqrtE,
  input  logic StallM,
  input  logic FlushE,
  input  logic WZeroE,
  input  logic IntDivE,
  input  logic [P.DIVBLEN:0] nE,
  input  logic ISpecialCaseE,
  output logic IFDivStartE,
  output logic FDivBusyE, FDivDoneE,
  output logic SpecialCaseM
);
  
  typedef enum logic [1:0] {IDLE, BUSY, DONE} statetype;
  statetype state;

  logic [P.DURLEN-1:0] step;
  logic [P.DURLEN-1:0] cycles;
  logic SpecialCaseE, FSpecialCaseE;

  // FDivStartE and IDivStartE come from fctrl, reflecitng the start of floating-point and possibly integer division
  assign IFDivStartE = (FDivStartE | (IDivStartE & P.IDIV_ON_FPU)) & (state == IDLE) & ~StallM;
  assign FDivDoneE = (state == DONE);
  assign FDivBusyE = (state == BUSY) | IFDivStartE; 
 
  // terminate immediately on special cases
  assign FSpecialCaseE = XZeroE | | XInfE  | XNaNE |  (XsE&SqrtE) | (YZeroE | YInfE | YNaNE)&~SqrtE;
  if (P.IDIV_ON_FPU) assign SpecialCaseE = IntDivE ? ISpecialCaseE : FSpecialCaseE;
  else              assign SpecialCaseE = FSpecialCaseE;
  flopenr #(1) SpecialCaseReg(clk, reset, IFDivStartE, SpecialCaseE, SpecialCaseM); // save SpecialCase for checking in fdivsqrtpostproc

// DIVN = P.NF+3
// NS = NF + 1
// N = NS or NS+2 for div/sqrt.  

/* verilator lint_off WIDTH */
  logic [P.DURLEN+1:0] Nf, fbits; // number of fractional bits
  if (P.FPSIZES == 1)
    assign Nf = P.NF;
  else if (P.FPSIZES == 2)
    always_comb
      case (FmtE)
        1'b0: Nf = P.NF1;
        1'b1: Nf = P.NF;
      endcase
  else if (P.FPSIZES == 3)
    always_comb
      case (FmtE)
        P.FMT: Nf = P.NF;
        P.FMT1: Nf = P.NF1;
        P.FMT2: Nf = P.NF2; 
      endcase
  else if (P.FPSIZES == 4)  
    always_comb
      case(FmtE)
        P.S_FMT: Nf = P.S_NF;
        P.D_FMT: Nf = P.D_NF;
        P.H_FMT: Nf = P.H_NF;
        P.Q_FMT: Nf = P.Q_NF;
      endcase 


  always_comb begin 
    if (SqrtE) fbits = Nf + 2 + 2; // Nf + two fractional bits for round/guard + 2 for right shift by up to 2
    else       fbits = Nf + 2 + P.LOGR; // Nf + two fractional bits for round/guard + integer bits - try this when placing results in msbs
    if (P.IDIV_ON_FPU) cycles =  IntDivE ? ((nE + 1)/P.DIVCOPIES) : (fbits + (P.LOGR*P.DIVCOPIES)-1)/(P.LOGR*P.DIVCOPIES);
    else              cycles = (fbits + (P.LOGR*P.DIVCOPIES)-1)/(P.LOGR*P.DIVCOPIES);
  end 

  /* verilator lint_on WIDTH */

  always_ff @(posedge clk) begin
      if (reset | FlushE) begin
          state <= #1 IDLE; 
      end else if (IFDivStartE) begin 
          step <= cycles; 
          if (SpecialCaseE) state <= #1 DONE;
          else              state <= #1 BUSY;
      end else if (state == BUSY) begin 
          if (step == 1 | WZeroE) state <= #1 DONE; // finished steps or terminate early on zero residual
          step <= step - 1;
      end else if (state == DONE) begin
        if (StallM) state <= #1 DONE;
        else        state <= #1 IDLE;
      end 
  end

endmodule
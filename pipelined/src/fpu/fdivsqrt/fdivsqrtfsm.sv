///////////////////////////////////////////
// fdivsqrtfsm.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module fdivsqrtfsm(
  input  logic clk, 
  input  logic reset, 
  input  logic [`FMTBITS-1:0] FmtE,
  input  logic XInfE, YInfE, 
  input  logic XZeroE, YZeroE, 
  input  logic XNaNE, YNaNE, 
  input  logic FDivStartE, IDivStartE,
  input  logic XsE,
  input  logic SqrtE,
  input  logic StallE,
  input  logic StallM,
  input  logic WZero,
  input  logic MDUE,
  input  logic [`DIVBLEN:0] n,
  output logic DivStartE,
  output logic DivDone,
  output logic FDivBusyE,
  output logic SpecialCaseM
);
  
  typedef enum logic [1:0] {IDLE, BUSY, DONE} statetype;
  statetype state;

  logic [`DURLEN-1:0] step;
  logic [`DURLEN-1:0] cycles;
  logic SpecialCaseE;

  // *** start logic is presently in fctl.  Make it look more like integer division start logic
  // DivStartE comes from fctrl, reflecitng the start of floating-point and possibly integer division
  assign DivStartE = (FDivStartE | IDivStartE) & (state == IDLE) & ~StallM;
  assign DivDone = (state == DONE) | (WZero & (state == BUSY));
  assign FDivBusyE = (state == BUSY & ~DivDone);

    // Divider control signals from MDU
  //assign DivBusyE = (state == BUSY) | DivStartE;

  // terminate immediately on special cases
  assign SpecialCaseE = XZeroE | (YZeroE&~SqrtE) | XInfE | YInfE | XNaNE | YNaNE | (XsE&SqrtE);
  flopenr #(1) SpecialCaseReg(clk, reset, ~StallM, SpecialCaseE, SpecialCaseM); // save SpecialCase for checking in fdivsqrtpostproc

// DIVN = `NF+3
// NS = NF + 1
// N = NS or NS+2 for div/sqrt.  

/* verilator lint_off WIDTH */
  logic [`DURLEN+1:0] Nf, fbits; // number of fractional bits
  if (`FPSIZES == 1)
    assign Nf = `NF;
  else if (`FPSIZES == 2)
    always_comb
      case (FmtE)
        1'b0: Nf = `NF1;
        1'b1: Nf = `NF;
      endcase
  else if (`FPSIZES == 3)
    always_comb
      case (FmtE)
        `FMT: Nf = `NF;
        `FMT1: Nf = `NF1;
        `FMT2: Nf = `NF2; 
      endcase
  else if (`FPSIZES == 4)  
    always_comb
      case(FmtE)
        `S_FMT: Nf = `S_NF;
        `D_FMT: Nf = `D_NF;
        `H_FMT: Nf = `H_NF;
        `Q_FMT: Nf = `Q_NF;
      endcase 


  always_comb begin 
    if (SqrtE) fbits = Nf + 2 + 2; // Nf + two fractional bits for round/guard + 2 for right shift by up to 2
    else       fbits = Nf + 2 + `LOGR; // Nf + two fractional bits for round/guard + integer bits - try this when placing results in msbs
    cycles =  MDUE ? n : (fbits + (`LOGR*`DIVCOPIES)-1)/(`LOGR*`DIVCOPIES);
  end 

  /* verilator lint_on WIDTH */

  always_ff @(posedge clk) begin
      if (reset) begin
          state <= #1 IDLE; 
      end else if (DivStartE&~StallE) begin 
          step <= cycles; 
//          $display("Setting Nf = %d fbits %d cycles = %d FmtE %d FPSIZES = %d Q_NF = %d num = %d denom = %d\n", Nf, fbits, cycles, FmtE, `FPSIZES, `Q_NF,
//          (fbits +(`LOGR*`DIVCOPIES)-1), (`LOGR*`DIVCOPIES));
          if (SpecialCaseE) state <= #1 DONE;
          else             state <= #1 BUSY;
      end else if (DivDone) begin
        if (StallM) state <= #1 DONE;
        else        state <= #1 IDLE;
      end else if (state == BUSY) begin
          if (step == 1) begin
              state <= #1 DONE;
          end
          step <= step - 1;
      end 
  end


endmodule
///////////////////////////////////////////
// fdivsqrtfsm.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, Cedar Turek
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
  input  logic DivStart, 
  input  logic XsE,
  input  logic SqrtE,
  input  logic StallE,
  input  logic StallM,
  input logic WZero,
  output logic [`DURLEN-1:0] EarlyTermShiftE,
  output logic DivDone,
  output logic DivBusy
);
  
  typedef enum logic [1:0] {IDLE, BUSY, DONE} statetype;
  statetype state;

  logic [`DURLEN-1:0] step;
  logic SpecialCase;
  logic [`DURLEN-1:0] cycles;

  assign EarlyTermShiftE = step;

  // terminate immediately on special cases
  assign SpecialCase = XZeroE | (YZeroE&~SqrtE) | XInfE | YInfE | XNaNE | YNaNE | (XsE&SqrtE);

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
    if (SqrtE) cycles =  (fbits + (`LOGR*`DIVCOPIES)-1)/(`LOGR*`DIVCOPIES);  // ceiling(fbits / r*k)
    else       cycles = `FPDUR; // *** line above should work once otfc is used to put results in upper bits
  end 

  /* verilator lint_on WIDTH */

  always_ff @(posedge clk) begin
      if (reset) begin
          state <= #1 IDLE; 
      end else if (DivStart&~StallE) begin 
          step <= cycles; // *** this should be adjusted to depend on the precision; sqrt should use one fewer step becasue firststep=1
//          $display("Setting Nf = %d fbits %d cycles = %d FmtE %d FPSIZES = %d Q_NF = %d num = %d denom = %d\n", Nf, fbits, cycles, FmtE, `FPSIZES, `Q_NF,
//          (fbits +(`LOGR*`DIVCOPIES)-1), (`LOGR*`DIVCOPIES));
          if (SpecialCase) state <= #1 DONE;
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

  assign DivDone = (state == DONE) | (WZero & (state == BUSY));
  assign DivBusy = (state == BUSY & ~DivDone);

endmodule
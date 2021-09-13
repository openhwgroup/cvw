///////////////////////////////////////////
// intdiv_restoring.sv
//
// Written: David_Harris@hmc.edu 12 September 2021
// Modified: 
//
// Purpose: Restoring integer division using a shift register a subtractor
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module intdiv_restoring (
  input  logic clk,
  input  logic reset,
  input  logic signedDivide,
  input  logic start,
  input  logic [`XLEN-1:0] X, D,
  output logic busy, done,
  output logic [`XLEN-1:0] Q, REM
 );

  logic [`XLEN-1:0] W, Win, Wshift, Wprime, Wnext, XQ, XQin, XQshift;
  logic qi; // curent quotient bit
  localparam STEPBITS = $clog2(`XLEN);
  logic [STEPBITS:0] step;
  logic div0;

  // restoring division
  mux2 #(`XLEN) wmux(W, 0, start, Win);
  mux2 #(`XLEN) xmux(0, X, start, XQin);
  assign {Wshift, XQshift} = {Win[`XLEN-2:0], XQin, qi};
  assign {qi, Wprime} = Wshift - D; // subtractor, carry out determines quotient bit
  mux2 #(`XLEN) wrestoremux(Wshift, Wprime, qi, Wnext);
  flopen #(`XLEN) wreg(clk, busy, Wnext, W);
  flopen #(`XLEN) xreg(clk, busy, XQshift, XQ);

  // outputs
  // *** sign extension, handling W instructions
  assign div0 = (D == 0);
  mux2 #(`XLEN) qmux(XQ, {`XLEN{1'b1}}, div0, Q); // Q taken from XQ register, or all 1s when dividing by zero
  mux2 #(`XLEN) remmux(W, X, div0, REM); // REM taken from W register, or from X when dividing by zero
 
  // busy logic
  always_ff @(posedge clk)
    if (start) begin
        busy = 1; done = 0; step = 0;
    end else if (busy) begin
        step = step + 1;
        if (step[STEPBITS] | div0) begin // *** early terminate on division by 0
            step = 0;
            busy = 0;
            done = 1;
        end
    end else if (done) begin
        done = 0;
    end

endmodule // muldiv


